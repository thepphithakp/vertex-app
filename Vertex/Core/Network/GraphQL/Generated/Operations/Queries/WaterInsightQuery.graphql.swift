// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension VertexAPI {
  nonisolated struct WaterInsightQuery: GraphQLQuery {
    static let operationName: String = "WaterInsight"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query WaterInsight($petId: UUID!, $from: DateTime!, $to: DateTime!) { pet(id: $petId) { __typename id waterInsight(from: $from, to: $to) { __typename text model generatedAt cached } } }"#
      ))

    public var petId: UUID
    public var from: DateTime
    public var to: DateTime

    public init(
      petId: UUID,
      from: DateTime,
      to: DateTime
    ) {
      self.petId = petId
      self.from = from
      self.to = to
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "petId": petId,
      "from": from,
      "to": to
    ] }

    nonisolated struct Data: VertexAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("pet", Pet?.self, arguments: ["id": .variable("petId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        WaterInsightQuery.Data.self
      ] }

      /// สัตว์เลี้ยงตัวเดียว — คืน null ถ้าไม่มีหรือไม่มีสิทธิ์ดู
      var pet: Pet? { __data["pet"] }

      /// Pet
      ///
      /// Parent Type: `Pet`
      nonisolated struct Pet: VertexAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.Pet }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", VertexAPI.UUID.self),
          .field("waterInsight", WaterInsight?.self, arguments: [
            "from": .variable("from"),
            "to": .variable("to")
          ]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          WaterInsightQuery.Data.Pet.self
        ] }

        var id: VertexAPI.UUID { __data["id"] }
        /// คำวิเคราะห์การกินน้ำที่เขียนด้วย LLM จากตัวเลขของช่วงเวลาที่ส่งมา
        ///
        /// **คืน null ได้เสมอ** — ยังไม่ได้ตั้ง API key, เรียก LLM ไม่สำเร็จ หรือเกิน
        /// quota ของ free tier ล้วนได้ null ทั้งหมด client ต้องมีข้อความสำรองของตัวเอง
        /// ไม่ใช่ปล่อยการ์ดว่าง (VT-108)
        ///
        /// ราคาแพงกว่าฟิลด์อื่นมากเพราะออกไปนอกคลัสเตอร์ — ดู complexity.go
        var waterInsight: WaterInsight? { __data["waterInsight"] }

        /// Pet.WaterInsight
        ///
        /// Parent Type: `WaterInsight`
        nonisolated struct WaterInsight: VertexAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.WaterInsight }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("text", String.self),
            .field("model", String.self),
            .field("generatedAt", VertexAPI.DateTime.self),
            .field("cached", Bool.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            WaterInsightQuery.Data.Pet.WaterInsight.self
          ] }

          var text: String { __data["text"] }
          /// ชื่อโมเดลที่ generate ข้อความนี้ เช่น gemini-2.5-flash
          var model: String { __data["model"] }
          var generatedAt: VertexAPI.DateTime { __data["generatedAt"] }
          /// true = ได้จาก cache ของ BFF ไม่ได้ยิงไปที่ LLM ใหม่
          var cached: Bool { __data["cached"] }
        }
      }
    }
  }

}