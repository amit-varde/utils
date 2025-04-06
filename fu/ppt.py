import sys
import json
import os
import argparse
import base64
import csv
import logging
import inspect
from io import StringIO, BytesIO
from datetime import datetime
try:
    from pptx import Presentation
    from pptx.enum.shapes import MSO_SHAPE_TYPE
except ImportError:
    logger = logging.getLogger(__name__)
    logger.error("The 'python-pptx' module is not installed.")
    logger.info("Please install it using one of the following commands:")
    logger.info("  pip install python-pptx")
    logger.info("  conda install -c conda-forge python-pptx")
    sys.exit(1)

DEFAULT_SLIDE_METADATA = {
    "layout_name": "Unknown",
    "title": "Untitled",
    "shapes": {},
    "tables":{},
    "images": {},
    "total_shapes": 0,
    "total_tables": 0,
    "total_images": 0,
    "total_textboxes": 0,
    "is_summary_slide": "no",
    "is_section_summary_slide": "no"
}

BLUE = "\033[94m"
RED = "\033[91m"
YELLOW = "\033[93m"
ORANGE = "\033[38;5;208m"
RESET = "\033[0m"

DEBUG_LEVEL = os.environ.get("DEBUG_LEVEL", "0")

# Define a custom level between DEBUG and INFO
DEBUG_INFO = 15  # DEBUG is 10, INFO is 20
logging.addLevelName(DEBUG_INFO, "DEBUG_INFO")

# Add a method to the logger class
def debug_info(self, message, *args, **kwargs):
    if self.isEnabledFor(DEBUG_INFO):
        self._log(DEBUG_INFO, message, args, **kwargs)

# Add the method to the Logger class
logging.Logger.debug_info = debug_info

class ColorFormatter(logging.Formatter):
    def format(self, record):
        stack = inspect.stack()
        # If debug, show parent function plus current function
        if DEBUG_LEVEL == "1" and len(stack) > 3:
            parent_function = stack[3].function
            record.parent_func = parent_function
            self._style._fmt = f"{YELLOW}%(levelname)s:%(parent_func)s:%(funcName)s:%(message)s{RESET}"
        else:
            record.parent_func = ""
            self._style._fmt = "%(levelname)s:%(name)s:%(funcName)s:%(message)s"

        if record.levelno == logging.INFO:
            record.levelname = f"{BLUE}{record.levelname}{RESET}"
        elif record.levelno == logging.ERROR:
            record.levelname = f"{RED}{record.levelname}{RESET}"
        elif record.levelno == logging.WARNING:
            record.levelname = f"{YELLOW}{record.levelname}{RESET}"
        elif record.levelno == DEBUG_INFO:
            record.levelname = f"{ORANGE}{record.levelname}{RESET}"
        return super().format(record)

stream_handler = logging.StreamHandler()
stream_handler.setFormatter(ColorFormatter(fmt="%(levelname)s:%(name)s:%(funcName)s:%(message)s"))
logger = logging.getLogger(__name__)
logger.handlers = [stream_handler]
logger.setLevel(logging.DEBUG)

