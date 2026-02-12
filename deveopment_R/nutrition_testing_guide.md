# Nutrition Feature Testing Guide

This guide outlines how to verify the **Nutrition Card** on the Client Home Screen, ensuring it correctly reflects the coach's guidance and view status.

## Feature Overview
The Nutrition Card is a dynamic element on the Client Home Screen that provides a shortcut to the coach's nutrition guidelines. It is designed to be a passive reminder that updates its status based on coach activity and client views.

---

## Test Scenarios

### 1. No Nutrition Advice (Hidden State)
**Setup:** A client with no active nutrition note assigned by the coach.
- **Action:** Log in as the Client or navigate to the Home Screen.
- **Expected Result:** The "Nutrition Guideline" card is **NOT** visible.

### 2. New Nutrition Advice (Status: NEW)
**Setup:** Coach creates and activates a new nutrition note for the client.
- **Coach Action:** 
    1. Go to Client Profile -> Nutrition.
    2. Create a new note.
    3. Tap "Activate".
- **Client Action:** Log in as the Client.
- **Expected Result:**
    - The "Nutrition Guideline" card appears.
    - Status badge shows **NEW** in the primary brand color.
    - The card has a subtle primary color glow/border.

### 3. Transition to Ongoing (Status: ONGOING)
**Setup:** Client views the "New" nutrition advice for the first time.
- **Client Action:** 
    1. Tap the Nutrition Card or "View Details" CTA.
    2. View the Nutrition Guideline screen.
    3. Navigate back to the Home Screen.
- **Expected Result:**
    - Status badge changes to **ONGOING** in green.
    - The card glow/border is removed (default style).

### 4. Coach Updates Advice (Status: UPDATED)
**Setup:** Coach edits an already active and viewed nutrition note.
- **Coach Action:**
    1. Go to Client Profile -> Nutrition.
    2. Edit the active note (change title, summary, or content).
    3. Tap "Save Note".
- **Client Action:** Navigate to the Home Screen.
- **Expected Result:**
    - Status badge changes to **UPDATED** in orange.
    - The card visually highlights with an orange border.

### 5. Transition Back to Ongoing (Status: ONGOING)
**Setup:** Client views the updated advice.
- **Client Action:** 
    1. Tap the Nutrition Card.
    2. Navigate back to the Home Screen.
- **Expected Result:**
    - Status badge returns to **ONGOING** in green.

---

## Data Verification for Coaches
Coaches can verify engagement directly from their management dashboard:
1. **Navigate to Client Profile -> Nutrition.**
2. **Observe the Note Card:** 
    - Verify the "Viewed" timestamp matches the exact time the client opened the note.
    - If never viewed, it should show "Not viewed yet" in red.

## UI/UX Constraints
- **Zero Input:** Verify the client screen is read-only.
- **Single Active Note:** Verify that activating a second note in the Coach dashboard automatically deactivates the previous one.
- **Persistence:** Verify that the card remains visible even if the client's training program is changed or deleted.
