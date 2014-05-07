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
import '../scanner/scannerlib.dart' show Token;
import '../dart_backend/dart_backend.dart' show DartBackend;
import 'ir_pickler.dart' show Unpickler, IrConstantPool;

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
          } else if (element.isDeferredLoaderGetter()) {
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
            assert(() {
              // In host-checked mode, serialize and de-serialize the IrNode.
              LibraryElement library = element.declaration.getLibrary();
              IrConstantPool constantPool = IrConstantPool.forLibrary(library);
              List<int> data = function.pickle(constantPool);
              function = new Unpickler(compiler, constantPool).unpickle(data);
              return true;
            });
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
    if (compiler.enableTypeAssertions ||
        compiler.backend is !DartBackend ||
        compiler.enableConcreteTypeInference) {
      return false;
    }
    return const bool.fromEnvironment('enable_ir', defaultValue: true);
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
    if (element.isGetter() || element.isSetter()) return false;
    if (element.enclosingElement.isClass()) return false;

    // TODO(lry): support native functions (also in [visitReturn]).
    if (function.isNative()) return false;

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
    return element.getCompilationUnit().script.file;
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
    ast.FunctionExpression function = element.parseNode(compiler);
    assert(function != null);
    assert(!function.modifiers.isExternal());
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

  ir.Primitive visitIf(ast.If node) {
    assert(isOpen);
    ir.Primitive condition = visit(node.condition);

    // The then and else parts are delimited.
    IrBuilder thenBuilder = new IrBuilder.delimited(this);
    thenBuilder.visit(node.thenPart);
    IrBuilder elseBuilder = new IrBuilder.delimited(this);
    if (node.hasElsePart) elseBuilder.visit(node.elsePart);

    // The free variables in the then and else parts are uses of definitions
    // from an outer builder.  Capture them or propagate them outward.  The
    // assigned variables in the then and else parts are arguments to the join
    // point continuation if any.

    // FreeVars is initially the length of assignedVars of the parent, and it
    // does not grow.  AssignedVars can grow.
    assert(assignedVars.length == thenBuilder.freeVars.length);
    assert(assignedVars.length == elseBuilder.freeVars.length);
    assert(assignedVars.length <= thenBuilder.assignedVars.length);
    assert(assignedVars.length <= elseBuilder.assignedVars.length);
    List<ir.Parameter> parameters = <ir.Parameter>[];
    List<ir.Primitive> thenArguments = <ir.Primitive>[];
    List<ir.Primitive> elseArguments = <ir.Primitive>[];
    for (int i = 0; i < assignedVars.length; ++i) {
      // These are the last assignments, if any, in the then and else
      // continuations respectively (if they can reach the join point).  If a
      // variable is assigned in either branch reaching the join point, it has
      // different values that must be passed as an argument to the join point
      // continuation.
      ir.Definition thenAssignment =
          thenBuilder.isOpen ? thenBuilder.assignedVars[i] : null;
      ir.Definition elseAssignment =
          elseBuilder.isOpen ? elseBuilder.assignedVars[i] : null;
      if (thenAssignment != null || elseAssignment != null) {
        // In the case that not both then and else parts can reach the join
        // point, there will still be a join-point continuation possibly with
        // arguments passed to it.  Such singly-used continuations should be
        // eliminated by shrinking conversions (because they can arise
        // otherwise as the result of optimization).
        ir.Parameter parameter = new ir.Parameter(null);
        parameters.add(parameter);
        thenArguments.add(thenAssignment == null
                              ? thenBuilder.freeVars[i]
                              : thenAssignment);
        elseArguments.add(elseAssignment == null
                              ? elseBuilder.freeVars[i]
                              : elseAssignment);
      }
    }

    // Create a then and else continuations and a join continuation if
    // necessary.  Jump to the join continuation from the exits of the then
    // and else continuations.
    ir.Continuation joinContinuation;
    ir.Continuation thenContinuation = new ir.Continuation([]);
    ir.Continuation elseContinuation = new ir.Continuation([]);
    if (thenBuilder.isOpen || elseBuilder.isOpen) {
      joinContinuation = new ir.Continuation(parameters);
      if (thenBuilder.isOpen) {
        thenBuilder.add(
            new ir.InvokeContinuation(joinContinuation, thenArguments));
      }
      if (elseBuilder.isOpen) {
        elseBuilder.add(
            new ir.InvokeContinuation(joinContinuation, elseArguments));
      }
    }
    thenContinuation.body = thenBuilder.root;
    elseContinuation.body = elseBuilder.root;

    // Capture free occurrences in the then and else bodies.  This is done
    // after creating invocations of the join continuation so free join
    // continuation arguments are properly captured.
    //
    // Also add join continuation parameters as assignments for the join body.
    // This is done last because the assigned variables are updated in place.
    int parameterIndex = 0;
    for (int i = 0; i < assignedVars.length; ++i) {
      // This is the definition that reaches the then and else continuations.
      // All free uses in either continuation are uses of this definition.
      ir.Definition reachingDefinition =
          assignedVars[i] == null ? freeVars[i] : assignedVars[i];
      reachingDefinition
          ..substituteFor(thenBuilder.freeVars[i])
          ..substituteFor(elseBuilder.freeVars[i]);

      if ((thenBuilder.isOpen && thenBuilder.assignedVars[i] != null) ||
          (elseBuilder.isOpen && elseBuilder.assignedVars[i] != null)) {
        assignedVars[i] = parameters[parameterIndex++];
      }
    }

    ir.Expression branch =
        new ir.LetCont(thenContinuation,
            new ir.LetCont(elseContinuation,
                new ir.Branch(new ir.IsTrue(condition),
                              thenContinuation,
                              elseContinuation)));
    if (joinContinuation == null) {
      add(branch);
      current = null;
    } else {
      add(new ir.LetCont(joinContinuation, branch));
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

  // TODO(kmillikin): other literals.  Strings require quoting and escaping
  // in the Dart backend.
  //   LiteralString
  //   LiteralList
  //   LiteralMap
  //   LiteralMapEntry
  //   LiteralSymbol

  ir.Primitive visitParenthesizedExpression(
      ast.ParenthesizedExpression node) {
    assert(isOpen);
    return visit(node.expression);
  }

  // ==== Sends ====
  ir.Primitive visitAssert(ast.Send node) {
    assert(isOpen);
    return giveup();
  }

  ir.Primitive visitClosureSend(ast.Send node) {
    assert(isOpen);
    return giveup();
  }

  ir.Primitive visitDynamicSend(ast.Send node) {
    assert(isOpen);
    return giveup();
  }

  ir.Primitive visitGetterSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    if (!Elements.isLocal(element)) return giveup();
    int index = variableIndex[element];
    ir.Primitive value = assignedVars[index];
    return value == null ? freeVars[index] : value;
  }

  ir.Primitive visitOperatorSend(ast.Send node) {
    assert(isOpen);
    return giveup();
  }

  // Build(StaticSend(f, arguments), C) = C[C'[InvokeStatic(f, xs)]]
  //   where (C', xs) = arguments.fold(Build, C)
  ir.Primitive visitStaticSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    // TODO(lry): support static fields. (separate IR instruction?)
    if (element.isField() || element.isGetter()) return giveup();
    // TODO(kmillikin): support static setters.
    if (element.isSetter()) return giveup();
    // TODO(lry): support constructors / factory calls.
    if (element.isConstructor()) return giveup();
    // TODO(lry): support foreign functions.
    if (element.isForeign(compiler)) return giveup();
    // TODO(lry): for elements that could not be resolved emit code to throw a
    // [NoSuchMethodError].
    if (element.isErroneous()) return giveup();
    // TODO(lry): generate IR for object identicality.
    if (element == compiler.identicalFunction) giveup();

    Selector selector = elements.getSelector(node);
    // TODO(lry): support named arguments
    if (selector.namedArgumentCount != 0) return giveup();

    // TODO(kmillikin): support a receiver: A.m().
    if (node.receiver != null) return giveup();

    List arguments = [];
    // TODO(lry): support default arguments, need support for locals.
    bool succeeded = selector.addArgumentsToList(
        node.arguments, arguments, element.implementation, visit,
        (node) => giveup(), compiler);
    if (!succeeded) {
      // TODO(lry): generate code to throw a [WrongArgumentCountError].
      return giveup();
    }
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
    if (!Elements.isLocal(element)) return giveup();
    if (node.assignmentOperator.source != '=') return giveup();
    // Exactly one argument expected for a simple assignment.
    assert(!node.arguments.isEmpty);
    assert(node.arguments.tail.isEmpty);
    ir.Primitive result = visit(node.arguments.head);
    assignedVars[variableIndex[element]] = result;
    return result;
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

// Verify that types are ones that can be reconstructed by the type emitter.
class SupportedTypeVerifier extends DartTypeVisitor<bool, Null> {
  bool visit(DartType type, Null _) => type.accept(this, null);

  bool visitType(DartType type, Null _) => false;

  bool visitVoidType(VoidType type, Null _) => true;

  // Currently, InterfaceType and TypedefType are supported so long as they
  // do not have type parameters.  They are subclasses of GenericType.
  bool visitGenericType(GenericType type, Null _) => !type.isGeneric;
}
