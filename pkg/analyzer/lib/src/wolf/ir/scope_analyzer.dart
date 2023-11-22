// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/wolf/ir/ir.dart';

/// Analyzes the scopes in a [BaseIRContainer].
///
/// This function computes the nesting of begin/end scopes in [ir]. A begin/end
/// scope is the set of instructions between a "begin" instruction (a `block`,
/// `loop`, `tryCatch`, `tryFinally`, `function`, or `instanceFunction`
/// instruction) and the `end` instruction that matches it.
Scopes analyzeScopes(BaseIRContainer ir,
    {ScopeAnalyzerEventListener? eventListener}) {
  eventListener ??= ScopeAnalyzerEventListener();
  var scopeAnalyzer = _ScopeAnalyzer(ir, eventListener);
  scopeAnalyzer.run();
  return Scopes._(scopeAnalyzer);
}

/// Event listener used by [analyzeScopes] to report progress information.
///
/// By itself this class does nothing; the caller of [analyzeScopes] should make
/// a derived class that overrides one or more of the `on...` methods.
base class ScopeAnalyzerEventListener {
  /// Called when [scopeAnalyzer] is about to process a "begin" instruction.
  void onPushScope({required int address, required int scope}) {}
}

/// The result of scope analysis.
///
/// See [analyzeScopes] for more information.
class Scopes {
  final List<int> _beginAddresses;
  final List<int> _endAddresses;
  final List<int> _lastDescendants;

  Scopes._(_ScopeAnalyzer analyzer)
      : _beginAddresses = analyzer.beginAddresses,
        _endAddresses = analyzer.endAddresses,
        _lastDescendants = analyzer.lastDescendants;

  /// The number of scopes that was found.
  int get scopeCount => _beginAddresses.length;

  /// The address of the "begin" instruction that opens [scope].
  ///
  /// Scopes are numbered in pre-order, so a [scope] of `i` corresponds to the
  /// scope opened by the `i`th begin instruction in the IR.
  int beginAddress(int scope) => _beginAddresses[scope];

  /// The address of the `end` instruction that closes [scope].
  ///
  /// Scopes are numbered in pre-order, so a [scope] of `i` corresponds to the
  /// scope opened by the `i`th begin instruction in the IR.
  int endAddress(int scope) => _endAddresses[scope];

  /// The scope index of the last scope transitively contained within [scope].
  ///
  /// If [scope] doesn't contain any other scopes, then [scope] is returned.
  int lastDescendant(int scope) => _lastDescendants[scope];

  /// Computes the highest-numbered scope whose [beginAddress] is less than or
  /// equal to [address].
  ///
  /// Scopes are numbered in pre-order, so the returned scope will either be the
  /// innermost scope containing [address], or one of its ancestors will be (see
  /// [ancestorContainingAddress]).
  int mostRecentScope(int address) {
    assert(address >= 0);
    // By validation, we know that the instruction sequence begins with
    // `function` or `instanceFunction`, so the outermost scope covers the whole
    // instruction sequence.
    assert(beginAddress(0) == 0);
    var low = 0;
    var high = scopeCount;
    while (low < high - 1) {
      // Loop invariants
      assert(beginAddress(low) <= address);
      assert(high == scopeCount || beginAddress(high) > address);

      var mid = (low + high) ~/ 2;
      if (beginAddress(mid) <= address) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

base class _ScopeAnalyzer {
  static const enableDebugPrints = false;
  final BaseIRContainer ir;
  final ScopeAnalyzerEventListener eventListener;

  /// Stack of scope indices for all open scopes.
  final scopeIndices = <int>[];

  /// See [Scopes.beginAddress].
  final beginAddresses = <int>[];

  /// See [Scopes.endAddress].
  final endAddresses = <int>[];

  /// See [Scopes.lastDescendant].
  final lastDescendants = <int>[];

  _ScopeAnalyzer(this.ir, this.eventListener);

  bool checkState() {
    if (enableDebugPrints) dumpState();
    // Scopes are numbered in pre-order, so `_scopeIndices` should be
    // monotonically increasing.
    for (var i = 0; i < scopeIndices.length - 1; i++) {
      assert(scopeIndices[i] < scopeIndices[i + 1],
          '_scopeIndices out of order: $scopeIndices');
    }
    return true;
  }

  void dumpState() {
    print('  scopeIndices: $scopeIndices');
    print('  beginAddresses: $beginAddresses');
    print('  endAddresses: $endAddresses');
    print('  lastDescendants: $lastDescendants');
  }

  void popScope(int address) {
    var scopeIndex = scopeIndices.removeLast();
    endAddresses[scopeIndex] = address;
    lastDescendants[scopeIndex] = lastDescendants.length - 1;
  }

  void pushScope(int address) {
    var scope = beginAddresses.length;
    eventListener.onPushScope(address: address, scope: scope);
    scopeIndices.add(scope);
    beginAddresses.add(address);
    endAddresses.add(-1);
    lastDescendants.add(-1);
  }

  void run() {
    for (var address = 0; address < ir.endAddress; address++) {
      assert(checkState());
      if (enableDebugPrints) {
        print('$address: ${ir.instructionToString(address)}');
      }
      switch (ir.opcodeAt(address)) {
        case Opcode.function:
          pushScope(address);
        case Opcode.block:
        case Opcode.loop:
          pushScope(address);
        case Opcode.end:
          popScope(address);
      }
    }
    assert(checkState());
    assert(scopeIndices.isEmpty);
  }
}
