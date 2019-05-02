// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library implements a kernel2kernel constant evaluation transformation.
///
/// Even though it is expected that the frontend does not emit kernel AST which
/// contains compile-time errors, this transformation still performs some
/// valiation and throws a [ConstantEvaluationError] if there was a compile-time
/// errors.
///
/// Due to the lack information which is is only available in the front-end,
/// this validation is incomplete (e.g. whether an integer literal used the
/// hexadecimal syntax or not).
///
/// Furthermore due to the lowering of certain constructs in the front-end
/// (e.g. '??') we need to support a super-set of the normal constant expression
/// language.  Issue(http://dartbug.com/31799)
library fasta.constant_evaluator;

import 'dart:core' hide MapEntry;

import 'dart:io' as io;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import 'package:kernel/target/targets.dart';

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageConstEvalCircularity,
        messageConstEvalContext,
        messageConstEvalFailedAssertion,
        messageConstEvalIterationInConstList,
        messageConstEvalIterationInConstSet,
        messageConstEvalIterationInConstMap,
        messageConstEvalNotListOrSetInSpread,
        messageConstEvalNotMapInSpread,
        messageConstEvalNullValue,
        messageConstEvalUnevaluated,
        noLength,
        templateConstEvalDeferredLibrary,
        templateConstEvalDuplicateElement,
        templateConstEvalDuplicateKey,
        templateConstEvalElementImplementsEqual,
        templateConstEvalFailedAssertionWithMessage,
        templateConstEvalFreeTypeParameter,
        templateConstEvalInvalidType,
        templateConstEvalInvalidBinaryOperandType,
        templateConstEvalInvalidEqualsOperandType,
        templateConstEvalInvalidMethodInvocation,
        templateConstEvalInvalidPropertyGet,
        templateConstEvalInvalidStaticInvocation,
        templateConstEvalInvalidStringInterpolationOperand,
        templateConstEvalInvalidSymbolName,
        templateConstEvalKeyImplementsEqual,
        templateConstEvalNegativeShift,
        templateConstEvalNonConstantLiteral,
        templateConstEvalNonConstantVariableGet,
        templateConstEvalZeroDivisor;

import 'collections.dart'
    show
        ForElement,
        ForInElement,
        IfElement,
        SpreadElement,
        ForMapEntry,
        ForInMapEntry,
        IfMapEntry,
        SpreadMapEntry;

Component transformComponent(Component component, ConstantsBackend backend,
    Map<String, String> environmentDefines, ErrorReporter errorReporter,
    {bool keepFields: true,
    bool enableAsserts: false,
    bool evaluateAnnotations: true,
    bool desugarSets: false,
    bool errorOnUnevaluatedConstant: false,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy}) {
  coreTypes ??= new CoreTypes(component);
  hierarchy ??= new ClassHierarchy(component);

  final typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);

  transformLibraries(component.libraries, backend, environmentDefines,
      typeEnvironment, errorReporter,
      keepFields: keepFields,
      enableAsserts: enableAsserts,
      desugarSets: desugarSets,
      errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
      evaluateAnnotations: evaluateAnnotations);
  return component;
}

void transformLibraries(
    List<Library> libraries,
    ConstantsBackend backend,
    Map<String, String> environmentDefines,
    TypeEnvironment typeEnvironment,
    ErrorReporter errorReporter,
    {bool keepFields: true,
    bool keepVariables: false,
    bool evaluateAnnotations: true,
    bool desugarSets: false,
    bool errorOnUnevaluatedConstant: false,
    bool enableAsserts: false}) {
  final ConstantsTransformer constantsTransformer = new ConstantsTransformer(
      backend,
      environmentDefines,
      keepFields,
      keepVariables,
      evaluateAnnotations,
      desugarSets,
      errorOnUnevaluatedConstant,
      typeEnvironment,
      enableAsserts,
      errorReporter);
  for (final Library library in libraries) {
    constantsTransformer.convertLibrary(library);
  }
}

class JavaScriptIntConstant extends DoubleConstant {
  final BigInt bigIntValue;
  JavaScriptIntConstant(int value) : this.fromBigInt(BigInt.from(value));
  JavaScriptIntConstant.fromDouble(double value)
      : bigIntValue = BigInt.from(value),
        super(value);
  JavaScriptIntConstant.fromBigInt(this.bigIntValue)
      : super(bigIntValue.toDouble());
  JavaScriptIntConstant.fromUInt64(int value)
      : this.fromBigInt(BigInt.from(value).toUnsigned(64));

  DartType getType(TypeEnvironment types) => types.intType;

  String toString() => '$bigIntValue';
}

class ConstantsTransformer extends Transformer {
  final ConstantEvaluator constantEvaluator;
  final TypeEnvironment typeEnvironment;

  /// Whether to preserve constant [Field]s.  All use-sites will be rewritten.
  final bool keepFields;
  final bool keepVariables;
  final bool evaluateAnnotations;
  final bool desugarSets;
  final bool errorOnUnevaluatedConstant;

  ConstantsTransformer(
      ConstantsBackend backend,
      Map<String, String> environmentDefines,
      this.keepFields,
      this.keepVariables,
      this.evaluateAnnotations,
      this.desugarSets,
      this.errorOnUnevaluatedConstant,
      this.typeEnvironment,
      bool enableAsserts,
      ErrorReporter errorReporter)
      : constantEvaluator = new ConstantEvaluator(backend, environmentDefines,
            typeEnvironment, enableAsserts, errorReporter,
            desugarSets: desugarSets,
            errorOnUnevaluatedConstant: errorOnUnevaluatedConstant);

  // Transform the library/class members:

  void convertLibrary(Library library) {
    transformAnnotations(library.annotations, library);

    transformList(library.dependencies, this, library);
    transformList(library.parts, this, library);
    transformList(library.typedefs, this, library);
    transformList(library.classes, this, library);
    transformList(library.procedures, this, library);
    transformList(library.fields, this, library);

    if (!keepFields) {
      // The transformer API does not iterate over `Library.additionalExports`,
      // so we manually delete the references to shaken nodes.
      library.additionalExports.removeWhere((Reference reference) {
        return reference.node is Field && reference.canonicalName == null;
      });
    }
  }

  visitLibraryPart(LibraryPart node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  visitLibraryDependency(LibraryDependency node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  visitClass(Class node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.fields, this, node);
      transformList(node.typeParameters, this, node);
      transformList(node.constructors, this, node);
      transformList(node.procedures, this, node);
      transformList(node.redirectingFactoryConstructors, this, node);
    });
    return node;
  }

  visitProcedure(Procedure node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      node.function = node.function.accept(this)..parent = node;
    });
    return node;
  }

  visitConstructor(Constructor node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.initializers, this, node);
      node.function = node.function.accept(this)..parent = node;
    });
    return node;
  }

  visitTypedef(Typedef node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.typeParameters, this, node);
      transformList(node.typeParametersOfFunctionType, this, node);
      transformList(node.positionalParameters, this, node);
      transformList(node.namedParameters, this, node);
    });
    return node;
  }

  visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.typeParameters, this, node);
      transformList(node.positionalParameters, this, node);
      transformList(node.namedParameters, this, node);
    });
    return node;
  }

  visitTypeParameter(TypeParameter node) {
    transformAnnotations(node.annotations, node);
    return node;
  }

  void transformAnnotations(List<Expression> nodes, TreeNode parent) {
    if (evaluateAnnotations && nodes.length > 0) {
      transformExpressions(nodes, parent);
    }
  }

  void transformExpressions(List<Expression> nodes, TreeNode parent) {
    constantEvaluator.withNewEnvironment(() {
      for (int i = 0; i < nodes.length; ++i) {
        nodes[i] = evaluateAndTransformWithContext(parent, nodes[i])
          ..parent = parent;
      }
    });
  }

  // Handle definition of constants:

  visitFunctionNode(FunctionNode node) {
    final positionalParameterCount = node.positionalParameters.length;
    for (int i = 0; i < positionalParameterCount; ++i) {
      final VariableDeclaration variable = node.positionalParameters[i];
      transformAnnotations(variable.annotations, variable);
      if (variable.initializer != null) {
        variable.initializer =
            evaluateAndTransformWithContext(variable, variable.initializer)
              ..parent = variable;
      }
    }
    for (final VariableDeclaration variable in node.namedParameters) {
      transformAnnotations(variable.annotations, variable);
      if (variable.initializer != null) {
        variable.initializer =
            evaluateAndTransformWithContext(variable, variable.initializer)
              ..parent = variable;
      }
    }
    if (node.body != null) {
      node.body = node.body.accept(this)..parent = node;
    }
    return node;
  }

  visitVariableDeclaration(VariableDeclaration node) {
    transformAnnotations(node.annotations, node);

    if (node.initializer != null) {
      if (node.isConst) {
        final Constant constant = evaluateWithContext(node, node.initializer);
        constantEvaluator.env.addVariableValue(node, constant);

        if (keepVariables) {
          // So the value of the variable is still available for debugging
          // purposes we convert the constant variable to be a final variable
          // initialized to the evaluated constant expression.
          node.initializer = makeConstantExpression(constant, node.initializer)
            ..parent = node;
          node.isFinal = true;
          node.isConst = false;
        } else {
          // Since we convert all use-sites of constants, the constant
          // [VariableDeclaration] is unused and we'll therefore remove it.
          return null;
        }
      } else {
        node.initializer = node.initializer.accept(this)..parent = node;
      }
    }
    return node;
  }

  visitField(Field node) {
    return constantEvaluator.withNewEnvironment(() {
      if (node.isConst) {
        // Since we convert all use-sites of constants, the constant [Field]
        // cannot be referenced anymore.  We therefore get rid of it if
        // [keepFields] was not specified.
        if (!keepFields) {
          return null;
        }

        // Otherwise we keep the constant [Field] and convert it's initializer.
        transformAnnotations(node.annotations, node);
        if (node.initializer != null) {
          node.initializer =
              evaluateAndTransformWithContext(node, node.initializer)
                ..parent = node;
        }
      } else {
        transformAnnotations(node.annotations, node);
        if (node.initializer != null) {
          node.initializer = node.initializer.accept(this)..parent = node;
        }
      }
      return node;
    });
  }

  // Handle use-sites of constants (and "inline" constant expressions):

  visitSymbolLiteral(SymbolLiteral node) {
    return makeConstantExpression(constantEvaluator.evaluate(node), node);
  }

  visitStaticGet(StaticGet node) {
    final Member target = node.target;
    if (target is Field && target.isConst) {
      return evaluateAndTransformWithContext(node, node);
    } else if (target is Procedure && target.kind == ProcedureKind.Method) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitStaticGet(node);
  }

  visitSwitchCase(SwitchCase node) {
    transformExpressions(node.expressions, node);
    return super.visitSwitchCase(node);
  }

  visitVariableGet(VariableGet node) {
    if (node.variable.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitVariableGet(node);
  }

  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitListLiteral(node);
  }

  visitSetLiteral(SetLiteral node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitSetLiteral(node);
  }

  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitMapLiteral(node);
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitConstructorInvocation(node);
  }

  visitStaticInvocation(StaticInvocation node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitStaticInvocation(node);
  }

  visitConstantExpression(ConstantExpression node) {
    Constant constant = node.constant;
    if (constant is UnevaluatedConstant) {
      Expression expression = constant.expression;
      return evaluateAndTransformWithContext(expression, expression);
    } else {
      node.constant = constantEvaluator.canonicalize(constant);
      return node;
    }
  }

  evaluateAndTransformWithContext(TreeNode treeContext, Expression node) {
    return makeConstantExpression(evaluateWithContext(treeContext, node), node);
  }

  evaluateWithContext(TreeNode treeContext, Expression node) {
    if (treeContext == node) {
      return constantEvaluator.evaluate(node);
    }

    return constantEvaluator.runInsideContext(treeContext, () {
      return constantEvaluator.evaluate(node);
    });
  }

  Expression makeConstantExpression(Constant constant, Expression node) {
    if (constant is UnevaluatedConstant &&
        constant.expression is InvalidExpression) {
      return constant.expression;
    }
    return new ConstantExpression(constant, node.getStaticType(typeEnvironment))
      ..fileOffset = node.fileOffset;
  }
}

