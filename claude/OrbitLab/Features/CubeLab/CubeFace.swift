import UIKit

/// The six sides of the cube, in the order `SCNBox` expects its materials.
enum CubeFace: Int, CaseIterable {
    case front, right, back, left, top, bottom

    var title: String {
        switch self {
        case .front: return "Nav"
        case .right: return "Power"
        case .back: return "Comms"
        case .left: return "Thermal"
        case .top: return "Dock"
        case .bottom: return "Cargo"
        }
    }

    var symbolName: String {
        switch self {
        case .front: return "location.north.line.fill"
        case .right: return "bolt.fill"
        case .back: return "antenna.radiowaves.left.and.right"
        case .left: return "thermometer"
        case .top: return "target"
        case .bottom: return "shippingbox.fill"
        }
    }

    var color: UIColor {
        switch self {
        case .front: return UIColor(red: 0.16, green: 0.44, blue: 0.86, alpha: 1)
        case .right: return UIColor(red: 0.92, green: 0.55, blue: 0.13, alpha: 1)
        case .back: return UIColor(red: 0.13, green: 0.68, blue: 0.56, alpha: 1)
        case .left: return UIColor(red: 0.74, green: 0.24, blue: 0.44, alpha: 1)
        case .top: return UIColor(red: 0.36, green: 0.30, blue: 0.78, alpha: 1)
        case .bottom: return UIColor(red: 0.55, green: 0.58, blue: 0.63, alpha: 1)
        }
    }
}

/// Renders the cube faces from SF Symbols and text instead of shipping bitmap assets.
enum CubeFaceImageFactory {
    static func makeImage(for face: CubeFace, size: CGFloat = 512) -> UIImage {
        let canvas = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { context in
            face.color.setFill()
            context.fill(CGRect(origin: .zero, size: canvas))

            // Subtle panel lines so each face reads as hardware, not a flat colour.
            UIColor.white.withAlphaComponent(0.16).setStroke()
            let inset = size * 0.08
            let border = UIBezierPath(roundedRect: CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2), cornerRadius: size * 0.06)
            border.lineWidth = size * 0.012
            border.stroke()

            let configuration = UIImage.SymbolConfiguration(pointSize: size * 0.34, weight: .semibold)
            if let symbol = UIImage(systemName: face.symbolName, withConfiguration: configuration)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let origin = CGPoint(x: (size - symbol.size.width) / 2, y: size * 0.30 - symbol.size.height / 2)
                symbol.draw(at: origin)
            }

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size * 0.12, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            let titleRect = CGRect(x: 0, y: size * 0.52, width: size, height: size * 0.18)
            face.title.draw(in: titleRect, withAttributes: attributes)

            let indexAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: size * 0.09, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.75),
                .paragraphStyle: paragraph
            ]
            let indexRect = CGRect(x: 0, y: size * 0.74, width: size, height: size * 0.14)
            "FACE \(face.rawValue + 1)".draw(in: indexRect, withAttributes: indexAttributes)
        }
    }
}
