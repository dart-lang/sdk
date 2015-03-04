// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder;

import '../constants/expressions.dart';
import '../constants/values.dart' show PrimitiveConstantValue;
import '../dart_types.dart';
import '../dart2jslib.dart';
import '../elements/elements.dart';
import '../io/source_file.dart';
import '../io/source_information.dart';
import '../tree/tree.dart' as ast;
import '../scanner/scannerlib.dart' show Token, isUserDefinableOperator;
import '../universe/universe.dart' show SelectorKind;
import 'cps_ir_nodes.dart' as ir;
import '../elements/modelx.dart' show SynthesizedConstructorElementX,
    ConstructorBodyElementX, FunctionSignatureX;
import '../closure.dart' hide ClosureScope;
import '../closure.dart' as closurelib;
import '../js_backend/js_backend.dart' show JavaScriptBackend;

part 'cps_ir_builder_visitor.dart';

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

/// A class to collect breaks or continues.
///
/// When visiting a potential target of breaks or continues, any breaks or
/// continues are collected by a JumpCollector and processed later, on demand.
/// The site of the break or continue is represented by a continuation
/// invocation that will have its target and arguments filled in later.
///
/// The environment of the builder at that point is captured and should not
/// be subsequently mutated until the jump is resolved.
class JumpCollector {
  final JumpTarget target;
  final List<ir.InvokeContinuation> _invocations = <ir.InvokeContinuation>[];
  final List<Environment> _environments = <Environment>[];
  final List<Iterable<LocalVariableElement>> boxedTryVariables =
      <Iterable<LocalVariableElement>>[];

  JumpCollector(this.target);

  bool get isEmpty => _invocations.isEmpty;
  int get length => _invocations.length;
  List<ir.InvokeContinuation> get invocations => _invocations;
  List<Environment> get environments => _environments;

  void addJump(IrBuilder builder) {
    // Unbox all variables that were boxed on entry to try blocks between the
    // jump and the target.
    for (Iterable<LocalVariableElement> boxedOnEntry in boxedTryVariables) {
      for (LocalVariableElement variable in boxedOnEntry) {
        assert(builder.isInMutableVariable(variable));
        ir.Primitive value = builder.buildLocalGet(variable);
        builder.environment.update(variable, value);
      }
    }
    ir.InvokeContinuation invoke = new ir.InvokeContinuation.uninitialized();
    builder.add(invoke);
    _invocations.add(invoke);
    _environments.add(builder.environment);
    builder._current = null;
    // TODO(kmillikin): Can we set builder.environment to null to make it
    // less likely to mutate it?
  }

  /// Add a set of variables that were boxed on entry to a try block.
  ///
  /// Jumps from a try block to targets outside have to unbox the variables
  /// that were boxed on entry before invoking the target continuation.  Call
  /// this function before translating a try block and call [leaveTry] after
  /// translating it.
  void enterTry(Iterable<LocalVariableElement> boxedOnEntry) {
    // The boxed variables are maintained as a stack to make leaving easy.
    boxedTryVariables.add(boxedOnEntry);
  }

  /// Remove the most recently added set of variables boxed on entry to a try
  /// block.
  ///
  /// Call [enterTry] before translating a try block and call this function
  /// after translating it.
  void leaveTry() {
    boxedTryVariables.removeLast();
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

  final List<ir.Definition> functionParameters = <ir.Definition>[];

  IrBuilderDelimitedState(this.constantSystem, this.currentElement);
}

/// A factory for building the cps IR.
///
/// [DartIrBuilder] and [JsIrBuilder] implement nested functions and captured
/// variables in different ways.
abstract class IrBuilder {
  IrBuilder _makeInstance();

  /// A map from TryStatements in the AST to their analysis information.
  ///
  /// This includes which variables should be copied into [ir.MutableVariable]s
  /// on entry to the try and copied out on exit.
  Map<ast.TryStatement, TryStatementInfo> get tryStatements;

  /// The set of local variables that will spend their lifetime as
  /// [ir.MutableVariable]s due to being captured by a nested function.
  Set<Local> get mutableCapturedVariables;

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
  ir.Primitive buildLocalGet(LocalElement element);
  ir.Primitive buildLocalSet(LocalElement element, ir.Primitive value);

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
  void _createFunctionParameter(ParameterElement parameterElement);

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
  /// The delimited visitor has its own compile-time environment mapping
  /// local variables to their values, which is initially a copy of the parent
  /// environment.  It has its own context for building an IR expression, so
  /// the built expression is not plugged into the parent's context.
  IrBuilder makeDelimitedBuilder() {
    return _makeInstance()
        ..state = state
        ..environment = new Environment.from(environment);
  }

