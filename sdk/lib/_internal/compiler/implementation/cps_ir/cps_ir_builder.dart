// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder;

import '../constants/expressions.dart';
import '../constants/values.dart' show PrimitiveConstantValue;
import '../dart_backend/dart_backend.dart' show DartBackend;
import '../dart_types.dart';
import '../dart2jslib.dart';
import '../elements/elements.dart';
import '../source_file.dart';
import '../tree/tree.dart' as ast;
import '../scanner/scannerlib.dart' show Token, isUserDefinableOperator;
import '../universe/universe.dart' show SelectorKind;
import 'cps_ir_nodes.dart' as ir;

part 'cps_ir_builder_visitor.dart';

/// A mapping from variable elements to their compile-time values.
///
/// Map elements denoted by parameters and local variables to the
/// [ir.Primitive] that is their value.  Parameters and locals are
/// assigned indexes which can be used to refer to them.
class Environment {
  /// A map from elements to their environment index.
  final Map<Element, int> variable2index;

  /// A reverse map from environment indexes to the variable.
  final List<Element> index2variable;

  /// A map from environment indexes to their value.
  final List<ir.Primitive> index2value;

  Environment.empty()
      : variable2index = <Element, int>{},
        index2variable = <Element>[],
        index2value = <ir.Primitive>[];

  /// Construct an environment that is a copy of another one.
  ///
  /// The mapping from elements to indexes is shared, not copied.
  Environment.from(Environment other)
      : variable2index = other.variable2index,
        index2variable = new List<Element>.from(other.index2variable),
        index2value = new List<ir.Primitive>.from(other.index2value);

  get length => index2variable.length;

  ir.Primitive operator [](int index) => index2value[index];

