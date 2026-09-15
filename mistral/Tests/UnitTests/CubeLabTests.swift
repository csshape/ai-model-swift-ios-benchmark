import XCTest
import SceneKit
@testable import OrbitLab

final class CubeLabTests: XCTestCase {
    
    func testStartPauseCubeRotation() {
        let mockStorage = MockStorageService()
        let viewModel = CubeViewModel(storageService: mockStorage)
        XCTAssertTrue(viewModel.isAutoRotating)
        viewModel.stopAutoRotation()
        XCTAssertFalse(viewModel.isAutoRotating)
        viewModel.startAutoRotation()
        XCTAssertTrue(viewModel.isAutoRotating)
    }
    
    func testSpeedChange() {
        let mockStorage = MockStorageService()
        let viewModel = CubeViewModel(storageService: mockStorage)
        let initialSpeed = viewModel.rotationSpeed
        viewModel.rotationSpeed = 2.0
        XCTAssertEqual(viewModel.rotationSpeed, 2.0)
        XCTAssertNotEqual(initialSpeed, viewModel.rotationSpeed)
    }
    
    func testResetRestoresDefaults() {
        let mockStorage = MockStorageService()
        let viewModel = CubeViewModel(storageService: mockStorage)
        viewModel.rotationSpeed = 3.0
        viewModel.isAutoRotating = false
        viewModel.reset()
        XCTAssertEqual(viewModel.rotationSpeed, 1.0)
        XCTAssertTrue(viewModel.isAutoRotating)
    }
    
    func testSceneCreation() {
        let mockStorage = MockStorageService()
        let viewModel = CubeViewModel(storageService: mockStorage)
        XCTAssertNotNil(viewModel.scene)
        XCTAssertNotNil(viewModel.cubeNode)
        XCTAssertNotNil(viewModel.cameraNode)
    }
    
    func testPersistenceOfSettings() {
        let mockStorage = MockStorageService()
        let viewModel = CubeViewModel(storageService: mockStorage)
        viewModel.rotationSpeed = 2.5
        viewModel.isAutoRotating = false
        
        do {
            let savedSettings: CubeSettings? = try mockStorage.load(forKey: StorageKey.cubeSettings)
            XCTAssertNotNil(savedSettings)
            XCTAssertEqual(savedSettings?.rotationSpeed, 2.5)
            XCTAssertEqual(savedSettings?.isAutoRotating, false)
        } catch {
            XCTFail("Failed to load settings")
        }
    }
}
