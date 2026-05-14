# LearnAI — Video Presentation Script

Target: 8–9 minutes | Format: Live demo + face + audio

---

## [0:00 – 0:20] Hook

> "I built LearnAI — you type any topic, and the app generates a full interactive story with chapters, scenes, and quests, all graded in real time by AI. Let me show you."

*[Start screen recording. Open the app at localhost:4000. Don't wait — go straight to register.]*

---

## [0:20 – 1:20] Register + Google OAuth

*[Navigate to /users/register]*

> "Fresh account, registering now."

*[Fill in email and password, submit. Show the welcome flash.]*

> "There's also Google OAuth — one click, seamlessly creates or finds the user in the database."

*[Click the Google sign-in button briefly to show it exists. You don't need to complete it — just demonstrate it's there.]*

---

## [1:20 – 4:20] Create a Story — Live AI Generation

*[Navigate to /stories/new]*

> "This is the story creation page. I'll type a topic."

*[Type something like: "The French Revolution"]*

> "Hit create — and now watch."

*[Submit the form. The full-screen progress feed appears.]*

*[While the steps stream in, narrate calmly — one sentence per beat, don't rush:]*

> "Under the hood, this spawns a supervised background Task that calls the AI API."

*[pause — let a step or two land]*

> "Each step it completes, it broadcasts a progress event over Phoenix PubSub."

*[pause]*

> "The LiveView is subscribed to that topic — it receives the message and updates the UI. No polling. No JavaScript. Just Elixir message passing."

*[pause — let it finish generating]*

*[When done, the page navigates to the story view automatically.]*

---

## [4:20 – 4:50] Skill Tree

*[You are now on /stories/:id]*

> "Here's the generated story — chapters and scenes laid out as a skill tree. Scenes unlock sequentially. You can't skip ahead."

*[Click on a locked scene to show it redirects. Click on the first unlocked scene.]*

---

## [4:50 – 6:50] Complete a Scene — All 3 Quest Types

*[You are now on /stories/:story_id/scenes/:id]*

> "Each scene has a set of quests. Three types."

**Multiple choice:**

*[Read the question, click an answer, submit.]*

> "Multiple choice — instant deterministic grading."

*[Hit next quest.]*

**Fill in the blank:**

*[Type an answer, submit.]*

> "Fill in the blank — same thing, checked against the correct answer."

*[Hit next quest.]*

**Short answer:**

*[Type a short answer, submit.]*

> "Short answer — this one goes to the AI to grade."

*[Pause while AI grades. Let the spinner breathe. Don't fill the silence.]*

*[Feedback appears.]*

> "AI feedback, is_correct flag, all recorded in the database."

*[Hit complete scene.]*

---

## [6:50 – 7:20] Profile + Chart

*[Navigate to /profile]*

> "The profile page tracks XP over time. That data point we just earned is already here."

*[Point to the Chart.js line chart.]*

> "Chart.js hooked into a LiveView push_event — the server pushes the data, the JS hook renders it."

---

## [7:20 – 7:50] Dark Mode + Mobile

*[Click the dark mode toggle in the navbar.]*

> "Dark mode — persisted to localStorage with a FOUC-prevention script in the HTML head so there's no white flash on load."

*[Resize the browser window to ~320px width.]*

> "Mobile — hamburger replaces the full nav, no horizontal scrolling, works down to 320 pixels."

*[Resize back to normal.]*

---

## [7:50 – 9:20] Lessons Learned

*[Switch to slides or just talk to camera — 2 slides max]*

---

### Lesson 1 — From Class: LiveView + PubSub Decoupling

> "The class taught PubSub as a broadcast mechanism. What I actually learned building this is what that separation buys you. The background Task that calls the AI API has zero knowledge of the UI. It just publishes on a topic. The LiveView subscribes and reacts. Neither side knows the other exists. That's what makes async work clean in Phoenix — you can swap, restart, or crash either side without touching the other."

---

### Lesson 2 — From Project: Abstract Your AI Dependency

> "Calling an AI API directly throughout your code is a trap. You can't test without a real API key, every test hits the network, and switching providers means touching everything. I defined a GeneratorPort behaviour — two callbacks, generate_story and grade_answer. OpenAIAdapter for production. StubAdapter for tests, returns hardcoded data. The entire app calls AI.generate_story — it has no idea which adapter is running. Swapping providers is one config line. Tests run instantly with zero network calls. That's why we have 99.3% test coverage."

*[Optional: briefly show the generator_port.ex file — 10 seconds, no explanation needed beyond what you just said.]*

---

## [9:20 – 9:35] Wrap

> "LearnAI — 99.3% test coverage, 7 optional rubric items, zero compile warnings. Thanks."

*[Stop recording.]*

---

## Notes

- If AI generation finishes faster than expected, slow down narration during the skill tree and scene sections — don't rush to fill the lost time.
- If AI is slow (> 90 sec), keep narrating the PubSub explanation at a relaxed pace. The visual is interesting enough to hold attention.
- Do not read this script word for word. Use it as beats. Know the flow, not the sentences.
- Record at a display scale where no more than 30 lines of code are visible fullscreen.