class ConstantEvaluator extends RecursiveVisitor<Constant> {
  final ConstantsBackend backend;
  final NumberSemantics numberSemantics;
  Map<String, String> environmentDefines;
  final bool errorOnUnevaluatedConstant;
  final CoreTypes coreTypes;
  final TypeEnvironment typeEnvironment;
  final bool enableAsserts;
  final ErrorReporter errorReporter;

  final bool desugarSets;
  final Field unmodifiableSetMap;

  final isInstantiated = new IsInstantiatedVisitor().isInstantiated;

  final Map<Constant, Constant> canonicalizationCache;
  final Map<Node, Object> nodeCache;
  final CloneVisitor cloner = new CloneVisitor();

  Map<Class, bool> primitiveEqualCache;

  final NullConstant nullConstant = new NullConstant();
  final BoolConstant trueConstant = new BoolConstant(true);
  final BoolConstant falseConstant = new BoolConstant(false);

  final List<TreeNode> contextChain = [];

  InstanceBuilder instanceBuilder;
  EvaluationEnvironment env;
  Set<Expression> replacementNodes = new Set<Expression>.identity();
  Map<Constant, Constant> lowered = new Map<Constant, Constant>.identity();

  bool seenUnevaluatedChild; // Any children that were left unevaluated?
  int lazyDepth; // Current nesting depth of lazy regions.

  bool get shouldBeUnevaluated => seenUnevaluatedChild || lazyDepth != 0;

  bool get targetingJavaScript => numberSemantics == NumberSemantics.js;

  ConstantEvaluator(this.backend, this.environmentDefines, this.typeEnvironment,
      this.enableAsserts, this.errorReporter,
      {this.desugarSets = false, this.errorOnUnevaluatedConstant = false})
      : numberSemantics = backend.numberSemantics,
        coreTypes = typeEnvironment.coreTypes,
        canonicalizationCache = <Constant, Constant>{},
        nodeCache = <Node, Constant>{},
        env = new EvaluationEnvironment(),
        unmodifiableSetMap = desugarSets
            ? typeEnvironment.coreTypes.index
                .getMember('dart:collection', '_UnmodifiableSet', '_map')
            : null {
    primitiveEqualCache = <Class, bool>{
      coreTypes.boolClass: true,
      coreTypes.doubleClass: false,
      coreTypes.intClass: true,
      coreTypes.internalSymbolClass: true,
      coreTypes.listClass: true,
      coreTypes.mapClass: true,
      coreTypes.nullClass: true,
      coreTypes.objectClass: true,
      coreTypes.setClass: true,
      coreTypes.stringClass: true,
      coreTypes.symbolClass: true,
      coreTypes.typeClass: true,
    };
  }

  Uri getFileUri(TreeNode node) {
    while (node != null && node is! FileUriNode) {
      node = node.parent;
    }
    return (node as FileUriNode)?.fileUri;
  }

  int getFileOffset(Uri uri, TreeNode node) {
    if (uri == null) return TreeNode.noOffset;
    while (node != null && node.fileOffset == TreeNode.noOffset) {
      node = node.parent;
    }
    return node == null ? TreeNode.noOffset : node.fileOffset;
  }

  /// Evaluate [node] and possibly cache the evaluation result.
  /// Returns UnevaluatedConstant if the constant could not be evaluated.
  /// If the expression in the UnevaluatedConstant is an InvalidExpression,
  /// an error occurred during constant evaluation.
  Constant evaluate(Expression node) {
    seenUnevaluatedChild = false;
    lazyDepth = 0;
    try {
      Constant result = _evaluateSubexpression(node);
      if (errorOnUnevaluatedConstant && result is UnevaluatedConstant) {
        return report(node, messageConstEvalUnevaluated);
      }
      return result;
    } on _AbortDueToError catch (e) {
      final Uri uri = getFileUri(e.node);
      final int fileOffset = getFileOffset(uri, e.node);
      final locatedMessage = e.message.withLocation(uri, fileOffset, noLength);

      final contextMessages = <LocatedMessage>[];
      if (e.context != null) contextMessages.addAll(e.context);
      for (final TreeNode node in contextChain) {
        final Uri uri = getFileUri(node);
        final int fileOffset = getFileOffset(uri, node);
        contextMessages.add(
            messageConstEvalContext.withLocation(uri, fileOffset, noLength));
      }
      errorReporter.report(locatedMessage, contextMessages);
      return new UnevaluatedConstant(new InvalidExpression(e.message.message));
    } on _AbortDueToInvalidExpression catch (e) {
      // TODO(askesc): Copy position from erroneous node.
      // Currently not possible, as it might be in a different file.
      // Can be done if we add an explicit URI to InvalidExpression.
      InvalidExpression invalid = new InvalidExpression(e.message);
      if (invalid.fileOffset == TreeNode.noOffset) {
        invalid.fileOffset = node.fileOffset;
      }
      errorReporter.reportInvalidExpression(invalid);
      return new UnevaluatedConstant(invalid);
    }
  }

  /// Report an error that has been detected during constant evaluation.
  Null report(TreeNode node, Message message, {List<LocatedMessage> context}) {
    throw new _AbortDueToError(node, message, context: context);
  }

  /// Report a construct that should not occur inside a potentially constant
  /// expression. It is assumed that an error has already been reported.
  Null reportInvalid(TreeNode node, String message) {
    throw new _AbortDueToInvalidExpression(node, message);
  }

  /// Produce an unevaluated constant node for an expression.
  Constant unevaluated(Expression original, Expression replacement) {
    replacement.fileOffset = original.fileOffset;
    // TODO(askesc,johnniwinther): Preserve fileUri on [replacement].
    return new UnevaluatedConstant(replacement);
  }

  /// Extract an expression from a (possibly unevaluated) constant to become
  /// part of the expression tree of another unevaluated constant.
  /// Makes sure a particular expression occurs only once in the tree by
  /// cloning further instances.
  Expression extract(Constant constant) {
    Expression expression = constant.asExpression();
    if (!replacementNodes.add(expression)) {
      expression = cloner.clone(expression);
      replacementNodes.add(expression);
    }
    return expression;
  }

  /// Enter a region of lazy evaluation. All leaf nodes are evaluated normally
  /// (to ensure inlining of referenced local variables), but composite nodes
  /// always treat their children as unevaluated, resulting in a partially
  /// evaluated clone of the original expression tree.
  /// Lazy evaluation is used for the subtrees of lazy operations with
  /// unevaluated conditions to ensure no errors are reported for problems
  /// in the subtree as long as the subtree is potentially constant.
  void enterLazy() => lazyDepth++;

  /// Leave a (possibly nested) region of lazy evaluation.
  void leaveLazy() => lazyDepth--;

  Constant lower(Constant original, Constant replacement) {
    if (!identical(original, replacement)) {
      original = canonicalize(original);
      replacement = canonicalize(replacement);
      lowered[replacement] = original;
      return replacement;
    }
    return canonicalize(replacement);
  }

  Constant unlower(Constant constant) {
    return lowered[constant] ?? constant;
  }

  Constant lowerListConstant(ListConstant constant) {
    if (shouldBeUnevaluated) return constant;
    return lower(constant, backend.lowerListConstant(constant));
  }

  Constant lowerSetConstant(SetConstant constant) {
    if (shouldBeUnevaluated) return constant;
    return lower(constant, backend.lowerSetConstant(constant));
  }

  Constant lowerMapConstant(MapConstant constant) {
    if (shouldBeUnevaluated) return constant;
    return lower(constant, backend.lowerMapConstant(constant));
  }

