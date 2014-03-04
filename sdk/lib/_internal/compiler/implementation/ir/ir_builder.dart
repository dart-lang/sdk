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
import '../js_backend/js_backend.dart' show JavaScriptBackend;
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
  final Map<Element, ir.Node> nodes = new Map<Element, ir.Node>();

  IrBuilderTask(Compiler compiler) : super(compiler);

  String get name => 'IR builder';

  bool hasIr(Element element) => nodes.containsKey(element.implementation);

  ir.Node getIr(Element element) => nodes[element.implementation];

  void buildNodes() {
    if (!irEnabled()) return;
    measure(() {
      Map<Element, TreeElements> resolved =
          compiler.enqueuer.resolution.resolvedElements;
      resolved.forEach((Element element, TreeElements elementsMapping) {
        if (canBuild(element)) {
          element = element.implementation;

          SourceFile sourceFile = elementSourceFile(element);
          IrNodeBuilderVisitor visitor =
              new IrNodeBuilderVisitor(elementsMapping, compiler, sourceFile);
          ir.Node irNode;
          ElementKind kind = element.kind;
          if (kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
            // TODO(lry): build ir for constructors.
          } else if (kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY ||
              kind == ElementKind.FUNCTION ||
              kind == ElementKind.GETTER ||
              kind == ElementKind.SETTER) {
            irNode = visitor.buildMethod(element);
          } else if (kind == ElementKind.FIELD) {
            // TODO(lry): build ir for lazy initializers of static fields.
          } else {
            compiler.internalErrorOnElement(element,
                'unexpected element kind $kind');
          }

          if (irNode != null) {
            assert(() {
              // In host-checked mode, serialize and de-serialize the IrNode.
              LibraryElement library = element.declaration.getLibrary();
              IrConstantPool constantPool = IrConstantPool.forLibrary(library);
              List<int> data = irNode.pickle(constantPool);
              irNode = new Unpickler(compiler, constantPool).unpickle(data);
              return true;
            });
            nodes[element] = irNode;
          }
        }
        ensureIr(element);
      });
    });
  }

  bool irEnabled() {
    // TODO(lry): support checked-mode checks.
    if (compiler.enableTypeAssertions ||
        compiler.backend is !JavaScriptBackend ||
        compiler.enableConcreteTypeInference) {
      return false;
    }
    return const bool.fromEnvironment('enable_ir', defaultValue: true);
  }

  bool canBuild(Element element) {
    // TODO(lry): support lazy initializers.
    FunctionElement function = element.asFunctionElement();
    if (function == null) return false;

    // TODO(lry): support functions with parameters.
    FunctionSignature signature = function.computeSignature(compiler);
    if (signature.parameterCount > 0) return false;

    // TODO(lry): support intercepted methods. Then the dependency on
    // JavaScriptBackend will go away.
    JavaScriptBackend backend = compiler.backend;
    if (backend.isInterceptedMethod(element)) return false;

    // TODO(lry): support native functions (also in [visitReturn]).
    if (function.isNative()) return false;

    // Methods annotated @IrRepresentation(false).
    if (enforceAstRepresentation(function)) return false;

    return true;
  }

  bool get inCheckedMode {
    bool result = false;
    assert((result = true));
    return result;
  }

  bool enforceAstRepresentation(Element element) {
    return irRepresentationValue(element, false);
  }

  bool enforceIrRepresentation(Element element) {
    return irRepresentationValue(element, true);
  }

  /**
   * In host-checked mode, the @IrRepresentation annotation can be used to
   * enforce the internal representation of a function.
   */
  bool irRepresentationValue(Element element, bool expected) {
    if (!inCheckedMode || compiler.backend is !JavaScriptBackend) return false;
    JavaScriptBackend backend = compiler.backend;
    for (MetadataAnnotation metadata in element.metadata) {
      if (metadata.value == null ||
          !metadata.value.isConstructedObject()) {
        continue;
      }
      ObjectConstant value = metadata.value;
      ClassElement cls = value.type.element;
      if (cls == backend.irRepresentationClass) {
        ConstructedConstant classConstant = value;
        BoolConstant constant = classConstant.fields[0];
        return constant.value == expected;
      }
    }
    return false;
  }

  void ensureIr(Element element) {
    // If no IR was built for [element], ensure it is not annotated
    // @IrRepresentation(true).
    if (inCheckedMode &&
        !compiler.irBuilder.hasIr(element) &&
        enforceIrRepresentation(element)) {
      compiler.reportFatalError(
          element,
          MessageKind.GENERIC,
          {'text': "Error: cannot build IR for $element."});
    }
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
class IrNodeBuilderVisitor extends ResolvedVisitor<ir.Node> {
  final SourceFile sourceFile;

  IrNodeBuilderVisitor(
      TreeElements elements,
      Compiler compiler,
      this.sourceFile)
    : super(elements, compiler);

  IrBuilder builder;

  /**
   * Builds the [ir.Function] for a function element. In case the function
   * uses features that cannot be expressed in the IR, this function returns
   * [:null:].
   */
  ir.Function buildMethod(FunctionElement functionElement) {
    return nullIfGiveup(() => buildMethodInternal(functionElement));
  }

  ir.Function buildMethodInternal(FunctionElement functionElement) {
    assert(invariant(functionElement, functionElement.isImplementation));
    ast.FunctionExpression function = functionElement.parseNode(compiler);
    assert(function != null);
    assert(!function.modifiers.isExternal());
    assert(elements[function] != null);

    int endPosition = function.getEndToken().charOffset;
    int namePosition = elements[function].position().charOffset;
    ir.Function result = new ir.Function(
        nodePosition(function), endPosition, namePosition, <ir.Node>[]);
    builder = new IrBuilder(this);
    builder.enterBlock();
    if (function.hasBody()) {
      function.body.accept(this);
      ensureReturn(function);
      result.statements
        ..addAll(builder.constants.values)
        ..addAll(builder.block.statements);
    }
    builder.exitBlock();
    return result;
  }

  ConstantSystem get constantSystem => compiler.backend.constantSystem;

  /* int | PositionWithIdentifierName */ nodePosition(ast.Node node) {
    Token token = node.getBeginToken();
    if (token.isIdentifier()) {
      return new ir.PositionWithIdentifierName(token.charOffset, token.value);
    } else {
      return token.charOffset;
    }
  }

  bool get blockReturns => builder.block.hasReturn;

  /**
   * Add an explicit [:return null:] for functions that don't have a return
   * statement on each branch. This includes functions with an empty body,
   * such as [:foo(){ }:].
   */
  void ensureReturn(ast.FunctionExpression node) {
    if (blockReturns) return;
    ir.Constant nullValue =
        builder.addConstant(constantSystem.createNull(), node);
    builder.addStatement(new ir.Return(nodePosition(node), nullValue));
  }

  ir.Node visitBlock(ast.Block node) {
    for (ast.Node n in node.statements.nodes) {
      n.accept(this);
      if (blockReturns) return null;
    }
    return null;
  }

  ir.Node visitReturn(ast.Return node) {
    assert(!blockReturns);
    ir.Expression value;
    // TODO(lry): support native returns.
    if (node.beginToken.value == 'native') giveup();
    if (node.expression == null) {
      value = builder.addConstant(constantSystem.createNull(), node);
    } else {
      value = node.expression.accept(this);
    }
    builder.addStatement(new ir.Return(nodePosition(node), value));
    builder.block.hasReturn = true;
    return null;
  }

  ir.Constant visitLiteralBool(ast.LiteralBool node) {
    return builder.addConstant(constantSystem.createBool(node.value), node);
  }

  ir.Constant visitLiteralDouble(ast.LiteralDouble node) {
    return builder.addConstant(constantSystem.createDouble(node.value), node);
  }

  ir.Constant visitLiteralInt(ast.LiteralInt node) {
    return builder.addConstant(constantSystem.createInt(node.value), node);
  }

  ir.Constant visitLiteralString(ast.LiteralString node) {
    Constant value = constantSystem.createString(node.dartString);
    return builder.addConstant(value, node);
  }

  ir.Constant visitLiteralNull(ast.LiteralNull node) {
    return builder.addConstant(constantSystem.createNull(), node);
  }

//  TODO(lry): other literals.
//  IrNode visitLiteralList(LiteralList node) => visitExpression(node);
//  IrNode visitLiteralMap(LiteralMap node) => visitExpression(node);
//  IrNode visitLiteralMapEntry(LiteralMapEntry node) => visitNode(node);
//  IrNode visitLiteralSymbol(LiteralSymbol node) => visitExpression(node);

  ir.Node visitAssert(ast.Send node) {
    giveup();
    return null;
  }

  ir.Node visitClosureSend(ast.Send node) {
    giveup();
    return null;
  }

  ir.Node visitDynamicSend(ast.Send node) {
    giveup();
    return null;
  }

  ir.Node visitGetterSend(ast.Send node) {
    giveup();
    return null;
  }

  ir.Node visitOperatorSend(ast.Send node) {
    giveup();
    return null;
  }

  ir.Node visitStaticSend(ast.Send node) {
    Selector selector = elements.getSelector(node);
    Element element = elements[node];

    // TODO(lry): support static fields. (separate IR instruction?)
    if (element.isField() || element.isGetter()) giveup();
    // TODO(lry): support constructors / factory calls.
    if (element.isConstructor()) giveup();
    // TODO(lry): support foreign functions.
    if (element.isForeign(compiler)) giveup();
    // TODO(lry): for elements that could not be resolved emit code to throw a
    // [NoSuchMethodError].
    if (element.isErroneous()) giveup();
    // TODO(lry): support named arguments
    if (selector.namedArgumentCount != 0) giveup();

    List<ir.Expression> arguments = <ir.Expression>[];
    // TODO(lry): support default arguments, need support for locals.
    bool succeeded = selector.addArgumentsToList(
        node.arguments, arguments, element.implementation,
        (node) => node.accept(this), (node) => giveup(), compiler);
    if (!succeeded) {
      // TODO(lry): generate code to throw a [WrongArgumentCountError].
      giveup();
    }
    // TODO(lry): generate IR for object identicality.
    if (element == compiler.identicalFunction) giveup();
    ir.InvokeStatic result = builder.addStatement(
        new ir.InvokeStatic(nodePosition(node), element, selector, arguments));
    return result;
  }

  ir.Node visitSuperSend(ast.Send node) {
    giveup();
    return null;
  }

  ir.Node visitTypeReferenceSend(ast.Send node) {
    giveup();
    return null;
  }

  static final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

  ir.Node giveup() => throw ABORT_IRNODE_BUILDER;

  ir.Node nullIfGiveup(ir.Node action()) {
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

class IrBuilder {
  final IrNodeBuilderVisitor visitor;
  IrBuilder(this.visitor);

  List<BlockBuilder> blockBuilders = <BlockBuilder>[];

  BlockBuilder get block => blockBuilders.last;

  Map<Constant, ir.Constant> constants = <Constant, ir.Constant>{};

  ir.Constant addConstant(Constant value, ast.Node node) {
    return constants.putIfAbsent(
      value, () => new ir.Constant(visitor.nodePosition(node), value));
  }

  ir.Node addStatement(ir.Node statement) {
    block.statements.add(statement);
    return statement;
  }

  void enterBlock() {
    blockBuilders.add(new BlockBuilder());
  }

  void exitBlock() {
    blockBuilders.removeLast();
  }
}

class BlockBuilder {
  List<ir.Node> statements = <ir.Node>[];
  bool hasReturn = false;
}
