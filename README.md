# 🏆 Ace Sports Academy Management System

A full-stack sports academy management system built to simplify the management of **sports programs, batch schedules, assistant coaches, student enrollments, and daily attendance**.

The system uses **Django REST Framework** as the backend, **MySQL** for relational data storage, and **Flutter** for the mobile application.

---

## 📌 Project Overview

Ace Sports Academy manages multiple training programs across different athletic fields. Managing students, batches, coaches, schedules, and attendance manually can become difficult as the academy grows.

This project provides a centralized system for managing these operations through a REST-based backend and a Flutter mobile application.

### The system provides:

* Sports and training program management
* Batch scheduling and capacity management
* Assistant coach management
* Student enrollment management
* Daily attendance tracking
* Dashboard statistics
* Search and filtering
* Backend validation
* REST APIs for mobile application communication

---

## 🚀 Features

### ⚽ Sports Management

* Create and manage sports programs
* Store sport names and descriptions
* Validate sport information
* Prevent duplicate sport records

### 📅 Batch Management

* Create training batches
* Configure morning/evening training slots
* Define batch duration
* Set maximum batch capacity
* Validate scheduling information

### 👨‍🏫 Assistant Coach Management

* Manage assistant coach records
* Store contact information
* Track active/inactive status
* Associate coaches with sports

### 👨‍🎓 Student Management

* Maintain student profiles
* Manage student enrollments
* Associate students with batches
* Track active/inactive student status
* Validate enrollment and capacity rules

### 📝 Attendance Management

* Record student attendance
* Track attendance for a selected date
* Support attendance statuses:

  * Present (`P`)
  * Absent (`A`)
  * Late (`L`)

### 📊 Dashboard

The dashboard provides consolidated academy statistics through a single API request, including:

* Total students
* Total coaches
* Total batches
* Attendance statistics
* Other daily academy metrics

### 🔎 Search & Filtering

Backend search functionality allows records to be filtered using fields such as:

* Name
* Phone
* Email
* Sport

---

## 🛠️ Technology Stack

| Layer                | Technology                        |
| -------------------- | --------------------------------- |
| Mobile Application   | Flutter                           |
| Programming Language | Dart                              |
| Backend              | Django REST Framework             |
| Backend Language     | Python                            |
| Database             | MySQL                             |
| API Communication    | REST API                          |
| HTTP Client          | Dart HTTP                         |
| Testing              | Django REST Framework APITestCase |
| Architecture         | Client–Server / REST              |

---

## 🏗️ System Architecture

```text
┌─────────────────────────────┐
│       Flutter Mobile App    │
│          (Dart)             │
└──────────────┬──────────────┘
               │
               │ HTTP / JSON
               ▼
┌─────────────────────────────┐
│      Django REST Framework  │
│                             │
│  Views → Serializers → ORM  │
└──────────────┬──────────────┘
               │
               │ Django ORM
               ▼
┌─────────────────────────────┐
│           MySQL             │
│      Relational Database    │
└─────────────────────────────┘
```

---

## 📁 Project Structure

```text
ace-sports-academy-management-system/
│
├── ace_sports_academy/
│   ├── config/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── ...
│   │
│   ├── apps/
│   │   │
│   │   ├── sports/
│   │   │   ├── models.py
│   │   │   ├── serializers.py
│   │   │   ├── views.py
│   │   │   └── urls.py
│   │   │
│   │   ├── batches/
│   │   │   ├── models.py
│   │   │   ├── serializers.py
│   │   │   ├── views.py
│   │   │   └── urls.py
│   │   │
│   │   ├── coaches/
│   │   ├── students/
│   │   └── attendance/
│   │
│   ├── manage.py
│   └── requirements.txt
│
└── frontend/
    └── Flutter Application
```

---

## 🔌 API Layer

The backend follows REST principles and exposes API endpoints for the different academy modules.

The general request flow is:

```text
Flutter
   │
   │ HTTP Request
   ▼
Django URL Routing
   │
   ▼
API View / ViewSet
   │
   ▼
Serializer
   │
   ▼
Django ORM
   │
   ▼
MySQL
```

The response is then serialized into JSON and returned to the Flutter application.

---

## 🧩 Backend Design

### Models

Django models represent the database entities and relationships.

Major entities include:

```text
Sport
Batch
Coach
Student
Attendance
```

The models are connected using relational database relationships where required.

### Serializers

Django REST Framework serializers are responsible for:

* Converting model objects into JSON
* Converting incoming JSON into validated Python data
* Performing API-level validation

### Views / ViewSets

The API views handle:

* Incoming HTTP requests
* Database operations
* Serializer validation
* API responses

### Django ORM

The project uses Django's ORM instead of writing raw SQL for normal database operations.

---

## 🔐 Validation

The backend implements validation at multiple levels to maintain data consistency.

Examples include:

* Required field validation
* Phone number validation
* Sport name validation
* Unique constraints
* Batch capacity validation
* Enrollment validation
* Scheduling validation

This prevents invalid data from entering the database.

---

## 🔍 Search & Filtering

The backend uses Django REST Framework's search and filtering capabilities to query records efficiently.

Records can be searched using fields such as:

```text
Name
Phone
Email
Sport
```

---

## 📊 Dashboard API

The dashboard combines multiple academy statistics into a single API response.

Instead of making separate requests for every statistic:

```text
Flutter
   │
   └── GET Dashboard API
              │
              ├── Student Count
              ├── Coach Count
              ├── Batch Count
              └── Attendance Statistics
```

This reduces unnecessary network requests from the mobile application.

---

## 🧪 Testing

The backend includes automated API tests using Django REST Framework's `APITestCase`.

The test suite covers areas such as:

* API endpoints
* Model validation
* CRUD operations
* Search functionality
* Backend business rules
* Authentication/permission-related behavior where applicable

---

## 📱 Flutter Application

The Flutter application acts as the client for the Django REST API.

It communicates with the backend through HTTP requests and handles JSON responses.

The application provides an interactive mobile interface for managing academy operations.

---

## ⚙️ Local Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd ace-sports-academy-management-system
```

### 2. Create a virtual environment

```bash
python -m venv venv
```

Activate it on Windows:

```bash
venv\Scripts\activate
```

### 3. Install backend dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure MySQL

Create a MySQL database and configure the database credentials in Django's settings.

### 5. Apply migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

### 6. Run the Django server

```bash
python manage.py runserver
```

The backend will be available at:

```text
http://127.0.0.1:8000/
```

### 7. Run Flutter

Navigate to the Flutter project:

```bash
cd frontend
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

## 🔄 Application Flow

```text
User
 │
 ▼
Flutter Mobile Application
 │
 │ HTTP Request
 ▼
Django REST API
 │
 ▼
Serializer Validation
 │
 ▼
Django ORM
 │
 ▼
MySQL Database
 │
 ▼
JSON Response
 │
 ▼
Flutter UI
```

---

## 🎯 Key Learning Outcomes

This project demonstrates practical experience with:

* Django project architecture
* Django models and relationships
* Database migrations
* Django REST Framework
* REST API development
* Serializers and validation
* Django ORM and QuerySets
* Search and filtering
* Flutter application development
* HTTP API integration
* JSON serialization/deserialization
* Relational database design
* API testing
* Full-stack client-server architecture

---

## 👨‍💻 Author

**Mayur Gardaswar**

B.E. Information Technology Student

---

## ⭐ Project

If you found this project useful, consider giving the repository a ⭐.
