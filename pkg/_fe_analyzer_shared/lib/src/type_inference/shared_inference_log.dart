// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../types/shared_type.dart';
import 'type_constraint.dart';

/// Maximum length for strings returned by [describe].
const int _descriptionLengthThreshold = 80;

/// Maximum number of events stored in the inference log at each nesting level
/// while not dumping output.
///
/// If more events than this occur at any given nesting level, older events will
/// be discarded and replaced with [_truncationEvent], to avoid the inference
/// log using up too much memory.
const int _eventTruncationThreshold = 4;

/// Expando storing a value `true` for each expression that has been passed to
/// the `oldExpression` argument of
/// [SharedInferenceLogWriterImpl.recordExpressionRewrite].
///
/// This is used as a check to make sure that
/// [SharedInferenceLogWriterImpl.recordExpressionRewrite] isn't called more
/// than once for any given `oldExpression`.
final _rewrittenExpressions = new Expando<bool>();

/// When more than [_eventTruncationThreshold] events occur at any given nesting
/// level, this event is used as a placeholder to take the place of any
/// discarded events.
final Event _truncationEvent = new Event(message: '...');

/// Converts [o] to a string in a way that:
/// - Shows the runtime type,
/// - Is tolerant of exceptions, and
/// - Limits the length of the result.
String describe(Object? o) {
  String s;
  try {
    s = o.toString().replaceAll('\n', ' ');
    if (s.length > _descriptionLengthThreshold) {
      s = s.substring(0, _descriptionLengthThreshold - 3) + '...';
    }
  } catch (e) {
    s = '<$e>';
  }
  return '${o.runtimeType}: $s';
}

/// Enumeration of the possible sources of constraints that might occur during
/// generic type inference.
enum ConstraintGenerationSource {
  /// The source of the constraint is the static type of an argument to the
  /// method whose type is being inferred, being matched against the
  /// corresponding parameter in the method's function type.
  argument(description: 'ARGUMENT'),

  /// The source of the constraint is the analyzer's
  /// `GenericInferrer.constrainGenericFunctionInContext` method.
  genericFunctionInContext(description: 'GENERIC FUNCTION IN CONTEXT'),

  /// The source of the constraint is the context of the invocation whose
  /// type is being inferred, being matched against the return type in function
  /// or method being invoked.
  returnType(description: 'RETURN TYPE');

  /// A text description of this constraint generation source, suitable for
  /// including in log messages.
  final String description;

  const ConstraintGenerationSource({required this.description});

  @override
  String toString() => description;
}

/// Representation of a single event in the inference log, with pointers to any
/// events that are nested beneath it.
class Event {
  /// Message display string.
  final String message;

  /// List of nested events.
  List<Event>? subEvents;

  Event({required this.message});
}

/// Specialization of [State] used when type inferring an expression.
class ExpressionState extends State {
  /// Whether [SharedInferenceLogWriterImpl.recordStaticType] or
  /// [SharedInferenceLogWriterImpl.recordExpressionWithNoType] has been called
  /// for the expression represented by this [State] object.
  ///
  /// The inference log infrastructure uses this boolean to verify that each
  /// expression that undergoes type inference either receives a static type, or
  /// is determined by analysis to not need a static type.
  bool typeRecorded = false;

  ExpressionState({
    required super.writer,
    required super.message,
    required super.nodeSet,
  }) : super(kind: StateKind.expression);
}

/// Specialization of [State] used when generic type inference is being
/// performed.
class GenericInferenceState<TypeParameter extends Object> extends State {
  /// The formal type parameters whose types are being inferred.
  final List<TypeParameter> typeFormals;

  GenericInferenceState({
    required super.writer,
    required super.message,
    required State parent,
    required this.typeFormals,
  }) : super(kind: StateKind.genericInference, nodeSet: parent.nodeSet);
}

/// Public API to the interface log writer.
///
/// This class defines methods that the analyzer or CFE can use to instrument
/// their type inference logic. The implementations are found in
/// [SharedInferenceLogWriterImpl].
abstract interface class SharedInferenceLogWriter {
  /// If [inProgress] is `true`, verifies that generic type inference is in
  /// progress; otherwise, verifies that generic type inference is not in
  /// progress.
  ///
  /// This method is used by the analyzer to validate certain assumptions about
  /// the state of type inference, for example:
  ///
  /// - That in methods that are passed a nullable reference to
  ///   `GenericInferrer`, a non-null value is passed in if and only if generic
  ///   type inference is in progress.
  ///
  /// - That when the user supplies explicit type arguments, generic type
  ///   inference does not take place.
  void assertGenericInferenceState({required bool inProgress});

