import Apollo
import ApolloAPI
import Foundation
import UIKit

/// ทางเดียวที่แอปคุยกับ BFF ผ่าน GraphQL
///
/// ตั้งใจให้หน้าตาการใช้งานเหมือน `NetworkManager.request` คือ `try await` แล้วได้ข้อมูล
/// หรือโยน `APIError` ที่เด้ง dialog ให้เอง เพื่อให้ย้ายหน้าจอทีละหน้าได้
/// โดยหน้าที่ยังไม่ย้ายทำงานเหมือนเดิมทุกอย่าง
enum VertexGraphQL {

    static let apollo: ApolloClient = {
        let store = ApolloStore(cache: InMemoryNormalizedCache())

        // ใช้ delegate ตัวเดียวกับ REST เพราะเซิร์ฟเวอร์ dev ใช้ cert ที่ระบบไม่เชื่อถือ
        // ถ้าไม่ใส่ ทุก query จะล้มที่ชั้น TLS ก่อนถึง BFF ด้วยซ้ำ
        let session = URLSession(
            configuration: .default,
            delegate: InsecureSessionDelegate(),
            delegateQueue: nil
        )

        let transport = RequestChainNetworkTransport(
            urlSession: session,
            interceptorProvider: VertexInterceptorProvider(),
            store: store,
            endpointURL: AppConfig.shared.graphqlURL,
            additionalHeaders: [
                "X-Source-System": "ios-app",
                "X-Device-Id": UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device",
            ]
        )

        return ApolloClient(networkTransport: transport, store: store)
    }()

    /// ยิง query แล้วคืนข้อมูล — error ถูกแปลงเป็น `APIError` และเด้ง dialog ให้แล้ว
    ///
    /// ค่าเริ่มต้นเป็น `.networkOnly` เพราะพฤติกรรมจะได้เหมือนตอนเรียก REST เป๊ะๆ
    /// หน้าไหนอยากได้ cache ค่อยเปิดเป็นรายหน้าเมื่อรู้ว่ามันถูกต้องกับหน้านั้นจริง
    static func fetch<Query: GraphQLQuery>(
        _ query: Query,
        cachePolicy: CachePolicy.Query.SingleResponse = .networkOnly
    ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
        do {
            let response = try await apollo.fetch(query: query, cachePolicy: cachePolicy)
            return try unwrap(response.data, errors: response.errors)
        } catch let error as APIError {
            throw error
        } catch {
            throw report(APIError(message: error.localizedDescription, requestId: nil))
        }
    }

    /// ยิง mutation — ไม่แตะ cache เพราะข้อมูลสรุป (เช่น totalMl) คำนวณที่ server
    /// การเขียน cache เองจะทำให้ตัวเลขบนจอไม่ตรงกับของจริงจนกว่าจะ refresh
    @discardableResult
    static func perform<Mutation: GraphQLMutation>(
        _ mutation: Mutation
    ) async throws -> Mutation.Data where Mutation.ResponseFormat == SingleResponseFormat {
        do {
            let response = try await apollo.perform(
                mutation: mutation,
                requestConfiguration: RequestConfiguration(writeResultsToCache: false)
            )
            return try unwrap(response.data, errors: response.errors)
        } catch let error as APIError {
            throw error
        } catch {
            throw report(APIError(message: error.localizedDescription, requestId: nil))
        }
    }

    // MARK: - แปลง error

    private static func unwrap<Data>(_ data: Data?, errors: [GraphQLError]?) throws -> Data {
        // GraphQL ตอบ 200 แม้ query จะพัง — error อยู่ในตัว body ไม่ใช่ status code
        // ถ้าไม่เช็คตรงนี้ หน้าจอจะขึ้นค่าว่างเงียบๆ แทนที่จะบอกว่าพัง
        if let first = errors?.first {
            throw report(apiError(from: first))
        }
        guard let data else {
            throw report(APIError(message: "เซิร์ฟเวอร์ไม่ได้ส่งข้อมูลกลับมา", requestId: nil))
        }
        return data
    }

    private static func apiError(from error: GraphQLError) -> APIError {
        APIError(
            message: error.message ?? "เกิดข้อผิดพลาดที่ไม่รู้จัก",
            // BFF ใส่ requestId มาให้ใน extensions เพื่อให้ตามใน Kibana ต่อได้
            requestId: error.extensions?["requestId"] as? String
        )
    }

    @discardableResult
    private static func report(_ error: APIError) -> APIError {
        Task { @MainActor in
            GlobalErrorManager.shared.handleError(error)
        }
        return error
    }
}

// MARK: - Interceptor

/// ใส่ของที่ทุก request ต้องมี: JWT ของผู้ใช้ และ request id สำหรับตามใน log
///
/// header ที่ค่าเดิมตลอด (source system, device id) ไปอยู่ที่ transport แทน
/// เพราะไม่ต้องคิดใหม่ทุกครั้ง
private struct VertexAuthInterceptor: GraphQLInterceptor {
    func intercept<Request: GraphQLRequest>(
        request: Request,
        next: NextInterceptorFunction<Request>
    ) async throws -> InterceptorResultStream<Request> {
        var request = request

        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
        }
        request.addHeader(name: "X-Request-Id", value: UUID().uuidString)

        return await next(request)
    }
}

private struct VertexInterceptorProvider: InterceptorProvider {
    func graphQLInterceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any GraphQLInterceptor] {
        [MaxRetryInterceptor(), VertexAuthInterceptor()]
    }
}
