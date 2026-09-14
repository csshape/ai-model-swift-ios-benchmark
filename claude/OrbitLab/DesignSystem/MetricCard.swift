import SwiftUI

/// Reusable headline-number card used across the dashboard.
struct MetricCard: View {
    let metric: MissionMetric
    let accent: AccentChoice

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: metric.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent.color)
                Text(metric.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Image(systemName: metric.trend.symbolName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            Text(metric.formattedValue)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metric.title)
        .accessibilityValue("\(metric.formattedValue), \(metric.trend.accessibleDescription)")
    }
}

#if DEBUG
struct MetricCard_Previews: PreviewProvider {
    static var previews: some View {
        MetricCard(
            metric: MissionMetric(
                id: "thrust",
                title: "Main thrust",
                value: 84.2,
                unit: "kN",
                trend: .up,
                symbolName: "flame.fill"
            ),
            accent: .aurora
        )
        .padding()
        .background(Theme.background(for: .aurora))
        .previewLayout(.sizeThatFits)
    }
}
#endif
