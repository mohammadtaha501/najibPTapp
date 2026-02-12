# Gap Analysis: PT Programme Mobile Application

This document outlines the findings from an audit of the current implementation compared to the **Business Requirements Document (BRD v1.0)**.

## Overview
The application currently covers the vast majority of core functional requirements, including role-based access, client management, exercise library, program creation/assignment, workout logging, and progress analytics.

## Identified Gaps

### 1. Client Information Editing (Feature 6.2)
*   **Requirement**: Coach can edit client profile information (Name, Email, Phone, Notes).
*   **Current State**: Coach can reset passwords, block, or delete clients, but there is no interface to edit the client's basic profile details (Name/Phone) after the account is created.

### 2. Rest Time Visibility & Timer (Feature 6.3, 6.4)
*   **Requirement**: Each exercise configuration includes "Rest time (in seconds)".
*   **Current State**: While `restTime` is stored in the `Exercise` model, it is not currently displayed to the client on the `ExerciseDetailLoggingScreen`, nor is there a countdown timer for rest periods as implied by realistic gym use.

### 3. General Announcements (Feature 11.1)
*   **Requirement**: Coach can send "General announcements from coach" to all clients.
*   **Current State**: No global announcement or broadcasting system is implemented. Interaction is currently limited to 1-to-1 chat.

### 4. Real-time Scheduled Reminders (Feature 11.1)
*   **Requirement**: "Workout reminders for clients".
*   **Current State**: The `NotificationService` contains mocked methods for scheduling reminders that print to the console. A production-ready background scheduling engine (e.g., `flutter_local_notifications` with `workmanager`) is not yet integrated for offline reminders.

### 5. Multi-Program UI Navigation (Feature 6.2)
*   **Requirement**: "Assign one or multiple programmes per client".
*   **Current State**: The backend supports multiple programs, but the `ClientHomeScreen` is designed to display a single "Current Program." There is no UI for a client to manually toggle between multiple active programs if they have more than one assigned simultaneously.

### 6. Reps Range Support (Feature 6.4)
*   **Requirement**: "Reps (range support, e.g. 8–12)".
*   **Current State**: The `reps` field in the model is a String and supports range input (e.g., "8-12"), but the logging screen currently treats it as a single target value for auto-populating set logs.

## Conclusion
The project is in a highly functional state. Addressing the **Client Editing** and **Rest Timer** gaps would be the highest priority for the next development phase to reach "Initial Release" parity as defined in the BRD.
