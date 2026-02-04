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

enum FlowStep {
    case shape
    case color
    case photo
    case preview
}

struct ContentView: View {
    @State private var step: FlowStep = .shape
    @State private var selectedShape: ShapeChoice?
    @State private var selectedColor: Color = .blue
    @State private var previewImage: UIImage?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch step {
            case .shape:
                ShapeStepView(selected: $selectedShape) {
                    step = .color
                }
                .transition(.opacity)
            case .color:
                ColorStepView(selectedColor: $selectedColor) {
                    step = .photo
                } onBack: {
                    step = .shape
                }
                .transition(.opacity)
            case .photo:
                PhotoStepView(
                    shape: selectedShape,
                    color: selectedColor,
                    onBack: { step = .color },
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
        selectedShape = nil
        selectedColor = .blue
        step = .shape
    }
}

struct ShapeStepView: View {
    @Binding var selected: ShapeChoice?
    var onNext: () -> Void

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

            Button("Suivant") {
                onNext()
            }
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(selected == nil ? Color.gray.opacity(0.4) : Color.white)
            .foregroundStyle(selected == nil ? Color.white.opacity(0.6) : Color.black)
            .clipShape(Capsule())
            .disabled(selected == nil)
        }
        .padding(24)
    }
}

struct ColorStepView: View {
    @Binding var selectedColor: Color
    var onNext: () -> Void
    var onBack: () -> Void
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
    var shape: ShapeChoice?
    var color: Color
    var onBack: () -> Void
    var onCaptured: (UIImage) -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var isDroneSequenceDone = false
    @State private var isDroneRunning = false
    @State private var captureRequestID: UUID?
    @State private var isCapturing = false
    @State private var pulse = false
    @State private var canStartPictureWhileDroneRunning = false
    @State private var showFlightToast = false
    @State private var toastWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack(alignment: .top) {
            LongExposureCameraView(
                shape: shape,
                captureRequestID: captureRequestID,
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
                        if let shape {
                            Image(systemName: shape.systemImage)
                            Text(shape.rawValue)
                        } else {
                            Text("Aucune forme")
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
        }
        .safeAreaInset(edge: .bottom) {
            Button(primaryButtonTitle) {
                if isDroneRunning {
                    guard canStartPictureWhileDroneRunning else { return }
                    guard !isCapturing else { return }
                    isCapturing = true
                    captureRequestID = UUID()
                    return
                }
                guard !isDroneSequenceDone else {
                    guard !isCapturing else { return }
                    isCapturing = true
                    captureRequestID = UUID()
                    isDroneSequenceDone = false
                    return
                }
                isDroneRunning = true
                canStartPictureWhileDroneRunning = false
                DroneSequenceManager.shared.startSequence(shape: shape) {
                    isDroneRunning = false
                    isDroneSequenceDone = true
                    canStartPictureWhileDroneRunning = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if isDroneRunning {
                        canStartPictureWhileDroneRunning = true
                    }
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
        .onChange(of: captureRequestID) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isCapturing = false
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

    private var buttonTitle: String {
        if isDroneRunning {
            return "Start picture"
        }
        return isDroneSequenceDone ? "Start picture" : "Start drone"
    }

    private var primaryButtonTitle: String {
        if isDroneRunning {
            return "Commencer la captation"
        }
        return isDroneSequenceDone ? "Commencer la captation" : "Démarrer le drone"
    }

    private var primaryButtonEnabled: Bool {
        if isDroneRunning {
            return canStartPictureWhileDroneRunning && !isCapturing
        }
        return !isCapturing
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
    var shape: ShapeChoice?
    var captureRequestID: UUID?
    var onFinished: (UIImage) -> Void = { _ in }

    func makeUIViewController(context: Context) -> LongExposureViewController {
        let controller = LongExposureViewController()
        controller.onFinishedCapture = onFinished
        controller.selectedShape = shape
        return controller
    }

    func updateUIViewController(_ uiViewController: LongExposureViewController, context: Context) {
        uiViewController.selectedShape = shape
        if let captureRequestID, captureRequestID != uiViewController.lastCaptureRequestID {
            uiViewController.lastCaptureRequestID = captureRequestID
            uiViewController.startCaptureExternally()
        }
    }
}
