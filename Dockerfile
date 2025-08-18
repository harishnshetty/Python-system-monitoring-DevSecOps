# =========================
# Build stage
# =========================
FROM python:3.12-slim AS builder

WORKDIR /app

# Install system packages required to build Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    python3-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements for caching
COPY src/requirements.txt .

# Create virtualenv and install Python dependencies
RUN python -m venv /app/venv \
    && /app/venv/bin/pip install --upgrade pip \
    && /app/venv/bin/pip install -r requirements.txt

# =========================
# Final stage
# =========================
FROM python:3.12-slim

WORKDIR /app

# Copy virtualenv and source code
COPY --from=builder /app/venv /app/venv
COPY src/ /app/src/

ENV PATH="/app/venv/bin:$PATH"

# Expose Flask default port
EXPOSE 5000

# Run Flask app
CMD ["python", "src/run.py"]