  /// Evaluate [node] and possibly cache the evaluation result.
  /// @throws _AbortDueToError or _AbortDueToInvalidExpression if expression
  /// can't be evaluated.
  Constant _evaluateSubexpression(Expression node) {
    if (node == null) return nullConstant;
    bool wasUnevaluated = seenUnevaluatedChild;
    seenUnevaluatedChild = false;
    Constant result;
    if (env.isEmpty) {
      // We only try to evaluate the same [node] *once* within an empty
      // environment.
      if (nodeCache.containsKey(node)) {
        result = nodeCache[node] ?? report(node, messageConstEvalCircularity);
      } else {
        nodeCache[node] = null;
        try {
          result = nodeCache[node] = node.accept(this);
        } catch (e) {
          nodeCache.remove(node);
          rethrow;
        }
      }
    } else {
      result = node.accept(this);
    }
    seenUnevaluatedChild = wasUnevaluated || result is UnevaluatedConstant;
    return result;
  }

  Constant runInsideContext(TreeNode node, Constant fun()) {
    try {
      pushContext(node);
      return fun();
    } finally {
      popContext(node);
    }
  }

  Constant runInsideContextIfNoContext(TreeNode node, Constant fun()) {
    if (contextChain.isEmpty) {
      return runInsideContext(node, fun);
    } else {
      return fun();
    }
  }

  pushContext(TreeNode contextNode) {
    contextChain.add(contextNode);
  }

  popContext(TreeNode contextNode) {
    assert(contextChain.last == contextNode);
    contextChain.length = contextChain.length - 1;
  }

  defaultTreeNode(Node node) {
    // Only a subset of the expression language is valid for constant
    // evaluation.
    return reportInvalid(
        node, 'Constant evaluation has no support for ${node.runtimeType}!');
  }

  visitNullLiteral(NullLiteral node) => nullConstant;

  visitBoolLiteral(BoolLiteral node) {
    return makeBoolConstant(node.value);
  }

  visitIntLiteral(IntLiteral node) {
    // The frontend ensures that integer literals are valid according to the
    // target representation.
    return targetingJavaScript
        ? canonicalize(new JavaScriptIntConstant.fromUInt64(node.value))
        : canonicalize(new IntConstant(node.value));
  }

  visitDoubleLiteral(DoubleLiteral node) {
    return canonicalize(makeDoubleConstant(node.value));
  }

  visitStringLiteral(StringLiteral node) {
    return canonicalize(new StringConstant(node.value));
  }

  visitTypeLiteral(TypeLiteral node) {
    final DartType type = evaluateDartType(node, node.type);
    return canonicalize(new TypeLiteralConstant(type));
  }

  visitConstantExpression(ConstantExpression node) {
    Constant constant = node.constant;
    Constant result = constant;
    if (constant is UnevaluatedConstant) {
      result = runInsideContext(constant.expression, () {
        return _evaluateSubexpression(constant.expression);
      });
    } else if (targetingJavaScript) {
      if (constant is DoubleConstant) {
        double value = constant.value;
        // TODO(askesc, fishythefish): Handle infinite integers.
        if (value.isFinite && value.truncateToDouble() == value) {
          result = new JavaScriptIntConstant.fromDouble(value);
        }
      }
    }
    // If there were already constants in the AST then we make sure we
    // re-canonicalize them.  After running the transformer we will therefore
    // have a fully-canonicalized constant DAG with roots coming from the
    // [ConstantExpression] nodes in the AST.
    return canonicalize(result);
  }

  /// Add an element (which is possibly a spread or an if element) to a
  /// constant list or set represented as a list of (possibly unevaluated)
  /// lists or sets to be concatenated.
  /// Each element of [parts] is either a `List<Constant>` (containing fully
  /// evaluated constants) or a `Constant` (potentially unevaluated).
  /// Pass an identity set as [seen] for sets and omit it for lists.
  void addToListOrSetConstant(
      List<Object> parts, Expression element, DartType elementType,
      [Set<Constant> seen]) {
    bool isSet = seen != null;
    if (element is SpreadElement) {
      Constant spread = unlower(_evaluateSubexpression(element.expression));
      if (shouldBeUnevaluated) {
        // Unevaluated spread
        if (element.isNullAware) {
          VariableDeclaration temp =
              new VariableDeclaration(null, initializer: extract(spread));
          parts.add(unevaluated(
              element.expression,
              new Let(
                  temp,
                  new ConditionalExpression(
                      new MethodInvocation(new VariableGet(temp),
                          new Name('=='), new Arguments([new NullLiteral()])),
                      new ListLiteral([], isConst: true),
                      new VariableGet(temp),
                      const DynamicType()))));
        } else {
          parts.add(spread);
        }
      } else if (spread == nullConstant) {
        // Null spread
        if (!element.isNullAware) {
          report(element.expression, messageConstEvalNullValue);
        }
      } else {
        // Fully evaluated spread
        List<Constant> entries;
        if (spread is ListConstant) {
          entries = spread.entries;
        } else if (spread is SetConstant) {
          entries = spread.entries;
        } else {
          // Not list or set in spread
          return report(
              element.expression, messageConstEvalNotListOrSetInSpread);
        }
        for (Constant entry in entries) {
          addToListOrSetConstant(
              parts, new ConstantExpression(entry), elementType, seen);
        }
      }
    } else if (element is IfElement) {
      Constant condition = _evaluateSubexpression(element.condition);
      if (shouldBeUnevaluated) {
        // Unevaluated if
        enterLazy();
        Constant then = _evaluateSubexpression(isSet
            ? new SetLiteral([cloner.clone(element.then)], isConst: true)
            : new ListLiteral([cloner.clone(element.then)], isConst: true));
        Constant otherwise;
        if (element.otherwise != null) {
          otherwise = _evaluateSubexpression(isSet
              ? new SetLiteral([cloner.clone(element.otherwise)], isConst: true)
              : new ListLiteral([cloner.clone(element.otherwise)],
                  isConst: true));
        } else {
          otherwise = isSet
              ? new SetConstant(const DynamicType(), [])
              : new ListConstant(const DynamicType(), []);
        }
        leaveLazy();
        parts.add(unevaluated(
            element.condition,
            new ConditionalExpression(extract(condition), extract(then),
                extract(otherwise), const DynamicType())));
      } else {
        // Fully evaluated if
        if (condition == trueConstant) {
          addToListOrSetConstant(parts, element.then, elementType, seen);
        } else if (condition == falseConstant) {
          if (element.otherwise != null) {
            addToListOrSetConstant(parts, element.otherwise, elementType, seen);
          }
        } else if (condition == nullConstant) {
          report(element.condition, messageConstEvalNullValue);
        } else {
          report(
              element.condition,
              templateConstEvalInvalidType.withArguments(
                  condition,
                  typeEnvironment.boolType,
                  condition.getType(typeEnvironment)));
        }
      }
    } else if (element is ForElement || element is ForInElement) {
      // For or for-in
      report(
          element,
          isSet
              ? messageConstEvalIterationInConstSet
              : messageConstEvalIterationInConstList);
    } else {
      // Ordinary expresion element
      Constant constant = _evaluateSubexpression(element);
      if (shouldBeUnevaluated) {
        parts.add(unevaluated(
            element,
            isSet
                ? new SetLiteral([extract(constant)],
                    typeArgument: elementType, isConst: true)
                : new ListLiteral([extract(constant)],
                    typeArgument: elementType, isConst: true)));
      } else {
        List<Constant> listOrSet;
        if (parts.last is List<Constant>) {
          listOrSet = parts.last;
        } else {
          parts.add(listOrSet = <Constant>[]);
        }
        if (isSet) {
          if (!hasPrimitiveEqual(constant)) {
            report(
                element,
                templateConstEvalElementImplementsEqual
                    .withArguments(constant));
          }
          if (!seen.add(constant)) {
            report(element,
                templateConstEvalDuplicateElement.withArguments(constant));
          }
        }
        listOrSet.add(ensureIsSubtype(constant, elementType, element));
      }
    }
  }

  Constant makeListConstantFromParts(
      List<Object> parts, Expression node, DartType elementType) {
    if (parts.length == 1) {
      // Fully evaluated
      return lowerListConstant(new ListConstant(elementType, parts.single));
    }
    List<Expression> lists = <Expression>[];
    for (Object part in parts) {
      if (part is List<Constant>) {
        lists.add(new ConstantExpression(new ListConstant(elementType, part)));
      } else if (part is Constant) {
        lists.add(extract(part));
      } else {
        throw 'Non-constant in constant list';
      }
    }
    return unevaluated(
        node, new ListConcatenation(lists, typeArgument: elementType));
  }

  visitListLiteral(ListLiteral node) {
    if (!node.isConst) {
      return report(
          node, templateConstEvalNonConstantLiteral.withArguments('List'));
    }
    final List<Object> parts = <Object>[<Constant>[]];
    for (Expression element in node.expressions) {
      addToListOrSetConstant(parts, element, node.typeArgument);
    }
    return makeListConstantFromParts(parts, node, node.typeArgument);
  }

  visitListConcatenation(ListConcatenation node) {
    final List<Object> parts = <Object>[<Constant>[]];
    for (Expression list in node.lists) {
      addToListOrSetConstant(parts,
          new SpreadElement(cloner.clone(list), false), node.typeArgument);
    }
    return makeListConstantFromParts(parts, node, node.typeArgument);
  }

  Constant makeSetConstantFromParts(
      List<Object> parts, Expression node, DartType elementType) {
    if (parts.length == 1) {
      // Fully evaluated
      List<Constant> entries = parts.single;
      SetConstant result = new SetConstant(elementType, entries);
      if (desugarSets) {
        final List<ConstantMapEntry> mapEntries =
            new List<ConstantMapEntry>(entries.length);
        for (int i = 0; i < entries.length; ++i) {
          mapEntries[i] = new ConstantMapEntry(entries[i], nullConstant);
        }
        Constant map = lowerMapConstant(
            new MapConstant(elementType, typeEnvironment.nullType, mapEntries));
        return lower(
            result,
            new InstanceConstant(
                unmodifiableSetMap.enclosingClass.reference,
                [elementType],
                <Reference, Constant>{unmodifiableSetMap.reference: map}));
      } else {
        return lowerSetConstant(result);
      }
    }
    List<Expression> sets = <Expression>[];
    for (Object part in parts) {
      if (part is List<Constant>) {
        sets.add(new ConstantExpression(new SetConstant(elementType, part)));
      } else if (part is Constant) {
        sets.add(extract(part));
      } else {
        throw 'Non-constant in constant set';
      }
    }
    return unevaluated(
        node, new SetConcatenation(sets, typeArgument: elementType));
  }