  void extend(Element element, ir.Primitive value) {
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

  ir.Primitive lookup(Element element) {
    assert(!element.isConst);
    assert(invariant(element, variable2index.containsKey(element),
                     message: "Unknown variable: $element."));
    return index2value[variable2index[element]];
  }

  void update(Element element, ir.Primitive value) {
    index2value[variable2index[element]] = value;
  }

  /// Verify that the variable2index and index2variable maps agree up to the
  /// index [length] exclusive.
  bool sameDomain(int length, Environment other) {
    assert(this.length >= length);
    assert(other.length >= length);
    for (int i = 0; i < length; ++i) {
      // An index maps to the same variable in both environments.
      Element variable = index2variable[i];
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

  JumpCollector(this.target);

  bool get isEmpty => _invocations.isEmpty;
  int get length => _invocations.length;
  List<ir.InvokeContinuation> get invocations => _invocations;
  List<Environment> get environments => _environments;

  void addJump(IrBuilder builder) {
    ir.InvokeContinuation invoke = new ir.InvokeContinuation.uninitialized();
    builder.add(invoke);
    _invocations.add(invoke);
    _environments.add(builder.environment);
    builder._current = null;
    // TODO(kmillikin): Can we set builder.environment to null to make it
    // less likely to mutate it?
  }
}

/// Mixin that provided encapsulated access to nested builders.
class IrBuilderMixin {
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
}


/// Shared state between nested builders.
class IrBuilderSharedState {
  final ConstantSystem constantSystem;

  /// A stack of collectors for breaks.
  final List<JumpCollector> breakCollectors = <JumpCollector>[];

  /// A stack of collectors for continues.
  final List<JumpCollector> continueCollectors = <JumpCollector>[];

  final List<ConstDeclaration> localConstants = <ConstDeclaration>[];

  final Iterable<Entity> closureLocals;

  final FunctionElement currentFunction;

  final ir.Continuation returnContinuation = new ir.Continuation.retrn();

  IrBuilderSharedState(this.constantSystem,
                       this.currentFunction,
                       this.closureLocals);
}

/// A factory for building the cps IR.
class IrBuilder {
  // TODO(johnniwinther): Make these field final and remove the default values
  // when [IrBuilder] is a property of [IrBuilderVisitor] instead of a mixin.

  final List<ir.Parameter> _parameters = <ir.Parameter>[];

  final IrBuilderSharedState state;

  /// A map from variable indexes to their values.
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

  IrBuilder(ConstantSystem constantSystem,
            FunctionElement currentFunction,
            Iterable<Entity> closureLocals)
      : this.state = new IrBuilderSharedState(
            constantSystem, currentFunction, closureLocals),
        this.environment = new Environment.empty();

  /// Construct a delimited visitor for visiting a subtree.
  ///
  /// The delimited visitor has its own compile-time environment mapping
  /// local variables to their values, which is initially a copy of the parent
  /// environment.  It has its own context for building an IR expression, so
  /// the built expression is not plugged into the parent's context.
  IrBuilder.delimited(IrBuilder parent)
      : this.state = parent.state,
        this.environment = new Environment.from(parent.environment);

  /// Construct a visitor for a recursive continuation.
  ///
  /// The recursive continuation builder has fresh parameters (i.e. SSA phis)
  /// for all the local variables in the parent, because the invocation sites
  /// of the continuation are not all known when the builder is created.  The
  /// recursive invocations will be passed values for all the local variables,
  /// which may be eliminated later if they are redundant---if they take on
  /// the same value at all invocation sites.
  IrBuilder.recursive(IrBuilder parent)
      : this.state = parent.state,
        this.environment = new Environment.empty() {
    parent.environment.index2variable.forEach(createParameter);
  }


  bool get isOpen => _root == null || _current != null;

  /// Create a parameter for [parameterElement] and add it to the current
  /// environment.
  ///
  /// [isClosureVariable] marks whether [parameterElement] is accessed from an
  /// inner function.
  void createParameter(LocalElement parameterElement,
                       {bool isClosureVariable: false}) {
    ir.Parameter parameter = new ir.Parameter(parameterElement);
    _parameters.add(parameter);
    if (isClosureVariable) {
      add(new ir.SetClosureVariable(parameterElement, parameter));
    } else {
      environment.extend(parameterElement, parameter);
    }
  }

  /// Add the constant [variableElement] to the environment with [value] as its
  /// constant value.
  void declareLocalConstant(LocalVariableElement variableElement,
                            ConstantExpression value) {
    state.localConstants.add(new ConstDeclaration(variableElement, value));
  }

  /// Add [variableElement] to the environment with [initialValue] as its
  /// initial value.
  ///
  /// [isClosureVariable] marks whether [variableElement] is accessed from an
  /// inner function.
  void declareLocalVariable(LocalVariableElement variableElement,
                            {ir.Primitive initialValue,
                             bool isClosureVariable: false}) {
    assert(isOpen);
    if (initialValue == null) {
      // TODO(kmillikin): Consider pooling constants.
      // The initial value is null.
      initialValue = makePrimConst(state.constantSystem.createNull());
      add(new ir.LetPrim(initialValue));
    }
    if (isClosureVariable) {
      add(new ir.SetClosureVariable(variableElement,
                                    initialValue,
                                    isDeclaration: true));
    } else {
      // In case a primitive was introduced for the initializer expression,
      // use this variable element to help derive a good name for it.
      initialValue.useElementAsHint(variableElement);
      environment.extend(variableElement, initialValue);
    }
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

  ir.Primitive continueWithExpression(ir.Expression build(ir.Continuation k)) {
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.Expression expression = build(k);
    add(new ir.LetCont(k, expression));
    return v;
  }

  ir.Constant makeConst(ConstantExpression exp) {
    return new ir.Constant(exp);
  }

  ir.Constant makePrimConst(PrimitiveConstantValue value) {
    return makeConst(new PrimitiveConstantExpression(value));
  }

  // TODO(johnniwinther): Build constants directly through [ConstExp] when these
  // are created from analyzer2dart.
  ir.Node buildPrimConst(PrimitiveConstantValue constant) {
    assert(isOpen);
    ir.Node prim = makePrimConst(constant);
    add(new ir.LetPrim(prim));
    return prim;
  }

  /// Create an integer literal.
  ir.Constant buildIntegerLiteral(int value) {
    return buildPrimConst(state.constantSystem.createInt(value));
  }

  /// Create an double literal.
  ir.Constant buildDoubleLiteral(double value) {
    return buildPrimConst(state.constantSystem.createDouble(value));
  }

  /// Create an bool literal.
  ir.Constant buildBooleanLiteral(bool value) {
    return buildPrimConst(state.constantSystem.createBool(value));
  }

  /// Create an null literal.
  ir.Constant buildNullLiteral() {
    return buildPrimConst(state.constantSystem.createNull());
  }

  /// Create a string literal.
  ir.Constant buildStringLiteral(String value) {
    return buildPrimConst(
        state.constantSystem.createString(new ast.DartString.literal(value)));
  }

  /// Create a get access of [local].
  ir.Primitive buildLocalGet(Element local) {
    assert(isOpen);
    return environment.lookup(local);
  }

  /// Create a get access of the static [element].
  ir.Primitive buildStaticGet(Element element, Selector selector) {
    assert(isOpen);
    assert(selector.isGetter);
    return continueWithExpression(
        (k) => new ir.InvokeStatic(
            element, selector, k, const <ir.Definition>[]));
  }

  /// Create a dynamic get access on [receiver] where the property is defined
  /// by the getter [selector].
  ir.Primitive buildDynamicGet(ir.Primitive receiver, Selector selector) {
    assert(isOpen);
    assert(selector.isGetter);
    return continueWithExpression(
        (k) => new ir.InvokeMethod(
            receiver, selector, k, const <ir.Definition>[]));
  }

  /**
   * Add an explicit `return null` for functions that don't have a return
   * statement on each branch. This includes functions with an empty body,
   * such as `foo(){ }`.
   */
  void ensureReturn() {
    if (!isOpen) return;
    ir.Constant constant = makePrimConst(state.constantSystem.createNull());
    add(new ir.LetPrim(constant));
    add(new ir.InvokeContinuation(state.returnContinuation, [constant]));
    _current = null;
  }

  /// Create a [ir.FunctionDefinition] for [element] using [_root] as the body.
  ///
  /// Parameters must be created before the construction of the body using
  /// [createParameter].
  ir.FunctionDefinition buildFunctionDefinition(
      FunctionElement element,
      List<ConstantExpression> defaults) {
    if (!element.isAbstract) {
      ensureReturn();
      return new ir.FunctionDefinition(
          element, state.returnContinuation, _parameters, _root,
          state.localConstants, defaults);
    } else {
      assert(invariant(element, _root == null,
          message: "Non-empty body for abstract method $element: $_root"));
      assert(invariant(element, state.localConstants.isEmpty,
          message: "Local constants for abstract method $element: "
                   "${state.localConstants}"));
      return new ir.FunctionDefinition.abstract(
                element, _parameters, defaults);
    }
  }


  /// Create a super invocation with method name and arguments structure defined
  /// by [selector] and argument values defined by [arguments].
  ir.Primitive buildSuperInvocation(Selector selector,
                                    List<ir.Definition> arguments) {
    assert(isOpen);
    return continueWithExpression(
        (k) => new ir.InvokeSuperMethod(selector, k, arguments));

  }

  /// Create a dynamic invocation on [receiver] with method name and arguments
  /// structure defined by [selector] and argument values defined by
  /// [arguments].
  ir.Primitive buildDynamicInvocation(ir.Definition receiver,
                                      Selector selector,
                                      List<ir.Definition> arguments) {
    assert(isOpen);
    return continueWithExpression(
        (k) => new ir.InvokeMethod(receiver, selector, k, arguments));
  }

  /// Create a static invocation of [element] with arguments structure defined
  /// by [selector] and argument values defined by [arguments].
  ir.Primitive buildStaticInvocation(Element element,
                                     Selector selector,
                                     List<ir.Definition> arguments) {
    return continueWithExpression(
        (k) => new ir.InvokeStatic(element, selector, k, arguments));
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
      value = makePrimConst(state.constantSystem.createNull());
      add(new ir.LetPrim(value));
    }
    add(new ir.InvokeContinuation(state.returnContinuation, [value]));
    _current = null;
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

    ir.Constant trueConstant =
        makePrimConst(state.constantSystem.createBool(true));
    ir.Constant falseConstant =
        makePrimConst(state.constantSystem.createBool(false));

    thenContinuation.body = new ir.LetPrim(falseConstant)
        ..plug(new ir.InvokeContinuation(joinContinuation, [falseConstant]));
    elseContinuation.body = new ir.LetPrim(trueConstant)
        ..plug(new ir.InvokeContinuation(joinContinuation, [trueConstant]));

    add(new ir.LetCont(joinContinuation,
          new ir.LetCont(thenContinuation,
            new ir.LetCont(elseContinuation,
              new ir.Branch(new ir.IsTrue(condition),
                            thenContinuation,
                            elseContinuation)))));
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

    IrBuilder rightBuilder = new IrBuilder.delimited(this);
    ir.Primitive rightValue = buildRightValue(rightBuilder);
    // A dummy empty target for the branch on the left subexpression branch.
    // This enables using the same infrastructure for join-point continuations
    // as in visitIf and visitConditional.  It will hold a definition of the
    // appropriate constant and an invocation of the join-point continuation.
    IrBuilder emptyBuilder = new IrBuilder.delimited(this);
    // Dummy empty targets for right true and right false.  They hold
    // definitions of the appropriate constant and an invocation of the
    // join-point continuation.
    IrBuilder rightTrueBuilder = new IrBuilder.delimited(rightBuilder);
    IrBuilder rightFalseBuilder = new IrBuilder.delimited(rightBuilder);

    // If we don't evaluate the right subexpression, the value of the whole
    // expression is this constant.
    ir.Constant leftBool = emptyBuilder.makePrimConst(
        emptyBuilder.state.constantSystem.createBool(isLazyOr));
    // If we do evaluate the right subexpression, the value of the expression
    // is a true or false constant.
    ir.Constant rightTrue = rightTrueBuilder.makePrimConst(
        rightTrueBuilder.state.constantSystem.createBool(true));
    ir.Constant rightFalse = rightFalseBuilder.makePrimConst(
        rightFalseBuilder.state.constantSystem.createBool(false));
    emptyBuilder.add(new ir.LetPrim(leftBool));
    rightTrueBuilder.add(new ir.LetPrim(rightTrue));
    rightFalseBuilder.add(new ir.LetPrim(rightFalse));

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
        new ir.LetCont(rightTrueContinuation,
            new ir.LetCont(rightFalseContinuation,
                new ir.Branch(new ir.IsTrue(rightValue),
                              rightTrueContinuation,
                              rightFalseContinuation))));
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
            new ir.LetCont(leftTrueContinuation,
                new ir.LetCont(leftFalseContinuation,
                    new ir.Branch(new ir.IsTrue(leftValue),
                                  leftTrueContinuation,
                                  leftFalseContinuation)))));
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
