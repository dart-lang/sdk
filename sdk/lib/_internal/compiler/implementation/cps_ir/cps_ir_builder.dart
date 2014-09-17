// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder;

import 'cps_ir_nodes.dart' as ir;
import '../elements/elements.dart';
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../source_file.dart';
import '../tree/tree.dart' as ast;
import '../scanner/scannerlib.dart' show Token, isUserDefinableOperator;
import '../dart_backend/dart_backend.dart' show DartBackend;
import '../universe/universe.dart' show SelectorKind;
import 'const_expression.dart';

/**
 * This task iterates through all resolved elements and builds [ir.Node]s. The
 * nodes are stored in the [nodes] map and accessible through [hasIr] and
 * [getIr].
 *
 * The functionality of the IrNodes is added gradually, therefore elements might
 * have an IR or not, depending on the language features that are used. For
 * elements that do have an IR, the tree [ast.Node]s and the [Token]s are not
 * used in the rest of the compilation. This is ensured by setting the element's
 * cached tree to `null` and also breaking the token stream to crash future
 * attempts to parse.
 *
 * The type inferrer works on either IR nodes or tree nodes. The IR nodes are
 * then translated into the SSA form for optimizations and code generation.
 * Long-term, once the IR supports the full language, the backend can be
 * re-implemented to work directly on the IR.
 */
class IrBuilderTask extends CompilerTask {
  final Map<Element, ir.FunctionDefinition> nodes =
      <Element, ir.FunctionDefinition>{};

  IrBuilderTask(Compiler compiler) : super(compiler);

  String get name => 'IR builder';

  bool hasIr(Element element) => nodes.containsKey(element.implementation);

  ir.FunctionDefinition getIr(Element element) => nodes[element.implementation];

  void buildNodes({bool useNewBackend: false}) {
    if (!irEnabled(useNewBackend: useNewBackend)) return;
    measure(() {
      Set<Element> resolved = compiler.enqueuer.resolution.resolvedElements;
      resolved.forEach((AstElement element) {
        if (canBuild(element)) {
          TreeElements elementsMapping = element.resolvedAst.elements;
          element = element.implementation;
          compiler.withCurrentElement(element, () {
            SourceFile sourceFile = elementSourceFile(element);
            IrBuilderVisitor builder =
                new IrBuilderVisitor(elementsMapping, compiler, sourceFile);
            ir.FunctionDefinition function;
            ElementKind kind = element.kind;
            if (kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
              // TODO(lry): build ir for constructors.
            } else if (element.isDeferredLoaderGetter) {
              // TODO(sigurdm): Build ir for deferred loader functions.
            } else if (kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY ||
                kind == ElementKind.FUNCTION ||
                kind == ElementKind.GETTER ||
                kind == ElementKind.SETTER) {
              function = builder.buildFunction(element);
            } else if (kind == ElementKind.FIELD) {
              // TODO(lry): build ir for lazy initializers of static fields.
            } else {
              compiler.internalError(element, 'Unexpected element kind $kind.');
            }

            if (function != null) {
              nodes[element] = function;
              compiler.tracer.traceCompilation(element.name, null);
              compiler.tracer.traceGraph("IR Builder", function);
            }
          });
        }
      });
    });
  }

  bool irEnabled({bool useNewBackend: false}) {
    // TODO(lry): support checked-mode checks.
    return (useNewBackend || const bool.fromEnvironment('USE_NEW_BACKEND')) &&
        compiler.backend is DartBackend &&
        !compiler.enableTypeAssertions &&
        !compiler.enableConcreteTypeInference;
  }

  bool canBuild(Element element) {
    // TODO(lry): support lazy initializers.
    FunctionElement function = element.asFunctionElement();
    if (function == null) return false;

    if (!compiler.backend.shouldOutput(function)) return false;

    // TODO(lry): support native functions (also in [visitReturn]).
    if (function.isNative) return false;

    // TODO(kmillikin,sigurdm): support syntax for redirecting factory
    if (function is ConstructorElement && function.isRedirectingFactory) {
      return false;
    }
    // TODO(kmillikin,sigurdm): support syntax for factory constructors
    if (function is ConstructorElement && function.isFactoryConstructor) {
      return false;
    }

    return true;
  }

  bool get inCheckedMode {
    bool result = false;
    assert((result = true));
    return result;
  }

  SourceFile elementSourceFile(Element element) {
    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      if (functionElement.patch != null) element = functionElement.patch;
    }
    return element.compilationUnit.script.file;
  }
}

class _GetterElements {
  ir.Primitive result;
  ir.Primitive index;
  ir.Primitive receiver;

  _GetterElements({this.result, this.index, this.receiver}) ;
}

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

  void addJump(IrBuilderVisitor builder) {
    ir.InvokeContinuation invoke = new ir.InvokeContinuation.uninitialized();
    builder.add(invoke);
    _invocations.add(invoke);
    _environments.add(builder.environment);
    builder._current = null;
    // TODO(kmillikin): Can we set builder.environment to null to make it
    // less likely to mutate it?
  }
}

/// A factory for building the cps IR.
class IrBuilder {
  // TODO(johnniwinther): Make these field final and remove the default values
  // when [IrBuilder] is a property of [IrBuilderVisitor] instead of a mixin.
  ConstantSystem constantSystem = DART_CONSTANT_SYSTEM;

  ir.Continuation returnContinuation = new ir.Continuation.retrn();

  List<ir.Parameter> _parameters = <ir.Parameter>[];

  /// A map from variable indexes to their values.
  Environment environment = new Environment.empty();

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

  bool get isOpen => _root == null || _current != null;

  /// Create a parameter for [parameterElement] and add it to the current
  /// environment. If [isClosureVariable] marks whether [parameterElement] is
  /// accessed from an inner function.
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

  ir.Constant makeConst(ConstExp exp, Constant value) {
    return new ir.Constant(exp, value);
  }

  ir.Constant makePrimConst(PrimitiveConstant value) {
    return makeConst(new PrimitiveConstExp(value), value);
  }

  // TODO(johnniwinther): Build constants directly through [ConstExp] when these
  // are created from analyzer2dart.
  ir.Node buildPrimConst(PrimitiveConstant constant) {
    assert(isOpen);
    ir.Node prim = makePrimConst(constant);
    add(new ir.LetPrim(prim));
    return prim;
  }

  /// Create an integer literal.
  ir.Constant buildIntegerLiteral(int value) {
    return buildPrimConst(constantSystem.createInt(value));
  }

  /// Create an double literal.
  ir.Constant buildDoubleLiteral(double value) {
    return buildPrimConst(constantSystem.createDouble(value));
  }

  /// Create an bool literal.
  ir.Constant buildBooleanLiteral(bool value) {
    return buildPrimConst(constantSystem.createBool(value));
  }

  /// Create an null literal.
  ir.Constant buildNullLiteral() {
    return buildPrimConst(constantSystem.createNull());
  }

