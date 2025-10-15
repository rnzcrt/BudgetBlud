# BudgetBlud

A comprehensive budget management mobile application built with Flutter, designed to help users track expenses, set budgets, and manage financial goals effectively.

## Features

- **User Authentication**: Secure login and signup with email verification
- **Budget Management**: Set monthly budgets and category-specific limits
- **Expense Tracking**: Add, edit, and delete expenses with categorization
- **Real-time Sync**: Data synchronization with Supabase backend
- **Multi-language Support**: English, Tagalog, and Spanish localization
- **Dark/Light Theme**: Customizable app appearance
- **Notifications**: Monthly budget reminders and alerts
- **Reports & Analytics**: Visual charts and expense reports
- **Data Export**: Export data to CSV and PDF formats
- **Offline Support**: Local data storage with cloud sync

## Screenshots

(Add screenshots here when available)

## Requirements

- Flutter SDK (^3.8.1)
- Dart SDK (^3.8.1)
- Android Studio or VS Code with Flutter extensions
- Supabase account for backend services

## Setup Instructions

### 1. Prerequisites

Ensure you have Flutter installed on your system:

```bash
flutter doctor
```

### 2. Clone the Repository

```bash
git clone <repository-url>
cd budgetblud
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Supabase Setup

1. Create a new project on [Supabase](https://supabase.com)
2. Go to Settings > API and copy your project URL and anon key
3. Create the following tables in your Supabase database:

#### `budgets` table:
```sql
CREATE TABLE budgets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  total_budget DECIMAL(10,2) NOT NULL DEFAULT 0,
  foods_limit DECIMAL(10,2) NOT NULL DEFAULT 0,
  transportation_limit DECIMAL(10,2) NOT NULL DEFAULT 0,
  shopping_limit DECIMAL(10,2) NOT NULL DEFAULT 0,
  bills_limit DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, month, year)
);
```

#### `expenses` table:
```sql
CREATE TABLE expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

4. Enable Row Level Security (RLS) on both tables
5. Create policies for authenticated users to access their own data

### 5. Environment Configuration

Create a `.env` file in the root directory (or configure environment variables):

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 6. Run the App

For Android:
```bash
flutter run
```

For iOS (macOS only):
```bash
flutter run
```

## Usage Guide

### Getting Started

1. **Launch the App**: Open BudgetBlud on your device
2. **Onboarding**: Follow the welcome screens to understand the app features
3. **Authentication**: Create an account or log in with existing credentials

### Setting Up Your Budget

1. Navigate to the Setup screen
2. Enter your total monthly budget
3. Set category limits for:
   - Foods
   - Transportation
   - Shopping
   - Bills

### Adding Expenses

1. Go to the Expenses screen
2. Tap the "+" button to add a new expense
3. Enter:
   - Amount
   - Category (choose from predefined or add custom)
   - Description (optional)
   - Date
4. Save the expense

### Managing Categories

- **Predefined Categories**: Foods, Transportation, Shopping, Bills, Housing
- **Custom Categories**: Add your own categories for better organization

### Viewing Reports

1. Access the Reports screen
2. View expense breakdowns by category
3. Check budget vs. actual spending
4. Export reports to CSV or PDF

### Settings

- **Theme**: Switch between light and dark modes
- **Language**: Change app language (English, Tagalog, Spanish)
- **Notifications**: Enable/disable monthly reminders
- **Data Management**: Reset current month data or export data

### Sync and Offline Support

- Data is automatically synced with Supabase when online
- Expenses and budgets are stored locally for offline access
- Changes made offline will sync when connection is restored

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── l10n/                     # Localization files
├── models/                   # Data models
│   ├── budget.dart
│   └── expense.dart
├── providers/                # State management
│   ├── budget_provider.dart
│   ├── expense_provider.dart
│   ├── theme_provider.dart
│   ├── language_provider.dart
│   └── user_provider.dart
├── screens/                  # UI screens
│   ├── auth_screen.dart
│   ├── budget_screen.dart
│   ├── expenses_screen.dart
│   ├── overview_screen.dart
│   ├── report_screen.dart
│   ├── settings_screen.dart
│   └── ...
├── services/                 # Business logic and external services
│   ├── supabase_service.dart
│   ├── supabase_sync_service.dart
│   ├── notification_service.dart
│   └── export_service.dart
└── utils/                    # Utility functions
    └── monthly_budget_manager.dart
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

### Common Issues

1. **Build fails**: Ensure all dependencies are installed with `flutter pub get`
2. **Supabase connection issues**: Verify your API keys and network connection
3. **Data not syncing**: Check RLS policies and user authentication
4. **Notifications not working**: Ensure proper permissions are granted

### Debug Mode

Run the app in debug mode to see detailed logs:

```bash
flutter run --debug
```

## License

This project is private and proprietary.

## Support

For support or questions, please contact the development team.
