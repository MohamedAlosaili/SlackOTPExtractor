# SlackOTPExtractor - Just Commands
# Usage: just <command>

# Default recipe - shows available commands
default:
    @echo "🚀 SlackOTPExtractor Commands"
    @echo "============================"
    @just --list

# Run the app locally (compile and start)
run:
    @echo "🔄 Stopping any existing instances..."
    @pkill SlackOTPExtractor 2>/dev/null || true
    @echo "🔨 Compiling SlackOTPExtractor..."
    @swiftc main.swift -o SlackOTPExtractor -framework Cocoa -framework UserNotifications
    @echo "✅ Compilation successful!"
    @echo ""
    @echo "🎯 Starting SlackOTPExtractor..."
    @echo "📍 Look for the key icon (🔑) in your menu bar"
    @echo "💡 Click the icon and select 'Start Monitoring' to begin"
    @echo ""
    @echo "🛑 Press Ctrl+C to stop the app"
    @echo "================================="
    @echo ""
    @./SlackOTPExtractor

# Compile only (no run)
build:
    @echo "🔨 Building SlackOTPExtractor..."
    @swiftc main.swift -o SlackOTPExtractor -framework Cocoa -framework UserNotifications
    @echo "✅ Build complete: SlackOTPExtractor"

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    @rm -f SlackOTPExtractor
    @echo "✅ Clean complete"

# Stop any running instances
stop:
    @echo "🛑 Stopping SlackOTPExtractor..."
    @pkill SlackOTPExtractor 2>/dev/null || echo "No running instances found"

# Check Swift installation
check:
    @echo "🔍 Checking development environment..."
    @swiftc --version
    @echo "✅ Swift is available"

# Quick test of OTP extraction logic
test:
    @echo "🧪 Testing OTP extraction..."
    @echo 'import Foundation; let text = "Your code is 1234 please enter"; let regex = try! NSRegularExpression(pattern: "\\\\b\\\\d{4,6}\\\\b"); if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)) { print("✅ Found OTP:", String(text[Range(match.range, in: text)!])) } else { print("❌ No OTP found") }' | swift -

# Show app status
status:
    @echo "📊 SlackOTPExtractor Status:"
    @echo "=========================="
    @if pgrep SlackOTPExtractor > /dev/null; then \
        echo "🟢 Status: Running (PID: $(pgrep SlackOTPExtractor))"; \
    else \
        echo "🔴 Status: Not running"; \
    fi
    @if [ -f "SlackOTPExtractor" ]; then \
        echo "📦 Binary: Available"; \
        echo "📏 Size: $(ls -lh SlackOTPExtractor | awk '{print $5}')"; \
    else \
        echo "📦 Binary: Not built"; \
    fi

# Development workflow - build and run with auto-restart on changes
dev:
    @echo "🔄 Development mode - watching for changes..."
    @echo "💡 Edit main.swift and the app will auto-restart"
    @echo "🛑 Press Ctrl+C to stop development mode"
    @fswatch -o main.swift | xargs -n1 -I{} just run

# Create a release build (optimized)
release:
    @echo "🚀 Building release version..."
    @swiftc main.swift -o SlackOTPExtractor -O -framework Cocoa -framework UserNotifications
    @echo "✅ Release build complete"
    @echo "📦 Binary size: $(ls -lh SlackOTPExtractor | awk '{print $5}')"