  /// Verifies that every call to an `enter...` method has been matched by a
  /// corresponding call to an `exit...` method.
  void assertIdle();

  /// Called when type inference begins inferring an annotation.
  void enterAnnotation(Object node);

  /// Called when generic type inference starts collecting constraints by
  /// attempting to match one type schema against another.
  void enterConstraintGeneration(
    ConstraintGenerationSource source,
    covariant SharedType p,
    covariant SharedType q,
  );

  /// Called when type inference begins inferring a collection element.
  void enterElement(Object node);

  /// Called when type inference begins inferring an expression.
  void enterExpression(Object node, covariant SharedType contextType);

  /// Called when type inference begins inferring an AST node associated with
  /// extension override syntax.
  void enterExtensionOverride(Object node, covariant SharedType contextType);

  /// Called when type inference has discovered that a construct that uses
  /// method invocation syntax (e.g. `x.f()`) is actually an invocation of a
  /// getter.
  ///
  /// [node] is the AST node for the rewritten getter (e.g. `x.f`).
  void enterFunctionExpressionInvocationTarget(Object node);

  /// Called when generic type inference begins.
  void enterGenericInference(
    List<SharedTypeParameter> typeFormals,
    covariant SharedType template,
  );

  /// Called when type inference begins inferring the left hand side of an
  /// assignment.
  void enterLValue(Object node);

  /// Called when type inference begins inferring a pattern.
  void enterPattern(Object node);

  /// Called when type inference begins inferring a statement.
  void enterStatement(Object node);

  /// Called when type inference has finished inferring an expression.
  void exitAnnotation(Object node);

  /// Called when type inference has finished collecting a set of constraints.
  void exitConstraintGeneration();

  /// Called when type inference has finished inferring a collection element.
  void exitElement(Object node);

  /// Called when type inference has finished inferring an expression.
  void exitExpression(Object node);

  /// Called when type inference has finished inferring an AST node associated
  /// with extension override syntax.
  void exitExtensionOverride(Object node);

  /// Called when generic type inference ends.
  void exitGenericInference({
    bool aborted = false,
    bool failed = false,
    covariant List<SharedType>? finalTypes,
  });

  /// Called when type inference has finished inferring the left hand side of an
  /// assignment.
  ///
  /// [reanalyzeAsRValue] should be `true` if type inference will follow up by
  /// re-analyzing the same expression as though it's an R-value rather than an
  /// L-value. (This happens in the analyzer when the LHS of an assignment
  /// isn't a valid assignable expression).
  void exitLValue(Object node, {bool reanalyzeAsRValue = false});

  /// Called when type inference has finished inferring a pattern.
  void exitPattern(Object node);

  /// Called when type inference has finished inferring a statement.
  void exitStatement(Object node);

  /// Called when type inference rewrites one expression into another.
  ///
  /// [newExpression] is the new expression that is being created. It must
  /// always be supplied.
  ///
  /// [oldExpression] is the old expression that is being replaced. It is
  /// optional; if it is supplied, then the inference log infrastructure will
  /// double check that it's only recorded once in the log.
  void recordExpressionRewrite({
    Object? oldExpression,
    required Object newExpression,
  });

  /// Called when type inference is inferring an expression, and discovers that
  /// the expression should not have any type.
  void recordExpressionWithNoType(Object expression);

  /// Records a constraint that was generated during the process of matching one
  /// type schema to another.
  void recordGeneratedConstraint(
    SharedTypeParameter parameter,
    MergedTypeConstraint<Object, SharedType, Object, Object> constraint,
  );

  /// Records that type inference has resolved a method name.
  void recordLookupResult({
    required Object expression,
    required SharedType type,
    required Object? target,
    required String methodName,
  });

  /// Called when null shorting terminates, and so the type of an expression is
  /// made nullable.
  ///
  /// [expression] is the expression whose type is changed, and [type] is the
  /// type it is changed to.
  void recordNullShortedType(Object expression, SharedType type);

