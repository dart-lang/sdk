// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/mapping.dart';
import 'package:meta/meta.dart';

final semanticTokenLegend = SemanticTokenLegendLookup();

/// A helper for looking up indexes and bitmasks of [SemanticTokenTypes] and
/// [SemanticTokenModifiers].
class SemanticTokenLegendLookup {
  /// An LSP [SemanticTokensLegend] describing all supported tokens and modifiers.
  SemanticTokensLegend lspLegend;

  /// All [SemanticTokenModifiers] the server may generate. The order of these
  /// items is important as the indexes will be used in communication between
  /// server and client.
  List<SemanticTokenModifiers> _usedTokenModifiers;

  /// All [SemanticTokenTypes] the server may generate. The order of these
  /// items is important as the indexes will be used in communication betewen
  /// server and client.
  List<SemanticTokenTypes> _usedTokenTypes;

  SemanticTokenLegendLookup() {
    // Build lists of all tokens and modifiers that exist in our mappings. These will
    // be used to determine the indexes used for communication.
    _usedTokenTypes = Set.of(highlightRegionTokenTypes.values).toList();
    _usedTokenModifiers =
        Set.of(highlightRegionTokenModifiers.values.expand((v) => v)).toList();

    // Build the LSP Legend which tells the client all of the tokens and modifiers
    // we will use in the order they should be accessed by index/bit.
    lspLegend = SemanticTokensLegend(
      tokenTypes:
          _usedTokenTypes.map((tokenType) => tokenType.toString()).toList(),
      tokenModifiers: _usedTokenModifiers
          .map((tokenModifier) => tokenModifier.toString())
          .toList(),
    );
  }

  int bitmaskForModifiers(Set<SemanticTokenModifiers> modifiers) {
    // Modifiers use a bit mask where each bit represents the index of a modifier.
    // 001001 would indicate the 1st and 4th modifiers are applied.
    return modifiers
            ?.map(_usedTokenModifiers.indexOf)
            ?.map((index) => math.pow(2, index))
            ?.reduce((a, b) => a + b) ??
        0;
  }

  int indexForType(SemanticTokenTypes type) {
    return _usedTokenTypes.indexOf(type);
  }

  /// Gets the [SemanticTokenModifiers] for a given index.
  @visibleForTesting
  List<SemanticTokenModifiers> modifiersForBitmask(int mask) {
    final modifiers = <SemanticTokenModifiers>[];
    for (var i = 0; i < _usedTokenModifiers.length; i++) {
      // Check if the i'th bit is set
      final modifierBit = 1 << i;
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