  visitSetLiteral(SetLiteral node) {
    if (!node.isConst) {
      return report(
          node, templateConstEvalNonConstantLiteral.withArguments('Set'));
    }
    final Set<Constant> seen = new Set<Constant>.identity();
    final List<Object> parts = <Object>[<Constant>[]];
    for (Expression element in node.expressions) {
      addToListOrSetConstant(parts, element, node.typeArgument, seen);
    }
    return makeSetConstantFromParts(parts, node, node.typeArgument);
  }

  visitSetConcatenation(SetConcatenation node) {
    final Set<Constant> seen = new Set<Constant>.identity();
    final List<Object> parts = <Object>[<Constant>[]];
    for (Expression set_ in node.sets) {
      addToListOrSetConstant(
          parts,
          new SpreadElement(cloner.clone(set_), false),
          node.typeArgument,
          seen);
    }
    return makeSetConstantFromParts(parts, node, node.typeArgument);
  }

  /// Add a map entry (which is possibly a spread or an if map entry) to a
  /// constant map represented as a list of (possibly unevaluated)
  /// maps to be concatenated.
  /// Each element of [parts] is either a `List<ConstantMapEntry>` (containing
  /// fully evaluated map entries) or a `Constant` (potentially unevaluated).
  void addToMapConstant(List<Object> parts, MapEntry element, DartType keyType,
      DartType valueType, Set<Constant> seenKeys) {
    if (element is SpreadMapEntry) {
      Constant spread = unlower(_evaluateSubexpression(element.expression));
      if (shouldBeUnevaluated) {
        // Unevaluated spread
        if (element.isNullAware) {
          VariableDeclaration temp =
              new VariableDeclaration(null, initializer: extract(spread));
          parts.add(unevaluated(
              element.expression,
              new Let(
                  temp,
                  new ConditionalExpression(
                      new MethodInvocation(new VariableGet(temp),
                          new Name('=='), new Arguments([new NullLiteral()])),
                      new MapLiteral([], isConst: true),
                      new VariableGet(temp),
                      const DynamicType()))));
        } else {
          parts.add(spread);
        }
      } else if (spread == nullConstant) {
        // Null spread
        if (!element.isNullAware) {
          report(element.expression, messageConstEvalNullValue);
        }
      } else {
        // Fully evaluated spread
        if (spread is MapConstant) {
          for (ConstantMapEntry entry in spread.entries) {
            addToMapConstant(
                parts,
                new MapEntry(new ConstantExpression(entry.key),
                    new ConstantExpression(entry.value)),
                keyType,
                valueType,
                seenKeys);
          }
        } else {
          // Not map in spread
          return report(element.expression, messageConstEvalNotMapInSpread);
        }
      }
    } else if (element is IfMapEntry) {
      Constant condition = _evaluateSubexpression(element.condition);
      if (shouldBeUnevaluated) {
        // Unevaluated if
        enterLazy();
        Constant then = _evaluateSubexpression(
            new MapLiteral([cloner.clone(element.then)], isConst: true));
        Constant otherwise;
        if (element.otherwise != null) {
          otherwise = _evaluateSubexpression(
              new MapLiteral([cloner.clone(element.otherwise)], isConst: true));
        } else {
          otherwise =
              new MapConstant(const DynamicType(), const DynamicType(), []);
        }
        leaveLazy();
        parts.add(unevaluated(
            element.condition,
            new ConditionalExpression(extract(condition), extract(then),
                extract(otherwise), const DynamicType())));
      } else {
        // Fully evaluated if
        if (condition == trueConstant) {
          addToMapConstant(parts, element.then, keyType, valueType, seenKeys);
        } else if (condition == falseConstant) {
          if (element.otherwise != null) {
            addToMapConstant(
                parts, element.otherwise, keyType, valueType, seenKeys);
          }
        } else if (condition == nullConstant) {
          report(element.condition, messageConstEvalNullValue);
        } else {
          report(
              element.condition,
              templateConstEvalInvalidType.withArguments(
                  condition,
                  typeEnvironment.boolType,
                  condition.getType(typeEnvironment)));
        }
      }
    } else if (element is ForMapEntry || element is ForInMapEntry) {
      // For or for-in
      report(element, messageConstEvalIterationInConstMap);
    } else {
      // Ordinary map entry
      Constant key = _evaluateSubexpression(element.key);
      Constant value = _evaluateSubexpression(element.value);
      if (shouldBeUnevaluated) {
        parts.add(unevaluated(
            element.key,
            new MapLiteral([new MapEntry(extract(key), extract(value))],
                isConst: true)));
      } else {
        List<ConstantMapEntry> entries;
        if (parts.last is List<ConstantMapEntry>) {
          entries = parts.last;
        } else {
          parts.add(entries = <ConstantMapEntry>[]);
        }
        if (!hasPrimitiveEqual(key)) {
          report(
              element, templateConstEvalKeyImplementsEqual.withArguments(key));
        }
        if (!seenKeys.add(key)) {
          report(element.key, templateConstEvalDuplicateKey.withArguments(key));
        }
        entries.add(new ConstantMapEntry(
            ensureIsSubtype(key, keyType, element.key),
            ensureIsSubtype(value, valueType, element.value)));
      }
    }
  }

  Constant makeMapConstantFromParts(List<Object> parts, Expression node,
      DartType keyType, DartType valueType) {
    if (parts.length == 1) {
      // Fully evaluated
      return lowerMapConstant(
          new MapConstant(keyType, valueType, parts.single));
    }
    List<Expression> maps = <Expression>[];
    for (Object part in parts) {
      if (part is List<ConstantMapEntry>) {
        maps.add(
            new ConstantExpression(new MapConstant(keyType, valueType, part)));
      } else if (part is Constant) {
        maps.add(extract(part));
      } else {
        throw 'Non-constant in constant map';
      }
    }
    return unevaluated(node,
        new MapConcatenation(maps, keyType: keyType, valueType: valueType));
  }

  visitMapLiteral(MapLiteral node) {
    if (!node.isConst) {
      return report(
          node, templateConstEvalNonConstantLiteral.withArguments('Map'));
    }
    final Set<Constant> seen = new Set<Constant>.identity();
    final List<Object> parts = <Object>[<ConstantMapEntry>[]];
    for (MapEntry element in node.entries) {
      addToMapConstant(parts, element, node.keyType, node.valueType, seen);
    }
    return makeMapConstantFromParts(parts, node, node.keyType, node.valueType);
  }

  visitMapConcatenation(MapConcatenation node) {
    final Set<Constant> seen = new Set<Constant>.identity();
    final List<Object> parts = <Object>[<ConstantMapEntry>[]];
    for (Expression map in node.maps) {
      addToMapConstant(parts, new SpreadMapEntry(cloner.clone(map), false),
          node.keyType, node.valueType, seen);
    }
    return makeMapConstantFromParts(parts, node, node.keyType, node.valueType);
  }

  visitFunctionExpression(FunctionExpression node) {
    return report(
        node, templateConstEvalNonConstantLiteral.withArguments('Function'));
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    final Constructor constructor = node.target;
    final Class klass = constructor.enclosingClass;
    bool isSymbol = klass == coreTypes.internalSymbolClass;
    if (!constructor.isConst) {
      return reportInvalid(node, 'Non-const constructor invocation.');
    }
    if (constructor.function.body != null &&
        constructor.function.body is! EmptyStatement) {
      return reportInvalid(
          node,
          'Constructor "$node" has non-trivial body '
          '"${constructor.function.body.runtimeType}".');
    }
    if (klass.isAbstract) {
      return reportInvalid(
          node, 'Constructor "$node" belongs to abstract class "${klass}".');
    }

    final positionals = evaluatePositionalArguments(node.arguments);
    final named = evaluateNamedArguments(node.arguments);

    // Is the constructor unavailable due to separate compilation?
    bool isUnavailable = constructor.isInExternalLibrary &&
        constructor.initializers.isEmpty &&
        constructor.enclosingClass.supertype != null;

    if (isUnavailable || (isSymbol && shouldBeUnevaluated)) {
      return unevaluated(
          node,
          new ConstructorInvocation(constructor,
              unevaluatedArguments(positionals, named, node.arguments.types),
              isConst: true));
    }

    // Special case the dart:core's Symbol class here and convert it to a
    // [SymbolConstant].  For invalid values we report a compile-time error.
    if (isSymbol) {
      final Constant nameValue = positionals.single;

      if (nameValue is StringConstant && isValidSymbolName(nameValue.value)) {
        return canonicalize(new SymbolConstant(nameValue.value, null));
      }
      return report(node.arguments.positional.first,
          templateConstEvalInvalidSymbolName.withArguments(nameValue));
    }

    final typeArguments = evaluateTypeArguments(node, node.arguments);

    // Fill in any missing type arguments with "dynamic".
    for (int i = typeArguments.length; i < klass.typeParameters.length; i++) {
      typeArguments.add(const DynamicType());
    }

    // Start building a new instance.
    return withNewInstanceBuilder(klass, typeArguments, () {
      return runInsideContextIfNoContext(node, () {
        // "Run" the constructor (and any super constructor calls), which will
        // initialize the fields of the new instance.
        if (shouldBeUnevaluated) {
          enterLazy();
          handleConstructorInvocation(
              constructor, typeArguments, positionals, named);
          leaveLazy();
          return unevaluated(node, instanceBuilder.buildUnevaluatedInstance());
        }
        handleConstructorInvocation(
            constructor, typeArguments, positionals, named);
        if (shouldBeUnevaluated) {
          return unevaluated(node, instanceBuilder.buildUnevaluatedInstance());
        }
        return canonicalize(instanceBuilder.buildInstance());
      });
    });
  }

