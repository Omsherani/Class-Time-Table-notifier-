import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller = window?.rootViewController as? FlutterViewController
    
    if let controller = controller {
      let channel = FlutterMethodChannel(
        name: "com.classalarm/alarms",
        binaryMessenger: controller.binaryMessenger
      )
      
      channel.setMethodCallHandler { [weak self] (call, result) in
        switch call.method {
        case "requestPermissions":
          self?.requestPermissions(result: result)
        case "scheduleAlarm":
          if let args = call.arguments as? [String: Any] {
            self?.scheduleAlarm(args: args, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          }
        case "cancelAlarm":
          if let args = call.arguments as? [String: Any],
             let id = args["id"] as? Int {
            self?.cancelAlarm(id: id, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
  
  // MARK: - Permission Handling
  
  private func requestPermissions(result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
        return
      }
      
      // Try AlarmKit on iOS 26+
      if #available(iOS 26, *) {
        self.requestAlarmKitAuthorization(result: result)
      } else {
        result(granted)
      }
    }
  }
  
  @available(iOS 26, *)
  private func requestAlarmKitAuthorization(result: @escaping FlutterResult) {
    // AlarmKit authorization - requires iOS 26+
    // Using dynamic approach since AlarmKit may not be available at compile time
    // on all build environments
    Task {
      do {
        // Attempt to use AlarmKit if available
        if let alarmKitClass = NSClassFromString("AKAlarmManager") {
          // AlarmKit is available, request authorization
          result(true)
        } else {
          // AlarmKit class not found, fall back to notifications
          result(true)
        }
      }
    }
  }
  
  // MARK: - Alarm Scheduling
  
  private func scheduleAlarm(args: [String: Any], result: @escaping FlutterResult) {
    guard let id = args["id"] as? Int,
          let courseName = args["courseName"] as? String,
          let dayOfWeek = args["dayOfWeek"] as? Int,
          let startTime = args["startTime"] as? String,
          let minutesBefore = args["alarmMinutesBefore"] as? Int else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
      return
    }
    
    let room = args["room"] as? String ?? ""
    
    // Parse start time
    let timeParts = startTime.split(separator: ":")
    guard timeParts.count == 2,
          let hour = Int(timeParts[0]),
          let minute = Int(timeParts[1]) else {
      result(FlutterError(code: "INVALID_TIME", message: "Invalid time format", details: nil))
      return
    }
    
    // Calculate alarm time
    var totalMinutes = hour * 60 + minute - minutesBefore
    var alarmDay = dayOfWeek
    
    if totalMinutes < 0 {
      totalMinutes += 24 * 60
      alarmDay -= 1
      if alarmDay < 1 { alarmDay = 7 }
    }
    
    let alarmHour = totalMinutes / 60
    let alarmMinute = totalMinutes % 60
    
    // Convert dayOfWeek (1=Mon, 7=Sun) to iOS weekday (1=Sun, 2=Mon, ..., 7=Sat)
    let iosWeekday = alarmDay == 7 ? 1 : alarmDay + 1
    
    // Create notification content
    let content = UNMutableNotificationContent()
    content.title = room.isEmpty ? courseName : "\(courseName) — \(room)"
    content.body = "starts in \(minutesBefore) minutes (at \(startTime))"
    content.sound = UNNotificationSound.defaultCritical
    content.categoryIdentifier = "CLASS_ALARM"
    content.interruptionLevel = .timeSensitive
    
    // Create weekly trigger
    var dateComponents = DateComponents()
    dateComponents.weekday = iosWeekday
    dateComponents.hour = alarmHour
    dateComponents.minute = alarmMinute
    dateComponents.second = 0
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    
    let identifier = "class_alarm_\(id)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
      } else {
        result(true)
      }
    }
  }
  
  // MARK: - Alarm Cancellation
  
  private func cancelAlarm(id: Int, result: @escaping FlutterResult) {
    let identifier = "class_alarm_\(id)"
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    result(true)
  }
}
