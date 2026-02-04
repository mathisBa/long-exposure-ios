import Foundation
import Network

struct DroneCommand {
    let text: String
    let waitAfter: TimeInterval
}

final class DroneSequenceManager {
    static let shared = DroneSequenceManager()

    private let queue = DispatchQueue(label: "drone.sequence.queue")
    private let sender = TelloUDPSender()
    private var isRunning = false

    private let commandSpacing: TimeInterval = 1.2

    func startSequence(shape: ShapeChoice?, completion: (() -> Void)? = nil) {
        guard let shape else { return }
        queue.async {
            guard !self.isRunning else { return }
            self.isRunning = true
            let commands = self.buildSequence(for: shape)
            self.run(commands, index: 0, completion: completion)
        }
    }

    private func run(_ commands: [DroneCommand], index: Int, completion: (() -> Void)?) {
        guard index < commands.count else {
            isRunning = false
            if let completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
            return
        }

        let command = commands[index]
        sender.send(command.text)
        queue.asyncAfter(deadline: .now() + command.waitAfter) {
            self.run(commands, index: index + 1, completion: completion)
        }
    }

    private func buildSequence(for shape: ShapeChoice) -> [DroneCommand] {
        var commands: [DroneCommand] = [
            DroneCommand(text: "command", waitAfter: commandSpacing),
            DroneCommand(text: "speed 25", waitAfter: commandSpacing),
            DroneCommand(text: "takeoff", waitAfter: commandSpacing)
        ]

        switch shape {
        case .square:
            commands.append(contentsOf: [
                DroneCommand(text: "up 50", waitAfter: commandSpacing),
                DroneCommand(text: "right 50", waitAfter: commandSpacing),
                DroneCommand(text: "down 50", waitAfter: commandSpacing),
                DroneCommand(text: "left 50", waitAfter: commandSpacing)
            ])
        case .rectangle:
            commands.append(contentsOf: [
                DroneCommand(text: "up 40", waitAfter: commandSpacing),
                DroneCommand(text: "right 80", waitAfter: commandSpacing),
                DroneCommand(text: "down 40", waitAfter: commandSpacing),
                DroneCommand(text: "left 80", waitAfter: commandSpacing)
            ])
        case .triangle:
            commands.append(contentsOf: [
                DroneCommand(text: "forward 60", waitAfter: commandSpacing),
                DroneCommand(text: "cw 120", waitAfter: commandSpacing),
                DroneCommand(text: "forward 60", waitAfter: commandSpacing),
                DroneCommand(text: "cw 120", waitAfter: commandSpacing),
                DroneCommand(text: "forward 60", waitAfter: commandSpacing),
                DroneCommand(text: "cw 120", waitAfter: commandSpacing)
            ])
        }

        commands.append(DroneCommand(text: "land", waitAfter: commandSpacing))
        return commands
    }
}

final class TelloUDPSender {
    private let queue = DispatchQueue(label: "tello.udp.queue")
    private let connection: NWConnection

    init() {
        let host = NWEndpoint.Host("192.168.10.1")
        let port = NWEndpoint.Port(integerLiteral: 8889)
        connection = NWConnection(host: host, port: port, using: .udp)
        connection.start(queue: queue)
    }

    func send(_ command: String) {
        let data = Data(command.utf8)
        connection.send(content: data, completion: .contentProcessed { _ in })
    }
}
