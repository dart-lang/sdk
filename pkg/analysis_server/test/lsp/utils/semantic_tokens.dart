// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';

/// A helper enum to combine both standard and custom modifiers so that they
/// can all be used as DotShorthands for improved readability in test
/// expectations.
enum AllSemanticTokenModifiers {
  abstract(SemanticTokenModifiers.abstract),
  annotation(CustomSemanticTokenModifiers.annotation),
  async(SemanticTokenModifiers.async),
  constructor(CustomSemanticTokenModifiers.constructor),
  control(CustomSemanticTokenModifiers.control),
  declaration(SemanticTokenModifiers.declaration),
  defaultLibrary(SemanticTokenModifiers.defaultLibrary),
  definition(SemanticTokenModifiers.definition),
  deprecated(SemanticTokenModifiers.deprecated),
  documentation(SemanticTokenModifiers.documentation),
  escape(CustomSemanticTokenModifiers.escape),
  importPrefix(CustomSemanticTokenModifiers.importPrefix),
  instance(CustomSemanticTokenModifiers.instance),
  interpolation(CustomSemanticTokenModifiers.interpolation),
  label(CustomSemanticTokenModifiers.label),
  modification(SemanticTokenModifiers.modification),
  readonly(SemanticTokenModifiers.readonly),
  source(CustomSemanticTokenModifiers.source),
  static(SemanticTokenModifiers.static),
  void_(CustomSemanticTokenModifiers.void_),
  wildcard(CustomSemanticTokenModifiers.wildcard);

  final SemanticTokenModifiers modifier;

  new(this.modifier);

  factory forModifier(SemanticTokenModifiers modifier) {
    return AllSemanticTokenModifiers.values.singleWhere(
      (value) => value.modifier == modifier,
    );
  }
}

/// A helper enum to combine both standard and custom semantic token types so
/// that they can all be used as DotShorthands for improved readability in test
/// expectations.
///
///
enum AllSemanticTokenTypes {
  annotation(CustomSemanticTokenTypes.annotation),
  boolean(CustomSemanticTokenTypes.boolean),
  class_(SemanticTokenTypes.class_),
  comment(SemanticTokenTypes.comment),
  decorator(SemanticTokenTypes.decorator),
  enum_(SemanticTokenTypes.enum_),
  enumMember(SemanticTokenTypes.enumMember),
  event(SemanticTokenTypes.event),
  function(SemanticTokenTypes.function),
  interface(SemanticTokenTypes.interface),
  keyword(SemanticTokenTypes.keyword),
  label(SemanticTokenTypes.label),
  macro(SemanticTokenTypes.macro),
  method(SemanticTokenTypes.method),
  modifier(SemanticTokenTypes.modifier),
  namespace(SemanticTokenTypes.namespace),
  number(SemanticTokenTypes.number),
  operator(SemanticTokenTypes.operator),
  parameter(SemanticTokenTypes.parameter),
  property(SemanticTokenTypes.property),
  regexp(SemanticTokenTypes.regexp),
  source(CustomSemanticTokenTypes.source),
  string(SemanticTokenTypes.string),
  struct(SemanticTokenTypes.struct),
  type(SemanticTokenTypes.type),
  typeParameter(SemanticTokenTypes.typeParameter),
  variable(SemanticTokenTypes.variable);

  final SemanticTokenTypes tokenType;

  new(this.tokenType);

  factory forTokenType(SemanticTokenTypes tokenType) {
    return AllSemanticTokenTypes.values.singleWhere(
      (value) => value.tokenType == tokenType,
    );
  }
}

mixin SemanticTokensTestMixin {
  String get eol;

  /// Decode tokens according to the LSP spec and pair with relevant file contents.
  List<Token> decodeSemanticTokens(String content, SemanticTokens tokens) {
    var contentLines = content.split(eol).map((line) => '$line$eol').toList();
    var results = <Token>[];

    var lastLine = 0;
    var lastColumn = 0;
    for (var i = 0; i < tokens.data.length; i += 5) {
      var lineDelta = tokens.data[i];
      var columnDelta = tokens.data[i + 1];
      var length = tokens.data[i + 2];
      var tokenTypeIndex = tokens.data[i + 3];
      var modifierBitmask = tokens.data[i + 4];

      // Calculate the actual line/col from the deltas.
      var line = lastLine + lineDelta;
      var column = lineDelta == 0 ? lastColumn + columnDelta : columnDelta;

      var tokenContent = contentLines[line].substring(column, column + length);
      results.add(
        Token(
          tokenContent,
          AllSemanticTokenTypes.forTokenType(
            semanticTokenLegend.typeForIndex(tokenTypeIndex),
          ),
          semanticTokenLegend
              .modifiersForBitmask(modifierBitmask)
              .map(AllSemanticTokenModifiers.forModifier)
              .toList(),
        ),
      );

      lastLine = line;
      lastColumn = column;
    }

    return results;
  }
}

class Token {
  final String content;
  final SemanticTokenTypes type;
  final List<SemanticTokenModifiers> modifiers;

  new(
    this.content,
    AllSemanticTokenTypes type, [
    List<AllSemanticTokenModifiers> mods = const [],
  ]) : type = type.tokenType,
       modifiers = mods.map((mod) => mod.modifier).toList();

  @override
  int get hashCode => content.hashCode;

  @override
  bool operator ==(Object o) =>
      o is Token &&
      o.content == content &&
      o.type == type &&
      listEqual(
        // Treat nulls the same as empty lists for convenience when comparing.
        o.modifiers,
        modifiers,
        (SemanticTokenModifiers a, SemanticTokenModifiers b) => a == b,
      );

  /// Outputs a text representation of the token in the form of constructor
  /// args for easy copy/pasting into tests to update expectations.
  @override
  String toString() {
    var modifiersString = modifiers.isEmpty
        ? ''
        : ', [${modifiers.map((m) => '.$m').join(', ')}]';
    return "('$content', .$type$modifiersString)";
  }
}
