// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension VertexAPI {
  nonisolated struct WaterDayQuery: GraphQLQuery {
    static let operationName: String = "WaterDay"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query WaterDay($petId: UUID!, $from: DateTime!, $to: DateTime!) { pet(id: $petId) { __typename id waterLogs(from: $from, to: $to, first: 200) { __typename edges { __typename node { __typename id date amount } } } } }"#
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
        WaterDayQuery.Data.self
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
          .field("waterLogs", WaterLogs.self, arguments: [
            "from": .variable("from"),
            "to": .variable("to"),
            "first": 200
          ]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          WaterDayQuery.Data.Pet.self
        ] }

        var id: VertexAPI.UUID { __data["id"] }
        var waterLogs: WaterLogs { __data["waterLogs"] }

        /// Pet.WaterLogs
        ///
        /// Parent Type: `WaterLogConnection`
        nonisolated struct WaterLogs: VertexAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.WaterLogConnection }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("edges", [Edge].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            WaterDayQuery.Data.Pet.WaterLogs.self
          ] }

          var edges: [Edge] { __data["edges"] }

          /// Pet.WaterLogs.Edge
          ///
          /// Parent Type: `WaterLogEdge`
          nonisolated struct Edge: VertexAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.WaterLogEdge }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("node", Node.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              WaterDayQuery.Data.Pet.WaterLogs.Edge.self
            ] }

            var node: Node { __data["node"] }

            /// Pet.WaterLogs.Edge.Node
            ///
            /// Parent Type: `WaterLog`
            nonisolated struct Node: VertexAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.WaterLog }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", VertexAPI.UUID.self),
                .field("date", VertexAPI.DateTime.self),
                .field("amount", Int.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                WaterDayQuery.Data.Pet.WaterLogs.Edge.Node.self
              ] }

              var id: VertexAPI.UUID { __data["id"] }
              var date: VertexAPI.DateTime { __data["date"] }
              var amount: Int { __data["amount"] }
            }
          }
        }
      }
    }
  }

}