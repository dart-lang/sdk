// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder;

import '../constants/expressions.dart';
import '../constants/values.dart' show PrimitiveConstantValue;
import '../dart_types.dart';
import '../dart2jslib.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../tree/tree.dart' as ast;
import '../closure.dart' hide ClosureScope;
import 'cps_ir_nodes.dart' as ir;
import 'cps_ir_builder_task.dart' show DartCapturedVariables,
    GlobalProgramInformation;

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
    // as the name of anonymous variables.  Because the variable2index map is
    // shared, `null` can already occur.  This is safe because such variables
    // are not looked up by name.
    //
    // TODO(kmillikin): This is still kind of fishy.  Refactor to not share
    // name maps or else garbage collect unneeded names.
    assert(element == null || !variable2index.containsKey(element));
    variable2index[element] = index2variable.length;
    index2variable.add(element);
    index2value.add(value);
  }

  void discard(int count) {
    assert(count <= index2variable.length);
    // The map from variables to their index are shared, so we cannot remove
    // the mapping in `variable2index`.
    index2variable.length -= count;
    index2value.length -= count;
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

      // The variable maps to the same index in both environments.
      int index = variable2index[variable];
      if (index == null || index != other.variable2index[variable]) {
        return false;
      }
    }
    return true;
  }
}

/// The abstract base class of objects that emit jumps to a continuation and
/// give a handle to the continuation and its environment.
abstract class JumpCollector {
  final JumpTarget target;

  ir.Continuation _continuation = null;
  final Environment _continuationEnvironment;

  final List<Iterable<LocalVariableElement>> _boxedTryVariables =
      <Iterable<LocalVariableElement>>[];

  JumpCollector(this._continuationEnvironment, this.target);

  /// True if the collector has not recorded any jumps to its continuation.
  bool get isEmpty;

  /// The continuation encapsulated by this collector.
  ir.Continuation get continuation;

  /// The compile-time environment to be used for translating code in the body
  /// of the continuation.
  Environment get environment;

