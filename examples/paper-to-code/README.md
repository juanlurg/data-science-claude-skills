# paper-to-code Example: Isolation Forest

## Paper

**Title**: *Isolation Forest*
**Authors**: Fei Tony Liu, Kai Ming Ting, Zhi-Hua Zhou
**Published**: IEEE International Conference on Data Mining (ICDM), 2008
**Key idea**: Anomalies are "few and different" — they can be isolated with
fewer random partitions than normal points, resulting in shorter average path
lengths in random trees.

## What the notebook demonstrates

- Plain-language overview of the paper's contribution
- Key equations in LaTeX (anomaly score, average path length, harmonic number)
- From-scratch implementation using only `numpy` (no sklearn)
- `IsolationTree` class with recursive partitioning
- `IsolationForest` class with ensemble scoring
- Toy example: detecting 15 injected anomalies in 300 normal 2D points
- Score distribution visualization showing bimodal separation

### Dependencies

Only `numpy` and `matplotlib` — no sklearn or other ML libraries needed.

## Generated notebook

`notebooks/paper_isolation_forest_2025-03-15.ipynb`

## Try it yourself

```
/data-science:paper-to-code "Isolation Forest by Liu, Ting & Zhou, 2008 IEEE ICDM"
```
