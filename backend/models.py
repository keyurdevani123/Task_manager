from sqlalchemy import Column, Integer, String, Text, Date, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from database import Base


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, default="")
    due_date = Column(Date, nullable=False)
    status = Column(String(20), nullable=False, default="To-Do")  # "To-Do", "In Progress", "Done"
    
    # Blocked-by relationship (self-referencing)
    blocked_by_id = Column(Integer, ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True)
    blocked_by = relationship("Task", remote_side=[id], foreign_keys=[blocked_by_id])
    
    # Recurring task fields
    is_recurring = Column(Boolean, default=False)
    recurrence_type = Column(String(10), nullable=True)  # "Daily" or "Weekly"
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
