# Vertex iOS App Rules

## SwiftUI & Combine Best Practices
- **ObservableObject / @Published**: Whenever you define a class that conforms to `ObservableObject` and uses `@Published` properties, you **MUST** ensure that `import Combine` is present at the top of the file. Do not rely solely on `import Foundation`.
- **Concurrency**: Use Swift 6 strict concurrency guidelines. Annotate ViewModels and UI-related services with `@MainActor`.
- **Design Guidelines**: Always use modern Glassmorphism, gradients, and subtle animations (`.symbolEffect`) where appropriate to keep the UI looking "cool" and premium.

## Backend (Go Fiber)
- **JSON Logs**: Always format logs in JSON for ELK compatibility.
- **Request ID**: Ensure `X-Request-Id` is passed down and returned in error responses for traceability.
- **OAuth/Auth**: Use the RSA (RS256) standard for JWTs. Ensure the `OAuthIdentity` table is used for any new OAuth providers (Google, Facebook, etc.).

## Constants / Environment
- **Google Client ID**: `565361629384-nm0k3gs5affdnva1gjlfb2b9musj0614.apps.googleusercontent.com`
- **Google Reversed Client ID**: `com.googleusercontent.apps.565361629384-nm0k3gs5affdnva1gjlfb2b9musj0614`

## Database & Back-office Design
- **Back Office Readiness**: All database table designs MUST support back-office administration by default.
- **Audit Fields**: Every table MUST include audit fields (`CreatedAt`, `UpdatedAt`, `DeletedAt` for soft-deletion, `CreatedBy`, `UpdatedBy`, and `IsActive`).
- **Dynamic Authorization**: Use Role-Based Access Control (RBAC) with Master Tables (e.g. `Permissions`, `Roles`) and Many-to-Many relationships instead of hardcoding permissions as boolean columns.
- **Normalization**: Ensure proper database normalization (composite unique indexes where appropriate) to prevent data anomalies.
