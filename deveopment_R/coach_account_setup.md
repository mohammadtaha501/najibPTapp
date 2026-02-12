# Manual Coach Account Creation Guide

Since in-app registration is disabled for security and elite access control, Coach accounts must be created manually via the Firebase Console. Follow these steps to set up a new Coach.

## Step 1: Create Authentication User
1. Open the **[Firebase Console](https://console.firebase.google.com/)**.
2. Select your project: `nijib-trainer` (or your project name).
3. Navigate to **Build** > **Authentication** > **Users** tab.
4. Click the **Add user** button.
5. Enter the **Email** and **Password** for the coach.
6. Click **Add user**.
7. **CRITICAL**: Copy the **User UID** generated for this user (it looks like a long string of random characters).

## Step 2: Create Firestore Profile
1. Navigate to **Build** > **Firestore Database**.
2. Select the **Data** tab.
3. Locate the `users` collection.
4. Click **Add document**.
5. In the **Document ID** field, paste the **User UID** you copied in Step 1.
6. Add the following fields to the document:

| Field Name | Type | Value | Notes |
| :--- | :--- | :--- | :--- |
| `uid` | string | [Paste UID] | Must match the Document ID. |
| `email` | string | coach@example.com | Use the same email from Step 1. |
| `name` | string | John Doe | Coach's full name for the UI. |
| `role` | number | `0` | **0** is for Coach, **1** is for Client. |
| `phone` | string | +123456789 | (Optional) |

7. Click **Save**.

## Verification
- Once saved, the Coach can log in via the app's home screen using the email and password provided.
- Upon login, they will be directed to the **Trainer Dashboard**, where they can start adding clients and creating programs.

---
> [!IMPORTANT]
> Client accounts do **not** need manual setup. Coaches should create client accounts directly within the app using the **"Add New Client"** button on their dashboard.
