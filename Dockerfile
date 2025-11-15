# Use Python 3.10.19 slim image (locked for reproducibility)
FROM python:3.10.19-slim

# Set working directory
WORKDIR /app

# Install system dependencies and uv
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Copy project files for dependency installation
COPY pyproject.toml .

# Install Python dependencies using uv
RUN uv pip install --system --no-cache -e .

# Copy application files
COPY app_langchain.py .
COPY config.py .

# Create .streamlit directory
RUN mkdir -p .streamlit
COPY .streamlit/config.toml .streamlit/

# Expose Streamlit default port
EXPOSE 8501

# Health check
HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health

# Run Streamlit with LangChain app
ENTRYPOINT ["streamlit", "run", "app_langchain.py", "--server.port=8501", "--server.address=0.0.0.0"]