  /// Create a string literal.
  ir.Constant buildStringLiteral(String value) {
    return buildPrimConst(
        constantSystem.createString(new ast.DartString.literal(value)));
  }

  /// Create a get access of [local].
  ir.Primitive buildGetLocal(Element local) {
    assert(isOpen);
    return environment.lookup(local);
  }

  /**
   * Add an explicit `return null` for functions that don't have a return
   * statement on each branch. This includes functions with an empty body,
   * such as `foo(){ }`.
   */
  void ensureReturn() {
    if (!isOpen) return;
    ir.Constant constant = makePrimConst(constantSystem.createNull());
    add(new ir.LetPrim(constant));
    add(new ir.InvokeContinuation(returnContinuation, [constant]));
    _current = null;
  }

  /// Create a [ir.FunctionDefinition] for [element] using [_root] as the body.
  ///
  /// Parameters must be created before the construction of the body using
  /// [createParameter].
  ir.FunctionDefinition buildFunctionDefinition(
      FunctionElement element,
      List<ConstDeclaration> constants,
      List<ConstExp> defaults) {
    if (!element.isAbstract) {
      ensureReturn();
      return new ir.FunctionDefinition(
          element, returnContinuation, _parameters, _root, constants, defaults);
    } else {
      assert(invariant(element, _root == null,
          message: "Non-empty body for abstract method $element: $_root"));
      assert(invariant(element, constants.isEmpty,
          message: "Local constants for abstract method $element: $constants"));
      return new ir.FunctionDefinition.abstract(
                element, _parameters, defaults);
    }
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
      value = makePrimConst(constantSystem.createNull());
      add(new ir.LetPrim(value));
    }
    add(new ir.InvokeContinuation(returnContinuation, [value]));
    _current = null;
  }

}

/**
 * A tree visitor that builds [IrNodes]. The visit methods add statements using
 * to the [builder] and return the last added statement for trees that represent
 * an expression.
 */
class IrBuilderVisitor extends ResolvedVisitor<ir.Primitive> with IrBuilder {
  final Compiler compiler;
  final SourceFile sourceFile;

  // In SSA terms, join-point continuation parameters are the phis and the
  // continuation invocation arguments are the corresponding phi inputs.  To
  // support name introduction and renaming for source level variables, we use
  // nested (delimited) visitors for constructing subparts of the IR that will
  // need renaming.  Each source variable is assigned an index.
  //
  // Each nested visitor maintains a list of free variable uses in the body.
  // These are implemented as a list of parameters, each with their own use
  // list of references.  When the delimited subexpression is plugged into the
  // surrounding context, the free occurrences can be captured or become free
  // occurrences in the next outer delimited subexpression.
  //
  // Each nested visitor maintains a list that maps indexes of variables
  // assigned in the delimited subexpression to their reaching definition ---
  // that is, the definition in effect at the hole in 'current'.  These are
  // used to determine if a join-point continuation needs to be passed
  // arguments, and what the arguments are.

  /// A stack of collectors for breaks.
  final List<JumpCollector> breakCollectors;
  /// A stack of collectors for continues.
  final List<JumpCollector> continueCollectors;

  ConstExpBuilder constantBuilder;

  final List<ConstDeclaration> localConstants;

  FunctionElement currentFunction;
  final DetectClosureVariables closureLocals;

  /// Construct a top-level visitor.
  IrBuilderVisitor(TreeElements elements, this.compiler, this.sourceFile)
      : breakCollectors = <JumpCollector>[],
        continueCollectors = <JumpCollector>[],
        localConstants = <ConstDeclaration>[],
        closureLocals = new DetectClosureVariables(elements),
        super(elements) {
    constantSystem = compiler.backend.constantSystem;
    constantBuilder = new ConstExpBuilder(this);
  }

  /// Construct a delimited visitor for visiting a subtree.
  ///
  /// The delimited visitor has its own compile-time environment mapping
  /// local variables to their values, which is initially a copy of the parent
  /// environment.  It has its own context for building an IR expression, so
  /// the built expression is not plugged into the parent's context.
  IrBuilderVisitor.delimited(IrBuilderVisitor parent)
      : compiler = parent.compiler,
        sourceFile = parent.sourceFile,
        breakCollectors = parent.breakCollectors,
        continueCollectors = parent.continueCollectors,
        constantBuilder = parent.constantBuilder,
        localConstants = parent.localConstants,
        currentFunction = parent.currentFunction,
        closureLocals = parent.closureLocals,
        super(parent.elements) {
    constantSystem = parent.constantSystem;
    returnContinuation = parent.returnContinuation;
    environment = new Environment.from(parent.environment);
  }

  /// Construct a visitor for a recursive continuation.
  ///
  /// The recursive continuation builder has fresh parameters (i.e. SSA phis)
  /// for all the local variables in the parent, because the invocation sites
  /// of the continuation are not all known when the builder is created.  The
  /// recursive invocations will be passed values for all the local variables,
  /// which may be eliminated later if they are redundant---if they take on
  /// the same value at all invocation sites.
  IrBuilderVisitor.recursive(IrBuilderVisitor parent)
      : compiler = parent.compiler,
        sourceFile = parent.sourceFile,
        breakCollectors = parent.breakCollectors,
        continueCollectors = parent.continueCollectors,
        constantBuilder = parent.constantBuilder,
        localConstants = parent.localConstants,
        currentFunction = parent.currentFunction,
        closureLocals = parent.closureLocals,
        super(parent.elements) {
    constantSystem = parent.constantSystem;
    returnContinuation = parent.returnContinuation;
    parent.environment.index2variable.forEach(createParameter);
  }

  /**
   * Builds the [ir.FunctionDefinition] for a function element. In case the
   * function uses features that cannot be expressed in the IR, this function
   * returns `null`.
   */
  ir.FunctionDefinition buildFunction(FunctionElement functionElement) {
    return nullIfGiveup(() => buildFunctionInternal(functionElement));
  }

  ir.FunctionDefinition buildFunctionInternal(FunctionElement element) {
    assert(invariant(element, element.isImplementation));
    currentFunction = element;
    ast.FunctionExpression function = element.node;
    assert(function != null);
    assert(!function.modifiers.isExternal);
    assert(elements[function] != null);

    closureLocals.visit(function);

    _root = _current = null;

    FunctionSignature signature = element.functionSignature;
    signature.orderedForEachParameter((ParameterElement parameterElement) {
      createParameter(parameterElement,
                      isClosureVariable: isClosureVariable(parameterElement));
    });

    List<ConstExp> defaults = new List<ConstExp>();
    signature.orderedOptionalParameters.forEach((ParameterElement element) {
      if (element.initializer != null) {
        defaults.add(constantBuilder.visit(element.initializer));
      } else {
        defaults.add(new PrimitiveConstExp(constantSystem.createNull()));
      }
    });

    visit(function.body);
    return buildFunctionDefinition(element, localConstants, defaults);
  }

  ir.Primitive visit(ast.Node node) => node.accept(this);

