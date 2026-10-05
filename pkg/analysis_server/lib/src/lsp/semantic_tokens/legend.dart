// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/mapping.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

final semanticTokenLegend = SemanticTokenLegendLookup.fromServerValues();

/// A helper for looking up indexes and bitmasks of [SemanticTokenTypes] and
/// [SemanticTokenModifiers].
class SemanticTokenLegendLookup {
  /// An LSP [SemanticTokensLegend] describing all supported tokens and modifiers.
  final SemanticTokensLegend lspLegend;

  /// All [SemanticTokenModifiers] the server may generate. The order of these
  /// items is important as the indexes will be used in communication between
  /// server and client.
  final List<SemanticTokenModifiers> _usedTokenModifiers;

  /// All [SemanticTokenTypes] the server may generate. The order of these
  /// items is important as the indexes will be used in communication between
  /// server and client.
  final List<SemanticTokenTypes> _usedTokenTypes;

  /// Creates a new legend lookup using the supplied legend (for example a
  /// legend provided by the server to a client).
  new(this.lspLegend)
    : _usedTokenTypes = lspLegend.tokenTypes
          .map(SemanticTokenTypes.fromJson)
          .toList(),
      _usedTokenModifiers = lspLegend.tokenModifiers
          .map(SemanticTokenModifiers.fromJson)
          .toList();

  /// Creates a new legend lookup by first building a legend from the token
  /// types and modifiers used by the server.
  factory fromServerValues() {
    // Build the LSP Legend which tells the client all of the tokens and modifiers
    // we will use in the order they should be accessed by index/bit.
    var legend = SemanticTokensLegend(
      tokenTypes: highlightRegionTokenTypes.values
          .followedBy(CustomSemanticTokenTypes.values)
          .map((tokenType) => tokenType.toString())
          .toSet()
          .toList(),
      tokenModifiers: highlightRegionTokenModifiers.values.flattenedToList
          .followedBy(CustomSemanticTokenModifiers.values)
          .map((tokenModifier) => tokenModifier.toString())
          .toSet()
          .toList(),
    );

    return SemanticTokenLegendLookup(legend);
  }

  int bitmaskForModifiers(Set<SemanticTokenModifiers>? modifiers) {
    // Modifiers use a bit mask where each bit represents the index of a modifier.
    // 001001 would indicate the 1st and 4th modifiers are applied.
    return modifiers
            ?.map(_usedTokenModifiers.indexOf)
            .map((index) => math.pow(2, index))
            .reduce((a, b) => a + b)
            .toInt() ??
        0;
  }

  int indexForType(SemanticTokenTypes type) {
    return _usedTokenTypes.indexOf(type);
  }

  /// Gets the [SemanticTokenModifiers] for a given index.
  @visibleForTesting
  List<SemanticTokenModifiers> modifiersForBitmask(int mask) {
    var modifiers = <SemanticTokenModifiers>[];
    for (var i = 0; i < _usedTokenModifiers.length; i++) {
      // Check if the i'th bit is set
      var modifierBit = 1 << i;
      if (mask & modifierBit != 0) {
        modifiers.add(_usedTokenModifiers[i]);
      }
    }
    return modifiers;
  }

  /// Gets the [SemanticTokenTypes] for a given index.
  @visibleForTesting
  SemanticTokenTypes typeForIndex(int index) => _usedTokenTypes[index];
}
