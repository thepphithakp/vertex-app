// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension VertexAPI {
  nonisolated struct PetCoreFields: VertexAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment PetCoreFields on Pet { __typename id name species breed colorCode birthDate gender currentWeight microchipId isSpayedNeutered bloodType allergies personality hasAvatar owner { __typename id fullName } }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.Pet }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", VertexAPI.UUID.self),
      .field("name", String.self),
      .field("species", String.self),
      .field("breed", String.self),
      .field("colorCode", String.self),
      .field("birthDate", VertexAPI.DateTime.self),
      .field("gender", String.self),
      .field("currentWeight", Double?.self),
      .field("microchipId", String?.self),
      .field("isSpayedNeutered", Bool.self),
      .field("bloodType", String?.self),
      .field("allergies", String?.self),
      .field("personality", String?.self),
      .field("hasAvatar", Bool.self),
      .field("owner", Owner.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
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

    /// Owner
    ///
    /// Parent Type: `User`
    nonisolated struct Owner: VertexAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { VertexAPI.Objects.User }
      static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", VertexAPI.UUID.self),
        .field("fullName", String.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PetCoreFields.Owner.self
      ] }

      var id: VertexAPI.UUID { __data["id"] }
      var fullName: String { __data["fullName"] }
    }
  }

}