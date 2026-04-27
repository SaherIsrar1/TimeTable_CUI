# CUI Timetable App - Development Overview

A smart, beautifully designed timetable application for students and teachers of COMSATS University Islamabad (CUI). The app features real-time class tracking, intelligent notifications, and classroom availability checking to streamline campus life.

## 🚀 Special Feature: Smart Class Assistant

This app includes a unique scheduling and notification system that allows users to:
- **Never Miss a Class** — Get automated local notifications exactly 10 minutes before every class.
- **Find Free Classrooms** — Dynamically calculate and discover available free slots based on real-time data.
- **Role-based Views** — Tailored 3-step configuration workflows for both Students and Teachers.
- **Quick Search** — Search for teachers and students with an intuitive "Recently Searched" history.
- **Interactive Maps** — Navigate the campus easily using integrated CartoDB Voyager maps.

---

## 🎯 Current Status

### ✅ **Backend & Data Integration: 100% Complete**
- Firebase Firestore integration for real-time timetable data
- Firebase Authentication
- Local storage using `shared_preferences` and `sqflite`
- Timezone-aware local notifications (`flutter_local_notifications`)

### ✅ **Frontend UI: 95% Complete**
- Redesigned with a premium **Navy & Sage** color palette
- Instagram-style skeleton loading UI for seamless data fetching
- Clean, clutter-free MVVM architecture (Provider)
- CartoDB Voyager map tiles integration

### ⚠️ **Ongoing Polish: 5% Complete**
- Refining the background processing logic for push notifications
- Perfecting map interactions and UI responsiveness
- Final code cleanups for the Provider architecture refactor

---

## 🔥 Priority Tasks

### **This Week: Notification Stability & UI Polish**

1. **Optimize Notification Service** (`lib/services/notification_service.dart`)
   - Ensure the `uiLocalNotificationDateInterpretation` parameter is correctly configured for `zonedSchedule`.
   - Verify notifications trigger reliably even when the app is backgrounded or terminated.

2. **Enhance Search Bar Functionality**
   - Solidify the "recently searched" history logic.
   - Refine filtering accuracy for teachers and students.

3. **Free Classroom Logic**
   - Ensure dynamic availability calculations perform efficiently over Firestore streams.
   - Optimize the UI presentation of available rooms.

---

## 🚀 Quick Start

### **Prerequisites**
- Flutter SDK (`^3.9.2`)
- Dart SDK
- Android Studio / VS Code
- A configured Firebase project

### **Installation**

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd timetable

# 2. Install dependencies
flutter pub get

# 3. Setup Firebase
# Ensure your google-services.json (Android) and GoogleService-Info.plist (iOS) are properly placed.

# 4. Run the app
flutter run
```

---

## 🛠️ Tech Stack

### **Core**
- **Framework:** Flutter (Dart)
- **Architecture:** MVVM (Model-View-ViewModel)
- **State Management:** Provider (`provider: ^6.1.5`)

### **Backend & Storage**
- **Database:** Firebase Cloud Firestore
- **Authentication:** Firebase Auth
- **Local Caching:** Shared Preferences, Sqflite

### **Key Packages**
- **Notifications:** `flutter_local_notifications` & `timezone`
- **UI Assets:** `cupertino_icons`, `flutter_spinkit`
- **Maps:** CartoDB Voyager integration via `webview_flutter` or similar map packages

---

## 📊 Feature Overview

### **Implemented Core Features**
✅ MVVM Architecture refactor completed
✅ Role-based onboarding (Teachers & Students)
✅ Real-time timetable fetching from Firestore
✅ Local Notifications (10 minutes prior to class)
✅ Free classroom availability tracker
✅ Teacher/Student Search with History
✅ Custom App Icon & Splash branding

### **Implemented UI Enhancements**
✅ "Navy & Sage" color palette applied
✅ Instagram-style skeleton loaders
✅ Decluttered UI (Drawer navigation removed in favor of clean routing)
✅ Premium map aesthetic using CartoDB Voyager

### **Missing / Future Features**
❌ Advanced Analytics Dashboard
❌ Offline mode for viewing previously cached timetables
❌ Cross-platform Web / Desktop support

---

## 🎯 Development Roadmap

### **Phase 1: Core Architecture & Data** ✅
- Firebase integration
- Basic UI layout
- Raw data fetching

### **Phase 2: State Management & Features** ✅
- Migration from `setState` to `Provider` (MVVM)
- Search functionality and free slot calculation
- Map integrations

### **Phase 3: Notifications & UI Polish** ← **YOU ARE HERE**
- Fixing `flutter_local_notifications` timezone configurations
- Implementing the Navy & Sage redesign
- Adding skeleton loaders

### **Phase 4: Launch & Optimization**
- Exhaustive background notification testing
- App store deployment prep
- Performance and memory profiling

---

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/AmazingFeature`)
2. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
3. Push to the branch (`git push origin feature/AmazingFeature`)
4. Open a Pull Request

---

## 📝 Notes

**Strengths:**
- Robust and decoupled MVVM architecture
- Beautiful, modern, and user-centric UI
- Practical and highly useful tool for the CUI ecosystem

**Next Action:**
Ensure `lib/services/notification_service.dart` builds without errors and test the background notification triggers thoroughly.
