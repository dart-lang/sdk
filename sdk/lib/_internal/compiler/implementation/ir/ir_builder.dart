// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder;

import 'ir_nodes.dart' as ir;
import '../elements/elements.dart';
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../source_file.dart';
import '../tree/tree.dart' as ast;
import '../scanner/scannerlib.dart' show Token, isUserDefinableOperator;
import '../dart_backend/dart_backend.dart' show DartBackend;
import '../universe/universe.dart' show SelectorKind;
import '../util/util.dart' show Link;

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

  void buildNodes() {
    if (!irEnabled()) return;
    measure(() {
      Map<Element, TreeElements> resolved =
          compiler.enqueuer.resolution.resolvedElements;
      resolved.forEach((Element element, TreeElements elementsMapping) {
        if (canBuild(element)) {
          element = element.implementation;

          SourceFile sourceFile = elementSourceFile(element);
          IrBuilder builder =
              new IrBuilder(elementsMapping, compiler, sourceFile);
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
            compiler.tracer.traceCompilation(element.name, null, compiler);
            compiler.tracer.traceGraph("IR Builder", function);
          }
        }
      });
    });
  }

  bool irEnabled() {
    // TODO(lry): support checked-mode checks.
    return const bool.fromEnvironment('USE_NEW_BACKEND') &&
        compiler.backend is DartBackend &&
        !compiler.enableTypeAssertions &&
        !compiler.enableConcreteTypeInference;
  }

  bool canBuild(Element element) {
    // TODO(lry): support lazy initializers.
    FunctionElement function = element.asFunctionElement();
    if (function == null) return false;

    // TODO(kmillikin): support functions with optional parameters.
    FunctionSignature signature = function.functionSignature;
    if (signature.optionalParameterCount > 0) return false;

    SupportedTypeVerifier typeVerifier = new SupportedTypeVerifier();
    if (!typeVerifier.visit(signature.type.returnType, null)) return false;
    bool parameters_ok = true;
    signature.forEachParameter((parameter) {
      parameters_ok =
          parameters_ok && typeVerifier.visit(parameter.type, null);
    });
    if (!parameters_ok) return false;

    // TODO(kmillikin): support getters and setters and static class members.
    // With the current Dart Tree emitter they just require recognizing them
    // and generating the correct syntax.
    if (element.isGetter || element.isSetter) return false;
    if (element.enclosingElement.isClass) return false;

    // TODO(lry): support native functions (also in [visitReturn]).
    if (function.isNative) return false;

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

/**
 * A tree visitor that builds [IrNodes]. The visit methods add statements using
 * to the [builder] and return the last added statement for trees that represent
 * an expression.
 */
class IrBuilder extends ResolvedVisitor<ir.Primitive> {
  final SourceFile sourceFile;
  final ir.Continuation returnContinuation;
  final List<ir.Parameter> parameters;

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

  ir.Expression root = null;
  ir.Expression current = null;

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
  final Map<Element, int> variableIndex;
  final List<ir.Parameter> freeVars;
  final List<ir.Primitive> assignedVars;

  /// Construct a top-level visitor.
  IrBuilder(TreeElements elements, Compiler compiler, this.sourceFile)
      : returnContinuation = new ir.Continuation.retrn(),
        parameters = <ir.Parameter>[],
        variableIndex = <Element, int>{},
        freeVars = null,
        assignedVars = <ir.Primitive>[],
        super(elements, compiler);

  /// Construct a delimited visitor.
  IrBuilder.delimited(IrBuilder parent)
      : sourceFile = parent.sourceFile,
        returnContinuation = parent.returnContinuation,
        parameters = parent.parameters,
        variableIndex = parent.variableIndex,
        freeVars = new List<ir.Parameter>.generate(
            parent.assignedVars.length, (_) => new ir.Parameter(null),
            growable: false),
        assignedVars = new List<ir.Primitive>.generate(
            parent.assignedVars.length, (_) => null),
        super(parent.elements, parent.compiler);

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
    ast.FunctionExpression function = element.node;
    assert(function != null);
    assert(!function.modifiers.isExternal);
    assert(elements[function] != null);

    root = current = null;

    FunctionSignature signature = element.functionSignature;
    signature.orderedForEachParameter((parameterElement) {
      ir.Parameter parameter = new ir.Parameter(parameterElement);
      parameters.add(parameter);
      variableIndex[parameterElement] = assignedVars.length;
      assignedVars.add(parameter);
    });

    visit(function.body);
    ensureReturn(function);
    return new ir.FunctionDefinition(returnContinuation, parameters, root);
  }

  ConstantSystem get constantSystem => compiler.backend.constantSystem;

  bool get isOpen => root == null || current != null;

  // Plug an expression into the 'hole' in the context being accumulated.  The
  // empty context (just a hole) is represented by root (and current) being
  // null.  Since the hole in the current context is filled by this function,
  // the new hole must be in the newly added expression---which becomes the
  // new value of current.
  void add(ir.Expression expr) {
    assert(isOpen);
    if (root == null) {
      root = current = expr;
    } else {
      current = current.plug(expr);
    }
  }

  /**
   * Add an explicit `return null` for functions that don't have a return
   * statement on each branch. This includes functions with an empty body,
   * such as `foo(){ }`.
   */
  void ensureReturn(ast.FunctionExpression node) {
    if (!isOpen) return;
    ir.Constant constant = new ir.Constant(constantSystem.createNull());
    add(new ir.LetPrim(constant));
    add(new ir.InvokeContinuation(returnContinuation, [constant]));
    current = null;
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

  /// Create branch join continuation parameters and fill in arguments.
  ///
  /// Given delimited builders for the arms of a branch, return a list of
  /// fresh join-point continuation parameters for the join continuation.
  /// Fill in [leftArguments] and [rightArguments] with the left and right
  /// continuation invocation arguments.
  List<ir.Parameter> createBranchJoinParametersAndFillArguments(
      IrBuilder leftBuilder,
      IrBuilder rightBuilder,
      List<ir.Primitive> leftArguments,
      List<ir.Primitive> rightArguments) {
    // The sets of free and assigned variables for a delimited builder is
    // initially the length of the assigned variables of the parent.  The free
    // variables cannot grow because there cannot be free occurrences of
    // variables that were not declared before the entrance to the delimited
    // subgraph.  The assigned variables can grow when new variables are
    // declared in the delimited graph, but we only inspect the prefix
    // corresponding to the parent's declared variables.
    assert(leftBuilder.isOpen);
    assert(rightBuilder.isOpen);
    assert(assignedVars.length <= leftBuilder.assignedVars.length);
    assert(assignedVars.length <= rightBuilder.assignedVars.length);

    List<ir.Parameter> parameters = <ir.Parameter>[];
    // If a variable was assigned on either the left or the right (and control
    // flow reaches the end of the corresponding subterm) then the variable has
    // different values reaching the join point and needs to be passed as an
    // argument to the join point continuation.
    for (int i = 0; i < assignedVars.length; ++i) {
      // The last assignments, if any, reaching the end of the two subterms.
      ir.Primitive leftAssignment = leftBuilder.assignedVars[i];
      ir.Primitive rightAssignment = rightBuilder.assignedVars[i];

      if (leftAssignment != null || rightAssignment != null) {
        // The corresponsing argument is the reaching definition if any, or a
        // free occurrence.  In the case that control does not reach both the
        // left and right subterms we will still have a join continuation with
        // possibly arguments passed to it.  Such singly-used continuations
        // are eliminated by the shrinking conversions.
        parameters.add(new ir.Parameter(null));
        ir.Primitive reachingDefinition =
            assignedVars[i] == null ? freeVars[i] : assignedVars[i];
        leftArguments.add(
            leftAssignment == null ? reachingDefinition : leftAssignment);
        rightArguments.add(
            rightAssignment == null ? reachingDefinition : rightAssignment);
      }
    }
    return parameters;
  }

  /// Allocate loop join continuation parameters and fill in arguments.
  ///
  /// Given delimited builders for a test at the top (while, for, or for-in)
  /// loop's condition and for the loop body, return a list of fresh
  /// join-point continuation parameters for the loop join.  Fill in
  /// [entryArguments] with the arguments to the non-recursive continuation
  /// invocation and [loopArguments] with the arguments to the recursive
  /// continuation invocation.
  ///
  /// The [bodyBuilder] is assumed to be open, otherwise there is no join
  /// necessary.
  List<ir.Parameter> createLoopJoinParametersAndFillArguments(
      List<ir.Primitive> entryArguments,
      IrBuilder condBuilder,
      IrBuilder bodyBuilder,
      List<ir.Primitive> loopArguments) {
    assert(bodyBuilder.isOpen);
    // The loop condition and body are delimited --- assignedVars are still
    // those reaching the entry to the loop.
    assert(assignedVars.length == condBuilder.freeVars.length);
    assert(assignedVars.length == bodyBuilder.freeVars.length);
    assert(assignedVars.length <= condBuilder.assignedVars.length);
    assert(assignedVars.length <= bodyBuilder.assignedVars.length);

    List<ir.Parameter> parameters = <ir.Parameter>[];
    // When the free variables in the loop body are computed later, the
    // parameters are assumed to appear in the same order as they appear in
    // the assignedVars list.
    for (int i = 0; i < assignedVars.length; ++i) {
      // Was there an assignment in the body?
      ir.Definition reachingAssignment = bodyBuilder.assignedVars[i];
      // If not, was there an assignment in the condition?
      if (reachingAssignment == null) {
        reachingAssignment = condBuilder.assignedVars[i];
      }
      // If not, no value needs to be passed to the join point.
      if (reachingAssignment == null) continue;

      parameters.add(new ir.Parameter(null));
      ir.Definition entryAssignment = assignedVars[i];
      entryArguments.add(
          entryAssignment == null ? freeVars[i] : entryAssignment);
      loopArguments.add(reachingAssignment);
    }
    return parameters;
  }

  /// Capture free variables in the arms of a branch.
  ///
  /// Capture the free variables in the left and right arms of a conditional
  /// branch.  The free variables are captured by the current definition.
  /// Also update the builder's assigned variables to be those reaching the
  /// branch join.  If there is no join, [parameters] should be `null` and
  /// at least one of [leftBuilder] or [rightBuilder] should not be open.
  void captureFreeBranchVariables(IrBuilder leftBuilder,
                                  IrBuilder rightBuilder,
                                  List<ir.Parameter> parameters) {
    // Parameters is non-null when there is a join, if and only if both left
    // and right subterm contexts are open.
    assert((leftBuilder.isOpen && rightBuilder.isOpen) ==
           (parameters != null));
    int parameterIndex = 0;
    for (int i = 0; i < assignedVars.length; ++i) {
      // This is the definition that reaches the left and right subterms.  All
      // free uses in either term are uses of this definition.
      ir.Primitive reachingDefinition =
          assignedVars[i] == null ? freeVars[i] : assignedVars[i];
      reachingDefinition
          ..substituteFor(leftBuilder.freeVars[i])
          ..substituteFor(rightBuilder.freeVars[i]);

      // Also add join continuation parameters as assignments for the join
      // body.  This is done last because the assigned variables are updated
      // in place.
      ir.Primitive leftAssignment = leftBuilder.assignedVars[i];
      ir.Primitive rightAssignment = rightBuilder.assignedVars[i];
      if (parameters != null) {
        if (leftAssignment != null || rightAssignment != null) {
          assignedVars[i] = parameters[parameterIndex++];
        }
      } else if (leftBuilder.isOpen) {
        if (leftAssignment != null) assignedVars[i] = leftAssignment;
      } else if (rightBuilder.isOpen) {
        if (rightAssignment != null) assignedVars[i] = rightAssignment;
      }
    }
  }

  /// Capture free variables in a test at the top loop.
  ///
  /// Capture the free variables in the condition and the body of a test at
  /// the top loop (e.g., while, for, or for-in).  Also updates the
  /// builder's assigned variables to be those reaching the loop successor
  /// statement.
  void captureFreeLoopVariables(IrBuilder condBuilder,
                                IrBuilder bodyBuilder,
                                List<ir.Parameter> parameters) {
    // Capturing loop-body variables differs from capturing variables for
    // the predecessors of a non-recursive join-point continuation.  The
    // join point continuation parameters are in scope for the condition
    // and body in the case of a loop.
    int parameterIndex = 0;
    // The parameters are assumed to be in the same order as the corresponding
    // variables appear in the assignedVars list.
    for (int i = 0; i < assignedVars.length; ++i) {
      // Add recursive join continuation parameters as assignments for the
      // join body, if there is a join continuation (parameters != null).
      // This is done first because free occurrences in the loop should be
      // captured by the join continuation parameters.
      if (parameters != null &&
          (condBuilder.assignedVars[i] != null ||
           bodyBuilder.assignedVars[i] != null)) {
        assignedVars[i] = parameters[parameterIndex++];
      }
      ir.Definition reachingDefinition =
            assignedVars[i] == null ? freeVars[i] : assignedVars[i];
      // Free variables in the body can be captured by assignments in the
      // condition.
      if (condBuilder.assignedVars[i] == null) {
        reachingDefinition.substituteFor(bodyBuilder.freeVars[i]);
      } else {
        condBuilder.assignedVars[i].substituteFor(bodyBuilder.freeVars[i]);
      }
      reachingDefinition.substituteFor(condBuilder.freeVars[i]);
    }
  }

  ir.Primitive visitIf(ast.If node) {
    assert(isOpen);
    ir.Primitive condition = visit(node.condition);

    // The then and else parts are delimited.
    IrBuilder thenBuilder = new IrBuilder.delimited(this);
    IrBuilder elseBuilder = new IrBuilder.delimited(this);
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

    List<ir.Parameter> parameters;  // Null if there is no join.
    if (thenBuilder.isOpen && elseBuilder.isOpen) {
      // There is a join-point continuation.  Build the term
      // 'let cont join(x, ...) = [] in Result' and plug invocations of the
      // join-point continuation into the then and else continuations.
      List<ir.Primitive> thenArguments = <ir.Primitive>[];
      List<ir.Primitive> elseArguments = <ir.Primitive>[];

      // Compute the join-point continuation parameters.  Fill in the
      // arguments to the join-point continuation invocations.
      parameters = createBranchJoinParametersAndFillArguments(
          thenBuilder, elseBuilder, thenArguments, elseArguments);
      ir.Continuation joinContinuation = new ir.Continuation(parameters);
      thenBuilder.add(
          new ir.InvokeContinuation(joinContinuation, thenArguments));
      elseBuilder.add(
          new ir.InvokeContinuation(joinContinuation, elseArguments));
      result = new ir.LetCont(joinContinuation, result);
    }

    // Capture free occurrences in the then and else bodies and update the
    // assigned variables for the successor.  This is done after creating
    // invocations of the join continuation so free join continuation
    // arguments are properly captured.
    captureFreeBranchVariables(thenBuilder, elseBuilder, parameters);

    // The then or else term root could be null, but not both.  If there is
    // a join then an InvokeContinuation was just added to both of them.  If
    // there is no join, then at least one of them is closed and thus has a
    // non-null root by the definition of the predicate isClosed.  In the
    // case that one of them is null, it must be the only one that is open
    // and thus contains the new hole in the context.  This case is handled
    // after the branch is plugged into the current hole.
    thenContinuation.body = thenBuilder.root;
    elseContinuation.body = elseBuilder.root;

    add(result);
    if (parameters == null) {
      // At least one subter is closed.
      if (thenBuilder.isOpen) {
        current = (thenBuilder.root == null) ? letThen : thenBuilder.current;
      } else if (elseBuilder.isOpen) {
        current = (elseBuilder.root == null) ? letElse : elseBuilder.current;
      } else {
        current = null;
      }
    }
    return null;
  }

  ir.Primitive visitWhile(ast.While node) {
    assert(isOpen);
    // While loops use three named continuations: the entry to the body,
    // the loop exit (break), and the loop back edge (continue).
    // The CPS translation [[while (condition) body; successor]] is:
    //
    // let cont continue(x, ...) =
    //     let cont break() = [[successor]] in
    //     let cont body() = [[body]]; continue(v, ...) in
    //     let prim cond = [[condition]] in
    //     branch cond (body, break) in
    // continue(v, ...)

    // The condition and body are delimited.
    IrBuilder condBuilder = new IrBuilder.delimited(this);
    IrBuilder bodyBuilder = new IrBuilder.delimited(this);
    ir.Primitive condition = condBuilder.visit(node.condition);
    bodyBuilder.visit(node.body);

    // Create body entry and loop exit continuations and a join-point
    // continuation if control flow reaches the end of the body.
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation breakContinuation = new ir.Continuation([]);
    condBuilder.add(new ir.Branch(new ir.IsTrue(condition),
                                  bodyContinuation,
                                  breakContinuation));
    ir.Continuation continueContinuation;
    List<ir.Parameter> parameters;
    List<ir.Primitive> entryArguments = <ir.Primitive>[];  // The forward edge.
    if (bodyBuilder.isOpen) {
      List<ir.Primitive> loopArguments = <ir.Primitive>[];  // The back edge.
      parameters =
          createLoopJoinParametersAndFillArguments(entryArguments, condBuilder,
                                   bodyBuilder, loopArguments);
      continueContinuation = new ir.Continuation(parameters);
      bodyBuilder.add(
          new ir.InvokeContinuation(continueContinuation, loopArguments,
                                    recursive:true));
    }
    bodyContinuation.body = bodyBuilder.root;

    // Capture free variable occurrences in the loop body.
    captureFreeLoopVariables(condBuilder, bodyBuilder, parameters);

    ir.Expression resultContext =
        new ir.LetCont(breakContinuation,
            new ir.LetCont(bodyContinuation,
                condBuilder.root));
    if (continueContinuation != null) {
      continueContinuation.body = resultContext;
      add(new ir.LetCont(continueContinuation,
            new ir.InvokeContinuation(continueContinuation,
              entryArguments)));
      current = resultContext;
    } else {
      add(resultContext);
    }
    return null;
  }

  ir.Primitive visitVariableDefinitions(ast.VariableDefinitions node) {
    assert(isOpen);
    for (ast.Node definition in node.definitions.nodes) {
      Element element = elements[definition];
      // Definitions are either SendSets if there is an initializer, or
      // Identifiers if there is no initializer.
      if (definition is ast.SendSet) {
        assert(!definition.arguments.isEmpty);
        assert(definition.arguments.tail.isEmpty);
        ir.Primitive initialValue = visit(definition.arguments.head);
        variableIndex[element] = assignedVars.length;
        assignedVars.add(initialValue);
      } else {
        assert(definition is ast.Identifier);
        // The initial value is null.
        // TODO(kmillikin): Consider pooling constants.
        ir.Constant constant = new ir.Constant(constantSystem.createNull());
        add(new ir.LetPrim(constant));
        variableIndex[element] = assignedVars.length;
        assignedVars.add(constant);
      }
    }
    return null;
  }

  // Build(Return(e), C) = C'[InvokeContinuation(return, x)]
  //   where (C', x) = Build(e, C)
  //
  // Return without a subexpression is translated as if it were return null.
  ir.Primitive visitReturn(ast.Return node) {
    assert(isOpen);
    // TODO(lry): support native returns.
    if (node.beginToken.value == 'native') return giveup();
    ir.Primitive value;
    if (node.expression == null) {
      value = new ir.Constant(constantSystem.createNull());
      add(new ir.LetPrim(value));
    } else {
      value = visit(node.expression);
    }
    add(new ir.InvokeContinuation(returnContinuation, [value]));
    current = null;
    return null;
  }

  // ==== Expressions ====
  ir.Primitive visitConditional(ast.Conditional node) {
    assert(isOpen);
    ir.Primitive condition = visit(node.condition);

    // The then and else expressions are delimited.
    IrBuilder thenBuilder = new IrBuilder.delimited(this);
    IrBuilder elseBuilder = new IrBuilder.delimited(this);
    ir.Primitive thenValue = thenBuilder.visit(node.thenExpression);
    ir.Primitive elseValue = elseBuilder.visit(node.elseExpression);

    // Compute the join-point continuation parameters.  Fill in the
    // arguments to the join-point continuation invocations.
    List<ir.Primitive> thenArguments = <ir.Primitive>[];
    List<ir.Primitive> elseArguments = <ir.Primitive>[];
    List<ir.Parameter> parameters =
        createBranchJoinParametersAndFillArguments(
            thenBuilder, elseBuilder, thenArguments, elseArguments);
    // Add a continuation parameter for the result of the expression.
    ir.Parameter resultParameter = new ir.Parameter(null);
    parameters.add(resultParameter);
    thenArguments.add(thenValue);
    elseArguments.add(elseValue);

    // Build the term
    //   let cont join(x, ..., result) = [] in
    //   let cont then() = [[thenPart]]; join(v, ...) in
    //   let cont else() = [[elsePart]]; join(v, ...) in
    //     if condition (then, else)
    ir.Continuation joinContinuation = new ir.Continuation(parameters);
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);
    thenBuilder.add(
        new ir.InvokeContinuation(joinContinuation, thenArguments));
    elseBuilder.add(
        new ir.InvokeContinuation(joinContinuation, elseArguments));

    // Capture free occurrences in the then and else bodies and update the
    // assigned variables for the successor.  This is done after creating
    // invocations of the join continuation so free join continuation
    // arguments are properly captured.
    captureFreeBranchVariables(thenBuilder, elseBuilder, parameters);

    thenContinuation.body = thenBuilder.root;
    elseContinuation.body = elseBuilder.root;
    add(new ir.LetCont(joinContinuation,
            new ir.LetCont(thenContinuation,
                new ir.LetCont(elseContinuation,
                    new ir.Branch(new ir.IsTrue(condition),
                                  thenContinuation,
                                  elseContinuation)))));
    return resultParameter;
  }

  // For all simple literals:
  // Build(Literal(c), C) = C[let val x = Constant(c) in [], x]
  ir.Primitive visitLiteralBool(ast.LiteralBool node) {
    assert(isOpen);
    ir.Constant constant =
        new ir.Constant(constantSystem.createBool(node.value));
    add(new ir.LetPrim(constant));
    return constant;
  }

  ir.Primitive visitLiteralDouble(ast.LiteralDouble node) {
    assert(isOpen);
    ir.Constant constant =
        new ir.Constant(constantSystem.createDouble(node.value));
    add(new ir.LetPrim(constant));
    return constant;
  }

  ir.Primitive visitLiteralInt(ast.LiteralInt node) {
    assert(isOpen);
    ir.Constant constant =
        new ir.Constant(constantSystem.createInt(node.value));
    add(new ir.LetPrim(constant));
    return constant;
  }


  ir.Primitive visitLiteralNull(ast.LiteralNull node) {
    assert(isOpen);
    ir.Constant constant = new ir.Constant(constantSystem.createNull());
    add(new ir.LetPrim(constant));
    return constant;
  }

  ir.Primitive visitLiteralString(ast.LiteralString node) {
    assert(isOpen);
    ir.Constant constant =
        new ir.Constant(constantSystem.createString(node.dartString));
    add(new ir.LetPrim(constant));
    return constant;
  }

  Constant getConstantForNode(ast.Node node) {
    Constant constant =
        compiler.backend.constants.getConstantForNode(node, elements);
    assert(invariant(node, constant != null,
        message: 'No constant computed for $node'));
    return constant;
  }

  bool isSupportedConst(Constant constant) {
    return const SupportedConstantVisitor().visit(constant);
  }

  ir.Primitive visitLiteralList(ast.LiteralList node) {
    assert(isOpen);
    ir.Primitive result;
    if (node.isConst) {
      // TODO(sigurdm): Remove when all constants are supported.
      Constant constant = getConstantForNode(node);
      if (!isSupportedConst(constant)) return giveup();
      result = new ir.Constant(constant);
    } else {
      List<ir.Primitive> values = new List<ir.Primitive>();
      node.elements.nodes.forEach((ast.Node node) {
        values.add(visit(node));
      });
      result = new ir.LiteralList(values);
    }
    add(new ir.LetPrim(result));
    return result;
  }

  ir.Primitive visitLiteralMap(ast.LiteralMap node) {
    assert(isOpen);
    ir.Primitive result;
    if (node.isConst) {
      // TODO(sigurdm): Remove when all constants are supported.
      Constant constant = getConstantForNode(node);
      if (!isSupportedConst(constant)) return giveup();
      result = new ir.Constant(constant);
    } else {
      List<ir.Primitive> keys = new List<ir.Primitive>();
      List<ir.Primitive> values = new List<ir.Primitive>();
      node.entries.nodes.forEach((ast.LiteralMapEntry node) {
        keys.add(visit(node.key));
        values.add(visit(node.value));
      });
      result = new ir.LiteralMap(keys, values);
    }
    add(new ir.LetPrim(result));
    return result;
  }

  ir.Primitive visitLiteralSymbol(ast.LiteralSymbol node) {
    assert(isOpen);
    ir.Constant constant = new ir.Constant(getConstantForNode(node));
    add(new ir.LetPrim(constant));
    return constant;
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

  ir.Primitive lookupLocal(Element element) {
    int index = variableIndex[element];
    ir.Primitive value = assignedVars[index];
    return value == null ? freeVars[index] : value;
  }

  // ==== Sends ====
  ir.Primitive visitAssert(ast.Send node) {
    assert(isOpen);
    return giveup();
  }

  ir.Primitive visitNamedArgument(ast.NamedArgument node) {
    assert(isOpen);
    return visit(node.expression);
  }

  ir.Primitive visitClosureSend(ast.Send node) {
    assert(isOpen);
    Selector closureSelector = elements.getSelector(node);
    Selector namedCallSelector = new Selector(closureSelector.kind,
                     "call",
                     closureSelector.library,
                     closureSelector.argumentCount,
                     closureSelector.namedArguments);
    assert(node.receiver == null);
    Element element = elements[node];
    ir.Primitive closureTarget;
    if (element == null) {
      closureTarget = visit(node.selector);
    } else {
      assert(Elements.isLocal(element));
      closureTarget = lookupLocal(element);
    }
    List<ir.Primitive> arguments = new List<ir.Primitive>();
    for (ast.Node n in node.arguments) {
      arguments.add(visit(n));
    }
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.Expression invoke =
        new ir.InvokeMethod(closureTarget, namedCallSelector, k, arguments);
    add(new ir.LetCont(k, invoke));
    return v;
  }

  ir.Primitive visitDynamicSend(ast.Send node) {
    assert(isOpen);
    if (node.receiver == null || node.receiver.isSuper()) {
      return giveup();
    }
    Selector selector = elements.getSelector(node);
    ir.Primitive receiver = visit(node.receiver);
    List<ir.Primitive> arguments = new List<ir.Primitive>();
    for (ast.Node n in node.arguments) {
      arguments.add(visit(n));
    }
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.Expression invoke =
        new ir.InvokeMethod(receiver, selector, k, arguments);
    add(new ir.LetCont(k, invoke));
    return v;
  }

  ir.Primitive visitGetterSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    if (Elements.isLocal(element)) {
      return lookupLocal(element);
    } else if (element == null || Elements.isInstanceField(element)) {
      ir.Primitive receiver = visit(node.receiver);
      ir.Parameter v = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([v]);
      Selector selector = elements.getSelector(node);
      assert(selector.kind == SelectorKind.GETTER);
      ir.InvokeMethod invoke = new ir.InvokeMethod(receiver, selector, k, []);
      add(new ir.LetCont(k, invoke));
      return v;
    } else {
      // TODO(asgerf): static and top-level
      // NOTE: Index-getters are OperatorSends, not GetterSends
      return giveup();
    }
  }

  ir.Primitive translateLogicalOperator(ast.Operator op,
                                        ast.Expression left,
                                        ast.Expression right) {
    // e0 && e1 is translated as if e0 ? (e1 == true) : false.
    // e0 || e1 is translated as if e0 ? true : (e1 == true).
    // The translation must convert both e0 and e1 to booleans and handle
    // local variable assignments in e1.

    ir.Primitive leftValue = visit(left);
    IrBuilder rightBuilder = new IrBuilder.delimited(this);
    ir.Primitive rightValue = rightBuilder.visit(right);
    // A dummy empty target for the branch on the left subexpression branch.
    // This enables using the same infrastructure for continuation arguments
    // and free variable capture as in visitIf and visitConditional.  It will
    // hold an invocation of the join-point continuation.  It cannot have
    // assigned variables but may have free variables as arguments to the
    // join-point continuation.
    IrBuilder emptyBuilder = new IrBuilder.delimited(this);

    List <ir.Primitive> leftArguments = <ir.Primitive>[];
    List <ir.Primitive> rightArguments = <ir.Primitive>[];
    List <ir.Parameter> parameters =
        createBranchJoinParametersAndFillArguments(
            emptyBuilder, rightBuilder, leftArguments, rightArguments);

    // Add a continuation parameter for the result of the expression.
    ir.Parameter resultParameter = new ir.Parameter(null);
    parameters.add(resultParameter);
    // If we don't evaluate the right subexpression, the value of the whole
    // expression is this constant.
    ir.Constant leftBool =
        new ir.Constant(constantSystem.createBool(op.source == '||'));
    leftArguments.add(leftBool);
    // If we do evaluate the right subexpression, the value of the expression
    // is a true or false constant.
    ir.Constant rightTrue = new ir.Constant(constantSystem.createBool(true));
    ir.Constant rightFalse = new ir.Constant(constantSystem.createBool(false));

    // Wire up two continuations for the left subexpression, two continuations
    // for the right subexpression, and a three-way join continuation.
    ir.Continuation joinContinuation = new ir.Continuation(parameters);
    ir.Continuation leftTrueContinuation = new ir.Continuation([]);
    ir.Continuation leftFalseContinuation = new ir.Continuation([]);
    ir.Continuation rightTrueContinuation = new ir.Continuation([]);
    ir.Continuation rightFalseContinuation = new ir.Continuation([]);
    // If right is true, invoke the join with a true value for the result.
    rightArguments.add(rightTrue);
    rightTrueContinuation.body = new ir.LetPrim(rightTrue)
        ..plug(new ir.InvokeContinuation(joinContinuation, rightArguments));
    // And if false, invoke the join continuation with a false value.  The
    // argument list of definitions can be mutated, because fresh Reference
    // objects are allocated by the InvokeContinuation constructor.
    rightArguments[rightArguments.length - 1] = rightFalse;
    rightFalseContinuation.body = new ir.LetPrim(rightFalse)
        ..plug(new ir.InvokeContinuation(joinContinuation, rightArguments));
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
      leftTrueContinuation.body = rightBuilder.root;
      leftFalseContinuation.body = new ir.LetPrim(leftBool)
          ..plug(new ir.InvokeContinuation(joinContinuation, leftArguments));
    } else {
      leftTrueContinuation.body = new ir.LetPrim(leftBool)
          ..plug(new ir.InvokeContinuation(joinContinuation, leftArguments));
      leftFalseContinuation.body = rightBuilder.root;
    }

    // Capture free local variable occurrences in the right subexpression
    // and update the reaching definitions for the join-point continuation
    // body to include the continuation's parameters.
    captureFreeBranchVariables(rightBuilder, emptyBuilder, parameters);

    add(new ir.LetCont(joinContinuation,
            new ir.LetCont(leftTrueContinuation,
                new ir.LetCont(leftFalseContinuation,
                    new ir.Branch(new ir.IsTrue(leftValue),
                                  leftTrueContinuation,
                                  leftFalseContinuation)))));
    return resultParameter;
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
    return giveup();
  }

  // Build(StaticSend(f, arguments), C) = C[C'[InvokeStatic(f, xs)]]
  //   where (C', xs) = arguments.fold(Build, C)
  ir.Primitive visitStaticSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    // TODO(lry): support static fields. (separate IR instruction?)
    if (element.isField || element.isGetter) return giveup();
    // TODO(kmillikin): support static setters.
    if (element.isSetter) return giveup();
    // TODO(lry): support constructors / factory calls.
    if (element.isConstructor) return giveup();
    // TODO(lry): support foreign functions.
    if (element.isForeign(compiler)) return giveup();
    // TODO(lry): for elements that could not be resolved emit code to throw a
    // [NoSuchMethodError].
    if (element.isErroneous) return giveup();
    // TODO(lry): generate IR for object identicality.
    if (element == compiler.identicalFunction) giveup();

    Selector selector = elements.getSelector(node);

    // TODO(kmillikin): support a receiver: A.m().
    if (node.receiver != null) return giveup();

    // TODO(lry): support default arguments, need support for locals.
    List<ir.Definition> arguments = node.arguments.toList(growable:false)
                                       .map(visit).toList(growable:false);
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.Expression invoke =
        new ir.InvokeStatic(element, selector, k, arguments);
    add(new ir.LetCont(k, invoke));
    return v;
  }

  ir.Primitive visitSuperSend(ast.Send node) {
    assert(isOpen);
    return giveup();
  }

  ir.Primitive visitTypeReferenceSend(ast.Send node) {
    assert(isOpen);
    return giveup();
  }

  ir.Primitive visitSendSet(ast.SendSet node) {
    assert(isOpen);
    Element element = elements[node];
    if (node.assignmentOperator.source != '=') return giveup();
    if (Elements.isLocal(element)) {
      // Exactly one argument expected for a simple assignment.
      assert(!node.arguments.isEmpty);
      assert(node.arguments.tail.isEmpty);
      ir.Primitive result = visit(node.arguments.head);
      assignedVars[variableIndex[element]] = result;
      return result;
    } else if (Elements.isStaticOrTopLevel(element)) {
      // TODO(asgerf): static and top-level
      return giveup();
    } else if (node.receiver == null) {
      // Nodes that fall in this case:
      // - Unresolved top-level
      // - Assignment to final variable (will not be resolved)
      return giveup();
    } else {
      // Setter or index-setter invocation
      assert(node.receiver != null);
      if (node.receiver.isSuper()) return giveup();

      ir.Primitive receiver = visit(node.receiver);
      ir.Parameter v = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([v]);
      Selector selector = elements.getSelector(node);
      assert(selector.kind == SelectorKind.SETTER ||
             selector.kind == SelectorKind.INDEX);
      List<ir.Definition> args = node.arguments.toList(growable:false)
                                     .map(visit).toList(growable:false);
      ir.InvokeMethod invoke = new ir.InvokeMethod(receiver, selector, k, args);
      add(new ir.LetCont(k, invoke));
      return args.last;
    }
  }

  ir.Primitive visitNewExpression(ast.NewExpression node) {
    if (node.isConst) {
      return giveup(); // TODO(asgerf): Const constructor call.
    }
    FunctionElement element = elements[node.send];
    if (Elements.isUnresolved(element)) {
      return giveup();
    }
    ast.Node selector = node.send.selector;
    GenericType type = elements.getType(node);
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    List<ir.Definition> args = node.send.arguments.toList(growable:false)
                                        .map(visit).toList(growable:false);
    ir.InvokeConstructor invoke = new ir.InvokeConstructor(
        type,
        element,
        elements.getSelector(node.send),
        k,
        args);
    add(new ir.LetCont(k, invoke));
    return v;
  }

  ir.Primitive visitStringJuxtaposition(ast.StringJuxtaposition node) {
    ir.Primitive first = visit(node.first);
    ir.Primitive second = visit(node.second);
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.ConcatenateStrings concat =
        new ir.ConcatenateStrings(k, [first, second]);
    add(new ir.LetCont(k, concat));
    return v;
  }

  ir.Primitive visitStringInterpolation(ast.StringInterpolation node) {
    List<ir.Primitive> arguments = [];
    arguments.add(visitLiteralString(node.string));
    var it = node.parts.iterator;
    while (it.moveNext()) {
      ast.StringInterpolationPart part = it.current;
      arguments.add(visit(part.expression));
      arguments.add(visitLiteralString(part.string));
    }
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.ConcatenateStrings concat = new ir.ConcatenateStrings(k, arguments);
    add(new ir.LetCont(k, concat));
    return v;
  }

  static final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

  ir.Primitive giveup() => throw ABORT_IRNODE_BUILDER;

  ir.FunctionDefinition nullIfGiveup(ir.FunctionDefinition action()) {
    try {
      return action();
    } catch(e) {
      if (e == ABORT_IRNODE_BUILDER) return null;
      rethrow;
    }
  }

  void internalError(String reason, {ast.Node node}) {
    giveup();
  }
}

