# Full-Stack Game Automation & Management System with Searchable FAQ

## 1. Overview

This system allows administrators and users to manage multiple online games, automate actions, and access a searchable knowledge base (FAQ & discussions). The main features include:

- Generic multi-game automation UI
- Automation backend using Node.js + Playwright
- Shared database (Supabase) for tasks, users, results, and knowledge base
- CRUD operations for games and player data
- Searchable FAQ and discussion module
- Flutter frontend for control and monitoring

---

## 2. Features

### 2.1 Frontend (Flutter / Next.js)
- Dashboard to:
  - Select a game from available games
  - Enter player username
  - Perform actions: login, fetch balance, recharge, freeplay check
  - View results: balance, freeplays, cashouts
- CRUD for:
  - Games (add, edit, delete)
  - Player profiles
- Trigger automation tasks
- Searchable FAQ and discussion module
- Display logs and results

### 2.2 Backend (Node.js)
- API server exposing endpoints for:
  - `/task` – run automation task for a user/game
  - `/games` – CRUD operations for game configurations
  - `/users` – CRUD operations for player data
  - `/faqs` – manage FAQ questions & answers
  - `/discussions` – manage user/admin discussions
- Automation service using **Playwright**:
  - Open browser (headless)
  - Navigate to game site
  - Fill login form (username, optional password)
  - Perform actions (recharge, fetch balance)
  - Return results to frontend
- Health checks for automation tasks
- Task logging

### 2.3 Database (Supabase)
- Tables:
  - `games`: id, name, URL, selectors (login, balance, recharge, etc.)
  - `users`: id, username, game_id, last_action
  - `tasks`: id, user_id, game_id, action, result, timestamp
  - `faqs`: id, question, answer, tags, game_id, approved, created_at, updated_at
  - `discussions`: id, user_id, content, game_id, parent_id, approved, created_at, updated_at
- Stores:
  - Game configurations
  - Player information
  - Task history
  - Logs
  - FAQ & discussion content

### 2.4 Multi-Game Support
- Each game has a config:
  - URL
  - Login selectors
  - Balance selectors
  - Recharge selectors
- UI is generic → dynamically selects game config

### 2.5 Automation Workflow
1. Frontend sends request: username + game + action
2. Node.js backend:
   - Loads game config
   - Launches headless browser via Playwright
   - Logs in with username
   - Performs requested action
   - Stores result in Supabase
3. Frontend fetches results from Supabase and displays

---

## 3. FAQ & Discussion Module

### 3.1 Features
- Admins can:
  - Add/edit/delete FAQs
  - Approve or reject content
  - Tag questions for search (e.g., “freeplay”, “NFT”, “cashout”)
- Users can:
  - View FAQs
  - Post discussion questions
  - Reply to existing threads
  - Search all FAQs and discussions
- Content searchable by:
  - Keywords
  - Tags
  - Game
- Approved answers can be copied to clipboard for practical use

### 3.2 Database Schema

#### Table: `faqs`
| Column        | Type      | Description |
|---------------|-----------|-------------|
| id            | uuid      | Primary key |
| question      | text      | FAQ question |
| answer        | text      | Approved answer |
| tags          | text[]    | Tags (freeplay, NFT, cashout) |
| game_id       | uuid      | Related game |
| approved      | boolean   | Admin approval status |
| created_at    | timestamp | Creation time |
| updated_at    | timestamp | Last updated |

#### Table: `discussions`
| Column        | Type      | Description |
|---------------|-----------|-------------|
| id            | uuid      | Primary key |
| user_id       | uuid      | Who posted |
| content       | text      | Discussion content |
| game_id       | uuid      | Related game (optional) |
| parent_id     | uuid      | For replies / threads |
| approved      | boolean   | Admin approval |
| created_at    | timestamp | Timestamp |
| updated_at    | timestamp | Timestamp |

### 3.3 API Endpoints

#### FAQ