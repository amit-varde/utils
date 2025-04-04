# PPTCraft

A Python toolkit for PowerPoint manipulation, extraction, and modification.

## Features

- Extract metadata from PowerPoint presentations
- Identify and extract section headers, summary slides, and tables
- Modify PowerPoint content programmatically
- Command-line interface for quick operations

## Installation

```bash
# Install from the repository
git clone https://github.com/yourusername/pptcraft.git
cd pptcraft
pip install -e .

# Or directly from PyPI (once published)
pip install pptcraft
```

## Usage

### As a Library

```python
from pptcraft import PPTXSlides

# Load a presentation
ppt = PPTXSlides("path/to/your/presentation.pptx")

# Extract metadata
metadata = ppt.extract_presentation_metadata()

# Get table data from a summary slide
tables = ppt.get_summary_table(5)  # Get tables from slide #6 (0-based index)

# Update a title slide
ppt.set_presentation_title_slide(title_text="New Title")

# Save the modified presentation
ppt.save_presentation("output.pptx")
```

### Command Line

```bash
# Process a PowerPoint file
pptcraft --file presentation.pptx --output modified.pptx
```

## Requirements

- Python 3.6+
- python-pptx

## License

MIT
