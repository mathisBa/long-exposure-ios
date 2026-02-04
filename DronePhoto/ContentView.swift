//
//  ContentView.swift
//  DronePhoto
//
//  Created by Mathis Baveye on 12/01/2026.
//

import SwiftUI

enum ShapeChoice: String, CaseIterable, Identifiable {
    case square = "Carré"
    case rectangle = "Rectangle"
    case triangle = "Triangle"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .square: return "square"
        case .rectangle: return "rectangle"
        case .triangle: return "triangle"
        }
    }
}

enum LetterChoice: String, CaseIterable, Identifiable {
    case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z

    var id: String { rawValue }
}

enum DigitChoice: String, CaseIterable, Identifiable {
    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"

    var id: String { rawValue }
}

enum DrawMode {
    case shape
    case letter
    case digit
    case custom
}

enum DrawingChoice {
    case shape(ShapeChoice)
    case letter(LetterChoice)
    case digit(DigitChoice)
    case custom(CustomPath)

    var displayName: String {
        switch self {
        case .shape(let shape): return shape.rawValue
        case .letter(let letter): return "Lettre \(letter.rawValue)"
        case .digit(let digit): return "Chiffre \(digit.rawValue)"
        case .custom: return "Chemin perso"
        }
    }

    var systemImage: String? {
        switch self {
        case .shape(let shape): return shape.systemImage
        case .letter, .digit: return nil
        case .custom: return "point.topleft.down.curvedto.point.bottomright.up"
        }
    }
}

enum FlowStep {
    case color
    case mode
    case shape
    case letter
    case digit
    case custom
    case photo
    case preview
}

struct ContentView: View {
    @State private var step: FlowStep = .color
    @State private var selectedMode: DrawMode?
    @State private var selectedShape: ShapeChoice?
    @State private var selectedLetter: LetterChoice?
    @State private var selectedDigit: DigitChoice?
    @State private var customPath = CustomPath(points: [])
    @State private var selectedColor: Color = .blue
    @State private var previewImage: UIImage?

    var body: some View {
        ZStack {
            selectedColor
                .ignoresSafeArea()
            LinearGradient(
                colors: [Color.black.opacity(0.45), Color.black.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch step {
            case .color:
                ColorStepView(selectedColor: $selectedColor, onNext: {
                    step = .mode
                }, onBack: nil)
                .transition(.opacity)
            case .mode:
                ModeStepView(selectedMode: $selectedMode, onBack: {
                    step = .color
                }) { mode in
                    switch mode {
                    case .shape:
                        step = .shape
                    case .letter:
                        step = .letter
                    case .digit:
                        step = .digit
                    case .custom:
                        step = .custom
                    }
                }
                .transition(.opacity)
            case .shape:
                ShapeStepView(selected: $selectedShape) {
                    step = .photo
                } onBack: {
                    step = .mode
                }
                .transition(.opacity)
            case .letter:
                LetterStepView(selected: $selectedLetter) {
                    step = .photo
                } onBack: {
                    step = .mode
                }
                .transition(.opacity)
            case .digit:
                DigitStepView(selected: $selectedDigit) {
                    step = .photo
                } onBack: {
                    step = .mode
                }
                .transition(.opacity)
            case .custom:
                CustomPathStepView(path: $customPath) {
                    step = .photo
                } onBack: {
                    step = .mode
                }
                .transition(.opacity)
            case .photo:
                PhotoStepView(
                    drawingChoice: currentDrawingChoice,
                    color: selectedColor,
                    onBack: {
                        switch selectedMode {
                        case .shape:
                            step = .shape
                        case .letter:
                            step = .letter
                        case .digit:
                            step = .digit
                        case .custom:
                            step = .custom
                        case .none:
                            step = .mode
                        }
                    },
                    onCaptured: { image in
                        previewImage = image
                        step = .preview
                    }
                )
                .transition(.opacity)
            case .preview:
                PreviewStepView(
                    image: previewImage,
                    onRestart: resetFlow
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    private func resetFlow() {
        selectedMode = nil
        selectedShape = nil
        selectedLetter = nil
        selectedDigit = nil
        customPath = CustomPath(points: [])
        selectedColor = .blue
        step = .color
    }

    private var currentDrawingChoice: DrawingChoice? {
        switch selectedMode {
        case .shape:
            if let selectedShape {
                return .shape(selectedShape)
            }
        case .letter:
            if let selectedLetter {
                return .letter(selectedLetter)
            }
        case .digit:
            if let selectedDigit {
                return .digit(selectedDigit)
            }
        case .custom:
            if customPath.points.count >= 2 {
                return .custom(customPath)
            }
        case .none:
            break
        }
        return nil
    }
}

struct ModeStepView: View {
    @Binding var selectedMode: DrawMode?
    var onBack: () -> Void
    var onNext: (DrawMode) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Choisis un type")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Button {
                selectedMode = .shape
                onNext(.shape)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.on.circle")
                        .font(.title2)
                    Text("Forme")
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)

            Button {
                selectedMode = .letter
                onNext(.letter)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "textformat")
                        .font(.title2)
                    Text("Lettre")
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)

            Button {
                selectedMode = .digit
                onNext(.digit)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .font(.title2)
                    Text("Chiffre")
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)

            Button {
                selectedMode = .custom
                onNext(.custom)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.title2)
                    Text("Chemin")
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)

            Button("Retour") {
                onBack()
            }
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.15))
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .padding(24)
    }
}

