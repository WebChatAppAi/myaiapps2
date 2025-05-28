# Project Details

## 🌳 Project Structure Tree View

```
.
├── 📁 android/
├── 📁 build/
├── 📁 ios/
├── 📁 lib/
│   ├── 📁 assets/
│   │   └── 📁 landing/
│   │       └── logo.png
│   ├── 📁 models/
│   │   └── chat_message.dart
│   ├── 📁 providers/
│   │   ├── auth_provider.dart
│   │   ├── chat_provider_updated.dart
│   │   ├── chat_provider.dart
│   │   ├── settings_provider.dart
│   │   └── user_provider.dart
│   ├── 📁 screens/
│   │   ├── landing_page.dart
│   │   ├── 📁 chat/
│   │   │   └── chat_list_screen.dart
│   │   ├── 📁 image/
│   │   │   └── image_generation_screen.dart
│   │   ├── 📁 landing/
│   │   │   ├── key_input_widget.dart
│   │   │   └── landing_page.dart
│   │   ├── 📁 profile/
│   │   │   └── profile_screen.dart
│   │   └── 📁 settings/
│   │       └── settings_screen.dart
│   ├── 📁 services/
│   │   ├── ai_service.dart
│   │   └── secure_storage_service.dart
│   ├── 📁 theme/
│   │   ├── app_theme.dart
│   │   └── colors.dart
│   ├── 📁 utils/
│   │   ├── constants.dart
│   │   ├── navigator_key.dart
│   │   ├── page_transitions.dart
│   │   └── toast_utils.dart
│   ├── 📁 widgets/
│   │   └── message_bubble.dart
│   └── main.dart
├── 📁 linux/
├── 📁 macos/
├── 📁 test/
│   └── widget_test.dart
├── 📁 web/
├── 📁 windows/
├── .cursorignore
├── .cursorrules
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
├── roadmap.md
├── TODO.md
└── VERSION.md
```

### 🔍 File Descriptions

- `.cursorignore`: Specifies files and directories to be ignored by the Cursor AI.
- `.cursorrules`: Contains custom instructions or rules for the Cursor AI.
- `.gitignore`: Specifies intentionally untracked files to ignore.
- `analysis_options.yaml`: Configuration file for the Dart analyzer, defining linting rules and static analysis settings.
- `pubspec.yaml`: Defines the project's dependencies, metadata (name, description, version), and assets.
- `README.md`: Provides a general overview of the project, its purpose, and how to get started.
- `roadmap.md`: Outlines the future development plans and milestones for the project.
- `TODO.md`: Lists pending tasks, improvements, or known issues.
- `VERSION.md`: Tracks the version history and release notes of the application.
- `lib/main.dart`: The main entry point of the Flutter application, responsible for initializing the app and defining the root widget.
- `lib/assets/landing/logo.png`: Image asset used on the landing page.
- `lib/models/chat_message.dart`: Defines the data structure for chat messages.
- `lib/providers/auth_provider.dart`: Manages user authentication state and logic.
- `lib/providers/chat_provider_updated.dart`: An updated version of the chat provider, likely containing newer chat-related logic.
- `lib/providers/chat_provider.dart`: Manages chat-related data and logic.
- `lib/providers/settings_provider.dart`: Manages application settings and user preferences.
- `lib/providers/user_provider.dart`: Manages user-specific data and state.
- `lib/screens/landing_page.dart`: The initial screen displayed when the app starts.
- `lib/screens/chat/chat_list_screen.dart`: Displays a list of chat conversations.
- `lib/screens/image/image_generation_screen.dart`: Handles the UI and logic for image generation features.
- `lib/screens/landing/key_input_widget.dart`: A widget for inputting API keys or similar sensitive information on the landing page.
- `lib/screens/landing/landing_page.dart`: The landing page UI, potentially including key input and initial setup.
- `lib/screens/profile/profile_screen.dart`: Displays user profile information and allows for editing.
- `lib/screens/settings/settings_screen.dart`: Provides the user interface for configuring application settings.
- `lib/services/ai_service.dart`: Handles communication with the AI backend for various AI-related functionalities.
- `lib/services/secure_storage_service.dart`: Manages secure storage of sensitive data like API keys.
- `lib/theme/app_theme.dart`: Defines the overall application theme, including colors, typography, and visual styles.
- `lib/theme/colors.dart`: Defines the color palette used throughout the application.
- `lib/utils/constants.dart`: Contains application-wide constants and static values.
- `lib/utils/navigator_key.dart`: Provides a global key for navigation operations.
- `lib/utils/page_transitions.dart`: Defines custom page transition animations.
- `lib/utils/toast_utils.dart`: Utility functions for displaying toast messages or temporary notifications.
- `lib/widgets/message_bubble.dart`: A reusable widget for displaying individual chat messages.
- `test/widget_test.dart`: Example widget test file for Flutter.

### 🤝 How to Contribute

To contribute to this project, developers should focus on the `lib/` directory, which contains the core application logic.

- **Core Logic**: Most feature development will occur within `lib/screens/` for UI, `lib/providers/` for state management, and `lib/services/` for backend interactions.
- **Models**: Data structures are defined in `lib/models/`.
- **UI Components**: Reusable UI elements are in `lib/widgets/`.
- **Theming**: Adjustments to the app's look and feel can be made in `lib/theme/`.
- **Utilities**: Common utility functions and constants are in `lib/utils/`.

When contributing, please adhere to the existing coding style and file placement conventions. Ensure all new features are accompanied by appropriate tests, especially for critical functionalities.
