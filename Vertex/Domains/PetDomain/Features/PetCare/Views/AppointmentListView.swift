import SwiftUI
import SwiftData

struct AppointmentListView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = AppointmentListViewModel()
    @State private var isShowingAdd = false
    @State private var appointmentToEdit: PetAppointment?
    
    // Animation state
    @State private var appear = false
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if viewModel.appointments.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(.blue.opacity(0.8))
                        .symbolEffect(.bounce, value: appear)
                    Text("ไม่มีนัดหมาย")
                        .font(.title2).bold()
                    Text("ยังไม่มีนัดหมายตรวจสุขภาพหรือวัคซีน\nเพิ่มการนัดหมายเพื่อให้ไม่พลาดทุกกิจกรรมสำคัญ")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        
                    Button(action: { isShowingAdd = true }) {
                        Text("สร้างนัดหมาย")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.top)
                }
                .opacity(appear ? 1 : 0)
                .scaleEffect(appear ? 1 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appear)
                .onAppear { appear = true }
            } else {
                List {
                    ForEach(viewModel.appointments) { appt in
                        Button(action: {
                            appointmentToEdit = appt
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(appt.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(appt.appointmentType)
                                        .font(.caption)
                                        .bold()
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.blue.opacity(0.15)))
                                        .foregroundColor(.blue)
                                }
                                
                                HStack {
                                    Label(appt.pet?.name ?? "ไม่ระบุตัว", systemImage: "pawprint.fill")
                                        .foregroundColor(.orange)
                                        .font(.subheadline)
                                        .bold()
                                    Spacer()
                                    // โชว์ Animation กระดิ่งสั่นๆ ถ้ามีการตั้งเตือน
                                    Image(systemName: appt.isReminderSet ? "bell.badge.fill" : "bell.slash")
                                        .foregroundColor(appt.isReminderSet ? .red : .gray)
                                        .symbolEffect(.pulse, options: .repeating, isActive: appt.isReminderSet)
                                }
                                
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(.secondary)
                                    Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                        )
                        .padding(.vertical, 6)
                        // WOW: Scroll Transition (iOS 17/18+)
                        .scrollTransition(.animated.threshold(.visible(0.1))) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.5)
                                .scaleEffect(phase.isIdentity ? 1 : 0.90)
                                .offset(y: phase.isIdentity ? 0 : 30)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let appt = viewModel.appointments[index]
                            Task {
                                await viewModel.deleteAppointment(appt, repository: LocalAppointmentRepository(context: context))
                            }
                        }
                    }
                }
                .tabBarAware()
                .listStyle(.plain)
                .animation(.bouncy, value: viewModel.appointments)
            }
        }
        .navigationTitle("Appointments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isShowingAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolEffect(.bounce, value: viewModel.appointments.count)
                }
            }
        }
        .sheet(isPresented: $isShowingAdd) {
            AddAppointmentView()
                .onDisappear {
                    Task { await viewModel.loadAppointments(repository: LocalAppointmentRepository(context: context)) }
                }
        }
        .sheet(item: $appointmentToEdit) { appt in
            AddAppointmentView(appointmentToEdit: appt)
                .onDisappear {
                    Task { await viewModel.loadAppointments(repository: LocalAppointmentRepository(context: context)) }
                }
        }
        .task {
            await viewModel.loadAppointments(repository: LocalAppointmentRepository(context: context))
        }
    }
}
