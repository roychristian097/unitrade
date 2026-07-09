# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **Global Theme Support**: Added `theme.dart` with `context.bgColor`, `context.surfaceColor`, `context.textColor`, and `context.textMuted` for consistent UI styling across the app.
- **Notifications System**: Added backend endpoints and database schema updates for handling user notifications (e.g., new messages, order status updates).
- **Chat Enhancements**: Added read/unread message tracking with `is_read` database column and unread count endpoints.

### Changed
- Refactored UI colors in `cart_screen.dart`, `chat_detail_screen.dart`, `chat_list_screen.dart`, `dashboard_screen.dart`, `marketplace_screen.dart`, `order_history_screen.dart`, `payment_screen.dart`, `product_detail_screen.dart`, `profile_page.dart`, `service_detail_screen.dart`, `services_screen.dart`, and `wishlist_screen.dart` to use the new global theme extension.
- Moved `wishlist_page.dart` and `purchases_page.dart` to `wishlist_screen.dart` and `order_history_screen.dart` for better naming consistency.

### Removed
- Removed `purchases_page.dart` and `wishlist_page.dart`.
