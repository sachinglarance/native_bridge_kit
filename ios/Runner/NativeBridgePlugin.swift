import AVFoundation
import Flutter
import UIKit

/// iOS side of the platform channels (Android: MainActivity.kt).
/// Registered as an in-app plugin so it works with the implicit engine.
final class NativeBridgePlugin: NSObject, FlutterPlugin {
  private static let methodChannel = "com.sachincharles.native_bridge/methods"
  private static let batteryChannel = "com.sachincharles.native_bridge/battery"

  private var pendingScan: FlutterResult?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NativeBridgePlugin()
    let methods = FlutterMethodChannel(name: methodChannel, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)

    let battery = FlutterEventChannel(name: batteryChannel, binaryMessenger: registrar.messenger())
    battery.setStreamHandler(BatteryStreamHandler())
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDeviceInfo":
      result(deviceInfo())
    case "getBatteryLevel":
      result(BatteryStreamHandler.currentLevel())
    case "haptic":
      let pattern = (call.arguments as? [String: Any])?["pattern"] as? String ?? "light"
      Haptics.play(pattern)
      result(nil)
    case "checkCameraPermission":
      result(Self.cameraStatus())
    case "requestCameraPermission":
      AVCaptureDevice.requestAccess(for: .video) { _ in
        DispatchQueue.main.async { result(Self.cameraStatus()) }
      }
    case "scanQrCode":
      startScan(result)
    case "openAppSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func deviceInfo() -> [String: Any] {
    let device = UIDevice.current
    #if targetEnvironment(simulator)
      let physical = false
    #else
      let physical = true
    #endif
    return [
      "platform": "ios",
      "manufacturer": "Apple",
      "model": Self.modelIdentifier(),
      "osVersion": "\(device.systemName) \(device.systemVersion)",
      "isPhysicalDevice": physical,
    ]
  }

  /// e.g. "iPhone15,2" (more precise than UIDevice.model, which is just "iPhone").
  private static func modelIdentifier() -> String {
    if let simModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
      return simModel
    }
    var info = utsname()
    uname(&info)
    return withUnsafeBytes(of: &info.machine) { buffer in
      String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
    }
  }

  private static func cameraStatus() -> String {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: return "granted"
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    // iOS only shows the prompt once; after a denial only Settings can change it.
    case .denied: return "permanentlyDenied"
    @unknown default: return "denied"
    }
  }

  private func startScan(_ result: @escaping FlutterResult) {
    guard pendingScan == nil else {
      result(FlutterError(code: "busy", message: "The scanner is already open", details: nil))
      return
    }
    guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
      result(FlutterError(code: "permission_denied", message: "Camera permission is required to scan", details: nil))
      return
    }
    guard let presenter = Self.topViewController() else {
      result(FlutterError(code: "no_ui", message: "No view controller to present the scanner", details: nil))
      return
    }
    pendingScan = result
    let scanner = QRScannerViewController { [weak self] outcome in
      switch outcome {
      case .success(let code): self?.pendingScan?(code)
      case .cancelled: self?.pendingScan?(nil)
      case .failure(let message):
        self?.pendingScan?(FlutterError(code: "scanner_error", message: message, details: nil))
      }
      self?.pendingScan = nil
    }
    scanner.modalPresentationStyle = .fullScreen
    presenter.present(scanner, animated: true)
  }

  private static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}

/// Streams battery level and state to Dart while it is listening.
final class BatteryStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  static func currentLevel() -> Int {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    return level < 0 ? -1 : Int((level * 100).rounded())  // -1 on the simulator
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    UIDevice.current.isBatteryMonitoringEnabled = true
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(emit), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    center.addObserver(self, selector: #selector(emit), name: UIDevice.batteryStateDidChangeNotification, object: nil)
    emit()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    UIDevice.current.isBatteryMonitoringEnabled = false
    sink = nil
    return nil
  }

  @objc private func emit() {
    let state: String
    switch UIDevice.current.batteryState {
    case .charging: state = "charging"
    case .full: state = "full"
    case .unplugged: state = "discharging"
    default: state = "unknown"
    }
    sink?(["level": Self.currentLevel(), "state": state])
  }
}

enum Haptics {
  static func play(_ pattern: String) {
    switch pattern {
    case "medium": UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    case "heavy": UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    case "success": UINotificationFeedbackGenerator().notificationOccurred(.success)
    case "error": UINotificationFeedbackGenerator().notificationOccurred(.error)
    default: UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }
}