  /// Construct a visitor for a recursive continuation.
  ///
  /// The recursive continuation builder has fresh parameters (i.e. SSA phis)
  /// for all the local variables in the parent, because the invocation sites
  /// of the continuation are not all known when the builder is created.  The
  /// recursive invocations will be passed values for all the local variables,
  /// which may be eliminated later if they are redundant---if they take on
  /// the same value at all invocation sites.
  IrBuilder makeRecursiveBuilder() {
    IrBuilder inner = _makeInstance()
        ..state = state
        ..environment = new Environment.empty();
    environment.index2variable.forEach(inner.createLocalParameter);
    return inner;
  }

  /// Construct a builder for an inner function.
  IrBuilder makeInnerFunctionBuilder(ExecutableElement currentElement) {
    return _makeInstance()
        ..state = new IrBuilderDelimitedState(state.constantSystem, currentElement)
        ..environment = new Environment.empty();
  }

  bool get isOpen => _root == null || _current != null;


  void buildFieldInitializerHeader({ClosureScope closureScope}) {
    _enterScope(closureScope);
  }

  List<ir.Primitive> buildFunctionHeader(Iterable<ParameterElement> parameters,
                                        {ClosureScope closureScope,
                                         ClosureEnvironment env}) {
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

  // Plug an expression into the 'hole' in the context being accumulated.  The
  // empty context (just a hole) is represented by root (and current) being
  // null.  Since the hole in the current context is filled by this function,
  // the new hole must be in the newly added expression---which becomes the
  // new value of current.
  void add(ir.Expression expr) {
    assert(isOpen);
    if (_root == null) {
      _root = _current = expr;
    } else {
      _current = _current.plug(expr);
    }
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
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.InvokeStatic(element, selector, k, arguments,
                                   sourceInformation));
  }

  ir.Primitive _buildInvokeSuper(Element target,
                                 Selector selector,
                                 List<ir.Primitive> arguments) {
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
    Selector callSelector = new Selector.callClosure(
        selector.argumentCount,
        selector.namedArguments);
    return _buildInvokeDynamic(target, callSelector, arguments);
  }


  /// Create a constant literal from [constant].
  ir.Constant buildConstantLiteral(ConstantExpression constant) {
    assert(isOpen);
    ir.Constant prim = new ir.Constant(constant);
    add(new ir.LetPrim(prim));
    return prim;
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
    ir.Primitive result = new ir.LiteralList(type, values);
    add(new ir.LetPrim(result));
    return result;
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
    ir.Primitive result = new ir.LiteralMap(type, entries);
    add(new ir.LetPrim(result));
    return result;
  }

  /// Creates a conditional expression with the provided [condition] where the
  /// then and else expression are created through the [buildThenExpression] and
  /// [buildElseExpression] functions, respectively.
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
    // continuation.
    assert(environment.length == thenBuilder.environment.length);
    assert(environment.length == elseBuilder.environment.length);
    thenBuilder.environment.extend(null, thenValue);
    elseBuilder.environment.extend(null, elseValue);
    JumpCollector jumps = new JumpCollector(null);
    jumps.addJump(thenBuilder);
    jumps.addJump(elseBuilder);
    ir.Continuation joinContinuation =
        createJoin(environment.length + 1, jumps);

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
    add(new ir.LetCont(joinContinuation,
            new ir.LetCont.many(<ir.Continuation>[thenContinuation,
                                                  elseContinuation],
                new ir.Branch(new ir.IsTrue(condition),
                              thenContinuation,
                              elseContinuation))));
    return (thenValue == elseValue)
        ? thenValue
        : joinContinuation.parameters.last;
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
                                           List<ir.RunnableBody> arguments,
                                           Selector selector) {
    return new ir.SuperInitializer(target, arguments, selector);
  }

  ir.FieldInitializer makeFieldInitializer(FieldElement element,
                                           ir.RunnableBody body) {
    return new ir.FieldInitializer(element, body);
  }

  /// Create a [ir.FieldDefinition] for the current [Element] using [_root] as
  /// the body using [initializer] as the initial value.
  ir.FieldDefinition makeFieldDefinition(ir.Primitive initializer) {
    if (initializer == null) {
      return new ir.FieldDefinition.withoutInitializer(state.currentElement);
    } else {
      ir.RunnableBody body = makeRunnableBody(initializer);
      return new ir.FieldDefinition(state.currentElement, body);
    }
  }

