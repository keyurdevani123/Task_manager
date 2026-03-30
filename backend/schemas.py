from pydantic import BaseModel, Field
from typing import Optional
from datetime import date, datetime
from enum import Enum


class TaskStatus(str, Enum):
    TODO = "To-Do"
    IN_PROGRESS = "In Progress"
    DONE = "Done"


class RecurrenceType(str, Enum):
    DAILY = "Daily"
    WEEKLY = "Weekly"


# --- Request Schemas ---

class TaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(default="")
    due_date: date
    status: TaskStatus = TaskStatus.TODO
    blocked_by_id: Optional[int] = None
    is_recurring: bool = False
    recurrence_type: Optional[RecurrenceType] = None


class TaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    due_date: Optional[date] = None
    status: Optional[TaskStatus] = None
    blocked_by_id: Optional[int] = None
    is_recurring: Optional[bool] = None
    recurrence_type: Optional[RecurrenceType] = None


# --- Response Schemas ---

class TaskResponse(BaseModel):
    id: int
    title: str
    description: str
    due_date: date
    status: TaskStatus
    blocked_by_id: Optional[int] = None
    is_recurring: bool
    recurrence_type: Optional[RecurrenceType] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class TaskListResponse(BaseModel):
    tasks: list[TaskResponse]
    total: int
