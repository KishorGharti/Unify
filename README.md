# Unify - Unified Business Messaging Mobile SaaS

Unify is a production-ready Flutter mobile SaaS application for unified customer messaging across **Facebook Pages** and **Instagram Professional accounts** via official Meta business APIs.

---

## 📱 Project Overview

- **Core Value Proposition**: Unify Meta customer messaging into a single high-performance mobile inbox so businesses never lose a lead or switch between multiple social media apps.
- **Initial Supported Channels**:
  - **Facebook Messenger** (for Facebook Pages)
  - **Instagram Messaging** (for Instagram Professional & Creator accounts)
- **Extensibility**: Generic `ChannelType` architecture ready for **WhatsApp Business**, **Viber**, **Telegram**, **Email**, and **TikTok**.

---

## 🏗️ Folder Hierarchy & File Structure

```
unify/
├── pubspec.yaml                                      # Dependencies (Riverpod, Dio, GoogleFonts, Intl)
├── analysis_options.yaml                             # Production Flutter linting rules
├── README.md                                         # Project documentation
└── lib/
    ├── main.dart                                     # App entrypoint, Theme routing, ProviderScope
    ├── core/
    │   ├── constants/
    │   │   ├── app_constants.dart                    # App configuration & storage keys
    │   │   ├── api_endpoints.dart                    # REST API & WebSocket route definitions
    │   │   └── channel_config.dart                   # Extensible ChannelType enum & brand tokens
    │   ├── theme/
    │   │   ├── app_colors.dart                       # Indigo/Violet palette, Meta/IG gradients
    │   │   ├── app_typography.dart                   # Plus Jakarta Sans & Inter scale
    │   │   ├── app_dimensions.dart                   # Radii, spacing, and avatar sizes
    │   │   └── app_theme.dart                        # Dark & Light ThemeData
    │   ├── errors/
    │   │   ├── app_exceptions.dart                   # Network, Auth, Server exceptions
    │   │   └── failure.dart                          # Domain failure types
    │   ├── utils/
    │   │   ├── date_formatter.dart                   # TimeAgo, MessageTime, ShortDate
    │   │   ├── validators.dart                       # Form validators (Email, Password, Company)
    │   │   └── extensions.dart                       # String casing & BuildContext helpers
    │   ├── storage/
    │   │   └── secure_storage.dart                   # Encrypted token & session persistence
    │   ├── network/
    │   │   ├── api_client.dart                       # Dio HTTP client
    │   │   ├── api_interceptors.dart                 # X-Tenant-ID & JWT Bearer injection
    │   │   ├── api_response.dart                     # Generic API response envelope
    │   │   └── network_info.dart                     # Connectivity checker
    │   ├── websocket/
    │   │   ├── socket_events.dart                    # Real-time event definitions
    │   │   ├── socket_service.dart                   # WebSocket client & topic subscriptions
    │   │   └── mock_socket_engine.dart               # Live incoming message simulation engine
    │   └── widgets/
    │       ├── unify_button.dart                    # Button with primary, gradient, secondary variants
    │       ├── unify_text_field.dart                # Styled input fields with validation
    │       ├── unify_card.dart                      # Glassmorphic surface containers
    │       ├── unify_badge.dart                     # Status and counter badge
    │       ├── channel_badge.dart                    # Branded Facebook & Instagram badges
    │       ├── status_badge.dart                     # Open, Pending, Resolved badges
    │       ├── user_avatar.dart                      # Avatar with channel icon & online indicator
    │       ├── empty_state_view.dart                 # Empty state handler
    │       ├── error_state_view.dart                 # Error state with retry action
    │       ├── loading_state_view.dart               # Loading indicators
    │       └── unify_nav_shell.dart                 # Bottom navigation with unread badges
    └── features/
        ├── auth/
        │   ├── data/
        │   │   ├── auth_repository.dart              # Multi-tenant login, signup, reset password
        │   │   └── models/
        │   │       ├── tenant_model.dart             # BusinessTenantModel
        │   │       └── user_model.dart               # UserModel with roles (Owner, Admin, Agent)
        │   └── presentation/
        │       ├── providers/auth_provider.dart      # AuthNotifier & state
        │       └── screens/
        │           ├── splash_screen.dart            # Animated splash & auth verification
        │           ├── onboarding_screen.dart        # 3-slide SaaS intro walkthrough
        │           ├── login_screen.dart             # Work credentials login
        │           ├── signup_screen.dart            # Multi-tenant workspace registration
        │           └── forgot_password_screen.dart   # Verification code password reset
        ├── dashboard/
        │   ├── data/models/dashboard_metrics.dart    # SLA metrics & analytics models
        │   └── presentation/
        │       ├── providers/dashboard_provider.dart # Dashboard metrics state
        │       └── screens/dashboard_screen.dart     # Live SLA metrics & channel distribution
        ├── inbox/
        │   ├── data/
        │   │   ├── inbox_repository.dart             # Conversation queries & cache
        │   │   └── models/conversation_model.dart    # Unified conversation model
        │   └── presentation/
        │       ├── providers/inbox_provider.dart     # Multi-filter & live search state
        │       └── screens/unified_inbox_screen.dart # Unified Inbox with platform filter chips
        ├── chat/
        │   ├── data/
        │   │   ├── chat_repository.dart              # Message sending & attachment storage
        │   │   └── models/message_model.dart         # Text, image, internal note models
        │   └── presentation/
        │       ├── providers/chat_provider.dart      # Chat state with WebSocket live stream
        │       ├── widgets/
        │       │   ├── chat_bubble.dart              # Customer & Agent message bubbles
        │       │   ├── internal_note_bubble.dart     # Private yellow-tint team note bubble
        │       │   ├── chat_input_bar.dart           # Meta reply vs Internal note switcher
        │       │   ├── quick_replies_modal.dart      # Canned response picker (/hello, /track, /stock)
        │       │   ├── assignee_picker_modal.dart    # Agent assignment modal
        │       │   └── tag_manager_modal.dart        # Conversation tag manager modal
        │       └── screens/conversation_screen.dart  # Modern chat interface
        ├── customer/
        │   ├── data/models/customer_profile_model.dart # CRM profile data model
        │   └── presentation/screens/customer_profile_screen.dart # Customer metadata & history
        ├── channels/
        │   ├── data/
        │   │   ├── channel_repository.dart           # Meta OAuth & Webhook subscriptions
        │   │   └── models/connected_account_model.dart # Connected account model
        │   └── presentation/
        │       ├── providers/channels_provider.dart  # Channels state notifier
        │       └── screens/
        │           ├── connected_accounts_screen.dart # Overview of FB Pages & IG accounts
        │           ├── connect_facebook_screen.dart  # Meta OAuth guide & page picker
        │           └── connect_instagram_screen.dart # Instagram Professional linking guide
        ├── team/
        │   ├── data/models/team_member_model.dart    # Team member & seat model
        │   └── presentation/
        │       ├── providers/team_provider.dart      # Team members state
        │       └── screens/team_members_screen.dart  # Role manager & invite member modal
        ├── subscription/
        │   ├── data/models/subscription_model.dart   # Plans, tiers, and invoice models
        │   └── presentation/
        │       ├── providers/subscription_provider.dart # Billing state notifier
        │       └── screens/
        │           ├── pricing_screen.dart           # Starter, Pro, Enterprise pricing cards
        │           └── billing_screen.dart           # Active subscription & invoice history
        └── settings/
            └── presentation/
                ├── providers/settings_provider.dart  # Preferences & theme mode state
                └── screens/
                    ├── settings_screen.dart          # Tenant switcher & app settings
                    ├── notifications_screen.dart     # Alert stream & assignment logs
                    └── user_profile_screen.dart      # User profile, 2FA, & credentials
```

---

## 🚀 Running the Project

1. Navigate to the project directory:
   ```bash
   cd C:\Users\u\.gemini\antigravity-ide\scratch\unify
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Launch on mobile emulator or device:
   ```bash
   flutter run
   ```
