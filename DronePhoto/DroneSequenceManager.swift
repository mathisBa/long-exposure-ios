import Foundation
import Network

final class DroneSequenceManager {
    static let shared = DroneSequenceManager()

    private let queue = DispatchQueue(label: "drone.sequence.queue")
    private let sender = TelloUDPClient()
    private var isRunning = false
    private var waitingForResponse = false
    private var pendingTimeout: DispatchWorkItem?
    private var currentCommands: [DroneCommand] = []
    private var currentIndex = 0
    private var completion: (() -> Void)?
    private var consecutiveTimeouts = 0
    private var onError: ((String) -> Void)?

    private let commandSpacing: TimeInterval = 0.0
    private let responseTimeout: TimeInterval = 6.0
    private let maxConsecutiveTimeouts = 2

    func startSequence(
        drawingChoice: DrawingChoice,
        onError: ((String) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        queue.async {
            guard !self.isRunning else { return }
            self.isRunning = true
            self.completion = completion
            self.onError = onError
            self.consecutiveTimeouts = 0
            let commands = self.buildSequence(for: drawingChoice)
            self.currentCommands = commands
            self.currentIndex = 0
            self.waitingForResponse = false
            self.sender.onMessage = { [weak self] message in
                self?.handleMessage(message)
            }
            self.sender.onStateChange = { [weak self] state in
                self?.handleStateChange(state)
            }
            self.sendNext()
        }
    }

    private func sendNext() {
        guard currentIndex < currentCommands.count else {
            isRunning = false
            if let completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
            return
        }

        let command = currentCommands[currentIndex]
        waitingForResponse = true
        sender.send(command.text)

        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.waitingForResponse else { return }
            self.waitingForResponse = false
            self.consecutiveTimeouts += 1
            if self.consecutiveTimeouts >= self.maxConsecutiveTimeouts {
                self.stopSequence(error: "Drone: pas de réponse (timeout)")
                return
            }
            self.currentIndex += 1
            self.sendNext()
        }
        pendingTimeout?.cancel()
        pendingTimeout = timeout
        queue.asyncAfter(deadline: .now() + responseTimeout, execute: timeout)
    }

    private func buildSequence(for drawingChoice: DrawingChoice) -> [DroneCommand] {
        var commands: [DroneCommand] = [
            DroneCommand(text: "command", waitAfter: commandSpacing),
            DroneCommand(text: "speed 25", waitAfter: commandSpacing),
            DroneCommand(text: "takeoff", waitAfter: commandSpacing)
        ]

        commands.append(contentsOf: DronePatternLibrary.commands(for: drawingChoice, spacing: commandSpacing))
        commands.append(DroneCommand(text: "land", waitAfter: commandSpacing))
        return commands
    }

    private func handleMessage(_ message: String) {
        queue.async {
            guard self.waitingForResponse else { return }
            if message.contains("ok") || message.contains("error") {
                self.waitingForResponse = false
                self.pendingTimeout?.cancel()
                self.consecutiveTimeouts = 0
                let delay = self.currentCommands[self.currentIndex].waitAfter
                self.currentIndex += 1
                if delay > 0 {
                    self.queue.asyncAfter(deadline: .now() + delay) {
                        self.sendNext()
                    }
                } else {
                    self.sendNext()
                }
            }
        }
    }

    private func handleStateChange(_ state: NWConnection.State) {
        switch state {
        case .failed, .cancelled:
            queue.async {
                self.stopSequence(error: "Drone: connexion perdue")
            }
        default:
            break
        }
    }

    private func stopSequence(error: String? = nil) {
        guard isRunning else { return }
        pendingTimeout?.cancel()
        waitingForResponse = false
        isRunning = false
        let errorHandler = onError
        onError = nil
        if let completion {
            DispatchQueue.main.async {
                completion()
            }
        }
        if let error, let errorHandler {
            DispatchQueue.main.async {
                errorHandler(error)
            }
        }
    }

    func emergencyLand() {
        queue.async {
            self.pendingTimeout?.cancel()
            self.waitingForResponse = false
            self.isRunning = false
            self.sender.send("land")
        }
    }
}

final class TelloUDPClient {
    private let queue = DispatchQueue(label: "tello.udp.queue")
    private let connection: NWConnection
    var onMessage: ((String) -> Void)?
    var onStateChange: ((NWConnection.State) -> Void)?

    init() {
        let host = NWEndpoint.Host("192.168.10.1")
        let port = NWEndpoint.Port(integerLiteral: 8889)
        connection = NWConnection(host: host, port: port, using: .udp)
        connection.stateUpdateHandler = { [weak self] state in
            self?.onStateChange?(state)
        }
        connection.start(queue: queue)
        receiveLoop()
    }

    func send(_ command: String) {
        let data = Data(command.utf8)
        connection.send(content: data, completion: .contentProcessed { _ in })
    }

    private func receiveLoop() {
        connection.receiveMessage { [weak self] data, _, _, _ in
            if let data, let text = String(data: data, encoding: .utf8) {
                self?.onMessage?(text)
            }
            self?.receiveLoop()
        }
    }
}