  visitInstanceCreation(InstanceCreation node) {
    return withNewInstanceBuilder(node.classNode, node.typeArguments, () {
      for (AssertStatement statement in node.asserts) {
        checkAssert(statement);
      }
      node.fieldValues.forEach((Reference fieldRef, Expression value) {
        instanceBuilder.setFieldValue(
            fieldRef.asField, _evaluateSubexpression(value));
      });
      if (shouldBeUnevaluated) {
        return unevaluated(node, instanceBuilder.buildUnevaluatedInstance());
      }
      return canonicalize(instanceBuilder.buildInstance());
    });
  }

  bool isValidSymbolName(String name) {
    // See https://api.dartlang.org/stable/2.0.0/dart-core/Symbol/Symbol.html:
    //
    //  A qualified name is a valid name preceded by a public identifier name and
    //  a '.', e.g., foo.bar.baz= is a qualified version of baz=.
    //
    //  That means that the content of the name String must be either
    //     - a valid public Dart identifier (that is, an identifier not
    //       starting with "_"),
    //     - such an identifier followed by "=" (a setter name),
    //     - the name of a declarable operator,
    //     - any of the above preceded by any number of qualifiers, where a
    //       qualifier is a non-private identifier followed by '.',
    //     - or the empty string (the default name of a library with no library
    //       name declaration).

    const operatorNames = const <String>[
      '+',
      '-',
      '*',
      '/',
      '%',
      '~/',
      '&',
      '|',
      '^',
      '~',
      '<<',
      '>>',
      '<',
      '<=',
      '>',
      '>=',
      '==',
      '[]',
      '[]=',
      'unary-'
    ];

    if (name == null) return false;
    if (name == '') return true;

    final parts = name.split('.');

    // Each qualifier must be a public identifier.
    for (int i = 0; i < parts.length - 1; ++i) {
      if (!isValidPublicIdentifier(parts[i])) return false;
    }

    String last = parts.last;
    if (operatorNames.contains(last)) {
      return true;
    }
    if (last.endsWith('=')) {
      last = last.substring(0, last.length - 1);
    }
    if (!isValidPublicIdentifier(last)) return false;

    return true;
  }

  /// From the Dart Language specification:
  ///
  ///   IDENTIFIER:
  ///     IDENTIFIER_START IDENTIFIER_PART*
  ///
  ///   IDENTIFIER_START:
  ///       IDENTIFIER_START_NO_DOLLAR | ‘$’
  ///
  ///   IDENTIFIER_PART:
  ///       IDENTIFIER_START | DIGIT
  ///
  ///   IDENTIFIER_NO_DOLLAR:
  ///     IDENTIFIER_START_NO_DOLLAR IDENTIFIER_PART_NO_DOLLAR*
  ///
  ///   IDENTIFIER_START_NO_DOLLAR:
  ///       LETTER | '_'
  ///
  ///   IDENTIFIER_PART_NO_DOLLAR:
  ///       IDENTIFIER_START_NO_DOLLAR | DIGIT
  ///
  static final publicIdentifierRegExp =
      new RegExp(r'^[a-zA-Z$][a-zA-Z0-9_$]*$');

  static const nonUsableKeywords = const <String>[
    'assert',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'else',
    'enum',
    'extends',
    'false',
    'final',
    'finally',
    'for',
    'if',
    'in',
    'is',
    'new',
    'null',
    'rethrow',
    'return',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'try',
    'var',
    'while',
    'with',
  ];

  bool isValidPublicIdentifier(String name) {
    return publicIdentifierRegExp.hasMatch(name) &&
        !nonUsableKeywords.contains(name);
  }

  handleConstructorInvocation(
      Constructor constructor,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments) {
    return runInsideContext(constructor, () {
      return withNewEnvironment(() {
        final Class klass = constructor.enclosingClass;
        final FunctionNode function = constructor.function;

        // We simulate now the constructor invocation.

        // Step 1) Map type arguments and normal arguments from caller to callee.
        for (int i = 0; i < klass.typeParameters.length; i++) {
          env.addTypeParameterValue(klass.typeParameters[i], typeArguments[i]);
        }
        for (int i = 0; i < function.positionalParameters.length; i++) {
          final VariableDeclaration parameter =
              function.positionalParameters[i];
          final Constant value = (i < positionalArguments.length)
              ? positionalArguments[i]
              : _evaluateSubexpression(parameter.initializer);
          env.addVariableValue(parameter, value);
        }
        for (final VariableDeclaration parameter in function.namedParameters) {
          final Constant value = namedArguments[parameter.name] ??
              _evaluateSubexpression(parameter.initializer);
          env.addVariableValue(parameter, value);
        }

        // Step 2) Run all initializers (including super calls) with environment setup.
        for (final Field field in klass.fields) {
          if (!field.isStatic) {
            instanceBuilder.setFieldValue(
                field, _evaluateSubexpression(field.initializer));
          }
        }
        for (final Initializer init in constructor.initializers) {
          if (init is FieldInitializer) {
            instanceBuilder.setFieldValue(
                init.field, _evaluateSubexpression(init.value));
          } else if (init is LocalInitializer) {
            final VariableDeclaration variable = init.variable;
            env.addVariableValue(
                variable, _evaluateSubexpression(variable.initializer));
          } else if (init is SuperInitializer) {
            handleConstructorInvocation(
                init.target,
                evaluateSuperTypeArguments(
                    init, constructor.enclosingClass.supertype),
                evaluatePositionalArguments(init.arguments),
                evaluateNamedArguments(init.arguments));
          } else if (init is RedirectingInitializer) {
            // Since a redirecting constructor targets a constructor of the same
            // class, we pass the same [typeArguments].
            handleConstructorInvocation(
                init.target,
                typeArguments,
                evaluatePositionalArguments(init.arguments),
                evaluateNamedArguments(init.arguments));
          } else if (init is AssertInitializer) {
            checkAssert(init.statement);
          } else {
            return reportInvalid(
                constructor,
                'No support for handling initializer of type '
                '"${init.runtimeType}".');
          }
        }
      });
    });
  }

  void checkAssert(AssertStatement statement) {
    if (enableAsserts) {
      final Constant condition = _evaluateSubexpression(statement.condition);

      if (shouldBeUnevaluated) {
        Expression message = null;
        if (statement.message != null) {
          enterLazy();
          message = extract(_evaluateSubexpression(statement.message));
          leaveLazy();
        }
        instanceBuilder.asserts.add(new AssertStatement(extract(condition),
            message: message,
            conditionStartOffset: statement.conditionStartOffset,
            conditionEndOffset: statement.conditionEndOffset));
      } else if (condition is BoolConstant) {
        if (!condition.value) {
          if (statement.message == null) {
            report(statement.condition, messageConstEvalFailedAssertion);
          }
          final Constant message = _evaluateSubexpression(statement.message);
          if (shouldBeUnevaluated) {
            instanceBuilder.asserts.add(new AssertStatement(extract(condition),
                message: extract(message),
                conditionStartOffset: statement.conditionStartOffset,
                conditionEndOffset: statement.conditionEndOffset));
          } else if (message is StringConstant) {
            report(
                statement.condition,
                templateConstEvalFailedAssertionWithMessage
                    .withArguments(message.value));
          } else {
            report(
                statement.message,
                templateConstEvalInvalidType.withArguments(
                    message,
                    typeEnvironment.stringType,
                    message.getType(typeEnvironment)));
          }
        }
      } else {
        report(
            statement.condition,
            templateConstEvalInvalidType.withArguments(condition,
                typeEnvironment.boolType, condition.getType(typeEnvironment)));
      }
    }
  }

  visitInvalidExpression(InvalidExpression node) {
    return reportInvalid(node, node.message);
  }

