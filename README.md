# SlackOTPExtractor

A macOS menu bar utility that monitors notifications and automatically extracts OTP (One-Time Password) codes, copying them to your clipboard for easy access.

![macOS Version](https://img.shields.io/badge/macOS-11.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Build Status](https://github.com/yourusername/SlackOTPExtractor/actions/workflows/build.yml/badge.svg)

## Features

✨ **Smart OTP Detection**: Automatically extracts OTP codes using optimized regex patterns:
- **4-6 digit codes with spaces** (prioritized for Slack messages)
- 4-8 digit numeric codes at word boundaries
- Alphanumeric codes  
- Common formats like "OTP: 123456", "verification code: ABC123"
- Custom regex patterns via settings
- **Minimal false positive filtering** (accepts common OTP sequences like 0000, 1234)

🎯 **Menu Bar Integration**: Clean, unobtrusive menu bar app with:
- Visual state indicator (filled key = monitoring, outline = stopped)
- Quick start/stop monitoring toggle
- Last OTP display with one-click re-copy
- Demo mode for testing

📋 **Clipboard Integration**: Automatically copies detected OTP codes to clipboard

🔔 **System Notifications**: Native macOS notifications when OTP codes are found

🚫 **False Positive Filtering**: Intelligent filtering to avoid common false positives like "0000", "1234", etc.

⚙️ **Customizable**: Set your own regex patterns for specific OTP formats

## Screenshots

*Menu bar icon states:*
- 🔑 (outline) = Not monitoring
- 🔑 (filled) = Actively monitoring

*Menu options:*
- Start/Stop Monitoring
- Last OTP: [click to copy again]
- Demo Mode (for testing)
- Settings (custom regex)
- Quit

## Installation

### Option 1: Download Pre-built Binary (Recommended)

1. Go to the [Releases page](https://github.com/yourusername/SlackOTPExtractor/releases)
2. Download the latest `SlackOTPExtractor.zip`
3. Extract the ZIP file
4. Move `SlackOTPExtractor.app` to your Applications folder
5. **Important**: Right-click the app and select "Open" (required for first launch on unsigned apps)
6. Grant notification permissions when prompted
7. Look for the key icon in your menu bar

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/SlackOTPExtractor.git
cd SlackOTPExtractor

# Build the app
swiftc main.swift -o SlackOTPExtractor -framework Cocoa -framework UserNotifications

# Run the app
./SlackOTPExtractor
```

## Usage

### Getting Started

1. **Launch the app**: The key icon will appear in your menu bar
2. **Start monitoring**: Click the icon and select "Start Monitoring"
3. **Test with demo**: Use "Start Demo" to see sample OTP extractions
4. **Real usage**: The app will monitor text and extract OTP codes automatically

### Menu Options

- **Start/Stop Monitoring**: Toggle OTP detection on/off
- **Last OTP**: Shows the most recently found code (click to copy again)
- **Start/Stop Demo**: Simulates finding OTP codes every 10 seconds for testing
- **Settings**: Configure custom regex patterns
- **Quit**: Exit the application

### Custom Regex Patterns

Access Settings from the menu to set custom regex patterns:

```regex
# Examples:
\b\d{6}\b           # 6-digit codes
[A-Z0-9]{8}         # 8-character alphanumeric
(?i)pin:\s*(\d{4})  # "PIN: 1234" format
```

Leave empty to use default patterns.

### Detected OTP Formats

The app automatically detects these common OTP formats:

- `123456` (4-8 digit codes)
- `ABC123` (alphanumeric codes)
- `OTP: 123456`
- `verification code: ABC123`
- `your code: 123456`
- `security code: ABC123`

## Development

### Project Structure

```
SlackOTPExtractor/
├── main.swift                 # Complete application code
├── .github/workflows/build.yml # GitHub Actions workflow
├── README.md                  # This file
└── LICENSE                    # MIT License
```

### Key Components

- **OTPExtractor**: Core logic for pattern matching and extraction
- **StatusBarApp**: Menu bar interface and user interaction
- **NotificationManager**: System notification handling
- **SettingsManager**: User preferences and configuration
- **ClipboardManager**: Clipboard operations
- **DemoMode**: Testing functionality

### Building

#### Local Development
```bash
swiftc main.swift -o SlackOTPExtractor -framework Cocoa -framework UserNotifications
```

#### Universal Binary (Intel + Apple Silicon)
```bash
# Intel binary
swiftc main.swift -o SlackOTPExtractor_x86 -target x86_64-apple-macos11.0 -framework Cocoa -framework UserNotifications

# Apple Silicon binary  
swiftc main.swift -o SlackOTPExtractor_arm64 -target arm64-apple-macos11.0 -framework Cocoa -framework UserNotifications

# Combine into universal binary
lipo -create SlackOTPExtractor_x86 SlackOTPExtractor_arm64 -output SlackOTPExtractor
```

## Automated Building with GitHub Actions

This project includes automated building and distribution via GitHub Actions.

### Setting Up Automated Releases

1. **Fork/Clone this repository**
2. **Push to GitHub** (ensure all files are committed)
3. **Create a release tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. **GitHub Actions will automatically**:
   - Build a universal binary (Intel + Apple Silicon)
   - Create a proper .app bundle with Info.plist
   - Package as ZIP for distribution
   - Create a GitHub release with download links

### Manual Build Trigger

You can also trigger builds manually:
1. Go to Actions tab in your GitHub repository
2. Select "Build and Release macOS App"
3. Click "Run workflow"

### Build Features

- ✅ Universal binary (Intel + Apple Silicon)
- ✅ Proper macOS app bundle structure
- ✅ Info.plist with LSUIElement=true (menu bar app)
- ✅ macOS 11.0+ deployment target
- ✅ Automated ZIP packaging
- ✅ GitHub release creation
- ✅ Build artifact uploads

## System Requirements

- **macOS**: 11.0 (Big Sur) or later
- **Architecture**: Intel x86_64 or Apple Silicon (arm64)
- **Permissions**: Notification access (requested on first run)

## Privacy & Security

- **Local Processing**: All OTP extraction happens locally on your Mac
- **No Network**: The app doesn't send data anywhere
- **Minimal Permissions**: Only requests notification permissions
- **Open Source**: Full source code available for review

## Troubleshooting

### App Won't Launch
- Right-click the app and select "Open" (required for unsigned apps)
- Check that you're running macOS 11.0 or later
- Try building from source if the binary doesn't work

### No OTP Detection
- Ensure monitoring is enabled (filled key icon)
- Test with demo mode first
- Check if custom regex pattern is valid
- Verify the text contains recognizable OTP patterns

### Notifications Not Showing
- Grant notification permissions in System Preferences > Notifications
- Check that Do Not Disturb mode isn't blocking notifications

### Performance Issues
- The app uses minimal CPU when idle
- Demo mode timer can be stopped to reduce activity
- No background network activity

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Future Enhancements

Potential features for future versions:

- [ ] Slack app integration for direct monitoring
- [ ] Other messaging app support (Discord, Teams, etc.)
- [ ] Keyboard shortcuts for manual extraction
- [ ] OTP history with timestamps
- [ ] Multiple custom regex patterns
- [ ] Auto-paste to active application
- [ ] Accessibility features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Swift and native macOS frameworks
- Uses NSStatusItem for menu bar integration
- UserNotifications framework for system alerts
- Regular expressions for flexible OTP pattern matching

---

**Note**: This app is designed to work with any text-based OTP delivery, not just Slack. The name reflects its primary intended use case, but it can extract OTP codes from any text source on your Mac.
