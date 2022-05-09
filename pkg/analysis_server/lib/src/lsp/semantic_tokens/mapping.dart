// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// A mapping from [HighlightRegionType] to a set of [SemanticTokenModifiers].
final highlightRegionTokenModifiers =
    <HighlightRegionType, Set<SemanticTokenModifiers>>{
  HighlightRegionType.COMMENT_DOCUMENTATION: {
    SemanticTokenModifiers.documentation
  },
  HighlightRegionType.CONSTRUCTOR_TEAR_OFF: {
    CustomSemanticTokenModifiers.constructor
  },
  HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.DYNAMIC_PARAMETER_DECLARATION: {
    SemanticTokenModifiers.declaration
  },
  HighlightRegionType.IMPORT_PREFIX: {
    CustomSemanticTokenModifiers.importPrefix,
  },
  HighlightRegionType.INSTANCE_FIELD_DECLARATION: {
    SemanticTokenModifiers.declaration,
    CustomSemanticTokenModifiers.instance
  },
  HighlightRegionType.INSTANCE_FIELD_REFERENCE: {
    CustomSemanticTokenModifiers.instance
  },
  HighlightRegionType.INSTANCE_GETTER_DECLARATION: {
    SemanticTokenModifiers.declaration,
    CustomSemanticTokenModifiers.instance
  },
  HighlightRegionType.INSTANCE_GETTER_REFERENCE: {
    CustomSemanticTokenModifiers.instance
  },
  HighlightRegionType.INSTANCE_METHOD_DECLARATION: {
    SemanticTokenModifiers.declaration,
    CustomSemanticTokenModifiers.instance
  },
  HighlightRegionType.INSTANCE_METHOD_REFERENCE: {
    CustomSemanticTokenModifiers.instance
  },
  HighlightRegionType.INSTANCE_METHOD_TEAR_OFF: {
    CustomSemanticTokenModifiers.instance
  },
  HighlightRegionType.INSTANCE_SETTER_DECLARATION: {
    SemanticTokenModifiers.declaration,
    CustomSemanticTokenModifiers.instance
  },
  HighlightRegionType.INSTANCE_SETTER_REFERENCE: {
    CustomSemanticTokenModifiers.instance
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
  HighlightRegionType.STATIC_METHOD_TEAR_OFF: {SemanticTokenModifiers.static},
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
  HighlightRegionType.VALID_STRING_ESCAPE: {
    CustomSemanticTokenModifiers.escape
  },
};

/// A mapping from [HighlightRegionType] to [SemanticTokenTypes].
///
/// A description of the intended uses for each token type can be found here:
/// https://code.visualstudio.com/api/language-extensions/semantic-highlight-guide#semantic-token-classification
final highlightRegionTokenTypes = {
  HighlightRegionType.ANNOTATION: CustomSemanticTokenTypes.annotation,
  HighlightRegionType.BUILT_IN: SemanticTokenTypes.keyword,
  HighlightRegionType.CLASS: SemanticTokenTypes.class_,
  HighlightRegionType.COMMENT_BLOCK: SemanticTokenTypes.comment,
  HighlightRegionType.COMMENT_DOCUMENTATION: SemanticTokenTypes.comment,
  HighlightRegionType.COMMENT_END_OF_LINE: SemanticTokenTypes.comment,
  HighlightRegionType.CONSTRUCTOR_TEAR_OFF: SemanticTokenTypes.method,
  HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_DECLARATION:
      SemanticTokenTypes.variable,
  HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_REFERENCE:
      SemanticTokenTypes.variable,
  HighlightRegionType.DYNAMIC_PARAMETER_DECLARATION:
      SemanticTokenTypes.parameter,
  HighlightRegionType.DYNAMIC_PARAMETER_REFERENCE: SemanticTokenTypes.parameter,
  HighlightRegionType.ENUM: SemanticTokenTypes.enum_,
  HighlightRegionType.ENUM_CONSTANT: SemanticTokenTypes.enumMember,
  HighlightRegionType.EXTENSION: SemanticTokenTypes.class_,
  HighlightRegionType.FUNCTION_TYPE_ALIAS: SemanticTokenTypes.type,
  HighlightRegionType.IDENTIFIER_DEFAULT: CustomSemanticTokenTypes.source,
  HighlightRegionType.IMPORT_PREFIX: SemanticTokenTypes.variable,
  HighlightRegionType.INSTANCE_FIELD_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.INSTANCE_FIELD_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.INSTANCE_GETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.INSTANCE_GETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.INSTANCE_METHOD_DECLARATION: SemanticTokenTypes.method,
  HighlightRegionType.INSTANCE_METHOD_REFERENCE: SemanticTokenTypes.method,
  HighlightRegionType.INSTANCE_METHOD_TEAR_OFF: SemanticTokenTypes.method,
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
  HighlightRegionType.LOCAL_FUNCTION_TEAR_OFF: SemanticTokenTypes.function,
  HighlightRegionType.LOCAL_VARIABLE_DECLARATION: SemanticTokenTypes.variable,
  HighlightRegionType.LOCAL_VARIABLE_REFERENCE: SemanticTokenTypes.variable,
  HighlightRegionType.PARAMETER_DECLARATION: SemanticTokenTypes.parameter,
  HighlightRegionType.PARAMETER_REFERENCE: SemanticTokenTypes.parameter,
  HighlightRegionType.STATIC_FIELD_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.STATIC_GETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.STATIC_GETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.STATIC_METHOD_DECLARATION: SemanticTokenTypes.method,
  HighlightRegionType.STATIC_METHOD_REFERENCE: SemanticTokenTypes.method,
  HighlightRegionType.STATIC_METHOD_TEAR_OFF: SemanticTokenTypes.method,
  HighlightRegionType.STATIC_SETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.STATIC_SETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION:
      SemanticTokenTypes.function,
  HighlightRegionType.TOP_LEVEL_FUNCTION_REFERENCE: SemanticTokenTypes.function,
  HighlightRegionType.TOP_LEVEL_FUNCTION_TEAR_OFF: SemanticTokenTypes.function,
  HighlightRegionType.TOP_LEVEL_GETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_SETTER_DECLARATION: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_SETTER_REFERENCE: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_VARIABLE: SemanticTokenTypes.property,
  HighlightRegionType.TOP_LEVEL_VARIABLE_DECLARATION:
      SemanticTokenTypes.property,
  HighlightRegionType.TYPE_ALIAS: SemanticTokenTypes.type,
  HighlightRegionType.TYPE_NAME_DYNAMIC: SemanticTokenTypes.type,
  HighlightRegionType.TYPE_PARAMETER: SemanticTokenTypes.typeParameter,
  HighlightRegionType.UNRESOLVED_INSTANCE_MEMBER_REFERENCE:
      CustomSemanticTokenTypes.source,
  HighlightRegionType.VALID_STRING_ESCAPE: SemanticTokenTypes.string,
};