  visitMethodInvocation(MethodInvocation node) {
    // We have no support for generic method invocation atm.
    assert(node.arguments.named.isEmpty);

    final Constant receiver = _evaluateSubexpression(node.receiver);
    final List<Constant> arguments =
        evaluatePositionalArguments(node.arguments);

    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new MethodInvocation(extract(receiver), node.name,
              unevaluatedArguments(arguments, {}, node.arguments.types)));
    }

    // Handle == and != first (it's common between all types). Since `a != b` is
    // parsed as `!(a == b)` it is handled implicitly through ==.
    if (arguments.length == 1 && node.name.name == '==') {
      final right = arguments[0];

      // [DoubleConstant] uses [identical] to determine equality, so we need two
      // special cases:
      // Two NaNs are always unequal even if [identical] returns `true`.
      if (isNaN(receiver) || isNaN(right)) {
        return falseConstant;
      }

      // Two zero values are always equal regardless of sign.
      if (isZero(receiver)) {
        return makeBoolConstant(isZero(right));
      }

      if (receiver is NullConstant ||
          receiver is BoolConstant ||
          receiver is IntConstant ||
          receiver is DoubleConstant ||
          receiver is StringConstant ||
          right is NullConstant) {
        return makeBoolConstant(receiver == right);
      } else {
        return report(
            node,
            templateConstEvalInvalidEqualsOperandType.withArguments(
                receiver, receiver.getType(typeEnvironment)));
      }
    }

    // This is a white-listed set of methods we need to support on constants.
    if (receiver is StringConstant) {
      if (arguments.length == 1) {
        switch (node.name.name) {
          case '+':
            final Constant other = arguments[0];
            if (other is StringConstant) {
              return canonicalize(
                  new StringConstant(receiver.value + other.value));
            }
            return report(
                node,
                templateConstEvalInvalidBinaryOperandType.withArguments(
                    '+',
                    receiver,
                    typeEnvironment.stringType,
                    other.getType(typeEnvironment)));
        }
      }
    } else if (receiver is IntConstant || receiver is JavaScriptIntConstant) {
      if (arguments.length == 0) {
        switch (node.name.name) {
          case 'unary-':
            if (targetingJavaScript) {
              BigInt value = (receiver as JavaScriptIntConstant).bigIntValue;
              if (value == BigInt.zero) {
                return canonicalize(new DoubleConstant(-0.0));
              }
              return canonicalize(new JavaScriptIntConstant.fromBigInt(-value));
            }
            int value = (receiver as IntConstant).value;
            return canonicalize(new IntConstant(-value));
          case '~':
            if (targetingJavaScript) {
              BigInt value = (receiver as JavaScriptIntConstant).bigIntValue;
              return canonicalize(new JavaScriptIntConstant.fromBigInt(
                  (~value).toUnsigned(32)));
            }
            int value = (receiver as IntConstant).value;
            return canonicalize(new IntConstant(~value));
        }
      } else if (arguments.length == 1) {
        final Constant other = arguments[0];
        final op = node.name.name;
        if (other is IntConstant || other is JavaScriptIntConstant) {
          if ((op == '<<' || op == '>>' || op == '>>>')) {
            var receiverValue = receiver is IntConstant
                ? receiver.value
                : (receiver as JavaScriptIntConstant).bigIntValue;
            int otherValue = other is IntConstant
                ? other.value
                : (other as JavaScriptIntConstant).bigIntValue.toInt();
            if (otherValue < 0) {
              return report(
                  node.arguments.positional.first,
                  // TODO(askesc): Change argument types in template to constants.
                  templateConstEvalNegativeShift.withArguments(
                      op, '${receiverValue}', '${otherValue}'));
            }
          }

          if ((op == '%' || op == '~/')) {
            var receiverValue = receiver is IntConstant
                ? receiver.value
                : (receiver as JavaScriptIntConstant).bigIntValue;
            int otherValue = other is IntConstant
                ? other.value
                : (other as JavaScriptIntConstant).bigIntValue.toInt();
            if (otherValue == 0) {
              return report(
                  node.arguments.positional.first,
                  // TODO(askesc): Change argument type in template to constant.
                  templateConstEvalZeroDivisor.withArguments(
                      op, '${receiverValue}'));
            }
          }

          switch (op) {
            case '|':
            case '&':
            case '^':
              int receiverValue = receiver is IntConstant
                  ? receiver.value
                  : (receiver as JavaScriptIntConstant)
                      .bigIntValue
                      .toUnsigned(32)
                      .toInt();
              int otherValue = other is IntConstant
                  ? other.value
                  : (other as JavaScriptIntConstant)
                      .bigIntValue
                      .toUnsigned(32)
                      .toInt();
              return evaluateBinaryBitOperation(
                  node.name.name, receiverValue, otherValue, node);
            case '<<':
            case '>>':
            case '>>>':
              bool negative = false;
              int receiverValue;
              if (receiver is IntConstant) {
                receiverValue = receiver.value;
              } else {
                BigInt bigIntValue =
                    (receiver as JavaScriptIntConstant).bigIntValue;
                receiverValue = bigIntValue.toUnsigned(32).toInt();
                negative = bigIntValue.isNegative;
              }
              int otherValue = other is IntConstant
                  ? other.value
                  : (other as JavaScriptIntConstant).bigIntValue.toInt();

              return evaluateBinaryShiftOperation(
                  node.name.name, receiverValue, otherValue, node,
                  negativeReceiver: negative);
            default:
              num receiverValue = receiver is IntConstant
                  ? receiver.value
                  : (receiver as DoubleConstant).value;
              num otherValue = other is IntConstant
                  ? other.value
                  : (other as DoubleConstant).value;
              return evaluateBinaryNumericOperation(
                  node.name.name, receiverValue, otherValue, node);
          }
        } else if (other is DoubleConstant) {
          num receiverValue = receiver is IntConstant
              ? receiver.value
              : (receiver as DoubleConstant).value;
          return evaluateBinaryNumericOperation(
              node.name.name, receiverValue, other.value, node);
        }
        return report(
            node,
            templateConstEvalInvalidBinaryOperandType.withArguments(
                node.name.name,
                receiver,
                typeEnvironment.numType,
                other.getType(typeEnvironment)));
      }
    } else if (receiver is DoubleConstant) {
      if (arguments.length == 0) {
        switch (node.name.name) {
          case 'unary-':
            return canonicalize(makeDoubleConstant(-receiver.value));
        }
      } else if (arguments.length == 1) {
        final Constant other = arguments[0];

        if (other is IntConstant || other is DoubleConstant) {
          final num value = (other is IntConstant)
              ? other.value
              : (other as DoubleConstant).value;
          return evaluateBinaryNumericOperation(
              node.name.name, receiver.value, value, node);
        }
        return report(
            node,
            templateConstEvalInvalidBinaryOperandType.withArguments(
                node.name.name,
                receiver,
                typeEnvironment.numType,
                other.getType(typeEnvironment)));
      }
    } else if (receiver is BoolConstant) {
      if (arguments.length == 1) {
        final Constant other = arguments[0];
        if (other is BoolConstant) {
          switch (node.name.name) {
            case '|':
              return canonicalize(
                  new BoolConstant(receiver.value || other.value));
            case '&':
              return canonicalize(
                  new BoolConstant(receiver.value && other.value));
            case '^':
              return canonicalize(
                  new BoolConstant(receiver.value != other.value));
          }
        }
      }
    } else if (receiver is NullConstant) {
      return report(node, messageConstEvalNullValue);
    }

    return report(
        node,
        templateConstEvalInvalidMethodInvocation.withArguments(
            node.name.name, receiver));
  }

  visitLogicalExpression(LogicalExpression node) {
    final Constant left = _evaluateSubexpression(node.left);
    if (shouldBeUnevaluated) {
      enterLazy();
      Constant right = _evaluateSubexpression(node.right);
      leaveLazy();
      return unevaluated(node,
          new LogicalExpression(extract(left), node.operator, extract(right)));
    }
    switch (node.operator) {
      case '||':
        if (left is BoolConstant) {
          if (left.value) return trueConstant;

          final Constant right = _evaluateSubexpression(node.right);
          if (right is BoolConstant || right is UnevaluatedConstant) {
            return right;
          }

          return report(
              node,
              templateConstEvalInvalidBinaryOperandType.withArguments(
                  node.operator,
                  left,
                  typeEnvironment.boolType,
                  right.getType(typeEnvironment)));
        }
        return report(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                node.operator, left));
      case '&&':
        if (left is BoolConstant) {
          if (!left.value) return falseConstant;

          final Constant right = _evaluateSubexpression(node.right);
          if (right is BoolConstant || right is UnevaluatedConstant) {
            return right;
          }

          return report(
              node,
              templateConstEvalInvalidBinaryOperandType.withArguments(
                  node.operator,
                  left,
                  typeEnvironment.boolType,
                  right.getType(typeEnvironment)));
        }
        return report(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                node.operator, left));
      case '??':
        return (left is! NullConstant)
            ? left
            : _evaluateSubexpression(node.right);
      default:
        return report(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                node.operator, left));
    }
  }

  visitConditionalExpression(ConditionalExpression node) {
    final Constant condition = _evaluateSubexpression(node.condition);
    if (condition == trueConstant) {
      return _evaluateSubexpression(node.then);
    } else if (condition == falseConstant) {
      return _evaluateSubexpression(node.otherwise);
    } else if (shouldBeUnevaluated) {
      enterLazy();
      Constant then = _evaluateSubexpression(node.then);
      Constant otherwise = _evaluateSubexpression(node.otherwise);
      leaveLazy();
      return unevaluated(
          node,
          new ConditionalExpression(extract(condition), extract(then),
              extract(otherwise), node.staticType));
    } else {
      return report(
          node,
          templateConstEvalInvalidType.withArguments(condition,
              typeEnvironment.boolType, condition.getType(typeEnvironment)));
    }
  }

  visitPropertyGet(PropertyGet node) {
    if (node.receiver is ThisExpression) {
      // Access "this" during instance creation.
      if (instanceBuilder == null) {
        return reportInvalid(node, 'Instance field access outside constructor');
      }
      for (final Field field in instanceBuilder.fields.keys) {
        if (field.name == node.name) {
          return instanceBuilder.fields[field];
        }
      }
      return reportInvalid(node,
          'Could not evaluate field get ${node.name} on incomplete instance');
    }

    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is StringConstant && node.name.name == 'length') {
      if (targetingJavaScript) {
        return canonicalize(new JavaScriptIntConstant(receiver.value.length));
      }
      return canonicalize(new IntConstant(receiver.value.length));
    } else if (shouldBeUnevaluated) {
      return unevaluated(node,
          new PropertyGet(extract(receiver), node.name, node.interfaceTarget));
    } else if (receiver is NullConstant) {
      return report(node, messageConstEvalNullValue);
    }
    return report(
        node,
        templateConstEvalInvalidPropertyGet.withArguments(
            node.name.name, receiver));
  }

  visitLet(Let node) {
    env.addVariableValue(
        node.variable, _evaluateSubexpression(node.variable.initializer));
    return _evaluateSubexpression(node.body);
  }

  visitVariableGet(VariableGet node) {
    // Not every variable which a [VariableGet] refers to must be marked as
    // constant.  For example function parameters as well as constructs
    // desugared to [Let] expressions are ok.
    //
    // TODO(kustermann): The heuristic of allowing all [VariableGet]s on [Let]
    // variables might allow more than it should.
    final VariableDeclaration variable = node.variable;
    if (variable.parent is Let || _isFormalParameter(variable)) {
      return env.lookupVariable(node.variable) ??
          report(
              node,
              templateConstEvalNonConstantVariableGet
                  .withArguments(variable.name));
    }
    if (variable.isConst) {
      return _evaluateSubexpression(variable.initializer);
    }
    return reportInvalid(node, 'Variable get of a non-const variable.');
  }

  visitStaticGet(StaticGet node) {
    return withNewEnvironment(() {
      final Member target = node.target;
      if (target is Field) {
        if (target.isConst) {
          if (target.isInExternalLibrary && target.initializer == null) {
            // The variable is unavailable due to separate compilation.
            return unevaluated(node, new StaticGet(target));
          }
          return runInsideContext(target, () {
            return _evaluateSubexpression(target.initializer);
          });
        }
        return report(
            node,
            templateConstEvalInvalidStaticInvocation
                .withArguments(target.name.name));
      } else if (target is Procedure) {
        if (target.kind == ProcedureKind.Method) {
          return canonicalize(new TearOffConstant(target));
        }
        return report(
            node,
            templateConstEvalInvalidStaticInvocation
                .withArguments(target.name.name));
      } else {
        reportInvalid(
            node, 'No support for ${target.runtimeType} in a static-get.');
      }
    });
  }

  visitStringConcatenation(StringConcatenation node) {
    final List<Object> concatenated = <Object>[new StringBuffer()];
    for (int i = 0; i < node.expressions.length; i++) {
      Constant constant = _evaluateSubexpression(node.expressions[i]);
      if (constant is PrimitiveConstant<Object>) {
        String value = constant.toString();
        Object last = concatenated.last;
        if (last is StringBuffer) {
          last.write(value);
        } else {
          concatenated.add(new StringBuffer(value));
        }
      } else if (shouldBeUnevaluated) {
        // The constant is either unevaluated or a non-primitive in an
        // unevaluated context. In both cases we defer the evaluation and/or
        // error reporting till later.
        concatenated.add(constant);
      } else {
        return report(
            node,
            templateConstEvalInvalidStringInterpolationOperand
                .withArguments(constant));
      }
    }
    if (concatenated.length > 1) {
      final expressions = new List<Expression>(concatenated.length);
      for (int i = 0; i < concatenated.length; i++) {
        Object value = concatenated[i];
        if (value is StringBuffer) {
          expressions[i] = new ConstantExpression(
              canonicalize(new StringConstant(value.toString())));
        } else {
          // The value is either unevaluated constant or a non-primitive
          // constant in an unevaluated expression.
          expressions[i] = extract(value);
        }
      }
      return unevaluated(node, new StringConcatenation(expressions));
    }
    return canonicalize(new StringConstant(concatenated.single.toString()));
  }

  visitStaticInvocation(StaticInvocation node) {
    final Procedure target = node.target;
    final Arguments arguments = node.arguments;
    final positionals = evaluatePositionalArguments(arguments);
    final named = evaluateNamedArguments(arguments);
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new StaticInvocation(
              target, unevaluatedArguments(positionals, named, arguments.types),
              isConst: true));
    }
    if (target.kind == ProcedureKind.Factory) {
      if (target.isConst &&
          target.name.name == "fromEnvironment" &&
          target.enclosingLibrary == coreTypes.coreLibrary &&
          positionals.length == 1) {
        if (environmentDefines != null) {
          // Evaluate environment constant.
          Constant name = positionals.single;
          if (name is StringConstant) {
            String value = environmentDefines[name.value];
            Constant defaultValue = named["defaultValue"];

            if (target.enclosingClass == coreTypes.boolClass) {
              Constant boolConstant = value == "true"
                  ? trueConstant
                  : value == "false"
                      ? falseConstant
                      : defaultValue is BoolConstant
                          ? makeBoolConstant(defaultValue.value)
                          : defaultValue is NullConstant
                              ? nullConstant
                              : falseConstant;
              return boolConstant;
            } else if (target.enclosingClass == coreTypes.intClass) {
              int intValue = value != null ? int.tryParse(value) : null;
              intValue ??= defaultValue is IntConstant
                  ? defaultValue.value
                  : defaultValue is JavaScriptIntConstant
                      ? defaultValue.bigIntValue.toInt()
                      : null;
              if (intValue == null) return nullConstant;
              if (targetingJavaScript) {
                return canonicalize(new JavaScriptIntConstant(intValue));
              }
              return canonicalize(new IntConstant(intValue));
            } else if (target.enclosingClass == coreTypes.stringClass) {
              value ??=
                  defaultValue is StringConstant ? defaultValue.value : null;
              if (value == null) return nullConstant;
              return canonicalize(new StringConstant(value));
            }
          } else if (name is NullConstant) {
            return report(node, messageConstEvalNullValue);
          }
        } else {
          // Leave environment constant unevaluated.
          return unevaluated(
              node,
              new StaticInvocation(target,
                  unevaluatedArguments(positionals, named, arguments.types),
                  isConst: true));
        }
      }
    } else if (target.name.name == 'identical') {
      // Ensure the "identical()" function comes from dart:core.
      final parent = target.parent;
      if (parent is Library && parent == coreTypes.coreLibrary) {
        final Constant left = positionals[0];
        final Constant right = positionals[1];

        if (targetingJavaScript) {
          // In JavaScript, we lower [identical] to `===`, so any comparison
          // against NaN yields `false`.
          if (isNaN(left) || isNaN(right)) {
            return falseConstant;
          }

          // In JavaScript, `-0.0 === 0.0`.
          if (isZero(left)) {
            return makeBoolConstant(isZero(right));
          }
        }

        // Since we canonicalize constants during the evaluation, we can use
        // identical here.
        return makeBoolConstant(identical(left, right));
      }
    }

    // TODO(kmillikin) For an invalid factory invocation we should adopt a
    // better message.  This will show something like:
    //
    // "The invocation of 'List' is not allowed within a const context."
    //
    // Which is not quite right when the code was "new List()".
    String name = target.name.name;
    if (target is Procedure && target.isFactory) {
      if (name.isEmpty) {
        name = target.enclosingClass.name;
      } else {
        name = '${target.enclosingClass.name}.${name}';
      }
    }
    return report(
        node, templateConstEvalInvalidStaticInvocation.withArguments(name));
  }

  visitAsExpression(AsExpression node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (shouldBeUnevaluated) {
      return unevaluated(node,
          new AsExpression(extract(constant), env.subsituteType(node.type)));
    }
    return ensureIsSubtype(constant, evaluateDartType(node, node.type), node);
  }

  visitIsExpression(IsExpression node) {
    final Constant constant = node.operand.accept(this);
    if (shouldBeUnevaluated) {
      return unevaluated(node, new IsExpression(extract(constant), node.type));
    }
    if (constant is NullConstant) {
      return makeBoolConstant(node.type == typeEnvironment.nullType ||
          node.type == typeEnvironment.objectType ||
          node.type is DynamicType);
    }
    return makeBoolConstant(
        isSubtype(constant, evaluateDartType(node, node.type)));
  }

  visitNot(Not node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (constant is BoolConstant) {
      return makeBoolConstant(constant != trueConstant);
    }
    if (shouldBeUnevaluated) {
      return unevaluated(node, new Not(extract(constant)));
    }
    return report(
        node,
        templateConstEvalInvalidType.withArguments(constant,
            typeEnvironment.boolType, constant.getType(typeEnvironment)));
  }

  visitSymbolLiteral(SymbolLiteral node) {
    final libraryReference =
        node.value.startsWith('_') ? libraryOf(node).reference : null;
    return canonicalize(new SymbolConstant(node.value, libraryReference));
  }

  visitInstantiation(Instantiation node) {
    final Constant constant = _evaluateSubexpression(node.expression);
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new Instantiation(extract(constant),
              node.typeArguments.map((t) => env.subsituteType(t)).toList()));
    }
    if (constant is TearOffConstant) {
      if (node.typeArguments.length ==
          constant.procedure.function.typeParameters.length) {
        final typeArguments = evaluateDartTypes(node, node.typeArguments);
        return canonicalize(
            new PartialInstantiationConstant(constant, typeArguments));
      }
      return reportInvalid(
          node,
          'The number of type arguments supplied in the partial instantiation '
          'does not match the number of type arguments of the $constant.');
    }
    // The inner expression in an instantiation can never be null, since
    // instantiations are only inferred on direct references to declarations.
    return reportInvalid(
        node, 'Only tear-off constants can be partially instantiated.');
  }

  @override
  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return report(
        node, templateConstEvalDeferredLibrary.withArguments(node.import.name));
  }

  // Helper methods:

  bool isZero(Constant value) =>
      (value is IntConstant && value.value == 0) ||
      (value is JavaScriptIntConstant && value.bigIntValue == BigInt.zero) ||
      (value is DoubleConstant && value.value == 0);

  bool isNaN(Constant value) => value is DoubleConstant && value.value.isNaN;

  bool hasPrimitiveEqual(Constant constant) {
    // TODO(askesc, fishythefish): Make sure the correct class is inferred
    // when we clean up JavaScript int constant handling.
    DartType type = constant.getType(typeEnvironment);
    return !(type is InterfaceType && !classHasPrimitiveEqual(type.classNode));
  }

  bool classHasPrimitiveEqual(Class klass) {
    bool cached = primitiveEqualCache[klass];
    if (cached != null) return cached;
    for (Procedure procedure in klass.procedures) {
      if (procedure.kind == ProcedureKind.Operator &&
          procedure.name.name == '==' &&
          !procedure.isAbstract &&
          !procedure.isForwardingStub) {
        return primitiveEqualCache[klass] = false;
      }
    }
    if (klass.supertype == null) return true; // To be on the safe side
    return primitiveEqualCache[klass] =
        classHasPrimitiveEqual(klass.supertype.classNode);
  }

  BoolConstant makeBoolConstant(bool value) =>
      value ? trueConstant : falseConstant;

  DoubleConstant makeDoubleConstant(double value) {
    if (targetingJavaScript) {
      // Convert to an integer when possible (matching the runtime behavior
      // of `is int`).
      if (value.isFinite && !identical(value, -0.0)) {
        var i = value.toInt();
        if (value == i.toDouble()) return new JavaScriptIntConstant(i);
      }
    }
    return new DoubleConstant(value);
  }

  bool isSubtype(Constant constant, DartType type) {
    DartType constantType = constant.getType(typeEnvironment);
    if (targetingJavaScript) {
      if (constantType == typeEnvironment.intType &&
          type == typeEnvironment.doubleType) {
        // With JS semantics, an integer is also a double.
        return true;
      }

      if (constantType == typeEnvironment.doubleType &&
          type == typeEnvironment.intType) {
        double value = (constant as DoubleConstant).value;
        if (value.isFinite && value == value.truncateToDouble()) {
          return true;
        }
      }
    }
    return typeEnvironment.isSubtypeOf(constantType, type);
  }

  Constant ensureIsSubtype(Constant constant, DartType type, TreeNode node) {
    if (!isSubtype(constant, type)) {
      return report(
          node,
          templateConstEvalInvalidType.withArguments(
              constant, type, constant.getType(typeEnvironment)));
    }
    return constant;
  }

  List<DartType> evaluateTypeArguments(TreeNode node, Arguments arguments) {
    return evaluateDartTypes(node, arguments.types);
  }

  List<DartType> evaluateSuperTypeArguments(TreeNode node, Supertype type) {
    return evaluateDartTypes(node, type.typeArguments);
  }

  List<DartType> evaluateDartTypes(TreeNode node, List<DartType> types) {
    // TODO: Once the frontend gurantees that there are no free type variables
    // left over after stubstitution, we can enable this shortcut again:
    // if (env.isEmpty) return types;
    return types.map((t) => evaluateDartType(node, t)).toList();
  }

  DartType evaluateDartType(TreeNode node, DartType type) {
    final result = env.subsituteType(type);

    if (!isInstantiated(result)) {
      return report(
          node, templateConstEvalFreeTypeParameter.withArguments(type));
    }

    return result;
  }

  List<Constant> evaluatePositionalArguments(Arguments arguments) {
    return arguments.positional.map((Expression node) {
      return _evaluateSubexpression(node);
    }).toList();
  }

  Map<String, Constant> evaluateNamedArguments(Arguments arguments) {
    if (arguments.named.isEmpty) return const <String, Constant>{};

    final Map<String, Constant> named = {};
    arguments.named.forEach((NamedExpression pair) {
      named[pair.name] = _evaluateSubexpression(pair.value);
    });
    return named;
  }

  Arguments unevaluatedArguments(List<Constant> positionalArgs,
      Map<String, Constant> namedArgs, List<DartType> types) {
    final positional = new List<Expression>(positionalArgs.length);
    final named = new List<NamedExpression>(namedArgs.length);
    for (int i = 0; i < positionalArgs.length; ++i) {
      positional[i] = extract(positionalArgs[i]);
    }
    int i = 0;
    namedArgs.forEach((String name, Constant value) {
      named[i++] = new NamedExpression(name, extract(value));
    });
    return new Arguments(positional, named: named, types: types);
  }

  Constant canonicalize(Constant constant) {
    return canonicalizationCache.putIfAbsent(constant, () => constant);
  }

  withNewInstanceBuilder(Class klass, List<DartType> typeArguments, fn()) {
    InstanceBuilder old = instanceBuilder;
    try {
      instanceBuilder = new InstanceBuilder(this, klass, typeArguments);
      return fn();
    } finally {
      instanceBuilder = old;
    }
  }

  withNewEnvironment(fn()) {
    final EvaluationEnvironment oldEnv = env;
    try {
      env = new EvaluationEnvironment();
      return fn();
    } finally {
      env = oldEnv;
    }
  }

  Constant evaluateBinaryBitOperation(String op, int a, int b, TreeNode node) {
    int result;
    switch (op) {
      case '|':
        result = a | b;
        break;
      case '&':
        result = a & b;
        break;
      case '^':
        result = a ^ b;
        break;
    }

    if (targetingJavaScript) {
      return canonicalize(new JavaScriptIntConstant(result));
    }
    return canonicalize(new IntConstant(result));
  }

  Constant evaluateBinaryShiftOperation(String op, int a, int b, TreeNode node,
      {negativeReceiver: false}) {
    int result;
    switch (op) {
      case '<<':
        result = a << b;
        break;
      case '>>':
        if (targetingJavaScript) {
          if (negativeReceiver) {
            const signBit = 0x80000000;
            a -= (a & signBit) << 1;
          }
          result = a >> b;
        } else {
          result = a >> b;
        }
        break;
      case '>>>':
        // TODO(fishythefish): Implement JS semantics for `>>>`.
        result = b >= 64 ? 0 : (a >> b) & ((1 << (64 - b)) - 1);
        break;
    }

    if (targetingJavaScript) {
      return canonicalize(new JavaScriptIntConstant(result.toUnsigned(32)));
    }
    return canonicalize(new IntConstant(result));
  }

  Constant evaluateBinaryNumericOperation(
      String op, num a, num b, TreeNode node) {
    num result;
    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '*':
        result = a * b;
        break;
      case '/':
        result = a / b;
        break;
      case '~/':
        result = a ~/ b;
        break;
      case '%':
        result = a % b;
        break;
    }

    if (result is int) {
      if (targetingJavaScript) {
        return canonicalize(new JavaScriptIntConstant(result));
      }
      return canonicalize(new IntConstant(result.toSigned(64)));
    }
    if (result is double) {
      return canonicalize(makeDoubleConstant(result));
    }

    switch (op) {
      case '<':
        return makeBoolConstant(a < b);
      case '<=':
        return makeBoolConstant(a <= b);
      case '>=':
        return makeBoolConstant(a >= b);
      case '>':
        return makeBoolConstant(a > b);
    }

    return reportInvalid(node, "Unexpected binary numeric operation '$op'.");
  }

  Library libraryOf(TreeNode node) {
    // The tree structure of the kernel AST ensures we always have an enclosing
    // library.
    while (true) {
      if (node is Library) return node;
      node = node.parent;
    }
  }
}

