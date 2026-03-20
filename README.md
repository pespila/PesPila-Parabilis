# PesPila-Parabilis

Soccer match outcome prediction using statistical distribution fitting, ensemble methods, and reinforcement learning.

## Installation

```bash
pip install -e ".[dev]"
```

## Usage

```python
from pespila.data.pipeline import DataPipeline

# Download and populate database
pipeline = DataPipeline()
pipeline.full_refresh()
```

## Streamlit App

```bash
pip install -e ".[app]"
streamlit run app/app.py
```
