# Equipment Checkout Calendar

A Flutter app for two users to sign out shared equipment and prevent double-booking.

## Equipment included
- T450 Skid Steer
- Dump Trailer
- Dodge 1500 Pickup
- Small Trailer
- Kia Optima
- Ford F250 Pickup

(More equipment can be added inside the app at any time.)

## Features
- **Calendar view** — colored dots show which equipment is booked on each day
- **Double-booking prevention** — the app blocks any checkout that conflicts with an existing one
- **Two users** — pick who you are when you open the app; rename yourself in settings
- **Multi-day bookings** — check out equipment for a day, a week, or longer
- **Equipment management** — add, rename, recolor, or deactivate equipment
- **Local storage** — all data persists between app restarts

## Setup

### Prerequisites
Install Flutter (https://docs.flutter.dev/get-started/install)

### Run the app

```bash
# 1. Clone the repo
git clone <repo-url>
cd flutter-beginners-tutorial

# 2. Create the Flutter project scaffold (only needed once)
#    This adds android/, ios/, web/ etc. without overwriting your source files.
flutter create . --project-name equipment_checkout --org com.equipmentcheckout

# 3. Install dependencies
flutter pub get

# 4. Run
flutter run
```

### Build a release APK (Android)

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

## Sharing data between two devices

Currently the app stores data locally on the device. For both users to see each other's bookings in real time, add a Firebase Firestore backend:

1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android / iOS app and download the config file
3. Replace the `_LocalStorage` calls in `lib/state/app_state.dart` with Firestore reads/writes

The conflict-detection logic in `AppState` stays the same regardless of storage backend.

## Project layout

```
lib/
  main.dart                    App entry point & router
  models/
    equipment.dart             Equipment data class
    booking.dart               Booking data class (with overlap detection)
    app_user.dart              User data class
  state/
    app_state.dart             All business logic & shared_preferences persistence
  screens/
    user_select_screen.dart    "Who are you?" picker shown on launch
    home_screen.dart           Calendar + day detail + booking list
    booking_form_screen.dart   Add / edit a booking
    equipment_screen.dart      Add / edit / toggle equipment
  widgets/
    booking_card.dart          Reusable card shown in the booking list
```
