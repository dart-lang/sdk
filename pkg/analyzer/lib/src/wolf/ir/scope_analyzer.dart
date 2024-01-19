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
  eventListener._scopeAnalyzer = scopeAnalyzer;
  scopeAnalyzer.run();
  eventListener._scopeAnalyzer = null;
  return Scopes._(scopeAnalyzer);
}

/// Event listener used by [analyzeScopes] to report progress information.
///
/// By itself this class does nothing; the caller of [analyzeScopes] should make
/// a derived class that overrides one or more of the `on...` methods.
base class ScopeAnalyzerEventListener {
  /// When an invocation of [analyzeScopes] is running and using this listener,
  /// the [_ScopeAnalyzer] that is performing the analysis; otherwise `null`.
  _ScopeAnalyzer? _scopeAnalyzer;

  /// Allocates a fresh state variable.
  ///
  /// Clients of the scope analyzer can use this method to allocate state
  /// variables to track pieces of state that are specific to a particular kind
  /// of analysis (e.g., a state variable could be used to track the number of
  /// elements in a list that's referred to by the code being analyzed, or to
  /// track the state of the event loop in the case of asynchronous code).
  StateVar createStateVar() => _scopeAnalyzer!.createStateVar();

  /// Called for each variable allocated by an `alloc` instruction.
  ///
  /// [index] is the index of the allocated variable (counting from zero at the
  /// start of the code being analyzed; every call to this method within the
  /// context of a single call to [analyzeScopes] will an index one greater than
  /// the previous call).
  ///
  /// [stateVar] is the state variable that the scope analyzer has allocated to
  /// track the value of the variable.
  void onAlloc({required int index, required StateVar stateVar}) {}

  /// Called when the scope analyzer has completely finished analyzing the
  /// instruction stream.
  void onFinished() {}

  /// Called prior to visiting each instruction.
  ///
  /// This call back is invoked before more specific callbacks like [onAlloc].
  void onInstruction(int address) {}

  /// Called when [scopeAnalyzer] is about to process a "begin" instruction.
  void onPushScope({required int address, required int scope}) {}

  /// Records that the value of a state variable was potentially affected.
  ///
  /// Clients of the scope analyzer can use this method to indicate that one of
  /// the state variables returned by [createStateVar] was affected by a later
  /// instruction.
  void stateVarAffected(StateVar stateVar) =>
      _scopeAnalyzer!.stateVarAffected(stateVar);
}

/// The result of scope analysis.
///
/// See [analyzeScopes] for more information.
class Scopes {
  /// Total number of state variables that were allocated.
  ///
  /// Valid values of [StateVar.index] range from `0` to `stateVarCount-1`.
  final int stateVarCount;

  final List<StateVar> _allocIndexToStateVar;
  final List<int> _beginAddresses;
  final List<StateVar> _effects;
  final List<int> _effectCounts;
  final List<int> _effectIndices;
  final List<int> _endAddresses;
  final List<int> _lastDescendants;
  final List<int> _parents;

  Scopes._(_ScopeAnalyzer analyzer)
      : stateVarCount = analyzer.stateVarToPendingEffectsIndex.length,
        _allocIndexToStateVar = analyzer.allocIndexToStateVar,
        _beginAddresses = analyzer.beginAddresses,
        _effects = analyzer.effects,
        _effectCounts = analyzer.effectCounts,
        _effectIndices = analyzer.effectIndices,
        _endAddresses = analyzer.endAddresses,
        _lastDescendants = analyzer.lastDescendants,
        _parents = analyzer.parents;

  /// The number of scopes that was found.
  int get scopeCount => _beginAddresses.length;

  /// The state variable tracking the [allocIndex]th local variable that was
  /// allocated.
  StateVar allocIndexToStateVar(int allocIndex) =>
      _allocIndexToStateVar[allocIndex];

  /// Computes the innermost ancestor of [scope] (or [scope] itself), whose
  /// [endAddress] is greater than or equal to [address].
  ///
  /// This method may be used in conjunction with [lastScopeBefore] to find the
  /// innermost scope containing an instruction, according to the formula:
  ///
  ///     var scope = ancestorContainingAddress(
  ///         scope: lastScopeBefore(address), address: address);
  int ancestorContainingAddress({required int scope, required int address}) {
    while (endAddress(scope) < address) {
      // By validation, we know that the instruction sequence begins with
      // `function` or `instanceFunction`, so the outermost scope covers the
      // whole instruction sequence. Therefore, if `scope` is `0`, that means
      // that `address` must have been an invalid address.
      assert(scope > 0, 'invalid address');
      scope = parent(scope);
    }
    return scope;
  }

