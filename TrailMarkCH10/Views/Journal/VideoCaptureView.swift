import SwiftUI
import AVFoundation
import UIKit
import UniformTypeIdentifiers

struct VideoCaptureView: UIViewControllerRepresentable {
    /// Called with the captured file URL and its duration in seconds.
    let onCapture: (URL, TimeInterval) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        // The Simulator has no camera; fall back to the library there.
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        if picker.sourceType == .camera {
            picker.cameraCaptureMode = .video
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (URL, TimeInterval) -> Void

        init(onCapture: @escaping (URL, TimeInterval) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            guard let url = info[.mediaURL] as? URL else { return }

            // Load duration asynchronously to avoid using deprecated AVAsset.duration
            let asset = AVURLAsset(url: url)
            Task {
                do {
                    let durationTime: CMTime = try await asset.load(.duration)
                    let seconds = CMTimeGetSeconds(durationTime)
                    self.onCapture(url, seconds.isFinite ? seconds : 0)
                } catch {
                    // If loading duration fails, still return the URL with a default duration of 0
                    self.onCapture(url, 0)
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
