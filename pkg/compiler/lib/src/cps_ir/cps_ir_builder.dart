// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder;

import '../common/names.dart' show
    Names,
    Selectors;
import '../compile_time_constants.dart' show
    BackendConstantEnvironment;
import '../constants/constant_system.dart';
import '../constants/values.dart' show
    ConstantValue,
    PrimitiveConstantValue;
import '../dart_types.dart';
import '../diagnostics/invariant.dart' show
    invariant;
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../tree/tree.dart' as ast;
import '../types/types.dart' show
    TypeMask;
import '../closure.dart' hide ClosureScope;
import '../universe/universe.dart' show
    CallStructure,
    Selector,
    SelectorKind;
import 'cps_ir_nodes.dart' as ir;
import 'cps_ir_builder_task.dart' show
    DartCapturedVariables,
    GlobalProgramInformation;

import '../common.dart' as types show
    TypeMask;
import '../js/js.dart' as js show Template, js, LiteralStatement;
import '../native/native.dart' show
    NativeBehavior;

/// A mapping from variable elements to their compile-time values.
///
/// Map elements denoted by parameters and local variables to the
/// [ir.Primitive] that is their value.  Parameters and locals are
/// assigned indexes which can be used to refer to them.
class Environment {
  /// A map from locals to their environment index.
  final Map<Local, int> variable2index;

  /// A reverse map from environment indexes to the variable.
  final List<Local> index2variable;

  /// A map from environment indexes to their value.
  final List<ir.Primitive> index2value;

  Environment.empty()
      : variable2index = <Local, int>{},
        index2variable = <Local>[],
        index2value = <ir.Primitive>[];

  /// Construct an environment that is a copy of another one.
  ///
  /// The mapping from elements to indexes is shared, not copied.
  Environment.from(Environment other)
      : variable2index = other.variable2index,
        index2variable = new List<Local>.from(other.index2variable),
        index2value = new List<ir.Primitive>.from(other.index2value);

  /// Construct an environment that is shaped like another one but with a
  /// fresh parameter for each variable.
  ///
  /// The mapping from elements to indexes is shared, not copied.
  Environment.fresh(Environment other)
      : variable2index = other.variable2index,
        index2variable = new List<Local>.from(other.index2variable),
        index2value = other.index2variable.map((Local local) {
          return new ir.Parameter(local);
        }).toList();

  get length => index2variable.length;

  ir.Primitive operator [](int index) => index2value[index];

  void extend(Local element, ir.Primitive value) {
    // Assert that the name is not already in the environment.  `null` is used
    // as the name of anonymous variables.
    assert(!variable2index.containsKey(element));
    if (element != null) variable2index[element] = index2variable.length;
    index2variable.add(element);
    index2value.add(value);
  }

  /// Drop [count] values from the environment.
  ///
  /// Return the previous last value in the environment for convenience.
  ir.Primitive discard(int count) {
    assert(count > 0);
    assert(count <= index2variable.length);
    ir.Primitive value = index2value.last;
    // The map from variables to their index are shared, so we cannot remove
    // the mapping in `variable2index`.
    index2variable.length -= count;
    index2value.length -= count;
    return value;
  }

  ir.Primitive lookup(Local element) {
    assert(invariant(element, variable2index.containsKey(element),
                     message: "Unknown variable: $element."));
    return index2value[variable2index[element]];
  }

  void update(Local element, ir.Primitive value) {
    index2value[variable2index[element]] = value;
  }

  /// Verify that the variable2index and index2variable maps agree up to the
  /// index [length] exclusive.
  bool sameDomain(int length, Environment other) {
    assert(this.length >= length);
    assert(other.length >= length);
    for (int i = 0; i < length; ++i) {
      // An index maps to the same variable in both environments.
      Local variable = index2variable[i];
      if (variable != other.index2variable[i]) return false;

      // A named variable maps to the same index in both environments.
      if (variable != null) {
        int index = variable2index[variable];
        if (index == null || index != other.variable2index[variable]) {
          return false;
        }
      }
    }
    return true;
  }

  bool contains(Local local) => variable2index.containsKey(local);
}

/// The abstract base class of objects that emit jumps to a continuation and
/// give a handle to the continuation and its environment.
abstract class JumpCollector {
  final JumpTarget target;

  ir.Continuation _continuation = null;
  final Environment _continuationEnvironment;

  final List<Iterable<LocalVariableElement>> _boxedTryVariables =
      <Iterable<LocalVariableElement>>[];

  /// Construct a collector for a given environment and optionally a target.
  ///
  /// The environment is the one in effect at the point where the jump's
  /// continuation will be bound.  Continuations can take an extra argument
  /// (see [addJump]).
  JumpCollector(this._continuationEnvironment, this.target,
      bool hasExtraArgument) {
    if (hasExtraArgument) _continuationEnvironment.extend(null, null);
  }

  /// True if the collector has not recorded any jumps to its continuation.
  bool get isEmpty;

  /// The continuation encapsulated by this collector.
  ir.Continuation get continuation;

  /// The compile-time environment to be used for translating code in the body
  /// of the continuation.
  Environment get environment;

  /// Emit a jump to the continuation for a given [IrBuilder].
  ///
  /// Jumps can take a single extra argument.  This is used to pass return
  /// values to finally blocks for returns inside try/finally and to pass
  /// values of expressions that have internal control flow to their join-point
  /// continuations.
  void addJump(IrBuilder builder, [ir.Primitive value]);

  /// Add a set of variables that were boxed on entry to a try block.
  ///
  /// All jumps from a try block to targets outside have to unbox the
  /// variables that were boxed on entry before invoking the target
  /// continuation.  Call this function before translating a try block and
  /// call [leaveTry] after translating it.
  void enterTry(Iterable<LocalVariableElement> boxedOnEntry) {
    // The boxed variables are maintained as a stack to make leaving easy.
    _boxedTryVariables.add(boxedOnEntry);
  }

  /// Remove the most recently added set of variables boxed on entry to a try
  /// block.
  ///
  /// Call [enterTry] before translating a try block and call this function
  /// after translating it.
  void leaveTry() {
    _boxedTryVariables.removeLast();
  }

  void _buildTryExit(IrBuilder builder) {
    for (Iterable<LocalVariableElement> boxedOnEntry in _boxedTryVariables) {
      for (LocalVariableElement variable in boxedOnEntry) {
        assert(builder.isInMutableVariable(variable));
        ir.Primitive value = builder.buildLocalVariableGet(variable);
        builder.environment.update(variable, value);
      }
    }
  }

  /// True if a jump inserted now will escape from a try block.
  ///
  /// Concretely, this is true when [enterTry] has been called without
  /// its corresponding [leaveTry] call.
  bool get isEscapingTry => _boxedTryVariables.isNotEmpty;
}

/// A class to collect 'forward' jumps.
///
/// A forward jump to a continuation in the sense of the CPS translation is
/// a jump where the jump is emitted before any code in the body of the
/// continuation is translated.  They have the property that continuation
/// parameters and the environment for the translation of the body can be
/// determined based on the invocations, before translating the body.  A
/// [ForwardJumpCollector] can encapsulate a continuation where all the
/// jumps are forward ones.
///
/// Examples of forward jumps in the translation are join points of
/// if-then-else and breaks from loops.
///
/// The implementation strategy is that the collector collects invocation
/// sites and the environments at those sites.  Then it constructs a
/// continuation 'on demand' after all the jumps are seen.  It determines
/// continuation parameters, the environment for the translation of code in
/// the continuation body, and the arguments at the invocation site only
/// after all the jumps to the continuation are seen.
class ForwardJumpCollector extends JumpCollector {
  final List<ir.InvokeContinuation> _invocations = <ir.InvokeContinuation>[];
  final List<Environment> _invocationEnvironments = <Environment>[];

  /// Construct a collector with a given base environment.
  ///
  /// The base environment is the one in scope at the site that the
  /// continuation represented by this collector will be bound.  The
  /// environment is copied by the collector.  Subsequent mutation of the
  /// original environment will not affect the collector.
  ForwardJumpCollector(Environment environment,
      {JumpTarget target, bool hasExtraArgument: false})
      : super(new Environment.from(environment), target, hasExtraArgument);

  bool get isEmpty => _invocations.isEmpty;

  ir.Continuation get continuation {
    if (_continuation == null) _setContinuation();
    return _continuation;
  }

  Environment get environment {
    if (_continuation == null) _setContinuation();
    return _continuationEnvironment;
  }

  void addJump(IrBuilder builder, [ir.Primitive value]) {
    assert(_continuation == null);
    _buildTryExit(builder);
    ir.InvokeContinuation invoke = new ir.InvokeContinuation.uninitialized(
        isEscapingTry: isEscapingTry);
    builder.add(invoke);
    _invocations.add(invoke);
    // Truncate the environment at the invocation site so it only includes
    // values that will be continuation arguments.  If an extra value is passed
    // it will already be included in the continuation environment, but it is
    // not present in the invocation environment.
    int delta = builder.environment.length - _continuationEnvironment.length;
    if (value != null) ++delta;
    if (delta > 0) builder.environment.discard(delta);
    if (value != null) builder.environment.extend(null, value);
    _invocationEnvironments.add(builder.environment);
    builder._current = null;
    // TODO(kmillikin): Can we set builder.environment to null to make it
    // less likely to mutate it?
  }

  void _setContinuation() {
    assert(_continuation == null);
    // We have seen all invocations of this continuation, and recorded the
    // environment in effect at each invocation site.

    // Compute the union of the assigned variables reaching the continuation.
    //
    // There is a continuation parameter for each environment variable
    // that has a different value (from the environment in scope at the
    // continuation binding) on some path.  `_environment` is initially a copy
    // of the environment in scope at the continuation binding.  Compute the
    // continuation parameters and add them to `_environment` so it will become
    // the one in scope for the continuation body.
    List<ir.Parameter> parameters = <ir.Parameter>[];
    if (_invocationEnvironments.isNotEmpty) {
      int length = _continuationEnvironment.length;
      for (int varIndex = 0; varIndex < length; ++varIndex) {
        for (Environment invocationEnvironment in _invocationEnvironments) {
          assert(invocationEnvironment.sameDomain(length,
                                                  _continuationEnvironment));
          if (invocationEnvironment[varIndex] !=
              _continuationEnvironment[varIndex]) {
            ir.Parameter parameter = new ir.Parameter(
                _continuationEnvironment.index2variable[varIndex]);
            _continuationEnvironment.index2value[varIndex] = parameter;
            parameters.add(parameter);
            break;
          }
        }
      }
    }
    _continuation = new ir.Continuation(parameters);

    // Compute the intersection of the parameters with the environments at
    // each continuation invocation.  Initialize the invocations.
    for (int jumpIndex = 0; jumpIndex < _invocations.length; ++jumpIndex) {
      Environment invocationEnvironment = _invocationEnvironments[jumpIndex];
      List<ir.Reference> arguments = <ir.Reference>[];
      int varIndex = 0;
      for (ir.Parameter parameter in parameters) {
        varIndex =
            _continuationEnvironment.index2value.indexOf(parameter, varIndex);
        arguments.add(new ir.Reference(invocationEnvironment[varIndex]));
      }
      ir.InvokeContinuation invocation = _invocations[jumpIndex];
      invocation.continuation = new ir.Reference(_continuation);
      invocation.arguments = arguments;
    }
  }
}

/// A class to collect 'backward' jumps.
///
/// A backward jump to a continuation in the sense of the CPS translation is
/// a jump where some code in the body of the continuation is translated
/// before the jump is emitted.  They have the property that the
/// continuation parameters and the environment for the translation of the
/// body must be determined before emitting all the invocations.  A
/// [BackwardJumpCollector] can ecapsulate a continuation where some jumps
/// are backward ones.
///
/// Examples of backward jumps in the translation are the recursive
/// invocations of loop continuations.
///
/// The implementation strategy is that the collector inserts a continuation
/// parameter for each variable in scope at the entry to the continuation,
/// before emitting any jump to the continuation.  When a jump is added, it
/// is given an argument for each continuation parameter.
class BackwardJumpCollector extends JumpCollector {
  /// Construct a collector with a given base environment.
  ///
  /// The base environment is the one in scope at the site that the
  /// continuation represented by this collector will be bound.  The
  /// translation of the continuation body will use an environment with the
  /// same shape, but with fresh continuation parameters for each variable.
  BackwardJumpCollector(Environment environment,
      {JumpTarget target, bool hasExtraArgument: false})
      : super(new Environment.fresh(environment), target, hasExtraArgument) {
    List<ir.Parameter> parameters =
        new List<ir.Parameter>.from(_continuationEnvironment.index2value);
    _continuation = new ir.Continuation(parameters, isRecursive: true);
  }

  bool isEmpty = true;

  ir.Continuation get continuation => _continuation;
  Environment get environment => _continuationEnvironment;

  void addJump(IrBuilder builder, [ir.Primitive value]) {
    assert(_continuation.parameters.length <= builder.environment.length);
    isEmpty = false;
    _buildTryExit(builder);
    // Truncate the environment at the invocation site so it only includes
    // values that will be continuation arguments.  If an extra value is passed
    // it will already be included in the continuation environment, but it is
    // not present in the invocation environment.
    int delta = builder.environment.length - _continuationEnvironment.length;
    if (value != null) ++delta;
    if (delta > 0) builder.environment.discard(delta);
    if (value != null) builder.environment.extend(null, value);
    builder.add(new ir.InvokeContinuation(_continuation,
        builder.environment.index2value,
        isRecursive: true,
        isEscapingTry: isEscapingTry));
    builder._current = null;
  }
}

