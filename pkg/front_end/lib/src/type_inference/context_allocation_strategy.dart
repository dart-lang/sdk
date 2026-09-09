// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:kernel/ast.dart';

import '../util/local_stack.dart';

extension type ScopeProviderInfoStack<Info extends ScopeProviderInfo>(
  List<Info> _list,
) implements LocalStack<Info> {
  ScopeProviderInfo? topmostOfKind(
    Set<ScopeProviderInfoKind> scopeProviderInfoKinds,
  ) {
    for (int index = _list.length - 1; index >= 0; index--) {
      Info info = _list[index];
      if (scopeProviderInfoKinds.contains(info.kind)) {
        return info;
      }
    }
    return null;
  }
}

enum ScopeProviderInfoKind {
  Block,
  BlockExpression,
  Catch,
  FunctionNode,
  FunctionNodeWithThis,
  InstanceField,
  Loop,
  StaticField,
}

class ScopeProviderInfo({required this.kind}) {
  final ScopeProviderInfoKind kind;
  Scope? scope;
  ThisVariable? thisVariable;
}

abstract class ContextAllocationStrategy<Info extends ScopeProviderInfo> {
  final ScopeProviderInfoStack<Info> _scopeProviderInfoStack =
      new ScopeProviderInfoStack<Info>(<Info>[]);

  static ContextAllocationStrategy<ScopeProviderInfo>
  createContextAllocationStrategy({
    required bool isClosureContextLoweringEnabled,
  }) {
    if (isClosureContextLoweringEnabled) {
      return new TrivialContextAllocationStrategy();
    } else {
      return new EmptyContextAllocationStrategy();
    }
  }

  final bool _enableDebugLogging = true;
  StringBuffer? _debugLog;

  Info? get _currentScopeProviderInfo => _scopeProviderInfoStack.currentOrNull;

  final PatternScopeListener<Info> _patternScopeBuilder =
      new PatternScopeListener<Info>();

  void _writeDebugLine(String line) {
    if (_enableDebugLogging) {
      (_debugLog ??= new StringBuffer()).writeln(line);
    }
  }

  // Coverage-ignore(suite): Not run.
  String _readDebugLog() {
    return _debugLog?.toString() ?? "";
  }

