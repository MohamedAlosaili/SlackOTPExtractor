import Cocoa
import UserNotifications
import Foundation

// MARK: - OTP Extractor Core Logic
class OTPExtractor {
    static let shared = OTPExtractor()
    
    // Default regex patterns for OTP detection
    private let defaultPatterns = [
        "\\s(\\d{4,6})\\s",                               // 4-6 digit codes with spaces around them (prioritized)
        "\\b\\d{4,6}\\b",                                 // 4-6 digit codes at word boundaries
        "(?i)(?:otp|code|verification)\\s*:?\\s*([A-Z0-9]{4,8})", // "OTP: xxxxx" format
        "(?i)verification\\s+code\\s*:?\\s*([A-Z0-9]{4,8})",      // "verification code xxxxx"
        "(?i)your\\s+code\\s*:?\\s*([A-Z0-9]{4,8})",             // "your code: xxxxx"
        "(?i)security\\s+code\\s*:?\\s*([A-Z0-9]{4,8})",         // "security code: xxxxx"
        "(?i)pin\\s*:?\\s*([0-9]{4,8})",                         // "PIN: xxxx"
        "(?i)enter\\s+(?:this\\s+)?code\\s*:?\\s*([A-Z0-9]{4,8})", // "enter this code: xxxxx"
        "(?i)authentication\\s+code\\s*:?\\s*([A-Z0-9]{4,8})"    // "authentication code: xxxxx"
    ]
    
    // Minimal false positive patterns (only filter obvious non-OTP patterns)
    private let falsePositivePatterns = [
        // Only keep very obvious non-OTP patterns, remove common OTP sequences
        "2024", "2025", "2023", "2022", "2021", "2020",  // Years
        "1900", "1901", "1902", "1903", "1904", "1905"   // Old years
    ]
    
    private init() {}
    
    func extractOTP(from text: String, customPattern: String? = nil) -> String? {
        let patterns = customPattern != nil ? [customPattern!] : defaultPatterns
        
        print("🔍 OTP Extraction Debug:")
        print("  📄 Input text: '\(text)'")
        print("  🎯 Testing \(patterns.count) pattern(s)")
        
        for (index, pattern) in patterns.enumerated() {
            print("  🔧 Pattern \(index + 1): \(pattern)")
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: text.utf16.count)
                
                let matches = regex.matches(in: text, options: [], range: range)
                print("    📊 Found \(matches.count) match(es)")
                
                if let match = matches.first {
                    let matchRange = match.range(at: match.numberOfRanges > 1 ? 1 : 0)
                    if let swiftRange = Range(matchRange, in: text) {
                        let extractedCode = String(text[swiftRange])
                        print("    ✅ Extracted: '\(extractedCode)'")
                        
                        // Filter out false positives
                        if falsePositivePatterns.contains(extractedCode) {
                            print("    ❌ Rejected as false positive")
                            continue
                        } else {
                            print("    ✅ Accepted as valid OTP")
                            return extractedCode
                        }
                    }
                }
            } catch {
                print("    ❌ Regex error: \(error)")
            }
        }
        
        print("  ❌ No valid OTP found with any pattern")
        return nil
    }
}

// MARK: - User Defaults Manager
class SettingsManager {
    static let shared = SettingsManager()
    
    private let customRegexKey = "customRegexPattern"
    private let isMonitoringKey = "isMonitoring"
    
    private init() {}
    
    var customRegexPattern: String? {
        get { UserDefaults.standard.string(forKey: customRegexKey) }
        set { UserDefaults.standard.set(newValue, forKey: customRegexKey) }
    }
    
    var isMonitoring: Bool {
        get { UserDefaults.standard.bool(forKey: isMonitoringKey) }
        set { UserDefaults.standard.set(newValue, forKey: isMonitoringKey) }
    }
}

// MARK: - Clipboard Manager and Monitor
class ClipboardManager {
    static let shared = ClipboardManager()
    
    private var lastClipboardContent: String?
    private var clipboardTimer: Timer?
    private var onClipboardChange: ((String) -> Void)?
    
