import Flutter
import UIKit

public class FaceLivePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "face_live", binaryMessenger: registrar.messenger())
    let instance = FaceLivePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register platform view factory
    let factory = FaceLivenessCameraViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "face_liveness_camera")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
