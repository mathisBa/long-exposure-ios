import Foundation

struct DroneCommand {
    let text: String
    let waitAfter: TimeInterval
}

enum DronePatternLibrary {
    static func commands(for drawingChoice: DrawingChoice, spacing: TimeInterval) -> [DroneCommand] {
        switch drawingChoice {
        case .shape(let shape):
            return shapeCommands(for: shape, spacing: spacing)
        case .letter(let letter):
            return letterCommands(for: letter, spacing: spacing)
        }
    }

    private static func shapeCommands(for shape: ShapeChoice, spacing: TimeInterval) -> [DroneCommand] {
        switch shape {
        case .square:
            return [
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "forward 50", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "back 50", waitAfter: spacing)
            ]
        case .rectangle:
            return [
                DroneCommand(text: "up 80", waitAfter: spacing),
                DroneCommand(text: "forward 40", waitAfter: spacing),
                DroneCommand(text: "down 80", waitAfter: spacing),
                DroneCommand(text: "back 40", waitAfter: spacing)
            ]
        case .triangle:
            return [
                DroneCommand(text: "up 60", waitAfter: spacing),
                DroneCommand(text: "forward 60", waitAfter: spacing),
                DroneCommand(text: "down 60", waitAfter: spacing),
                DroneCommand(text: "back 60", waitAfter: spacing)
            ]
        }
    }

    private static func letterCommands(for letter: LetterChoice, spacing: TimeInterval) -> [DroneCommand] {
        switch letter {
        case .A:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "down 100", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing)
            ]
        case .B:
            return [
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "down 100", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing)
            ]
        case .C:
            return [
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing)
            ]
        case .D:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "go 50 0 -50 25", waitAfter: spacing),
                DroneCommand(text: "go -50 0 -50 25", waitAfter: spacing)
            ]
        case .E:
            return [
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing)
            ]
        case .F:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing)
            ]
        case .G:
            return [
                DroneCommand(text: "right 25", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing)
            ]
        case .H:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "down 100", waitAfter: spacing)
            ]
        case .I:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing)
            ]
        case .J:
            return [
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing)
            ]
        case .K:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "go 50 0 50 25", waitAfter: spacing),
                DroneCommand(text: "go -50 0 -50 25", waitAfter: spacing),
                DroneCommand(text: "go 50 0 -50 25", waitAfter: spacing)
            ]
        case .L:
            return [
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing)
            ]
        case .M:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 25", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "right 25", waitAfter: spacing),
                DroneCommand(text: "down 100", waitAfter: spacing)
            ]
        case .N:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "go 50 0 -100 25", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing)
            ]
        case .O:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "down 100", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing)
            ]
        case .P:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing)
            ]
        case .Q:
            return [
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "down 100", waitAfter: spacing),
                DroneCommand(text: "go -25 0 25 25", waitAfter: spacing),
                DroneCommand(text: "go 50 0 -50 25", waitAfter: spacing)
            ]
        case .R:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "go 50 0 -50 25", waitAfter: spacing)
            ]
        case .S:
            return [
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing)
            ]
        case .T:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "left 25", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing)
            ]
        case .U:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "down 100", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing)
            ]
        case .V:
            return [
                DroneCommand(text: "go -25 0 100 25", waitAfter: spacing),
                DroneCommand(text: "go 25 0 -100 25", waitAfter: spacing),
                DroneCommand(text: "go 25 0 100 25", waitAfter: spacing)
            ]
        case .W:
            return [
                DroneCommand(text: "up 100", waitAfter: spacing),
                DroneCommand(text: "down 100", waitAfter: spacing),
                DroneCommand(text: "right 25", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "right 25", waitAfter: spacing),
                DroneCommand(text: "up 100", waitAfter: spacing)
            ]
        case .X:
            return [
                DroneCommand(text: "go 50 0 100 25", waitAfter: spacing),
                DroneCommand(text: "go -25 0 -50 25", waitAfter: spacing),
                DroneCommand(text: "go -25 0 50 25", waitAfter: spacing),
                DroneCommand(text: "go 50 0 -100 25", waitAfter: spacing)
            ]
        case .Y:
            return [
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "left 25", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing),
                DroneCommand(text: "down 50", waitAfter: spacing),
                DroneCommand(text: "right 50", waitAfter: spacing),
                DroneCommand(text: "up 50", waitAfter: spacing)
            ]
        case .Z:
            return [
                DroneCommand(text: "left 50", waitAfter: spacing),
                DroneCommand(text: "go 50 0 100 25", waitAfter: spacing),
                DroneCommand(text: "left 50", waitAfter: spacing)
            ]
        }
    }
}
