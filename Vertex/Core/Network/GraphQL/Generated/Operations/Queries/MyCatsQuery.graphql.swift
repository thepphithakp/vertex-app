// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension VertexAPI {
  nonisolated struct MyCatsQuery: GraphQLQuery {
    static let operationName: String = "MyCats"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyCats { viewer { __typename pets { __typename ...PetCoreFields } } }"#,
        fragments: [PetCoreFields.self]
      ))

    public init() {}

    nonisolated struct Data: VertexAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("viewer", Viewer.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyCatsQuery.Data.self
      ] }

      /// ข้อมูลของผู้ใช้ที่ถือ token นี้
      var viewer: Viewer { __data["viewer"] }

      /// Viewer
      ///
      /// Parent Type: `Viewer`
      nonisolated struct Viewer: VertexAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.Viewer }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("pets", [Pet].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyCatsQuery.Data.Viewer.self
        ] }

        /// สัตว์เลี้ยงทั้งหมดที่ผู้ใช้คนนี้เข้าถึงได้ (เป็นเจ้าของหรือเป็นผู้ดูแล)
        var pets: [Pet] { __data["pets"] }

        /// Viewer.Pet
        ///
        /// Parent Type: `Pet`
        nonisolated struct Pet: VertexAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.Pet }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(PetCoreFields.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyCatsQuery.Data.Viewer.Pet.self,
            PetCoreFields.self
          ] }

          var id: VertexAPI.UUID { __data["id"] }
          var name: String { __data["name"] }
          var species: String { __data["species"] }
          var breed: String { __data["breed"] }
          var colorCode: String { __data["colorCode"] }
          var birthDate: VertexAPI.DateTime { __data["birthDate"] }
          var gender: String { __data["gender"] }
          var currentWeight: Double? { __data["currentWeight"] }
          var microchipId: String? { __data["microchipId"] }
          var isSpayedNeutered: Bool { __data["isSpayedNeutered"] }
          var bloodType: String? { __data["bloodType"] }
          var allergies: String? { __data["allergies"] }
          var personality: String? { __data["personality"] }
          var hasAvatar: Bool { __data["hasAvatar"] }
          var owner: Owner { __data["owner"] }

          struct Fragments: FragmentContainer {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            var petCoreFields: PetCoreFields { _toFragment() }
          }

          typealias Owner = PetCoreFields.Owner
        }
      }
    }
  }

}