  /// Emit a jump to the continuation for a given [IrBuilder].
  void addJump(IrBuilder builder);

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
        ir.Primitive value = builder.buildLocalGet(variable);
        builder.environment.update(variable, value);
      }
    }
  }
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
  ForwardJumpCollector(Environment environment, {JumpTarget target: null})
      : super(new Environment.from(environment), target);

  bool get isEmpty => _invocations.isEmpty;

  ir.Continuation get continuation {
    if (_continuation == null) _setContinuation();
    return _continuation;
  }

  Environment get environment {
    if (_continuation == null) _setContinuation();
    return _continuationEnvironment;
  }

  void addJump(IrBuilder builder) {
    assert(_continuation == null);
    _buildTryExit(builder);
    ir.InvokeContinuation invoke = new ir.InvokeContinuation.uninitialized();
    builder.add(invoke);
    _invocations.add(invoke);
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
  BackwardJumpCollector(Environment environment, {JumpTarget target: null})
      : super(new Environment.fresh(environment), target) {
    List<ir.Parameter> parameters =
        new List<ir.Parameter>.from(_continuationEnvironment.index2value);
    _continuation = new ir.Continuation(parameters, isRecursive: true);
  }

  bool isEmpty = true;

  ir.Continuation get continuation => _continuation;
  Environment get environment => _continuationEnvironment;

  void addJump(IrBuilder builder) {
    assert(_continuation.parameters.length <= builder.environment.length);
    isEmpty = false;
    _buildTryExit(builder);
    builder.add(new ir.InvokeContinuation(_continuation,
        builder.environment.index2value.take(_continuation.parameters.length)
            .toList(),
        isRecursive: true));
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
class IrBuilderDelimitedState {
  final ConstantSystem constantSystem;

  /// A stack of collectors for breaks.
  final List<JumpCollector> breakCollectors = <JumpCollector>[];

  /// A stack of collectors for continues.
  final List<JumpCollector> continueCollectors = <JumpCollector>[];

  final List<ConstDeclaration> localConstants = <ConstDeclaration>[];

  final ExecutableElement currentElement;

  final ir.Continuation returnContinuation = new ir.Continuation.retrn();
  ir.Parameter _thisParameter;
  ir.Parameter enclosingMethodThisParameter;

  final List<ir.Definition> functionParameters = <ir.Definition>[];

  IrBuilderDelimitedState(this.constantSystem, this.currentElement);

  ir.Parameter get thisParameter => _thisParameter;
  void set thisParameter(ir.Parameter value) {
    assert(_thisParameter == null);
    _thisParameter = value;
  }
}

class ThisParameterLocal implements Local {
  final ExecutableElement executableContext;
  ThisParameterLocal(this.executableContext);
  String get name => 'this';
  toString() => 'ThisParameterLocal($executableContext)';
}

/// A factory for building the cps IR.
///
/// [DartIrBuilder] and [JsIrBuilder] implement nested functions and captured
/// variables in different ways.
abstract class IrBuilder {
  IrBuilder _makeInstance();

  /// True if [local] should currently be accessed from a [ir.MutableVariable].
  bool isInMutableVariable(Local local);

  /// Creates a [ir.MutableVariable] for the given local.
  void makeMutableVariable(Local local);

  /// Remove an [ir.MutableVariable] for a local.
  ///
  /// Subsequent access to the local will be direct rather than through the
  /// mutable variable.  This is used for variables that do not spend their
  /// entire lifetime as mutable variables (e.g., variables that are boxed
  /// in mutable variables for a try block).
  void removeMutableVariable(Local local);

  void declareLocalVariable(LocalVariableElement element,
                            {ir.Primitive initialValue});

  /// Called when entering a nested function with free variables.
  ///
  /// The free variables must subsequently be accessible using [buildLocalGet]
  /// and [buildLocalSet].
  void _enterClosureEnvironment(ClosureEnvironment env);

  /// Called when entering a function body or loop body.
  ///
  /// This is not called for for-loops, which instead use the methods
  /// [_enterForLoopInitializer], [_enterForLoopBody], and [_enterForLoopUpdate]
  /// due to their special scoping rules.
  ///
  /// The boxed variables declared in this scope must subsequently be available
  /// using [buildLocalGet], [buildLocalSet], etc.
  void _enterScope(ClosureScope scope);

  /// Called before building the initializer of a for-loop.
  ///
  /// The loop variables will subsequently be declared using
  /// [declareLocalVariable].
  void _enterForLoopInitializer(ClosureScope scope,
                                List<LocalElement> loopVariables);

  /// Called before building the body of a for-loop.
  void _enterForLoopBody(ClosureScope scope,
                         List<LocalElement> loopVariables);

  /// Called before building the update of a for-loop.
  void _enterForLoopUpdate(ClosureScope scope,
                           List<LocalElement> loopVariables);

  /// Add the given function parameter to the IR, and bind it in the environment
  /// or put it in its box, if necessary.
  void _createFunctionParameter(Local parameterElement);
  void _createThisParameter();

  /// Creates an access to the receiver from the current (or enclosing) method.
  ///
  /// If inside a closure class, [buildThis] will redirect access through
  /// closure fields in order to access the receiver from the enclosing method.
  ir.Primitive buildThis();

  // TODO(johnniwinther): Make these field final and remove the default values
  // when [IrBuilder] is a property of [IrBuilderVisitor] instead of a mixin.

  final List<ir.Parameter> _parameters = <ir.Parameter>[];

  IrBuilderDelimitedState state;

  /// A map from variable indexes to their values.
  ///
  /// [BoxLocal]s map to their box. [LocalElement]s that are boxed are not
  /// in the map; look up their [BoxLocal] instead.
  Environment environment;

  // The IR builder maintains a context, which is an expression with a hole in
  // it.  The hole represents the focus where new expressions can be added.
  // The context is implemented by 'root' which is the root of the expression
  // and 'current' which is the expression that immediately contains the hole.
  // Not all expressions have a hole (e.g., invocations, which always occur in
  // tail position, do not have a hole).  Expressions with a hole have a plug
  // method.
  //
  // Conceptually, visiting a statement takes a context as input and returns
  // either a new context or else an expression without a hole if all
  // control-flow paths through the statement have exited.  An expression
  // without a hole is represented by a (root, current) pair where root is the
  // expression and current is null.
  //
  // Conceptually again, visiting an expression takes a context as input and
  // returns either a pair of a new context and a definition denoting
  // the expression's value, or else an expression without a hole if all
  // control-flow paths through the expression have exited.
  //
  // We do not pass contexts as arguments or return them.  Rather we use the
  // current context (root, current) as the visitor state and mutate current.
  // Visiting a statement returns null; visiting an expression returns the
  // primitive denoting its value.

  ir.Expression _root = null;
  ir.Expression _current = null;

  /// Initialize a new top-level IR builder.
  void _init(ConstantSystem constantSystem, ExecutableElement currentElement) {
    state = new IrBuilderDelimitedState(constantSystem, currentElement);
    environment = new Environment.empty();
  }

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
    return _makeInstance()
        ..state = state
        ..environment = env != null ? env : new Environment.from(environment);
  }

  /// Construct a builder for making constructor field initializers.
  IrBuilder makeInitializerBuilder() {
    return _makeInstance()
        ..state = new IrBuilderDelimitedState(state.constantSystem,
                                              state.currentElement)
        ..environment = new Environment.from(environment);
  }

  /// Construct a builder for an inner function.
  IrBuilder makeInnerFunctionBuilder(ExecutableElement currentElement) {
    IrBuilderDelimitedState innerState =
        new IrBuilderDelimitedState(state.constantSystem, currentElement)
          ..enclosingMethodThisParameter = state.enclosingMethodThisParameter;
    return _makeInstance()
        ..state = innerState
        ..environment = new Environment.empty();
  }

  bool get isOpen => _root == null || _current != null;


  void buildFieldInitializerHeader({ClosureScope closureScope}) {
    _enterScope(closureScope);
  }

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
  ir.Parameter createLocalParameter(Local local) {
    ir.Parameter parameter = new ir.Parameter(local);
    _parameters.add(parameter);
    environment.extend(local, parameter);
    return parameter;
  }

  /// Adds the constant [variableElement] to the environment with [value] as its
  /// constant value.
  void declareLocalConstant(LocalVariableElement variableElement,
                            ConstantExpression value) {
    state.localConstants.add(new ConstDeclaration(variableElement, value));
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
        (k) => new ir.InvokeStatic(element, selector, k, arguments,
                                   sourceInformation));
  }

  ir.Primitive _buildInvokeSuper(Element target,
                                 Selector selector,
                                 List<ir.Primitive> arguments) {
    assert(target.isInstanceMember);
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.InvokeMethodDirectly(
            buildThis(), target, selector, k, arguments));
  }

  ir.Primitive _buildInvokeDynamic(ir.Primitive receiver,
                                   Selector selector,
                                   List<ir.Primitive> arguments) {
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.InvokeMethod(receiver, selector, k, arguments));
  }

  ir.Primitive _buildInvokeCall(ir.Primitive target,
                                Selector selector,
                                List<ir.Definition> arguments) {
    Selector callSelector = new Selector.callClosureFrom(selector);
    return _buildInvokeDynamic(target, callSelector, arguments);
  }


  /// Create a constant literal from [constant].
  ir.Constant buildConstantLiteral(ConstantExpression constant) {
    assert(isOpen);
    return addPrimitive(new ir.Constant(constant));
  }

  // Helper for building primitive literals.
  ir.Constant _buildPrimitiveConstant(PrimitiveConstantValue constant) {
    return buildConstantLiteral(new PrimitiveConstantExpression(constant));
  }

  /// Create an integer literal.
  ir.Constant buildIntegerLiteral(int value) {
    return _buildPrimitiveConstant(state.constantSystem.createInt(value));
  }

  /// Create an double literal.
  ir.Constant buildDoubleLiteral(double value) {
    return _buildPrimitiveConstant(state.constantSystem.createDouble(value));
  }

  /// Create an bool literal.
  ir.Constant buildBooleanLiteral(bool value) {
    return _buildPrimitiveConstant(state.constantSystem.createBool(value));
  }

  /// Create an null literal.
  ir.Constant buildNullLiteral() {
    return _buildPrimitiveConstant(state.constantSystem.createNull());
  }

  /// Create a string literal.
  ir.Constant buildStringLiteral(String value) {
    return _buildPrimitiveConstant(
        state.constantSystem.createString(new ast.DartString.literal(value)));
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
    // Extend the join-point environment with a placeholder for the value of
    // the expression.  Optimistically assume that the value is the value of
    // the first subexpression.  This value might noe even be in scope at the
    // join-point because it's bound in the first subexpression.  However, if
    // that is the case, it will necessarily differ from the value of the
    // other subexpression and cause the introduction of a join-point
    // continuation parameter.  If the two values do happen to be the same,
    // this will avoid inserting a useless continuation parameter.
    environment.extend(null, thenValue);
    thenBuilder.environment.extend(null, thenValue);
    elseBuilder.environment.extend(null, elseValue);
    JumpCollector join = new ForwardJumpCollector(environment);
    thenBuilder.jumpTo(join);
    elseBuilder.jumpTo(join);

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
            new ir.LetCont.many(<ir.Continuation>[thenContinuation,
                                                  elseContinuation],
                new ir.Branch(new ir.IsTrue(condition),
                              thenContinuation,
                              elseContinuation))));
    environment = join.environment;
    environment.discard(1);
    return (thenValue == elseValue)
        ? thenValue
        : join.continuation.parameters.last;
  }

  /**
   * Add an explicit `return null` for functions that don't have a return
   * statement on each branch. This includes functions with an empty body,
   * such as `foo(){ }`.
   */
  void _ensureReturn() {
    if (!isOpen) return;
    ir.Constant constant = buildNullLiteral();
    add(new ir.InvokeContinuation(state.returnContinuation, [constant]));
    _current = null;
  }

  ir.SuperInitializer makeSuperInitializer(ConstructorElement target,
                                           List<ir.Body> arguments,
                                           Selector selector) {
    return new ir.SuperInitializer(target, arguments, selector);
  }

  ir.FieldInitializer makeFieldInitializer(FieldElement element,
                                           ir.Body body) {
    return new ir.FieldInitializer(element, body);
  }

  /// Create a [ir.FieldDefinition] for the current [Element] using [_root] as
  /// the body using [initializer] as the initial value.
  ir.FieldDefinition makeFieldDefinition(ir.Primitive initializer) {
    if (initializer == null) {
      return new ir.FieldDefinition.withoutInitializer(state.currentElement);
    } else {
      ir.Body body = makeBody(initializer);
      return new ir.FieldDefinition(state.currentElement, body);
    }
  }

  ir.Body makeBody([ir.Primitive value]) {
    if (value == null) {
      _ensureReturn();
    } else {
      buildReturn(value);
    }
    return new ir.Body(_root, state.returnContinuation);
  }

  /// Create a [ir.FunctionDefinition] for [element] using [_root] as the body.
  ///
  /// Parameters must be created before the construction of the body using
  /// [createFunctionParameter].
  ir.FunctionDefinition makeFunctionDefinition(
      List<ConstantExpression> defaults) {
    FunctionElement element = state.currentElement;
    if (element.isAbstract || element.isExternal) {
      assert(invariant(element, _root == null,
          message: "Non-empty body for abstract method $element: $_root"));
      assert(invariant(element, state.localConstants.isEmpty,
          message: "Local constants for abstract method $element: "
                   "${state.localConstants}"));
      return new ir.FunctionDefinition.abstract(
          element, state.functionParameters, defaults);
    } else {
      ir.Body body = makeBody();
      return new ir.FunctionDefinition(
          element, state.thisParameter, state.functionParameters, body,
          state.localConstants, defaults);
    }
  }

  /// Create a constructor definition without a body, for representing
  /// external constructors declarations.
  ir.ConstructorDefinition makeAbstractConstructorDefinition(
      List<ConstantExpression> defaults) {
    FunctionElement element = state.currentElement;
    assert(invariant(element, _root == null,
        message: "Non-empty body for external constructor $element: $_root"));
    assert(invariant(element, state.localConstants.isEmpty,
        message: "Local constants for external constructor $element: "
                 "${state.localConstants}"));
    return new ir.ConstructorDefinition.abstract(
        element, state.functionParameters, defaults);
  }

  ir.ConstructorDefinition makeConstructorDefinition(
      List<ConstantExpression> defaults, List<ir.Initializer> initializers) {
    FunctionElement element = state.currentElement;
    ir.Body body = makeBody();
    return new ir.ConstructorDefinition(
        element, state.thisParameter, state.functionParameters, body, initializers,
        state.localConstants, defaults);
  }

  /// Create a super invocation where the method name and the argument structure
  /// are defined by [selector] and the argument values are defined by
  /// [arguments].
  ir.Primitive buildSuperInvocation(Element target,
                                    Selector selector,
                                    List<ir.Primitive> arguments);

  /// Create a getter invocation of the [target] on the super class.
  ir.Primitive buildSuperGet(Element target) {
    Selector selector = new Selector.getter(target.name, target.library);
    return buildSuperInvocation(target, selector, const <ir.Primitive>[]);
  }

  /// Create a setter invocation of the [target] on the super class of with
  /// [value].
  ir.Primitive buildSuperSet(Element target, ir.Primitive value) {
    Selector selector = new Selector.setter(target.name, target.library);
    buildSuperInvocation(target, selector, [value]);
    return value;
  }

  /// Create an index set invocation on the super class with the provided
  /// [index] and [value].
  ir.Primitive buildSuperIndexSet(Element target,
                                  ir.Primitive index,
                                  ir.Primitive value) {
    _buildInvokeSuper(target, new Selector.indexSet(),
        <ir.Primitive>[index, value]);
    return value;
  }

  /// Create a dynamic invocation on [receiver] where the method name and
  /// argument structure are defined by [selector] and the argument values are
  /// defined by [arguments].
  ir.Primitive buildDynamicInvocation(ir.Primitive receiver,
                                      Selector selector,
                                      List<ir.Primitive> arguments) {
    return _buildInvokeDynamic(receiver, selector, arguments);
  }

  /// Create a dynamic getter invocation on [receiver] where the getter name is
  /// defined by [selector].
  ir.Primitive buildDynamicGet(ir.Primitive receiver, Selector selector) {
    assert(selector.isGetter);
    return _buildInvokeDynamic(receiver, selector, const <ir.Primitive>[]);
  }

  /// Create a dynamic setter invocation on [receiver] where the setter name and
  /// argument are defined by [selector] and [value], respectively.
  ir.Primitive buildDynamicSet(ir.Primitive receiver,
                               Selector selector,
                               ir.Primitive value) {
    assert(selector.isSetter);
    _buildInvokeDynamic(receiver, selector, <ir.Primitive>[value]);
    return value;
  }

  /// Create a dynamic index set invocation on [receiver] with the provided
  /// [index] and [value].
  ir.Primitive  buildDynamicIndexSet(ir.Primitive receiver,
                                     ir.Primitive index,
                                     ir.Primitive value) {
    _buildInvokeDynamic(
        receiver, new Selector.indexSet(), <ir.Primitive>[index, value]);
    return value;
  }

  /// Create a read access of [local].
  ir.Primitive buildLocalGet(LocalElement element);

  /// Create a write access to [local] with the provided [value].
  ir.Primitive buildLocalSet(LocalElement element, ir.Primitive value);

  /// Create an invocation of the local [element] where argument structure is
  /// defined by [selector] and the argument values are defined by [arguments].
  ir.Primitive buildLocalInvocation(LocalElement element,
                                    Selector selector,
                                    List<ir.Primitive> arguments) {
    return buildCallInvocation(buildLocalGet(element), selector, arguments);
  }

  /// Create a static invocation of [element] where argument structure is
  /// defined by [selector] and the argument values are defined by [arguments].
  ir.Primitive buildStaticInvocation(Element element,
                                     Selector selector,
                                     List<ir.Primitive> arguments,
                                     {SourceInformation sourceInformation}) {
    return _buildInvokeStatic(element, selector, arguments, sourceInformation);
  }

  /// Create a static getter invocation of [element] where the getter name is
  /// defined by [selector].
  ir.Primitive buildStaticGet(Element element,
                              {SourceInformation sourceInformation}) {
    Selector selector = new Selector.getter(element.name, element.library);
    // TODO(karlklose,sigurdm): build different nodes for getters.
    return _buildInvokeStatic(
        element, selector, const <ir.Primitive>[], sourceInformation);
  }

  /// Create a static setter invocation of [element] where the setter name and
  /// argument are defined by [selector] and [value], respectively.
  ir.Primitive buildStaticSet(Element element,
                              ir.Primitive value,
                              {SourceInformation sourceInformation}) {
    Selector selector = new Selector.setter(element.name, element.library);
    // TODO(karlklose,sigurdm): build different nodes for setters.
    _buildInvokeStatic(
        element, selector, <ir.Primitive>[value], sourceInformation);
    return value;
  }

  /// Create a constructor invocation of [element] on [type] where the
  /// constructor name and argument structure are defined by [selector] and the
  /// argument values are defined by [arguments].
  ir.Primitive buildConstructorInvocation(FunctionElement element,
                                          Selector selector,
                                          DartType type,
                                          List<ir.Primitive> arguments);

  /// Create a string concatenation of the [arguments].
  ir.Primitive buildStringConcatenation(List<ir.Primitive> arguments) {
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.ConcatenateStrings(k, arguments));
  }

  /// Create an invocation of the `call` method of [functionExpression], where
  /// the named arguments are given by [selector].
  ir.Primitive buildCallInvocation(
      ir.Primitive functionExpression,
      Selector selector,
      List<ir.Definition> arguments) {
    return _buildInvokeCall(functionExpression, selector, arguments);
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

  void jumpTo(JumpCollector collector) {
    collector.addJump(this);
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
      condition = buildBooleanLiteral(true);
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
        new ir.LetCont.many(<ir.Continuation>[exitContinuation,
                                              bodyContinuation],
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
            new Selector.getter("iterator", null),
            iteratorInvoked,
            emptyArguments)));

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
            new Selector.call("moveNext", null, 0),
            moveNextInvoked,
            emptyArguments)));

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
        new ir.InvokeMethod(iterator, new Selector.getter("current", null),
            currentInvoked, emptyArguments)));
    // TODO(sra): Does this cover all cases? The general setter case include
    // super.
    if (Elements.isLocal(variableElement)) {
      bodyBuilder.buildLocalSet(variableElement, currentValue);
    } else if (Elements.isStaticOrTopLevel(variableElement) ||
               Elements.isErroneous(variableElement)) {
      bodyBuilder.buildStaticSet(variableElement, currentValue);
    } else {
      ir.Primitive receiver = bodyBuilder.buildThis();
      assert(receiver != null);
      bodyBuilder.buildDynamicSet(receiver, variableSelector, currentValue);
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
        new ir.LetCont.many(<ir.Continuation>[exitContinuation,
                                              bodyContinuation],
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
        new ir.LetCont.many(<ir.Continuation>[exitContinuation,
                                              bodyContinuation],
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
        new ir.LetCont.many(<ir.Continuation>[exitContinuation,
                                              repeatContinuation],
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

  /// Creates a try-statement.
  ///
  /// [tryInfo] provides information on local variables declared and boxed
  /// within this try statement.
  /// [buildTryBlock] builds the try block.
  /// [catchClauseInfos] provides access to the catch type, exception variable,
  /// and stack trace variable, and a function for building the catch block.
  void buildTry(
      {TryStatementInfo tryStatementInfo,
       SubbuildFunction buildTryBlock,
       List<CatchClauseInfo> catchClauseInfos: const <CatchClauseInfo>[]}) {
    assert(isOpen);

    // Catch handlers are in scope for their body.  The CPS translation of
    // [[try tryBlock catch (e) catchBlock; successor]] is:
    //
    // let cont join(v0, v1, ...) = [[successor]] in
    //   let mutable m0 = x0 in
    //     let mutable m1 = x1 in
    //       ...
    //       let handler catch_(e) =
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
    JumpCollector join = new ForwardJumpCollector(environment);
    IrBuilder tryCatchBuilder = makeDelimitedBuilder();

    // Variables that are boxed due to being captured in a closure are boxed
    // for their entire lifetime, and so they do not need to be boxed on
    // entry to any try block.  They are not filtered out before this because
    // we can not identify all of them in the same pass where we identify the
    // variables assigned in the try (they may be captured by a closure after
    // the try statement).
    for (LocalVariableElement variable in tryStatementInfo.boxedOnEntry) {
      assert(!tryCatchBuilder.isInMutableVariable(variable));
      ir.Primitive value = tryCatchBuilder.buildLocalGet(variable);
      tryCatchBuilder.makeMutableVariable(variable);
      tryCatchBuilder.declareLocalVariable(variable, initialValue: value);
    }

    IrBuilder tryBuilder = tryCatchBuilder.makeDelimitedBuilder();

    void interceptJumps(JumpCollector collector) {
      collector.enterTry(tryStatementInfo.boxedOnEntry);
    }
    void restoreJumps(JumpCollector collector) {
      collector.leaveTry();
    }
    tryBuilder.state.breakCollectors.forEach(interceptJumps);
    tryBuilder.state.continueCollectors.forEach(interceptJumps);
    buildTryBlock(tryBuilder);
    if (tryBuilder.isOpen) {
      interceptJumps(join);
      tryBuilder.jumpTo(join);
      restoreJumps(join);
    }
    tryBuilder.state.breakCollectors.forEach(restoreJumps);
    tryBuilder.state.continueCollectors.forEach(restoreJumps);

    IrBuilder catchBuilder = tryCatchBuilder.makeDelimitedBuilder();
    for (LocalVariableElement variable in tryStatementInfo.boxedOnEntry) {
      assert(catchBuilder.isInMutableVariable(variable));
      ir.Primitive value = catchBuilder.buildLocalGet(variable);
      // Note that we remove the variable from the set of mutable variables
      // here (and not above for the try body).  This is because the set of
      // mutable variables is global for the whole function and not local to
      // a delimited builder.
      catchBuilder.removeMutableVariable(variable);
      catchBuilder.environment.update(variable, value);
    }

    // TODO(kmillikin): Handle multiple catch clauses.
    assert(catchClauseInfos.length == 1);
    for (CatchClauseInfo catchClauseInfo in catchClauseInfos) {
      LocalVariableElement exceptionVariable =
          catchClauseInfo.exceptionVariable;
      ir.Parameter exceptionParameter = new ir.Parameter(exceptionVariable);
      catchBuilder.environment.extend(exceptionVariable, exceptionParameter);
      ir.Parameter traceParameter;
      LocalVariableElement stackTraceVariable =
          catchClauseInfo.stackTraceVariable;
      if (stackTraceVariable != null) {
        traceParameter = new ir.Parameter(stackTraceVariable);
        catchBuilder.environment.extend(stackTraceVariable, traceParameter);
      } else {
        // Use a dummy continuation parameter for the stack trace parameter.
        // This will ensure that all handlers have two parameters and so they
        // can be treated uniformly.
        traceParameter = new ir.Parameter(null);
      }
      catchClauseInfo.buildCatchBlock(catchBuilder);
      if (catchBuilder.isOpen) catchBuilder.jumpTo(join);
      List<ir.Parameter> catchParameters =
          <ir.Parameter>[exceptionParameter, traceParameter];
      ir.Continuation catchContinuation = new ir.Continuation(catchParameters);
      catchContinuation.body = catchBuilder._root;

      tryCatchBuilder.add(
          new ir.LetHandler(catchContinuation, tryBuilder._root));
      tryCatchBuilder._current = null;
    }

    add(new ir.LetCont(join.continuation, tryCatchBuilder._root));
    environment = join.environment;
  }

  /// Create a return statement `return value;` or `return;` if [value] is
  /// null.
  void buildReturn([ir.Primitive value]) {
    // Build(Return(e), C) = C'[InvokeContinuation(return, x)]
    //   where (C', x) = Build(e, C)
    //
    // Return without a subexpression is translated as if it were return null.
    assert(isOpen);
    if (value == null) {
      value = buildNullLiteral();
    }
    add(new ir.InvokeContinuation(state.returnContinuation, [value]));
    _current = null;
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

  /// Create a negation of [condition].
  ir.Primitive buildNegation(ir.Primitive condition) {
    // ! e is translated as e ? false : true

    // Add a continuation parameter for the result of the expression.
    ir.Parameter resultParameter = new ir.Parameter(null);

    ir.Continuation joinContinuation = new ir.Continuation([resultParameter]);
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);

    ir.Constant makeBoolConstant(bool value) {
      return new ir.Constant(new PrimitiveConstantExpression(
          state.constantSystem.createBool(value)));
    }

    ir.Constant trueConstant = makeBoolConstant(true);
    ir.Constant falseConstant = makeBoolConstant(false);

    thenContinuation.body = new ir.LetPrim(falseConstant)
        ..plug(new ir.InvokeContinuation(joinContinuation, [falseConstant]));
    elseContinuation.body = new ir.LetPrim(trueConstant)
        ..plug(new ir.InvokeContinuation(joinContinuation, [trueConstant]));

    add(new ir.LetCont(joinContinuation,
          new ir.LetCont.many(<ir.Continuation>[thenContinuation,
                                                elseContinuation],
              new ir.Branch(new ir.IsTrue(condition),
                            thenContinuation,
                            elseContinuation))));
    return resultParameter;
  }

  /// Creates a type test or type cast of [receiver] against [type].
  ///
  /// Set [isTypeTest] to `true` to create a type test and furthermore set
  /// [isNotCheck] to `true` to create a negated type test.
  ir.Primitive buildTypeOperator(ir.Primitive receiver,
                                 DartType type,
                                 {bool isTypeTest: false,
                                  bool isNotCheck: false}) {
    assert(isOpen);
    assert(isTypeTest != null);
    assert(!isNotCheck || isTypeTest);
    ir.Primitive check = _continueWithExpression(
        (k) => new ir.TypeOperator(receiver, type, k, isTypeTest: isTypeTest));
    return isNotCheck ? buildNegation(check) : check;

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
    ir.Constant leftBool = emptyBuilder.buildBooleanLiteral(isLazyOr);
    // If we do evaluate the right subexpression, the value of the expression
    // is a true or false constant.
    ir.Constant rightTrue = rightTrueBuilder.buildBooleanLiteral(true);
    ir.Constant rightFalse = rightFalseBuilder.buildBooleanLiteral(false);

    // Treat the result values as named values in the environment, so they
    // will be treated as arguments to the join-point continuation.
    assert(environment.length == emptyBuilder.environment.length);
    assert(environment.length == rightTrueBuilder.environment.length);
    assert(environment.length == rightFalseBuilder.environment.length);
    // Treat the value of the expression as a local variable so it will get
    // a continuation parameter.
    environment.extend(null, null);
    emptyBuilder.environment.extend(null, leftBool);
    rightTrueBuilder.environment.extend(null, rightTrue);
    rightFalseBuilder.environment.extend(null, rightFalse);

    // Wire up two continuations for the left subexpression, two continuations
    // for the right subexpression, and a three-way join continuation.
    JumpCollector join = new ForwardJumpCollector(environment);
    emptyBuilder.jumpTo(join);
    rightTrueBuilder.jumpTo(join);
    rightFalseBuilder.jumpTo(join);
    ir.Continuation leftTrueContinuation = new ir.Continuation([]);
    ir.Continuation leftFalseContinuation = new ir.Continuation([]);
    ir.Continuation rightTrueContinuation = new ir.Continuation([]);
    ir.Continuation rightFalseContinuation = new ir.Continuation([]);
    rightTrueContinuation.body = rightTrueBuilder._root;
    rightFalseContinuation.body = rightFalseBuilder._root;
    // The right subexpression has two continuations.
    rightBuilder.add(
        new ir.LetCont.many(<ir.Continuation>[rightTrueContinuation,
                                              rightFalseContinuation],
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
            new ir.LetCont.many(<ir.Continuation>[leftTrueContinuation,
                                                  leftFalseContinuation],
                new ir.Branch(new ir.IsTrue(leftValue),
                              leftTrueContinuation,
                              leftFalseContinuation))));
    environment = join.environment;
    environment.discard(1);
    // There is always a join parameter for the result value, because it
    // is different on at least two paths.
    return join.continuation.parameters.last;
  }
}

/// Shared state between DartIrBuilders within the same method.
class DartIrBuilderSharedState {
  /// Maps local variables to their corresponding [MutableVariable] object.
  final Map<Local, ir.MutableVariable> local2mutable =
      <Local, ir.MutableVariable>{};

  /// Creates a [MutableVariable] for the given local.
  void makeMutableVariable(Local local) {
    ir.MutableVariable variable =
        new ir.MutableVariable(local.executableContext, local);
    local2mutable[local] = variable;
  }

  /// [MutableVariable]s that should temporarily be treated as registers.
  final Set<Local> registerizedMutableVariables = new Set<Local>();

  DartIrBuilderSharedState(Set<Local> capturedVariables) {
    capturedVariables.forEach(makeMutableVariable);
  }
}

/// Dart-specific subclass of [IrBuilder].
///
/// Inner functions are represented by a [FunctionDefinition] with the
/// IR for the inner function nested inside.
///
/// Captured variables are translated to ref cells (see [MutableVariable])
/// using [GetMutableVariable] and [SetMutableVariable].
class DartIrBuilder extends IrBuilder {
  final DartIrBuilderSharedState dartState;

  IrBuilder _makeInstance() => new DartIrBuilder._blank(dartState);
  DartIrBuilder._blank(this.dartState);

  DartIrBuilder(ConstantSystem constantSystem,
                ExecutableElement currentElement,
                Set<Local> capturedVariables)
      : dartState = new DartIrBuilderSharedState(capturedVariables) {
    _init(constantSystem, currentElement);
  }

  bool isInMutableVariable(Local local) {
    return dartState.local2mutable.containsKey(local) &&
           !dartState.registerizedMutableVariables.contains(local);
  }

  void makeMutableVariable(Local local) {
    dartState.makeMutableVariable(local);
  }

  void removeMutableVariable(Local local) {
    dartState.local2mutable.remove(local);
  }

  /// Gets the [MutableVariable] containing the value of [local].
  ir.MutableVariable getMutableVariable(Local local) {
    return dartState.local2mutable[local];
  }

  void _enterScope(ClosureScope scope) {
    assert(scope == null);
  }

  void _enterClosureEnvironment(ClosureEnvironment env) {
    assert(env == null);
  }

  void _enterForLoopInitializer(ClosureScope scope,
                                List<LocalElement> loopVariables) {
    assert(scope == null);
    for (LocalElement loopVariable in loopVariables) {
      if (dartState.local2mutable.containsKey(loopVariable)) {
        // Temporarily keep the loop variable in a primitive.
        // The loop variable will be added to environment when
        // [declareLocalVariable] is called.
        dartState.registerizedMutableVariables.add(loopVariable);
      }
    }
  }

  void _enterForLoopBody(ClosureScope scope,
                         List<LocalElement> loopVariables) {
    assert(scope == null);
    for (LocalElement loopVariable in loopVariables) {
      if (dartState.local2mutable.containsKey(loopVariable)) {
        // Move from [Primitive] into [MutableVariable].
        dartState.registerizedMutableVariables.remove(loopVariable);
        add(new ir.LetMutable(getMutableVariable(loopVariable),
                              environment.lookup(loopVariable)));
      }
    }
  }

  void _enterForLoopUpdate(ClosureScope scope,
                           List<LocalElement> loopVariables) {
    assert(scope == null);
    // Move captured loop variables back into the local environment.
    // The update expression will use the values we put in the environment,
    // and then the environments for the initializer and update will be
    // joined at the head of the body.
    for (LocalElement loopVariable in loopVariables) {
      if (isInMutableVariable(loopVariable)) {
        ir.MutableVariable mutableVariable = getMutableVariable(loopVariable);
        ir.Primitive value =
            addPrimitive(new ir.GetMutableVariable(mutableVariable));
        environment.update(loopVariable, value);
        dartState.registerizedMutableVariables.add(loopVariable);
      }
    }
  }

  void _createFunctionParameter(Local parameterElement) {
    ir.Parameter parameter = new ir.Parameter(parameterElement);
    _parameters.add(parameter);
    if (isInMutableVariable(parameterElement)) {
      state.functionParameters.add(getMutableVariable(parameterElement));
    } else {
      state.functionParameters.add(parameter);
      environment.extend(parameterElement, parameter);
    }
  }

  void _createThisParameter() {
    void create() {
      ir.Parameter thisParameter =
          new ir.Parameter(new ThisParameterLocal(state.currentElement));
      state.thisParameter = thisParameter;
      state.enclosingMethodThisParameter = thisParameter;
    }
    if (state.currentElement.isLocal) return;
    if (state.currentElement.isStatic) return;
    if (state.currentElement.isGenerativeConstructor) {
      create();
      return;
    }
    if (state.currentElement.isStatic) return;
    if (state.currentElement.isInstanceMember) {
      create();
      return;
    }
  }

  void declareLocalVariable(LocalVariableElement variableElement,
                            {ir.Primitive initialValue}) {
    assert(isOpen);
    if (initialValue == null) {
      initialValue = buildNullLiteral();
    }
    if (isInMutableVariable(variableElement)) {
      add(new ir.LetMutable(getMutableVariable(variableElement),
                            initialValue));
    } else {
      initialValue.useElementAsHint(variableElement);
      environment.extend(variableElement, initialValue);
    }
  }

  /// Add [functionElement] to the environment with provided [definition].
  void declareLocalFunction(LocalFunctionElement functionElement,
                            ir.FunctionDefinition definition) {
    assert(isOpen);
    if (isInMutableVariable(functionElement)) {
      ir.MutableVariable variable = getMutableVariable(functionElement);
      add(new ir.DeclareFunction(variable, definition));
    } else {
      ir.CreateFunction prim = addPrimitive(new ir.CreateFunction(definition));
      environment.extend(functionElement, prim);
      prim.useElementAsHint(functionElement);
    }
  }

  /// Create a function expression from [definition].
  ir.Primitive buildFunctionExpression(ir.FunctionDefinition definition) {
    return addPrimitive(new ir.CreateFunction(definition));
  }

  /// Create a read access of [local].
  ir.Primitive buildLocalGet(LocalElement local) {
    assert(isOpen);
    if (isInMutableVariable(local)) {
      // Do not use [local] as a hint on [result]. The variable should always
      // be inlined, but the hint prevents it.
      return addPrimitive(new ir.GetMutableVariable(getMutableVariable(local)));
    } else {
      return environment.lookup(local);
    }
  }

  /// Create a write access to [local] with the provided [value].
  ir.Primitive buildLocalSet(LocalElement local, ir.Primitive value) {
    assert(isOpen);
    if (isInMutableVariable(local)) {
      add(new ir.SetMutableVariable(getMutableVariable(local), value));
    } else {
      value.useElementAsHint(local);
      environment.update(local, value);
    }
    return value;
  }

  ir.Primitive buildThis() {
    return state.enclosingMethodThisParameter;
  }

  ir.Primitive buildSuperInvocation(Element target,
                                    Selector selector,
                                    List<ir.Primitive> arguments) {
    return _buildInvokeSuper(target, selector, arguments);
  }

  @override
  ir.Primitive buildConstructorInvocation(FunctionElement element,
                                          Selector selector,
                                          DartType type,
                                          List<ir.Primitive> arguments) {
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.InvokeConstructor(type, element, selector, k,
            arguments));
  }
}

/// State shared between JsIrBuilders within the same function.
///
/// Note that this is not shared between builders of nested functions.
class JsIrBuilderSharedState {
  /// Maps boxed locals to their location. These locals are not part of
  /// the environment.
  final Map<Local, ClosureLocation> boxedVariables = {};

  /// If non-null, this refers to the receiver (`this`) in the enclosing method.
  ir.Primitive receiver;

  /// `true` when we are currently building expressions inside the initializer
  /// list of a constructor.
  bool inInitializers = false;
}

/// JS-specific subclass of [IrBuilder].
///
/// Inner functions are represented by a [ClosureClassElement], and captured
/// variables are boxed as necessary using [CreateBox], [GetField], [SetField].
class JsIrBuilder extends IrBuilder {
  final JsIrBuilderSharedState jsState;
  final GlobalProgramInformation program;

  IrBuilder _makeInstance() => new JsIrBuilder._blank(program, jsState);
  JsIrBuilder._blank(this.program, this.jsState);

  JsIrBuilder(this.program, ConstantSystem constantSystem,
      ExecutableElement currentElement)
      : jsState = new JsIrBuilderSharedState() {
    _init(constantSystem, currentElement);
  }

  Map<ast.TryStatement, TryStatementInfo> get tryStatements => null;
  Set<Local> get mutableCapturedVariables => null;
  bool isInMutableVariable(Local local) => false;
  void makeMutableVariable(Local local) {}
  void removeMutableVariable(Local local) {}

  void enterInitializers() {
    assert(jsState.inInitializers == false);
    jsState.inInitializers = true;
  }

  void leaveInitializers() {
    assert(jsState.inInitializers == true);
    jsState.inInitializers = false;
  }

  void _enterClosureEnvironment(ClosureEnvironment env) {
    if (env == null) return;

    // Obtain a reference to the function object (this).
    ir.Parameter thisPrim = state.thisParameter;

    // Obtain access to the free variables.
    env.freeVariables.forEach((Local local, ClosureLocation location) {
      if (location.isBox) {
        // Boxed variables are loaded from their box on-demand.
        jsState.boxedVariables[local] = location;
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
      jsState.receiver = environment.lookup(env.thisLocal);
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

  void _enterScope(ClosureScope scope) {
    if (scope == null) return;
    ir.CreateBox boxPrim = addPrimitive(new ir.CreateBox());
    environment.extend(scope.box, boxPrim);
    boxPrim.useElementAsHint(scope.box);
    scope.capturedVariables.forEach((Local local, ClosureLocation location) {
      assert(!jsState.boxedVariables.containsKey(local));
      if (location.isBox) {
        jsState.boxedVariables[local] = location;
      }
    });
  }

  void _createFunctionParameter(Local parameterElement) {
    ir.Parameter parameter = new ir.Parameter(parameterElement);
    _parameters.add(parameter);
    state.functionParameters.add(parameter);
    ClosureLocation location = jsState.boxedVariables[parameterElement];
    if (location != null) {
      add(new ir.SetField(environment.lookup(location.box),
                          location.field,
                          parameter));
    } else {
      environment.extend(parameterElement, parameter);
    }
  }

  void _createThisParameter() {
    if (Elements.isStaticOrTopLevel(state.currentElement)) return;
    if (state.currentElement.isLocal) return;
    state.thisParameter =
        new ir.Parameter(new ThisParameterLocal(state.currentElement));
  }

  void declareLocalVariable(LocalElement variableElement,
                            {ir.Primitive initialValue}) {
    assert(isOpen);
    if (initialValue == null) {
      initialValue = buildNullLiteral();
    }
    ClosureLocation location = jsState.boxedVariables[variableElement];
    if (location != null) {
      add(new ir.SetField(environment.lookup(location.box),
                          location.field,
                          initialValue));
    } else {
      initialValue.useElementAsHint(variableElement);
      environment.extend(variableElement, initialValue);
    }
  }

  /// Add [functionElement] to the environment with provided [definition].
  void declareLocalFunction(LocalFunctionElement functionElement,
                            ClosureClassElement classElement) {
    ir.Primitive closure = buildFunctionExpression(classElement);
    declareLocalVariable(functionElement, initialValue: closure);
  }

  ir.Primitive buildFunctionExpression(ClosureClassElement classElement) {
    List<ir.Primitive> arguments = <ir.Primitive>[];
    for (ClosureFieldElement field in classElement.closureFields) {
      // Captured 'this' is not available as a local in the current environment,
      // so treat that specially.
      ir.Primitive value = field.local is ThisLocal
          ? buildThis()
          : environment.lookup(field.local);
      arguments.add(value);
    }
    return addPrimitive(
        new ir.CreateInstance(classElement, arguments, const <ir.Primitive>[]));
  }

  /// Create a read access of [local].
  ir.Primitive buildLocalGet(LocalElement local) {
    assert(isOpen);
    ClosureLocation location = jsState.boxedVariables[local];
    if (location != null) {
      ir.Primitive result = new ir.GetField(environment.lookup(location.box),
                                            location.field);
      result.useElementAsHint(local);
      return addPrimitive(result);
    } else {
      return environment.lookup(local);
    }
  }

  /// Create a write access to [local] with the provided [value].
  ir.Primitive buildLocalSet(LocalElement local, ir.Primitive value) {
    assert(isOpen);
    ClosureLocation location = jsState.boxedVariables[local];
    if (location != null) {
      add(new ir.SetField(environment.lookup(location.box),
                          location.field,
                          value));
    } else {
      value.useElementAsHint(local);
      environment.update(local, value);
    }
    return value;
  }

  void _enterForLoopInitializer(ClosureScope scope,
                                List<LocalElement> loopVariables) {
    if (scope == null) return;
    // If there are no boxed loop variables, don't create the box here, let
    // it be created inside the body instead.
    if (scope.boxedLoopVariables.isEmpty) return;
    _enterScope(scope);
  }

  void _enterForLoopBody(ClosureScope scope,
                         List<LocalElement> loopVariables) {
    if (scope == null) return;
    // If there are boxed loop variables, the box has already been created
    // at the initializer.
    if (!scope.boxedLoopVariables.isEmpty) return;
    _enterScope(scope);
  }

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
      add(new ir.SetField(newBox, location.field, value));
    }
    environment.update(scope.box, newBox);
  }

  ir.Primitive buildThis() {
    if (jsState.receiver != null) return jsState.receiver;
    return state.thisParameter;
  }

  ir.Primitive buildSuperInvocation(Element target,
                                    Selector selector,
                                    List<ir.Primitive> arguments) {
    // Direct calls to FieldElements are currently problematic because the
    // backend will not issue a getter for the field unless it finds a dynamic
    // access that matches its getter.
    // As a workaround, we generate GetField for this case, although ideally
    // this should be the result of inlining the field's getter.
    if (target is FieldElement) {
      if (selector.isGetter) {
        return addPrimitive(new ir.GetField(buildThis(), target));
      } else {
        assert(selector.isSetter);
        add(new ir.SetField(buildThis(), target, arguments.single));
        return arguments.single;
      }
    } else {
      return _buildInvokeSuper(target, selector, arguments);
    }
  }

  ir.Primitive buildInvokeDirectly(FunctionElement target,
                                   ir.Primitive receiver,
                                   List<ir.Primitive> arguments) {
    assert(isOpen);
    Selector selector =
        new Selector.call(target.name, target.library, arguments.length);
    return _continueWithExpression(
        (k) => new ir.InvokeMethodDirectly(
            receiver, target, selector, k, arguments));
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
      ir.Parameter parameter = createLocalParameter(param);
      state.functionParameters.add(parameter);
    }
    if (closureScope != null) {
      jsState.boxedVariables.addAll(closureScope.capturedVariables);
    }
  }

  @override
  ir.Primitive buildConstructorInvocation(ConstructorElement element,
                                          Selector selector,
                                          DartType type,
                                          List<ir.Primitive> arguments) {
    assert(isOpen);

    ClassElement cls = element.enclosingClass;
    if (program.requiresRuntimeTypesFor(cls)) {
      InterfaceType interface = type;
      Iterable<ir.Primitive> typeArguments =
          interface.typeArguments.map((DartType argument) {
        return type.treatAsRaw
            ? buildNullLiteral()
            : buildTypeExpression(argument);
      });
      arguments = new List<ir.Primitive>.from(arguments)
          ..addAll(typeArguments);
    }
    return _continueWithExpression(
        (k) => new ir.InvokeConstructor(type, element, selector, k,
            arguments));
  }

  ir.Primitive buildTypeExpression(DartType type) {
    if (type is TypeVariableType) {
      return buildTypeVariableAccess(buildThis(), type);
    } else {
      assert(type is InterfaceType);
      List<ir.Primitive> arguments = <ir.Primitive>[];
      type.forEachTypeVariable((TypeVariableType variable) {
        ir.Primitive value = buildTypeVariableAccess(buildThis(), variable);
        arguments.add(value);
      });
      return addPrimitive(new ir.TypeExpression(type, arguments));
    }
  }

  ir.Primitive buildTypeVariableAccess(ir.Primitive target,
                                       TypeVariableType variable) {
    ir.Parameter accessTypeArgumentParameter() {
      for (int i = 0; i < environment.length; i++) {
        Local local = environment.index2variable[i];
        if (local is TypeInformationParameter &&
            local.variable == variable.element) {
          return environment.index2value[i];
        }
      }
      throw 'unable to find constructor parameter for type variable $variable.';
    }

    if (jsState.inInitializers) {
      return accessTypeArgumentParameter();
    } else {
      return addPrimitive(new ir.ReadTypeVariable(variable, target));
    }
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

// TODO(johnniwinther): Support passing of [DartType] for the exception.
class CatchClauseInfo {
  final LocalVariableElement exceptionVariable;
  final LocalVariableElement stackTraceVariable;
  final SubbuildFunction buildCatchBlock;

  CatchClauseInfo({this.exceptionVariable,
                   this.stackTraceVariable,
                   this.buildCatchBlock});
}

/// Synthetic parameter to a JavaScript factory method that takes the type
/// argument given for the type variable [variable].
class TypeInformationParameter implements Local {
  final TypeVariableElement variable;
  final ExecutableElement executableContext;
  TypeInformationParameter(this.variable, this.executableContext);
  String get name => variable.name;
}
