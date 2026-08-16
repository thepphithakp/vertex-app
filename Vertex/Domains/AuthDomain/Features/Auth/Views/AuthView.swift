import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isLoginMode = true
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative Circles
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 150, y: 250)
            
            VStack {
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    Text("Vertex")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    
                    Text("Your All-in-One Super App")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 40)
                
                // Auth Card
                VStack(spacing: 20) {
                    Picker("Mode", selection: $isLoginMode) {
                        Text("Sign In").tag(true)
                        Text("Sign Up").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 10)
                    
                    if !isLoginMode {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            TextField("Full Name", text: $viewModel.fullName)
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        TextField("Email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $viewModel.password)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        Task {
                            if isLoginMode {
                                await viewModel.login()
                            } else {
                                await viewModel.signup()
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isLoginMode ? "Sign In" : "Sign Up")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .disabled(viewModel.isLoading)
                    
                    // Divider
                    HStack {
                        VStack { Divider().background(Color.white) }
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.white)
                        VStack { Divider().background(Color.white) }
                    }
                    .padding(.vertical, 10)
                    
                    // Sign in with Google
                    Button(action: {
                        viewModel.handleGoogleLogin()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill") // Placeholder for Google icon
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
}

#Preview {
    AuthView()
}