/// Function for building a node in the context of the current builder.
typedef ir.Node BuildFunction(node);

/// Function for building nodes in the context of the provided [builder].
typedef ir.Node SubbuildFunction(IrBuilder builder);

/// Mixin that provides encapsulated access to nested builders.
abstract class IrBuilderMixin<N> {
  IrBuilder _irBuilder;

  /// Execute [f] with [builder] as the current builder.
  withBuilder(IrBuilder builder, f()) {
    assert(builder != null);
    IrBuilder prev = _irBuilder;
    _irBuilder = builder;
    var result = f();
    _irBuilder = prev;
    return result;
  }

  /// The current builder.
  IrBuilder get irBuilder {
    assert(_irBuilder != null);
    return _irBuilder;
  }

  /// Visits the [node].
  ir.Primitive visit(N node);

  /// Builds and returns the [ir.Node] for [node] or returns `null` if
  /// [node] is `null`.
  ir.Node build(N node) => node != null ? visit(node) : null;

  /// Returns a closure that takes an [IrBuilder] and builds [node] in its
  /// context using [build].
  SubbuildFunction subbuild(N node) {
    return (IrBuilder builder) => withBuilder(builder, () => build(node));
  }

  /// Returns a closure that takes an [IrBuilder] and runs [f] in its context.
  SubbuildFunction nested(f()) {
    return (IrBuilder builder) => withBuilder(builder, f);
  }

  /// Returns a closure that takes an [IrBuilder] and builds the sequence of
  /// [nodes] in its context using [build].
  // TODO(johnniwinther): Type [nodes] as `Iterable<N>` when `NodeList` uses
  // `List` instead of `Link`.
  SubbuildFunction subbuildSequence(/*Iterable<N>*/ nodes) {
    return (IrBuilder builder) {
      return withBuilder(builder, () => builder.buildSequence(nodes, build));
    };
  }
}

/// Shared state between delimited IrBuilders within the same function.
class IrBuilderSharedState {
  final GlobalProgramInformation program;

  final BackendConstantEnvironment constants;

  ConstantSystem get constantSystem => constants.constantSystem;

  /// A stack of collectors for breaks.
  List<JumpCollector> breakCollectors = <JumpCollector>[];

  /// A stack of collectors for continues.
  List<JumpCollector> continueCollectors = <JumpCollector>[];

  final ExecutableElement currentElement;

  final ir.Continuation returnContinuation = new ir.Continuation.retrn();

  /// The target of a return from the function.
  ///
  /// A null value indicates that the target is the function's return
  /// continuation.  Otherwise, when inside the try block of try/finally
  /// a return is intercepted to give a place to generate the finally code.
  JumpCollector returnCollector = null;

  /// Parameter holding the internal value of 'this' passed to the function.
  ///
  /// For nested functions, this is *not* captured receiver, but the function
  /// object itself.
  ir.Parameter thisParameter;

  /// If non-null, this refers to the receiver (`this`) in the enclosing method.
  ir.Primitive enclosingThis;

  final List<ir.Parameter> functionParameters = <ir.Parameter>[];

  /// Maps boxed locals to their location. These locals are not part of
  /// the environment.
  final Map<Local, ClosureLocation> boxedVariables = {};

  IrBuilderSharedState(this.program, this.constants, this.currentElement);
}

class ThisParameterLocal implements Local {
  final ExecutableElement executableContext;
  ThisParameterLocal(this.executableContext);
  String get name => 'this';
  toString() => 'ThisParameterLocal($executableContext)';
}

/// The IR builder maintains an environment and an IR fragment.
///
/// The IR fragment is an expression with a hole in it. The hole represents
/// the focus where new expressions can be added. The fragment is implemented
/// by [_root] which is the root of the expression and [_current] which is the
/// expression that immediately contains the hole. Not all expressions have a
/// hole (e.g., invocations, which always occur in tail position, do not have a
/// hole). Expressions with a hole have a plug method.
///
/// The environment maintains the reaching definition of each local variable,
/// including some synthetic locals such as [TypeVariableLocal].
///
/// Internally, IR builders also maintains a [JumpCollector] stack and tracks
/// which variables are currently boxed or held in a mutable local variable.
class IrBuilder {
  final List<ir.Parameter> _parameters = <ir.Parameter>[];

  final IrBuilderSharedState state;

  /// A map from variable indexes to their values.
  ///
  /// [BoxLocal]s map to their box. [LocalElement]s that are boxed are not
  /// in the map; look up their [BoxLocal] instead.
  Environment environment;

  /// A map from mutable local variables to their [ir.MutableVariable]s.
  ///
  /// Mutable variables are treated as boxed.  Writes to them are observable
  /// side effects.
  Map<Local, ir.MutableVariable> mutableVariables;

  ir.Expression _root = null;
  ir.Expression _current = null;

  GlobalProgramInformation get program => state.program;

  IrBuilder(GlobalProgramInformation program,
            BackendConstantEnvironment constants,
            ExecutableElement currentElement)
    : state = new IrBuilderSharedState(program, constants, currentElement),
      environment = new Environment.empty(),
      mutableVariables = <Local, ir.MutableVariable>{};

  IrBuilder._internal(this.state, this.environment, this.mutableVariables);

  /// Construct a delimited visitor for visiting a subtree.
  ///
  /// Build a subterm that is not (yet) connected to the CPS term.  The
  /// delimited visitor has its own has its own context for building an IR
  /// expression, so the built expression is not plugged into the parent's
  /// context.  It has its own compile-time environment mapping local
  /// variables to their values.  If an optional environment argument is
  /// supplied, it is used as the builder's initial environment.  Otherwise
  /// the environment is initially a copy of the parent builder's environment.
  IrBuilder makeDelimitedBuilder([Environment env = null]) {
    return new IrBuilder._internal(
        state,
        env != null ? env : new Environment.from(environment),
        mutableVariables);
  }

  /// True if [local] should currently be accessed from a [ir.MutableVariable].
  bool isInMutableVariable(Local local) {
    return mutableVariables.containsKey(local);
  }

  /// Creates a [ir.MutableVariable] for the given local.
  void makeMutableVariable(Local local) {
    mutableVariables[local] =
        new ir.MutableVariable(local);
  }

  /// Remove an [ir.MutableVariable] for a local.
  ///
  /// Subsequent access to the local will be direct rather than through the
  /// mutable variable.
  void removeMutableVariable(Local local) {
    mutableVariables.remove(local);
  }

  /// Gets the [MutableVariable] containing the value of [local].
  ir.MutableVariable getMutableVariable(Local local) {
    return mutableVariables[local];
  }

  bool get isOpen => _root == null || _current != null;

  List<ir.Primitive> buildFunctionHeader(Iterable<Local> parameters,
                                        {ClosureScope closureScope,
                                         ClosureEnvironment env}) {
    _createThisParameter();
    _enterClosureEnvironment(env);
    _enterScope(closureScope);
    parameters.forEach(_createFunctionParameter);
    return _parameters;
  }

  /// Creates a parameter for [local] and adds it to the current environment.
  ir.Parameter _createLocalParameter(Local local) {
    ir.Parameter parameter = new ir.Parameter(local);
    _parameters.add(parameter);
    environment.extend(local, parameter);
    return parameter;
  }

  /// Plug an expression into the 'hole' in the context being accumulated.  The
  /// empty context (just a hole) is represented by root (and current) being
  /// null.  Since the hole in the current context is filled by this function,
  /// the new hole must be in the newly added expression---which becomes the
  /// new value of current.
  void add(ir.Expression expr) {
    assert(isOpen);
    if (_root == null) {
      _root = _current = expr;
    } else {
      _current = _current.plug(expr);
    }
  }

  /// Create and add a new [LetPrim] for [primitive].
  ir.Primitive addPrimitive(ir.Primitive primitive) {
    add(new ir.LetPrim(primitive));
    return primitive;
  }

  ir.Primitive _continueWithExpression(ir.Expression build(ir.Continuation k)) {
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.Expression expression = build(k);
    add(new ir.LetCont(k, expression));
    return v;
  }

