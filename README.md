# second-project

FastAPI service designed for AWS Lambda deployment.

## Development

1. Install dependencies:
   ```bash
   poetry install
   ```

2. Run locally:
   ```bash
   poetry run uvicorn src.second-project.main:app --reload
   ```

3. Run tests:
   ```bash
   poetry run pytest
   ```

## Deployment

This service is designed to be deployed to AWS Lambda using a framework like AWS SAM or Serverless Framework.
