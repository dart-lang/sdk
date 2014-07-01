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

  void buildNodes() {
    if (!irEnabled()) return;
    measure(() {
      Set<Element> resolved = compiler.enqueuer.resolution.resolvedElements;
      resolved.forEach((AstElement element) {
        if (canBuild(element)) {
          TreeElements elementsMapping = element.resolvedAst.elements;
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

            new ir.RegisterAllocator().visit(function);
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

    if (!compiler.backend.shouldOutput(function)) return false;

    // TODO(kmillikin): support functions with optional parameters.
    FunctionSignature signature = function.functionSignature;
    if (signature.optionalParameterCount > 0) return false;

    // TODO(kmillikin): support getters and setters and static class members.
    // With the current Dart Tree emitter they just require recognizing them
    // and generating the correct syntax.
    if (element.isGetter || element.isSetter) return false;

    // TODO(lry): support native functions (also in [visitReturn]).
    if (function.isNative) return false;

    // TODO(asgerf): support syntax for redirecting factory constructors
    if (function is ConstructorElement && function.isRedirectingFactory) {
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
  final List<Element> index2variable;
  final List<ir.Parameter> freeVars;
  final List<ir.Primitive> assignedVars;

  ConstExpBuilder constantBuilder;

  final List<ConstDeclaration> localConstants;

  /// Construct a top-level visitor.
  IrBuilder(TreeElements elements, Compiler compiler, this.sourceFile)
      : returnContinuation = new ir.Continuation.retrn(),
        parameters = <ir.Parameter>[],
        variableIndex = <Element, int>{},
        freeVars = null,
        assignedVars = <ir.Primitive>[],
        index2variable = <Element>[],
        localConstants = <ConstDeclaration>[],
        super(elements, compiler) {
          constantBuilder = new ConstExpBuilder(this);
        }

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
        index2variable = new List<Element>.from(parent.index2variable),
        constantBuilder = parent.constantBuilder,
        localConstants = parent.localConstants,
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
      index2variable.add(parameterElement);
    });

    visit(function.body);
    ensureReturn(function);
    return new ir.FunctionDefinition(returnContinuation, parameters, root,
        localConstants);
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

  ir.Constant makeConst(ConstExp exp, Constant value) {
    return new ir.Constant(exp, value);
  }

  ir.Constant makePrimConst(PrimitiveConstant value) {
    return makeConst(new PrimitiveConstExp(value), value);
  }

  /**
   * Add an explicit `return null` for functions that don't have a return
   * statement on each branch. This includes functions with an empty body,
   * such as `foo(){ }`.
   */
  void ensureReturn(ast.FunctionExpression node) {
    if (!isOpen) return;
    ir.Constant constant = makePrimConst(constantSystem.createNull());
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
        parameters.add(new ir.Parameter(index2variable[i]));
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
      IrBuilder conditionBuilder,
      IrBuilder bodyBuilder,
      List<ir.Primitive> entryArguments,
      List<ir.Primitive> loopArguments) {
    assert(bodyBuilder.isOpen);
    // The loop condition and body are delimited --- assignedVars are still
    // those reaching the entry to the loop.
    assert(assignedVars.length == conditionBuilder.freeVars.length);
    assert(assignedVars.length == bodyBuilder.freeVars.length);
    assert(assignedVars.length <= conditionBuilder.assignedVars.length);
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
        reachingAssignment = conditionBuilder.assignedVars[i];
      }
      // If not, no value needs to be passed to the join point.
      if (reachingAssignment == null) continue;

      parameters.add(new ir.Parameter(index2variable[i]));
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

  ir.Primitive visitFor(ast.For node) {
    assert(isOpen);
    // For loops use three named continuations: the entry to the condition,
    // the entry to the body, and the loop exit (break).  The CPS translation
    // of [[for (initializer; condition; update) body; successor]] is:
    //
    // [[initializer]];
    // let cont loop(x, ...) =
    //     let cont exit() = [[successor]] in
    //     let cont body() = [[body]]; [[update]]; loop(v, ...) in
    //     let prim cond = [[condition]] in
    //     branch cond (body, exit) in
    // loop(v, ...)

    if (node.initializer != null) visit(node.initializer);

    // If the condition is empty then the body is entered unconditionally.
    IrBuilder condBuilder = new IrBuilder.delimited(this);
    ir.Primitive condition;
    if (node.condition == null) {
      condition = makePrimConst(constantSystem.createBool(true));
      condBuilder.add(new ir.LetPrim(condition));
    } else {
      condition = condBuilder.visit(node.condition);
    }

    IrBuilder bodyBuilder = new IrBuilder.delimited(this);
    bodyBuilder.visit(node.body);
    for (ast.Node n in node.update) {
      if (!bodyBuilder.isOpen) break;
      bodyBuilder.visit(n);
    }

    // Create body entry and loop exit continuations and a join-point
    // continuation if control flow reaches the end of the body (update).
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation exitContinuation = new ir.Continuation([]);
    condBuilder.add(new ir.Branch(new ir.IsTrue(condition),
                                  bodyContinuation,
                                  exitContinuation));
    ir.Continuation loopContinuation;
    List<ir.Parameter> parameters;
    List<ir.Primitive> entryArguments = <ir.Primitive>[];
    if (bodyBuilder.isOpen) {
      List<ir.Primitive> loopArguments = <ir.Primitive>[];
      parameters =
          createLoopJoinParametersAndFillArguments(
              condBuilder, bodyBuilder, entryArguments, loopArguments);
      loopContinuation = new ir.Continuation(parameters);
      bodyBuilder.add(
          new ir.InvokeContinuation(loopContinuation, loopArguments,
                                    recursive:true));
    }
    bodyContinuation.body = bodyBuilder.root;

    captureFreeLoopVariables(condBuilder, bodyBuilder, parameters);

    ir.Expression resultContext =
        new ir.LetCont(exitContinuation,
            new ir.LetCont(bodyContinuation,
                condBuilder.root));
    if (loopContinuation != null) {
      loopContinuation.body = resultContext;
      add(new ir.LetCont(loopContinuation,
              new ir.InvokeContinuation(loopContinuation, entryArguments)));
      current = resultContext;
    } else {
      add(resultContext);
    }
    return null;
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
    // let cont loop(x, ...) =
    //     let cont exit() = [[successor]] in
    //     let cont body() = [[body]]; continue(v, ...) in
    //     let prim cond = [[condition]] in
    //     branch cond (body, exit) in
    // loop(v, ...)

    // The condition and body are delimited.
    IrBuilder condBuilder = new IrBuilder.delimited(this);
    IrBuilder bodyBuilder = new IrBuilder.delimited(this);
    ir.Primitive condition = condBuilder.visit(node.condition);
    bodyBuilder.visit(node.body);

    // Create body entry and loop exit continuations and a join-point
    // continuation if control flow reaches the end of the body.
    ir.Continuation bodyContinuation = new ir.Continuation([]);
    ir.Continuation exitContinuation = new ir.Continuation([]);
    condBuilder.add(new ir.Branch(new ir.IsTrue(condition),
                                  bodyContinuation,
                                  exitContinuation));
    ir.Continuation loopContinuation;
    List<ir.Parameter> parameters;
    List<ir.Primitive> entryArguments = <ir.Primitive>[];  // The forward edge.
    if (bodyBuilder.isOpen) {
      List<ir.Primitive> loopArguments = <ir.Primitive>[];  // The back edge.
      parameters =
          createLoopJoinParametersAndFillArguments(
              condBuilder, bodyBuilder, entryArguments, loopArguments);
      loopContinuation = new ir.Continuation(parameters);
      bodyBuilder.add(
          new ir.InvokeContinuation(loopContinuation, loopArguments,
                                    recursive:true));
    }
    bodyContinuation.body = bodyBuilder.root;

    // Capture free variable occurrences in the loop body.
    captureFreeLoopVariables(condBuilder, bodyBuilder, parameters);

    ir.Expression resultContext =
        new ir.LetCont(exitContinuation,
            new ir.LetCont(bodyContinuation,
                condBuilder.root));
    if (loopContinuation != null) {
      loopContinuation.body = resultContext;
      add(new ir.LetCont(loopContinuation,
              new ir.InvokeContinuation(loopContinuation, entryArguments)));
      current = resultContext;
    } else {
      add(resultContext);
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
        // Definitions are either SendSets if there is an initializer, or
        // Identifiers if there is no initializer.
        if (definition is ast.SendSet) {
          assert(!definition.arguments.isEmpty);
          assert(definition.arguments.tail.isEmpty);
          ir.Primitive initialValue = visit(definition.arguments.head);
          // In case a primitive was introduced for the initializer expression,
          // use this variable element to help derive a good name for it.
          initialValue.useElementAsHint(element);
          variableIndex[element] = assignedVars.length;
          assignedVars.add(initialValue);
          index2variable.add(element);
        } else {
          assert(definition is ast.Identifier);
          // The initial value is null.
          // TODO(kmillikin): Consider pooling constants.
          ir.Constant constant = makePrimConst(constantSystem.createNull());
          constant.useElementAsHint(element);
          add(new ir.LetPrim(constant));
          variableIndex[element] = assignedVars.length;
          assignedVars.add(constant);
          index2variable.add(element);
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
    assert(isOpen);
    // TODO(lry): support native returns.
    if (node.beginToken.value == 'native') return giveup(node, 'Native return');
    ir.Primitive value;
    if (node.expression == null) {
      value = makePrimConst(constantSystem.createNull());
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

  ir.Primitive lookupLocal(Element element) {
    assert(!element.isConst);
    int index = variableIndex[element];
    ir.Primitive value = assignedVars[index];
    return value == null ? freeVars[index] : value;
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
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.Expression invoke =
        new ir.InvokeMethod(receiver, namedCallSelector, k, args);
    add(new ir.LetCont(k, invoke));
    return v;
  }

  ir.Primitive visitClosureSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    ir.Primitive closureTarget;
    if (element == null) {
      closureTarget = visit(node.selector);
    } else {
      assert(Elements.isLocal(element));
      closureTarget = lookupLocal(element);
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
    return node.receiver != null && node.receiver.isSuper()
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
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.Expression invoke =
        createDynamicInvoke(node, selector, receiver, k, arguments);
    add(new ir.LetCont(k, invoke));
    return v;
  }

  _GetterElements translateGetter(ast.Send node, Selector selector) {
    Element element = elements[node];
    ir.Primitive result;
    ir.Primitive receiver;
    ir.Primitive index;

    if (Elements.isErroneousElement(element)) {
      giveup(node, 'Erroneous element on GetterSend');
      return null;
    }

    if (element != null && element.isConst) {
      // Reference to constant local, top-level or static field

      result = translateConstant(node);
    } else if (Elements.isLocal(element)) {
      // Reference to local variable

      result = lookupLocal(element);
    } else if (element == null ||
               Elements.isInstanceField(element) ||
               Elements.isInstanceMethod(element) ||
               selector.isIndex ||
               node.isSuperCall) {
    // Dynamic dispatch to a getter. Sometimes resolution will suggest a target
    // element, but in these cases we must still emit a dynamic dispatch. The
    // target element may be an instance method in case we are converting a
    // method to a function object.

      receiver = visitReceiver(node.receiver);
      List<ir.Primitive> arguments = new List<ir.Primitive>();
      if (selector.isIndex) {
        index = visit(node.arguments.head);
        arguments.add(index);
      }

      ir.Parameter v = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([v]);
      assert(selector.kind == SelectorKind.GETTER ||
             selector.kind == SelectorKind.INDEX);
      ir.Expression invoke =
          createDynamicInvoke(node, selector, receiver, k, arguments);
      add(new ir.LetCont(k, invoke));
      result = v;
    } else if (element.isField || element.isGetter ||
        // Access to a static field or getter (non-static case handled above).
        // Even if there is only a setter, we compile as if it was a getter,
        // so the vm can fail at runtime.

        element.isSetter) {
      ir.Parameter v = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([v]);
      assert(selector.kind == SelectorKind.GETTER ||
             selector.kind == SelectorKind.SETTER);
      ir.Expression invoke =
          new ir.InvokeStatic(element, selector, k, []);
      add(new ir.LetCont(k, invoke));
      result = v;
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
        makePrimConst(constantSystem.createBool(op.source == '||'));
    leftArguments.add(leftBool);
    // If we do evaluate the right subexpression, the value of the expression
    // is a true or false constant.
    ir.Constant rightTrue = makePrimConst(constantSystem.createBool(true));
    ir.Constant rightFalse = makePrimConst(constantSystem.createBool(false));

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
    if (op.source == "is") {
      DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
      if (type.isMalformed) return giveup(node, "Malformed type for is");
      ir.Primitive receiver = visit(node.receiver);
      ir.IsCheck isCheck = new ir.IsCheck(receiver, type);
      add(new ir.LetPrim(isCheck));
      return node.isIsNotCheck ? buildNegation(isCheck) : isCheck;
    }
    if (op.source == "as") {
      DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
      if (type.isMalformed) return giveup(node, "Malformed type for as");
      ir.Primitive receiver = visit(node.receiver);
      ir.Parameter v = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([v]);
      ir.AsCast asCast = new ir.AsCast(receiver, type, k);
      add(new ir.LetCont(k, asCast));
      return v;
    }
    return giveup(node);
  }

  // Build(StaticSend(f, arguments), C) = C[C'[InvokeStatic(f, xs)]]
  //   where (C', xs) = arguments.fold(Build, C)
  ir.Primitive visitStaticSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    // TODO(lry): support constructors / factory calls.
    if (element.isConstructor) return giveup(node, 'StaticSend: constructor');
    // TODO(lry): support foreign functions.
    if (element.isForeign(compiler)) return giveup(node, 'StaticSend: foreign');
    // TODO(lry): for elements that could not be resolved emit code to throw a
    // [NoSuchMethodError].
    if (element.isErroneous) return giveup(node, 'StaticSend: erroneous');
    // TODO(lry): generate IR for object identicality.
    if (element == compiler.identicalFunction) {
      return giveup(node, 'StaticSend: identical');
    }

    Selector selector = elements.getSelector(node);

    // TODO(lry): support default arguments, need support for locals.
    List<ir.Definition> arguments = node.arguments.mapToList(visit,
                                                             growable:false);
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.Expression invoke =
        new ir.InvokeStatic(element, selector, k, arguments);
    add(new ir.LetCont(k, invoke));
    return v;
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
      // TODO(sigurdm): Change this to match proposed semantics of issue #19725.
      return visitDynamicSend(node);
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

    ast.Node assignArg = selector.isIndexSet
        ? node.arguments.tail.head
        : node.arguments.head;

    // Get the value into valueToStore
    if (op.source == "=") {
      if (selector.isIndexSet) {
        receiver = visitReceiver(node.receiver);
        index = visit(node.arguments.head);
      } else if (element == null || Elements.isInstanceField(element)) {
        receiver = visitReceiver(node.receiver);
      }
      valueToStore = visit(assignArg);
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
        arg = visit(assignArg);
      }
      valueToStore = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([valueToStore]);
      ir.Expression invoke =
          new ir.InvokeMethod(originalValue, operatorSelector, k, [arg]);
      add(new ir.LetCont(k, invoke));
    }

    // Set the value
    if (Elements.isLocal(element)) {
      valueToStore.useElementAsHint(element);
      assignedVars[variableIndex[element]] = valueToStore;
    } else if (Elements.isStaticOrTopLevel(element)) {
      assert(element.isField || element.isSetter);
      ir.Parameter v = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([v]);
      Selector selector = elements.getSelector(node);
      ir.InvokeStatic invoke =
          new ir.InvokeStatic(element, selector, k, [valueToStore]);
      add(new ir.LetCont(k, invoke));
    } else {
      if (element != null && Elements.isUnresolved(element)) {
        return giveup(node, 'SendSet: non-local, non-static, unresolved');
      }
      // Setter or index-setter invocation
      ir.Parameter v = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([v]);
      Selector selector = elements.getSelector(node);
      assert(selector.kind == SelectorKind.SETTER ||
          selector.kind == SelectorKind.INDEX);
      List<ir.Definition> arguments = selector.isIndexSet
          ? [index, valueToStore]
          : [valueToStore];
      ir.Expression invoke =
          createDynamicInvoke(node, selector, receiver, k, arguments);
      add(new ir.LetCont(k, invoke));
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
    if (Elements.isUnresolved(element)) {
      return giveup(node, 'NewExpression: unresolved constructor');
    }
    Selector selector = elements.getSelector(node.send);
    ast.Node selectorNode = node.send.selector;
    GenericType type = elements.getType(node);
    List<ir.Primitive> args =
        node.send.arguments.mapToList(visit, growable:false);
    ir.Parameter v = new ir.Parameter(null);
    ir.Continuation k = new ir.Continuation([v]);
    ir.InvokeConstructor invoke =
        new ir.InvokeConstructor(type, element,selector, k, args);
    add(new ir.LetCont(k, invoke));
    return v;
  }

  ir.Primitive visitStringJuxtaposition(ast.StringJuxtaposition node) {
    assert(isOpen);
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
    assert(isOpen);
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

  ir.Primitive translateConstant(ast.Node node, [Constant value]) {
    assert(isOpen);
    if (value == null) {
      value = getConstantForNode(node);
    }
    ir.Primitive primitive = makeConst(constantBuilder.visit(node), value);
    add(new ir.LetPrim(primitive));
    return primitive;
  }

  static final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

  ir.Primitive giveup(ast.Node node, [String reason]) {
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
  final IrBuilder parent;
  final TreeElements elements;
  final ConstantSystem constantSystem;
  final ConstantCompiler constantCompiler;

  ConstExpBuilder(IrBuilder parent)
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
    if (Elements.isUnresolved(element)) {
      throw parent.giveup(node, 'const NewExpression: unresolved constructor');
    }
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
