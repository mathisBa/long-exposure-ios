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

    var body: some View {
        ZStack(alignment: .top) {
            LongExposureCameraView(onFinished: onCaptured)
                .ignoresSafeArea()

            HStack {
                Button("Retour") {
                    onBack()
                }
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.35))
                .foregroundStyle(.white)
                .clipShape(Capsule())

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
            .padding(.top, 12)
            .padding(.horizontal, 16)
        }
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
    var onFinished: (UIImage) -> Void = { _ in }

    func makeUIViewController(context: Context) -> LongExposureViewController {
        let controller = LongExposureViewController()
        controller.onFinishedCapture = onFinished
        return controller
    }

    func updateUIViewController(_ uiViewController: LongExposureViewController, context: Context) {
    }
}