/// Holds the necessary information for a constant object, namely
///   * the [klass] being instantiated
///   * the [typeArguments] used for the instantiation
///   * the [fields] the instance will obtain (all fields from the
///     instantiated [klass] up to the [Object] klass).
class InstanceBuilder {
  ConstantEvaluator evaluator;

  /// The class of the new instance.
  final Class klass;

  /// The values of the type parameters of the new instance.
  final List<DartType> typeArguments;

  /// The field values of the new instance.
  final Map<Field, Constant> fields = <Field, Constant>{};

  final List<AssertStatement> asserts = <AssertStatement>[];

  InstanceBuilder(this.evaluator, this.klass, this.typeArguments);

  void setFieldValue(Field field, Constant constant) {
    fields[field] = constant;
  }

  InstanceConstant buildInstance() {
    assert(asserts.isEmpty);
    final Map<Reference, Constant> fieldValues = <Reference, Constant>{};
    fields.forEach((Field field, Constant value) {
      assert(value is! UnevaluatedConstant);
      fieldValues[field.reference] = value;
    });
    return new InstanceConstant(klass.reference, typeArguments, fieldValues);
  }

  InstanceCreation buildUnevaluatedInstance() {
    final Map<Reference, Expression> fieldValues = <Reference, Expression>{};
    fields.forEach((Field field, Constant value) {
      fieldValues[field.reference] = evaluator.extract(value);
    });
    return new InstanceCreation(
        klass.reference, typeArguments, fieldValues, asserts);
  }
}

