import Foundation

struct AppContainer {
    let apiClient: APIClient
    let service: BadmintonServiceProtocol

    init(baseURL: URL = AppEnvironment.baseURL, useMockService: Bool = AppEnvironment.useMockService) {
        let client = APIClient(baseURL: baseURL)
        self.apiClient = client
        if useMockService {
            self.service = MockBadmintonService()
        } else {
            self.service = BadmintonService(client: client)
        }
    }
}
