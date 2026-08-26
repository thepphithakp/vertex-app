// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension VertexAPI {
  nonisolated struct LitterDayQuery: GraphQLQuery {
    static let operationName: String = "LitterDay"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query LitterDay($petId: UUID!, $from: DateTime!, $to: DateTime!) { pet(id: $petId) { __typename id litterLogs(from: $from, to: $to, first: 200) { __typename edges { __typename node { __typename id date type amount } } } } }"#
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
        LitterDayQuery.Data.self
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
          .field("litterLogs", LitterLogs.self, arguments: [
            "from": .variable("from"),
            "to": .variable("to"),
            "first": 200
          ]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LitterDayQuery.Data.Pet.self
        ] }

        var id: VertexAPI.UUID { __data["id"] }
        var litterLogs: LitterLogs { __data["litterLogs"] }

        /// Pet.LitterLogs
        ///
        /// Parent Type: `LitterLogConnection`
        nonisolated struct LitterLogs: VertexAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.LitterLogConnection }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("edges", [Edge].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LitterDayQuery.Data.Pet.LitterLogs.self
          ] }

          var edges: [Edge] { __data["edges"] }

          /// Pet.LitterLogs.Edge
          ///
          /// Parent Type: `LitterLogEdge`
          nonisolated struct Edge: VertexAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.LitterLogEdge }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("node", Node.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              LitterDayQuery.Data.Pet.LitterLogs.Edge.self
            ] }

            var node: Node { __data["node"] }

            /// Pet.LitterLogs.Edge.Node
            ///
            /// Parent Type: `LitterLog`
            nonisolated struct Node: VertexAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.LitterLog }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", VertexAPI.UUID.self),
                .field("date", VertexAPI.DateTime.self),
                .field("type", String.self),
                .field("amount", Int.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                LitterDayQuery.Data.Pet.LitterLogs.Edge.Node.self
              ] }

              var id: VertexAPI.UUID { __data["id"] }
              var date: VertexAPI.DateTime { __data["date"] }
              var type: String { __data["type"] }
              var amount: Int { __data["amount"] }
            }
          }
        }
      }
    }
  }

}