import SwiftUI

/// A hand drawn line chart. Swift Charts needs iOS 16, and the app targets iOS 15,
/// so the trace is built from `Path` directly.
struct TelemetryChartView: View {
    let samples: [TelemetrySample]
    let range: ClosedRange<Double>
    let accent: AccentChoice

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                gridLines(in: size)
                if samples.count > 1 {
                    filledArea(in: size)
                        .fill(
                            LinearGradient(
                                colors: [accent.color.opacity(0.35), accent.color.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    trace(in: size)
                        .stroke(accent.color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                } else {
                    Text("No telemetry yet")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            guard size.height > 0 else { return }
            for step in 0...4 {
                let y = size.height * CGFloat(step) / 4
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
    }

    private func point(for index: Int, value: Double, in size: CGSize) -> CGPoint {
        let count = max(samples.count - 1, 1)
        let x = size.width * CGFloat(index) / CGFloat(count)
        let span = range.upperBound - range.lowerBound
        let normalised = span > 0 ? (value - range.lowerBound) / span : 0.5
        let clamped = min(max(normalised, 0), 1)
        let y = size.height * (1 - CGFloat(clamped))
        return CGPoint(x: x, y: y)
    }

    private func trace(in size: CGSize) -> Path {
        Path { path in
            for (index, sample) in samples.enumerated() {
                let position = point(for: index, value: sample.value, in: size)
                if index == 0 {
                    path.move(to: position)
                } else {
                    path.addLine(to: position)
                }
            }
        }
    }

    private func filledArea(in size: CGSize) -> Path {
        Path { path in
            guard let first = samples.first, let last = samples.last else { return }
            path.move(to: CGPoint(x: point(for: 0, value: first.value, in: size).x, y: size.height))
            for (index, sample) in samples.enumerated() {
                path.addLine(to: point(for: index, value: sample.value, in: size))
            }
            path.addLine(to: CGPoint(x: point(for: samples.count - 1, value: last.value, in: size).x, y: size.height))
            path.closeSubpath()
        }
    }
}

#if DEBUG
struct TelemetryChartView_Previews: PreviewProvider {
    static var previews: some View {
        TelemetryChartView(
            samples: (0..<40).map { TelemetrySample(id: $0, value: SimulatedTelemetrySource.value(at: $0, in: .thrust)) },
            range: TelemetryChannel.thrust.range,
            accent: .aurora
        )
        .frame(height: 200)
        .padding()
        .background(Theme.background(for: .aurora))
        .previewLayout(.sizeThatFits)
    }
}
#endif
