import Foundation

class ResistineVPNXPC: NSObject, VPNXPCProtocol {
    func startVPN(config: String, with reply: @escaping (Bool) -> Void) {
        NSLog("XPC: startVPN called")
        VPNController.shared.start(config: config, completionHandler: reply)
    }
    
    func stopVPN(with reply: @escaping (Bool) -> Void) {
        NSLog("XPC: stopVPN called")
        VPNController.shared.stop(completionHandler: reply)
    }
    
    func status(with reply: @escaping (Int) -> Void) {
        NSLog("XPC: status called")
        VPNController.shared.status { status in
            reply(status.rawValue)
        }
    }
}

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: VPNXPCProtocol.self)
        let exportedObject = ResistineVPNXPC()
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}

// Main entry point for the XPC service
let delegate = ServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
