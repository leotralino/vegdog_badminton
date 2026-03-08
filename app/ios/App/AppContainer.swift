import Foundation

struct AppContainer {
    let apiClient: APIClient
    let service: BadmintonServiceProtocol

    init(baseURL: URL = AppEnvironment.baseURL) {
        let client = APIClient(baseURL: baseURL)
        self.apiClient = client
        self.service = BadmintonService(client: client)
    }
}