class PPTXSlides:
    def __init__(self, file_path=None):
        """
        purpose: Initialize the PPTXSlides
        args: file_path (str or None)
        returns: None
        usage_example: slides = PPTXSlides("slides.pptx")
        """
        logger.debug_info("Executing: __init__")
        self.presentation = None  # The presentation object
        self.file_path = None  # Path to the loaded file
        self.slides = []  # All slides in presentation
        self.slide_metadata = [] #  Array to store metadata for each slide
        # "purpose oriented slides"
        self.summary_slides = []  # Indices of summary slides
        self.section_header = []  # Indices of section header slides
        # "Purpose oriented data structures"
        self.section_summaries = {}  # Dictionary mapping section header indices to title and summary text
        self.summary_tables = {}  # Dictionary mapping slide titles to tables
        # If file_path is provided, load the presentation
        if file_path:
            self.file_path = file_path
            self.presentation, self.slides, self.slide_metadata = self.load_presentation(file_path)
            logger.info(f"Total number of slides loaded: {len(self.slides)}")
            
    # ------------------------------------------------
    def identify_purpose_oriented_slides(self):
        """
        purpose: Identify summary or section header slides
        args: none
        returns: None
        usage_example: slides.identify_purpose_oriented_slides()
        """
        logger.debug_info("Executing: _identify_slide_purpose")
        summary_slides = []
        section_summary_slides = []
        
        for i, slide in enumerate(self.slides):
            metadata = self.slide_metadata[i]
            layout_name = metadata.get("layout_name", "")
            if layout_name == "Section Header":
                self.set_metadata(i, "is_section_summary_slide", "yes")
                section_summary_slides.append(i)
                logger.info(f"Found section header slide at index {i}: {metadata['title']}")
                # Extract section title and summary
                section_title = ""
                section_summary = ""
                for shape_idx, shape in enumerate(slide.shapes):
                    if shape_idx == 0 and hasattr(shape, "text_frame") and hasattr(shape.text_frame, "text"):
                        section_title = shape.text_frame.text
                    elif shape_idx == 1 and hasattr(shape, "text_frame") and hasattr(shape.text_frame, "text"):
                        section_summary = shape.text_frame.text
                self.section_summaries[i] = {
                    "section_title": section_title,
                    "section_summary": section_summary
                }
            elif layout_name == "Title Only":
                # Look for a title text that starts with "Summary: "
                title_text = ""
                for shape in slide.shapes:
                    if hasattr(shape, "text") and shape.text:
                        title_text = shape.text.strip()
                        break
                if title_text.lower().startswith("summary:"):
                    self.set_metadata(i, "is_summary_slide", "yes")
                    logger.info(f"Found summary slide at index {i}: {metadata['title']}")
                    summary_slides.append(i)
        self.summary_slides = summary_slides
        self.section_header = section_summary_slides

    # ------------------------------------------------
    # File handling methods
    # ------------------------------------------------
    
    def load_presentation(self, file_path):
        """
        purpose: Load a PPTX file
        args: file_path (str)
        returns: list of slides
        usage_example: slides.load_presentation("slides.pptx")
        """
        logger.debug_info("Executing: load_presentation")
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"PowerPoint file not found: {file_path}")
        if not os.path.isfile(file_path):
            raise ValueError(f"The path is not a file: {file_path}")
        logger.info(f"Attempting to process file: {file_path}")
        logger.info(f"File exists: {os.path.exists(file_path)}")
        logger.info(f"File size: {os.path.getsize(file_path)} bytes")
        # Use python-pptx to read the presentation
        try:
            presentation = Presentation(file_path)
            slides = list(presentation.slides)
            slides_metadata = [self.extract_metadata_from_slide(slide) for slide in slides]
            if not slides:
                logger.warning("No slides found in the presentation.")
            return presentation, slides, slides_metadata
        except Exception as e:
            logger.error(f"Error reading PowerPoint file: {e}")
            raise
    # ------------------------------------------------
    def save_presentation(self, output_file):
        """
        purpose: Save the PPTX file
        args: output_file (str)
        returns: str (output path)
        usage_example: slides.save_presentation("slides_updated.pptx")
        """
        logger.debug_info("Executing: save_presentation")
        output_dir = os.path.dirname(output_file)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)
        logger.info(f"Writing presentation to: {output_file}")
        self.presentation.save(output_file)
        logger.info(f"Successfully saved presentation to: {output_file}")
        return output_file

    # ------------------------------------------------
    # Extract methods
    # ------------------------------------------------
    def extract_metadata_from_slide(self, slide):
        """
        purpose: Extract slide metadata
        args: slide (Slide object)
        returns: dict
        usage_example: metadata = slides.extract_metadata_from_slide(slide_obj)
        """
        logger.info("Extracting metadata for slide")
        
        # Initialize metadata with default values
        metadata = DEFAULT_SLIDE_METADATA.copy()
        
        # Get layout name
        layout_name = "Unknown"
        if hasattr(slide, 'slide_layout') and hasattr(slide.slide_layout, 'name'):
            layout_name = slide.slide_layout.name
        metadata["layout_name"] = layout_name
        logger.info(f"layout: {layout_name}")
        
        # Get slide title
        slide_title = "Untitled"
        for shape in slide.shapes:
            if hasattr(shape, "text") and shape.text:
                if hasattr(shape, "is_title") and shape.is_title:
                    slide_title = shape.text
                    break
                elif slide_title == "Untitled":
                    slide_title = shape.text
        metadata["title"] = slide_title
        
        # Count shapes by type
        shape_counts = {}
        for shape in slide.shapes:
            shape_type = str(shape.shape_type)
            if shape_type in shape_counts:
                shape_counts[shape_type] += 1
            else:
                shape_counts[shape_type] = 1
        
        metadata["shapes"] = shape_counts
        metadata["total_shapes"] = len(slide.shapes)
        
        # Count specific types
        metadata["total_tables"] = sum(1 for shape in slide.shapes if shape.shape_type == MSO_SHAPE_TYPE.TABLE)
        metadata["total_images"] = sum(1 for shape in slide.shapes if shape.shape_type == MSO_SHAPE_TYPE.PICTURE)
        metadata["total_textboxes"] = sum(1 for shape in slide.shapes if hasattr(shape, "text_frame") and not (hasattr(shape, "is_title") and shape.is_title))
        
        return metadata
    
    def extract_table_from_slide(self, index):
        """
        purpose: Extract table data from a slide
        args: index (int)
        returns: list of tables
        usage_example: slides.extract_table_from_slide(1)
        """
        logger.debug_info(f"Executing: extract_table_from_slide for slide {index + 1}")
        
        if index >= len(self.slides):
            logger.warning(f"Invalid slide index: {index}, max index is {len(self.slides)-1}")
            return []
            
        slide = self.slides[index]
        slide_tables = []
        slide_title = self.slide_metadata[index]["title"]
        
        for shape in slide.shapes:
            if shape.shape_type == MSO_SHAPE_TYPE.TABLE:
                table = shape.table
                table_data = []
                for r in range(len(table.rows)):
                    row_data = []
                    for c in range(len(table.columns)):
                        cell = table.cell(r, c)
                        cell_text = cell.text.replace('\n', ' ')
                        row_data.append(cell_text)
                    table_data.append(row_data)
                slide_tables.append(table_data)
        
        # Store in summary_tables if there are tables found
        if slide_tables:
            self.summary_tables[index] = slide_tables
        
        return slide_tables
    
    # ------------------------------------------------
    # Get methods
    # ------------------------------------------------
    
    def get_summary_table(self, index):
        """
        purpose: Get summary tables for a slide
        args: index (int)
        returns: list of tables or None
        usage_example: slides.get_summary_table(0)
        """
        # Validate the index
        if not (0 <= index < len(self.slides)):
            logger.warning(f"Warning: Invalid slide index {index}, valid range is 0-{len(self.slides)-1}")
            return None
        
        # Extract the slide title from the index
        slide_title = self.slide_metadata[index]["title"]
        
        # Extract tables if they don't exist for this slide
        if index not in self.summary_tables:
            self.extract_table_from_slide(index)
        
        # Return tables for the slide index
        if index in self.summary_tables:
            return self.summary_tables[index]
        else:
            logger.warning(f"Warning: No tables found for slide at index {index}")
            return None
    
    def get_section_summary(self, index):
        """
        purpose: Get section summary info
        args: index (int)
        returns: dict or None
        usage_example: slides.get_section_summary(2)
        """
        if index in self.section_summaries:
            return self.section_summaries[index]
        else:
            logger.warning(f"Warning: No section summary found for index {index}")
            return None

    def get_metadata(self, index, item):
        """
        purpose: Get a single slide metadata field
        args: index (int), item (str)
        returns: value or None
        usage_example: slides.get_metadata(0, "title")
        """
        return self.slide_metadata[index].get(item)

    # ------------------------------------------------
    # Set methods
    # ------------------------------------------------
    
    def set_presentation_title_slide(self, index=0, title_text=None, attribution_text=None):
        """
        purpose: Set or update a title slide
        args: index (int), title_text (str), attribution_text (str)
        returns: bool
        usage_example: slides.set_presentation_title_slide(0, "Weekly Update")
        """
        logger.debug_info(f"Executing: set_presentation_title_slide for slide {index + 1}")
        if not self.presentation or not self.slides or not (0 <= index < len(self.slides)):
            logger.warning(f"Invalid slide index: {index}")
            return False
            
        slide = self.slides[index]
        text_shapes = []
        for shape in slide.shapes:
            if hasattr(shape, "text_frame"):
                text_shapes.append(shape)
                
        today = datetime.now().strftime("%m-%d-%Y")
        if title_text is None:
            title_text = f"Weekly Update {today}"
        if attribution_text is None:
            attribution_text = "Alec .. did this automatically"
            
        content = [title_text, attribution_text]
        for i, text in enumerate(content):
            if text is None:
                continue
            if i < len(text_shapes):
                text_shapes[i].text_frame.text = text
            elif i == 1 and len(text_shapes) == 1:
                p = text_shapes[0].text_frame.add_paragraph()
                p.text = f"\n\n{attribution_text}"
            else:
                logger.warning(f"Warning: Not enough text shapes on slide {index + 1} for content #{i+1}")
        return True
    
    def set_summary_table(self, index, row, col, new_text):
        """
        purpose: Update a table cell
        args: index (int), row (int), col (int), new_text (str)
        returns: bool
        usage_example: slides.set_summary_table(1, 2, 0, "New Value")
        """
        # Validate the index
        if not (0 <= index < len(self.slides)):
            logger.warning(f"Invalid slide index: {index}, valid range is 0-{len(self.slides)-1}")
            return False
        
        # Extract tables if they don't exist for this slide
        if index not in self.summary_tables:
            tables = self.extract_table_from_slide(index)
            if not tables:
                logger.warning(f"No tables found on slide at index {index}")
                return False
        
        # Get the tables for this slide
        slide_tables = self.summary_tables[index]
        if not slide_tables:
            logger.warning(f"No tables found on slide at index {index}")
            return False
            
        table_data = slide_tables[0]  # Use the first table
        if row < 0 or row >= len(table_data):
            logger.warning(f"Invalid row index: {row}, valid range is 0-{len(table_data)-1}")
            return False
        if col < 0 or col >= len(table_data[0]):
            logger.warning(f"Invalid column index: {col}, valid range is 0-{len(table_data[0])-1}")
            return False
            
        # Update the data in memory
        table_data[row][col] = new_text
        
        # Update the actual PowerPoint object
        slide = self.slides[index]
        for shape in slide.shapes:
            if shape.shape_type == MSO_SHAPE_TYPE.TABLE:
                try:
                    shape.table.cell(row, col).text = new_text
                    return True
                except IndexError:
                    logger.error(f"Error updating PowerPoint table: Index out of range")
                    return False
                    
        logger.warning(f"Updated table data in memory but couldn't update PowerPoint object")
        return True
    
    def set_section_summary(self, index, title=None, summary=None):
        """
        purpose: Update section title/summary
        args: index (int), title (str), summary (str)
        returns: bool
        usage_example: slides.set_section_summary(2, "Section Title", "Section Summary")
        """
        # This method already matches the requested signature, but we'll ensure it works properly
        if index not in self.section_summaries:
            logger.error(f"Error: No section found with index {index}")
            return False
            
        # Update in-memory data
        if title is not None:
            self.section_summaries[index]["section_title"] = title
            
        if summary is not None:
            self.section_summaries[index]["section_summary"] = summary
            
        # Update actual PowerPoint slide
        if index < len(self.slides):
            slide = self.slides[index]
            for shape_idx, shape in enumerate(slide.shapes):
                if shape_idx == 0 and hasattr(shape, "text_frame") and title is not None:
                    shape.text_frame.text = title
                elif shape_idx == 1 and hasattr(shape, "text_frame") and summary is not None:
                    shape.text_frame.text = summary
            return True
        else:
            logger.warning(f"Warning: Could update section summary in memory but not in PowerPoint (invalid slide index)")
            return False

    def set_metadata(self, index, item, value):
        """
        purpose: Update a slide metadata field
        args: index (int), item (str), value (any)
        returns: None
        usage_example: slides.set_metadata(0, "is_summary_slide", "yes")
        """
        self.slide_metadata[index][item] = value

    # ------------------------------------------------
    # Show/display methods
    # ------------------------------------------------
    
    def show_slide_metadata(self, index):
        """
        purpose: Print single slide metadata
        args: index (int)
        returns: None
        usage_example: slides.show_slide_metadata(0)
        """
        # Don't call extract_metadata_from_slide with an index
        # Just use the already stored metadata
        logger.info("Slide {} Metadata:".format(index + 1))
        logger.info(json.dumps(self.slide_metadata[index], indent=4))
        
        # Check if this is a purpose-built slide (summary or section summary)
        is_summary = self.slide_metadata[index].get("is_summary_slide") == "yes"
        is_section_summary = self.slide_metadata[index].get("is_section_summary_slide") == "yes"
        if is_summary or is_section_summary:
            logger.info(f"Purpose-built slide detected. Showing tables:")
            self.show_table(self.slides[index])
        logger.info("-" * 75)
    
    def show_presentation_metadata(self):
        """
        purpose: Print metadata for all slides
        args: none
        returns: None
        usage_example: slides.show_presentation_metadata()
        """
        logger.debug_info("Executing: show_presentation_metadata")
        logger.info(f"\nPresentation contains {len(self.slides)} slides")
        logger.info("=" * 50)
        for i in range(len(self.slides)):
            logger.info(f"Slide {i + 1}:")
            self.show_slide_metadata(i)
    
    def show_table(self, slide):
        """
        purpose: Print table data for a given slide object
        args: slide (Slide object)
        returns: None
        usage_example: slides.show_table(slide_obj)
        """
        logger.debug_info("Executing: show_table")
        
        # Extract tables from the slide
        slide_tables = []
        for shape in slide.shapes:
            if shape.shape_type == MSO_SHAPE_TYPE.TABLE:
                table = shape.table
                table_data = []
                for r in range(len(table.rows)):
                    row_data = []
                    for c in range(len(table.columns)):
                        cell = table.cell(r, c)
                        cell_text = cell.text.replace('\n', ' ')
                        row_data.append(cell_text)
                    table_data.append(row_data)
                slide_tables.append(table_data)
        
        if slide_tables:
            # Try to get slide title
            slide_title = "Unknown"
            for shape in slide.shapes:
                if hasattr(shape, "text") and shape.text:
                    if hasattr(shape, "is_title") and shape.is_title:
                        slide_title = shape.text
                        break
                    
            logger.info(f"\nTable data from slide ({slide_title}):")
            self._display_tables(slide_tables)
        else:
            logger.warning("No tables found in the provided slide")

    def _display_tables(self, tables):
        """
        purpose: Internal helper to display tables
        args: tables (list of table data)
        returns: None
        """
        for table_idx, table_data in enumerate(tables):
            logger.info(f"Table {table_idx + 1}:")
            try:
                if not table_data:
                    logger.info("  Empty table")
                    continue
                col_widths = [0] * len(table_data[0])
                for row in table_data:
                    for i, cell in enumerate(row):
                        if i < len(col_widths):
                            col_widths[i] = max(col_widths[i], len(cell))
                separator = "  +" + "+".join("-" * (width + 2) for width in col_widths) + "+"
                logger.info(separator)
                for row in table_data:
                    row_text = "  |"
                    for i, cell in enumerate(row):
                        if i < len(col_widths):
                            padding = col_widths[i] - len(cell)
                            row_text += f" {cell}{' ' * padding} |"
                    logger.info(row_text)
                    logger.info(separator)
            except Exception as e:
                logger.error(f"Error formatting table: {e}")
                logger.info(table_data)
            logger.info("")

