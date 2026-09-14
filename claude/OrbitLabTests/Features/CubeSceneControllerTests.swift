import Metal
import SceneKit
import XCTest
@testable import OrbitLab

@MainActor
final class CubeSceneControllerTests: XCTestCase {
    func test_cubeIsBuiltWithSixDistinctFaceMaterials() {
        let controller = CubeSceneController()

        XCTAssertEqual(controller.faceMaterialCount, 6)
        XCTAssertEqual(CubeFace.allCases.count, 6)
        XCTAssertEqual(Set(CubeFace.allCases.map(\.title)).count, 6)
        XCTAssertEqual(Set(CubeFace.allCases.map(\.symbolName)).count, 6)
        XCTAssertEqual(Set(CubeFace.allCases.map { $0.color.description }).count, 6)
    }

    func test_applyStartsAndStopsTheSpinAndTracksTheAppliedSpeed() {
        let controller = CubeSceneController()

        controller.apply(isAnimating: true, speed: 2.0)
        XCTAssertTrue(controller.isAnimating)
        XCTAssertEqual(controller.appliedSpeed, 2.0, accuracy: 0.0001)

        controller.apply(isAnimating: false, speed: 2.0)
        XCTAssertFalse(controller.isAnimating)
    }

    func test_resetRestoresTheDefaultOrientationAndSpeed() {
        let controller = CubeSceneController()

        controller.apply(isAnimating: true, speed: 3.0)
        controller.rotate(deltaX: 120, deltaY: -60)
        controller.reset()

        XCTAssertFalse(controller.isAnimating)
        XCTAssertEqual(controller.appliedSpeed, CubeSettings.default.speed, accuracy: 0.0001)
    }

    func test_speedOutsideTheSupportedRangeIsClampedBeforeReachingTheScene() {
        let controller = CubeSceneController()

        controller.apply(isAnimating: true, speed: 250)

        XCTAssertEqual(controller.appliedSpeed, CubeSettings.speedRange.upperBound, accuracy: 0.0001)
    }
}

/// Proves the cube is real 3D geometry that actually rasterises, not a placeholder view.
@MainActor
final class CubeSceneRenderingTests: XCTestCase {
    func test_sceneRendersVisibleCubeGeometryOffscreen() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("No Metal device on this host")
        }
        let controller = CubeSceneController()
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = controller.scene
        renderer.pointOfView = controller.scene.rootNode.childNodes.first { $0.camera != nil }

        let image = renderer.snapshot(atTime: 0, with: CGSize(width: 256, height: 256), antialiasingMode: .none)
        let colours = try Self.distinctColours(in: image)

        XCTAssertGreaterThan(colours.count, 8, "A rendered textured cube must contain many distinct colours")
    }

    private static func distinctColours(in image: UIImage) throws -> Set<UInt32> {
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt32](repeating: 0, count: width * height)
        let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        try XCTUnwrap(context).draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Set(pixels)
    }
}