  // ==== Statements ====
  // Build(Block(stamements), C) = C'
  //   where C' = statements.fold(Build, C)
  ir.Primitive visitBlock(ast.Block node) {
    assert(isOpen);
    for (ast.Node n in node.statements.nodes) {
      visit(n);
      if (!isOpen) return null;
    }
    return null;
  }

  // Build(BreakStatement L, C) = C[InvokeContinuation(...)]
  //
  // The continuation and arguments are filled in later after translating
  // the body containing the break.
  ir.Primitive visitBreakStatement(ast.BreakStatement node) {
    assert(isOpen);
    JumpTarget target = elements.getTargetOf(node);
    for (JumpCollector collector in breakCollectors) {
      if (target == collector.target) {
        collector.addJump(this);
        return null;
      }
    }
    compiler.internalError(node, "'break' target not found");
    return null;
  }

  // Build(ContinueStatement L, C) = C[InvokeContinuation(...)]
  //
  // The continuation and arguments are filled in later after translating
  // the body containing the continue.
  ir.Primitive visitContinueStatement(ast.ContinueStatement node) {
    assert(isOpen);
    JumpTarget target = elements.getTargetOf(node);
    for (JumpCollector collector in continueCollectors) {
      if (target == collector.target) {
        collector.addJump(this);
        return null;
      }
    }
    compiler.internalError(node, "'continue' target not found");
    return null;
  }

  // Build(EmptyStatement, C) = C
  ir.Primitive visitEmptyStatement(ast.EmptyStatement node) {
    assert(isOpen);
    return null;
  }

