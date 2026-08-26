// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension VertexAPI {
  nonisolated struct CatProfileQuery: GraphQLQuery {
    static let operationName: String = "CatProfile"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query CatProfile($petId: UUID!) { pet(id: $petId) { __typename ...PetCoreFields } }"#,
        fragments: [PetCoreFields.self]
      ))

    public var petId: UUID

    public init(petId: UUID) {
      self.petId = petId
    }

    @_spi(Unsafe) public var __variables: Variables? { ["petId": petId] }

    nonisolated struct Data: VertexAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("pet", Pet?.self, arguments: ["id": .variable("petId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CatProfileQuery.Data.self
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
          .fragment(PetCoreFields.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CatProfileQuery.Data.Pet.self,
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