struct ShapeStepView: View {
    @Binding var selected: ShapeChoice?
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Choisis une forme")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            ForEach(ShapeChoice.allCases) { shape in
                Button {
                    selected = shape
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: shape.systemImage)
                            .font(.title2)
                        Text(shape.rawValue)
                            .font(.title3.weight(.semibold))
                        Spacer()
                        if selected == shape {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selected == shape ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Button("Retour") {
                    onBack()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .foregroundStyle(.white)
                .clipShape(Capsule())

                Button("Suivant") {
                    onNext()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(selected == nil ? Color.gray.opacity(0.4) : Color.white)
                .foregroundStyle(selected == nil ? Color.white.opacity(0.6) : Color.black)
                .clipShape(Capsule())
                .disabled(selected == nil)
            }
        }
        .padding(24)
    }
}

struct LetterStepView: View {
    @Binding var selected: LetterChoice?
    var onNext: () -> Void
    var onBack: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 54), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Choisis une lettre")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(LetterChoice.allCases) { letter in
                    Button {
                        selected = letter
                    } label: {
                        Text(letter.rawValue)
                            .font(.title3.weight(.semibold))
                            .frame(width: 54, height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selected == letter ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                                    )
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                Button("Retour") {
                    onBack()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .foregroundStyle(.white)
                .clipShape(Capsule())

                Button("Suivant") {
                    onNext()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(selected == nil ? Color.gray.opacity(0.4) : Color.white)
                .foregroundStyle(selected == nil ? Color.white.opacity(0.6) : Color.black)
                .clipShape(Capsule())
                .disabled(selected == nil)
            }
        }
        .padding(24)
    }
}

struct DigitStepView: View {
    @Binding var selected: DigitChoice?
    var onNext: () -> Void
    var onBack: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 54), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Choisis un chiffre")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DigitChoice.allCases) { digit in
                    Button {
                        selected = digit
                    } label: {
                        Text(digit.rawValue)
                            .font(.title3.weight(.semibold))
                            .frame(width: 54, height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selected == digit ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                                    )
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                Button("Retour") {
                    onBack()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .foregroundStyle(.white)
                .clipShape(Capsule())

                Button("Suivant") {
                    onNext()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(selected == nil ? Color.gray.opacity(0.4) : Color.white)
                .foregroundStyle(selected == nil ? Color.white.opacity(0.6) : Color.black)
                .clipShape(Capsule())
                .disabled(selected == nil)
            }
        }
        .padding(24)
    }
}

struct CustomPathPoint: Hashable {
    let row: Int
    let col: Int
}

struct CustomPath: Equatable {
    var points: [CustomPathPoint]
}

struct CustomPathStepView: View {
    @Binding var path: CustomPath
    var onNext: () -> Void
    var onBack: () -> Void

    private let rows = 4
    private let cols = 3