  // Build(ExpressionStatement(e), C) = C'
  //   where (C', _) = Build(e, C)
  ir.Primitive visitExpressionStatement(ast.ExpressionStatement node) {
    assert(isOpen);
    visit(node.expression);
    return null;
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

  /// Invoke a join-point continuation that contains arguments for all local
  /// variables.
  ///
  /// Given the continuation and a list of uninitialized invocations, fill
  /// in each invocation with the continuation and appropriate arguments.
  void invokeFullJoin(ir.Continuation join,
                      JumpCollector jumps,
                      {recursive: false}) {
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

  ir.Primitive visitFor(ast.For node) {
    assert(isOpen);
    // TODO(kmillikin,sigurdm): Handle closure variables declared in a for-loop.
    if (node.initializer is ast.VariableDefinitions) {
      ast.VariableDefinitions definitions = node.initializer;
      for (ast.Node definition in definitions.definitions.nodes) {
        Element element = elements[definition];
        if (isClosureVariable(element)) {
          return giveup(definition, 'Closure variable in for loop initializer');
        }
      }
    }

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

    if (node.initializer != null) visit(node.initializer);

    IrBuilderVisitor condBuilder = new IrBuilderVisitor.recursive(this);
    ir.Primitive condition;
    if (node.condition == null) {
      // If the condition is empty then the body is entered unconditionally.
      condition = makePrimConst(constantSystem.createBool(true));
      condBuilder.add(new ir.LetPrim(condition));
    } else {
      condition = condBuilder.visit(node.condition);
    }

    JumpTarget target = elements.getTargetDefinition(node);
    JumpCollector breakCollector = new JumpCollector(target);
    JumpCollector continueCollector = new JumpCollector(target);
    breakCollectors.add(breakCollector);
    continueCollectors.add(continueCollector);

    IrBuilderVisitor bodyBuilder = new IrBuilderVisitor.delimited(condBuilder);
    bodyBuilder.visit(node.body);
    assert(breakCollectors.last == breakCollector);
    assert(continueCollectors.last == continueCollector);
    breakCollectors.removeLast();
    continueCollectors.removeLast();

    // The binding of the continue continuation should occur as late as
    // possible, that is, at the nearest common ancestor of all the continue
    // sites in the body.  However, that is difficult to compute here, so it
    // is instead placed just outside the body of the body continuation.
    bool hasContinues = !continueCollector.isEmpty;
    IrBuilderVisitor updateBuilder = hasContinues
        ? new IrBuilderVisitor.recursive(condBuilder)
        : bodyBuilder;
    for (ast.Node n in node.update) {
      if (!updateBuilder.isOpen) break;
      updateBuilder.visit(n);
    }

    // Create body entry and loop exit continuations and a branch to them.
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation exitContinuation = new ir.Continuation([]);
    ir.LetCont branch =
        new ir.LetCont(exitContinuation,
            new ir.LetCont(bodyContinuation,
                new ir.Branch(new ir.IsTrue(condition),
                              bodyContinuation,
                              exitContinuation)));
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
          new ir.LetCont(continueContinuation, bodyBuilder._root);
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
      letJoin.continuation = createJoin(environment.length, breakCollector);
      _current = letJoin;
    } else {
      _current = condBuilder._current;
      environment = condBuilder.environment;
    }
    return null;
  }

  ir.Primitive visitIf(ast.If node) {
    assert(isOpen);
    ir.Primitive condition = visit(node.condition);

    // The then and else parts are delimited.
    IrBuilderVisitor thenBuilder = new IrBuilderVisitor.delimited(this);
    IrBuilderVisitor elseBuilder = new IrBuilderVisitor.delimited(this);
    thenBuilder.visit(node.thenPart);
    if (node.hasElsePart) elseBuilder.visit(node.elsePart);

    // Build the term
    // (Result =) let cont then() = [[thenPart]] in
    //            let cont else() = [[elsePart]] in
    //              if condition (then, else)
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);
    ir.Expression letElse =
        new ir.LetCont(elseContinuation,
          new ir.Branch(new ir.IsTrue(condition),
                        thenContinuation,
                        elseContinuation));
    ir.Expression letThen = new ir.LetCont(thenContinuation, letElse);
    ir.Expression result = letThen;

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
        _current = (thenBuilder._root == null) ? letThen : thenBuilder._current;
        environment = thenBuilder.environment;
      } else if (elseBuilder.isOpen) {
        _current = (elseBuilder._root == null) ? letElse : elseBuilder._current;
        environment = elseBuilder.environment;
      } else {
        _current = null;
      }
    }
    return null;
  }

  ir.Primitive visitLabeledStatement(ast.LabeledStatement node) {
    ast.Statement body = node.statement;
    return body is ast.Loop
        ? visit(body)
        : giveup(node, 'labeled statement');
  }

  ir.Primitive visitWhile(ast.While node) {
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
    IrBuilderVisitor condBuilder = new IrBuilderVisitor.recursive(this);
    ir.Primitive condition = condBuilder.visit(node.condition);

    JumpTarget target = elements.getTargetDefinition(node);
    JumpCollector breakCollector = new JumpCollector(target);
    JumpCollector continueCollector = new JumpCollector(target);
    breakCollectors.add(breakCollector);
    continueCollectors.add(continueCollector);

    IrBuilderVisitor bodyBuilder = new IrBuilderVisitor.delimited(condBuilder);
    bodyBuilder.visit(node.body);
    assert(breakCollectors.last == breakCollector);
    assert(continueCollectors.last == continueCollector);
    breakCollectors.removeLast();
    continueCollectors.removeLast();

    // Create body entry and loop exit continuations and a branch to them.
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation exitContinuation = new ir.Continuation([]);
    ir.LetCont branch =
        new ir.LetCont(exitContinuation,
            new ir.LetCont(bodyContinuation,
                new ir.Branch(new ir.IsTrue(condition),
                              bodyContinuation,
                              exitContinuation)));
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
      letJoin.continuation = createJoin(environment.length, breakCollector);
      _current = letJoin;
    } else {
      _current = condBuilder._current;
      environment = condBuilder.environment;
    }
    return null;
  }

  ir.Primitive visitForIn(ast.ForIn node) {
    // The for-in loop
    //
    // for (a in e) s;
    //
    // Is compiled analogously to:
    //
    // a = e.iterator;
    // while (a.moveNext()) {
    //   var n0 = a.current;
    //   s;
    // }

    // The condition and body are delimited.
    IrBuilderVisitor condBuilder = new IrBuilderVisitor.recursive(this);

    ir.Primitive expressionReceiver = visit(node.expression);
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

    JumpTarget target = elements.getTargetDefinition(node);
    JumpCollector breakCollector = new JumpCollector(target);
    JumpCollector continueCollector = new JumpCollector(target);
    breakCollectors.add(breakCollector);
    continueCollectors.add(continueCollector);

    IrBuilderVisitor bodyBuilder = new IrBuilderVisitor.delimited(condBuilder);
    ast.Node identifier = node.declaredIdentifier;
    Element variableElement = elements.getForInVariable(node);
    Selector selector = elements.getSelector(identifier);

    // node.declaredIdentifier can be either an ast.VariableDefinitions
    // (defining a new local variable) or a send designating some existing
    // variable.
    ast.Node declaredIdentifier = node.declaredIdentifier;

    if (declaredIdentifier is ast.VariableDefinitions) {
      bodyBuilder.visit(declaredIdentifier);
    }

    ir.Parameter currentValue = new ir.Parameter(null);
    ir.Continuation currentInvoked = new ir.Continuation([currentValue]);
    bodyBuilder.add(new ir.LetCont(currentInvoked,
        new ir.InvokeMethod(iterator, new Selector.getter("current", null),
            currentInvoked, emptyArguments)));
    if (Elements.isLocal(variableElement)) {
      bodyBuilder.setLocal(variableElement, currentValue);
    } else if (Elements.isStaticOrTopLevel(variableElement)) {
      bodyBuilder.setStatic(variableElement, selector, currentValue);
    } else {
      ir.Primitive receiver = bodyBuilder.lookupThis();
      bodyBuilder.setDynamic(null, receiver, selector, currentValue);
    }

    bodyBuilder.visit(node.body);
    assert(breakCollectors.last == breakCollector);
    assert(continueCollectors.last == continueCollector);
    breakCollectors.removeLast();
    continueCollectors.removeLast();

    // Create body entry and loop exit continuations and a branch to them.
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation exitContinuation = new ir.Continuation([]);
    ir.LetCont branch =
        new ir.LetCont(exitContinuation,
            new ir.LetCont(bodyContinuation,
                new ir.Branch(new ir.IsTrue(condition),
                              bodyContinuation,
                              exitContinuation)));
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
      letJoin.continuation = createJoin(environment.length, breakCollector);
      _current = letJoin;
    } else {
      _current = condBuilder._current;
      environment = condBuilder.environment;
    }
    return null;
  }

  ir.Primitive visitVariableDefinitions(ast.VariableDefinitions node) {
    assert(isOpen);
    if (node.modifiers.isConst) {
      for (ast.SendSet definition in node.definitions.nodes) {
        assert(!definition.arguments.isEmpty);
        assert(definition.arguments.tail.isEmpty);
        VariableElement element = elements[definition];
        ConstExp value = constantBuilder.visit(definition.arguments.head);
        localConstants.add(new ConstDeclaration(element, value));
      }
    } else {
      for (ast.Node definition in node.definitions.nodes) {
        Element element = elements[definition];
        ir.Primitive initialValue;
        // Definitions are either SendSets if there is an initializer, or
        // Identifiers if there is no initializer.
        if (definition is ast.SendSet) {
          assert(!definition.arguments.isEmpty);
          assert(definition.arguments.tail.isEmpty);
          initialValue = visit(definition.arguments.head);
        } else {
          assert(definition is ast.Identifier);
          // The initial value is null.
          // TODO(kmillikin): Consider pooling constants.
          initialValue = makePrimConst(constantSystem.createNull());
          add(new ir.LetPrim(initialValue));
        }
        if (isClosureVariable(element)) {
          LocalElement local = element;
          add(new ir.SetClosureVariable(local, initialValue,
                                        isDeclaration: true));
        } else {
          // In case a primitive was introduced for the initializer expression,
          // use this variable element to help derive a good name for it.
          initialValue.useElementAsHint(element);
          environment.extend(element, initialValue);
        }
      }
    }
    return null;
  }

  // Build(Return(e), C) = C'[InvokeContinuation(return, x)]
  //   where (C', x) = Build(e, C)
  //
  // Return without a subexpression is translated as if it were return null.
  ir.Primitive visitReturn(ast.Return node) {
    // TODO(lry): support native returns.
    if (node.beginToken.value == 'native') return giveup(node, 'Native return');
    if (node.expression == null) {
      buildReturn();
    } else {
      buildReturn(visit(node.expression));
    }
    return null;
  }

  // ==== Expressions ====
  ir.Primitive visitConditional(ast.Conditional node) {
    assert(isOpen);
    ir.Primitive condition = visit(node.condition);

    // The then and else expressions are delimited.
    IrBuilderVisitor thenBuilder = new IrBuilderVisitor.delimited(this);
    IrBuilderVisitor elseBuilder = new IrBuilderVisitor.delimited(this);
    ir.Primitive thenValue = thenBuilder.visit(node.thenExpression);
    ir.Primitive elseValue = elseBuilder.visit(node.elseExpression);

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
    //   let cont then() = [[thenPart]]; join(v, ...) in
    //   let cont else() = [[elsePart]]; join(v, ...) in
    //     if condition (then, else)
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);
    thenContinuation.body = thenBuilder._root;
    elseContinuation.body = elseBuilder._root;
    add(new ir.LetCont(joinContinuation,
            new ir.LetCont(thenContinuation,
                new ir.LetCont(elseContinuation,
                    new ir.Branch(new ir.IsTrue(condition),
                                  thenContinuation,
                                  elseContinuation)))));
    return (thenValue == elseValue)
        ? thenValue
        : joinContinuation.parameters.last;
  }

  // For all simple literals:
  // Build(Literal(c), C) = C[let val x = Constant(c) in [], x]
  ir.Primitive visitLiteralBool(ast.LiteralBool node) {
    assert(isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitLiteralDouble(ast.LiteralDouble node) {
    assert(isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitLiteralInt(ast.LiteralInt node) {
    assert(isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitLiteralNull(ast.LiteralNull node) {
    assert(isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitLiteralString(ast.LiteralString node) {
    assert(isOpen);
    return translateConstant(node);
  }

  Constant getConstantForNode(ast.Node node) {
    Constant constant =
        compiler.backend.constantCompilerTask.compileNode(node, elements);
    assert(invariant(node, constant != null,
        message: 'No constant computed for $node'));
    return constant;
  }

  ir.Primitive visitLiteralList(ast.LiteralList node) {
    assert(isOpen);
    if (node.isConst) {
      return translateConstant(node);
    }
    List<ir.Primitive> values = node.elements.nodes.mapToList(visit);
    GenericType type = elements.getType(node);
    ir.Primitive result = new ir.LiteralList(type, values);
    add(new ir.LetPrim(result));
    return result;
  }

  ir.Primitive visitLiteralMap(ast.LiteralMap node) {
    assert(isOpen);
    if (node.isConst) {
      return translateConstant(node);
    }
    List<ir.Primitive> keys = new List<ir.Primitive>();
    List<ir.Primitive> values = new List<ir.Primitive>();
    node.entries.nodes.forEach((ast.LiteralMapEntry node) {
      keys.add(visit(node.key));
      values.add(visit(node.value));
    });
    GenericType type = elements.getType(node);
    ir.Primitive result = new ir.LiteralMap(type, keys, values);
    add(new ir.LetPrim(result));
    return result;
  }

  ir.Primitive visitLiteralSymbol(ast.LiteralSymbol node) {
    assert(isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitIdentifier(ast.Identifier node) {
    assert(isOpen);
    // "this" is the only identifier that should be met by the visitor.
    assert(node.isThis());
    return lookupThis();
  }

  ir.Primitive visitParenthesizedExpression(
      ast.ParenthesizedExpression node) {
    assert(isOpen);
    return visit(node.expression);
  }

  // Stores the result of visiting a CascadeReceiver, so we can return it from
  // its enclosing Cascade.
  ir.Primitive _currentCascadeReceiver;

  ir.Primitive visitCascadeReceiver(ast.CascadeReceiver node) {
    assert(isOpen);
    return _currentCascadeReceiver = visit(node.expression);
  }

  ir.Primitive visitCascade(ast.Cascade node) {
    assert(isOpen);
    var oldCascadeReceiver = _currentCascadeReceiver;
    // Throw away the result of visiting the expression.
    // Instead we return the result of visiting the CascadeReceiver.
    this.visit(node.expression);
    ir.Primitive receiver = _currentCascadeReceiver;
    _currentCascadeReceiver = oldCascadeReceiver;
    return receiver;
  }

  ir.Primitive lookupThis() {
    ir.Primitive result = new ir.This();
    add(new ir.LetPrim(result));
    return result;
  }

  // ==== Sends ====
  ir.Primitive visitAssert(ast.Send node) {
    assert(isOpen);
    return giveup(node, 'Assert');
  }

  ir.Primitive visitNamedArgument(ast.NamedArgument node) {
    assert(isOpen);
    return visit(node.expression);
  }

  ir.Primitive translateClosureCall(ir.Primitive receiver,
                                    Selector closureSelector,
                                    ast.NodeList arguments) {
    Selector namedCallSelector = new Selector(closureSelector.kind,
                     "call",
                     closureSelector.library,
                     closureSelector.argumentCount,
                     closureSelector.namedArguments);
    List<ir.Primitive> args = arguments.nodes.mapToList(visit, growable:false);
    return continueWithExpression(
        (k) => new ir.InvokeMethod(receiver, namedCallSelector, k, args));
  }

  ir.Primitive visitClosureSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    ir.Primitive closureTarget;
    if (element == null) {
      closureTarget = visit(node.selector);
    } else if (isClosureVariable(element)) {
      LocalElement local = element;
      closureTarget = new ir.GetClosureVariable(local);
      add(new ir.LetPrim(closureTarget));
    } else {
      assert(Elements.isLocal(element));
      closureTarget = environment.lookup(element);
    }
    Selector closureSelector = elements.getSelector(node);
    return translateClosureCall(closureTarget, closureSelector,
        node.argumentsNode);
  }

  /// If [node] is null, returns this.
  /// If [node] is super, returns null (for special handling)
  /// Otherwise visits [node] and returns the result.
  ir.Primitive visitReceiver(ast.Expression node) {
    if (node == null) return lookupThis();
    if (node.isSuper()) return null;
    return visit(node);
  }

  /// Makes an [InvokeMethod] unless [node.receiver.isSuper()], in that case
  /// makes an [InvokeSuperMethod] ignoring [receiver].
  ir.Expression createDynamicInvoke(ast.Send node,
                             Selector selector,
                             ir.Definition receiver,
                             ir.Continuation k,
                             List<ir.Definition> arguments) {
    return node != null && node.receiver != null && node.receiver.isSuper()
        ? new ir.InvokeSuperMethod(selector, k, arguments)
        : new ir.InvokeMethod(receiver, selector, k, arguments);
  }

  ir.Primitive visitDynamicSend(ast.Send node) {
    assert(isOpen);
    Selector selector = elements.getSelector(node);
    ir.Primitive receiver = visitReceiver(node.receiver);
    List<ir.Primitive> arguments = new List<ir.Primitive>();
    for (ast.Node n in node.arguments) {
      arguments.add(visit(n));
    }
    return continueWithExpression(
        (k) => createDynamicInvoke(node, selector, receiver, k, arguments));
  }

  _GetterElements translateGetter(ast.Send node, Selector selector) {
    Element element = elements[node];
    ir.Primitive result;
    ir.Primitive receiver;
    ir.Primitive index;

    if (element != null && element.isConst) {
      // Reference to constant local, top-level or static field
      result = translateConstant(node);
    } else if (isClosureVariable(element)) {
      LocalElement local = element;
      result = new ir.GetClosureVariable(local);
      add(new ir.LetPrim(result));
    } else if (Elements.isLocal(element)) {
      // Reference to local variable
      result = buildGetLocal(element);
    } else if (element == null ||
               Elements.isInstanceField(element) ||
               Elements.isInstanceMethod(element) ||
               selector.isIndex ||
               // TODO(johnniwinther): clean up semantics of resultion.
               node.isSuperCall) {
      // Dynamic dispatch to a getter. Sometimes resolution will suggest a
      // target element, but in these cases we must still emit a dynamic
      // dispatch. The target element may be an instance method in case we are
      // converting a method to a function object.

      receiver = visitReceiver(node.receiver);
      List<ir.Primitive> arguments = new List<ir.Primitive>();
      if (selector.isIndex) {
        index = visit(node.arguments.head);
        arguments.add(index);
      }

      assert(selector.kind == SelectorKind.GETTER ||
             selector.kind == SelectorKind.INDEX);
      result = continueWithExpression(
          (k) => createDynamicInvoke(node, selector, receiver, k, arguments));
    } else if (element.isField || element.isGetter || element.isErroneous ||
               element.isSetter) {
      // Access to a static field or getter (non-static case handled above).
      // Even if there is only a setter, we compile as if it was a getter,
      // so the vm can fail at runtime.
      assert(selector.kind == SelectorKind.GETTER ||
             selector.kind == SelectorKind.SETTER);
      result = continueWithExpression(
          (k) => new ir.InvokeStatic(element, selector, k, []));
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      // Convert a top-level or static function to a function object.
      result = translateConstant(node);
    } else {
      throw "Unexpected SendSet getter: $node, $element";
    }
    return new _GetterElements(
        result: result,index: index, receiver: receiver);
  }

  ir.Primitive visitGetterSend(ast.Send node) {
    assert(isOpen);
    return translateGetter(node, elements.getSelector(node)).result;

  }

  ir.Primitive buildNegation(ir.Primitive condition) {
    // ! e is translated as e ? false : true

    // Add a continuation parameter for the result of the expression.
    ir.Parameter resultParameter = new ir.Parameter(null);

    ir.Continuation joinContinuation = new ir.Continuation([resultParameter]);
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);

    ir.Constant trueConstant = makePrimConst(constantSystem.createBool(true));
    ir.Constant falseConstant = makePrimConst(constantSystem.createBool(false));

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

  ir.Primitive translateLogicalOperator(ast.Operator op,
                                        ast.Expression left,
                                        ast.Expression right) {
    // e0 && e1 is translated as if e0 ? (e1 == true) : false.
    // e0 || e1 is translated as if e0 ? true : (e1 == true).
    // The translation must convert both e0 and e1 to booleans and handle
    // local variable assignments in e1.

    ir.Primitive leftValue = visit(left);
    IrBuilderVisitor rightBuilder = new IrBuilderVisitor.delimited(this);
    ir.Primitive rightValue = rightBuilder.visit(right);
    // A dummy empty target for the branch on the left subexpression branch.
    // This enables using the same infrastructure for join-point continuations
    // as in visitIf and visitConditional.  It will hold a definition of the
    // appropriate constant and an invocation of the join-point continuation.
    IrBuilderVisitor emptyBuilder = new IrBuilderVisitor.delimited(this);
    // Dummy empty targets for right true and right false.  They hold
    // definitions of the appropriate constant and an invocation of the
    // join-point continuation.
    IrBuilderVisitor rightTrueBuilder = new IrBuilderVisitor.delimited(rightBuilder);
    IrBuilderVisitor rightFalseBuilder = new IrBuilderVisitor.delimited(rightBuilder);

    // If we don't evaluate the right subexpression, the value of the whole
    // expression is this constant.
    ir.Constant leftBool = emptyBuilder.makePrimConst(
        constantSystem.createBool(op.source == '||'));
    // If we do evaluate the right subexpression, the value of the expression
    // is a true or false constant.
    ir.Constant rightTrue = rightTrueBuilder.makePrimConst(
        constantSystem.createBool(true));
    ir.Constant rightFalse = rightFalseBuilder.makePrimConst(
        constantSystem.createBool(false));
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
    if (op.source == '&&') {
      leftTrueContinuation.body = rightBuilder._root;
      leftFalseContinuation.body = emptyBuilder._root;
    } else {
      leftTrueContinuation.body = emptyBuilder._root;
      leftFalseContinuation.body = rightBuilder._root;
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

  ir.Primitive visitOperatorSend(ast.Send node) {
    assert(isOpen);
    ast.Operator op = node.selector;
    if (isUserDefinableOperator(op.source)) {
      return visitDynamicSend(node);
    }
    if (op.source == '&&' || op.source == '||') {
      assert(node.receiver != null);
      assert(!node.arguments.isEmpty);
      assert(node.arguments.tail.isEmpty);
      return translateLogicalOperator(op, node.receiver, node.arguments.head);
    }
    if (op.source == "!") {
      assert(node.receiver != null);
      assert(node.arguments.isEmpty);
      return buildNegation(visit(node.receiver));
    }
    if (op.source == "!=") {
      assert(node.receiver != null);
      assert(!node.arguments.isEmpty);
      assert(node.arguments.tail.isEmpty);
      return buildNegation(visitDynamicSend(node));
    }
    assert(invariant(node, op.source == "is" || op.source == "as",
           message: "unexpected operator $op"));
    DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
    ir.Primitive receiver = visit(node.receiver);
    ir.Primitive check = continueWithExpression(
        (k) => new ir.TypeOperator(op.source, receiver, type, k));
    return node.isIsNotCheck ? buildNegation(check) : check;
  }

  // Build(StaticSend(f, arguments), C) = C[C'[InvokeStatic(f, xs)]]
  //   where (C', xs) = arguments.fold(Build, C)
  ir.Primitive visitStaticSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    assert(!element.isConstructor);
    // TODO(lry): support foreign functions.
    if (element.isForeign(compiler.backend)) {
      return giveup(node, 'StaticSend: foreign');
    }

    Selector selector = elements.getSelector(node);

    // TODO(lry): support default arguments, need support for locals.
    List<ir.Definition> arguments = node.arguments.mapToList(visit,
                                                             growable:false);
    return buildStaticInvocation(element, selector, arguments);
  }


  ir.Primitive visitSuperSend(ast.Send node) {
    assert(isOpen);
    if (node.isPropertyAccess) {
      return visitGetterSend(node);
    } else {
      return visitDynamicSend(node);
    }
  }

  visitTypePrefixSend(ast.Send node) {
    compiler.internalError(node, "visitTypePrefixSend should not be called.");
  }

  ir.Primitive visitTypeLiteralSend(ast.Send node) {
    assert(isOpen);
    // If the user is trying to invoke the type literal or variable,
    // it must be treated as a function call.
    if (node.argumentsNode != null) {
      // TODO(sigurdm): Handle this to match proposed semantics of issue #19725.
      return giveup(node, 'Type literal invoked as function');
    }

    DartType type = elements.getTypeLiteralType(node);
    if (type is TypeVariableType) {
      ir.Primitive prim = new ir.ReifyTypeVar(type.element);
      add(new ir.LetPrim(prim));
      return prim;
    } else {
      return translateConstant(node);
    }
  }

  /// True if [element] is a local variable, local function, or parameter that
  /// is accessed from an inner function. Recursive self-references in a local
  /// function count as closure accesses.
  ///
  /// If `true`, [element] is a [LocalElement].
  bool isClosureVariable(Element element) {
    return closureLocals.isClosureVariable(element);
  }

  void setLocal(Element element, ir.Primitive valueToStore) {
    if (isClosureVariable(element)) {
      LocalElement local = element;
      add(new ir.SetClosureVariable(local, valueToStore));
    } else {
      valueToStore.useElementAsHint(element);
      environment.update(element, valueToStore);
    }
  }

  void setStatic(Element element,
                 Selector selector,
                 ir.Primitive valueToStore) {
    assert(element.isErroneous || element.isField || element.isSetter);
    continueWithExpression(
        (k) => new ir.InvokeStatic(element, selector, k, [valueToStore]));
  }

  void setDynamic(ast.Node node,
                  ir.Primitive receiver, Selector selector,
                  ir.Primitive valueToStore) {
    List<ir.Definition> arguments = [valueToStore];
    continueWithExpression(
        (k) => createDynamicInvoke(node, selector, receiver, k, arguments));
  }

  void setIndex(ast.Node node,
                ir.Primitive receiver,
                Selector selector,
                ir.Primitive index,
                ir.Primitive valueToStore) {
    List<ir.Definition> arguments = [index, valueToStore];
    continueWithExpression(
        (k) => createDynamicInvoke(node, selector, receiver, k, arguments));
  }

  ir.Primitive visitSendSet(ast.SendSet node) {
    assert(isOpen);
    Element element = elements[node];
    ast.Operator op = node.assignmentOperator;
    // For complex operators, this is the result of getting (before assigning)
    ir.Primitive originalValue;
    // For []+= style operators, this saves the index.
    ir.Primitive index;
    ir.Primitive receiver;
    // This is what gets assigned.
    ir.Primitive valueToStore;
    Selector selector = elements.getSelector(node);
    Selector operatorSelector =
        elements.getOperatorSelectorInComplexSendSet(node);
    Selector getterSelector =
        elements.getGetterSelectorInComplexSendSet(node);
    assert(
        // Indexing send-sets have an argument for the index.
        (selector.isIndexSet ? 1 : 0) +
        // Non-increment send-sets have one more argument.
        (ast.Operator.INCREMENT_OPERATORS.contains(op.source) ? 0 : 1)
            == node.argumentCount());

    ast.Node getAssignArgument() {
      assert(invariant(node, !node.arguments.isEmpty,
                       message: "argument expected"));
      return selector.isIndexSet
          ? node.arguments.tail.head
          : node.arguments.head;
    }

    // Get the value into valueToStore
    if (op.source == "=") {
      if (selector.isIndexSet) {
        receiver = visitReceiver(node.receiver);
        index = visit(node.arguments.head);
      } else if (element == null || Elements.isInstanceField(element)) {
        receiver = visitReceiver(node.receiver);
      }
      valueToStore = visit(getAssignArgument());
    } else {
      // Get the original value into getter
      assert(ast.Operator.COMPLEX_OPERATORS.contains(op.source));

      _GetterElements getterResult = translateGetter(node, getterSelector);
      index = getterResult.index;
      receiver = getterResult.receiver;
      originalValue = getterResult.result;

      // Do the modification of the value in getter.
      ir.Primitive arg;
      if (ast.Operator.INCREMENT_OPERATORS.contains(op.source)) {
        arg = makePrimConst(constantSystem.createInt(1));
        add(new ir.LetPrim(arg));
      } else {
        arg = visit(getAssignArgument());
      }
      valueToStore = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([valueToStore]);
      ir.Expression invoke =
          new ir.InvokeMethod(originalValue, operatorSelector, k, [arg]);
      add(new ir.LetCont(k, invoke));
    }

    if (Elements.isLocal(element)) {
      setLocal(element, valueToStore);
    } else if ((!node.isSuperCall && Elements.isErroneousElement(element)) ||
                Elements.isStaticOrTopLevel(element)) {
      setStatic(element, elements.getSelector(node), valueToStore);
    } else {
      // Setter or index-setter invocation
      Selector selector = elements.getSelector(node);
      assert(selector.kind == SelectorKind.SETTER ||
          selector.kind == SelectorKind.INDEX);
      if (selector.isIndexSet) {
        setIndex(node, receiver, selector, index, valueToStore);
      } else {
        setDynamic(node, receiver, selector, valueToStore);
      }
    }

    if (node.isPostfix) {
      assert(originalValue != null);
      return originalValue;
    } else {
      return valueToStore;
    }
  }

  ir.Primitive visitNewExpression(ast.NewExpression node) {
    assert(isOpen);
    if (node.isConst) {
      return translateConstant(node);
    }
    FunctionElement element = elements[node.send];
    Selector selector = elements.getSelector(node.send);
    ast.Node selectorNode = node.send.selector;
    DartType type = elements.getType(node);
    List<ir.Primitive> args =
        node.send.arguments.mapToList(visit, growable:false);
    return continueWithExpression(
        (k) => new ir.InvokeConstructor(type, element,selector, k, args));
  }

  ir.Primitive visitStringJuxtaposition(ast.StringJuxtaposition node) {
    assert(isOpen);
    ir.Primitive first = visit(node.first);
    ir.Primitive second = visit(node.second);
    return continueWithExpression(
        (k) => new ir.ConcatenateStrings(k, [first, second]));
  }

  ir.Primitive visitStringInterpolation(ast.StringInterpolation node) {
    assert(isOpen);
    List<ir.Primitive> arguments = [];
    arguments.add(visitLiteralString(node.string));
    var it = node.parts.iterator;
    while (it.moveNext()) {
      ast.StringInterpolationPart part = it.current;
      arguments.add(visit(part.expression));
      arguments.add(visitLiteralString(part.string));
    }
    return continueWithExpression(
        (k) => new ir.ConcatenateStrings(k, arguments));
  }

  ir.Primitive translateConstant(ast.Node node, [Constant value]) {
    assert(isOpen);
    if (value == null) {
      value = getConstantForNode(node);
    }
    ir.Primitive primitive = makeConst(constantBuilder.visit(node), value);
    add(new ir.LetPrim(primitive));
    return primitive;
  }

  ir.FunctionDefinition makeSubFunction(ast.FunctionExpression node) {
    return new IrBuilderVisitor(elements, compiler, sourceFile)
           .buildFunctionInternal(elements[node]);
  }

  ir.Primitive visitFunctionExpression(ast.FunctionExpression node) {
    FunctionElement element = elements[node];
    ir.FunctionDefinition inner = makeSubFunction(node);
    ir.CreateFunction prim = new ir.CreateFunction(inner);
    add(new ir.LetPrim(prim));
    return prim;
  }

  ir.Primitive visitFunctionDeclaration(ast.FunctionDeclaration node) {
    LocalFunctionElement element = elements[node.function];
    ir.FunctionDefinition inner = makeSubFunction(node.function);
    if (isClosureVariable(element)) {
      add(new ir.DeclareFunction(element, inner));
    } else {
      ir.CreateFunction prim = new ir.CreateFunction(inner);
      add(new ir.LetPrim(prim));
      environment.extend(element, prim);
      prim.useElementAsHint(element);
    }
    return null;
  }

  static final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

  dynamic giveup(ast.Node node, [String reason]) {
    throw ABORT_IRNODE_BUILDER;
  }

  ir.FunctionDefinition nullIfGiveup(ir.FunctionDefinition action()) {
    try {
      return action();
    } catch(e, tr) {
      if (e == ABORT_IRNODE_BUILDER) {
        return null;
      }
      rethrow;
    }
  }

  void internalError(String reason, {ast.Node node}) {
    giveup(node);
  }
}

/// Translates constant expressions from the AST to the [ConstExp] language.
class ConstExpBuilder extends ast.Visitor<ConstExp> {
  final IrBuilderVisitor parent;
  final TreeElements elements;
  final ConstantSystem constantSystem;
  final ConstantCompiler constantCompiler;

  ConstExpBuilder(IrBuilderVisitor parent)
      : this.parent = parent,
        this.elements = parent.elements,
        this.constantSystem = parent.constantSystem,
        this.constantCompiler = parent.compiler.backend.constantCompilerTask;

  Constant computeConstant(ast.Node node) {
    return constantCompiler.compileNode(node, elements);
  }

  /// True if the given constant is small enough that inlining it is likely
  /// to be profitable. Always false for non-primitive constants.
  bool isSmallConstant(Constant constant) {
    if (constant is BoolConstant || constant is NullConstant) {
      return true;
    }
    if (constant is IntConstant) {
      return -10 < constant.value && constant.value < 100;
    }
    if (constant is DoubleConstant) {
      return constant.isZero || constant.isOne;
    }
    if (constant is StringConstant) {
      ast.DartString string = constant.value;
      if (string is ast.LiteralDartString) {
        return string.length < 4;
      }
      if (string is ast.SourceBasedDartString) {
        return string.length < 4;
      }
    }
    return false;
  }

  ConstExp visit(ast.Node node) => node.accept(this);

  ConstExp visitStringJuxtaposition(ast.StringJuxtaposition node) {
    ConstExp first = visit(node.first);
    ConstExp second = visit(node.second);
    return new ConcatenateConstExp([first, second]);
  }

  ConstExp visitStringInterpolation(ast.StringInterpolation node) {
    List<ConstExp> arguments = <ConstExp>[];
    arguments.add(visitLiteralString(node.string));
    var it = node.parts.iterator;
    while (it.moveNext()) {
      ast.StringInterpolationPart part = it.current;
      arguments.add(visit(part.expression));
      arguments.add(visitLiteralString(part.string));
    }
    return new ConcatenateConstExp(arguments);
  }

  ConstExp visitNewExpression(ast.NewExpression node) {
    FunctionElement element = elements[node.send];
    // The resolver will already have thrown an error if the constructor was
    // unresolved.
    assert(invariant(node, !Elements.isUnresolved(element)));

    Selector selector = elements.getSelector(node.send);
    ast.Node selectorNode = node.send.selector;
    GenericType type = elements.getType(node);
    List<ConstExp> args = node.send.arguments.mapToList(visit, growable:false);
    return new ConstructorConstExp(type, element, selector, args);
  }

  ConstExp visitNamedArgument(ast.NamedArgument node) {
    return visit(node.expression);
  }

  ConstExp visitSend(ast.Send node) {
    Element element = elements[node];
    if (node.isOperator) {
      return new PrimitiveConstExp(computeConstant(node));
    }
    if (Elements.isStaticOrTopLevelFunction(element)) {
      return new FunctionConstExp(element);
    }
    if (Elements.isLocal(element) ||
        Elements.isStaticOrTopLevelField(element)) {
      // If the constant is small, inline it instead of using the declared const
      Constant value = constantCompiler.getConstantForVariable(element);
      if (isSmallConstant(value))
        return new PrimitiveConstExp(value);
      else
        return new VariableConstExp(element);
    }
    DartType type = elements.getTypeLiteralType(node);
    if (type != null) {
      return new TypeConstExp(type);
    }
    throw "Unexpected constant Send: $node";
  }

  ConstExp visitParenthesizedExpression(ast.ParenthesizedExpression node) {
    return visit(node.expression);
  }

  ConstExp visitLiteralList(ast.LiteralList node) {
    List<ConstExp> values = node.elements.nodes.mapToList(visit);
    GenericType type = elements.getType(node);
    return new ListConstExp(type, values);
  }

  ConstExp visitLiteralMap(ast.LiteralMap node) {
    List<ConstExp> keys = new List<ConstExp>();
    List<ConstExp> values = new List<ConstExp>();
    node.entries.nodes.forEach((ast.LiteralMapEntry node) {
      keys.add(visit(node.key));
      values.add(visit(node.value));
    });
    GenericType type = elements.getType(node);
    return new MapConstExp(type, keys, values);
  }

  ConstExp visitLiteralSymbol(ast.LiteralSymbol node) {
    return new SymbolConstExp(node.slowNameString);
  }

  ConstExp visitLiteralInt(ast.LiteralInt node) {
    return new PrimitiveConstExp(constantSystem.createInt(node.value));
  }

  ConstExp visitLiteralDouble(ast.LiteralDouble node) {
    return new PrimitiveConstExp(constantSystem.createDouble(node.value));
  }

  ConstExp visitLiteralString(ast.LiteralString node) {
    return new PrimitiveConstExp(constantSystem.createString(node.dartString));
  }

  ConstExp visitLiteralBool(ast.LiteralBool node) {
    return new PrimitiveConstExp(constantSystem.createBool(node.value));
  }

  ConstExp visitLiteralNull(ast.LiteralNull node) {
    return new PrimitiveConstExp(constantSystem.createNull());
  }

  ConstExp visitConditional(ast.Conditional node) {
    BoolConstant condition = computeConstant(node.condition);
    return visit(condition.isTrue ? node.thenExpression : node.elseExpression);
  }

  ConstExp visitNode(ast.Node node) {
    throw "Unexpected constant: $node";
  }

}

/// Classifies local variables and local functions as 'closure variables'.
/// A closure variable is one that is accessed from an inner function nested
/// one or more levels inside the one that declares it.
class DetectClosureVariables extends ast.Visitor {
  final TreeElements elements;
  DetectClosureVariables(this.elements);

  FunctionElement currentFunction;
  Set<Local> usedFromClosure = new Set<Local>();
  Set<FunctionElement> recursiveFunctions = new Set<FunctionElement>();

  bool isClosureVariable(Entity entity) => usedFromClosure.contains(entity);

  void markAsClosureVariable(Local local) {
    usedFromClosure.add(local);
  }

  visit(ast.Node node) => node.accept(this);

  visitNode(ast.Node node) {
    node.visitChildren(this);
  }

  visitSend(ast.Send node) {
    Element element = elements[node];
    if (Elements.isLocal(element) &&
        !element.isConst &&
        element.enclosingElement != currentFunction) {
      LocalElement local = element;
      markAsClosureVariable(local);
    }
    node.visitChildren(this);
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    FunctionElement oldFunction = currentFunction;
    currentFunction = elements[node];
    visit(node.body);
    currentFunction = oldFunction;
  }

}