  /// Records the preliminary types chosen during either a downwards or a
  /// horizontal inference step.
  void recordPreliminaryTypes(List<SharedType> types);

  /// Called when type inference is inferring an expression, and assigns the
  /// expression a static type.
  void recordStaticType(Object expression, SharedType type);
}

/// Implementation of the interface log writer.
///
/// This class provides the implementation of [SharedInferenceLogWriter], along
/// with additional helper methods.
///
/// The helper methods are public so that the analyzer and CFE can call them
/// from classes derived from [SharedInferenceLogWriterImpl], but these methods
/// are not exposed in [SharedInferenceLogWriter] so that they won't be called
/// accidentally on their own.
abstract class SharedInferenceLogWriterImpl
    implements SharedInferenceLogWriter {
  /// A stack of [State] objects representing the calls that have been made to
  /// `enter...` methods without any matched `exit...` method.
  ///
  /// The first entry in [_stateStack] is always [_topState].
  final _stateStack = <State>[];

  /// The topmost [State] object, which recursively contains all the other
  /// [Event]s.
  final State _topState = new State._top();

  /// True if [dump] has been called, and therefore every call to [addEvent]
  /// should result in the event being immediately printed.
  bool _dumping = false;

  SharedInferenceLogWriterImpl() {
    _stateStack.add(_topState);
  }

  /// Gets the current state, which is the last entry in [_stateStack].
  State get state => _stateStack.last;

  /// Records an event by adding it to the innermost state in the [_stateStack].
  ///
  /// If [_dumping] is `true`, then the event's message is immediately printed,
  /// with appropriate indentation.
  void addEvent(Event event) {
    List<Event> subEvents = (state.subEvents ??= [])..add(event);
    if (_dumping) {
      print(' ' * _stateStack.length + event.message);
    } else if (subEvents.length > _eventTruncationThreshold) {
      subEvents.removeRange(
        0,
        subEvents.length - _eventTruncationThreshold - 1,
      );
      subEvents[0] = _truncationEvent;
    }
  }

  @override
  void assertGenericInferenceState({required bool inProgress}) {
    bool actualInProgress = state.kind == StateKind.genericInference;
    if (inProgress != actualInProgress) {
      fail(
        'Expected generic inference inProgress=$inProgress, '
        'actual=$actualInProgress',
      );
    }
  }

  @override
  void assertIdle() {
    if (state.kind != StateKind.top) {
      fail('Node not exited: $state');
    }
  }

  /// Performs checks on [state], and calls [fail] if those checks fail.
  ///
  /// If [expectedNode] is not `null`, then [state] is checked to see if its
  /// [State.nodeSet] contains [expectedNode].
  ///
  /// If [expectedKind] is not `null`, then [state] is checked to see if its
  /// [State.kind] matches [expectedKind].
  ///
  /// If a check fails, then [method], [arguments], and [namedArguments] are
  /// used to describe the circumstances of the failure.
  void checkCall({
    required String method,
    List<Object?> arguments = const [],
    Map<String, Object?> namedArguments = const {},
    Object? expectedNode,
    StateKind? expectedKind,
  }) {
    String describeMethod() {
      List<String> formattedArguments = [
        for (Object? argument in arguments) describe(argument),
        for (var MapEntry(:key, :value) in namedArguments.entries)
          '$key: ${describe(value)}',
      ];
      return '$method(${formattedArguments.join(', ')})';
    }

    if (expectedNode != null &&
        !state.nodeSet.any((node) => identical(node, expectedNode))) {
      List<String> nodeSetDescriptions = [
        for (Object? node in state.nodeSet) describe(node),
      ];
      String nodeSetDescription = nodeSetDescriptions.length == 1
          ? nodeSetDescriptions[0]
          : nodeSetDescriptions.join(', ');
      fail(
        '${describeMethod()}: expected containing node to be '
        '${describe(expectedNode)}, actual is $nodeSetDescription',
      );
    }

    if (expectedKind != null) {
      if (state.kind != expectedKind) {
        fail('${describeMethod()}: invalid in state $state');
      }
    }
  }

  /// Begins dumping the inference log to standard output, if dumping hasn't
  /// been begun already.
  ///
  /// Dumping continues for the remainder of the lifetime of `this`.
  void dump() {
    if (_dumping) return;
    _dumping = true;

    void dumpEvent(String indent, Event event) {
      print('$indent${event.message}');
      List<Event>? subEvents = event.subEvents;
      if (subEvents != null) {
        String subIndent = '$indent ';
        for (Event subEvent in subEvents) {
          dumpEvent(subIndent, subEvent);
        }
      }
    }

    dumpEvent('', _topState);
  }

  @override
  void enterAnnotation(Object node) {
    pushState(
      new State(
        kind: StateKind.annotation,
        writer: this,
        message: 'INFER ANNOTATION ${describe(node)}',
        nodeSet: [node],
      ),
    );
  }

  @override
  void enterConstraintGeneration(
    ConstraintGenerationSource source,
    SharedType p,
    SharedType q,
  ) {
    checkCall(
      method: 'enterConstraintGeneration',
      arguments: [source, p, q],
      expectedKind: StateKind.genericInference,
    );
    pushState(
      new State(
        kind: StateKind.constraintGeneration,
        writer: this,
        message: 'GENERATE CONSTRAINTS FOR $source: $p <# $q',
        nodeSet: state.nodeSet,
      ),
    );
  }

  @override
  void enterElement(Object node) {
    pushState(
      new State(
        kind: StateKind.collectionElement,
        writer: this,
        message: 'INFER ELEMENT ${describe(node)}',
        nodeSet: [node],
      ),
    );
  }

  @override
  void enterExpression(Object node, SharedType contextType) {
    pushState(
      new ExpressionState(
        writer: this,
        message: 'INFER EXPRESSION ${describe(node)} IN CONTEXT $contextType',
        nodeSet: [node],
      ),
    );
  }

  @override
  void enterExtensionOverride(Object node, SharedType contextType) {
    pushState(
      new State(
        kind: StateKind.extensionOverride,
        writer: this,
        message:
            'INFER EXTENSION OVERRIDE ${describe(node)} IN CONTEXT '
            '$contextType',
        nodeSet: [node],
      ),
    );
  }

  @override
  void enterFunctionExpressionInvocationTarget(Object node) {
    pushState(
      new ExpressionState(
        writer: this,
        message: 'REINTERPRET METHOD NAME ${describe(node)} AS AN EXPRESSION',
        nodeSet: [node],
      ),
    );
  }

  @override
  void enterGenericInference(
    List<SharedTypeParameter> typeFormals,
    SharedType template,
  ) {
    if (state.kind == StateKind.genericInference) {
      fail('Tried to start generic inference when already in progress');
    }
    String typeFormalNames = [
      for (SharedTypeParameter typeFormal in typeFormals)
        typeFormal.displayName,
    ].join(', ');
    pushState(
      new GenericInferenceState(
        writer: this,
        message: 'FIND $typeFormalNames IN $template',
        parent: state,
        typeFormals: typeFormals,
      ),
    );
  }

  @override
  void enterLValue(Object node) {
    pushState(
      new State(
        kind: StateKind.lValue,
        writer: this,
        message: 'INFER LVALUE ${describe(node)}',
        nodeSet: [node],
      ),
    );
  }

  @override
  void enterPattern(Object node) {
    pushState(
      new State(
        kind: StateKind.pattern,
        writer: this,
        message: 'INFER PATTERN ${describe(node)}',
        nodeSet: [node],
      ),
    );
  }

  @override
  void enterStatement(Object node) {
    pushState(
      new State(
        kind: StateKind.statement,
        writer: this,
        message: 'INFER STATEMENT ${describe(node)}',
        nodeSet: [node],
      ),
    );
  }

  @override
  void exitAnnotation(Object node) {
    checkCall(
      method: 'exitAnnotation',
      arguments: [node],
      expectedNode: node,
      expectedKind: StateKind.annotation,
    );
    popState();
  }

  @override
  void exitConstraintGeneration() {
    checkCall(
      method: 'exitConstraintGeneration',
      expectedKind: StateKind.constraintGeneration,
    );
    popState();
  }

  @override
  void exitElement(Object node) {
    checkCall(
      method: 'exitElement',
      arguments: [node],
      expectedNode: node,
      expectedKind: StateKind.collectionElement,
    );
    popState();
  }

  @override
  void exitExpression(Object node) {
    checkCall(
      method: 'exitExpression',
      arguments: [node],
      expectedNode: node,
      expectedKind: StateKind.expression,
    );
    bool typeRecorded = (state as ExpressionState).typeRecorded;
    if (!typeRecorded) {
      fail('Failed to record a type for $state');
    }
    popState();
  }

  @override
  void exitExtensionOverride(Object node) {
    checkCall(
      method: 'exitExtensionOverride',
      arguments: [node],
      expectedNode: node,
      expectedKind: StateKind.extensionOverride,
    );
    popState();
  }

  @override
  void exitGenericInference({
    bool aborted = false,
    bool failed = false,
    List<SharedType>? finalTypes,
  }) {
    if ((aborted ? 1 : 0) + (failed ? 1 : 0) + (finalTypes != null ? 1 : 0) !=
        1) {
      fail(
        'Must specify exactly one of aborted=true, failed=true, '
        'finalTypes=non-null',
      );
    }
    checkCall(
      method: 'exitGenericInference',
      namedArguments: {
        if (aborted) 'aborted': aborted,
        if (failed) 'failed': failed,
        if (finalTypes != null) 'finalTypes': finalTypes,
      },
      expectedKind: StateKind.genericInference,
    );
    if (aborted) {
      addEvent(new Event(message: 'GENERIC INFERENCE ABORTED'));
    } else if (failed) {
      addEvent(new Event(message: 'GENERIC INFERENCE FAILED'));
    } else if (finalTypes != null) {
      List<Object> typeFormals = (state as GenericInferenceState).typeFormals;
      List<String> typeAssignments = [
        for (int i = 0; i < finalTypes.length; i++)
          '${typeFormals[i]}=${finalTypes[i]}',
      ];
      addEvent(
        new Event(message: 'FINAL GENERIC TYPES ${typeAssignments.join(', ')}'),
      );
    }
    popState();
  }

  @override
  void exitLValue(Object node, {bool reanalyzeAsRValue = false}) {
    checkCall(
      method: 'exitLValue',
      arguments: [node],
      namedArguments: {
        if (reanalyzeAsRValue) 'reanalyzeAsRValue': reanalyzeAsRValue,
      },
      expectedNode: node,
      expectedKind: StateKind.lValue,
    );
    if (reanalyzeAsRValue) {
      addEvent(new Event(message: 'WILL REANALYZE AS RVALUE'));
    }
    popState();
  }

  @override
  void exitPattern(Object node) {
    checkCall(
      method: 'exitPattern',
      arguments: [node],
      expectedNode: node,
      expectedKind: StateKind.pattern,
    );
    popState();
  }

  @override
  void exitStatement(Object node) {
    checkCall(
      method: 'exitStatement',
      arguments: [node],
      expectedNode: node,
      expectedKind: StateKind.statement,
    );
    popState();
  }

  /// Called when a check performed by the inference logging mechanism fails.
  ///
  /// The contents of the inference log are dumped to standard output, including
  /// an event showing the failure [message], and then an exception is thrown.
  Never fail(String message) {
    dump();
    addEvent(new Event(message: 'FAILURE: $message'));
    throw new StateError(message);
  }

  /// Pops the most recently pushed [State] from [_stateStack].
  void popState() {
    if (_stateStack.length == 1) {
      fail('Tried to pop top state');
    }
    _stateStack.removeLast();
  }

  /// Pushes [state] onto the [_stateStack].
  void pushState(State state) {
    if (state.kind == StateKind.top) {
      fail('Tried to push top state');
    }
    _stateStack.add(state);
  }

  @override
  void recordExpressionRewrite({
    Object? oldExpression,
    required Object newExpression,
  }) {
    checkCall(
      method: 'recordExpressionRewrite',
      arguments: [oldExpression, newExpression],
      expectedNode: oldExpression,
      expectedKind: StateKind.expression,
    );
    addEvent(
      new Event(
        message:
            'REWRITE ${describe(oldExpression)} TO '
            '${describe(newExpression)}',
      ),
    );
    (state as ExpressionState).nodeSet.add(newExpression);
    if (oldExpression != null) {
      if (_rewrittenExpressions[oldExpression] ?? false) {
        fail('Expression already rewritten: ${describe(oldExpression)}');
      }
      _rewrittenExpressions[oldExpression] = true;
    }
  }

  @override
  void recordExpressionWithNoType(Object expression) {
    checkCall(
      method: 'recordExpressionWithNoType',
      arguments: [expression],
      expectedNode: expression,
      expectedKind: StateKind.expression,
    );
    addEvent(
      new Event(message: 'EXPRESSION ${describe(expression)} HAS NO TYPE'),
    );
    ExpressionState state = this.state as ExpressionState;
    if (state.typeRecorded) {
      fail('A type (or lack thereof) was already recorded for this expression');
    }
    state.typeRecorded = true;
  }

  @override
  void recordGeneratedConstraint(
    SharedTypeParameter parameter,
    MergedTypeConstraint<Object, SharedType, Object, Object> constraint,
  ) {
    checkCall(
      method: 'recordGeneratedConstraint',
      arguments: [parameter, constraint],
      expectedKind: StateKind.constraintGeneration,
    );
    String constraintText = constraint.toString().replaceAll(
      '<type>',
      parameter.toString(),
    );
    addEvent(new Event(message: 'ADDED CONSTRAINT $constraintText'));
  }

  @override
  void recordLookupResult({
    required Object expression,
    required SharedType type,
    required Object? target,
    required String methodName,
  }) {
    checkCall(
      method: 'recordLookupResult',
      namedArguments: {
        'expression': expression,
        'type': type,
        'target': target,
        'methodName': methodName,
      },
      expectedNode: expression,
      expectedKind: StateKind.expression,
    );
    String query = target != null
        ? '${describe(target)}.$methodName'
        : methodName;
    addEvent(new Event(message: 'LOOKUP $query FINDS $type'));
  }

  @override
  void recordNullShortedType(Object expression, SharedType type) {
    addEvent(
      new Event(
        message:
            'STATIC TYPE OF ${describe(expression)} REFINED BY NULL SHORTING '
            'TO $type',
      ),
    );
  }

  @override
  void recordPreliminaryTypes(List<SharedType> types) {
    checkCall(
      method: 'recordPreliminaryTypes',
      arguments: [types],
      expectedKind: StateKind.genericInference,
    );
    List<Object> typeFormals = (state as GenericInferenceState).typeFormals;
    List<String> typeAssignments = [
      for (int i = 0; i < types.length; i++) '${typeFormals[i]}=${types[i]}',
    ];
    addEvent(
      new Event(
        message: 'PRELIMINARY GENERIC TYPES ${typeAssignments.join(', ')}',
      ),
    );
  }

  @override
  void recordStaticType(Object expression, SharedType type) {
    checkCall(
      method: 'recordStaticType',
      arguments: [expression, type],
      expectedNode: expression,
      expectedKind: StateKind.expression,
    );
    addEvent(
      new Event(message: 'STATIC TYPE OF ${describe(expression)} IS $type'),
    );
    ExpressionState state = this.state as ExpressionState;
    if (state.typeRecorded) {
      fail('A type (or lack thereof) was already recorded for this expression');
    }
    state.typeRecorded = true;
  }
}

