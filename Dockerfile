# Use Python 3.12 slim image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install poetry 1.8.5
RUN pip install "poetry==1.8.5"

# Copy poetry files
COPY pyproject.toml poetry.lock ./

# Configure poetry
RUN poetry config virtualenvs.create false \
    && poetry config installer.max-workers 10

# Install dependencies
RUN poetry install --no-interaction --no-ansi --no-root

# Copy application code
COPY ./src/second-project /app/second-project

# Set environment variables
ENV PORT=8080

# Expose the port
EXPOSE 8080

# Command to run the application
CMD ["poetry", "run", "uvicorn", "second-project.main:app", "--host", "0.0.0.0", "--port", "8080"]