import Foundation
import NetworkExtension

@objc protocol VPNXPCProtocol {
    func startVPN(config: String, with reply: @escaping (Bool) -> Void)
    func stopVPN(with reply: @escaping (Bool) -> Void)
    func status(with reply: @escaping (Int) -> Void)
}

let connection = NSXPCConnection(serviceName: "com.resistine.ResistineVPNXPC")
connection.remoteObjectInterface = NSXPCInterface(with: VPNXPCProtocol.self)
connection.resume()

guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
    print("Error: \(error.localizedDescription)")
    exit(1)
}) as? VPNXPCProtocol else {
    print("Error: Could not create XPC proxy")
    exit(1)
}

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("Usage: resistine-vpn <command> [args]")
    print("Commands: start <config>, stop, status")
    exit(1)
}

let command = arguments[1]
let group = DispatchGroup()
group.enter()

switch command {
case "start":
    guard arguments.count > 2 else {
        print("Error: Missing config for start command")
        exit(1)
    }
    let config = arguments[2]
    proxy.startVPN(config: config) { success in
        print(success ? "VPN started successfully" : "Failed to start VPN")
        group.leave()
    }
case "stop":
    proxy.stopVPN { success in
        print(success ? "VPN stopped successfully" : "Failed to stop VPN")
        group.leave()
    }
case "status":
    proxy.status { statusRaw in
        let status = NEVPNStatus(rawValue: statusRaw) ?? .invalid
        switch status {
        case .connected, .connecting, .reasserting:
            print("Connected")
        default:
            print("Disconnected")
        }
        group.leave()
    }
default:
    print("Unknown command: \(command)")
    exit(1)
}

_ = group.wait(timeout: .now() + 10)
connection.invalidate()
