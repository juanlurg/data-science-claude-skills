# Notebook Generation

## Writing .ipynb Files

Jupyter notebooks are JSON files. Write them directly using the Write tool. No `nbformat` dependency needed.

## Minimal Notebook Structure

```json
{
  "nbformat": 4,
  "nbformat_minor": 5,
  "metadata": {
    "kernelspec": {
      "display_name": "Python 3",
      "language": "python",
      "name": "python3"
    },
    "language_info": {
      "name": "python",
      "version": "3.11.0"
    }
  },
  "cells": []
}
```

## Cell Types

**Markdown cell:**
```json
{
  "cell_type": "markdown",
  "metadata": {},
  "source": ["# Title\n", "\n", "Description text."]
}
```

**Code cell:**
```json
{
  "cell_type": "code",
  "metadata": {},
  "source": ["import pandas as pd\n", "df = pd.read_csv('data.csv')"],
  "execution_count": null,
  "outputs": []
}
```

## Rules

1. The `source` field is an array of strings. Each string is one line, ending with `\n` except the last line.
2. Always create the `./notebooks/` directory if it doesn't exist before writing.
3. Every notebook starts with a metadata markdown cell containing: skill name, date generated, input file path.
4. File naming: `{skill}_{context}_{YYYY-MM-DD}.ipynb`.
5. All generated code must be self-contained. No imports from the plugin. A user must be able to run the notebook standalone.
6. Escape special characters in JSON strings: backslashes, quotes, newlines.
