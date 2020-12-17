// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

final highlightRegionMapper = RegionTypeMapper();

/// A mapping from [HighlightRegionType] to a set of [SemanticTokenModifiers].
final highlightRegionTokenModifiers =
    <HighlightRegionType, Set<SemanticTokenModifiers>>{
  HighlightRegionType.COMMENT_DOCUMENTATION: {
    SemanticTokenModifiers.documentation
  },
  HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.DYNAMIC_PARAMETER_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.INSTANCE_FIELD_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.INSTANCE_GETTER_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.INSTANCE_METHOD_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.INSTANCE_SETTER_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.LOCAL_FUNCTION_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.LOCAL_VARIABLE_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.PARAMETER_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.STATIC_FIELD_DECLARATION: {
    SemanticTokenModifiers.declaration,
    SemanticTokenModifiers.static,
  },
  HighlightRegionType.STATIC_GETTER_DECLARATION: {
    SemanticTokenModifiers.declaration,
    SemanticTokenModifiers.static,
  },
  HighlightRegionType.STATIC_GETTER_REFERENCE: {SemanticTokenModifiers.static},
  HighlightRegionType.STATIC_METHOD_DECLARATION: {
    SemanticTokenModifiers.declaration,
    SemanticTokenModifiers.static,
  },
  HighlightRegionType.STATIC_METHOD_REFERENCE: {SemanticTokenModifiers.static},
  HighlightRegionType.STATIC_SETTER_DECLARATION: {
    SemanticTokenModifiers.declaration,
    SemanticTokenModifiers.static,
  },
  HighlightRegionType.STATIC_SETTER_REFERENCE: {SemanticTokenModifiers.static},
  HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION: {
    SemanticTokenModifiers.declaration,
    SemanticTokenModifiers.static,
  },
  HighlightRegionType.TOP_LEVEL_GETTER_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.TOP_LEVEL_SETTER_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.TOP_LEVEL_VARIABLE_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
};