  ir.Primitive _buildInvokeStatic(Element element,
                                  Selector selector,
                                  List<ir.Primitive> arguments,
                                  SourceInformation sourceInformation) {
    assert(!element.isLocal);
    assert(!element.isInstanceMember);
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.InvokeStatic(element, selector, arguments, k,
                                   sourceInformation));
  }

  ir.Primitive _buildInvokeSuper(Element target,
                                 Selector selector,
                                 List<ir.Primitive> arguments,
                                 SourceInformation sourceInformation) {
    assert(target.isInstanceMember);
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.InvokeMethodDirectly(
            buildThis(), target, selector, arguments, k, sourceInformation));
  }

  ir.Primitive _buildInvokeDynamic(ir.Primitive receiver,
                                   Selector selector,
                                   TypeMask mask,
                                   List<ir.Primitive> arguments,
                                   SourceInformation sourceInformation) {
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.InvokeMethod(receiver, selector, mask, arguments, k,
                                   sourceInformation));
  }

  ir.Primitive _buildInvokeCall(ir.Primitive target,
                                CallStructure callStructure,
                                TypeMask mask,
                                List<ir.Definition> arguments,
                                {SourceInformation sourceInformation}) {
    Selector selector = callStructure.callSelector;
    return _buildInvokeDynamic(
        target, selector, mask, arguments, sourceInformation);
  }


  /// Create a [ir.Constant] from [value] and add it to the CPS term.
  ir.Constant buildConstant(ConstantValue value,
                            {SourceInformation sourceInformation}) {
    assert(isOpen);
    return addPrimitive(
        new ir.Constant(value, sourceInformation: sourceInformation));
  }

  /// Create an integer constant and add it to the CPS term.
  ir.Constant buildIntegerConstant(int value) {
    return buildConstant(state.constantSystem.createInt(value));
  }

  /// Create a double constant and add it to the CPS term.
  ir.Constant buildDoubleConstant(double value) {
    return buildConstant(state.constantSystem.createDouble(value));
  }

  /// Create a Boolean constant and add it to the CPS term.
  ir.Constant buildBooleanConstant(bool value) {
    return buildConstant(state.constantSystem.createBool(value));
  }

  /// Create a null constant and add it to the CPS term.
  ir.Constant buildNullConstant() {
    return buildConstant(state.constantSystem.createNull());
  }

  /// Create a string constant and add it to the CPS term.
  ir.Constant buildStringConstant(String value) {
    return buildConstant(
        state.constantSystem.createString(new ast.DartString.literal(value)));
  }

  /// Create a string constant and add it to the CPS term.
  ir.Constant buildDartStringConstant(ast.DartString value) {
    return buildConstant(state.constantSystem.createString(value));
  }

  /// Creates a non-constant list literal of the provided [type] and with the
  /// provided [values].
  ir.Primitive buildListLiteral(InterfaceType type,
                                Iterable<ir.Primitive> values) {
    assert(isOpen);
    return addPrimitive(new ir.LiteralList(type, values.toList()));
  }

  /// Creates a non-constant map literal of the provided [type] and with the
  /// entries build from the [keys] and [values] using [build].
  ir.Primitive buildMapLiteral(InterfaceType type,
                               Iterable keys,
                               Iterable values,
                               BuildFunction build) {
    assert(isOpen);
    List<ir.LiteralMapEntry> entries = <ir.LiteralMapEntry>[];
    Iterator key = keys.iterator;
    Iterator value = values.iterator;
    while (key.moveNext() && value.moveNext()) {
      entries.add(new ir.LiteralMapEntry(
          build(key.current), build(value.current)));
    }
    assert(!key.moveNext() && !value.moveNext());
    return addPrimitive(new ir.LiteralMap(type, entries));
  }

  /// Creates a conditional expression with the provided [condition] where the
  /// then and else expression are created through the [buildThenExpression]
  /// and [buildElseExpression] functions, respectively.
  ir.Primitive buildConditional(
      ir.Primitive condition,
      ir.Primitive buildThenExpression(IrBuilder builder),
      ir.Primitive buildElseExpression(IrBuilder builder)) {
    assert(isOpen);

    // The then and else expressions are delimited.
    IrBuilder thenBuilder = makeDelimitedBuilder();
    IrBuilder elseBuilder = makeDelimitedBuilder();
    ir.Primitive thenValue = buildThenExpression(thenBuilder);
    ir.Primitive elseValue = buildElseExpression(elseBuilder);

    // Treat the values of the subexpressions as named values in the
    // environment, so they will be treated as arguments to the join-point
    // continuation.  We know the environments are the right size because
    // expressions cannot introduce variable bindings.
    assert(environment.length == thenBuilder.environment.length);
    assert(environment.length == elseBuilder.environment.length);
    JumpCollector join =
        new ForwardJumpCollector(environment, hasExtraArgument: true);
    thenBuilder.jumpTo(join, thenValue);
    elseBuilder.jumpTo(join, elseValue);

    // Build the term
    //   let cont join(x, ..., result) = [] in
    //   let cont then() = [[thenPart]]; join(v, ...)
    //        and else() = [[elsePart]]; join(v, ...)
    //   in
    //     if condition (then, else)
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);
    thenContinuation.body = thenBuilder._root;
    elseContinuation.body = elseBuilder._root;
    add(new ir.LetCont(join.continuation,
            new ir.LetCont.two(thenContinuation, elseContinuation,
                new ir.Branch(new ir.IsTrue(condition),
                              thenContinuation,
                              elseContinuation))));
    environment = join.environment;
    return environment.discard(1);
  }

  /**
   * Add an explicit `return null` for functions that don't have a return
   * statement on each branch. This includes functions with an empty body,
   * such as `foo(){ }`.
   */
  void _ensureReturn() {
    if (!isOpen) return;
    ir.Constant constant = buildNullConstant();
    add(new ir.InvokeContinuation(state.returnContinuation, [constant]));
    _current = null;
  }

  /// Create a [ir.FunctionDefinition] using [_root] as the body.
  ///
  /// The protocol for building a function is:
  /// 1. Call [buildFunctionHeader].
  /// 2. Call `buildXXX` methods to build the body.
  /// 3. Call [makeFunctionDefinition] to finish.
  ir.FunctionDefinition makeFunctionDefinition() {
    _ensureReturn();
    return new ir.FunctionDefinition(
        state.currentElement,
        state.thisParameter,
        state.functionParameters,
        state.returnContinuation,
        _root);
  }

  /// Create a invocation of the [method] on the super class where the call
  /// structure is defined [callStructure] and the argument values are defined
  /// by [arguments].
  ir.Primitive buildSuperMethodInvocation(
      MethodElement method,
      CallStructure callStructure,
      List<ir.Primitive> arguments,
      {SourceInformation sourceInformation}) {
    // TODO(johnniwinther): This shouldn't be necessary.
    SelectorKind kind = Elements.isOperatorName(method.name)
        ? SelectorKind.OPERATOR : SelectorKind.CALL;
    Selector selector =
        new Selector(kind, method.memberName, callStructure);
    return _buildInvokeSuper(method, selector, arguments, sourceInformation);
  }

  /// Create a read access of the [method] on the super class, i.e. a
  /// closurization of [method].
  ir.Primitive buildSuperMethodGet(MethodElement method,
                                   {SourceInformation sourceInformation}) {
    // TODO(johnniwinther): This should have its own ir node.
    return _buildInvokeSuper(
        method,
        new Selector.getter(method.memberName),
        const <ir.Primitive>[],
        sourceInformation);
  }

  /// Create a getter invocation of the [getter] on the super class.
  ir.Primitive buildSuperGetterGet(MethodElement getter,
                                   SourceInformation sourceInformation) {
    // TODO(johnniwinther): This should have its own ir node.
    return _buildInvokeSuper(
        getter,
        new Selector.getter(getter.memberName),
        const <ir.Primitive>[],
        sourceInformation);
  }

  /// Create an setter invocation of the [setter] on the super class with
  /// [value].
  ir.Primitive buildSuperSetterSet(MethodElement setter,
                                   ir.Primitive value,
                                   {SourceInformation sourceInformation}) {
    // TODO(johnniwinther): This should have its own ir node.
    _buildInvokeSuper(
        setter,
        new Selector.setter(setter.memberName),
        <ir.Primitive>[value],
        sourceInformation);
    return value;
  }

  /// Create an invocation of the index [method] on the super class with
  /// the provided [index].
  ir.Primitive buildSuperIndex(MethodElement method,
                               ir.Primitive index,
                               {SourceInformation sourceInformation}) {
    return _buildInvokeSuper(
        method, new Selector.index(), <ir.Primitive>[index],
        sourceInformation);
  }

  /// Create an invocation of the index set [method] on the super class with
  /// the provided [index] and [value].
  ir.Primitive buildSuperIndexSet(MethodElement method,
                                  ir.Primitive index,
                                  ir.Primitive value,
                                  {SourceInformation sourceInformation}) {
    _buildInvokeSuper(method, new Selector.indexSet(),
        <ir.Primitive>[index, value], sourceInformation);
    return value;
  }

  /// Create a dynamic invocation on [receiver] where the method name and
  /// argument structure are defined by [selector] and the argument values are
  /// defined by [arguments].
  ir.Primitive buildDynamicInvocation(ir.Primitive receiver,
                                      Selector selector,
                                      TypeMask mask,
                                      List<ir.Primitive> arguments,
                                      {SourceInformation sourceInformation}) {
    return _buildInvokeDynamic(
        receiver, selector, mask, arguments, sourceInformation);
  }

  /// Create a dynamic getter invocation on [receiver] where the getter name is
  /// defined by [selector].
  ir.Primitive buildDynamicGet(ir.Primitive receiver,
                               Selector selector,
                               TypeMask mask,
                               SourceInformation sourceInformation) {
    assert(selector.isGetter);
    FieldElement field = program.locateSingleField(selector, mask);
    if (field != null) {
      // If the world says this resolves to a unique field, then it MUST be
      // treated as a field access, since the getter might not be emitted.
      return buildFieldGet(receiver, field);
    } else {
      return _buildInvokeDynamic(
          receiver, selector, mask, const <ir.Primitive>[], sourceInformation);
    }
  }

  /// Create a dynamic setter invocation on [receiver] where the setter name and
  /// argument are defined by [selector] and [value], respectively.
  ir.Primitive buildDynamicSet(ir.Primitive receiver,
                               Selector selector,
                               TypeMask mask,
                               ir.Primitive value,
                               {SourceInformation sourceInformation}) {
    assert(selector.isSetter);
    FieldElement field = program.locateSingleField(selector, mask);
    if (field != null) {
      // If the world says this resolves to a unique field, then it MUST be
      // treated as a field access, since the setter might not be emitted.
      buildFieldSet(receiver, field, value);
    } else {
      _buildInvokeDynamic(receiver, selector, mask, <ir.Primitive>[value],
                          sourceInformation);
    }
    return value;
  }

  /// Create a dynamic index set invocation on [receiver] with the provided
  /// [index] and [value].
  ir.Primitive buildDynamicIndexSet(ir.Primitive receiver,
                                    TypeMask mask,
                                    ir.Primitive index,
                                    ir.Primitive value,
                                    {SourceInformation sourceInformation}) {
    _buildInvokeDynamic(
        receiver, new Selector.indexSet(), mask, <ir.Primitive>[index, value],
        sourceInformation);
    return value;
  }

  /// Create a read access of the [local] variable or parameter.
  ir.Primitive buildLocalVariableGet(LocalElement local) {
    // TODO(johnniwinther): Separate function access from variable access.
    return _buildLocalGet(local);
  }

  /// Create a read access of the local [function], i.e. closurization of
  /// [function].
  ir.Primitive buildLocalFunctionGet(LocalFunctionElement function) {
    // TODO(johnniwinther): Separate function access from variable access.
    return _buildLocalGet(function);
  }

  /// Create an invocation of the the [local] variable or parameter where
  /// argument structure is defined by [callStructure] and the argument values
  /// are defined by [arguments].
  ir.Primitive buildLocalVariableInvocation(
      LocalVariableElement local,
      CallStructure callStructure,
      List<ir.Primitive> arguments,
      {SourceInformation callSourceInformation}) {
    return buildCallInvocation(
        buildLocalVariableGet(local), callStructure, arguments,
        sourceInformation: callSourceInformation);
  }

  /// Create an invocation of the local [function] where argument structure is
  /// defined by [callStructure] and the argument values are defined by
  /// [arguments].
  ir.Primitive buildLocalFunctionInvocation(
      LocalFunctionElement function,
      CallStructure callStructure,
      List<ir.Primitive> arguments,
      SourceInformation sourceInformation) {
    // TODO(johnniwinther): Maybe this should have its own ir node.
    return buildCallInvocation(
        buildLocalFunctionGet(function), callStructure, arguments,
        sourceInformation: sourceInformation);
  }

  /// Create a static invocation of [function] where argument structure is
  /// defined by [callStructure] and the argument values are defined by
  /// [arguments].
  ir.Primitive buildStaticFunctionInvocation(
      MethodElement function,
      CallStructure callStructure,
      List<ir.Primitive> arguments,
      {SourceInformation sourceInformation}) {
    Selector selector =
        new Selector(SelectorKind.CALL, function.memberName, callStructure);
    return _buildInvokeStatic(
        function, selector, arguments, sourceInformation);
  }

  /// Create a read access of the static [field].
  ir.Primitive buildStaticFieldGet(FieldElement field,
                                   SourceInformation sourceInformation) {
    return addPrimitive(new ir.GetStatic(field, sourceInformation));
  }

  /// Create a read access of a static [field] that might not have been
  /// initialized yet.
  ir.Primitive buildStaticFieldLazyGet(FieldElement field,
                                       SourceInformation sourceInformation) {
    return _continueWithExpression(
        (k) => new ir.GetLazyStatic(field, k, sourceInformation));
  }

  /// Create a getter invocation of the static [getter].
  ir.Primitive buildStaticGetterGet(MethodElement getter,
                                    SourceInformation sourceInformation) {
    Selector selector = new Selector.getter(getter.memberName);
    return _buildInvokeStatic(
        getter, selector, const <ir.Primitive>[], sourceInformation);
  }

  /// Create a read access of the static [function], i.e. a closurization of
  /// [function].
  ir.Primitive buildStaticFunctionGet(MethodElement function,
                                      {SourceInformation sourceInformation}) {
    return addPrimitive(new ir.GetStatic(function, sourceInformation));
  }

  /// Create a write access to the static [field] with the [value].
  ir.Primitive buildStaticFieldSet(FieldElement field,
                                   ir.Primitive value,
                                   [SourceInformation sourceInformation]) {
    addPrimitive(new ir.SetStatic(field, value, sourceInformation));
    return value;
  }

  /// Create a setter invocation of the static [setter] with the [value].
  ir.Primitive buildStaticSetterSet(MethodElement setter,
                                    ir.Primitive value,
                                    {SourceInformation sourceInformation}) {
    Selector selector = new Selector.setter(setter.memberName);
    _buildInvokeStatic(
        setter, selector, <ir.Primitive>[value], sourceInformation);
    return value;
  }

  /// Create an erroneous invocation where argument structure is defined by
  /// [selector] and the argument values are defined by [arguments].
  // TODO(johnniwinther): Make this more fine-grained.
  ir.Primitive buildErroneousInvocation(
      Element element,
      Selector selector,
      List<ir.Primitive> arguments) {
    // TODO(johnniwinther): This should have its own ir node.
    return _buildInvokeStatic(element, selector, arguments, null);
  }

  /// Concatenate string values.
  ///
  /// The arguments must be strings; usually a call to [buildStringify] is
  /// needed to ensure the proper conversion takes places.
  ir.Primitive buildStringConcatenation(List<ir.Primitive> arguments,
                                        {SourceInformation sourceInformation}) {
    assert(isOpen);
    return addPrimitive(new ir.ApplyBuiltinOperator(
        ir.BuiltinOperator.StringConcatenate,
        arguments,
        sourceInformation));
  }

  /// Create an invocation of the `call` method of [functionExpression], where
  /// the structure of arguments are given by [callStructure].
  // TODO(johnniwinther): This should take a [TypeMask].
  ir.Primitive buildCallInvocation(
      ir.Primitive functionExpression,
      CallStructure callStructure,
      List<ir.Definition> arguments,
      {SourceInformation sourceInformation}) {
    return _buildInvokeCall(functionExpression, callStructure, null, arguments,
        sourceInformation: sourceInformation);
  }

  /// Creates an if-then-else statement with the provided [condition] where the
  /// then and else branches are created through the [buildThenPart] and
  /// [buildElsePart] functions, respectively.
  ///
  /// An if-then statement is created if [buildElsePart] is a no-op.
  // TODO(johnniwinther): Unify implementation with [buildConditional] and
  // [_buildLogicalOperator].
  void buildIf(ir.Primitive condition,
               void buildThenPart(IrBuilder builder),
               void buildElsePart(IrBuilder builder)) {
    assert(isOpen);

    // The then and else parts are delimited.
    IrBuilder thenBuilder = makeDelimitedBuilder();
    IrBuilder elseBuilder = makeDelimitedBuilder();
    buildThenPart(thenBuilder);
    buildElsePart(elseBuilder);

    // Build the term
    // (Result =) let cont then() = [[thenPart]]
    //                 and else() = [[elsePart]]
    //            in
    //              if condition (then, else)
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);
    // If exactly one of the then and else continuation bodies is open (i.e.,
    // the other one has an exit on all paths), then Continuation.plug expects
    // that continuation to be listed first.  Arbitrarily use [then, else]
    // order otherwise.
    List<ir.Continuation> arms = !thenBuilder.isOpen && elseBuilder.isOpen
        ? <ir.Continuation>[elseContinuation, thenContinuation]
        : <ir.Continuation>[thenContinuation, elseContinuation];

    ir.Expression result =
        new ir.LetCont.many(arms,
            new ir.Branch(new ir.IsTrue(condition),
                          thenContinuation,
                          elseContinuation));

    JumpCollector join;  // Null if there is no join.
    if (thenBuilder.isOpen && elseBuilder.isOpen) {
      // There is a join-point continuation.  Build the term
      // 'let cont join(x, ...) = [] in Result' and plug invocations of the
      // join-point continuation into the then and else continuations.
      join = new ForwardJumpCollector(environment);
      thenBuilder.jumpTo(join);
      elseBuilder.jumpTo(join);
      result = new ir.LetCont(join.continuation, result);
    }

    // The then or else term root could be null, but not both.  If there is
    // a join then an InvokeContinuation was just added to both of them.  If
    // there is no join, then at least one of them is closed and thus has a
    // non-null root by the definition of the predicate isClosed.  In the
    // case that one of them is null, it must be the only one that is open
    // and thus contains the new hole in the context.  This case is handled
    // after the branch is plugged into the current hole.
    thenContinuation.body = thenBuilder._root;
    elseContinuation.body = elseBuilder._root;

    add(result);
    if (join == null) {
      // At least one subexpression is closed.
      if (thenBuilder.isOpen) {
        if (thenBuilder._root != null) _current = thenBuilder._current;
        environment = thenBuilder.environment;
      } else if (elseBuilder.isOpen) {
        if (elseBuilder._root != null) _current = elseBuilder._current;
        environment = elseBuilder.environment;
      } else {
        _current = null;
      }
    } else {
      environment = join.environment;
    }
  }

  void jumpTo(JumpCollector collector, [ir.Primitive value]) {
    collector.addJump(this, value);
  }

  void addRecursiveContinuation(BackwardJumpCollector collector) {
    assert(environment.length == collector.environment.length);
    add(new ir.LetCont(collector.continuation,
            new ir.InvokeContinuation(collector.continuation,
                                      environment.index2value)));
    environment = collector.environment;
  }

  /// Creates a for loop in which the initializer, condition, body, update are
  /// created by [buildInitializer], [buildCondition], [buildBody] and
  /// [buildUpdate], respectively.
  ///
  /// The jump [target] is used to identify which `break` and `continue`
  /// statements that have this `for` statement as their target.
  ///
  /// The [closureScope] identifies variables that should be boxed in this loop.
  /// This includes variables declared inside the body of the loop as well as
  /// in the for-loop initializer.
  ///
  /// [loopVariables] is the list of variables declared in the for-loop
  /// initializer.
  void buildFor({SubbuildFunction buildInitializer,
                 SubbuildFunction buildCondition,
                 SubbuildFunction buildBody,
                 SubbuildFunction buildUpdate,
                 JumpTarget target,
                 ClosureScope closureScope,
                 List<LocalElement> loopVariables}) {
    assert(isOpen);

    // For loops use four named continuations: the entry to the condition,
    // the entry to the body, the loop exit, and the loop successor (break).
    // The CPS translation of
    // [[for (initializer; condition; update) body; successor]] is:
    //
    // _enterForLoopInitializer();
    // [[initializer]];
    // let cont loop(x, ...) =
    //     let prim cond = [[condition]] in
    //     let cont break(x, ...) = [[successor]] in
    //     let cont exit() = break(v, ...) in
    //     let cont body() =
    //         _enterForLoopBody();
    //         let cont continue(x, ...) =
    //             _enterForLoopUpdate();
    //             [[update]];
    //             loop(v, ...) in
    //         [[body]];
    //         continue(v, ...) in
    //     branch cond (body, exit) in
    // loop(v, ...)
    //
    // If there are no breaks in the body, the break continuation is inlined
    // in the exit continuation (i.e., the translation of the successor
    // statement occurs in the exit continuation).  If there is only one
    // invocation of the continue continuation (i.e., no continues in the
    // body), the continue continuation is inlined in the body.
    _enterForLoopInitializer(closureScope, loopVariables);
    buildInitializer(this);

    JumpCollector loop = new BackwardJumpCollector(environment);
    addRecursiveContinuation(loop);

    ir.Primitive condition = buildCondition(this);
    if (condition == null) {
      // If the condition is empty then the body is entered unconditionally.
      condition = buildBooleanConstant(true);
    }
    JumpCollector breakCollector =
        new ForwardJumpCollector(environment, target: target);

    // Use a pair of builders for the body, one for the entry code if any
    // and one for the body itself.  We only decide whether to insert a
    // continue continuation until after translating the body and there is no
    // way to insert such a continuation between the entry code and the body
    // if they are translated together.
    IrBuilder outerBodyBuilder = makeDelimitedBuilder();
    outerBodyBuilder._enterForLoopBody(closureScope, loopVariables);
    JumpCollector continueCollector =
        new ForwardJumpCollector(outerBodyBuilder.environment, target: target);

    IrBuilder innerBodyBuilder = outerBodyBuilder.makeDelimitedBuilder();
    state.breakCollectors.add(breakCollector);
    state.continueCollectors.add(continueCollector);
    buildBody(innerBodyBuilder);
    assert(state.breakCollectors.last == breakCollector);
    assert(state.continueCollectors.last == continueCollector);
    state.breakCollectors.removeLast();
    state.continueCollectors.removeLast();

    // The binding of the continue continuation should occur as late as
    // possible, that is, at the nearest common ancestor of all the continue
    // sites in the body.  However, that is difficult to compute here, so it
    // is instead placed just outside the translation of the loop body.  In
    // the case where there are no continues in the body, the updates are
    // translated immediately after the body.
    bool hasContinues = !continueCollector.isEmpty;
    IrBuilder updateBuilder;
    if (hasContinues) {
      if (innerBodyBuilder.isOpen) innerBodyBuilder.jumpTo(continueCollector);
      updateBuilder = makeDelimitedBuilder(continueCollector.environment);
    } else {
      updateBuilder = innerBodyBuilder;
    }
    updateBuilder._enterForLoopUpdate(closureScope, loopVariables);
    buildUpdate(updateBuilder);
    if (updateBuilder.isOpen) updateBuilder.jumpTo(loop);
    // Connect the inner and outer body builders.  This is done only after
    // it is guaranteed that the updateBuilder has a non-empty term.
    if (hasContinues) {
      outerBodyBuilder.add(new ir.LetCont(continueCollector.continuation,
          innerBodyBuilder._root));
      continueCollector.continuation.body = updateBuilder._root;
    } else {
      outerBodyBuilder.add(innerBodyBuilder._root);
    }

    // Create loop exit and body entry continuations and a branch to them.
    ir.Continuation exitContinuation = new ir.Continuation([]);
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    bodyContinuation.body = outerBodyBuilder._root;
    // Note the order of continuations: the first one is the one that will
    // be filled by LetCont.plug.
    ir.LetCont branch =
        new ir.LetCont.two(exitContinuation, bodyContinuation,
            new ir.Branch(new ir.IsTrue(condition),
                          bodyContinuation,
                          exitContinuation));
    // If there are breaks in the body, then there must be a join-point
    // continuation for the normal exit and the breaks.  Otherwise, the
    // successor is translated in the hole in the exit continuation.
    bool hasBreaks = !breakCollector.isEmpty;
    ir.LetCont letBreak;
    if (hasBreaks) {
      IrBuilder exitBuilder = makeDelimitedBuilder();
      exitBuilder.jumpTo(breakCollector);
      exitContinuation.body = exitBuilder._root;
      letBreak = new ir.LetCont(breakCollector.continuation, branch);
      add(letBreak);
      environment = breakCollector.environment;
    } else {
      add(branch);
    }
  }

  /// Creates a for-in loop, `for (v in e) b`.
  ///
  /// [buildExpression] creates the expression, `e`. The variable, `v`, can
  /// take one of three forms:
  ///     1) `v` can be declared within the for-in statement, like in
  ///        `for (var v in e)`, in which case, [buildVariableDeclaration]
  ///        creates its declaration and [variableElement] is the element for
  ///        the declared variable,
  ///     2) `v` is predeclared statically known variable, that is top-level,
  ///        static, or local variable, in which case [variableElement] is the
  ///        variable element, and [variableSelector] defines its write access,
  ///     3) `v` is an instance variable in which case [variableSelector]
  ///        defines its write access.
  /// [buildBody] creates the body, `b`, of the loop. The jump [target] is used
  /// to identify which `break` and `continue` statements that have this for-in
  /// statement as their target.
  void buildForIn({SubbuildFunction buildExpression,
                   SubbuildFunction buildVariableDeclaration,
                   Element variableElement,
                   Selector variableSelector,
                   TypeMask variableMask,
                   TypeMask currentMask,
                   TypeMask iteratorMask,
                   TypeMask moveNextMask,
                   SubbuildFunction buildBody,
                   JumpTarget target,
                   ClosureScope closureScope}) {
    // The for-in loop
    //
    // for (a in e) s;
    //
    // Is compiled analogously to:
    //
    // it = e.iterator;
    // while (it.moveNext()) {
    //   var a = it.current;
    //   s;
    // }

    // Fill the current hole with:
    // let prim expressionReceiver = [[e]] in
    // let cont iteratorInvoked(iterator) =
    //     [ ]
    // in expressionReceiver.iterator () iteratorInvoked
    ir.Primitive expressionReceiver = buildExpression(this);
    List<ir.Primitive> emptyArguments = <ir.Primitive>[];
    ir.Parameter iterator = new ir.Parameter(null);
    ir.Continuation iteratorInvoked = new ir.Continuation([iterator]);
    add(new ir.LetCont(iteratorInvoked,
        new ir.InvokeMethod(expressionReceiver,
            Selectors.iterator,
            iteratorMask,
            emptyArguments,
            iteratorInvoked)));

    // Fill with:
    // let cont loop(x, ...) =
    //     let cont moveNextInvoked(condition) =
    //         [ ]
    //     in iterator.moveNext () moveNextInvoked
    // in loop(v, ...)
    JumpCollector loop = new BackwardJumpCollector(environment, target: target);
    addRecursiveContinuation(loop);
    ir.Parameter condition = new ir.Parameter(null);
    ir.Continuation moveNextInvoked = new ir.Continuation([condition]);
    add(new ir.LetCont(moveNextInvoked,
        new ir.InvokeMethod(iterator,
            Selectors.moveNext,
            moveNextMask,
            emptyArguments,
            moveNextInvoked)));

    // As a delimited term, build:
    // <<BODY>> =
    //   _enterScope();
    //   [[variableDeclaration]]
    //   let cont currentInvoked(currentValue) =
    //       [[a = currentValue]];
    //       [ ]
    //   in iterator.current () currentInvoked
    IrBuilder bodyBuilder = makeDelimitedBuilder();
    bodyBuilder._enterScope(closureScope);
    if (buildVariableDeclaration != null) {
      buildVariableDeclaration(bodyBuilder);
    }
    ir.Parameter currentValue = new ir.Parameter(null);
    ir.Continuation currentInvoked = new ir.Continuation([currentValue]);
    bodyBuilder.add(new ir.LetCont(currentInvoked,
        new ir.InvokeMethod(
            iterator,
            Selectors.current,
            currentMask,
            emptyArguments, currentInvoked)));
    // TODO(sra): Does this cover all cases? The general setter case include
    // super.
    // TODO(johnniwinther): Extract this as a provided strategy.
    if (Elements.isLocal(variableElement)) {
      bodyBuilder.buildLocalVariableSet(variableElement, currentValue);
    } else if (Elements.isErroneous(variableElement)) {
      bodyBuilder.buildErroneousInvocation(variableElement,
          new Selector.setter(
              new Name(variableElement.name, variableElement.library)),
          <ir.Primitive>[currentValue]);
    } else if (Elements.isStaticOrTopLevel(variableElement)) {
      if (variableElement.isField) {
        bodyBuilder.buildStaticFieldSet(variableElement, currentValue);
      } else {
        bodyBuilder.buildStaticSetterSet(variableElement, currentValue);
      }
    } else {
      ir.Primitive receiver = bodyBuilder.buildThis();
      assert(receiver != null);
      bodyBuilder.buildDynamicSet(
          receiver, variableSelector, variableMask, currentValue);
    }

    // Translate the body in the hole in the delimited term above, and add
    // a jump to the loop if control flow is live after the body.
    JumpCollector breakCollector =
        new ForwardJumpCollector(environment, target: target);
    state.breakCollectors.add(breakCollector);
    state.continueCollectors.add(loop);
    buildBody(bodyBuilder);
    assert(state.breakCollectors.last == breakCollector);
    assert(state.continueCollectors.last == loop);
    state.breakCollectors.removeLast();
    state.continueCollectors.removeLast();
    if (bodyBuilder.isOpen) bodyBuilder.jumpTo(loop);

    // Create body entry and loop exit continuations and a branch to them.
    //
    // let cont exit() = [ ]
    //      and body() = <<BODY>>
    // in branch condition (body, exit)
    ir.Continuation exitContinuation = new ir.Continuation([]);
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    bodyContinuation.body = bodyBuilder._root;
    // Note the order of continuations: the first one is the one that will
    // be filled by LetCont.plug.
    ir.LetCont branch =
        new ir.LetCont.two(exitContinuation, bodyContinuation,
            new ir.Branch(new ir.IsTrue(condition),
                          bodyContinuation,
                          exitContinuation));
    // If there are breaks in the body, then there must be a join-point
    // continuation for the normal exit and the breaks.  Otherwise, the
    // successor is translated in the hole in the exit continuation.
    bool hasBreaks = !breakCollector.isEmpty;
    ir.LetCont letBreak;
    if (hasBreaks) {
      IrBuilder exitBuilder = makeDelimitedBuilder();
      exitBuilder.jumpTo(breakCollector);
      exitContinuation.body = exitBuilder._root;
      letBreak = new ir.LetCont(breakCollector.continuation, branch);
      add(letBreak);
      environment = breakCollector.environment;
    } else {
      add(branch);
    }
  }

  /// Creates a while loop in which the condition and body are created by
  /// [buildCondition] and [buildBody], respectively.
  ///
  /// The jump [target] is used to identify which `break` and `continue`
  /// statements that have this `while` statement as their target.
  void buildWhile({SubbuildFunction buildCondition,
                   SubbuildFunction buildBody,
                   JumpTarget target,
                   ClosureScope closureScope}) {
    assert(isOpen);
    // While loops use four named continuations: the entry to the body, the
    // loop exit, the loop back edge (continue), and the loop exit (break).
    // The CPS translation of [[while (condition) body; successor]] is:
    //
    // let cont continue(x, ...) =
    //     let prim cond = [[condition]] in
    //     let cont break(x, ...) = [[successor]] in
    //     let cont exit() = break(v, ...)
    //          and body() =
    //                _enterScope();
    //                [[body]];
    //                continue(v, ...)
    //     in branch cond (body, exit)
    // in continue(v, ...)
    //
    // If there are no breaks in the body, the break continuation is inlined
    // in the exit continuation (i.e., the translation of the successor
    // statement occurs in the exit continuation).
    JumpCollector loop = new BackwardJumpCollector(environment, target: target);
    addRecursiveContinuation(loop);

    ir.Primitive condition = buildCondition(this);

    JumpCollector breakCollector =
        new ForwardJumpCollector(environment, target: target);

    IrBuilder bodyBuilder = makeDelimitedBuilder();
    bodyBuilder._enterScope(closureScope);
    state.breakCollectors.add(breakCollector);
    state.continueCollectors.add(loop);
    buildBody(bodyBuilder);
    assert(state.breakCollectors.last == breakCollector);
    assert(state.continueCollectors.last == loop);
    state.breakCollectors.removeLast();
    state.continueCollectors.removeLast();
    if (bodyBuilder.isOpen) bodyBuilder.jumpTo(loop);

    // Create body entry and loop exit continuations and a branch to them.
    ir.Continuation exitContinuation = new ir.Continuation([]);
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    bodyContinuation.body = bodyBuilder._root;
    // Note the order of continuations: the first one is the one that will
    // be filled by LetCont.plug.
    ir.LetCont branch =
        new ir.LetCont.two(exitContinuation, bodyContinuation,
            new ir.Branch(new ir.IsTrue(condition),
                          bodyContinuation,
                          exitContinuation));
    // If there are breaks in the body, then there must be a join-point
    // continuation for the normal exit and the breaks.  Otherwise, the
    // successor is translated in the hole in the exit continuation.
    bool hasBreaks = !breakCollector.isEmpty;
    ir.LetCont letBreak;
    if (hasBreaks) {
      IrBuilder exitBuilder = makeDelimitedBuilder();
      exitBuilder.jumpTo(breakCollector);
      exitContinuation.body = exitBuilder._root;
      letBreak = new ir.LetCont(breakCollector.continuation, branch);
      add(letBreak);
      environment = breakCollector.environment;
    } else {
      add(branch);
    }
  }


  /// Creates a do-while loop.
  ///
  /// The body and condition are created by [buildBody] and [buildCondition].
  /// The jump target [target] is the target of `break` and `continue`
  /// statements in the body that have the loop as their target.
  /// [closureScope] contains all the variables declared in the loop (but not
  /// declared in some inner closure scope).
  void buildDoWhile({SubbuildFunction buildBody,
                     SubbuildFunction buildCondition,
                     JumpTarget target,
                     ClosureScope closureScope}) {
    assert(isOpen);
    // The CPS translation of [[do body; while (condition); successor]] is:
    //
    // let cont break(x, ...) = [[successor]] in
    // let cont rec loop(x, ...) =
    //   let cont continue(x, ...) =
    //     let prim cond = [[condition]] in
    //       let cont exit() = break(v, ...)
    //            and repeat() = loop(v, ...)
    //       in branch cond (repeat, exit)
    //   in [[body]]; continue(v, ...)
    // in loop(v, ...)
    IrBuilder loopBuilder = makeDelimitedBuilder();
    JumpCollector loop =
        new BackwardJumpCollector(loopBuilder.environment, target: target);
    loopBuilder.addRecursiveContinuation(loop);

    // Translate the body.
    JumpCollector breakCollector =
        new ForwardJumpCollector(environment, target: target);
    JumpCollector continueCollector =
        new ForwardJumpCollector(loopBuilder.environment, target: target);
    IrBuilder bodyBuilder = loopBuilder.makeDelimitedBuilder();
    bodyBuilder._enterScope(closureScope);
    state.breakCollectors.add(breakCollector);
    state.continueCollectors.add(continueCollector);
    buildBody(bodyBuilder);
    assert(state.breakCollectors.last == breakCollector);
    assert(state.continueCollectors.last == continueCollector);
    state.breakCollectors.removeLast();
    state.continueCollectors.removeLast();
    if (bodyBuilder.isOpen) bodyBuilder.jumpTo(continueCollector);

    // Construct the body of the continue continuation (i.e., the condition).
    // <Continue> =
    // let prim cond = [[condition]] in
    //   let cont exit() = break(v, ...)
    //        and repeat() = loop(v, ...)
    //   in branch cond (repeat, exit)
    IrBuilder continueBuilder = loopBuilder.makeDelimitedBuilder();
    continueBuilder.environment = continueCollector.environment;
    ir.Primitive condition = buildCondition(continueBuilder);

    ir.Continuation exitContinuation = new ir.Continuation([]);
    IrBuilder exitBuilder = continueBuilder.makeDelimitedBuilder();
    exitBuilder.jumpTo(breakCollector);
    exitContinuation.body = exitBuilder._root;
    ir.Continuation repeatContinuation = new ir.Continuation([]);
    IrBuilder repeatBuilder = continueBuilder.makeDelimitedBuilder();
    repeatBuilder.jumpTo(loop);
    repeatContinuation.body = repeatBuilder._root;

    continueBuilder.add(
        new ir.LetCont.two(exitContinuation, repeatContinuation,
            new ir.Branch(new ir.IsTrue(condition),
                          repeatContinuation,
                          exitContinuation)));
    continueCollector.continuation.body = continueBuilder._root;

    // Construct the loop continuation (i.e., the body and condition).
    // <Loop> =
    // let cont continue(x, ...) =
    //   <Continue>
    // in [[body]]; continue(v, ...)
    loopBuilder.add(
        new ir.LetCont(continueCollector.continuation,
            bodyBuilder._root));

    // And tie it all together.
    add(new ir.LetCont(breakCollector.continuation, loopBuilder._root));
    environment = breakCollector.environment;
  }

  void buildSimpleSwitch(JumpTarget target,
                         ir.Primitive value,
                         List<SwitchCaseInfo> cases,
                         SwitchCaseInfo defaultCase,
                         Element error,
                         SourceInformation sourceInformation) {
    assert(isOpen);
    JumpCollector join = new ForwardJumpCollector(environment, target: target);

    IrBuilder casesBuilder = makeDelimitedBuilder();
    casesBuilder.state.breakCollectors.add(join);
    for (SwitchCaseInfo caseInfo in cases) {
      buildConditionsFrom(int index) => (IrBuilder builder) {
        ir.Primitive comparison = builder.buildIdentical(
            value, caseInfo.constants[index]);
        return (index == caseInfo.constants.length - 1)
            ? comparison
            : builder.buildLogicalOperator(
                comparison, buildConditionsFrom(index + 1), isLazyOr: true);
      };

      ir.Primitive condition = buildConditionsFrom(0)(casesBuilder);
      IrBuilder thenBuilder = makeDelimitedBuilder();
      caseInfo.buildBody(thenBuilder);
      if (thenBuilder.isOpen) {
        // It is a runtime error to reach the end of a switch case, unless
        // it is the last case.
        if (caseInfo == cases.last && defaultCase == null) {
          thenBuilder.jumpTo(join);
        } else {
          ir.Primitive exception = thenBuilder._buildInvokeStatic(
              error,
              new Selector.fromElement(error),
              <ir.Primitive>[],
              sourceInformation);
          thenBuilder.buildThrow(exception);
        }
      }

      ir.Continuation thenContinuation = new ir.Continuation([]);
      thenContinuation.body = thenBuilder._root;
      ir.Continuation elseContinuation = new ir.Continuation([]);
      // A LetCont.many term has a hole as the body of the first listed
      // continuation, to be plugged by the translation.  Therefore put the
      // else continuation first.
      casesBuilder.add(
          new ir.LetCont.two(elseContinuation, thenContinuation,
              new ir.Branch(new ir.IsTrue(condition),
                            thenContinuation,
                            elseContinuation)));
    }

    if (defaultCase != null) {
      defaultCase.buildBody(casesBuilder);
    }
    if (casesBuilder.isOpen) casesBuilder.jumpTo(join);

    casesBuilder.state.breakCollectors.removeLast();

    if (!join.isEmpty) {
      add(new ir.LetCont(join.continuation, casesBuilder._root));
      environment = join.environment;
    } else if (casesBuilder._root != null) {
      add(casesBuilder._root);
      _current = casesBuilder._current;
      environment = casesBuilder.environment;
    } else {
      // The translation of the cases did not emit any code.
    }
  }

  /// Utility function to translate try/catch into the IR.
  ///
  /// The translation treats try/finally and try/catch/finally as if they
  /// were macro-expanded into try/catch.  This utility function generates
  /// that try/catch.  The function is parameterized over a list of variables
  /// that should be boxed on entry to the try, and over functions to emit
  /// code for entering the try, building the try body, leaving the try body,
  /// building the catch body, and leaving the entire try/catch.
  ///
  /// Please see the function's implementation for where these functions are
  /// called.
  void _helpBuildTryCatch(TryStatementInfo variables,
      void enterTry(IrBuilder builder),
      SubbuildFunction buildTryBlock,
      void leaveTry(IrBuilder builder),
      List<ir.Parameter> buildCatch(IrBuilder builder, JumpCollector join),
      void leaveTryCatch(IrBuilder builder, JumpCollector join,
          ir.Expression body)) {
    JumpCollector join = new ForwardJumpCollector(environment);
    IrBuilder tryCatchBuilder = makeDelimitedBuilder();

    // Variables treated as mutable in a try are not mutable outside of it.
    // Work with a copy of the outer builder's mutable variables.
    tryCatchBuilder.mutableVariables =
        new Map<Local, ir.MutableVariable>.from(mutableVariables);
    for (LocalVariableElement variable in variables.boxedOnEntry) {
      assert(!tryCatchBuilder.isInMutableVariable(variable));
      ir.Primitive value = tryCatchBuilder.buildLocalVariableGet(variable);
      tryCatchBuilder.makeMutableVariable(variable);
      tryCatchBuilder.declareLocalVariable(variable, initialValue: value);
    }

    IrBuilder tryBuilder = tryCatchBuilder.makeDelimitedBuilder();
    enterTry(tryBuilder);
    buildTryBlock(tryBuilder);
    if (tryBuilder.isOpen) {
      join.enterTry(variables.boxedOnEntry);
      tryBuilder.jumpTo(join);
      join.leaveTry();
    }
    leaveTry(tryBuilder);

    IrBuilder catchBuilder = tryCatchBuilder.makeDelimitedBuilder();
    for (LocalVariableElement variable in variables.boxedOnEntry) {
      assert(catchBuilder.isInMutableVariable(variable));
      ir.Primitive value = catchBuilder.buildLocalVariableGet(variable);
      // After this point, the variables that were boxed on entry to the try
      // are no longer treated as mutable.
      catchBuilder.removeMutableVariable(variable);
      catchBuilder.environment.update(variable, value);
    }

    List<ir.Parameter> catchParameters = buildCatch(catchBuilder, join);
    ir.Continuation catchContinuation = new ir.Continuation(catchParameters);
    catchContinuation.body = catchBuilder._root;
    tryCatchBuilder.add(
        new ir.LetHandler(catchContinuation, tryBuilder._root));

    leaveTryCatch(this, join, tryCatchBuilder._root);
  }

  /// Translates a try/catch.
  ///
  /// [variables] provides information on local variables declared and boxed
  /// within the try body.
  /// [buildTryBlock] builds the try block.
  /// [catchClauseInfos] provides access to the catch type, exception variable,
  /// and stack trace variable, and a function for building the catch block.
  void buildTryCatch(TryStatementInfo variables,
                     SubbuildFunction buildTryBlock,
                     List<CatchClauseInfo> catchClauseInfos) {
    assert(isOpen);
    // Catch handlers are in scope for their body.  The CPS translation of
    // [[try tryBlock catch (ex, st) catchBlock; successor]] is:
    //
    // let cont join(v0, v1, ...) = [[successor]] in
    //   let mutable m0 = x0 in
    //     let mutable m1 = x1 in
    //       ...
    //       let handler catch_(ex, st) =
    //         let prim p0 = GetMutable(m0) in
    //           let prim p1 = GetMutable(m1) in
    //             ...
    //             [[catchBlock]]
    //             join(p0, p1, ...)
    //       in
    //         [[tryBlock]]
    //         let prim p0' = GetMutable(m0) in
    //           let prim p1' = GetMutable(m1) in
    //             ...
    //             join(p0', p1', ...)
    //
    // In other words, both the try and catch block are in the scope of the
    // join-point continuation, and they are both in the scope of a sequence
    // of mutable bindings for the variables assigned in the try.  The join-
    // point continuation is not in the scope of these mutable bindings.
    // The tryBlock is in the scope of a binding for the catch handler.  Each
    // instruction (specifically, each call) in the tryBlock is in the dynamic
    // scope of the handler.  The mutable bindings are dereferenced at the end
    // of the try block and at the beginning of the catch block, so the
    // variables are unboxed in the catch block and at the join point.

    void enterTry(IrBuilder builder) {
      // On entry to try of try/catch, update the builder's state to reflect the
      // variables that have been boxed.
      void interceptJump(JumpCollector collector) {
        collector.enterTry(variables.boxedOnEntry);
      }
      builder.state.breakCollectors.forEach(interceptJump);
      builder.state.continueCollectors.forEach(interceptJump);
    }

    void leaveTry(IrBuilder builder) {
      // On exit from try of try/catch, update the builder's state to reflect
      // the variables that are no longer boxed.
      void restoreJump(JumpCollector collector) {
        collector.leaveTry();
      }
      builder.state.breakCollectors.forEach(restoreJump);
      builder.state.continueCollectors.forEach(restoreJump);
    }

    List<ir.Parameter> buildCatch(IrBuilder builder,
                                  JumpCollector join) {
      // Translate the catch clauses.  Multiple clauses are translated as if
      // they were explicitly cascaded if/else type tests.

      // Handlers are always translated as having both exception and stack trace
      // parameters.  Multiple clauses do not have to use the same names for
      // them.  Choose the first of each as the name hint for the respective
      // handler parameter.
      ir.Parameter exceptionParameter =
          new ir.Parameter(catchClauseInfos.first.exceptionVariable);
      LocalVariableElement traceVariable;
      CatchClauseInfo catchAll;
      for (int i = 0; i < catchClauseInfos.length; ++i) {
        CatchClauseInfo info = catchClauseInfos[i];
        if (info.type == null) {
          catchAll = info;
          catchClauseInfos.length = i;
          break;
        }
        if (traceVariable == null) {
          traceVariable = info.stackTraceVariable;
        }
      }
      ir.Parameter traceParameter = new ir.Parameter(traceVariable);

      ir.Expression buildCatchClause(CatchClauseInfo clause) {
        IrBuilder clauseBuilder = builder.makeDelimitedBuilder();
        if (clause.exceptionVariable != null) {
          clauseBuilder.declareLocalVariable(clause.exceptionVariable,
              initialValue: exceptionParameter);
        }
        if (clause.stackTraceVariable != null) {
          clauseBuilder.declareLocalVariable(clause.stackTraceVariable,
              initialValue: traceParameter);
        }
        clause.buildCatchBlock(clauseBuilder);
        if (clauseBuilder.isOpen) clauseBuilder.jumpTo(join);
        return clauseBuilder._root;
      }

      // Expand multiple catch clauses into an explicit if/then/else.  Iterate
      // them in reverse so the current block becomes the next else block.
      ir.Expression catchBody = (catchAll == null)
          ? new ir.Rethrow()
          : buildCatchClause(catchAll);
      for (CatchClauseInfo clause in catchClauseInfos.reversed) {
        ir.Continuation thenContinuation = new ir.Continuation([]);
        ir.Continuation elseContinuation = new ir.Continuation([]);
        thenContinuation.body = buildCatchClause(clause);
        elseContinuation.body = catchBody;

        // Build the type test guarding this clause. We can share the
        // environment with the nested builder because this part cannot mutate
        // it.
        IrBuilder checkBuilder = builder.makeDelimitedBuilder(environment);
        ir.Primitive typeMatches =
            checkBuilder.buildTypeOperator(exceptionParameter,
                clause.type,
                isTypeTest: true);
        checkBuilder.add(new ir.LetCont.two(thenContinuation, elseContinuation,
                new ir.Branch(new ir.IsTrue(typeMatches),
                    thenContinuation,
                    elseContinuation)));
        catchBody = checkBuilder._root;
      }
      builder.add(catchBody);

      return <ir.Parameter>[exceptionParameter, traceParameter];
    }

    void leaveTryCatch(IrBuilder builder, JumpCollector join,
                       ir.Expression body) {
      // Add the binding for the join-point continuation and continue the
      // translation in its body.
      builder.add(new ir.LetCont(join.continuation, body));
      builder.environment = join.environment;
    }

    _helpBuildTryCatch(variables, enterTry, buildTryBlock, leaveTry,
        buildCatch, leaveTryCatch);
  }

  /// Translates a try/finally.
  ///
  /// [variables] provides information on local variables declared and boxed
  /// within the try body.
  /// [buildTryBlock] builds the try block.
  /// [buildFinallyBlock] builds the finally block.
  void buildTryFinally(TryStatementInfo variables,
                       SubbuildFunction buildTryBlock,
                       SubbuildFunction buildFinallyBlock) {
    assert(isOpen);
    // Try/finally is implemented in terms of try/catch and by duplicating the
    // code for finally at all exits.  The encoding is:
    //
    // try tryBlock finally finallyBlock
    // ==>
    // try tryBlock catch (ex, st) { finallyBlock; rethrow } finallyBlock
    //
    // Where in tryBlock, all of the break, continue, and return exits are
    // translated as jumps to continuations (bound outside the catch handler)
    // that include the finally code followed by a break, continue, or
    // return respectively.

    List<JumpCollector> savedBreaks, newBreaks, savedContinues, newContinues;
    JumpCollector savedReturn, newReturn;
    void enterTry(IrBuilder builder) {
      // On entry to the try of try/finally, update the builder's state to
      // relfect the variables that have been boxed.  Then intercept all break,
      // continue, and return jumps out of the try so that they can go to
      // continuations that include the finally code.
      JumpCollector interceptJump(JumpCollector collector) {
        JumpCollector result =
            new ForwardJumpCollector(environment, target: collector.target);
        result.enterTry(variables.boxedOnEntry);
        return result;
      }
      savedBreaks = builder.state.breakCollectors;
      savedContinues = builder.state.continueCollectors;
      savedReturn = builder.state.returnCollector;

      builder.state.breakCollectors = newBreaks =
          savedBreaks.map(interceptJump).toList();
      builder.state.continueCollectors = newContinues =
          savedContinues.map(interceptJump).toList();
      builder.state.returnCollector = newReturn =
          new ForwardJumpCollector(environment, hasExtraArgument: true)
              ..enterTry(variables.boxedOnEntry);
    }

    void leaveTry(IrBuilder builder) {
      // On exit from the try of try/finally, update the builder's state to
      // reflect the variables that are no longer boxed and restore the
      // original, unintercepted break, continue, and return targets.
      void restoreJump(JumpCollector collector) {
        collector.leaveTry();
      }
      newBreaks.forEach(restoreJump);
      newContinues.forEach(restoreJump);
      newReturn.leaveTry();
      builder.state.breakCollectors = savedBreaks;
      builder.state.continueCollectors = savedContinues;
      builder.state.returnCollector = savedReturn;
    }

    List<ir.Parameter> buildCatch(IrBuilder builder,
                                  JumpCollector join) {
      // The catch block of the try/catch used for try/finally is the finally
      // code followed by a rethrow.
      buildFinallyBlock(builder);
      if (builder.isOpen) {
        builder.add(new ir.Rethrow());
        builder._current = null;
      }
      return <ir.Parameter>[new ir.Parameter(null), new ir.Parameter(null)];
    }

    void leaveTryCatch(IrBuilder builder, JumpCollector join,
                       ir.Expression body) {
      // Build a list of continuations for jumps from the try block and
      // duplicate the finally code before jumping to the actual target.
      List<ir.Continuation> exits = <ir.Continuation>[join.continuation];
      void addJump(JumpCollector newCollector,
                   JumpCollector originalCollector) {
        if (newCollector.isEmpty) return;
        IrBuilder builder = makeDelimitedBuilder(newCollector.environment);
        buildFinallyBlock(builder);
        if (builder.isOpen) builder.jumpTo(originalCollector);
        newCollector.continuation.body = builder._root;
        exits.add(newCollector.continuation);
      }
      for (int i = 0; i < newBreaks.length; ++i) {
        addJump(newBreaks[i], savedBreaks[i]);
      }
      for (int i = 0; i < newContinues.length; ++i) {
        addJump(newContinues[i], savedContinues[i]);
      }
      if (!newReturn.isEmpty) {
        IrBuilder builder = makeDelimitedBuilder(newReturn.environment);
        ir.Primitive value = builder.environment.discard(1);
        buildFinallyBlock(builder);
        if (builder.isOpen) builder.buildReturn(value: value);
        newReturn.continuation.body = builder._root;
        exits.add(newReturn.continuation);
      }
      builder.add(new ir.LetCont.many(exits, body));
      builder.environment = join.environment;
      buildFinallyBlock(builder);
    }

    _helpBuildTryCatch(variables, enterTry, buildTryBlock, leaveTry,
        buildCatch, leaveTryCatch);
  }

  /// Create a return statement `return value;` or `return;` if [value] is
  /// null.
  void buildReturn({ir.Primitive value, SourceInformation sourceInformation}) {
    // Build(Return(e), C) = C'[InvokeContinuation(return, x)]
    //   where (C', x) = Build(e, C)
    //
    // Return without a subexpression is translated as if it were return null.
    assert(isOpen);
    if (value == null) {
      value = buildNullConstant();
    }
    if (state.returnCollector == null) {
      add(new ir.InvokeContinuation(state.returnContinuation, [value],
              sourceInformation: sourceInformation));
      _current = null;
    } else {
      // Inside the try block of try/finally, all returns go to a join-point
      // continuation that contains the finally code.  The return value is
      // passed as an extra argument.
      jumpTo(state.returnCollector, value);
    }
  }

  /// Build a call to the closure conversion helper for the [Function] typed
  /// value in [value].
  ir.Primitive _convertDartClosure(ir.Primitive value, FunctionType type) {
    ir.Constant arity = buildIntegerConstant(type.computeArity());
    return buildStaticFunctionInvocation(
        program.closureConverter,
        CallStructure.TWO_ARGS,
        <ir.Primitive>[value, arity]);
  }

  /// Generate the body for a native function [function] that is annotated with
  /// an implementation in JavaScript (provided as string in [javaScriptCode]).
  void buildNativeFunctionBody(FunctionElement function,
                               String javaScriptCode) {
    NativeBehavior behavior = new NativeBehavior();
    behavior.sideEffects.setAllSideEffects();
    // Generate a [ForeignCode] statement from the given native code.
    buildForeignCode(
        js.js.statementTemplateYielding(
            new js.LiteralStatement(javaScriptCode)),
        <ir.Primitive>[],
        behavior);
  }

  /// Generate the body for a native function that redirects to a native
  /// JavaScript function, getter, or setter.
  ///
  /// Generates a call to the real target, which is given by [functions]'s
  /// `fixedBackendName`, passing all parameters as arguments.  The target can
  /// be the JavaScript implementation of a function, getter, or setter.
  void buildRedirectingNativeFunctionBody(FunctionElement function,
                                          SourceInformation source) {
    String name = function.fixedBackendName;
    List<ir.Primitive> arguments = <ir.Primitive>[];
    NativeBehavior behavior = new NativeBehavior();
    behavior.sideEffects.setAllSideEffects();
    program.addNativeMethod(function);
    // Construct the access of the target element.
    String code = function.isInstanceMember ? '#.$name' : name;
    if (function.isInstanceMember) {
      arguments.add(state.thisParameter);
    }
    // Collect all parameters of the function and templates for them to be
    // inserted into the JavaScript code.
    List<String> argumentTemplates = <String>[];
    function.functionSignature.forEachParameter((ParameterElement parameter) {
      ir.Primitive input = environment.lookup(parameter);
      DartType type = program.unaliasType(parameter.type);
      if (type is FunctionType) {
        // The parameter type is a function type either directly or through
        // typedef(s).
        input = _convertDartClosure(input, type);
      }
      arguments.add(input);
      argumentTemplates.add('#');
    });
    // Construct the application of parameters for functions and setters.
    if (function.kind == ElementKind.FUNCTION) {
      code = "$code(${argumentTemplates.join(', ')})";
    } else if (function.kind == ElementKind.SETTER) {
      code = "$code = ${argumentTemplates.single}";
    } else {
      assert(argumentTemplates.isEmpty);
      assert(function.kind == ElementKind.GETTER);
    }
    // Generate the [ForeignCode] expression and a return statement to return
    // its value.
    ir.Primitive value = buildForeignCode(
        js.js.uncachedExpressionTemplate(code),
        arguments,
        behavior);
    buildReturn(value: value, sourceInformation: source);
  }

  /// Create a blocks of [statements] by applying [build] to all reachable
  /// statements. The first statement is assumed to be reachable.
  // TODO(johnniwinther): Type [statements] as `Iterable` when `NodeList` uses
  // `List` instead of `Link`.
  void buildBlock(var statements, BuildFunction build) {
    // Build(Block(stamements), C) = C'
    //   where C' = statements.fold(Build, C)
    assert(isOpen);
    return buildSequence(statements, build);
  }

  /// Creates a sequence of [nodes] by applying [build] to all reachable nodes.
  ///
  /// The first node in the sequence does not need to be reachable.
  // TODO(johnniwinther): Type [nodes] as `Iterable` when `NodeList` uses
  // `List` instead of `Link`.
  void buildSequence(var nodes, BuildFunction build) {
    for (var node in nodes) {
      if (!isOpen) return;
      build(node);
    }
  }

  /// Creates a labeled statement
  void buildLabeledStatement({SubbuildFunction buildBody,
                              JumpTarget target}) {
    JumpCollector join = new ForwardJumpCollector(environment, target: target);
    IrBuilder innerBuilder = makeDelimitedBuilder();
    innerBuilder.state.breakCollectors.add(join);
    buildBody(innerBuilder);
    innerBuilder.state.breakCollectors.removeLast();
    bool hasBreaks = !join.isEmpty;
    if (hasBreaks) {
      if (innerBuilder.isOpen) innerBuilder.jumpTo(join);
      add(new ir.LetCont(join.continuation, innerBuilder._root));
      environment = join.environment;
    } else if (innerBuilder._root != null) {
      add(innerBuilder._root);
      _current = innerBuilder._current;
      environment = innerBuilder.environment;
    } else {
      // The translation of the body did not emit any CPS term.
    }
  }

  // Build(BreakStatement L, C) = C[InvokeContinuation(...)]
  //
  // The continuation and arguments are filled in later after translating
  // the body containing the break.
  bool buildBreak(JumpTarget target) {
    return buildJumpInternal(target, state.breakCollectors);
  }

  // Build(ContinueStatement L, C) = C[InvokeContinuation(...)]
  //
  // The continuation and arguments are filled in later after translating
  // the body containing the continue.
  bool buildContinue(JumpTarget target) {
    return buildJumpInternal(target, state.continueCollectors);
  }

  bool buildJumpInternal(JumpTarget target,
                         Iterable<JumpCollector> collectors) {
    assert(isOpen);
    for (JumpCollector collector in collectors) {
      if (target == collector.target) {
        jumpTo(collector);
        return true;
      }
    }
    return false;
  }

  void buildThrow(ir.Primitive value) {
    assert(isOpen);
    add(new ir.Throw(value));
    _current = null;
  }

  ir.Primitive buildNonTailThrow(ir.Primitive value) {
    assert(isOpen);
    ir.Parameter param = new ir.Parameter(null);
    ir.Continuation cont = new ir.Continuation(<ir.Parameter>[param]);
    add(new ir.LetCont(cont, new ir.Throw(value)));
    return param;
  }

  void buildRethrow() {
    assert(isOpen);
    add(new ir.Rethrow());
    _current = null;
  }

  /// Create a negation of [condition].
  ir.Primitive buildNegation(ir.Primitive condition) {
    // ! e is translated as e ? false : true

    // Add a continuation parameter for the result of the expression.
    ir.Parameter resultParameter = new ir.Parameter(null);

    ir.Continuation joinContinuation = new ir.Continuation([resultParameter]);
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);

    ir.Constant makeBoolConstant(bool value) {
      return new ir.Constant(state.constantSystem.createBool(value));
    }

    ir.Constant trueConstant = makeBoolConstant(true);
    ir.Constant falseConstant = makeBoolConstant(false);

    thenContinuation.body = new ir.LetPrim(falseConstant)
        ..plug(new ir.InvokeContinuation(joinContinuation, [falseConstant]));
    elseContinuation.body = new ir.LetPrim(trueConstant)
        ..plug(new ir.InvokeContinuation(joinContinuation, [trueConstant]));

    add(new ir.LetCont(joinContinuation,
          new ir.LetCont.two(thenContinuation, elseContinuation,
              new ir.Branch(new ir.IsTrue(condition),
                            thenContinuation,
                            elseContinuation))));
    return resultParameter;
  }

  /// Create a lazy and/or expression. [leftValue] is the value of the left
  /// operand and [buildRightValue] is called to process the value of the right
  /// operand in the context of its own [IrBuilder].
  ir.Primitive buildLogicalOperator(
      ir.Primitive leftValue,
      ir.Primitive buildRightValue(IrBuilder builder),
      {bool isLazyOr: false}) {
    // e0 && e1 is translated as if e0 ? (e1 == true) : false.
    // e0 || e1 is translated as if e0 ? true : (e1 == true).
    // The translation must convert both e0 and e1 to booleans and handle
    // local variable assignments in e1.
    IrBuilder rightBuilder = makeDelimitedBuilder();
    ir.Primitive rightValue = buildRightValue(rightBuilder);
    // A dummy empty target for the branch on the left subexpression branch.
    // This enables using the same infrastructure for join-point continuations
    // as in visitIf and visitConditional.  It will hold a definition of the
    // appropriate constant and an invocation of the join-point continuation.
    IrBuilder emptyBuilder = makeDelimitedBuilder();
    // Dummy empty targets for right true and right false.  They hold
    // definitions of the appropriate constant and an invocation of the
    // join-point continuation.
    IrBuilder rightTrueBuilder = rightBuilder.makeDelimitedBuilder();
    IrBuilder rightFalseBuilder = rightBuilder.makeDelimitedBuilder();

    // If we don't evaluate the right subexpression, the value of the whole
    // expression is this constant.
    ir.Constant leftBool = emptyBuilder.buildBooleanConstant(isLazyOr);
    // If we do evaluate the right subexpression, the value of the expression
    // is a true or false constant.
    ir.Constant rightTrue = rightTrueBuilder.buildBooleanConstant(true);
    ir.Constant rightFalse = rightFalseBuilder.buildBooleanConstant(false);

    // Result values are passed as continuation arguments, which are
    // constructed based on environments.  These assertions are a sanity check.
    assert(environment.length == emptyBuilder.environment.length);
    assert(environment.length == rightTrueBuilder.environment.length);
    assert(environment.length == rightFalseBuilder.environment.length);

    // Wire up two continuations for the left subexpression, two continuations
    // for the right subexpression, and a three-way join continuation.
    JumpCollector join =
        new ForwardJumpCollector(environment, hasExtraArgument: true);
    emptyBuilder.jumpTo(join, leftBool);
    rightTrueBuilder.jumpTo(join, rightTrue);
    rightFalseBuilder.jumpTo(join, rightFalse);
    ir.Continuation leftTrueContinuation = new ir.Continuation([]);
    ir.Continuation leftFalseContinuation = new ir.Continuation([]);
    ir.Continuation rightTrueContinuation = new ir.Continuation([]);
    ir.Continuation rightFalseContinuation = new ir.Continuation([]);
    rightTrueContinuation.body = rightTrueBuilder._root;
    rightFalseContinuation.body = rightFalseBuilder._root;
    // The right subexpression has two continuations.
    rightBuilder.add(
        new ir.LetCont.two(rightTrueContinuation, rightFalseContinuation,
            new ir.Branch(new ir.IsTrue(rightValue),
                          rightTrueContinuation,
                          rightFalseContinuation)));
    // Depending on the operator, the left subexpression's continuations are
    // either the right subexpression or an invocation of the join-point
    // continuation.
    if (isLazyOr) {
      leftTrueContinuation.body = emptyBuilder._root;
      leftFalseContinuation.body = rightBuilder._root;
    } else {
      leftTrueContinuation.body = rightBuilder._root;
      leftFalseContinuation.body = emptyBuilder._root;
    }

    add(new ir.LetCont(join.continuation,
            new ir.LetCont.two(leftTrueContinuation, leftFalseContinuation,
                new ir.Branch(new ir.IsTrue(leftValue),
                              leftTrueContinuation,
                              leftFalseContinuation))));
    environment = join.environment;
    return environment.discard(1);
  }

  ir.Primitive buildIdentical(ir.Primitive x, ir.Primitive y,
                              {SourceInformation sourceInformation}) {
    return addPrimitive(new ir.ApplyBuiltinOperator(
        ir.BuiltinOperator.Identical, <ir.Primitive>[x, y],
        sourceInformation));
  }

  /// Called when entering a nested function with free variables.
  ///
  /// The free variables must subsequently be accessible using [buildLocalGet]
  /// and [buildLocalSet].
  void _enterClosureEnvironment(ClosureEnvironment env) {
    if (env == null) return;

    // Obtain a reference to the function object (this).
    ir.Parameter thisPrim = state.thisParameter;

    // Obtain access to the free variables.
    env.freeVariables.forEach((Local local, ClosureLocation location) {
      if (location.isBox) {
        // Boxed variables are loaded from their box on-demand.
        state.boxedVariables[local] = location;
      } else {
        // Unboxed variables are loaded from the function object immediately.
        // This includes BoxLocals which are themselves unboxed variables.
        environment.extend(local,
            addPrimitive(new ir.GetField(thisPrim, location.field)));
      }
    });

    // If the function captures a reference to the receiver from the
    // enclosing method, remember which primitive refers to the receiver object.
    if (env.thisLocal != null && env.freeVariables.containsKey(env.thisLocal)) {
      state.enclosingThis = environment.lookup(env.thisLocal);
    }

    // If the function has a self-reference, use the value of `this`.
    if (env.selfReference != null) {
      environment.extend(env.selfReference, thisPrim);
    }
  }

  /// Creates a box for [scope.box] and binds the captured variables to
  /// that box.
  ///
  /// The captured variables can subsequently be manipulated with
  /// [declareLocalVariable], [buildLocalGet], and [buildLocalSet].
  void enterScope(ClosureScope scope) => _enterScope(scope);

  /// Called when entering a function body or loop body.
  ///
  /// This is not called for for-loops, which instead use the methods
  /// [_enterForLoopInitializer], [_enterForLoopBody], and [_enterForLoopUpdate]
  /// due to their special scoping rules.
  ///
  /// The boxed variables declared in this scope must subsequently be available
  /// using [buildLocalGet], [buildLocalSet], etc.
  void _enterScope(ClosureScope scope) {
    if (scope == null) return;
    ir.CreateBox boxPrim = addPrimitive(new ir.CreateBox());
    environment.extend(scope.box, boxPrim);
    boxPrim.useElementAsHint(scope.box);
    scope.capturedVariables.forEach((Local local, ClosureLocation location) {
      assert(!state.boxedVariables.containsKey(local));
      if (location.isBox) {
        state.boxedVariables[local] = location;
      }
    });
  }

  /// Add the given function parameter to the IR, and bind it in the environment
  /// or put it in its box, if necessary.
  void _createFunctionParameter(Local parameterElement) {
    ir.Parameter parameter = new ir.Parameter(parameterElement);
    _parameters.add(parameter);
    state.functionParameters.add(parameter);
    ClosureLocation location = state.boxedVariables[parameterElement];
    if (location != null) {
      addPrimitive(new ir.SetField(
          environment.lookup(location.box),
          location.field,
          parameter));
    } else {
      environment.extend(parameterElement, parameter);
    }
  }

  void _createThisParameter() {
    assert(state.thisParameter == null);
    if (Elements.isStaticOrTopLevel(state.currentElement)) return;
    if (state.currentElement.isLocal) return;
    state.thisParameter =
        new ir.Parameter(new ThisParameterLocal(state.currentElement));
  }

  void declareLocalVariable(LocalElement variableElement,
                            {ir.Primitive initialValue}) {
    assert(isOpen);
    if (initialValue == null) {
      initialValue = buildNullConstant();
    }
    ClosureLocation location = state.boxedVariables[variableElement];
    if (location != null) {
      addPrimitive(new ir.SetField(
          environment.lookup(location.box),
          location.field,
          initialValue));
    } else if (isInMutableVariable(variableElement)) {
      add(new ir.LetMutable(
          getMutableVariable(variableElement),
          initialValue));
    } else {
      initialValue.useElementAsHint(variableElement);
      environment.extend(variableElement, initialValue);
    }
  }

  /// Add [functionElement] to the environment with provided [definition].
  void declareLocalFunction(LocalFunctionElement functionElement,
                            ClosureClassElement classElement,
                            SourceInformation sourceInformation) {
    ir.Primitive closure =
         buildFunctionExpression(classElement, sourceInformation);
    declareLocalVariable(functionElement, initialValue: closure);
  }

  ir.Primitive buildFunctionExpression(ClosureClassElement classElement,
                                       SourceInformation sourceInformation) {
    List<ir.Primitive> arguments = <ir.Primitive>[];
    for (ClosureFieldElement field in classElement.closureFields) {
      // Captured 'this' and type variables are not always available as locals
      // in the environment, so treat those specially.
      ir.Primitive value;
      if (field.local is ThisLocal) {
        value = buildThis();
      } else if (field.local is TypeVariableLocal) {
        TypeVariableLocal variable = field.local;
        value = buildTypeVariableAccess(variable.typeVariable);
      } else {
        value = environment.lookup(field.local);
      }
      arguments.add(value);
    }
    return addPrimitive(new ir.CreateInstance(
        classElement, arguments, const <ir.Primitive>[], sourceInformation));
  }

  /// Create a read access of [local] variable or parameter.
  ir.Primitive _buildLocalGet(LocalElement local) {
    assert(isOpen);
    ClosureLocation location = state.boxedVariables[local];
    if (location != null) {
      ir.Primitive result = new ir.GetField(environment.lookup(location.box),
                                            location.field);
      result.useElementAsHint(local);
      return addPrimitive(result);
    } else if (isInMutableVariable(local)) {
      return addPrimitive(new ir.GetMutable(getMutableVariable(local)));
    } else {
      return environment.lookup(local);
    }
  }

  /// Create a write access to [local] variable or parameter with the provided
  /// [value].
  ir.Primitive buildLocalVariableSet(LocalElement local, ir.Primitive value) {
    assert(isOpen);
    ClosureLocation location = state.boxedVariables[local];
    if (location != null) {
      addPrimitive(new ir.SetField(
          environment.lookup(location.box),
          location.field,
          value));
    } else if (isInMutableVariable(local)) {
      addPrimitive(new ir.SetMutable(
          getMutableVariable(local), value));
    } else {
      value.useElementAsHint(local);
      environment.update(local, value);
    }
    return value;
  }

  /// Called before building the initializer of a for-loop.
  ///
  /// The loop variables will subsequently be declared using
  /// [declareLocalVariable].
  void _enterForLoopInitializer(ClosureScope scope,
                                List<LocalElement> loopVariables) {
    if (scope == null) return;
    // If there are no boxed loop variables, don't create the box here, let
    // it be created inside the body instead.
    if (scope.boxedLoopVariables.isEmpty) return;
    _enterScope(scope);
  }

  /// Called before building the body of a for-loop.
  void _enterForLoopBody(ClosureScope scope,
                         List<LocalElement> loopVariables) {
    if (scope == null) return;
    // If there are boxed loop variables, the box has already been created
    // at the initializer.
    if (!scope.boxedLoopVariables.isEmpty) return;
    _enterScope(scope);
  }

  /// Called before building the update of a for-loop.
  void _enterForLoopUpdate(ClosureScope scope,
                           List<LocalElement> loopVariables) {
    if (scope == null) return;
    // If there are no boxed loop variables, then the box is created inside the
    // body, so there is no need to explicitly renew it.
    if (scope.boxedLoopVariables.isEmpty) return;
    ir.Primitive box = environment.lookup(scope.box);
    ir.Primitive newBox = addPrimitive(new ir.CreateBox());
    newBox.useElementAsHint(scope.box);
    for (VariableElement loopVar in scope.boxedLoopVariables) {
      ClosureLocation location = scope.capturedVariables[loopVar];
      ir.Primitive value = addPrimitive(new ir.GetField(box, location.field));
      addPrimitive(new ir.SetField(newBox, location.field, value));
    }
    environment.update(scope.box, newBox);
  }

  /// Creates an access to the receiver from the current (or enclosing) method.
  ///
  /// If inside a closure class, [buildThis] will redirect access through
  /// closure fields in order to access the receiver from the enclosing method.
  ir.Primitive buildThis() {
    if (state.enclosingThis != null) return state.enclosingThis;
    assert(state.thisParameter != null);
    return state.thisParameter;
  }

  ir.Primitive buildFieldGet(ir.Primitive receiver, FieldElement target) {
    return addPrimitive(new ir.GetField(receiver, target));
  }

  void buildFieldSet(ir.Primitive receiver,
                     FieldElement target,
                     ir.Primitive value) {
    addPrimitive(new ir.SetField(receiver, target, value));
  }

  ir.Primitive buildSuperFieldGet(FieldElement target) {
    return addPrimitive(new ir.GetField(buildThis(), target));
  }

  ir.Primitive buildSuperFieldSet(FieldElement target, ir.Primitive value) {
    addPrimitive(new ir.SetField(buildThis(), target, value));
    return value;
  }

  ir.Primitive buildInvokeDirectly(MethodElement target,
                                   ir.Primitive receiver,
                                   List<ir.Primitive> arguments,
                                   {SourceInformation sourceInformation}) {
    assert(isOpen);
    Selector selector =
        new Selector.call(target.memberName, new CallStructure(arguments.length));
    return _continueWithExpression(
        (k) => new ir.InvokeMethodDirectly(
            receiver, target, selector, arguments, k, sourceInformation));
  }

  /// Loads parameters to a constructor body into the environment.
  ///
  /// The header for a constructor body differs from other functions in that
  /// some parameters are already boxed, and the box is passed as an argument
  /// instead of being created in the header.
  void buildConstructorBodyHeader(Iterable<Local> parameters,
                                  ClosureScope closureScope) {
    _createThisParameter();
    for (Local param in parameters) {
      ir.Parameter parameter = _createLocalParameter(param);
      state.functionParameters.add(parameter);
    }
    if (closureScope != null) {
      state.boxedVariables.addAll(closureScope.capturedVariables);
    }
  }

  /// Create a constructor invocation of [element] on [type] where the
  /// constructor name and argument structure are defined by [callStructure] and
  /// the argument values are defined by [arguments].
  ir.Primitive buildConstructorInvocation(
      ConstructorElement element,
      CallStructure callStructure,
      DartType type,
      List<ir.Primitive> arguments,
      SourceInformation sourceInformation) {
    assert(isOpen);
    Selector selector =
        new Selector(SelectorKind.CALL, element.memberName, callStructure);
    ClassElement cls = element.enclosingClass;
    if (program.requiresRuntimeTypesFor(cls)) {
      InterfaceType interface = type;
      Iterable<ir.Primitive> typeArguments =
          interface.typeArguments.map((DartType argument) {
        return type.treatAsRaw
            ? buildNullConstant()
            : buildTypeExpression(argument);
      });
      arguments = new List<ir.Primitive>.from(arguments)
          ..addAll(typeArguments);
    }
    return _continueWithExpression(
        (k) => new ir.InvokeConstructor(
            type, element, selector, arguments, k, sourceInformation));
  }

  ir.Primitive buildTypeExpression(DartType type) {
    type = program.unaliasType(type);
    if (type is TypeVariableType) {
      return buildTypeVariableAccess(type);
    } else if (type is InterfaceType || type is FunctionType) {
      List<ir.Primitive> arguments = <ir.Primitive>[];
      type.forEachTypeVariable((TypeVariableType variable) {
        ir.Primitive value = buildTypeVariableAccess(variable);
        arguments.add(value);
      });
      return addPrimitive(new ir.TypeExpression(type, arguments));
    } else if (type.treatAsDynamic) {
      return buildNullConstant();
    } else {
      // TypedefType can reach here, and possibly other things.
      throw 'unimplemented translation of type expression $type (${type.kind})';
    }
  }

  /// Obtains the internal type representation of the type held in [variable].
  ///
  /// The value of [variable] is taken from the current receiver object, or
  /// if we are currently building a constructor field initializer, from the
  /// corresponding type argument (field initializers are evaluated before the
  /// receiver object is created).
  ir.Primitive buildTypeVariableAccess(TypeVariableType variable,
                                       {SourceInformation sourceInformation}) {
    // If the local exists in the environment, use that.
    // This is put here when we are inside a constructor or field initializer,
    // (or possibly a closure inside one of these).
    Local local = new TypeVariableLocal(variable, state.currentElement);
    if (environment.contains(local)) {
      return environment.lookup(local);
    }

    // If the type variable is not in a local, read its value from the
    // receiver object.
    ir.Primitive target = buildThis();
    return addPrimitive(
        new ir.ReadTypeVariable(variable, target, sourceInformation));
  }

  /// Make the given type variable accessible through the local environment
  /// with the value of [binding].
  void declareTypeVariable(TypeVariableType variable, DartType binding) {
    environment.extend(
        new TypeVariableLocal(variable, state.currentElement),
        buildTypeExpression(binding));
  }

  /// Reifies the value of [variable] on the current receiver object.
  ir.Primitive buildReifyTypeVariable(TypeVariableType variable,
                                      SourceInformation sourceInformation) {
    ir.Primitive typeArgument =
        buildTypeVariableAccess(variable, sourceInformation: sourceInformation);
    return addPrimitive(
        new ir.ReifyRuntimeType(typeArgument, sourceInformation));
  }

  ir.Primitive buildInvocationMirror(Selector selector,
                                     List<ir.Primitive> arguments) {
    return addPrimitive(new ir.CreateInvocationMirror(selector, arguments));
  }

  ir.Primitive buildForeignCode(js.Template codeTemplate,
                                List<ir.Primitive> arguments,
                                NativeBehavior behavior,
                                {Element dependency}) {
    assert(behavior != null);
    types.TypeMask type = program.getTypeMaskForForeign(behavior);
    ir.Primitive result = _continueWithExpression((k) => new ir.ForeignCode(
        codeTemplate,
        type,
        arguments,
        behavior,
        k,
        dependency: dependency));
    if (!codeTemplate.isExpression) {
      // Close the term if this is a "throw" expression or native body.
      add(new ir.Unreachable());
      _current = null;
    }
    return result;
  }

  /// Creates a type test or type cast of [value] against [type].
  ir.Primitive buildTypeOperator(ir.Primitive value,
                                 DartType type,
                                 {bool isTypeTest}) {
    assert(isOpen);
    assert(isTypeTest != null);

    type = program.unaliasType(type);

    if (type.isMalformed) {
      FunctionElement helper = program.throwTypeErrorHelper;
      ErroneousElement element = type.element;
      ir.Primitive message = buildStringConstant(element.message);
      return buildStaticFunctionInvocation(
          helper,
          CallStructure.ONE_ARG,
          <ir.Primitive>[message]);
    }

    List<ir.Primitive> typeArguments = const <ir.Primitive>[];
    if (type is GenericType && type.typeArguments.isNotEmpty) {
      typeArguments = type.typeArguments.map(buildTypeExpression).toList();
    } else if (type is TypeVariableType) {
      typeArguments = <ir.Primitive>[buildTypeVariableAccess(type)];
    } else if (type is FunctionType) {
      typeArguments = <ir.Primitive>[buildTypeExpression(type)];
    }

    if (isTypeTest) {
      // For type tests, we must treat specially the rare cases where `null`
      // satisfies the test (which otherwise never satisfies a type test).
      // This is not an optimization: the TypeOperator assumes that `null`
      // cannot satisfy the type test unless the type is a type variable.
      if (type.isObject || type.isDynamic) {
        // `x is Object` and `x is dynamic` are always true, even if x is null.
        return buildBooleanConstant(true);
      }
      if (type is InterfaceType && type.element == program.nullClass) {
        // `x is Null` is true if and only if x is null.
        return _buildCheckNull(value);
      }
      return addPrimitive(new ir.TypeTest(value, type, typeArguments));
    } else {
      if (type.isObject || type.isDynamic) {
        // `x as Object` and `x as dynamic` are the same as `x`.
        return value;
      }
      return _continueWithExpression(
              (k) => new ir.TypeCast(value, type, typeArguments, k));
    }
  }

  /// Create an if-null expression. This is equivalent to a conditional
  /// expression whose result is either [value] if [value] is not null, or
  /// `right` if [value] is null. Only when [value] is null, [buildRight] is
  /// evaluated to produce the `right` value.
  ir.Primitive buildIfNull(ir.Primitive value,
                           ir.Primitive buildRight(IrBuilder builder),
                           {SourceInformation sourceInformation}) {
    ir.Primitive condition =
        _buildCheckNull(value, sourceInformation: sourceInformation);
    return buildConditional(condition, buildRight, (_) => value);
  }

  /// Create a conditional send. This is equivalent to a conditional expression
  /// that checks if [receiver] is null, if so, it returns null, otherwise it
  /// evaluates the [buildSend] expression.
  ir.Primitive buildIfNotNullSend(ir.Primitive receiver,
                                  ir.Primitive buildSend(IrBuilder builder),
                                  {SourceInformation sourceInformation}) {
    ir.Primitive condition =
        _buildCheckNull(receiver, sourceInformation: sourceInformation);
    return buildConditional(condition, (_) => receiver, buildSend);
  }

  /// Creates a type test checking whether [value] is null.
  ir.Primitive _buildCheckNull(ir.Primitive value,
                               {SourceInformation sourceInformation}) {
    assert(isOpen);
    return buildIdentical(value, buildNullConstant(),
        sourceInformation: sourceInformation);
  }

  /// Convert the given value to a string.
  ir.Primitive buildStringify(ir.Primitive value) {
    return buildStaticFunctionInvocation(
        program.stringifyFunction,
        new CallStructure.unnamed(1),
        <ir.Primitive>[value]);
  }

  ir.Node buildAwait(ir.Primitive value) {
    return _continueWithExpression((k) => new ir.Await(value, k));
  }
}