/// Specialization of [Event] representing an event that might be associated
/// with one or more AST nodes.
class State extends Event {
  /// The kind of state object.
  ///
  /// This allows [SharedInferenceLogWriterImpl.checkCall] to quickly check that
  /// certain operations are only performed when expected (e.g. a type should
  /// only be recorded when performing type inference on an expression).
  final StateKind kind;

  /// A list of all the AST nodes for which this state is valid.
  ///
  /// Typically this list will have a single value (the node that was passed to
  /// the corresponding `enter...` method). But if a node is rewritten,
  /// additional values will be added to the list. This makes it possible for
  /// `exit...` calls to verify that they match the appropriate corresponding
  /// `enter...` calls, while being tolerant of rewrites.
  final List<Object?> nodeSet;

  /// Creates a new state object and adds it to the log via [writer].
  State({
    required this.kind,
    required SharedInferenceLogWriterImpl writer,
    required super.message,
    required this.nodeSet,
  }) : assert(kind != StateKind.top) {
    writer.addEvent(this);
  }

  /// Creates a new state object representing the outermost nesting level of the
  /// inference log.
  State._top() : kind = StateKind.top, nodeSet = [null], super(message: 'TOP');

  @override
  String toString() => '$runtimeType(${describe(nodeSet.first)})';
}

/// Possible values of [State.kind].
enum StateKind {
  annotation,
  collectionElement,
  constraintGeneration,
  expression,
  extensionOverride,
  genericInference,
  lValue,
  pattern,
  statement,
  top,
}
