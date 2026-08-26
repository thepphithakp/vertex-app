// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension VertexAPI {
  nonisolated struct PetAnalyticsQuery: GraphQLQuery {
    static let operationName: String = "PetAnalytics"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query PetAnalytics($petId: UUID!, $from: DateTime!, $to: DateTime!) { pet(id: $petId) { __typename id litterSummary(from: $from, to: $to) { __typename totalPoop totalPee avgPoopPerDay avgPeePerDay daily { __typename date poop pee } } waterSummary(from: $from, to: $to) { __typename totalMl avgMlPerDay dailyTargetMl daily { __typename date ml } } } }"#
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
        PetAnalyticsQuery.Data.self
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
          .field("litterSummary", LitterSummary.self, arguments: [
            "from": .variable("from"),
            "to": .variable("to")
          ]),
          .field("waterSummary", WaterSummary.self, arguments: [
            "from": .variable("from"),
            "to": .variable("to")
          ]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PetAnalyticsQuery.Data.Pet.self
        ] }

        var id: VertexAPI.UUID { __data["id"] }
        /// สรุปรายวันสำหรับหน้า Analytics
        ///
        /// ตอนนี้ client ดึง log ทั้งหมดตั้งแต่ต้นแล้ว group เองในเครื่อง
        /// ซึ่งทั้งเปลืองและทำงานไม่ถูกต้อง (ดูหมายเหตุใน VT-98)
        /// ให้ฝั่ง server ทำ GROUP BY ให้จบ
        var litterSummary: LitterSummary { __data["litterSummary"] }
        var waterSummary: WaterSummary { __data["waterSummary"] }

        /// Pet.LitterSummary
        ///
        /// Parent Type: `LitterSummary`
        nonisolated struct LitterSummary: VertexAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.LitterSummary }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("totalPoop", Int.self),
            .field("totalPee", Int.self),
            .field("avgPoopPerDay", Double.self),
            .field("avgPeePerDay", Double.self),
            .field("daily", [Daily].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PetAnalyticsQuery.Data.Pet.LitterSummary.self
          ] }

          var totalPoop: Int { __data["totalPoop"] }
          var totalPee: Int { __data["totalPee"] }
          var avgPoopPerDay: Double { __data["avgPoopPerDay"] }
          var avgPeePerDay: Double { __data["avgPeePerDay"] }
          /// ครบทุกวันในช่วง วันที่ไม่มีข้อมูลจะเป็น 0 เพื่อให้กราฟไม่ขาดช่วง
          var daily: [Daily] { __data["daily"] }

          /// Pet.LitterSummary.Daily
          ///
          /// Parent Type: `LitterDailyBucket`
          nonisolated struct Daily: VertexAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.LitterDailyBucket }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("date", VertexAPI.DateTime.self),
              .field("poop", Int.self),
              .field("pee", Int.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              PetAnalyticsQuery.Data.Pet.LitterSummary.Daily.self
            ] }

            var date: VertexAPI.DateTime { __data["date"] }
            var poop: Int { __data["poop"] }
            var pee: Int { __data["pee"] }
          }
        }

        /// Pet.WaterSummary
        ///
        /// Parent Type: `WaterSummary`
        nonisolated struct WaterSummary: VertexAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.WaterSummary }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("totalMl", Int.self),
            .field("avgMlPerDay", Double.self),
            .field("dailyTargetMl", Int?.self),
            .field("daily", [Daily].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PetAnalyticsQuery.Data.Pet.WaterSummary.self
          ] }

          var totalMl: Int { __data["totalMl"] }
          var avgMlPerDay: Double { __data["avgMlPerDay"] }
          /// เป้าหมายต่อวันคำนวณจากน้ำหนัก (50 ml ต่อกิโลกรัม)
          ///
          /// null เมื่อสัตว์เลี้ยงยังไม่มีน้ำหนักบันทึกไว้ — client ปัจจุบันเดาเป็น 4 กก.
          /// แล้วแสดงเป้าหมายที่ไม่จริง ซึ่งแย่กว่าการบอกว่าไม่รู้
          var dailyTargetMl: Int? { __data["dailyTargetMl"] }
          var daily: [Daily] { __data["daily"] }

          /// Pet.WaterSummary.Daily
          ///
          /// Parent Type: `WaterDailyBucket`
          nonisolated struct Daily: VertexAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.WaterDailyBucket }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("date", VertexAPI.DateTime.self),
              .field("ml", Int.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              PetAnalyticsQuery.Data.Pet.WaterSummary.Daily.self
            ] }

            var date: VertexAPI.DateTime { __data["date"] }
            var ml: Int { __data["ml"] }
          }
        }
      }
    }
  }

}