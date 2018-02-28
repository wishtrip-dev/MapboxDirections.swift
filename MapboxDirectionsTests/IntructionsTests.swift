import XCTest
import OHHTTPStubs
@testable import MapboxDirections

class SpokenInstructionsTests: XCTestCase {
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testInstructions() {
        let expectation = self.expectation(description: "calculating directions should return results")
        
        let queryParams: [String: String?] = [
            "alternatives": "false",
            "geometries": "polyline",
            "overview": "full",
            "steps": "true",
            "continue_straight": "true",
            "access_token": BogusToken,
            "voice_instructions": "true",
            "voice_units": "imperial",
            "banner_instructions": "true"
        ]
        
        stub(condition: isHost("api.mapbox.com")
            && containsQueryParams(queryParams)) { _ in
                let path = Bundle(for: type(of: self)).path(forResource: "instructions", ofType: "json")
                return OHHTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let options = RouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.780602, longitude: -122.431373),
            CLLocationCoordinate2D(latitude: 37.758859, longitude: -122.404058),
            ], profileIdentifier: .automobileAvoidingTraffic)
        options.shapeFormat = .polyline
        options.includesSteps = true
        options.includesAlternativeRoutes = false
        options.routeShapeResolution = .full
        options.includesSpokenInstructions = true
        options.distanceMeasurementSystem = .imperial
        options.includesVisualInstructions = true
        var route: Route?
        let task = Directions(accessToken: BogusToken).calculate(options) { (waypoints, routes, error) in
            XCTAssertNil(error, "Error: \(error!.localizedDescription)")
            
            XCTAssertNotNil(routes)
            XCTAssertEqual(routes!.count, 1)
            route = routes!.first!
            
            expectation.fulfill()
        }
        XCTAssertNotNil(task)
        
        waitForExpectations(timeout: 2) { (error) in
            XCTAssertNil(error, "Error: \(error!.localizedDescription)")
            XCTAssertEqual(task.state, .completed)
        }
        
        XCTAssertNotNil(route)
        XCTAssertEqual(route!.routeIdentifier, "cjdnkkc8u00047bobygk1p7bi")
        
        let leg = route!.legs.first!
        let step = leg.steps[1]
        
        XCTAssertEqual(step.instructionsSpokenAlongStep!.count, 3)
        
        let spokenInstructions = step.instructionsSpokenAlongStep!
        
        XCTAssertEqual(spokenInstructions[0].distanceAlongStep, 944.9)
        XCTAssertEqual(spokenInstructions[1].distanceAlongStep, 258.0)
        XCTAssertEqual(spokenInstructions[2].distanceAlongStep, 55.3)
        
        XCTAssertEqual(spokenInstructions[0].ssmlText, "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Continue on Fillmore Street for a half mile</prosody></amazon:effect></speak>")
        XCTAssertEqual(spokenInstructions[1].ssmlText, "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In 900 feet, turn left onto <phoneme ph=\"ˈheɪt ˌstɹiːt\">Haight Street</phoneme></prosody></amazon:effect></speak>")
        XCTAssertEqual(spokenInstructions[2].ssmlText, "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn left onto <phoneme ph=\"ˈheɪt ˌstɹiːt\">Haight Street</phoneme></prosody></amazon:effect></speak>")
        
        XCTAssertEqual(spokenInstructions[0].text, "Continue on Fillmore Street for a half mile")
        XCTAssertEqual(spokenInstructions[1].text, "In 900 feet, turn left onto Haight Street")
        XCTAssertEqual(spokenInstructions[2].text, "Turn left onto Haight Street")
        
        let visualInstructions = step.instructionsDisplayedAlongStep
        
        XCTAssertNotNil(visualInstructions)
        XCTAssertEqual(visualInstructions?.first?.primaryText, "Haight Street")
        XCTAssertEqual(visualInstructions?.first?.primaryTextComponents.first!.text, "Haight Street")
        XCTAssertEqual(visualInstructions?.first?.distanceAlongStep, 944.89999999999998)
        XCTAssertEqual(visualInstructions?.first?.primaryTextComponents.first?.maneuverType, .turn)
        XCTAssertEqual(visualInstructions?.first?.primaryTextComponents.first?.maneuverDirection, .left)
        XCTAssertEqual(visualInstructions?.first?.drivingSide, .right)
        XCTAssertNil(visualInstructions?.first?.secondaryText)
    }
}