    private init() {}
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    func getClipboardContent() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }
    
    func startMonitoring(onChange: @escaping (String) -> Void) {
        onClipboardChange = onChange
        lastClipboardContent = getClipboardContent()
        
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if let currentContent = self.getClipboardContent(),
               currentContent != self.lastClipboardContent && !currentContent.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                let timestamp = formatter.string(from: Date())
                print("\n📋 [\(timestamp)] CLIPBOARD CHANGE DETECTED!")
                print("🆕 New content (\(currentContent.count) chars): '\(currentContent)'")
                if let lastContent = self.lastClipboardContent {
                    print("🗂️ Previous content: '\(lastContent.prefix(50))...'")
                }
                self.lastClipboardContent = currentContent
                self.onClipboardChange?(currentContent)
            }
        }
        print("📋 Started monitoring clipboard changes...")
        print("💡 Copy any text containing OTP codes and they'll be automatically detected!")
    }
    
    func stopMonitoring() {
        clipboardTimer?.invalidate()
        clipboardTimer = nil
        onClipboardChange = nil
        print("📋 Stopped monitoring clipboard changes...")
    }
}

// MARK: - Notification Manager
class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func showOTPFoundNotification(otp: String) {
        let content = UNMutableNotificationContent()
        content.title = "OTP Code Found!"
        content.body = "Code \(otp) has been copied to clipboard"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound, .badge])
    }
}

// MARK: - System Notification Monitor
class SystemNotificationMonitor {
    static let shared = SystemNotificationMonitor()
    
    private var onNotificationReceived: ((String) -> Void)?
    private var notificationCount = 0
    
    private init() {}
    
    func startMonitoring(onNotification: @escaping (String) -> Void) {
        onNotificationReceived = onNotification
        notificationCount = 0
        
        // Monitor distributed notifications from all apps
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(notificationReceived(_:)),
            name: nil,
            object: nil
        )
        
        print("🔔 Started monitoring system notifications...")
        print("💡 NOTE: Due to macOS privacy restrictions, Slack notification content may not be accessible")
        print("📋 PRIMARY METHOD: Copy Slack messages containing OTP codes (Cmd+C)")
        print("🎯 App will detect OTP codes when you copy text from Slack!")
    }
    
    func stopMonitoring() {
        DistributedNotificationCenter.default().removeObserver(self)
        onNotificationReceived = nil
        print("🔔 Stopped monitoring system notifications...")
        if notificationCount > 0 {
            print("📊 Processed \(notificationCount) system notifications")
        }
    }
    
    @objc private func notificationReceived(_ notification: Notification) {
        notificationCount += 1
        
        // Log notification details for debugging
        let notificationName = notification.name.rawValue
        print("📨 System notification #\(notificationCount): \(notificationName)")
        
        // Filter for notifications that might contain text
        var textToCheck = ""
        var foundTextContent = false
        
        if let userInfo = notification.userInfo {
            // Try to extract text from various common notification keys
            for (key, value) in userInfo {
                if let stringValue = value as? String {
                    print("  📄 Key '\(key)': '\(stringValue)'")
                    textToCheck += "\(stringValue) "
                    foundTextContent = true
                }
            }
        }
        
        // Also check the notification name for text
        textToCheck += notificationName
        
        if foundTextContent || notificationName.contains("Slack") {
            print("  🔍 Checking for OTP in notification content...")
            if !textToCheck.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onNotificationReceived?(textToCheck)
            }
        }
    }
}

// MARK: - Demo Mode
class DemoMode {
    static let shared = DemoMode()
    
    private let demoTexts = [
        "Your verification code is 123456",
        "OTP: 789012",
        "Security code: ABC123",
        "Your code: 456789",
        "Please enter this code: 987654",
        "Two-factor authentication code: XY7890"
    ]
    
    private var timer: Timer?
    
    private init() {}
    
    func startDemo(with statusBarApp: StatusBarApp) {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            let randomText = self.demoTexts.randomElement() ?? self.demoTexts[0]
            statusBarApp.processText(randomText, isDemo: true, source: "Demo")
        }
    }
    
    func stopDemo() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Status Bar Application
