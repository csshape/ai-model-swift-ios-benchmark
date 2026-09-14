import SwiftUI

struct TelemetryGraphView: View {
    let points: [TelemetryPoint]
    let maxVisible: Int

    private var normalized: [CGPoint] {
        guard !points.isEmpty else { return [] }
        let values = points.map { $0.value }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let range = maxV - minV > 0 ? maxV - minV : 1
        let display = points.suffix(maxVisible)
        return display.enumerated().map { i, p in
            let x = CGFloat(i) / CGFloat(maxVisible - 1)
            let y = 1.0 - CGFloat((p.value - minV) / range)
            return CGPoint(x: x, y: y)
        }
    }

    var body: some View {
        GeometryReader { g in
            Path { path in
                for (i, p) in normalized.enumerated() {
                    let x = p.x * g.size.width
                    let y = p.y * g.size.height
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            Path { path in
                guard !normalized.isEmpty else { return }
                path.move(to: CGPoint(x: 0, y: g.size.height))
                for p in normalized {
                    path.addLine(to: CGPoint(x: p.x * g.size.width, y: p.y * g.size.height))
                }
                path.addLine(to: CGPoint(x: g.size.width, y: g.size.height))
                path.closeSubpath()
            }
            .fill(Color.blue.opacity(0.1))
        }
        .frame(height: 200)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .accessibilityLabel("Telemetry graph")
    }
}
