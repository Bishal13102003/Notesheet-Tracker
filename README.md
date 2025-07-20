# 📄 Notesheet Tracker

A role-based notesheet submission and review system built with **Flutter Web** and **Supabase**.

> 🚀 Aimed at streamlining internal organizational workflows for submitting, reviewing, and approving notesheets. Supports three user roles: **Requester**, **Reviewer**, and **Admin**.

---

## 🌐 Live Demo
Coming Soon…

---

## ✨ Features

### ✅ User Authentication
- Email/password-based sign-up and login (Supabase Auth)
- Email verification support
- Role-based dashboard access: Requester, Reviewer, Admin

### 📥 Notesheet Management
- Create and submit notesheets with:
  - Title, description, urgency, deadline
  - PDF upload and preview
- Upload PDFs to Supabase storage
- View submission success/failure messages

### 🔍 Reviewer Dashboard
- View pending and in-review notesheets
- See status chips (e.g., Pending, In Review)
- Comment and approve functionality (planned)

### 🛠 Admin Dashboard
- Monitor system stats (users, departments, submissions)
- View recent activity logs (login, submissions, etc.)
- User and department management (planned)

### 🎨 Modern UI
- Responsive layout (mobile & web friendly)
- Material 3 design (light theme)
- Card-based layout for clean UX
- Friendly error messages & loading indicators

---

## 🏗 Tech Stack

| Frontend | Backend |
|----------|---------|
| [Flutter Web](https://flutter.dev) | [Supabase](https://supabase.com) |
| Dart | Supabase Auth |
| Material 3 | Supabase Realtime DB |
| File Picker | Supabase Storage |

---

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/your-username/notesheet-tracker.git
cd notesheet-tracker