/// A mapping from [HighlightRegionType] to [SemanticTokenTypes].
final highlightRegionTokenTypes = {
  HighlightRegionType.ANNOTATION: CustomSemanticTokenTypes.annotation,
  HighlightRegionType.BUILT_IN: SemanticTokenTypes.keyword,
  HighlightRegionType.CLASS: SemanticTokenTypes.class_,
  HighlightRegionType.COMMENT_BLOCK: SemanticTokenTypes.comment,
  HighlightRegionType.COMMENT_DOCUMENTATION: SemanticTokenTypes.comment,
  HighlightRegionType.COMMENT_END_OF_LINE: SemanticTokenTypes.comment,
  HighlightRegionType.CONSTRUCTOR: SemanticTokenTypes.class_,
  HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_DECLARATION:
      SemanticTokenTypes.variable,
  HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_REFERENCE:
      SemanticTokenTypes.variable,
  HighlightRegionType.DYNAMIC_PARAMETER_DECLARATION:
      SemanticTokenTypes.parameter,
  HighlightRegionType.DYNAMIC_PARAMETER_REFERENCE: SemanticTokenTypes.parameter,
  HighlightRegionType.ENUM: SemanticTokenTypes.enum_,
  HighlightRegionType.ENUM_CONSTANT: SemanticTokenTypes.enumMember,
  HighlightRegionType.FUNCTION_TYPE_ALIAS: SemanticTokenTypes.type,
  HighlightRegionType.INSTANCE_FIELD_DECLARATION: SemanticTokenTypes.variable,
  HighlightRegionType.INSTANCE_FIELD_REFERENCE: SemanticTokenTypes.variable,
  HighlightRegionType.INSTANCE_GETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.INSTANCE_GETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.INSTANCE_METHOD_DECLARATION: SemanticTokenTypes.method,
  HighlightRegionType.INSTANCE_METHOD_REFERENCE: SemanticTokenTypes.method,
  HighlightRegionType.INSTANCE_SETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.INSTANCE_SETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.KEYWORD: SemanticTokenTypes.keyword,
  HighlightRegionType.LIBRARY_NAME: SemanticTokenTypes.namespace,
  HighlightRegionType.LITERAL_BOOLEAN: CustomSemanticTokenTypes.boolean,
  HighlightRegionType.LITERAL_DOUBLE: SemanticTokenTypes.number,
  HighlightRegionType.LITERAL_INTEGER: SemanticTokenTypes.number,
  HighlightRegionType.LITERAL_STRING: SemanticTokenTypes.string,
  HighlightRegionType.LOCAL_FUNCTION_DECLARATION: SemanticTokenTypes.function,
  HighlightRegionType.LOCAL_FUNCTION_REFERENCE: SemanticTokenTypes.function,
  HighlightRegionType.LOCAL_VARIABLE_DECLARATION: SemanticTokenTypes.variable,
  HighlightRegionType.LOCAL_VARIABLE_REFERENCE: SemanticTokenTypes.variable,
  HighlightRegionType.PARAMETER_DECLARATION: SemanticTokenTypes.parameter,
  HighlightRegionType.PARAMETER_REFERENCE: SemanticTokenTypes.parameter,
  HighlightRegionType.STATIC_FIELD_DECLARATION: SemanticTokenTypes.variable,
  HighlightRegionType.STATIC_GETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.STATIC_GETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.STATIC_METHOD_DECLARATION: SemanticTokenTypes.method,
  HighlightRegionType.STATIC_METHOD_REFERENCE: SemanticTokenTypes.method,
  HighlightRegionType.STATIC_SETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.STATIC_SETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION:
      SemanticTokenTypes.function,
  HighlightRegionType.TOP_LEVEL_FUNCTION_REFERENCE: SemanticTokenTypes.function,
  HighlightRegionType.TOP_LEVEL_GETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_SETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_SETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_VARIABLE: SemanticTokenTypes.variable,
  HighlightRegionType.TOP_LEVEL_VARIABLE_DECLARATION:
      SemanticTokenTypes.variable,
  HighlightRegionType.TYPE_NAME_DYNAMIC: SemanticTokenTypes.type,
  HighlightRegionType.TYPE_PARAMETER: SemanticTokenTypes.typeParameter,
  HighlightRegionType.UNRESOLVED_INSTANCE_MEMBER_REFERENCE:
      SemanticTokenTypes.variable,
};

/// A helper for converting from Server highlight regions to LSP semantic tokens.
class RegionTypeMapper {
  /// A map to get the [SemanticTokenTypes] index directly from a [HighlightRegionType].
  final Map<HighlightRegionType, int> _tokenTypeIndexForHighlightRegion = {};

  /// A map to get the [SemanticTokenModifiers] bitmask directly from a [HighlightRegionType].
  final Map<HighlightRegionType, int> _tokenModifierBitmaskForHighlightRegion =
      {};

  RegionTypeMapper() {
    // Build mappings that go directly from [HighlightRegionType] to index/bitmask
    // for faster lookups.
    for (final regionType in highlightRegionTokenTypes.keys) {
      _tokenTypeIndexForHighlightRegion[regionType] = semanticTokenLegend
          .indexForType(highlightRegionTokenTypes[regionType]);
    }

    for (final regionType in highlightRegionTokenTypes.keys) {
      _tokenModifierBitmaskForHighlightRegion[regionType] = semanticTokenLegend
          .bitmaskForModifiers(highlightRegionTokenModifiers[regionType]);
    }
  }

  /// Gets the [SemanticTokenModifiers] bitmask for a [HighlightRegionType]. Returns
  /// null if the region type has not been mapped.
  int bitmaskForModifier(HighlightRegionType type) =>
      _tokenModifierBitmaskForHighlightRegion[type];

  /// Gets the [SemanticTokenTypes] index for a [HighlightRegionType]. Returns
  /// null if the region type has not been mapped.
  int indexForToken(HighlightRegionType type) =>
      _tokenTypeIndexForHighlightRegion[type];
}
