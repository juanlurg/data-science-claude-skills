# Environment Detection

## Package Manager Detection

Check the project root for these files in priority order:

1. `uv.lock` → use `uv add <package>`
2. `pyproject.toml` (without uv.lock) → check if `[tool.uv]` section exists: if yes use `uv add`, else use `pip install`
3. `Pipfile` → use `pipenv install <package>`
4. `requirements.txt` → use `pip install <package>`
5. `environment.yml` → use `conda install <package>`
6. Nothing found → default to `pip install <package>`

## Dependency Check

For each required package, run:

```bash
python -c "import <package_name>" 2>/dev/null && echo "OK" || echo "MISSING"
```

If any are missing, present the user with:

> The following packages are needed: **X, Y, Z**
> Install with `<detected_command> X Y Z`?

Wait for confirmation before installing. Never install without asking.

## Data Library Detection

Check which data libraries are available:

```bash
python -c "import pandas" 2>/dev/null && echo "pandas"
python -c "import polars" 2>/dev/null && echo "polars"
```

- If only pandas: generate pandas code
- If only polars: generate polars code
- If both: ask user which they prefer, default to pandas

## Python Detection

```bash
python --version 2>/dev/null || python3 --version 2>/dev/null
```

Use whichever is available. Prefer `python` over `python3`.
