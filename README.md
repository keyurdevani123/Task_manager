# Task Manager App

A full-stack Task Management application built with **Flutter** (frontend) and **FastAPI/Python** (backend) with **PostgreSQL** database.

## Track & Stretch Goal

- **Track A**: Full-Stack Builder (Flutter + FastAPI + PostgreSQL)
- **Stretch Goal 2**: Recurring Tasks Logic (Daily / Weekly)

---

## Features

### Core
- ✅ **CRUD Operations**: Create, Read, Update, Delete tasks
- ✅ **Task Data Model**: Title, Description, Due Date, Status, Blocked By
- ✅ **Search & Filter**: Debounced search by title (300ms) + filter by status
- ✅ **Drafts**: Form data persists when app is minimized or user navigates back
- ✅ **Blocked-By Logic**: Tasks blocked by incomplete tasks appear greyed out with lock icon
- ✅ **2-Second Delay**: Simulated on Create & Update with loading state + double-tap prevention

### Stretch Goal — Recurring Tasks
- ✅ **Recurring Toggle**: Daily or Weekly recurrence on task creation
- ✅ **Auto-Generation**: When a recurring task is marked "Done", a new task is auto-created with the due date pushed forward (+1 day / +1 week)
- ✅ **Original Logged**: The completed task remains in the list as "Done"

### UI/UX
- ✅ Dark theme with polished design
- ✅ Smooth transitions and animations
- ✅ Status color coding (blue-violet / amber / green)
- ✅ Inline status change via popup menu
- ✅ Pull-to-refresh
- ✅ Empty and error states

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter & Dart |
| State Management | Provider |
| Backend | Python FastAPI |
| Database | PostgreSQL |
| ORM | SQLAlchemy |
| Draft Persistence | SharedPreferences |

---

## Setup Instructions

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.5+)
- [Python 3.10+](https://www.python.org/downloads/)
- [PostgreSQL](https://www.postgresql.org/download/)

### 1. Database Setup

```bash
# Create the database
psql -U postgres
CREATE DATABASE taskmanager;
\q
```

### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Configure database (edit .env file)
# DATABASE_URL=postgresql://postgres:your_password@localhost:5432/taskmanager

# Run the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`  
Interactive docs at `http://localhost:8000/docs`

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
flutter pub get

# Run the app
flutter run
# or for a specific platform:
flutter run -d windows
flutter run -d chrome
```

> **Note**: The Flutter app connects to `http://localhost:8000` by default.  
> To change this, edit `lib/services/api_service.dart` → `baseUrl`.

---

## Project Structure

```
Task_Manager/
├── backend/
│   ├── main.py             # FastAPI app + routes
│   ├── models.py           # SQLAlchemy Task model
│   ├── schemas.py          # Pydantic request/response schemas
│   ├── crud.py             # CRUD operations + recurring logic
│   ├── database.py         # PostgreSQL connection
│   ├── .env                # Database URL config
│   └── requirements.txt    # Python dependencies
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart                       # App entry point
│   │   ├── models/task.dart                # Task data model
│   │   ├── services/
│   │   │   ├── api_service.dart            # REST API client
│   │   │   └── draft_service.dart          # Draft persistence
│   │   ├── providers/task_provider.dart    # State management
│   │   ├── screens/
│   │   │   ├── task_list_screen.dart       # Main list view
│   │   │   └── task_form_screen.dart       # Create/Edit form
│   │   ├── widgets/
│   │   │   ├── task_card.dart              # Task card component
│   │   │   ├── status_filter.dart          # Status filter chips
│   │   │   └── search_bar.dart             # Debounced search
│   │   └── theme/app_theme.dart            # Dark theme config
│   └── pubspec.yaml
│
└── README.md
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/tasks?search=&status=` | List tasks (with optional filters) |
| GET | `/tasks/{id}` | Get single task |
| POST | `/tasks` | Create task (2s delay) |
| PUT | `/tasks/{id}` | Update task (2s delay) |
| DELETE | `/tasks/{id}` | Delete task |

---

## Key Technical Decisions

1. **Provider for State Management**: Chose Provider over Riverpod/Bloc for simplicity and readability. It provides sufficient capability for this app's scope while keeping the codebase clean.

2. **Server-Side Recurring Logic**: The recurring task auto-generation happens in the backend (`crud.py → update_task`), not the frontend. This ensures data consistency and means the logic works regardless of which client hits the API.

3. **Draft Persistence with SharedPreferences**: Lightweight key-value storage that persists form data when the app lifecycle changes (paused/inactive). The draft is cleared only on successful save.

4. **Debounced Search (300ms)**: Client-side filtering with a 300ms debounce timer prevents excessive re-renders during fast typing, improving UX.

5. **Simulated Delay Server-Side**: The 2-second delay uses `asyncio.sleep(2)` in FastAPI endpoints, keeping it non-blocking and simulating real network latency as specified.

---

## AI Usage Report

AI tools (Claude/Gemini) were used to accelerate development:

### Helpful Prompts
- "Create a FastAPI backend with SQLAlchemy for a task management app with self-referencing blocked_by relationship and recurring task logic"
- "Build a Flutter dark theme with blue-violet accent, card-based design, and proper Material 3 color scheme"

### AI Issues Encountered
- The AI initially suggested using `Color.withOpacity()` which is deprecated in newer Flutter versions. Fixed by using `Color.withValues(alpha: ...)` instead.
- Had to manually adjust the draft persistence timing to ensure `WidgetsBindingObserver` correctly saves on both back-swipe and app minimize.

---

## Demo Video

[Link to demo video on Google Drive]