  /// Creates and returns a tracking object for the entered [ScopeProvider].
  Info enterScopeProvider({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) {
    Info scopeProviderInfo = createScopeProviderInfo(
      scopeProviderInfoKind: scopeProviderInfoKind,
    );
    _scopeProviderInfoStack.push(scopeProviderInfo);

    assert(() {
      _writeDebugLine(
        "Entered ${scopeProviderInfo.kind} "
        "(id=${identityHashCode(scopeProviderInfo)}).",
      );
      return true;
    }());

    return scopeProviderInfo;
  }

  /// Ensures that the tracking object [scopeProviderInfo] for the exited
  /// [ScopeProvider] matches the one previously entered.
  void exitScopeProvider(ScopeProviderInfo scopeProviderInfo) {
    assert(() {
      _writeDebugLine(
        "Exited ${scopeProviderInfo.kind} "
        "(id=${identityHashCode(scopeProviderInfo)}).",
      );
      return true;
    }());
    assert(
      identical(_currentScopeProviderInfo, scopeProviderInfo),
      "Expected the current scope provider "
      "to be identical to the exited one: "
      "current=${_currentScopeProviderInfo?.kind}, "
      "exited=${scopeProviderInfo.kind}."
      "\nDebug log:\n${_readDebugLog()}",
    );
    _scopeProviderInfoStack.pop();
  }

  static Scope _ensureScope(ScopeProviderInfo info) {
    return info.scope ??= new Scope(contexts: []);
  }

  Scope _ensureScopeWithThis() {
    ScopeProviderInfo? scopeProviderInfo = _scopeProviderInfoStack
        .topmostOfKind(const {
          ScopeProviderInfoKind.FunctionNodeWithThis,
          ScopeProviderInfoKind.InstanceField,
        });
    assert(scopeProviderInfo != null);
    return scopeProviderInfo!.scope ??= // Coverage-ignore(suite): Not run.
    new Scope(
      contexts: [],
    );
  }

  VariableContext _ensureVariableContextInCurrentScope({
    required CaptureKind captureKind,
  }) {
    return ensureVariableContextInScopeProviderInfo(
      info: _currentScopeProviderInfo!,
      captureKind: captureKind,
    );
  }

  static VariableContext ensureVariableContextInScopeProviderInfo<
    Info extends ScopeProviderInfo
  >({required Info info, required CaptureKind captureKind}) {
    Scope scope = _ensureScope(info);
    VariableContext? context = _fetchVariableContextOfScope(
      scope: scope,
      captureKind: captureKind,
    );
    if (context != null) {
      return context;
    } else {
      context = new VariableContext(captureKind: captureKind, variables: []);
      scope.addContext(context);
      return context;
    }
  }

  static VariableContext? _fetchVariableContextOfScope({
    required Scope scope,
    required CaptureKind captureKind,
  }) {
    for (VariableContext context in scope.contexts) {
      if (context.captureKind == captureKind) {
        return context;
      }
    }
    return null;
  }

  void handleDeclarationOfVariable(
    Variable variable, {
    required CaptureKind captureKind,
  });

  List<VariableContext> computeCapturedVariableContexts(
    List<VariableBase> variables,
  ) {
    if (variables.isEmpty) {
      return [];
    }
    return {for (VariableBase variable in variables) variable.context}.toList();
  }

  ThisVariable get thisVariable {
    ThisVariable? result;
    for (VariableContext context in _ensureScopeWithThis().contexts) {
      if (context.variables.whereType<ThisVariable>().firstOrNull
          case var variable?) {
        result = variable;
        break;
      }
    }
    return result!;
  }

  Info createScopeProviderInfo({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  });

  /// Initiates closure context allocation as a part of type inference.
  ///
  /// [parameters] are those of the function being inferred.
  ScopeProviderInfo beginClosureContextAllocation(
    List<VariableWithCaptureKind<Variable>> parameters, {
    required VariableWithCaptureKind<ThisVariable>? thisVariable,
  }) {
    ScopeProviderInfo scopeProviderInfo = enterScopeProvider(
      scopeProviderInfoKind: thisVariable == null
          ? ScopeProviderInfoKind.FunctionNode
          : ScopeProviderInfoKind.FunctionNodeWithThis,
    );
    if (thisVariable != null) {
      scopeProviderInfo.thisVariable = thisVariable.variable;
      handleDeclarationOfVariable(
        thisVariable.variable,
        captureKind: thisVariable.captureKind,
      );
    }
    handleDeclarationsOfParameters(parameters);
    return scopeProviderInfo;
  }

  /// Finishes closure context allocation after inferring the function body.
  void endClosureContextAllocation(ScopeProviderInfo scopeProviderInfo) {
    exitScopeProvider(scopeProviderInfo);
  }

  void handleDeclarationsOfParameters(
    List<VariableWithCaptureKind<Variable>> parameters,
  ) {
    for (VariableWithCaptureKind<Variable> parameter in parameters) {
      handleDeclarationOfVariable(
        parameter.variable,
        captureKind: parameter.captureKind,
      );
    }
  }

  void handleAfterCaseHeads(
    List<VariableWithCaptureKind<VariableBase>> variables,
  ) {
    _patternScopeBuilder.handleAfterCaseHeads(
      _currentScopeProviderInfo!,
      variables,
    );
  }

  void handleSwitchCaseBeginning() {
    _patternScopeBuilder.handleSwitchCaseBeginning();
  }

  void handleInternalVariablePattern(
    VariableWithCaptureKind<VariableBase> variable,
  ) {
    _patternScopeBuilder.handleInternalVariablePattern(
      _currentScopeProviderInfo!,
      variable,
    );
  }

  void handleJoinedPatternVariable(
    VariableWithCaptureKind<VariableBase> variable,
    JoinedPatternVariableLocation location,
  ) {
    _patternScopeBuilder.handleJoinedPatternVariable(
      _currentScopeProviderInfo!,
      variable,
      location,
    );
  }

  void handleSwitchBeforeAlternative({
    required int caseIndex,
    required int subIndex,
  }) {
    _patternScopeBuilder.handleSwitchBeforeAlternative(
      caseIndex: caseIndex,
      subIndex: subIndex,
    );
  }
}

class TrivialContextAllocationStrategy
    extends ContextAllocationStrategy<ScopeProviderInfo> {
  @override
  void handleDeclarationOfVariable(
    Variable variable, {
    required CaptureKind captureKind,
  }) {
    assert(_currentScopeProviderInfo != null);
    _ensureVariableContextInCurrentScope(captureKind: captureKind)
        .addVariable(variable);
  }

  @override
  ScopeProviderInfo createScopeProviderInfo({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) => new ScopeProviderInfo(kind: scopeProviderInfoKind);
}

// Coverage-ignore(suite): Not run.
class CollectorScopeProviderInfo extends ScopeProviderInfo {
  /// Link to [CollectorScopeProviderInfo] that the current info object
  /// delegates collecting captured variables to.
  ///
  /// [capturedVariableCollector] points to the object itself if it itself
  /// collects its own (and its children's) captured variables. It is `null` in
  /// case the current scope doesn't contain captured variables yet.
  CollectorScopeProviderInfo? capturedVariableCollector;

  new({required super.kind});
}

// Coverage-ignore(suite): Not run.
class LoopDepthAllocationStrategy
    extends ContextAllocationStrategy<CollectorScopeProviderInfo> {
  @override
  CollectorScopeProviderInfo createScopeProviderInfo({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) => new CollectorScopeProviderInfo(kind: scopeProviderInfoKind);

  /// Predicate describing the stopping conditions for delegation to collector.
  ///
  /// Loops and functions serves as boundaries to propagating the delegation to
  /// collector.
  static bool _isStoppingDelegationToCollector(
    ScopeProviderInfoKind scopeProviderInfoKind,
  ) {
    switch (scopeProviderInfoKind) {
      case ScopeProviderInfoKind.Block:
      case ScopeProviderInfoKind.BlockExpression:
      case ScopeProviderInfoKind.Catch:
        return false;
      case ScopeProviderInfoKind.Loop:
      case ScopeProviderInfoKind.FunctionNode:
      case ScopeProviderInfoKind.FunctionNodeWithThis:
      case ScopeProviderInfoKind.InstanceField:
      case ScopeProviderInfoKind.StaticField:
        return true;
    }
  }

  @override
  CollectorScopeProviderInfo enterScopeProvider({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) {
    CollectorScopeProviderInfo? previousScopeProvider =
        _currentScopeProviderInfo;
    CollectorScopeProviderInfo currentScopeProvider = super.enterScopeProvider(
      scopeProviderInfoKind: scopeProviderInfoKind,
    );
    // If the delegation to collection shouldn't be stopped, inherit the
    // collector from the previous [CollectorScopeProviderInfo] object. In case
    // it was `null` (that is, it didn't hold any captured variables), the
    // current scope starts with `null` as well.
    if (!_isStoppingDelegationToCollector(scopeProviderInfoKind)) {
      currentScopeProvider.capturedVariableCollector =
          previousScopeProvider?.capturedVariableCollector;
    }
    return currentScopeProvider;
  }

  @override
  void handleDeclarationOfVariable(
    Variable variable, {
    required CaptureKind captureKind,
  }) {
    CollectorScopeProviderInfo currentScope = _currentScopeProviderInfo!;
    if (variable is ThisVariable) {
      currentScope.thisVariable = variable;
    }

    // Delegation happens when the current variable is not uncaptured (that is,
    // it's either captured or assert-captured), and there's a collector to
    // delegate to.
    bool delegateToCollector =
        captureKind != CaptureKind.notCaptured &&
        currentScope.capturedVariableCollector != null;
    if (delegateToCollector) {
      ContextAllocationStrategy._fetchVariableContextOfScope(
        scope: currentScope.capturedVariableCollector!.scope!,
        captureKind: captureKind,
      )!.addVariable(variable);
    } else {
      _ensureVariableContextInCurrentScope(captureKind: captureKind)
          .addVariable(variable);

      // In case it was the first not uncaptured variable (that is, either
      // captured or assert-captured) for the current scope, and it didn't have
      // a collector to delegate to due to the enclosing if-condition, it
      // becomes a collector of captured variables itself.
      bool becomesCollector =
          captureKind != CaptureKind.notCaptured &&
          currentScope.capturedVariableCollector == null;
      if (becomesCollector) {
        currentScope.capturedVariableCollector = currentScope;
      }
    }
  }
}

class EmptyContextAllocationStrategy
    implements ContextAllocationStrategy<ScopeProviderInfo> {
  static final ScopeProviderInfo _emptyScopeProviderInfo =
      new ScopeProviderInfo(kind: ScopeProviderInfoKind.Block);

  @override
  // Coverage-ignore(suite): Not run.
  ScopeProviderInfo createScopeProviderInfo({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) {
    return _emptyScopeProviderInfo;
  }

  @override
  ScopeProviderInfo enterScopeProvider({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) {
    return _emptyScopeProviderInfo;
  }

  @override
  void handleDeclarationOfVariable(
    Variable variable, {
    required CaptureKind captureKind,
  }) {}

  @override
  StringBuffer? get _debugLog {
    throw new UnsupportedError("EmptyContextAllocationStrategy._debugLog");
  }

  @override
  void set _debugLog(StringBuffer? value) {
    throw new UnsupportedError("EmptyContextAllocationStrategy._debugLog=");
  }

  @override
  bool get _enableDebugLogging {
    throw new UnsupportedError(
      "EmptyContextAllocationStrategy._enableDebugLogging",
    );
  }

  @override
  PatternScopeListener<ScopeProviderInfo> get _patternScopeBuilder {
    throw new UnsupportedError(
      "EmptyContextAllocationStrategy._patternScopeBuilder",
    );
  }

  @override
  ScopeProviderInfo? get _currentScopeProviderInfo {
    throw new UnsupportedError(
      "EmptyContextAllocationStrategy._currentScopeProviderInfo",
    );
  }

  @override
  Scope _ensureScopeWithThis() {
    throw new UnsupportedError(
      "EmptyContextAllocationStrategy._ensureScopeWithThis",
    );
  }

  @override
  VariableContext _ensureVariableContextInCurrentScope({
    required CaptureKind captureKind,
  }) {
    throw new UnsupportedError(
      "EmptyContextAllocationStrategy._ensureVariableContextInCurrentScope",
    );
  }

  @override
  String _readDebugLog() {
    throw new UnsupportedError("EmptyContextAllocationStrategy._readDebugLog");
  }

  @override
  ScopeProviderInfoStack<ScopeProviderInfo> get _scopeProviderInfoStack {
    throw new UnsupportedError(
      "EmptyContextAllocationStrategy._scopeProviderInfoStack",
    );
  }

  @override
  void _writeDebugLine(String line) {
    throw new UnsupportedError(
      "EmptyContextAllocationStrategy._writeDebugLine",
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  ScopeProviderInfo beginClosureContextAllocation(
    List<VariableWithCaptureKind<Variable>> parameters, {
    required VariableWithCaptureKind<ThisVariable>? thisVariable,
  }) {
    return _emptyScopeProviderInfo;
  }

  @override
  List<VariableContext> computeCapturedVariableContexts(
    List<VariableBase> variables,
  ) {
    return const [];
  }

  @override
  // Coverage-ignore(suite): Not run.
  void endClosureContextAllocation(ScopeProviderInfo scopeProviderInfo) {}

  @override
  void exitScopeProvider(ScopeProviderInfo scopeProviderInfo) {}

  @override
  void handleAfterCaseHeads(
    List<VariableWithCaptureKind<VariableBase>> variables,
  ) {}

  @override
  void handleDeclarationsOfParameters(
    List<VariableWithCaptureKind<Variable>> parameters,
  ) {}

  @override
  void handleInternalVariablePattern(
    VariableWithCaptureKind<VariableBase> variable,
  ) {}

  @override
  void handleJoinedPatternVariable(
    VariableWithCaptureKind<VariableBase> variable,
    JoinedPatternVariableLocation location,
  ) {}

  @override
  void handleSwitchBeforeAlternative({
    required int caseIndex,
    required int subIndex,
  }) {}

  @override
  void handleSwitchCaseBeginning() {}

  @override
  ThisVariable get thisVariable {
    throw new UnsupportedError("EmptyContextAllocationStrategy.thisVariable");
  }
}

/// A variable paired together with its [CaptureKind].
class VariableWithCaptureKind<Variable extends VariableBase>(
  var Variable variable,
  var CaptureKind captureKind,
) {
  @override
  String toString() {
    return "VariableWithCaptureKind(variable=${variable}, "
        "captureKind=${captureKind})";
  }
}

/// The root of the hierarchy of events to build scopes and allocate variables.
sealed class PatternScopeBuilderEvent<Info extends ScopeProviderInfo> {
  void allocateVariables();

  void _allocateVariableInScopeProviderInfo(
    ScopeProviderInfo info,
    VariableWithCaptureKind variable,
  ) {
    // TODO(cstefantsova): Should this be delegated to
    //  [ContextAllocationStrategy].
    ContextAllocationStrategy.ensureVariableContextInScopeProviderInfo(
      info: info,
      captureKind: variable.captureKind,
    ).addVariable(variable.variable);
  }
}

/// The event of reaching the end of all heads of a switch case.
class AfterCaseHeadsEvent<Info extends ScopeProviderInfo>
    extends PatternScopeBuilderEvent<Info> {
  final ScopeProviderInfo info;
  final List<VariableWithCaptureKind<VariableBase>> variables;

  new(this.info, this.variables);

  @override
  void allocateVariables() {
    for (VariableWithCaptureKind variable in variables) {
      _allocateVariableInScopeProviderInfo(info, variable);
    }
  }

  @override
  String toString() {
    return "AfterCaseHeadsEvent(info=${info}, variables=${variables})";
  }
}

/// The event of an [InternalVariablePattern] occurring.
class InternalVariablePatternEvent<Info extends ScopeProviderInfo>
    extends PatternScopeBuilderEvent<Info> {
  final ScopeProviderInfo info;
  final VariableWithCaptureKind<VariableBase> variable;

  new(this.info, this.variable);

  @override
  void allocateVariables() {
    _allocateVariableInScopeProviderInfo(info, variable);
  }

  @override
  String toString() {
    return "InternalVariablePatternEvent(info=${info}, variable=${variable})";
  }
}

/// The event of a joined pattern variable being created.
class JoinedPatternVariableEvent<Info extends ScopeProviderInfo>
    extends PatternScopeBuilderEvent<Info> {
  final ScopeProviderInfo info;
  final VariableWithCaptureKind<VariableBase> variable;
  final JoinedPatternVariableLocation location;

  new(this.info, this.variable, this.location);

  @override
  void allocateVariables() {
    _allocateVariableInScopeProviderInfo(info, variable);
  }

  @override
  String toString() {
    return "JoinedPatternVariableEvent(info=${info}, variable=${variable}, "
        "location=${location})";
  }
}

/// The builder for a single case head within a pattern switch case.
class PatternSwitchCaseHeadScopeBuilder<Info extends ScopeProviderInfo> {
  List<PatternScopeBuilderEvent<Info>> _events = [];
  JoinedPatternVariableEvent<Info>? _joinedPatternVariableEvent;

  /// Handle a variable pattern event as a part of the head's pattern.
  void handleInternalVariablePatternEvent(
    InternalVariablePatternEvent<Info> event,
  ) {
    _events.add(event);
  }

  /// Handle a joint variable in the case head.
  ///
  /// A joint variable appears when there is or-pattern, and each of the
  /// alternatives declares an identical variable.
  void handleJoinedPatternVariableEvent(
    JoinedPatternVariableEvent<Info> event,
  ) {
    _joinedPatternVariableEvent = event;
  }

  /// Allocates the variables of the case head in the current context.
  ///
  /// If the head has a joint variable, that is, if the pattern in the head
  /// contains or-pattern, where each of the alternatives declares the joint
  /// variable, only the joint variable is allocated. Otherwise, all of the
  /// variables in the pattern are allocated.
  void allocateVariables() {
    if (_joinedPatternVariableEvent case var joinedPatternVariableEvent?) {
      joinedPatternVariableEvent.allocateVariables();
    } else {
      for (PatternScopeBuilderEvent<Info> event in _events) {
        event.allocateVariables();
      }
    }
  }
}

/// The builder for a pattern switch case.
class PatternSwitchCaseScopeBuilder<Info extends ScopeProviderInfo> {
  List<PatternSwitchCaseHeadScopeBuilder<Info>> _headBuilders = [];

  PatternSwitchCaseHeadScopeBuilder<Info> get _currentHeadBuilder {
    return _headBuilders.last;
  }

  /// Handle the end of all case heads.
  ///
  /// This is supposed to be the last event handled by the
  /// [PatternSwitchCaseScopeBuilder].
  void handleAfterCaseHeads(
    Info info,
    List<VariableWithCaptureKind<VariableBase>> variables,
  ) {
    for (PatternSwitchCaseHeadScopeBuilder<Info> headBuilder in _headBuilders) {
      headBuilder.allocateVariables();
    }
    _headBuilders.clear();

    PatternScopeBuilderEvent<Info> event = new AfterCaseHeadsEvent<Info>(
      info,
      variables,
    );

    event.allocateVariables();
  }

  /// Handle a variable pattern event as a part of the head's pattern.
  void handleInternalVariablePatternEvent(
    InternalVariablePatternEvent<Info> event,
  ) {
    _currentHeadBuilder.handleInternalVariablePatternEvent(event);
  }

  /// Handle a joined pattern variable.
  ///
  /// This event is emitted either at the end of a head containing an
  /// or-pattern with a joint variable or at the end of all heads, all of which
  /// contain a reference to the joint variable. [location] is the
  /// differentiator between the cases.
  void handleJoinedPatternVariable(
    Info info,
    VariableWithCaptureKind<VariableBase> variable,
    JoinedPatternVariableLocation location,
  ) {
    JoinedPatternVariableEvent<Info> event = new JoinedPatternVariableEvent(
      info,
      variable,
      location,
    );

    switch (location) {
      case JoinedPatternVariableLocation.singlePattern:
        // This is the case for the joint variable of a single pattern of a
        // case head. Let the head builder handle it.
        _currentHeadBuilder.handleJoinedPatternVariableEvent(event);
      case JoinedPatternVariableLocation.sharedCaseScope:
      // This is the case of a joint variable among all of the case heads. It
      // also means that the end of the case heads is reached. Do nothing,
      // since [handleAfterCaseHeads] handles the joint variables too.
    }
  }

  /// Handle a new switch case head.
  void handleSwitchBeforeAlternative({
    required int caseIndex,
    required int subIndex,
  }) {
    _headBuilders.add(new PatternSwitchCaseHeadScopeBuilder<Info>());
  }
}

/// The builder for a variable pattern.
class InternalVariablePatternScopeBuilder<Info extends ScopeProviderInfo> {
  PatternSwitchCaseScopeBuilder<Info>? patternSwitchCaseScopeBuilder;

  new(this.patternSwitchCaseScopeBuilder);

  /// Handle the internal variable pattern depending on the context.
  ///
  /// In case [patternSwitchCaseScopeBuilder] is null, the internal variable
  /// pattern stands on its own, and its variable should be allocated in the
  /// current scope. Otherwise, let the enclosing pattern handle it.
  void handleInternalVariablePattern(
    Info info,
    VariableWithCaptureKind<VariableBase> variable,
  ) {
    InternalVariablePatternEvent<Info> event =
        new InternalVariablePatternEvent<Info>(info, variable);

    if (patternSwitchCaseScopeBuilder case var patternSwitchCaseScopeBuilder?) {
      patternSwitchCaseScopeBuilder.handleInternalVariablePatternEvent(event);
    } else {
      event.allocateVariables();
    }
  }
}

/// Listens to events and builds scopes and allocates variables.
///
/// This is a listener object that manages the scope builder objects.
class PatternScopeListener<Info extends ScopeProviderInfo> {
  PatternSwitchCaseScopeBuilder<Info>? patternSwitchCaseScopeBuilder;

  /// The event of the beginning of a switch case.
  void handleSwitchCaseBeginning() {
    patternSwitchCaseScopeBuilder = new PatternSwitchCaseScopeBuilder<Info>();
  }

  /// The event of reaching the end of all heads of a switch case.
  void handleAfterCaseHeads(
    Info info,
    List<VariableWithCaptureKind<VariableBase>> variables,
  ) {
    patternSwitchCaseScopeBuilder!.handleAfterCaseHeads(info, variables);
    patternSwitchCaseScopeBuilder = null;
  }

  /// The event of an [InternalVariablePattern] occurring.
  void handleInternalVariablePattern(
    Info info,
    VariableWithCaptureKind<VariableBase> variable,
  ) {
    new InternalVariablePatternScopeBuilder<Info>(patternSwitchCaseScopeBuilder)
        .handleInternalVariablePattern(info, variable);
  }

  /// The event of a joined pattern variable being created.
  void handleJoinedPatternVariable(
    Info info,
    VariableWithCaptureKind<VariableBase> variable,
    JoinedPatternVariableLocation location,
  ) {
    patternSwitchCaseScopeBuilder!.handleJoinedPatternVariable(
      info,
      variable,
      location,
    );
  }

  /// The event of a new case head beginning.
  void handleSwitchBeforeAlternative({
    required int caseIndex,
    required int subIndex,
  }) {
    patternSwitchCaseScopeBuilder!.handleSwitchBeforeAlternative(
      caseIndex: caseIndex,
      subIndex: subIndex,
    );
  }
}