class StatusBarApp: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var isMonitoring = false
    private var lastOTP: String?
    
    override init() {
        super.init()
        setupStatusBar()
        setupMenu()
        updateStatusIcon()
        
        // Restore monitoring state
        isMonitoring = SettingsManager.shared.isMonitoring
        updateMenuItems()
    }
    
    private func setupStatusBar() {
        print("🔧 Setting up status bar...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusItem = statusItem {
            print("✅ Status item created successfully")
            
            if let button = statusItem.button {
                print("✅ Status item button available")
                
                // Use simple text instead of SF Symbol for better compatibility
                button.title = "🔑"
                print("✅ Text icon set successfully: 🔑")
                
                print("✅ Status bar setup complete - icon should be visible in menu bar")
            } else {
                print("❌ Failed to get status item button")
            }
        } else {
            print("❌ Failed to create status item")
        }
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
        // Title
        let titleItem = NSMenuItem(title: "OTP Extractor", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Start/Stop monitoring
        let monitorItem = NSMenuItem(title: "Start Monitoring", action: #selector(toggleMonitoring), keyEquivalent: "")
        monitorItem.target = self
        monitorItem.tag = 1
        menu.addItem(monitorItem)
        
        // Last OTP
        let lastOTPItem = NSMenuItem(title: "Last OTP: None", action: #selector(copyLastOTP), keyEquivalent: "")
        lastOTPItem.target = self
        lastOTPItem.tag = 2
        lastOTPItem.isEnabled = false
        menu.addItem(lastOTPItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Demo mode
        let demoItem = NSMenuItem(title: "Start Demo", action: #selector(toggleDemo), keyEquivalent: "")
        demoItem.target = self
        demoItem.tag = 3
        menu.addItem(demoItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        updateMenuItems()
    }
    
    private func updateStatusIcon() {
        let iconName = isMonitoring ? "key.fill" : "key"
        statusItem.button?.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "OTP Extractor")
    }
    
    private func updateMenuItems() {
        if let monitorItem = menu.item(withTag: 1) {
            monitorItem.title = isMonitoring ? "Stop Monitoring" : "Start Monitoring"
        }
        
        if let lastOTPItem = menu.item(withTag: 2) {
            if let otp = lastOTP {
                lastOTPItem.title = "Last OTP: \(otp)"
                lastOTPItem.isEnabled = true
            } else {
                lastOTPItem.title = "Last OTP: None"
                lastOTPItem.isEnabled = false
            }
        }
        
        updateStatusIcon()
    }
    
    @objc private func toggleMonitoring() {
        isMonitoring.toggle()
        SettingsManager.shared.isMonitoring = isMonitoring
        updateMenuItems()
        
        if isMonitoring {
            print("🚀 Starting real-time OTP monitoring...")
            print("")
            print("📋 HOW TO USE WITH SLACK:")
            print("1. When you receive a Slack message with an OTP code")
            print("2. Simply COPY the message text (Cmd+C)")
            print("3. The app will automatically detect and copy the OTP!")
            print("")
            
            // Start clipboard monitoring (primary method)
            ClipboardManager.shared.startMonitoring { [weak self] clipboardText in
                self?.processText(clipboardText, source: "Clipboard")
            }
            
            // Start system notification monitoring (secondary method)
            SystemNotificationMonitor.shared.startMonitoring { [weak self] notificationText in
                self?.processText(notificationText, source: "Notification")
            }
            
            print("✅ Real-time monitoring active!")
            print("🎯 Ready to detect OTP codes from copied Slack messages!")
            
        } else {
            print("⏹️ Stopping OTP monitoring...")
            ClipboardManager.shared.stopMonitoring()
            SystemNotificationMonitor.shared.stopMonitoring()
            DemoMode.shared.stopDemo()
            if let demoItem = menu.item(withTag: 3) {
                demoItem.title = "Start Demo"
            }
            print("❌ Monitoring stopped.")
        }
    }
    
    @objc private func copyLastOTP() {
        guard let otp = lastOTP else { return }
        ClipboardManager.shared.copyToClipboard(otp)
        NotificationManager.shared.showOTPFoundNotification(otp: otp)
    }
    
    @objc private func toggleDemo() {
        guard let demoItem = menu.item(withTag: 3) else { return }
        
        if demoItem.title == "Start Demo" {
            demoItem.title = "Stop Demo"
            DemoMode.shared.startDemo(with: self)
            if !isMonitoring {
                toggleMonitoring()
            }
        } else {
            demoItem.title = "Start Demo"
            DemoMode.shared.stopDemo()
        }
    }
    
    @objc private func showSettings() {
        let alert = NSAlert()
        alert.messageText = "Settings"
        alert.informativeText = "Enter a custom regex pattern for OTP extraction (leave empty for default patterns):"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = SettingsManager.shared.customRegexPattern ?? ""
        textField.placeholderString = "e.g., \\b\\d{6}\\b"
        alert.accessoryView = textField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let pattern = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            SettingsManager.shared.customRegexPattern = pattern.isEmpty ? nil : pattern
        }
    }
    
    @objc private func quit() {
        DemoMode.shared.stopDemo()
        ClipboardManager.shared.stopMonitoring()
        SystemNotificationMonitor.shared.stopMonitoring()
        NSApplication.shared.terminate(nil)
    }
    
    // Auto-start monitoring for local development (bypasses menu)
    func startMonitoringAutomatically() {
        if !isMonitoring {
            print("🤖 Auto-starting monitoring (bypassing menu)...")
            toggleMonitoring()
        } else {
            print("✅ Monitoring already active")
        }
    }
    
    // Method to process text (called by demo mode or real monitoring)
    func processText(_ text: String, isDemo: Bool = false, source: String = "Unknown") {
        guard isMonitoring else { 
            print("⚠️ Skipping text processing - monitoring is disabled")
            return 
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        print("\n🔍 [\(timestamp)] PROCESSING TEXT FROM: \(source)")
        print("📝 Text length: \(text.count) characters")
        print("📄 Full text: '\(text)'")
        print("🎯 Searching for OTP codes...")
        
        let customPattern = SettingsManager.shared.customRegexPattern
        if let customPattern = customPattern {
            print("🔧 Using custom regex pattern: \(customPattern)")
        } else {
            print("🔧 Using default regex patterns")
        }
        
        if let otp = OTPExtractor.shared.extractOTP(from: text, customPattern: customPattern) {
            print("✅ OTP FOUND: '\(otp)'")
            
            // Avoid infinite loops - don't process our own OTP clipboard copies
            if source == "Clipboard" && otp == lastOTP {
                print("🔄 Skipping - this is our own OTP copy (avoiding infinite loop)")
                return
            }
            
            print("💾 Storing as last OTP: \(otp)")
            lastOTP = otp
            updateMenuItems()
            
            // Only copy to clipboard if it's not already from clipboard
            if source != "Clipboard" {
                print("📋 Copying OTP to clipboard: \(otp)")
                ClipboardManager.shared.copyToClipboard(otp)
                print("✅ Successfully copied to clipboard")
            } else {
                print("📋 Skipping clipboard copy (source is already clipboard)")
            }
            
            let notificationBody: String
            if isDemo {
                notificationBody = "Demo: Code \(otp) copied to clipboard"
            } else {
                notificationBody = "Code \(otp) found from \(source) and copied to clipboard"
            }
            
            print("🔔 Showing system notification: \(notificationBody)")
            let content = UNMutableNotificationContent()
            content.title = "OTP Code Found!"
            content.body = notificationBody
            content.sound = UNNotificationSound.default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Notification error: \(error)")
                } else {
                    print("✅ System notification sent successfully")
                }
            }
            
            print("🎉 OTP PROCESSING COMPLETE: \(otp) from \(source)")
        } else {
            print("❌ NO OTP FOUND in text")
            print("💡 Text did not match any OTP patterns")
        }
        print("─────────────────────────────────────────")
    }
}

// MARK: - Application Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarApp: StatusBarApp!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Application starting...")
        
        // Hide dock icon (makes it a menu bar only app)
        print("🔧 Setting activation policy to accessory (menu bar only)...")
        NSApp.setActivationPolicy(.accessory)
        
        print("🔧 Creating status bar app...")
        statusBarApp = StatusBarApp()
        
        print("✅ OTP Extractor started successfully!")
        print("👀 Look for the 🔑 emoji in your menu bar!")
        print("")
        print("🚀 AUTOMATIC STARTUP: Starting monitoring automatically...")
        
        // Auto-start monitoring for local development
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let statusBarApp = self.statusBarApp {
                statusBarApp.startMonitoringAutomatically()
            }
        }
        
        print("💡 If menu icon doesn't appear, monitoring will still work!")
        print("🎯 Try copying text with OTP codes - they'll be detected automatically!")
        print("⌨️  Press Cmd+Q in terminal to quit")
        print("📋 Clipboard monitoring is now active!")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - Main Application Entry Point
class Application: NSApplication {
    let appDelegate = AppDelegate()
    
    override init() {
        super.init()
        self.delegate = appDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Start the application
let app = Application.shared
app.run()