// While we don't support all constants we need to filter out the unsupported
// ones:
class SupportedConstantVisitor extends ConstantVisitor<bool> {
  const SupportedConstantVisitor();

  bool visit(Constant constant) => constant.accept(this);
  bool visitFunction(FunctionConstant constant) => false;
  bool visitNull(NullConstant constant) => true;
  bool visitInt(IntConstant constant) => true;
  bool visitDouble(DoubleConstant constant) => true;
  bool visitTrue(TrueConstant constant) => true;
  bool visitFalse(FalseConstant constant) => true;
  bool visitString(StringConstant constant) => true;
  bool visitList(ListConstant constant) {
    return constant.entries.every(visit);
  }
  bool visitMap(MapConstant constant) {
    return visit(constant.keys) && constant.values.every(visit);
  }
  bool visitConstructed(ConstructedConstant constant) => false;
  bool visitType(TypeConstant constant) => false;
  bool visitInterceptor(InterceptorConstant constant) => false;
  bool visitDummy(DummyConstant constant) => false;
  bool visitDeferred(DeferredConstant constant) => false;
}

// Verify that types are ones that can be reconstructed by the type emitter.
class SupportedTypeVerifier extends DartTypeVisitor<bool, Null> {
  bool visit(DartType type, Null _) => type.accept(this, null);

  bool visitType(DartType type, Null _) => false;

  bool visitVoidType(VoidType type, Null _) => true;

  // Currently, InterfaceType and TypedefType are supported so long as they
  // do not have type parameters.  They are subclasses of GenericType.
  bool visitGenericType(GenericType type, Null _) => !type.isGeneric;
}