  /// The address of the "begin" instruction that opens [scope].
  ///
  /// Scopes are numbered in pre-order, so a [scope] of `i` corresponds to the
  /// scope opened by the `i`th begin instruction in the IR.
  int beginAddress(int scope) => _beginAddresses[scope];

  /// Retrieves one of the state variables affected by a scope.
  ///
  /// To find the `i`th state variable affected by `scope`, use an [index] value
  /// of `effectIndex(scope) + i`.
  StateVar effectAt(int index) => _effects[index];

  /// The number of state variables affected by instructions in [scope].
  ///
  /// Scopes are numbered in pre-order, so a [scope] of `i` corresponds to the
  /// scope opened by the `i`th begin instruction in the IR.
  int effectCount(int scope) => _effectCounts[scope];

  /// The first index to pass to [effectAt] to enumerate the state variables
  /// affected by instructions in [scope].
  ///
  /// Scopes are numbered in pre-order, so a [scope] of `i` corresponds to the
  /// scope opened by the `i`th begin instruction in the IR.
  int effectIndex(int scope) => _effectIndices[scope];

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

  /// The scope immediately containing [scope], or `-1` if [scope] is the
  /// outermost scope.
  ///
  /// Scopes are numbered in pre-order, so a [scope] of `i` corresponds to the
  /// scope opened by the `i`th begin instruction in the IR.
  int parent(int scope) => _parents[scope];
}

/// A state variable tracked by the scope analyzer.
///
/// State variables are simply unique integer indices; clients that need to
/// track information about each state variable should store that information in
/// a list indexed by the state variable.
// TODO(paulberry): when extension types are supported, make this an extension
// type.
class StateVar {
  final int index;

  StateVar(this.index);

  @override
  int get hashCode => index.hashCode;

  @override
  bool operator ==(other) => other is StateVar && index == other.index;

  @override
  String toString() => index.toString();
}

