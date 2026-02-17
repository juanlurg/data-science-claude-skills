---
name: paper-to-code
description: Reads a research paper and generates an implementation notebook with equations, code, and a toy example. Use when the user wants to implement a paper, convert a paper to code, or reproduce a paper's algorithm.
argument-hint: <pdf-path-or-arxiv-url>
---

# Paper to Code

## Input

`$ARGUMENTS` is either:

- A **PDF file path** (local file).
- An **arXiv URL** (e.g., `https://arxiv.org/abs/2301.12345`).

If not provided, ask the user for the paper path or URL.

## Step 1: Read the Paper

**If PDF path:**
- Read the PDF using the Read tool (Claude can read PDFs directly).

**If arXiv URL:**
- Use WebFetch to get the abstract page.
- Extract the PDF link: replace `/abs/` with `/pdf/` and append `.pdf`.
- Fetch and read the PDF content.

**Extract from the paper:**
- Title, authors, year.
- Abstract.
- Key method sections describing the novel contribution.
- Core equations and algorithm descriptions.
- Any pseudocode or algorithm boxes.

## Step 2: Identify Required Framework

Based on the paper content, determine which libraries are needed:

- **numpy only** — simple algorithms, statistical methods.
- **sklearn** — ML algorithms, preprocessing.
- **PyTorch** — deep learning, neural networks.
- **TensorFlow** — deep learning (if paper uses TF).
- **JAX** — differentiable programming, if paper uses JAX.

Check environment per [environment-detection.md](../../lib/environment-detection.md). Ask before installing missing packages.

## Step 3: Generate the Notebook

Follow [notebook-format.md](../../lib/notebook-format.md) for structure.

### Section 1: Header (markdown)

```
# Paper Implementation: {paper_title}

**Authors:** {authors}
**Year:** {year}
**Link:** [{url_or_path}]({url_or_path})

*Generated on {YYYY-MM-DD} by paper-to-code skill*

> **Disclaimer:** This is an AI-generated starting point, not a verified
> reproduction. Verify against the original paper before use in production.
```

### Section 2: Paper Overview (markdown)

1-2 paragraphs in plain language explaining:
- What problem the paper solves.
- Why it matters (context in the field).
- The key insight or approach.

No jargon. Write as if explaining to a competent programmer who hasn't read the paper.

### Section 3: Key Equations (markdown)

Core mathematical formulations in LaTeX. Each equation followed by a plain-English explanation.

Format:

```
$$\alpha_i = \frac{\exp(e_i)}{\sum_j \exp(e_j)}$$

This is the softmax attention weight — it converts raw scores into a probability
distribution over all positions. Higher scores get exponentially more weight.
```

Include only the equations central to the novel contribution — not standard loss functions or well-known formulas unless the paper modifies them.

### Section 4: Core Implementation (code + markdown)

Python implementation of the **main algorithm** — the novel contribution of the paper, NOT the entire paper.

Guidelines:
- Break into logical functions or classes that map to paper sections.
- Heavy inline comments referencing paper sections: `# Section 3.2, Eq. 5 — compute attention scores`.
- Prefer functional style for clarity, unless the paper naturally maps to classes.
- Keep code focused: no data loading boilerplate, no training loops, no logging — just the core algorithm.

Markdown cells between code cells explaining what each piece does and how it connects to the paper.

### Section 5: Toy Example (code + markdown)

Create a small synthetic dataset or simple input to demonstrate the implementation:

```python
# Create toy data
import numpy as np
np.random.seed(42)
X = np.random.randn(100, 10)  # 100 samples, 10 features
```

Run the implementation on it. Print or visualize results.

Include a sanity check:

```
# Sanity check
# Expected behavior: output shape should be (100, 5) for 5 classes
print(f"Output shape: {output.shape}")
assert output.shape == (100, 5), "Shape mismatch!"
print("Sanity check passed.")
```

### Section 6: Limitations & Notes (markdown)

- What was simplified from the full paper.
- What was skipped (e.g., specific training tricks, large-scale experiments).
- Key differences from the paper's full implementation.
- Links to official repositories if they exist (search GitHub for the paper title).
- Suggestions for extending the implementation.

## Step 4: Write the Notebook

Write to `./notebooks/paper_{short_title}_{YYYY-MM-DD}.ipynb` where `short_title` is a snake_case abbreviation of the paper title (max 30 characters).

Create the `./notebooks/` directory if it doesn't exist.

## Step 5: Report

Tell the user:
- Where the notebook was saved.
- What was implemented (the core contribution).
- What was skipped and why.

## Important Rules

- Focus on the **NOVEL contribution** of the paper, not standard boilerplate.
- If the paper is too complex for a single notebook (e.g., full transformer architecture), pick the core innovation and implement that. Explain what was scoped out.
- Prefer functional style for clarity over OOP unless the paper naturally maps to classes.
- All code must be self-contained and runnable standalone.
- The toy example must actually run and produce visible output.
- Never claim the implementation is a complete reproduction — always include the disclaimer.
