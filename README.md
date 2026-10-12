# BudgetBlud 💸 

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white)
![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/Platform-iOS-000000?logo=apple&logoColor=white)
![Group Project](https://img.shields.io/badge/Type-Group_school_project-lightgrey)
[![Made with AI](https://img.shields.io/badge/Made_with-AI_assistance-blue)](#ai-credits)
 
BudgetBlud is a Flutter budgeting application developed as a **group school project**. It helps users organize their finances with budgeting tools and Supabase-backed data synchronization.

> **Project context:** Academic group project. My contributions focused on the Flutter frontend and Supabase integration. The app was developed collaboratively, so this README distinguishes my contributions from the project's overall functionality.

## Project Overview

BudgetBlud is designed to help users track and manage their budgets through a mobile interface. The project combines a Flutter/Dart frontend with Supabase services for backend functionality and data synchronization.

## Features

The project README describes the following functionality. Confirm each feature against the current app before presenting it as complete:

- Budgeting and expense-management workflows
- Flutter-based mobile interface
- Supabase integration and data synchronization

Add more specific features here only if they are implemented in the current version, such as transaction categories, spending summaries, budget limits, or account management.

## My Contributions

As a member of the project team, my contributions included:

- Developing parts of the Flutter frontend.
- Working on Supabase integration and synchronization.
- Helping connect the mobile interface to backend data.

The overall application was built collaboratively with my teammates.

## Tech Stack

| Area | Technology |
|---|---|
| Mobile application | Flutter, Dart |
| Backend and data services | Supabase |
| Source control | Git, GitHub |

## Platform and Languages
 
| | |
| --- | --- |
| **Language** | Dart (all application code is in `lib/`) |
| **Framework** | Flutter, Dart SDK `^3.8.1` |
| **Target platforms** | **Android** and **iOS** mobile devices. The repository contains both Android and iOS projects (iOS deployment target 12.0), with launcher icons configured for both. |
| **Other Flutter folders** | `web/`, `windows/`, `linux/`, and `macos/` are default Flutter scaffolding and are not a target of this project. |
 

## Possible Future Improvements
 
- **Safer configuration:** move the Supabase URL and anon key out of source code (for example with `--dart-define`) and confirm Row Level Security is enabled on every table.
- **Recurring expenses and bill reminders:** automatic monthly entries for rent, subscriptions, and bills.
- **Savings goals:** targets with progress tracking.
- **More currencies and date ranges:** currency selection and custom report periods.
- **Spending insights:** month-over-month comparison and over-budget alerts per category.
- **Data backup:** import from CSV in addition to the existing export.
- **Quality:** add widget and provider tests and run `flutter analyze` in a GitHub Actions workflow.
```

## Run Locally

### Requirements

- Flutter SDK compatible with the project's `pubspec.yaml`
- Dart SDK version supported by that Flutter installation
- A Supabase project and the required project configuration
- Android Studio, VS Code, or another Flutter-supported development environment

### Setup

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure the Supabase URL and public client key using the configuration approach expected by this project. Check the source code for the exact configuration fields before running it.

   **Security:** Never commit Supabase service-role keys, passwords, access tokens, or other secrets. A client-side application should use only the appropriate public client configuration and rely on correctly configured Supabase Row Level Security (RLS) policies to protect data.

4. Run the application on a supported emulator or device:

   ```bash
   flutter run
   ```

> Setup may require additional project-specific configuration. Update these instructions with the exact steps and filenames after verifying them on a clean checkout.

## Validation

Before publishing an updated version, run:

```bash
flutter analyze
flutter test
```

Document the actual results below after running the commands. If automated tests have not been written yet, say so honestly and list the manual checks performed instead.

- Static analysis: [Not run / Passed / Issues found]
- Automated tests: [Not run / Passed / Issues found]
- Manual checks: [List checks actually performed]

## What I Learned

Through this group project, I gained experience contributing to a Flutter application, integrating a mobile frontend with Supabase, coordinating development with teammates, and debugging application behavior.

## Academic Project

Developed collaboratively as a school project at **Holy Angel University**.

This project demonstrates my experience with mobile application development and backend-service integration in a team environment. My individual contributions were focused on the Flutter frontend and Supabase integration.

```markdown
## AI Credits
 
AI tools were used to help with parts of this project and to draft this README.
 
<!-- Edit to name the tools and what they were used for. -->
```
 
---
