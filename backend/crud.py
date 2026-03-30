from datetime import timedelta
from sqlalchemy.orm import Session
from sqlalchemy import or_

from models import Task
from schemas import TaskCreate, TaskUpdate


def get_tasks(db: Session, search: str | None = None, status: str | None = None) -> list[Task]:
    """Fetch all tasks with optional search (by title) and status filter."""
    query = db.query(Task)

    if search:
        query = query.filter(Task.title.ilike(f"%{search}%"))

    if status:
        query = query.filter(Task.status == status)

    return query.order_by(Task.created_at.desc()).all()


def get_task(db: Session, task_id: int) -> Task | None:
    """Fetch a single task by ID."""
    return db.query(Task).filter(Task.id == task_id).first()


def create_task(db: Session, task_data: TaskCreate) -> Task:
    """Create a new task."""
    db_task = Task(
        title=task_data.title,
        description=task_data.description,
        due_date=task_data.due_date,
        status=task_data.status.value,
        blocked_by_id=task_data.blocked_by_id,
        is_recurring=task_data.is_recurring,
        recurrence_type=task_data.recurrence_type.value if task_data.recurrence_type else None,
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task


def update_task(db: Session, task_id: int, task_data: TaskUpdate) -> tuple[Task | None, Task | None]:
    """
    Update an existing task. Returns (updated_task, new_recurring_task).
    If a recurring task is marked Done, auto-creates the next occurrence.
    """
    db_task = db.query(Task).filter(Task.id == task_id).first()
    if not db_task:
        return None, None

    old_status = db_task.status
    update_dict = task_data.model_dump(exclude_unset=True)

    # Convert enum values to strings for DB storage
    if "status" in update_dict and update_dict["status"] is not None:
        update_dict["status"] = update_dict["status"].value
    if "recurrence_type" in update_dict and update_dict["recurrence_type"] is not None:
        update_dict["recurrence_type"] = update_dict["recurrence_type"].value

    for key, value in update_dict.items():
        setattr(db_task, key, value)

    db.commit()
    db.refresh(db_task)

    # --- Recurring Task Logic (Stretch Goal 2) ---
    new_task = None
    if (
        db_task.is_recurring
        and db_task.recurrence_type
        and old_status != "Done"
        and db_task.status == "Done"
    ):
        # Calculate next due date
        if db_task.recurrence_type == "Daily":
            next_due = db_task.due_date + timedelta(days=1)
        else:  # Weekly
            next_due = db_task.due_date + timedelta(weeks=1)

        new_task = Task(
            title=db_task.title,
            description=db_task.description,
            due_date=next_due,
            status="To-Do",
            blocked_by_id=None,
            is_recurring=True,
            recurrence_type=db_task.recurrence_type,
        )
        db.add(new_task)
        db.commit()
        db.refresh(new_task)

    return db_task, new_task


def delete_task(db: Session, task_id: int) -> bool:
    """Delete a task. Also clears blocked_by references pointing to this task."""
    db_task = db.query(Task).filter(Task.id == task_id).first()
    if not db_task:
        return False

    # Clear any blocked_by references to this task
    db.query(Task).filter(Task.blocked_by_id == task_id).update(
        {"blocked_by_id": None}, synchronize_session="fetch"
    )

    db.delete(db_task)
    db.commit()
    return True
