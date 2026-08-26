// @generated
// This file was automatically generated and can be edited to
// provide custom configuration for a generated GraphQL schema.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

import ApolloAPI

nonisolated enum SchemaConfiguration: ApolloAPI.SchemaConfiguration {
  /// ทุก type ที่มี `id` ให้ใช้ `id` เป็น cache key
  ///
  /// ถ้าไม่ตั้ง Apollo จะเก็บ cache ตาม path ของ query แปลว่าแมวตัวเดียวกัน
  /// ที่มาจากหน้า MyCats กับหน้า CatProfile จะกลายเป็นคนละก้อนในแคช
  /// แก้ชื่อแมวแล้วอีกหน้าไม่อัปเดตตาม
  ///
  /// type ที่ไม่มี `id` (พวก bucket สรุปรายวัน) คืน nil ให้ Apollo ฝังไว้กับตัวแม่ตามเดิม
  static func cacheKeyInfo(for type: ApolloAPI.Object, object: ApolloAPI.ObjectData) -> CacheKeyInfo? {
    guard let id = object["id"] as? String else { return nil }
    return CacheKeyInfo(id: id)
  }
}
