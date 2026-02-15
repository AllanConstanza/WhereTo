# WhereTo — City Explorer App

WhereTo is an iOS travel discovery app built with **SwiftUI**, designed to help users explore major U.S. cities, view local events, and see landmarks.  
The app integrates APIs, geolocation, dynamic images, user authentication, and personalization features.

---

## Features

### **Authentication**
- Firebase Email/Password Login
- Profile screen showing user email
- Profile picture upload (Firestore + Storage)
- Delete Account functionality
- Dark/Light mode toggle (saved per user)

### **City Discovery**
- Browse curated list of major U.S. cities
- Auto-fetch Wikipedia images for each city
- Geocoding to retrieve real coordinates
- Sorting cities by proximity to user
- City detail screen includes:
  - Wikipedia landmark search
  - Live events (Ticketmaster-ready integration)

### **To-Do List**
- City-specific bucket list items
- Stored per logged-in user

---

## Tech Stack

- **SwiftUI**
- **Firebase Authentication**
- **Firestore**
- **Firebase Storage**
- **Wikipedia REST API**
- **CoreLocation**
- **Async/Await Networking**
- **MVVM structure**

---

## Screenshots

| Home | Details | Live Events | To-Do List | Recently Deleted
|------|---------|---------|---------|---------|


| <img src="https://github.com/user-attachments/assets/5a0a4481-6c6d-4140-8917-6b5fb8c0aaad" width="240" /> | <img src="https://github.com/user-attachments/assets/0322e613-5f48-43a0-b7d3-7d6abed16a2d" width="240" /> | <img alt="Live Events" src="https://github.com/user-attachments/assets/27a5b1ac-8736-48e6-8192-f1660dedeb66" width="240"/> | <img alt="To Do List" src="https://github.com/user-attachments/assets/25534ce5-db7b-4f90-a5d4-ce262fedf167" width="240" /> | <img  alt="Recently Deleted" src="https://github.com/user-attachments/assets/b4775450-6330-4625-a94a-3036bdb4e013" width="240" />



---

## Installation
- Clone the repository
- Open WhereTo.Xcodeproj and add your GoogleService-info.plist to the project 
- Add your API keys inside AppConfig.swift
- run the app on ios simulator 

## Notes
- Profile picture upload requires Firebase Storage enabled 
- Wikipedia images depend on city naming; fallback behavior is included
- Ticketmaster Events require API keys to be activated