/// Holds an environment of type parameters, parameters and variables.
class EvaluationEnvironment {
  /// The values of the type parameters in scope.
  final Map<TypeParameter, DartType> _typeVariables =
      <TypeParameter, DartType>{};

  /// The values of the parameters/variables in scope.
  final Map<VariableDeclaration, Constant> _variables =
      <VariableDeclaration, Constant>{};

  /// Whether the current environment is empty.
  bool get isEmpty => _typeVariables.isEmpty && _variables.isEmpty;

  void addTypeParameterValue(TypeParameter parameter, DartType value) {
    assert(!_typeVariables.containsKey(parameter));
    _typeVariables[parameter] = value;
  }

  void addVariableValue(VariableDeclaration variable, Constant value) {
    _variables[variable] = value;
  }

  DartType lookupParameterValue(TypeParameter parameter) {
    final DartType value = _typeVariables[parameter];
    assert(value != null);
    return value;
  }

  Constant lookupVariable(VariableDeclaration variable) {
    return _variables[variable];
  }

  DartType subsituteType(DartType type) {
    if (_typeVariables.isEmpty) return type;
    return substitute(type, _typeVariables);
  }
}

// Used as control-flow to abort the current evaluation.
class _AbortDueToError {
  final TreeNode node;
  final Message message;
  final List<LocatedMessage> context;

  _AbortDueToError(this.node, this.message, {this.context});
}

class _AbortDueToInvalidExpression {
  final TreeNode node;
  final String message;

  _AbortDueToInvalidExpression(this.node, this.message);
}

abstract class ErrorReporter {
  const ErrorReporter();

  void report(LocatedMessage message, List<LocatedMessage> context);

  void reportInvalidExpression(InvalidExpression node);
}

class SimpleErrorReporter implements ErrorReporter {
  const SimpleErrorReporter();

  @override
  void report(LocatedMessage message, List<LocatedMessage> context) {
    _report(message);
    for (LocatedMessage contextMessage in context) {
      _report(contextMessage);
    }
  }

  @override
  void reportInvalidExpression(InvalidExpression node) {
    // Ignored
  }

  void _report(LocatedMessage message) {
    reportMessage(message.uri, message.charOffset, message.message);
  }

  void reportMessage(Uri uri, int offset, String message) {
    io.exitCode = 42;
    io.stderr.writeln('$uri:$offset Constant evaluation error: $message');
  }
}

class IsInstantiatedVisitor extends DartTypeVisitor<bool> {
  final _availableVariables = new Set<TypeParameter>();

  bool isInstantiated(DartType type) {
    return type.accept(this);
  }

  bool defaultDartType(DartType node) {
    throw 'A visitor method seems to be unimplemented!';
  }

  bool visitInvalidType(InvalidType node) => true;
  bool visitDynamicType(DynamicType node) => true;
  bool visitVoidType(VoidType node) => true;
  bool visitBottomType(BottomType node) => true;

  bool visitTypeParameterType(TypeParameterType node) {
    return _availableVariables.contains(node.parameter);
  }

  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments
        .every((DartType typeArgument) => typeArgument.accept(this));
  }

  bool visitFunctionType(FunctionType node) {
    final parameters = node.typeParameters;
    _availableVariables.addAll(parameters);
    final bool result = node.returnType.accept(this) &&
        node.positionalParameters.every((p) => p.accept(this)) &&
        node.namedParameters.every((p) => p.type.accept(this));
    _availableVariables.removeAll(parameters);
    return result;
  }

  bool visitTypedefType(TypedefType node) {
    return node.unalias.accept(this);
  }
}

bool _isFormalParameter(VariableDeclaration variable) {
  final parent = variable.parent;
  if (parent is FunctionNode) {
    return parent.positionalParameters.contains(variable) ||
        parent.namedParameters.contains(variable);
  }
  return false;
}
