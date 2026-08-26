// @generated
// This file was automatically generated and can be edited to
// implement advanced custom scalar functionality.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

import Foundation
@_spi(Internal) @_spi(Execution) import ApolloAPI

extension VertexAPI {
  typealias DateTime = String

}
// เก็บเป็น String ตามที่ codegen ทำมา ไม่แปลงเป็น Foundation.Date ที่ชั้นนี้
//
// เหตุผลคือ `CustomScalarType` ต้องรับ JSON ได้ทุกรูปแบบที่ server ส่งมาและต้องแปลง
// กลับเป็น variable ได้ด้วย ถ้า parse พลาดจะกลายเป็น error ทั้ง query
// ทั้งที่วันเสียแค่ field เดียว — แปลงตอนเอาไปใช้ที่ mapping ปลอดภัยกว่า
//
// ฟอร์แมตต้องตรงกับที่ NetworkManager ใช้กับ REST คือ ISO8601 ทั้งแบบมีและไม่มีเศษวินาที
// เพราะทั้งสองทางคุยกับ service ชุดเดียวกัน
extension VertexAPI {

    /// แปลง DateTime จาก GraphQL เป็น Date — คืน nil เมื่อรูปแบบไม่ตรง
    static func date(from value: DateTime) -> Foundation.Date? {
        let candidates: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime],
        ]
        for options in candidates {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = options
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    /// แปลง Date เป็น DateTime สำหรับส่งเป็น variable
    ///
    /// ต้องมี offset ของเครื่อง ห้ามส่งเป็น `Z` เด็ดขาด
    ///
    /// BFF แบ่งถังรายวันตาม timezone ที่ติดมากับค่า `from` แล้วปัดลงไปต้นวันของ
    /// timezone นั้น ส่งเวลาเดียวกันเป๊ะๆ แต่เขียนเป็น UTC จะได้คนละผลลัพธ์:
    /// `2026-08-20T00:00:00+07:00` ได้ 7 ถัง ส่วน `2026-08-19T17:00:00Z`
    /// ซึ่งเป็นเวลาเดียวกันได้ 8 ถัง ทำให้ค่าเฉลี่ยต่อวันหารด้วยตัวหารผิด
    /// (อึ 6 ก้อนกลายเป็น 0.75/วัน แทนที่จะเป็น 0.86/วัน)
    ///
    /// `.withColonSeparatorInTimeZone` จำเป็น เพราะฝั่ง Go parse RFC3339
    /// ที่ต้องเป็น `+07:00` ไม่ใช่ `+0700`
    static func dateTime(from date: Foundation.Date) -> DateTime {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds,
            .withColonSeparatorInTimeZone,
        ]
        return formatter.string(from: date)
    }
}
