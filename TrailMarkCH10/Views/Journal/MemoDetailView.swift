//
//  MemoDetailView.swift
//  TrailMark (iOS)
//
//  Course 1.2 — plays a memo back. Video uses AVKit's VideoPlayer; audio uses
//  the shared TrailmarkCore.AudioPlayer, drawn as a scrubbable waveform. Shows
//  the capture location if geotagged (Course 1.4).
//

import SwiftUI
import AVKit
import MapKit
import TrailMarkCH10Core

struct MemoDetailView: View {
    @Environment(AppModel.self) private var model
    let memo: MediaMemo

    @State private var audioPlayer = AudioPlayer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch memo.kind {
                case .video:
                    VideoPlayer(player: AVPlayer(url: model.media.url(for: memo)))
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .audio:
                    audioControls
                }

                metadata

                if let coordinate = memo.coordinate {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))) {
                        Marker(memo.title, coordinate: coordinate)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)
                }
            }
            .padding()
        }
        .navigationTitle(memo.kind.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { audioPlayer.stop() }
    }

    private var audioControls: some View {
        VStack(spacing: 12) {
            waveform
                .frame(height: 88)
                .frame(maxWidth: .infinity)

            HStack {
                Text(timeString(audioPlayer.currentTime))
                Spacer()
                Text("-" + timeString(max(audioPlayer.duration - audioPlayer.currentTime, 0)))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)

            Button {
                audioPlayer.isPlaying ? audioPlayer.pause() : audioPlayer.play(url: audioURL)
            } label: {
                Label(audioPlayer.isPlaying ? "Pause" : "Play",
                      systemImage: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        // Decode the waveform once the view is on screen; the player is ready
        // to go before the user reaches for the play button.
        .task(id: memo.id) { await audioPlayer.prepare(url: audioURL) }
        // Drive the playhead and the output meter while playing.
        .task(id: audioPlayer.isPlaying) {
            while audioPlayer.isPlaying && !Task.isCancelled {
                audioPlayer.tick()
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }

    @ViewBuilder
    private var waveform: some View {
        if audioPlayer.waveform.isEmpty {
            // Nothing to draw yet: either still decoding, or the file wouldn't
            // decode at all and the old static glyph is the honest fallback.
            ZStack {
                Image(systemName: "waveform")
                    .font(.system(size: 44))
                    .foregroundStyle(.teal.opacity(0.4))
                    .symbolEffect(.variableColor, isActive: audioPlayer.isPlaying)
                if audioPlayer.isLoadingWaveform {
                    ProgressView()
                }
            }
        } else {
            AudioWaveformView(samples: audioPlayer.waveform,
                              progress: audioPlayer.progress,
                              level: audioPlayer.level,
                              isPlaying: audioPlayer.isPlaying) { fraction in
                audioPlayer.seek(to: fraction * audioPlayer.duration)
            }
        }
    }

    private var audioURL: URL {
        model.media.url(for: memo)
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Recorded", value: memo.createdAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Duration", value: memo.durationText)
            if memo.coordinate != nil {
                LabeledContent("Location", value: "Geotagged")
            }
        }
        .font(.subheadline)
    }
}