    var body: some View {
        VStack(spacing: 18) {
            Text("Trace ton chemin")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            GeometryReader { proxy in
                let size = proxy.size
                let padding: CGFloat = 16
                let gridWidth = size.width - padding * 2
                let gridHeight = size.height - padding * 2
                let cellWidth = gridWidth / CGFloat(cols - 1)
                let cellHeight = gridHeight / CGFloat(rows - 1)

                ZStack {
                    Path { path in
                        for row in 0..<rows {
                            for col in 0..<cols {
                                let x = padding + CGFloat(col) * cellWidth
                                let y = padding + CGFloat(row) * cellHeight
                                path.addEllipse(in: CGRect(x: x - 7, y: y - 7, width: 14, height: 14))
                            }
                        }
                    }
                    .fill(Color.white.opacity(0.9))

                    if path.points.count >= 2 {
                        Path { line in
                            for (index, point) in path.points.enumerated() {
                                let x = padding + CGFloat(point.col) * cellWidth
                                let y = padding + CGFloat(point.row) * cellHeight
                                if index == 0 {
                                    line.move(to: CGPoint(x: x, y: y))
                                } else {
                                    line.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = min(max(value.location.x - padding, 0), gridWidth)
                            let y = min(max(value.location.y - padding, 0), gridHeight)
                            let col = Int(round(x / cellWidth))
                            let row = Int(round(y / cellHeight))
                            guard row >= 0, row < rows, col >= 0, col < cols else { return }
                            let point = CustomPathPoint(row: row, col: col)
                            if path.points.last != point {
                                guard let last = path.points.last else {
                                    path.points.append(point)
                                    return
                                }
                                let dRow = abs(point.row - last.row)
                                let dCol = abs(point.col - last.col)
                                guard (dRow + dCol) == 1 else { return }
                                path.points.append(point)
                            }
                        }
                )
            }
            .frame(height: 320)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )

            HStack(spacing: 12) {
                Button("Retour") {
                    onBack()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .foregroundStyle(.white)
                .clipShape(Capsule())

                Button("Effacer") {
                    path.points = []
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .foregroundStyle(.white)
                .clipShape(Capsule())

                Button("Suivant") {
                    onNext()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(path.points.count < 2 ? Color.gray.opacity(0.4) : Color.white)
                .foregroundStyle(path.points.count < 2 ? Color.white.opacity(0.6) : Color.black)
                .clipShape(Capsule())
                .disabled(path.points.count < 2)
            }
        }
        .padding(24)
    }
}
struct ColorStepView: View {
    @Binding var selectedColor: Color
    var onNext: () -> Void
    var onBack: (() -> Void)?
    @State private var dragOffset: CGFloat = 0

    private let swatches: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink
    ]

    var body: some View {
        VStack(spacing: 18) {
            Text("Choisis une couleur")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            ZStack {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 4)
                    )
                    .shadow(color: selectedColor.opacity(0.5), radius: 18, x: 0, y: 8)
            }

            ColorPicker("Couleur", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))

            HStack(spacing: 10) {
                ForEach(swatches.indices, id: \.self) { index in
                    let swatch = swatches[index]
                    Button {
                        selectedColor = swatch
                    } label: {
                        Circle()
                            .fill(swatch)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(selectedColor == swatch ? 1.0 : 0.3), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                if let onBack {
                    Button("Retour") {
                        onBack()
                    }
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }

                Button("Suivant") {
                    onNext()
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
        }
        .padding(24)
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    guard let onBack else { return }
                    let shouldGoBack = value.translation.width > 90 && abs(value.translation.height) < 60
                    dragOffset = 0
                    if shouldGoBack {
                        onBack()
                    }
                }
        )
    }
}

struct PhotoStepView: View {
    var drawingChoice: DrawingChoice?
    var color: Color
    var onBack: () -> Void
    var onCaptured: (UIImage) -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var isDroneRunning = false
    @State private var captureRequestID: UUID?
    @State private var stopCaptureRequestID: UUID?
    @State private var isCapturing = false
    @State private var pulse = false
    @State private var showFlightToast = false
    @State private var toastWorkItem: DispatchWorkItem?
    @State private var showDroneErrorToast = false
    @State private var droneErrorMessage = ""
    @State private var errorWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack(alignment: .top) {
            LongExposureCameraView(
                drawingChoice: drawingChoice,
                captureRequestID: captureRequestID,
                stopCaptureRequestID: stopCaptureRequestID,
                onFinished: onCaptured
            )
                .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    if !isDroneRunning {
                        Button("Retour") {
                            onBack()
                        }
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.35))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        if let drawingChoice {
                            if let systemImage = drawingChoice.systemImage {
                                Image(systemName: systemImage)
                            }
                            Text(drawingChoice.displayName)
                        } else {
                            Text("Aucun choix")
                        }
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.35))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }

                if isDroneRunning {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Drone en cours...")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Capsule())
                    .scaleEffect(pulse ? 1.04 : 1.0)
                    .opacity(pulse ? 1.0 : 0.85)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            pulse = true
                        }
                    }
                    .onDisappear {
                        pulse = false
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
        }
        .overlay(alignment: .top) {
            if showFlightToast {
                Text("Vol en cours")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .transition(.opacity)
                    .padding(.top, 64)
            }
            if showDroneErrorToast {
                Text(droneErrorMessage)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.75))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .transition(.opacity)
                    .padding(.top, 104)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if isCapturing {
                    Button("Arrêter la capture") {
                        stopCapture()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.9))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                }
                if isDroneRunning {
                    Button("Stop drone") {
                        DroneSequenceManager.shared.emergencyLand()
                        showDroneError("Drone: atterrissage d'urgence")
                        stopCapture()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                }

                Button(primaryButtonTitle) {
                    guard let drawingChoice else { return }
                    isDroneRunning = true
                    DroneSequenceManager.shared.startSequence(
                        drawingChoice: drawingChoice,
                        onPatternStart: {
                            isCapturing = true
                            captureRequestID = UUID()
                        },
                        onPatternEnd: {
                            stopCapture()
                        },
                        onError: { message in
                        showDroneError(message)
                    }) {
                        isDroneRunning = false
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue.opacity(primaryButtonEnabled ? 1.0 : 0.6))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .disabled(!primaryButtonEnabled)
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    guard !isDroneRunning else {
                        showFlightToastMessage()
                        return
                    }
                    let shouldGoBack = value.translation.width > 90 && abs(value.translation.height) < 60
                    dragOffset = 0
                    if shouldGoBack {
                        onBack()
                    }
                }
        )
    }

    private var primaryButtonTitle: String {
        if isDroneRunning {
            return "Captation en cours"
        }
        return "Démarrer le drone"
    }

    private var primaryButtonEnabled: Bool {
        if isDroneRunning { return false }
        if case .custom(let path) = drawingChoice {
            return path.points.count >= 2
        }
        return drawingChoice != nil
    }

    private func showFlightToastMessage() {
        toastWorkItem?.cancel()
        withAnimation(.easeIn(duration: 0.15)) {
            showFlightToast = true
        }
        let workItem = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.2)) {
                showFlightToast = false
            }
        }
        toastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    private func showDroneError(_ message: String) {
        errorWorkItem?.cancel()
        droneErrorMessage = message
        withAnimation(.easeIn(duration: 0.15)) {
            showDroneErrorToast = true
        }
        let workItem = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.2)) {
                showDroneErrorToast = false
            }
        }
        errorWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
    }

    private func stopCapture() {
        guard isCapturing else { return }
        stopCaptureRequestID = UUID()
        isCapturing = false
    }
}

struct PreviewStepView: View {
    var image: UIImage?
    var onRestart: () -> Void

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                Spacer()
                Button("Nouvelle photo") {
                    onRestart()
                }
                .font(.headline)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(Capsule())
                .padding(.bottom, 24)
            }
        }
    }
}

struct LongExposureCameraView: UIViewControllerRepresentable {
    var drawingChoice: DrawingChoice?
    var captureRequestID: UUID?
    var stopCaptureRequestID: UUID?
    var onFinished: (UIImage) -> Void = { _ in }

    func makeUIViewController(context: Context) -> LongExposureViewController {
        let controller = LongExposureViewController()
        controller.onFinishedCapture = onFinished
        return controller
    }

    func updateUIViewController(_ uiViewController: LongExposureViewController, context: Context) {
        if let captureRequestID, captureRequestID != uiViewController.lastCaptureRequestID {
            uiViewController.lastCaptureRequestID = captureRequestID
            uiViewController.startCaptureExternally()
        }
        if let stopCaptureRequestID, stopCaptureRequestID != uiViewController.lastStopCaptureRequestID {
            uiViewController.lastStopCaptureRequestID = stopCaptureRequestID
            uiViewController.stopCaptureExternally()
        }
    }
}