  ir.RunnableBody makeRunnableBody([ir.Primitive value]) {
    if (value == null) {
      _ensureReturn();
    } else {
      buildReturn(value);
    }
    return new ir.RunnableBody(_root, state.returnContinuation);
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
      ir.RunnableBody body = makeRunnableBody();
      return new ir.FunctionDefinition(
          element, state.functionParameters, body,
          state.localConstants, defaults);
    }
  }

  ir.ConstructorDefinition makeConstructorDefinition(
      List<ConstantExpression> defaults, List<ir.Initializer> initializers) {
    FunctionElement element = state.currentElement;
    if (element.isExternal) {
      assert(invariant(element, _root == null,
          message: "Non-empty body for external constructor $element: $_root"));
      assert(invariant(element, state.localConstants.isEmpty,
          message: "Local constants for external constructor $element: "
                   "${state.localConstants}"));
      return new ir.ConstructorDefinition.abstract(
                element, state.functionParameters, defaults);
    }
    ir.RunnableBody body = makeRunnableBody();
    return new ir.ConstructorDefinition(
        element, state.functionParameters, body, initializers,
        state.localConstants, defaults);
  }

  /// Create a super invocation where the method name and the argument structure
  /// are defined by [selector] and the argument values are defined by
  /// [arguments].
  ir.Primitive buildSuperInvocation(Element target,
                                    Selector selector,
                                    List<ir.Primitive> arguments);

  /// Create a setter invocation on the super class where the setter name and
  /// argument are defined by [selector] and [value], respectively.
  void buildSuperSet(Element target, Selector selector, ir.Primitive value) {
    buildSuperInvocation(target, selector, [value]);
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
                              Selector selector,
                              {SourceInformation sourceInformation}) {
    assert(selector.isGetter);
    // TODO(karlklose,sigurdm): build different nodes for getters.
    return _buildInvokeStatic(
        element, selector, const <ir.Primitive>[], sourceInformation);
  }

  /// Create a static setter invocation of [element] where the setter name and
  /// argument are defined by [selector] and [value], respectively.
  ir.Primitive buildStaticSet(Element element,
                              Selector selector,
                              ir.Primitive value,
                              {SourceInformation sourceInformation}) {
    assert(selector.isSetter);
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
                                          List<ir.Primitive> arguments) {
    assert(isOpen);
    return _continueWithExpression(
        (k) => new ir.InvokeConstructor(type, element, selector, k, arguments));
  }

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

    ir.Continuation joinContinuation;  // Null if there is no join.
    if (thenBuilder.isOpen && elseBuilder.isOpen) {
      // There is a join-point continuation.  Build the term
      // 'let cont join(x, ...) = [] in Result' and plug invocations of the
      // join-point continuation into the then and else continuations.
      JumpCollector jumps = new JumpCollector(null);
      jumps.addJump(thenBuilder);
      jumps.addJump(elseBuilder);
      joinContinuation = createJoin(environment.length, jumps);
      result = new ir.LetCont(joinContinuation, result);
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
    if (joinContinuation == null) {
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
    }
  }

  void jumpTo(ir.Continuation continuation) {
    assert(isOpen);
    assert(environment.length >= continuation.parameters.length);
    ir.InvokeContinuation jump = new ir.InvokeContinuation.uninitialized();
    jump.continuation = new ir.Reference(continuation);
    jump.arguments = new List<ir.Reference>.generate(
        continuation.parameters.length, (i) {
      return new ir.Reference(environment[i]);
    });
    add(jump);
    _current = null;
  }

  /// Invoke a join-point continuation that contains arguments for all local
  /// variables.
  ///
  /// Given the continuation and a list of uninitialized invocations, fill
  /// in each invocation with the continuation and appropriate arguments.
  void invokeFullJoin(ir.Continuation join,
                      JumpCollector jumps,
                      {recursive: false}) {
    // TODO(kmillikin): If the JumpCollector collected open IrBuilders instead
    // of pairs of invocations and environments, we could use IrBuilder.jumpTo
    // here --- the code is almost the same.
    join.isRecursive = recursive;
    for (int i = 0; i < jumps.length; ++i) {
      Environment currentEnvironment = jumps.environments[i];
      ir.InvokeContinuation invoke = jumps.invocations[i];
      invoke.continuation = new ir.Reference(join);
      invoke.arguments = new List<ir.Reference>.generate(
          join.parameters.length,
          (i) => new ir.Reference(currentEnvironment[i]));
      invoke.isRecursive = recursive;
    }
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
    // [[initializer]];
    // let cont loop(x, ...) =
    //     let prim cond = [[condition]] in
    //     let cont break() = [[successor]] in
    //     let cont exit() = break(v, ...) in
    //     let cont body() =
    //       let cont continue(x, ...) = [[update]]; loop(v, ...) in
    //       [[body]]; continue(v, ...) in
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

    IrBuilder condBuilder = makeRecursiveBuilder();
    ir.Primitive condition = buildCondition(condBuilder);
    if (condition == null) {
      // If the condition is empty then the body is entered unconditionally.
      condition = condBuilder.buildBooleanLiteral(true);
    }

    JumpCollector breakCollector = new JumpCollector(target);
    JumpCollector continueCollector = new JumpCollector(target);
    state.breakCollectors.add(breakCollector);
    state.continueCollectors.add(continueCollector);

    IrBuilder bodyBuilder = condBuilder.makeDelimitedBuilder();

    bodyBuilder._enterForLoopBody(closureScope, loopVariables);

    buildBody(bodyBuilder);
    assert(state.breakCollectors.last == breakCollector);
    assert(state.continueCollectors.last == continueCollector);
    state.breakCollectors.removeLast();
    state.continueCollectors.removeLast();

    // The binding of the continue continuation should occur as late as
    // possible, that is, at the nearest common ancestor of all the continue
    // sites in the body.  However, that is difficult to compute here, so it
    // is instead placed just outside the body of the body continuation.
    bool hasContinues = !continueCollector.isEmpty;
    IrBuilder updateBuilder = hasContinues
        ? condBuilder.makeRecursiveBuilder()
        : bodyBuilder;
    updateBuilder._enterForLoopUpdate(closureScope, loopVariables);
    buildUpdate(updateBuilder);

    // Create body entry and loop exit continuations and a branch to them.
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation exitContinuation = new ir.Continuation([]);
    // Note the order of continuations: the first one is the one that will
    // be filled by LetCont.plug.
    ir.LetCont branch =
        new ir.LetCont.many(<ir.Continuation>[exitContinuation,
                                              bodyContinuation],
            new ir.Branch(new ir.IsTrue(condition),
                          bodyContinuation,
                          exitContinuation));
    // If there are breaks in the body, then there must be a join-point
    // continuation for the normal exit and the breaks.
    bool hasBreaks = !breakCollector.isEmpty;
    ir.LetCont letJoin;
    if (hasBreaks) {
      letJoin = new ir.LetCont(null, branch);
      condBuilder.add(letJoin);
      condBuilder._current = branch;
    } else {
      condBuilder.add(branch);
    }
    ir.Continuation continueContinuation;
    if (hasContinues) {
      // If there are continues in the body, we need a named continue
      // continuation as a join point.
      continueContinuation = new ir.Continuation(updateBuilder._parameters);
      if (bodyBuilder.isOpen) continueCollector.addJump(bodyBuilder);
      invokeFullJoin(continueContinuation, continueCollector);
    }
    ir.Continuation loopContinuation =
        new ir.Continuation(condBuilder._parameters);
    if (updateBuilder.isOpen) {
      JumpCollector backEdges = new JumpCollector(null);
      backEdges.addJump(updateBuilder);
      invokeFullJoin(loopContinuation, backEdges, recursive: true);
    }

    // Fill in the body and possible continue continuation bodies.  Do this
    // only after it is guaranteed that they are not empty.
    if (hasContinues) {
      continueContinuation.body = updateBuilder._root;
      bodyContinuation.body =
          new ir.LetCont(continueContinuation,
              bodyBuilder._root);
    } else {
      bodyContinuation.body = bodyBuilder._root;
    }

    loopContinuation.body = condBuilder._root;
    add(new ir.LetCont(loopContinuation,
            new ir.InvokeContinuation(loopContinuation,
                environment.index2value)));
    if (hasBreaks) {
      _current = branch;
      environment = condBuilder.environment;
      breakCollector.addJump(this);
      letJoin.continuations =
          <ir.Continuation>[createJoin(environment.length, breakCollector)];
      _current = letJoin;
    } else {
      _current = condBuilder._current;
      environment = condBuilder.environment;
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

    // The condition and body are delimited.
    IrBuilder condBuilder = makeRecursiveBuilder();

    ir.Primitive expressionReceiver = buildExpression(this);
    List<ir.Primitive> emptyArguments = new List<ir.Primitive>();

    ir.Parameter iterator = new ir.Parameter(null);
    ir.Continuation iteratorInvoked = new ir.Continuation([iterator]);
    add(new ir.LetCont(iteratorInvoked,
        new ir.InvokeMethod(expressionReceiver,
            new Selector.getter("iterator", null), iteratorInvoked,
            emptyArguments)));

    ir.Parameter condition = new ir.Parameter(null);
    ir.Continuation moveNextInvoked = new ir.Continuation([condition]);
    condBuilder.add(new ir.LetCont(moveNextInvoked,
        new ir.InvokeMethod(iterator,
            new Selector.call("moveNext", null, 0),
            moveNextInvoked, emptyArguments)));

    JumpCollector breakCollector = new JumpCollector(target);
    JumpCollector continueCollector = new JumpCollector(target);
    state.breakCollectors.add(breakCollector);
    state.continueCollectors.add(continueCollector);

    IrBuilder bodyBuilder = condBuilder.makeDelimitedBuilder();
    bodyBuilder._enterScope(closureScope);
    if (buildVariableDeclaration != null) {
      buildVariableDeclaration(bodyBuilder);
    }

    ir.Parameter currentValue = new ir.Parameter(null);
    ir.Continuation currentInvoked = new ir.Continuation([currentValue]);
    bodyBuilder.add(new ir.LetCont(currentInvoked,
        new ir.InvokeMethod(iterator, new Selector.getter("current", null),
            currentInvoked, emptyArguments)));
    if (Elements.isLocal(variableElement)) {
      bodyBuilder.buildLocalSet(variableElement, currentValue);
    } else if (Elements.isStaticOrTopLevel(variableElement)) {
      bodyBuilder.buildStaticSet(
          variableElement, variableSelector, currentValue);
    } else {
      ir.Primitive receiver = bodyBuilder.buildThis();
      bodyBuilder.buildDynamicSet(receiver, variableSelector, currentValue);
    }

    buildBody(bodyBuilder);
    assert(state.breakCollectors.last == breakCollector);
    assert(state.continueCollectors.last == continueCollector);
    state.breakCollectors.removeLast();
    state.continueCollectors.removeLast();

    // Create body entry and loop exit continuations and a branch to them.
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation exitContinuation = new ir.Continuation([]);
    // Note the order of continuations: the first one is the one that will
    // be filled by LetCont.plug.
    ir.LetCont branch =
        new ir.LetCont.many(<ir.Continuation>[exitContinuation,
                                              bodyContinuation],
            new ir.Branch(new ir.IsTrue(condition),
                          bodyContinuation,
                          exitContinuation));
    // If there are breaks in the body, then there must be a join-point
    // continuation for the normal exit and the breaks.
    bool hasBreaks = !breakCollector.isEmpty;
    ir.LetCont letJoin;
    if (hasBreaks) {
      letJoin = new ir.LetCont(null, branch);
      condBuilder.add(letJoin);
      condBuilder._current = branch;
    } else {
      condBuilder.add(branch);
    }
    ir.Continuation loopContinuation =
        new ir.Continuation(condBuilder._parameters);
    if (bodyBuilder.isOpen) continueCollector.addJump(bodyBuilder);
    invokeFullJoin(
        loopContinuation, continueCollector, recursive: true);
    bodyContinuation.body = bodyBuilder._root;

    loopContinuation.body = condBuilder._root;
    add(new ir.LetCont(loopContinuation,
            new ir.InvokeContinuation(loopContinuation,
                                      environment.index2value)));
    if (hasBreaks) {
      _current = branch;
      environment = condBuilder.environment;
      breakCollector.addJump(this);
      letJoin.continuations =
          <ir.Continuation>[createJoin(environment.length, breakCollector)];
      _current = letJoin;
    } else {
      _current = condBuilder._current;
      environment = condBuilder.environment;
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
    //     let cont break() = [[successor]] in
    //     let cont exit() = break(v, ...) in
    //     let cont body() = [[body]]; continue(v, ...) in
    //     branch cond (body, exit) in
    // continue(v, ...)
    //
    // If there are no breaks in the body, the break continuation is inlined
    // in the exit continuation (i.e., the translation of the successor
    // statement occurs in the exit continuation).

    // The condition and body are delimited.
    IrBuilder condBuilder = makeRecursiveBuilder();
    ir.Primitive condition = buildCondition(condBuilder);

    JumpCollector breakCollector = new JumpCollector(target);
    JumpCollector continueCollector = new JumpCollector(target);
    state.breakCollectors.add(breakCollector);
    state.continueCollectors.add(continueCollector);

    IrBuilder bodyBuilder = condBuilder.makeDelimitedBuilder();
    bodyBuilder._enterScope(closureScope);
    buildBody(bodyBuilder);
    assert(state.breakCollectors.last == breakCollector);
    assert(state.continueCollectors.last == continueCollector);
    state.breakCollectors.removeLast();
    state.continueCollectors.removeLast();

    // Create body entry and loop exit continuations and a branch to them.
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation exitContinuation = new ir.Continuation([]);
    // Note the order of continuations: the first one is the one that will
    // be filled by LetCont.plug.
    ir.LetCont branch =
        new ir.LetCont.many(<ir.Continuation>[exitContinuation,
                                              bodyContinuation],
            new ir.Branch(new ir.IsTrue(condition),
                          bodyContinuation,
                          exitContinuation));
    // If there are breaks in the body, then there must be a join-point
    // continuation for the normal exit and the breaks.
    bool hasBreaks = !breakCollector.isEmpty;
    ir.LetCont letJoin;
    if (hasBreaks) {
      letJoin = new ir.LetCont(null, branch);
      condBuilder.add(letJoin);
      condBuilder._current = branch;
    } else {
      condBuilder.add(branch);
    }
    ir.Continuation loopContinuation =
        new ir.Continuation(condBuilder._parameters);
    if (bodyBuilder.isOpen) continueCollector.addJump(bodyBuilder);
    invokeFullJoin(loopContinuation, continueCollector, recursive: true);
    bodyContinuation.body = bodyBuilder._root;

    loopContinuation.body = condBuilder._root;
    add(new ir.LetCont(loopContinuation,
            new ir.InvokeContinuation(loopContinuation,
                                      environment.index2value)));
    if (hasBreaks) {
      _current = branch;
      environment = condBuilder.environment;
      breakCollector.addJump(this);
      letJoin.continuations =
          <ir.Continuation>[createJoin(environment.length, breakCollector)];
      _current = letJoin;
    } else {
      _current = condBuilder._current;
      environment = condBuilder.environment;
    }
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
        collector.addJump(this);
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
    emptyBuilder.environment.extend(null, leftBool);
    rightTrueBuilder.environment.extend(null, rightTrue);
    rightFalseBuilder.environment.extend(null, rightFalse);

    // Wire up two continuations for the left subexpression, two continuations
    // for the right subexpression, and a three-way join continuation.
    JumpCollector jumps = new JumpCollector(null);
    jumps.addJump(emptyBuilder);
    jumps.addJump(rightTrueBuilder);
    jumps.addJump(rightFalseBuilder);
    ir.Continuation joinContinuation =
        createJoin(environment.length + 1, jumps);
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

    add(new ir.LetCont(joinContinuation,
            new ir.LetCont.many(<ir.Continuation>[leftTrueContinuation,
                                                  leftFalseContinuation],
                new ir.Branch(new ir.IsTrue(leftValue),
                              leftTrueContinuation,
                              leftFalseContinuation))));
    // There is always a join parameter for the result value, because it
    // is different on at least two paths.
    return joinContinuation.parameters.last;
  }

  /// Create a non-recursive join-point continuation.
  ///
  /// Given the environment length at the join point and a list of
  /// jumps that should reach the join point, create a join-point
  /// continuation.  The join-point continuation has a parameter for each
  /// variable that has different values reaching on different paths.
  ///
  /// The jumps are uninitialized [ir.InvokeContinuation] expressions.
  /// They are filled in with the target continuation and appropriate
  /// arguments.
  ///
  /// As a side effect, the environment of this builder is updated to include
  /// the join-point continuation parameters.
  ir.Continuation createJoin(int environmentLength, JumpCollector jumps) {
    assert(jumps.length >= 2);

    // Compute which values are identical on all paths reaching the join.
    // Handle the common case of a pair of contexts efficiently.
    Environment first = jumps.environments[0];
    Environment second = jumps.environments[1];
    assert(environmentLength <= first.length);
    assert(environmentLength <= second.length);
    assert(first.sameDomain(environmentLength, second));
    // A running count of the join-point parameters.
    int parameterCount = 0;
    // The null elements of common correspond to required parameters of the
    // join-point continuation.
    List<ir.Primitive> common =
        new List<ir.Primitive>.generate(environmentLength,
            (i) {
              ir.Primitive candidate = first[i];
              if (second[i] == candidate) {
                return candidate;
              } else {
                ++parameterCount;
                return null;
              }
            });
    // If there is already a parameter for each variable, the other
    // environments do not need to be considered.
    if (parameterCount < environmentLength) {
      for (int i = 0; i < environmentLength; ++i) {
        ir.Primitive candidate = common[i];
        if (candidate == null) continue;
        for (Environment current in jumps.environments.skip(2)) {
          assert(environmentLength <= current.length);
          assert(first.sameDomain(environmentLength, current));
          if (candidate != current[i]) {
            common[i] = null;
            ++parameterCount;
            break;
          }
        }
        if (parameterCount >= environmentLength) break;
      }
    }

    // Create the join point continuation.
    List<ir.Parameter> parameters = <ir.Parameter>[];
    parameters.length = parameterCount;
    int index = 0;
    for (int i = 0; i < environmentLength; ++i) {
      if (common[i] == null) {
        parameters[index++] = new ir.Parameter(first.index2variable[i]);
      }
    }
    assert(index == parameterCount);
    ir.Continuation join = new ir.Continuation(parameters);

    // Fill in all the continuation invocations.
    for (int i = 0; i < jumps.length; ++i) {
      Environment currentEnvironment = jumps.environments[i];
      ir.InvokeContinuation invoke = jumps.invocations[i];
      // Sharing this.environment with one of the invocations will not do
      // the right thing (this.environment has already been mutated).
      List<ir.Reference> arguments = <ir.Reference>[];
      arguments.length = parameterCount;
      int index = 0;
      for (int i = 0; i < environmentLength; ++i) {
        if (common[i] == null) {
          arguments[index++] = new ir.Reference(currentEnvironment[i]);
        }
      }
      invoke.continuation = new ir.Reference(join);
      invoke.arguments = arguments;
    }

    // Mutate this.environment to be the environment at the join point.  Do
    // this after adding the continuation invocations, because this.environment
    // might be collected by the jump collector and so the old environment
    // values are needed for the continuation invocation.
    //
    // Iterate to environment.length because environmentLength includes values
    // outside the environment which are 'phantom' variables used for the
    // values of expressions like &&, ||, and ?:.
    index = 0;
    for (int i = 0; i < environment.length; ++i) {
      if (common[i] == null) {
        environment.index2value[i] = parameters[index++];
      }
    }

    return join;
  }
}

/// Shared state between DartIrBuilders within the same method.
class DartIrBuilderSharedState {
  /// Maps local variables to their corresponding [MutableVariable] object.
  final Map<Local, ir.MutableVariable> local2mutable =
      <Local, ir.MutableVariable>{};

  final DartCapturedVariables capturedVariables;

  /// Creates a [MutableVariable] for the given local.
  void makeMutableVariable(Local local) {
    ir.MutableVariable variable =
        new ir.MutableVariable(local.executableContext, local);
    local2mutable[local] = variable;
  }

  /// [MutableVariable]s that should temporarily be treated as registers.
  final Set<Local> registerizedMutableVariables = new Set<Local>();

  DartIrBuilderSharedState(this.capturedVariables) {
    capturedVariables.capturedVariables.forEach(makeMutableVariable);
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
                DartCapturedVariables capturedVariables)
      : dartState = new DartIrBuilderSharedState(capturedVariables) {
    _init(constantSystem, currentElement);
  }

  Map<ast.TryStatement, TryStatementInfo> get tryStatements {
    return dartState.capturedVariables.tryStatements;
  }

  Set<Local> get mutableCapturedVariables {
    return dartState.capturedVariables.capturedVariables;
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
        ir.Primitive get = new ir.GetMutableVariable(mutableVariable);
        add(new ir.LetPrim(get));
        environment.update(loopVariable, get);
        dartState.registerizedMutableVariables.add(loopVariable);
      }
    }
  }

  void _createFunctionParameter(ParameterElement parameterElement) {
    ir.Parameter parameter = new ir.Parameter(parameterElement);
    _parameters.add(parameter);
    if (isInMutableVariable(parameterElement)) {
      state.functionParameters.add(getMutableVariable(parameterElement));
    } else {
      state.functionParameters.add(parameter);
      environment.extend(parameterElement, parameter);
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
      ir.CreateFunction prim = new ir.CreateFunction(definition);
      add(new ir.LetPrim(prim));
      environment.extend(functionElement, prim);
      prim.useElementAsHint(functionElement);
    }
  }

  /// Create a function expression from [definition].
  ir.Primitive buildFunctionExpression(ir.FunctionDefinition definition) {
    ir.CreateFunction prim = new ir.CreateFunction(definition);
    add(new ir.LetPrim(prim));
    return prim;
  }

  /// Create a read access of [local].
  ir.Primitive buildLocalGet(LocalElement local) {
    assert(isOpen);
    if (isInMutableVariable(local)) {
      // Do not use [local] as a hint on [result]. The variable should always
      // be inlined, but the hint prevents it.
      ir.Primitive result =
          new ir.GetMutableVariable(getMutableVariable(local));
      add(new ir.LetPrim(result));
      return result;
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
    ir.Primitive thisPrim = new ir.This();
    add(new ir.LetPrim(thisPrim));
    return thisPrim;
  }

  ir.Primitive buildSuperInvocation(Element target,
                                    Selector selector,
                                    List<ir.Primitive> arguments) {
    return _buildInvokeSuper(target, selector, arguments);
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
}

/// JS-specific subclass of [IrBuilder].
///
/// Inner functions are represented by a [ClosureClassElement], and captured
/// variables are boxed as necessary using [CreateBox], [GetField], [SetField].
class JsIrBuilder extends IrBuilder {
  final JsIrBuilderSharedState jsState;

  IrBuilder _makeInstance() => new JsIrBuilder._blank(jsState);
  JsIrBuilder._blank(this.jsState);

  JsIrBuilder(ConstantSystem constantSystem, ExecutableElement currentElement)
      : jsState = new JsIrBuilderSharedState() {
    _init(constantSystem, currentElement);
  }

  Map<ast.TryStatement, TryStatementInfo> get tryStatements => null;
  Set<Local> get mutableCapturedVariables => null;
  bool isInMutableVariable(Local local) => false;
  void makeMutableVariable(Local local) {}
  void removeMutableVariable(Local local) {}

  void _enterClosureEnvironment(ClosureEnvironment env) {
    if (env == null) return;

    // Obtain a reference to the function object (this).
    ir.Primitive thisPrim = new ir.This();
    add(new ir.LetPrim(thisPrim));

    // Obtain access to the free variables.
    env.freeVariables.forEach((Local local, ClosureLocation location) {
      if (location.isBox) {
        // Boxed variables are loaded from their box on-demand.
        jsState.boxedVariables[local] = location;
      } else {
        // Unboxed variables are loaded from the function object immediately.
        // This includes BoxLocals which are themselves unboxed variables.
        ir.Primitive load = new ir.GetField(thisPrim, location.field);
        add(new ir.LetPrim(load));
        environment.extend(local, load);
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

  void _enterScope(ClosureScope scope) {
    if (scope == null) return;
    ir.CreateBox boxPrim = new ir.CreateBox();
    add(new ir.LetPrim(boxPrim));
    environment.extend(scope.box, boxPrim);
    boxPrim.useElementAsHint(scope.box);
    scope.capturedVariables.forEach((Local local, ClosureLocation location) {
      assert(!jsState.boxedVariables.containsKey(local));
      if (location.isBox) {
        jsState.boxedVariables[local] = location;
      }
    });
  }

  void _createFunctionParameter(ParameterElement parameterElement) {
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
    ir.Primitive closure = new ir.CreateInstance(classElement, arguments);
    add(new ir.LetPrim(closure));
    return closure;
  }

  /// Create a read access of [local].
  ir.Primitive buildLocalGet(LocalElement local) {
    assert(isOpen);
    ClosureLocation location = jsState.boxedVariables[local];
    if (location != null) {
      ir.Primitive result = new ir.GetField(environment.lookup(location.box),
                                            location.field);
      result.useElementAsHint(local);
      add(new ir.LetPrim(result));
      return result;
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
    ir.Primitive newBox = new ir.CreateBox();
    newBox.useElementAsHint(scope.box);
    add(new ir.LetPrim(newBox));
    for (VariableElement loopVar in scope.boxedLoopVariables) {
      ClosureLocation location = scope.capturedVariables[loopVar];
      ir.Primitive get = new ir.GetField(box, location.field);
      add(new ir.LetPrim(get));
      add(new ir.SetField(newBox, location.field, get));
    }
    environment.update(scope.box, newBox);
  }

  ir.Primitive buildThis() {
    if (jsState.receiver != null) return jsState.receiver;
    ir.Primitive thisPrim = new ir.This();
    add(new ir.LetPrim(thisPrim));
    return thisPrim;
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
        ir.Primitive get = new ir.GetField(buildThis(), target);
        add(new ir.LetPrim(get));
        return get;
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
    for (Local param in parameters) {
      ir.Parameter parameter = createLocalParameter(param);
      state.functionParameters.add(parameter);
    }
    if (closureScope != null) {
      jsState.boxedVariables.addAll(closureScope.capturedVariables);
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
