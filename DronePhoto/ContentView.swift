//
//  ContentView.swift
//  DronePhoto
//
//  Created by Mathis Baveye on 12/01/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LongExposureCameraView()
            .ignoresSafeArea()
    }
}

struct LongExposureCameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LongExposureViewController {
        LongExposureViewController()
    }

    func updateUIViewController(_ uiViewController: LongExposureViewController, context: Context) {
    }
}
