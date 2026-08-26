// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

nonisolated protocol VertexAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == VertexAPI.SchemaMetadata {}

nonisolated protocol VertexAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == VertexAPI.SchemaMetadata {}

nonisolated protocol VertexAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == VertexAPI.SchemaMetadata {}

nonisolated protocol VertexAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == VertexAPI.SchemaMetadata {}

extension VertexAPI {
  typealias SelectionSet = VertexAPI_SelectionSet

  typealias InlineFragment = VertexAPI_InlineFragment

  typealias MutableSelectionSet = VertexAPI_MutableSelectionSet

  typealias MutableInlineFragment = VertexAPI_MutableInlineFragment

  nonisolated enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
      "LitterDailyBucket": VertexAPI.Objects.LitterDailyBucket,
      "LitterLog": VertexAPI.Objects.LitterLog,
      "LitterLogConnection": VertexAPI.Objects.LitterLogConnection,
      "LitterLogEdge": VertexAPI.Objects.LitterLogEdge,
      "LitterSummary": VertexAPI.Objects.LitterSummary,
      "Pet": VertexAPI.Objects.Pet,
      "Query": VertexAPI.Objects.Query,
      "User": VertexAPI.Objects.User,
      "Viewer": VertexAPI.Objects.Viewer,
      "WaterDailyBucket": VertexAPI.Objects.WaterDailyBucket,
      "WaterInsight": VertexAPI.Objects.WaterInsight,
      "WaterLog": VertexAPI.Objects.WaterLog,
      "WaterLogConnection": VertexAPI.Objects.WaterLogConnection,
      "WaterLogEdge": VertexAPI.Objects.WaterLogEdge,
      "WaterSummary": VertexAPI.Objects.WaterSummary
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}