def main():
    """
    purpose: Command-line entry point
    args: none (CLI parser used)
    returns: None
    usage_example: python ppt.py --file slides.pptx
    """
    logger.debug_info("Executing: main")
    parser = argparse.ArgumentParser(description='Extract information from PowerPoint files.')
    parser.add_argument('--file', '-f', type=str, 
                       default="/Users/amit/work/utils/fu/test_cases/3-27-2025.pptx",
                       help='Path to the PowerPoint file')
    parser.add_argument('--output', '-o', type=str,
                       help='Output file path (optional, default: input_update.pptx)')
    args = parser.parse_args()
    file_path = args.file
    output_path = args.output
    
    try:
        if not os.path.exists(file_path):
            logger.error(f"Error: File not found: {file_path}")
            sys.exit(1)
        logger.info(f"Reading presentation from: {file_path}")
        status_pptx = PPTXSlides(file_path)
        logger.debug_info("Loaded..")
        status_pptx.identify_purpose_oriented_slides()
        status_pptx.show_presentation_metadata()
        
        # Update the title slide
        today = datetime.now().strftime("%m-%d-%Y")
        status_pptx.set_presentation_title_slide(title_text=f"{today}: Weekly Update")
        
        # Save the presentation
        if not output_path:
            base_name, ext = os.path.splitext(file_path)
            output_path = f"{base_name}_update{ext}"
        status_pptx.save_presentation(output_path)
        logger.info(f"PPTX file updated successfully from {file_path} to {output_path}")
    except Exception as e:
        logger.error(f"Error processing presentation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