/// Location of a variable relative to a given closure.
class ClosureLocation {
  /// If not `null`, this location is [box].[field].
  /// The location of [box] can be obtained separately from an
  /// enclosing [ClosureEnvironment] or [ClosureScope].
  /// If `null`, then the location is [field] on the enclosing function object.
  final BoxLocal box;

  /// The field in which the variable is stored.
  final Entity field;

  bool get isBox => box != null;

  ClosureLocation(this.box, this.field);
}

/// Introduces a new box and binds local variables to this box.
///
/// A [ClosureScope] may exist for each function and for each loop.
/// Generally, one may pass `null` to the [IrBuilder] instead of a
/// [ClosureScope] when a given scope has no boxed variables.
class ClosureScope {
  /// This box is now in scope and [capturedVariables] may use it.
  final BoxLocal box;

  /// Maps [LocalElement]s to their location.
  final Map<Local, ClosureLocation> capturedVariables;

  /// If this is the scope of a for-loop, [boxedLoopVariables] is the list
  /// of boxed variables that are declared in the initializer.
  final List<VariableElement> boxedLoopVariables;

  ClosureScope(this.box, this.capturedVariables, this.boxedLoopVariables);
}

/// Environment passed when building a nested function, describing how
/// to access variables from the enclosing scope.
class ClosureEnvironment {
  /// References to this local should be treated as recursive self-reference.
  /// (This is *not* in [freeVariables]).
  final LocalFunctionElement selfReference;

  /// If non-null, [thisLocal] has an entry in [freeVariables] describing where
  /// to find the captured value of `this`.
  final ThisLocal thisLocal;

  /// Maps [LocalElement]s, [BoxLocal]s and [ThisLocal] to their location.
  final Map<Local, ClosureLocation> freeVariables;

  ClosureEnvironment(this.selfReference, this.thisLocal, this.freeVariables);
}

class TryStatementInfo {
  final Set<LocalVariableElement> declared = new Set<LocalVariableElement>();
  final Set<LocalVariableElement> boxedOnEntry =
      new Set<LocalVariableElement>();
}

class CatchClauseInfo {
  final DartType type;
  final LocalVariableElement exceptionVariable;
  final LocalVariableElement stackTraceVariable;
  final SubbuildFunction buildCatchBlock;

  CatchClauseInfo({this.type,
                   this.exceptionVariable,
                   this.stackTraceVariable,
                   this.buildCatchBlock});
}

class SwitchCaseInfo {
  final List<ir.Primitive> constants = <ir.Primitive>[];
  final SubbuildFunction buildBody;

  SwitchCaseInfo(this.buildBody);

  void addConstant(ir.Primitive constant) => constants.add(constant);
}
