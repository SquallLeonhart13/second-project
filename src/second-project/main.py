from fastapi import FastAPI
from mangum import Mangum

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello from Lambda!"}

# Handler for AWS Lambda
handler = Mangum(app)
