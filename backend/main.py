import asyncio
from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database import engine, get_db, Base
from schemas import TaskCreate, TaskUpdate, TaskResponse, TaskListResponse
import crud

# Create tables on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Task Manager API",
    description="REST API for the Flodo Task Management App",
    version="1.0.0",
)

# CORS — allow Flutter dev servers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- Health Check ----------

@app.get("/health")
def health_check():
    return {"status": "ok"}


# ---------- Task Endpoints ----------

@app.get("/tasks", response_model=TaskListResponse)
def list_tasks(
    search: str | None = Query(None, description="Search tasks by title"),
    status: str | None = Query(None, description="Filter by status: To-Do, In Progress, Done"),
    db: Session = Depends(get_db),
):
    """List all tasks with optional search and status filter."""
    tasks = crud.get_tasks(db, search=search, status=status)
    return TaskListResponse(tasks=tasks, total=len(tasks))


@app.get("/tasks/{task_id}", response_model=TaskResponse)
def get_task(task_id: int, db: Session = Depends(get_db)):
    """Get a single task by ID."""
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.post("/tasks", response_model=TaskResponse, status_code=201)
async def create_task(task_data: TaskCreate, db: Session = Depends(get_db)):
    """Create a new task. Simulates a 2-second processing delay."""
    # Validate blocked_by_id exists if provided
    if task_data.blocked_by_id:
        blocker = crud.get_task(db, task_data.blocked_by_id)
        if not blocker:
            raise HTTPException(status_code=400, detail="Blocked-by task not found")

    # Simulate 2-second delay as required
    await asyncio.sleep(2)

    return crud.create_task(db, task_data)


@app.put("/tasks/{task_id}", response_model=dict)
async def update_task(task_id: int, task_data: TaskUpdate, db: Session = Depends(get_db)):
    """
    Update a task. Simulates a 2-second processing delay.
    If a recurring task is marked Done, returns the newly generated task too.
    """
    # Validate blocked_by_id if being updated
    if task_data.blocked_by_id is not None:
        blocker = crud.get_task(db, task_data.blocked_by_id)
        if not blocker:
            raise HTTPException(status_code=400, detail="Blocked-by task not found")
        if task_data.blocked_by_id == task_id:
            raise HTTPException(status_code=400, detail="A task cannot block itself")

    # Simulate 2-second delay as required
    await asyncio.sleep(2)

    updated_task, new_recurring_task = crud.update_task(db, task_id, task_data)
    if not updated_task:
        raise HTTPException(status_code=404, detail="Task not found")

    response = {
        "task": TaskResponse.model_validate(updated_task).model_dump(mode="json"),
        "new_recurring_task": None,
    }
    if new_recurring_task:
        response["new_recurring_task"] = TaskResponse.model_validate(new_recurring_task).model_dump(mode="json")

    return response


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    """Delete a task by ID."""
    success = crud.delete_task(db, task_id)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found")
    return None
