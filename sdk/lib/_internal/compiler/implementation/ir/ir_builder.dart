// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder;

import 'ir_nodes.dart' as ir;
import '../elements/elements.dart';
import '../dart2jslib.dart';
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
 * cached tree to [:null:] and also breaking the token stream to crash future
 * attempts to parse.
 *
 * The type inferrer works on either IR nodes or tree nodes. The IR nodes are
 * then translated into the SSA form for optimizations and code generation.
 * Long-term, once the IR supports the full language, the backend can be
 * re-implemented to work directly on the IR.
 */
class IrBuilderTask extends CompilerTask {
  final Map<Element, ir.Function> nodes = <Element, ir.Function>{};

  IrBuilderTask(Compiler compiler) : super(compiler);

  String get name => 'IR builder';

  bool hasIr(Element element) => nodes.containsKey(element.implementation);

  ir.Function getIr(Element element) => nodes[element.implementation];

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
          ir.Function function;
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
    return const bool.fromEnvironment('enable_ir', defaultValue: false);
  }

  bool canBuild(Element element) {
    // TODO(lry): support lazy initializers.
    FunctionElement function = element.asFunctionElement();
    if (function == null) return false;

    // TODO(lry): support functions with parameters.
    FunctionSignature signature = function.functionSignature;
    if (signature.parameterCount > 0) return false;

    // TODO(kmillikin): support return types.  With the current Dart Tree
    // emitter they require constructing an AST and tokens from a type element.
    if (!signature.type.returnType.isDynamic) return false;

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
class IrBuilder extends ResolvedVisitor<ir.Definition> {
  final SourceFile sourceFile;
  ir.Continuation returnContinuation = null;

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
  // We do not pass and return contexts, rather we use the current context
  // (root, current) as the visitor state and mutate current.  Visiting a
  // statement returns null; visiting an expression optionally returns the
  // definition denoting its value.
  ir.Expression root = null;
  ir.Expression current = null;

  IrBuilder(TreeElements elements, Compiler compiler, this.sourceFile)
      : super(elements, compiler);

  /**
   * Builds the [ir.Function] for a function element. In case the function
   * uses features that cannot be expressed in the IR, this function returns
   * [:null:].
   */
  ir.Function buildFunction(FunctionElement functionElement) {
    return nullIfGiveup(() => buildFunctionInternal(functionElement));
  }

  ir.Function buildFunctionInternal(FunctionElement functionElement) {
    assert(invariant(functionElement, functionElement.isImplementation));
    ast.FunctionExpression function = functionElement.parseNode(compiler);
    assert(function != null);
    assert(!function.modifiers.isExternal());
    assert(elements[function] != null);

    returnContinuation = new ir.Continuation.retrn();
    root = current = null;
    function.body.accept(this);
    ensureReturn(function);
    int endPosition = function.getEndToken().charOffset;
    int namePosition = elements[function].position().charOffset;
    return
        new ir.Function(endPosition, namePosition, returnContinuation, root);
  }

  ConstantSystem get constantSystem => compiler.backend.constantSystem;

  bool get isOpen => root == null || current != null;

  // Plug an expression into the 'hole' in the context being accumulated.  The
  // empty context (just a hole) is represented by root (and current) being
  // null.  Since the hole in the current context is filled by this function,
  // the new hole must be in the newly added expression---which becomes the
  // new value of current.
  void add(ir.Expression expr) {
    if (root == null) {
      root = current = expr;
    } else if (current != null) {
      current = current.plug(expr);
    }
  }

  /**
   * Add an explicit [:return null:] for functions that don't have a return
   * statement on each branch. This includes functions with an empty body,
   * such as [:foo(){ }:].
   */
  void ensureReturn(ast.FunctionExpression node) {
    if (!isOpen) return;
    ir.Constant constant = new ir.Constant(constantSystem.createNull());
    add(new ir.LetPrim(constant));
    add(new ir.InvokeContinuation(returnContinuation, constant));
    current = null;
  }

  ir.Definition visitEmptyStatement(ast.EmptyStatement node) {
    assert(isOpen);
    return null;
  }

  ir.Definition visitBlock(ast.Block node) {
    assert(isOpen);
    for (var n in node.statements.nodes) {
      n.accept(this);
      if (!isOpen) return null;
    }
    return null;
  }

  // Build(Return)    = let val x = null in InvokeContinuation(return, x)
  // Build(Return(e)) = C[InvokeContinuation(return, x)]
  //   where (C, x) = Build(e)
  ir.Definition visitReturn(ast.Return node) {
    assert(isOpen);
    // TODO(lry): support native returns.
    if (node.beginToken.value == 'native') return giveup();
    ir.Definition value;
    if (node.expression == null) {
      value = new ir.Constant(constantSystem.createNull());
      add(new ir.LetPrim(value));
    } else {
      value = node.expression.accept(this);
      if (!isOpen) return null;
    }
    add(new ir.InvokeContinuation(returnContinuation, value));
    current = null;
    return null;
  }

  // For all simple literals:
  // Build(Literal(c)) = (let val x = Constant(c) in [], x)
  ir.Definition visitLiteralBool(ast.LiteralBool node) {
    assert(isOpen);
    ir.Constant constant =
        new ir.Constant(constantSystem.createBool(node.value));
    add(new ir.LetPrim(constant));
    return constant;
  }

  ir.Definition visitLiteralDouble(ast.LiteralDouble node) {
    assert(isOpen);
    ir.Constant constant =
        new ir.Constant(constantSystem.createDouble(node.value));
    add(new ir.LetPrim(constant));
    return constant;
  }

  ir.Definition visitLiteralInt(ast.LiteralInt node) {
    assert(isOpen);
    ir.Constant constant =
        new ir.Constant(constantSystem.createInt(node.value));
    add(new ir.LetPrim(constant));
    return constant;
  }


  ir.Definition visitLiteralNull(ast.LiteralNull node) {
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

  ir.Definition visitAssert(ast.Send node) {
    return giveup();
  }

  ir.Definition visitClosureSend(ast.Send node) {
    return giveup();
  }

  ir.Definition visitDynamicSend(ast.Send node) {
    return giveup();
  }

  ir.Definition visitGetterSend(ast.Send node) {
    return giveup();
  }

  ir.Definition visitOperatorSend(ast.Send node) {
    return giveup();
  }

  // Build(StaticSend(f, a...)) = C[InvokeStatic(f, x...)]
  //   where (C, x...) = BuildList(a...)
  ir.Definition visitStaticSend(ast.Send node) {
    assert(isOpen);
    Element element = elements[node];
    // TODO(lry): support static fields. (separate IR instruction?)
    if (element.isField() || element.isGetter()) return giveup();
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
        node.arguments, arguments, element.implementation,
        // Guard against visiting arguments after an argument expression throws.
        (node) => isOpen ? node.accept(this) : null,
        (node) => giveup(),
        compiler);
    if (!succeeded) {
      // TODO(lry): generate code to throw a [WrongArgumentCountError].
      return giveup();
    }
    if (!isOpen) return null;
    ir.Parameter v = new ir.Parameter();
    ir.Continuation k = new ir.Continuation(v);
    ir.Expression invoke =
        new ir.InvokeStatic(element, selector, k, arguments);
    add(new ir.LetCont(k, invoke));
    return v;
  }

  ir.Definition visitSuperSend(ast.Send node) {
    return giveup();
  }

  ir.Definition visitTypeReferenceSend(ast.Send node) {
    return giveup();
  }

  static final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

  ir.Definition giveup() => throw ABORT_IRNODE_BUILDER;

  ir.Function nullIfGiveup(ir.Function action()) {
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
