# 60-90 Second Demo Video Script

**Preparation Before Recording:**
1. Have two tasks already created in your app (so the list isn't empty). 
   - Task 1: "Morning Standup" (Status: "To-Do")
   - Task 2: "Write Documentation" (Status: "In Progress")
2. Open your screen recording software (Loom, OBS, or just your phone's screen recorder if you're demonstrating on mobile).
3. Take a deep breath! You've got this.

---

### Segment 1: Introduction & Read (0:00 - 0:10)
**Visual:** Show the main Task List screen with your 2 pre-existing tasks. Scroll up and down slightly. Tap the "In Progress" filter chip, then tap "All" to show the filter works.
**Audio:** *"Hi Nilay! For the Flodo take-home assignment, I chose Track A for a full-stack experience using Flutter and FastAPI. Here is the main list view where you can see my tasks, complete with working status filters and a debounced search bar."*

### Segment 2: Create & Drafts (0:10 - 0:25)
**Visual:** Tap the '+' floating action button. Type "Code Review" as the title. Type "Review PRs" as the description. Then, tap the **Back** arrow (or swipe back) to cancel. Tap '+' again to open the form—the text is still there! 
**Audio:** *"Let's create a task. If I start typing a title and description, but accidentally back out of the screen... when I open it back up, my draft is persisted using SharedPreferences so no data is lost."*

### Segment 3: The 2-Second Delay & Blocked-By Logic (0:25 - 0:45)
**Visual:** On that same draft, scroll down to the "Blocked By" dropdown and select "Write Documentation". Hit **Save**. The 2-second loading spinner will appear. Once it saves, point out that the new card is greyed out with a lock icon.
**Audio:** *"I'm going to set this task to be blocked by 'Write Documentation' and hit Save. Notice the intentional 2-second simulated delay and loading state, preventing double-submissions. Our new task is now visually blocked and greyed out because its parent task isn't done yet."*

### Segment 4: Update & Deletion (0:45 - 0:55)
**Visual:** Tap the status chip for "Write Documentation" and change it directly to "Done". The blocked "Code Review" task instantly unlocks and returns to full color. Then, tap the `X` or delete icon on the "Morning Standup" task and confirm the deletion.
**Audio:** *"If I update the blocking task to 'Done', the dependent task instantly unlocks. Deleting tasks is also seamless and updates the database immediately."*

### Segment 5: Stretch Goal & Technical Decision (0:55 - 1:20)
**Visual:** Create a new task called "Check Emails". Toggle "Recurring Task" ON and select "Daily". Save it (wait 2 secs). Then, instantly change its status to "Done". A brand new "Check Emails" task for tomorrow will immediately pop into the list.
**Audio:** *"For my stretch goal, I implemented automated recurring tasks. If I create a daily recurring task and mark it 'Done', a fresh copy for tomorrow is automatically generated. The technical decision I'm most proud of is handling this recurring logic entirely on the Python backend rather than the Flutter frontend. This guarantees that whether a user updates a task via the mobile app, a web app, or a direct API call, the database perfectly maintains consistency without relying on client-side logic. Thanks for reviewing!"*
