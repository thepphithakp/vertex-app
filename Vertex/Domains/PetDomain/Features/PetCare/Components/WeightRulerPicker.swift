import SwiftUI

struct WeightRulerPicker: View {
    @Binding var weight: Double
    @State private var scrolledID: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Text Display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", weight))
                    .font(.system(size: 60, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                Text("kg")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Pointer (Triangle)
            Image(systemName: "arrowtriangledown.fill")
                .foregroundColor(.blue)
                .font(.title2)
                .offset(y: 10)
                .zIndex(1)
            
            // Ruler
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // 0.0 kg ถึง 20.0 kg (200 ช่อง)
                        ForEach(0...200, id: \.self) { i in
                            VStack(spacing: 4) {
                                Rectangle()
                                    // เส้นหลัก (จำนวนเต็ม) สีเข้มและยาวกว่า, เส้นย่อย (ทศนิยม) สีอ่อนและสั้น
                                    .fill(i % 10 == 0 ? Color.primary : Color.gray.opacity(0.5))
                                    .frame(width: 2, height: i % 10 == 0 ? 30 : 15)
                                
                                if i % 10 == 0 {
                                    Text("\(i / 10)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(" ")
                                        .font(.caption)
                                }
                            }
                            .frame(width: 14) // ความกว้างของแต่ละขีด
                            .id(i)
                        }
                    }
                    .scrollTargetLayout() // เพื่อให้มัน Snap ตรงกับ View พอดี
                    .padding(.horizontal, geo.size.width / 2 - 7) // ดันให้ขีดแรกและขีดสุดท้ายมาอยู่ตรงกลางจอได้
                }
                .scrollPosition(id: $scrolledID, anchor: .center)
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: scrolledID) { _, newValue in
                    if let newValue {
                        weight = Double(newValue) / 10.0
                    }
                }
                .onAppear {
                    // กำหนดตำแหน่งเริ่มต้นให้ตรงกับ weight
                    if scrolledID == nil {
                        scrolledID = Int(round(weight * 10.0))
                    }
                }
            }
            .frame(height: 80)
        }
    }
}