/// Analyzer of the scopes, and their effects on state variables, in a
/// [BaseIRContainer].
///
/// This class computes the nesting of begin/end scopes in [ir]. A begin/end
/// scope is the set of instructions between a "begin" instruction (a `block`,
/// `loop`, `tryCatch`, `tryFinally`, `function`, or `instanceFunction`
/// instruction) and the `end` instruction that matches it. It also computes the
/// set of state variables affected by the code within each begin/end scope.
///
/// State variables correspond to local variables in the program, as well as any
/// other significant program state that needs to be tracked; the specific state
/// variables that are tracked are determined by caller of [analyzeScopes].
base class _ScopeAnalyzer {
  static const enableDebugPrints = false;
  final BaseIRContainer ir;
  final ScopeAnalyzerEventListener eventListener;

  /// Stack of scope indices for all open scopes.
  ///
  /// This stack begins with a sentinel value of `-1`, so that when [pushScope]
  /// is called for the first time (to create the outermost scope) it will set
  /// the outermost scope's parent scope to `-1`.
  final scopeIndices = [-1];

  /// Stack of state variables affected by all open scopes.
  ///
  /// The locals written in the outermost scope appear first, then the ones in
  /// the next inner scope, and so on. Locals are de-duplicated within a scope.
  final pendingEffects = <StateVar>[];

  /// Stack of indices into [pendingEffects] representing the start of each
  /// scope enclosing the current scope.
  final outerScopeStarts = <int>[];

  /// Table mapping each state variable to the index of its last appearance in
  /// [pendingEffects].
  ///
  /// And index of -1 means the local does not appear in [pendingEffects].
  final stateVarToPendingEffectsIndex = <int>[];

  /// Table mapping each index in [pendingEffects] to the previous occurrence
  /// of the same state variable in [pendingEffects].
  final previousPendingEffectsIndices = <int>[];

  /// Table mapping each local to the state variable that tracks it.
  final localToStateVar = <StateVar>[];

  /// See [Scopes.allocIndexToStateVar].
  final allocIndexToStateVar = <StateVar>[];

  /// See [Scopes.beginAddress].
  final beginAddresses = <int>[];

  /// See [Scopes.effectAt].
  final effects = <StateVar>[];

  /// See [Scopes.effectCount].
  final effectCounts = <int>[];

  /// See [Scopes.effectIndex].
  final effectIndices = <int>[];

  /// See [Scopes.endAddress].
  final endAddresses = <int>[];

  /// See [Scopes.lastDescendant].
  final lastDescendants = <int>[];

  /// See [Scopes.parent].
  final parents = <int>[];

  var nextAllocIndex = 0;

  /// Index into [pendingEffects] representing the start of the current scope.
  var scopeStart = 0;

  _ScopeAnalyzer(this.ir, this.eventListener);

  bool checkState() {
    if (enableDebugPrints) dumpState();
    var stateVarCount = stateVarToPendingEffectsIndex.length;
    var pendingEffectsCount = pendingEffects.length;
    // `_scopeIndices` always starts with the sentinel value `-1`.
    assert(scopeIndices[0] == -1, 'invalid sentinel value in _scopeIndices');
    // Scopes are numbered in pre-order, so `_scopeIndices` should be
    // monotonically increasing.
    for (var i = 0; i < scopeIndices.length - 1; i++) {
      assert(scopeIndices[i] < scopeIndices[i + 1],
          '_scopeIndices out of order: $scopeIndices');
    }
    // State variables mentioned in `_pendingEffects` must exist.
    for (var stateVar in pendingEffects) {
      assert(
          stateVar.index >= 0 && stateVar.index < stateVarCount,
          '_pendingEffects contains non-existent state var $stateVar: '
          '$pendingEffects');
    }
    // `_scopeStart` and `_outerScopeStarts` should refer to properly nested
    // indices within `_pendingEffects`.
    var previousScopeStart = 0;
    var scopeStarts = [...outerScopeStarts, scopeStart];
    for (var scopeStart in scopeStarts) {
      assert(scopeStart >= previousScopeStart,
          'improper nesting of scope starts: $scopeStarts');
      assert(scopeStart <= pendingEffectsCount,
          'scope start is too large: $scopeStart > $pendingEffectsCount');
    }
    // `_stateVarToPendingEffectsIndex` and `_previousPendingEffectsIndices`
    // should properly reflect the contents of `_pendingEffects`.
    assert(
        previousPendingEffectsIndices.length == pendingEffectsCount,
        '_previousPendingEffectsIndices should have length '
        '$pendingEffectsCount: $previousPendingEffectsIndices');
    var expectedStateVarToPendingEffectsIndex =
        List.filled(stateVarToPendingEffectsIndex.length, -1);
    for (var i = 0; i < pendingEffectsCount; i++) {
      assert(
          previousPendingEffectsIndices[i] ==
              expectedStateVarToPendingEffectsIndex[pendingEffects[i].index],
          '_previousPendingEffectsIndices[$i] is incorrect: expected '
          '${expectedStateVarToPendingEffectsIndex[pendingEffects[i].index]}, '
          'got ${previousPendingEffectsIndices[i]}');
      expectedStateVarToPendingEffectsIndex[pendingEffects[i].index] = i;
    }
    for (var i = 0; i < stateVarCount; i++) {
      assert(
          stateVarToPendingEffectsIndex[i] ==
              expectedStateVarToPendingEffectsIndex[i],
          '_stateVarToPendingEffectsIndex is incorrect: '
          'expected $expectedStateVarToPendingEffectsIndex, '
          'got $stateVarToPendingEffectsIndex');
    }
    // State variables mentioned in `_localToStateVar` must exist.
    for (var stateVar in localToStateVar) {
      assert(
          stateVar.index >= 0 && stateVar.index < stateVarCount,
          '_localToStateVar contains non-existent state var $stateVar: '
          '$localToStateVar');
    }
    return true;
  }

  StateVar createStateVar() {
    var stateVar = StateVar(stateVarToPendingEffectsIndex.length);
    stateVarToPendingEffectsIndex.add(-1);
    return stateVar;
  }

  void dumpState() {
    print('  scopeIndices: $scopeIndices');
    print('  pendingEffects: $pendingEffects');
    print('  scopeStart: $scopeStart');
    print('  outerScopeStarts: $outerScopeStarts');
    print('  stateVarToPendingEffectsIndex: $stateVarToPendingEffectsIndex');
    print('  previousPendingEffectsIndices: $previousPendingEffectsIndices');
    print('  localToStateVar: $localToStateVar');
    print('  allocIndexToStateVar: $allocIndexToStateVar');
    print('  beginAddresses: $beginAddresses');
    print('  effects: $effects');
    print('  effectCounts: $effectCounts');
    print('  effectIndices: $effectIndices');
    print('  endAddresses: $endAddresses');
    print('  lastDescendants: $lastDescendants');
    print('  parents: $parents');
  }

  void popScope(int address) {
    var innerScopeStart = scopeStart;
    scopeStart = outerScopeStarts.removeLast();
    var scopeIndex = scopeIndices.removeLast();
    endAddresses[scopeIndex] = address;
    lastDescendants[scopeIndex] = lastDescendants.length - 1;
    effectIndices[scopeIndex] = effects.length;
    effectCounts[scopeIndex] = pendingEffects.length - innerScopeStart;
    for (var i = innerScopeStart; i < pendingEffects.length;) {
      var stateVar = pendingEffects[i];
      effects.add(stateVar);
      var previousPendingEffectsIndex = previousPendingEffectsIndices[i];
      if (previousPendingEffectsIndex >= scopeStart) {
        // This state variable was also affected by the outer scope, so remove
        // the duplicate.
        removePendingEffect(stateVar, i, previousPendingEffectsIndex);
        // And then carry on with index `i`, which now represents a different
        // state variable.
      } else {
        // This state variable effect wasn't duplicated, so move onto the next
        // one.
        i++;
      }
    }
  }

  void pushScope(int address) {
    var scope = beginAddresses.length;
    eventListener.onPushScope(address: address, scope: scope);
    var pendingEffectsLength = pendingEffects.length;
    outerScopeStarts.add(scopeStart);
    scopeStart = pendingEffectsLength;
    var outerScope = scopeIndices.last;
    scopeIndices.add(scope);
    beginAddresses.add(address);
    endAddresses.add(-1);
    effectIndices.add(-1);
    effectCounts.add(-1);
    lastDescendants.add(-1);
    parents.add(outerScope);
  }

  void removePendingEffect(StateVar stateVar, int pendingEffectsIndex,
      int previousPendingEffectsIndex) {
    assert(
        stateVarToPendingEffectsIndex[stateVar.index] == pendingEffectsIndex);
    assert(previousPendingEffectsIndices[pendingEffectsIndex] ==
        previousPendingEffectsIndex);
    // There may be additional entries in `_pendingEffects` after the entry to
    // be removed, so move the last entry in `_pendingEffects` to
    // `pendingEffectsIndex`. This is a no-op if the entry to be removed is
    // already the last entry, but we do it anyway to avoid a
    // difficult-to-predict branch.
    var stateVarToMove = pendingEffects.last;
    pendingEffects[pendingEffectsIndex] = stateVarToMove;
    stateVarToPendingEffectsIndex[stateVarToMove.index] = pendingEffectsIndex;
    previousPendingEffectsIndices[pendingEffectsIndex] =
        previousPendingEffectsIndices.last;
    // Drop the last entry in `_pendingEffects`.
    stateVarToPendingEffectsIndex[stateVar.index] = previousPendingEffectsIndex;
    pendingEffects.removeLast();
    previousPendingEffectsIndices.removeLast();
  }

  void run() {
    for (var address = 0; address < ir.endAddress; address++) {
      assert(checkState());
      if (enableDebugPrints) {
        print('$address: ${ir.instructionToString(address)}');
      }
      eventListener.onInstruction(address);
      switch (ir.opcodeAt(address)) {
        case Opcode.alloc:
          var count = Opcode.alloc.decodeCount(ir, address);
          for (var i = 0; i < count; i++) {
            var stateVar = createStateVar();
            eventListener.onAlloc(
                index: allocIndexToStateVar.length, stateVar: stateVar);
            localToStateVar.add(stateVar);
            allocIndexToStateVar.add(stateVar);
          }
        case Opcode.block:
        case Opcode.function:
        case Opcode.loop:
          pushScope(address);
        case Opcode.end:
          popScope(address);
        case Opcode.release:
          var count = Opcode.release.decodeCount(ir, address);
          for (var i = 0; i < count; i++) {
            var stateVar = localToStateVar.last;
            var pendingEffectsIndex =
                stateVarToPendingEffectsIndex[stateVar.index];
            if (pendingEffectsIndex >= 0) {
              // Local should have been allocated in this scope, so it can't
              // affect any outer scope, and therefore we can stop tracking it.
              const previousPendingEffectsIndex = -1;
              removePendingEffect(
                  stateVar, pendingEffectsIndex, previousPendingEffectsIndex);
            }
            localToStateVar.removeLast();
          }
        case Opcode.writeLocal:
          var local = Opcode.writeLocal.decodeLocalIndex(ir, address);
          stateVarAffected(localToStateVar[local]);
      }
    }
    assert(checkState());
    assert(scopeIndices.length == 1);
    assert(scopeStart == 0);
    assert(outerScopeStarts.isEmpty);
    assert(localToStateVar.isEmpty);
    eventListener.onFinished();
  }

  void stateVarAffected(StateVar stateVar) {
    var pendingEffectsIndex = stateVarToPendingEffectsIndex[stateVar.index];
    // Only record an entry in `_pendingEffects` if there isn't already an
    // entry indicating that the state variable was affected in the
    // current scope.
    if (stateVarToPendingEffectsIndex[stateVar.index] < scopeStart) {
      previousPendingEffectsIndices.add(pendingEffectsIndex);
      stateVarToPendingEffectsIndex[stateVar.index] = pendingEffects.length;
      pendingEffects.add(stateVar);
    }
  }
}
