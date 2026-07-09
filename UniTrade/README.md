# UniTrade

UniTrade is a marketplace platform with both a mobile application (Flutter) and a backend service (FastAPI).

## Project Structure

- `mobile_app/`: The Flutter frontend application for UniTrade.
- `backend/`: The Python FastAPI backend service and SQLite database.

## Recent Updates

We've recently introduced global theming for the mobile app to ensure consistent UI styling, as well as a robust notification system and chat improvements. See `CHANGELOG.md` for a full list of recent changes.

## Getting Started

### Backend
1. Navigate to the `backend` directory.
2. Install dependencies (e.g., `pip install -r requirements.txt`).
3. Run the FastAPI server: `uvicorn main:app --reload`.

### Mobile App
1. Navigate to the `mobile_app` directory.
2. Run `flutter pub get` to install dependencies.
3. Run the app: `flutter run`.
