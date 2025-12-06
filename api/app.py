from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routes import health, users, vocabulary, practice, asl_vocabulary

app = FastAPI(
    title="LinguaLearn AI API",
    description="Multi-modal language learning platform",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router, prefix="/api", tags=["health"])
app.include_router(users.router, prefix="/api", tags=["users"])
app.include_router(vocabulary.router, prefix="/api", tags=["vocabulary"])
app.include_router(practice.router, prefix="/api", tags=["practice"])
app.include_router(asl_vocabulary.router, prefix="/api", tags=["asl"])

@app.on_event("startup")
async def startup_event():
    print("LinguaLearn API starting...")

@app.on_event("shutdown")
async def shutdown_event():
    print("LinguaLearn API shutting down...")
