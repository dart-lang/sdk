// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library implements a kernel2kernel constant evaluation transformation.
///
/// Even though it is expected that the frontend does not emit kernel AST which
/// contains compile-time errors, this transformation still performs some
/// validation and throws a [ConstantEvaluationError] if there was a
/// compile-time errors.
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
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/target/targets.dart';

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageConstEvalCircularity,
        messageConstEvalContext,
        messageConstEvalExtension,
        messageConstEvalFailedAssertion,
        messageConstEvalNotListOrSetInSpread,
        messageConstEvalNotMapInSpread,
        messageConstEvalNullValue,
        messageConstEvalStartingPoint,
        messageConstEvalUnevaluated,
        messageNonAgnosticConstant,
        noLength,
        templateConstEvalCaseImplementsEqual,
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
        templateConstEvalNonConstantVariableGet,
        templateConstEvalZeroDivisor;

import 'constant_int_folder.dart';

part 'constant_collection_builders.dart';

Component transformComponent(
    Component component,
    ConstantsBackend backend,
    Map<String, String> environmentDefines,
    ErrorReporter errorReporter,
    EvaluationMode evaluationMode,
    {bool evaluateAnnotations,
    bool desugarSets,
    bool enableTripleShift,
    bool errorOnUnevaluatedConstant,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy}) {
  assert(evaluateAnnotations != null);
  assert(desugarSets != null);
  assert(enableTripleShift != null);
  assert(errorOnUnevaluatedConstant != null);
  coreTypes ??= new CoreTypes(component);
  hierarchy ??= new ClassHierarchy(component, coreTypes);

  final TypeEnvironment typeEnvironment =
      new TypeEnvironment(coreTypes, hierarchy);

  transformLibraries(component.libraries, backend, environmentDefines,
      typeEnvironment, errorReporter, evaluationMode,
      desugarSets: desugarSets,
      enableTripleShift: enableTripleShift,
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
    EvaluationMode evaluationMode,
    {bool evaluateAnnotations,
    bool desugarSets,
    bool enableTripleShift,
    bool errorOnUnevaluatedConstant}) {
  assert(evaluateAnnotations != null);
  assert(desugarSets != null);
  assert(enableTripleShift != null);
  assert(errorOnUnevaluatedConstant != null);
  final ConstantsTransformer constantsTransformer = new ConstantsTransformer(
      backend,
      environmentDefines,
      evaluateAnnotations,
      desugarSets,
      enableTripleShift,
      errorOnUnevaluatedConstant,
      typeEnvironment,
      errorReporter,
      evaluationMode);
  for (final Library library in libraries) {
    constantsTransformer.convertLibrary(library);
  }
}

void transformProcedure(
    Procedure procedure,
    ConstantsBackend backend,
    Map<String, String> environmentDefines,
    TypeEnvironment typeEnvironment,
    ErrorReporter errorReporter,
    EvaluationMode evaluationMode,
    {bool evaluateAnnotations: true,
    bool desugarSets: false,
    bool enableTripleShift: false,
    bool errorOnUnevaluatedConstant: false}) {
  assert(evaluateAnnotations != null);
  assert(desugarSets != null);
  assert(enableTripleShift != null);
  assert(errorOnUnevaluatedConstant != null);
  final ConstantsTransformer constantsTransformer = new ConstantsTransformer(
      backend,
      environmentDefines,
      evaluateAnnotations,
      desugarSets,
      enableTripleShift,
      errorOnUnevaluatedConstant,
      typeEnvironment,
      errorReporter,
      evaluationMode);
  constantsTransformer.visitProcedure(procedure);
}

enum EvaluationMode {
  weak,
  agnostic,
  strong,
}

class ConstantWeakener extends ComputeOnceConstantVisitor<Constant> {
  ConstantEvaluator _evaluator;

  ConstantWeakener(this._evaluator);

  CoreTypes get _coreTypes => _evaluator.coreTypes;

  Constant processValue(Constant node, Constant value) {
    if (value != null) {
      value = _evaluator.canonicalize(value);
    }
    return value;
  }

  @override
  Constant defaultConstant(Constant node) => throw new UnsupportedError(
      "Unhandled constant ${node} (${node.runtimeType})");

  @override
  Constant visitNullConstant(NullConstant node) => null;

  @override
  Constant visitBoolConstant(BoolConstant node) => null;

  @override
  Constant visitIntConstant(IntConstant node) => null;

  @override
  Constant visitDoubleConstant(DoubleConstant node) => null;

  @override
  Constant visitStringConstant(StringConstant node) => null;

  @override
  Constant visitSymbolConstant(SymbolConstant node) => null;

  @override
  Constant visitMapConstant(MapConstant node) {
    DartType keyType = rawLegacyErasure(_coreTypes, node.keyType);
    DartType valueType = rawLegacyErasure(_coreTypes, node.valueType);
    List<ConstantMapEntry> entries;
    for (int index = 0; index < node.entries.length; index++) {
      ConstantMapEntry entry = node.entries[index];
      Constant key = visitConstant(entry.key);
      Constant value = visitConstant(entry.value);
      if (key != null || value != null) {
        entries ??= node.entries.toList(growable: false);
        entries[index] =
            new ConstantMapEntry(key ?? entry.key, value ?? entry.value);
      }
    }
    if (keyType != null || valueType != null || entries != null) {
      return new MapConstant(keyType ?? node.keyType,
          valueType ?? node.valueType, entries ?? node.entries);
    }
    return null;
  }

  @override
  Constant visitListConstant(ListConstant node) {
    DartType typeArgument = rawLegacyErasure(_coreTypes, node.typeArgument);
    List<Constant> entries;
    for (int index = 0; index < node.entries.length; index++) {
      Constant entry = visitConstant(node.entries[index]);
      if (entry != null) {
        entries ??= node.entries.toList(growable: false);
        entries[index] = entry;
      }
    }
    if (typeArgument != null || entries != null) {
      return new ListConstant(
          typeArgument ?? node.typeArgument, entries ?? node.entries);
    }
    return null;
  }

  @override
  Constant visitSetConstant(SetConstant node) {
    DartType typeArgument = rawLegacyErasure(_coreTypes, node.typeArgument);
    List<Constant> entries;
    for (int index = 0; index < node.entries.length; index++) {
      Constant entry = visitConstant(node.entries[index]);
      if (entry != null) {
        entries ??= node.entries.toList(growable: false);
        entries[index] = entry;
      }
    }
    if (typeArgument != null || entries != null) {
      return new SetConstant(
          typeArgument ?? node.typeArgument, entries ?? node.entries);
    }
    return null;
  }

  @override
  Constant visitInstanceConstant(InstanceConstant node) {
    List<DartType> typeArguments;
    for (int index = 0; index < node.typeArguments.length; index++) {
      DartType typeArgument =
          rawLegacyErasure(_coreTypes, node.typeArguments[index]);
      if (typeArgument != null) {
        typeArguments ??= node.typeArguments.toList(growable: false);
        typeArguments[index] = typeArgument;
      }
    }
    Map<Reference, Constant> fieldValues;
    for (Reference reference in node.fieldValues.keys) {
      Constant value = visitConstant(node.fieldValues[reference]);
      if (value != null) {
        fieldValues ??= new Map<Reference, Constant>.from(node.fieldValues);
        fieldValues[reference] = value;
      }
    }
    if (typeArguments != null || fieldValues != null) {
      return new InstanceConstant(node.classReference,
          typeArguments ?? node.typeArguments, fieldValues ?? node.fieldValues);
    }
    return null;
  }

  @override
  Constant visitPartialInstantiationConstant(
      PartialInstantiationConstant node) {
    List<DartType> types;
    for (int index = 0; index < node.types.length; index++) {
      DartType type = rawLegacyErasure(_coreTypes, node.types[index]);
      if (type != null) {
        types ??= node.types.toList(growable: false);
        types[index] = type;
      }
    }
    if (types != null) {
      return new PartialInstantiationConstant(node.tearOffConstant, types);
    }
    return null;
  }

  @override
  Constant visitTearOffConstant(TearOffConstant node) => null;

  @override
  Constant visitTypeLiteralConstant(TypeLiteralConstant node) {
    DartType type = rawLegacyErasure(_coreTypes, node.type);
    if (type != null) {
      return new TypeLiteralConstant(type);
    }
    return null;
  }

  @override
  Constant visitUnevaluatedConstant(UnevaluatedConstant node) => null;
}

class ConstantsTransformer extends Transformer {
  final ConstantsBackend backend;
  final ConstantEvaluator constantEvaluator;
  final TypeEnvironment typeEnvironment;
  StaticTypeContext _staticTypeContext;

  final bool evaluateAnnotations;
  final bool desugarSets;
  final bool enableTripleShift;
  final bool errorOnUnevaluatedConstant;

  ConstantsTransformer(
      this.backend,
      Map<String, String> environmentDefines,
      this.evaluateAnnotations,
      this.desugarSets,
      this.enableTripleShift,
      this.errorOnUnevaluatedConstant,
      this.typeEnvironment,
      ErrorReporter errorReporter,
      EvaluationMode evaluationMode)
      : constantEvaluator = new ConstantEvaluator(
            backend, environmentDefines, typeEnvironment, errorReporter,
            desugarSets: desugarSets,
            enableTripleShift: enableTripleShift,
            errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
            evaluationMode: evaluationMode);

  /// Whether to preserve constant [Field]s. All use-sites will be rewritten.
  bool get keepFields => backend.keepFields;

  /// Whether to preserve constant [VariableDeclaration]s. All use-sites will be
  /// rewritten.
  bool get keepLocals => backend.keepLocals;

  // Transform the library/class members:

  void convertLibrary(Library library) {
    _staticTypeContext =
        new StaticTypeContext.forAnnotations(library, typeEnvironment);

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
    _staticTypeContext = null;
  }

  @override
  LibraryPart visitLibraryPart(LibraryPart node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  @override
  LibraryDependency visitLibraryDependency(LibraryDependency node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  @override
  Class visitClass(Class node) {
    StaticTypeContext oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext.forAnnotations(
        node.enclosingLibrary, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.fields, this, node);
      transformList(node.typeParameters, this, node);
      transformList(node.constructors, this, node);
      transformList(node.procedures, this, node);
      transformList(node.redirectingFactoryConstructors, this, node);
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  Procedure visitProcedure(Procedure node) {
    StaticTypeContext oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      node.function = node.function.accept<TreeNode>(this)..parent = node;
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  Constructor visitConstructor(Constructor node) {
    StaticTypeContext oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.initializers, this, node);
      node.function = node.function.accept<TreeNode>(this)..parent = node;
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  Typedef visitTypedef(Typedef node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.typeParameters, this, node);
      transformList(node.typeParametersOfFunctionType, this, node);
      transformList(node.positionalParameters, this, node);
      transformList(node.namedParameters, this, node);
    });
    return node;
  }

  @override
  RedirectingFactoryConstructor visitRedirectingFactoryConstructor(
      RedirectingFactoryConstructor node) {
    StaticTypeContext oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.typeParameters, this, node);
      transformList(node.positionalParameters, this, node);
      transformList(node.namedParameters, this, node);
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  TypeParameter visitTypeParameter(TypeParameter node) {
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

  @override
  FunctionNode visitFunctionNode(FunctionNode node) {
    transformList(node.typeParameters, this, node);
    final int positionalParameterCount = node.positionalParameters.length;
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
      node.body = node.body.accept<TreeNode>(this)..parent = node;
    }
    return node;
  }

  @override
  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) {
    transformAnnotations(node.annotations, node);

    if (node.initializer != null) {
      if (node.isConst) {
        final Constant constant = evaluateWithContext(node, node.initializer);
        constantEvaluator.env.addVariableValue(node, constant);
        node.initializer = makeConstantExpression(constant, node.initializer)
          ..parent = node;

        // If this constant is inlined, remove it.
        if (!keepLocals && shouldInline(node.initializer)) {
          if (constant is! UnevaluatedConstant) {
            // If the constant is unevaluated we need to keep the expression,
            // so that, in the case the constant contains error but the local
            // is unused, the error will still be reported.
            return null;
          }
        }
      } else {
        node.initializer = node.initializer.accept<TreeNode>(this)
          ..parent = node;
      }
    }
    return node;
  }

  @override
  Field visitField(Field node) {
    StaticTypeContext oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    Field field = constantEvaluator.withNewEnvironment(() {
      if (node.isConst) {
        transformAnnotations(node.annotations, node);
        node.initializer =
            evaluateAndTransformWithContext(node, node.initializer)
              ..parent = node;

        // If this constant is inlined, remove it.
        if (!keepFields && shouldInline(node.initializer)) {
          return null;
        }
      } else {
        transformAnnotations(node.annotations, node);
        if (node.initializer != null) {
          node.initializer = node.initializer.accept<TreeNode>(this)
            ..parent = node;
        }
      }
      return node;
    });
    _staticTypeContext = oldStaticTypeContext;
    return field;
  }

  // Handle use-sites of constants (and "inline" constant expressions):

  @override
  Expression visitSymbolLiteral(SymbolLiteral node) {
    return makeConstantExpression(
        constantEvaluator.evaluate(_staticTypeContext, node), node);
  }

  @override
  Expression visitStaticGet(StaticGet node) {
    final Member target = node.target;
    if (target is Field && target.isConst) {
      // Make sure the initializer is evaluated first.
      StaticTypeContext oldStaticTypeContext = _staticTypeContext;
      _staticTypeContext = new StaticTypeContext(target, typeEnvironment);
      target.initializer =
          evaluateAndTransformWithContext(target, target.initializer)
            ..parent = target;
      _staticTypeContext = oldStaticTypeContext;
      if (shouldInline(target.initializer)) {
        return evaluateAndTransformWithContext(node, node);
      }
    } else if (target is Procedure && target.kind == ProcedureKind.Method) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitStaticGet(node);
  }

  @override
  SwitchCase visitSwitchCase(SwitchCase node) {
    transformExpressions(node.expressions, node);
    return super.visitSwitchCase(node);
  }

  @override
  SwitchStatement visitSwitchStatement(SwitchStatement node) {
    SwitchStatement result = super.visitSwitchStatement(node);
    Library library = constantEvaluator.libraryOf(node);
    if (library != null && library.isNonNullableByDefault) {
      for (SwitchCase switchCase in node.cases) {
        for (Expression caseExpression in switchCase.expressions) {
          if (caseExpression is ConstantExpression) {
            if (!constantEvaluator.hasPrimitiveEqual(caseExpression.constant)) {
              Uri uri = constantEvaluator.getFileUri(caseExpression);
              int offset = constantEvaluator.getFileOffset(uri, caseExpression);
              constantEvaluator.errorReporter.report(
                  templateConstEvalCaseImplementsEqual
                      .withArguments(caseExpression.constant,
                          constantEvaluator.isNonNullableByDefault)
                      .withLocation(uri, offset, noLength),
                  null);
            }
          } else {
            // If caseExpression is not ConstantExpression, an error is reported
            // elsewhere.
          }
        }
      }
    }
    return result;
  }

  @override
  Expression visitVariableGet(VariableGet node) {
    final VariableDeclaration variable = node.variable;
    if (variable.isConst) {
      variable.initializer =
          evaluateAndTransformWithContext(variable, variable.initializer)
            ..parent = variable;
      if (shouldInline(variable.initializer)) {
        return evaluateAndTransformWithContext(node, node);
      }
    }
    return super.visitVariableGet(node);
  }

  @override
  Expression visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitListLiteral(node);
  }

  @override
  Expression visitListConcatenation(ListConcatenation node) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  Expression visitSetLiteral(SetLiteral node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitSetLiteral(node);
  }

  @override
  Expression visitSetConcatenation(SetConcatenation node) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  Expression visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitMapLiteral(node);
  }

  @override
  Expression visitMapConcatenation(MapConcatenation node) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  Expression visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitConstructorInvocation(node);
  }

  @override
  Expression visitStaticInvocation(StaticInvocation node) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitStaticInvocation(node);
  }

  @override
  Expression visitConstantExpression(ConstantExpression node) {
    Constant constant = node.constant;
    if (constant is UnevaluatedConstant) {
      Expression expression = constant.expression;
      return evaluateAndTransformWithContext(expression, expression);
    } else {
      node.constant = constantEvaluator.canonicalize(constant);
      return node;
    }
  }

  Expression evaluateAndTransformWithContext(
      TreeNode treeContext, Expression node) {
    return makeConstantExpression(evaluateWithContext(treeContext, node), node);
  }

  Constant evaluateWithContext(TreeNode treeContext, Expression node) {
    if (treeContext == node) {
      return constantEvaluator.evaluate(_staticTypeContext, node);
    }

    return constantEvaluator.runInsideContext(treeContext, () {
      return constantEvaluator.evaluate(_staticTypeContext, node);
    });
  }

  Expression makeConstantExpression(Constant constant, Expression node) {
    if (constant is UnevaluatedConstant &&
        constant.expression is InvalidExpression) {
      return constant.expression;
    }
    return new ConstantExpression(
        constant, node.getStaticType(_staticTypeContext))
      ..fileOffset = node.fileOffset;
  }

  bool shouldInline(Expression initializer) {
    if (initializer is ConstantExpression) {
      return backend.shouldInlineConstant(initializer);
    }
    return true;
  }
}

class ConstantEvaluator extends RecursiveVisitor<Constant> {
  final ConstantsBackend backend;
  final NumberSemantics numberSemantics;
  ConstantIntFolder intFolder;
  Map<String, String> environmentDefines;
  final bool errorOnUnevaluatedConstant;
  final CoreTypes coreTypes;
  final TypeEnvironment typeEnvironment;
  StaticTypeContext _staticTypeContext;
  final ErrorReporter errorReporter;
  final EvaluationMode evaluationMode;

  final bool desugarSets;
  final Field unmodifiableSetMap;

  final bool enableTripleShift;

  final bool Function(DartType) isInstantiated =
      new IsInstantiatedVisitor().isInstantiated;

  final Map<Constant, Constant> canonicalizationCache;
  final Map<Node, Object> nodeCache;
  final CloneVisitorNotMembers cloner = new CloneVisitorNotMembers();

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

  bool get isNonNullableByDefault =>
      _staticTypeContext.nonNullable == Nullability.nonNullable;

  ConstantWeakener _weakener;

  ConstantEvaluator(this.backend, this.environmentDefines, this.typeEnvironment,
      this.errorReporter,
      {this.desugarSets = false,
      this.enableTripleShift = false,
      this.errorOnUnevaluatedConstant = false,
      this.evaluationMode: EvaluationMode.weak})
      : numberSemantics = backend.numberSemantics,
        coreTypes = typeEnvironment.coreTypes,
        canonicalizationCache = <Constant, Constant>{},
        nodeCache = <Node, Constant>{},
        env = new EvaluationEnvironment(),
        unmodifiableSetMap = desugarSets
            ? typeEnvironment.coreTypes.index
                .getMember('dart:collection', '_UnmodifiableSet', '_map')
            : null {
    if (environmentDefines == null && !backend.supportsUnevaluatedConstants) {
      throw new ArgumentError(
          "No 'environmentDefines' passed to the constant evaluator but the "
          "ConstantsBackend does not support unevaluated constants.");
    }
    intFolder = new ConstantIntFolder.forSemantics(this, numberSemantics);
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
    _weakener = new ConstantWeakener(this);
  }

  DartType convertType(DartType type) {
    switch (evaluationMode) {
      case EvaluationMode.strong:
      case EvaluationMode.agnostic:
        return type;
      case EvaluationMode.weak:
        return legacyErasure(coreTypes, type);
    }
    throw new UnsupportedError(
        "Unexpected evaluation mode: ${evaluationMode}.");
  }

  List<DartType> convertTypes(List<DartType> types) {
    switch (evaluationMode) {
      case EvaluationMode.strong:
      case EvaluationMode.agnostic:
        return types;
      case EvaluationMode.weak:
        return types
            .map((DartType type) => legacyErasure(coreTypes, type))
            .toList();
    }
    throw new UnsupportedError(
        "Unexpected evaluation mode: ${evaluationMode}.");
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
  Constant evaluate(StaticTypeContext context, Expression node) {
    _staticTypeContext = context;
    seenUnevaluatedChild = false;
    lazyDepth = 0;
    try {
      Constant result = _evaluateSubexpression(node);
      if (result is UnevaluatedConstant) {
        if (errorOnUnevaluatedConstant) {
          return report(node, messageConstEvalUnevaluated);
        }
        return new UnevaluatedConstant(
            removeRedundantFileUriExpressions(result.expression));
      }
      return result;
    } on _AbortDueToError catch (e) {
      final Uri uri = getFileUri(e.node);
      final int fileOffset = getFileOffset(uri, e.node);
      final LocatedMessage locatedMessageActualError =
          e.message.withLocation(uri, fileOffset, noLength);

      final List<LocatedMessage> contextMessages = <LocatedMessage>[
        locatedMessageActualError
      ];
      if (e.context != null) contextMessages.addAll(e.context);
      for (final TreeNode node in contextChain) {
        if (node == e.node) continue;
        final Uri uri = getFileUri(node);
        final int fileOffset = getFileOffset(uri, node);
        contextMessages.add(
            messageConstEvalContext.withLocation(uri, fileOffset, noLength));
      }

      {
        final Uri uri = getFileUri(node);
        final int fileOffset = getFileOffset(uri, node);
        final LocatedMessage locatedMessage = messageConstEvalStartingPoint
            .withLocation(uri, fileOffset, noLength);
        errorReporter.report(locatedMessage, contextMessages);
      }
      return new UnevaluatedConstant(new InvalidExpression(e.message.message));
    } on _AbortDueToInvalidExpression catch (e) {
      InvalidExpression invalid = new InvalidExpression(e.message)
        ..fileOffset = node.fileOffset;
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
    return new UnevaluatedConstant(
        new FileUriExpression(replacement, getFileUri(original))
          ..fileOffset = original.fileOffset);
  }

  Expression removeRedundantFileUriExpressions(Expression node) {
    return node.accept(new RedundantFileUriExpressionRemover()) as Expression;
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

  Constant _evaluateNullableSubexpression(Expression node) {
    if (node == null) return nullConstant;
    return _evaluateSubexpression(node);
  }

  T runInsideContext<T>(TreeNode node, T fun()) {
    try {
      pushContext(node);
      return fun();
    } finally {
      popContext(node);
    }
  }

  T runInsideContextIfNoContext<T>(TreeNode node, T fun()) {
    if (contextChain.isEmpty) {
      return runInsideContext(node, fun);
    } else {
      return fun();
    }
  }

  void pushContext(TreeNode contextNode) {
    contextChain.add(contextNode);
  }

  void popContext(TreeNode contextNode) {
    assert(contextChain.last == contextNode);
    contextChain.length = contextChain.length - 1;
  }

  @override
  Constant defaultTreeNode(Node node) {
    // Only a subset of the expression language is valid for constant
    // evaluation.
    return reportInvalid(
        node, 'Constant evaluation has no support for ${node.runtimeType}!');
  }

  @override
  Constant visitFileUriExpression(FileUriExpression node) {
    return _evaluateSubexpression(node.expression);
  }

  @override
  Constant visitNullLiteral(NullLiteral node) => nullConstant;

  @override
  Constant visitBoolLiteral(BoolLiteral node) {
    return makeBoolConstant(node.value);
  }

  @override
  Constant visitIntLiteral(IntLiteral node) {
    // The frontend ensures that integer literals are valid according to the
    // target representation.
    return canonicalize(intFolder.makeIntConstant(node.value, unsigned: true));
  }

  @override
  Constant visitDoubleLiteral(DoubleLiteral node) {
    return canonicalize(new DoubleConstant(node.value));
  }

  @override
  Constant visitStringLiteral(StringLiteral node) {
    return canonicalize(new StringConstant(node.value));
  }

  @override
  Constant visitTypeLiteral(TypeLiteral node) {
    final DartType type = evaluateDartType(node, node.type);
    return canonicalize(new TypeLiteralConstant(type));
  }

  @override
  Constant visitConstantExpression(ConstantExpression node) {
    Constant constant = node.constant;
    Constant result = constant;
    if (constant is UnevaluatedConstant) {
      result = runInsideContext(constant.expression, () {
        return _evaluateSubexpression(constant.expression);
      });
    }
    // If there were already constants in the AST then we make sure we
    // re-canonicalize them.  After running the transformer we will therefore
    // have a fully-canonicalized constant DAG with roots coming from the
    // [ConstantExpression] nodes in the AST.
    return canonicalize(result);
  }

  @override
  Constant visitListLiteral(ListLiteral node) {
    if (!node.isConst) {
      return reportInvalid(node, "Non-constant list literal");
    }
    final ListConstantBuilder builder =
        new ListConstantBuilder(node, convertType(node.typeArgument), this);
    for (Expression element in node.expressions) {
      builder.add(element);
    }
    return builder.build();
  }

  @override
  Constant visitListConcatenation(ListConcatenation node) {
    final ListConstantBuilder builder =
        new ListConstantBuilder(node, convertType(node.typeArgument), this);
    for (Expression list in node.lists) {
      builder.addSpread(list);
    }
    return builder.build();
  }

  @override
  Constant visitSetLiteral(SetLiteral node) {
    if (!node.isConst) {
      return reportInvalid(node, "Non-constant set literal");
    }
    final SetConstantBuilder builder =
        new SetConstantBuilder(node, convertType(node.typeArgument), this);
    for (Expression element in node.expressions) {
      builder.add(element);
    }
    return builder.build();
  }

  @override
  Constant visitSetConcatenation(SetConcatenation node) {
    final SetConstantBuilder builder =
        new SetConstantBuilder(node, convertType(node.typeArgument), this);
    for (Expression set_ in node.sets) {
      builder.addSpread(set_);
    }
    return builder.build();
  }

  @override
  Constant visitMapLiteral(MapLiteral node) {
    if (!node.isConst) {
      return reportInvalid(node, "Non-constant map literal");
    }
    final MapConstantBuilder builder = new MapConstantBuilder(
        node, convertType(node.keyType), convertType(node.valueType), this);
    for (MapEntry element in node.entries) {
      builder.add(element);
    }
    return builder.build();
  }

  @override
  Constant visitMapConcatenation(MapConcatenation node) {
    final MapConstantBuilder builder = new MapConstantBuilder(
        node, convertType(node.keyType), convertType(node.valueType), this);
    for (Expression map in node.maps) {
      builder.addSpread(map);
    }
    return builder.build();
  }

  @override
  Constant visitFunctionExpression(FunctionExpression node) {
    return reportInvalid(node, "Function literal");
  }

  @override
  Constant visitConstructorInvocation(ConstructorInvocation node) {
    if (!node.isConst) {
      return reportInvalid(
          node, 'Non-constant constructor invocation "$node".');
    }

    final Constructor constructor = node.target;
    checkConstructorConst(node, constructor);

    final Class klass = constructor.enclosingClass;
    if (klass.isAbstract) {
      return reportInvalid(
          node, 'Constructor "$node" belongs to abstract class "${klass}".');
    }

    final List<Constant> positionals =
        evaluatePositionalArguments(node.arguments);
    final Map<String, Constant> named = evaluateNamedArguments(node.arguments);

    bool isSymbol = klass == coreTypes.internalSymbolClass;
    if (isSymbol && shouldBeUnevaluated) {
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
      return report(
          node.arguments.positional.first,
          templateConstEvalInvalidSymbolName.withArguments(
              nameValue, isNonNullableByDefault));
    }

    final List<DartType> typeArguments =
        convertTypes(evaluateTypeArguments(node, node.arguments));

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

  void checkConstructorConst(TreeNode node, Constructor constructor) {
    if (!constructor.isConst) {
      reportInvalid(node, 'Non-const constructor invocation.');
    }
    if (constructor.function.body != null &&
        constructor.function.body is! EmptyStatement) {
      reportInvalid(
          node,
          'Constructor "$node" has non-trivial body '
          '"${constructor.function.body.runtimeType}".');
    }
  }

  @override
  Constant visitInstanceCreation(InstanceCreation node) {
    return withNewInstanceBuilder(
        node.classNode, convertTypes(node.typeArguments), () {
      for (AssertStatement statement in node.asserts) {
        checkAssert(statement);
      }
      node.fieldValues.forEach((Reference fieldRef, Expression value) {
        instanceBuilder.setFieldValue(
            fieldRef.asField, _evaluateSubexpression(value));
      });
      node.unusedArguments.forEach((Expression value) {
        Constant constant = _evaluateSubexpression(value);
        if (constant is UnevaluatedConstant) {
          instanceBuilder.unusedArguments.add(extract(constant));
        }
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
    //  A qualified name is a valid name preceded by a public identifier name
    //  and a '.', e.g., foo.bar.baz= is a qualified version of baz=.
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

    const List<String> operatorNames = const <String>[
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
      '>>>',
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

    final List<String> parts = name.split('.');

    // Each qualifier must be a public identifier.
    for (int i = 0; i < parts.length - 1; ++i) {
      if (!isValidPublicIdentifier(parts[i])) return false;
    }

    String last = parts.last;
    if (operatorNames.contains(last)) {
      return enableTripleShift || last != '>>>';
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
  static final RegExp publicIdentifierRegExp =
      new RegExp(r'^[a-zA-Z$][a-zA-Z0-9_$]*$');

  static const List<String> nonUsableKeywords = const <String>[
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

  void handleConstructorInvocation(
      Constructor constructor,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments) {
    return runInsideContext(constructor, () {
      return withNewEnvironment(() {
        final Class klass = constructor.enclosingClass;
        final FunctionNode function = constructor.function;

        // We simulate now the constructor invocation.

        // Step 1) Map type arguments and normal arguments from caller to
        //         callee.
        for (int i = 0; i < klass.typeParameters.length; i++) {
          env.addTypeParameterValue(klass.typeParameters[i], typeArguments[i]);
        }
        for (int i = 0; i < function.positionalParameters.length; i++) {
          final VariableDeclaration parameter =
              function.positionalParameters[i];
          final Constant value = (i < positionalArguments.length)
              ? positionalArguments[i]
              : _evaluateNullableSubexpression(parameter.initializer);
          env.addVariableValue(parameter, value);
        }
        for (final VariableDeclaration parameter in function.namedParameters) {
          final Constant value = namedArguments[parameter.name] ??
              _evaluateNullableSubexpression(parameter.initializer);
          env.addVariableValue(parameter, value);
        }

        // Step 2) Run all initializers (including super calls) with environment
        //         setup.
        for (final Field field in klass.fields) {
          if (!field.isStatic) {
            instanceBuilder.setFieldValue(
                field, _evaluateNullableSubexpression(field.initializer));
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
            checkConstructorConst(init, constructor);
            handleConstructorInvocation(
                init.target,
                evaluateSuperTypeArguments(
                    init, constructor.enclosingClass.supertype),
                evaluatePositionalArguments(init.arguments),
                evaluateNamedArguments(init.arguments));
          } else if (init is RedirectingInitializer) {
            // Since a redirecting constructor targets a constructor of the same
            // class, we pass the same [typeArguments].
            checkConstructorConst(init, constructor);
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

        for (UnevaluatedConstant constant in env.unevaluatedUnreadConstants) {
          instanceBuilder.unusedArguments.add(extract(constant));
        }
      });
    });
  }

  void checkAssert(AssertStatement statement) {
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
                  typeEnvironment.coreTypes.stringLegacyRawType,
                  message.getType(_staticTypeContext),
                  isNonNullableByDefault));
        }
      }
    } else {
      report(
          statement.condition,
          templateConstEvalInvalidType.withArguments(
              condition,
              typeEnvironment.coreTypes.boolLegacyRawType,
              condition.getType(_staticTypeContext),
              isNonNullableByDefault));
    }
  }

  @override
  Constant visitInvalidExpression(InvalidExpression node) {
    return reportInvalid(node, node.message);
  }

  @override
  Constant visitMethodInvocation(MethodInvocation node) {
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

    final String op = node.name.name;

    // Handle == and != first (it's common between all types). Since `a != b` is
    // parsed as `!(a == b)` it is handled implicitly through ==.
    if (arguments.length == 1 && op == '==') {
      final Constant right = arguments[0];

      if (receiver is NullConstant ||
          receiver is BoolConstant ||
          receiver is IntConstant ||
          receiver is DoubleConstant ||
          receiver is StringConstant ||
          right is NullConstant) {
        // [DoubleConstant] uses [identical] to determine equality, so we need
        // to take the special cases into account.
        return doubleSpecialCases(receiver, right) ??
            makeBoolConstant(receiver == right);
      } else {
        return report(
            node,
            templateConstEvalInvalidEqualsOperandType.withArguments(receiver,
                receiver.getType(_staticTypeContext), isNonNullableByDefault));
      }
    }

    // This is a white-listed set of methods we need to support on constants.
    if (receiver is StringConstant) {
      if (arguments.length == 1) {
        switch (op) {
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
                    typeEnvironment.coreTypes.stringLegacyRawType,
                    other.getType(_staticTypeContext),
                    isNonNullableByDefault));
        }
      }
    } else if (intFolder.isInt(receiver)) {
      if (arguments.length == 0) {
        return canonicalize(intFolder.foldUnaryOperator(node, op, receiver));
      } else if (arguments.length == 1) {
        final Constant other = arguments[0];
        if (intFolder.isInt(other)) {
          return canonicalize(
              intFolder.foldBinaryOperator(node, op, receiver, other));
        } else if (other is DoubleConstant) {
          if ((op == '|' || op == '&' || op == '^') ||
              (op == '<<' || op == '>>' || op == '>>>')) {
            return report(
                node,
                templateConstEvalInvalidBinaryOperandType.withArguments(
                    op,
                    other,
                    typeEnvironment.coreTypes.intLegacyRawType,
                    other.getType(_staticTypeContext),
                    isNonNullableByDefault));
          }
          num receiverValue = (receiver as PrimitiveConstant<num>).value;
          return canonicalize(evaluateBinaryNumericOperation(
              op, receiverValue, other.value, node));
        }
        return report(
            node,
            templateConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.numLegacyRawType,
                other.getType(_staticTypeContext),
                isNonNullableByDefault));
      }
    } else if (receiver is DoubleConstant) {
      if ((op == '|' || op == '&' || op == '^') ||
          (op == '<<' || op == '>>' || op == '>>>')) {
        return report(
            node,
            templateConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.intLegacyRawType,
                receiver.getType(_staticTypeContext),
                isNonNullableByDefault));
      }
      if (arguments.length == 0) {
        switch (op) {
          case 'unary-':
            return canonicalize(new DoubleConstant(-receiver.value));
        }
      } else if (arguments.length == 1) {
        final Constant other = arguments[0];

        if (other is IntConstant || other is DoubleConstant) {
          final num value = (other as PrimitiveConstant<num>).value;
          return canonicalize(
              evaluateBinaryNumericOperation(op, receiver.value, value, node));
        }
        return report(
            node,
            templateConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.numLegacyRawType,
                other.getType(_staticTypeContext),
                isNonNullableByDefault));
      }
    } else if (receiver is BoolConstant) {
      if (arguments.length == 1) {
        final Constant other = arguments[0];
        if (other is BoolConstant) {
          switch (op) {
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
            op, receiver, isNonNullableByDefault));
  }

  @override
  Constant visitLogicalExpression(LogicalExpression node) {
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
                  typeEnvironment.coreTypes.boolLegacyRawType,
                  right.getType(_staticTypeContext),
                  isNonNullableByDefault));
        }
        return report(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                node.operator, left, isNonNullableByDefault));
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
                  typeEnvironment.coreTypes.boolLegacyRawType,
                  right.getType(_staticTypeContext),
                  isNonNullableByDefault));
        }
        return report(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                node.operator, left, isNonNullableByDefault));
      case '??':
        return (left is! NullConstant)
            ? left
            : _evaluateSubexpression(node.right);
      default:
        return report(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                node.operator, left, isNonNullableByDefault));
    }
  }

  @override
  Constant visitConditionalExpression(ConditionalExpression node) {
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
          node.condition,
          templateConstEvalInvalidType.withArguments(
              condition,
              typeEnvironment.coreTypes.boolLegacyRawType,
              condition.getType(_staticTypeContext),
              isNonNullableByDefault));
    }
  }

  @override
  Constant visitPropertyGet(PropertyGet node) {
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
      return canonicalize(intFolder.makeIntConstant(receiver.value.length));
    } else if (shouldBeUnevaluated) {
      return unevaluated(node,
          new PropertyGet(extract(receiver), node.name, node.interfaceTarget));
    } else if (receiver is NullConstant) {
      return report(node, messageConstEvalNullValue);
    }
    return report(
        node,
        templateConstEvalInvalidPropertyGet.withArguments(
            node.name.name, receiver, isNonNullableByDefault));
  }

  @override
  Constant visitLet(Let node) {
    env.addVariableValue(
        node.variable, _evaluateSubexpression(node.variable.initializer));
    return _evaluateSubexpression(node.body);
  }

  @override
  Constant visitVariableGet(VariableGet node) {
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

  /// Computes the constant for [expression] defined in the context of [member].
  ///
  /// This compute the constant as seen in the current evaluation mode even when
  /// the constant is defined in a library compiled with the agnostic evaluation
  /// mode.
  Constant _evaluateExpressionInContext(Member member, Expression expression) {
    StaticTypeContext oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(member, typeEnvironment);
    Constant constant = runInsideContext(member, () {
      Constant constant = _evaluateSubexpression(expression);
      if (_staticTypeContext.nonNullableByDefaultCompiledMode ==
              NonNullableByDefaultCompiledMode.Agnostic &&
          evaluationMode == EvaluationMode.weak) {
        constant = _weakener.visitConstant(constant) ?? constant;
      }
      return constant;
    });
    _staticTypeContext = oldStaticTypeContext;
    return constant;
  }

  @override
  Constant visitStaticGet(StaticGet node) {
    return withNewEnvironment(() {
      final Member target = node.target;
      if (target is Field) {
        if (target.isConst) {
          return _evaluateExpressionInContext(target, target.initializer);
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
        return null;
      }
    });
  }

  @override
  Constant visitStringConcatenation(StringConcatenation node) {
    final List<Object> concatenated = <Object>[new StringBuffer()];
    for (int i = 0; i < node.expressions.length; i++) {
      Constant constant = _evaluateSubexpression(node.expressions[i]);
      if (constant is PrimitiveConstant<Object>) {
        String value;
        if (constant is DoubleConstant && intFolder.isInt(constant)) {
          value = new BigInt.from(constant.value).toString();
        } else {
          value = constant.value.toString();
        }
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
            templateConstEvalInvalidStringInterpolationOperand.withArguments(
                constant, isNonNullableByDefault));
      }
    }
    if (concatenated.length > 1) {
      final List<Expression> expressions =
          new List<Expression>(concatenated.length);
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

  Constant _getFromEnvironmentDefaultValue(Procedure target) {
    VariableDeclaration variable = target.function.namedParameters
        .singleWhere((v) => v.name == 'defaultValue');
    return variable.initializer != null
        ? _evaluateExpressionInContext(target, variable.initializer)
        : nullConstant;
  }

  Constant _handleFromEnvironment(
      Procedure target, StringConstant name, Map<String, Constant> named) {
    String value = environmentDefines[name.value];
    Constant defaultValue = named["defaultValue"];
    if (target.enclosingClass == coreTypes.boolClass) {
      Constant boolConstant;
      if (value == "true") {
        boolConstant = trueConstant;
      } else if (value == "false") {
        boolConstant = falseConstant;
      } else if (defaultValue != null) {
        if (defaultValue is BoolConstant) {
          boolConstant = makeBoolConstant(defaultValue.value);
        } else if (defaultValue is NullConstant) {
          boolConstant = nullConstant;
        } else {
          boolConstant = falseConstant;
        }
      } else {
        boolConstant = _getFromEnvironmentDefaultValue(target);
      }
      return boolConstant;
    } else if (target.enclosingClass == coreTypes.intClass) {
      int intValue = value != null ? int.tryParse(value) : null;
      Constant intConstant;
      if (intValue != null) {
        bool negated = value.startsWith('-');
        intConstant = intFolder.makeIntConstant(intValue, unsigned: !negated);
      } else if (defaultValue != null) {
        if (intFolder.isInt(defaultValue)) {
          intConstant = defaultValue;
        } else {
          intConstant = nullConstant;
        }
      } else {
        intConstant = _getFromEnvironmentDefaultValue(target);
      }
      return canonicalize(intConstant);
    } else if (target.enclosingClass == coreTypes.stringClass) {
      Constant stringConstant;
      if (value != null) {
        stringConstant = canonicalize(new StringConstant(value));
      } else if (defaultValue != null) {
        if (defaultValue is StringConstant) {
          stringConstant = defaultValue;
        } else {
          stringConstant = nullConstant;
        }
      } else {
        stringConstant = _getFromEnvironmentDefaultValue(target);
      }
      return stringConstant;
    }
    throw new UnsupportedError(
        'Unexpected fromEnvironment constructor: $target');
  }

  Constant _handleHasEnvironment(StringConstant name) {
    return environmentDefines.containsKey(name.value)
        ? trueConstant
        : falseConstant;
  }

  @override
  Constant visitStaticInvocation(StaticInvocation node) {
    final Procedure target = node.target;
    final Arguments arguments = node.arguments;
    final List<Constant> positionals = evaluatePositionalArguments(arguments);
    final Map<String, Constant> named = evaluateNamedArguments(arguments);
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new StaticInvocation(
              target, unevaluatedArguments(positionals, named, arguments.types),
              isConst: true));
    }
    if (target.kind == ProcedureKind.Factory) {
      if (target.isConst &&
          target.enclosingLibrary == coreTypes.coreLibrary &&
          positionals.length == 1 &&
          (target.name.name == "fromEnvironment" ||
              target.name.name == "hasEnvironment")) {
        if (environmentDefines != null) {
          // Evaluate environment constant.
          Constant name = positionals.single;
          if (name is StringConstant) {
            if (target.name.name == "fromEnvironment") {
              return _handleFromEnvironment(target, name, named);
            } else {
              return _handleHasEnvironment(name);
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
      final TreeNode parent = target.parent;
      if (parent is Library && parent == coreTypes.coreLibrary) {
        final Constant left = positionals[0];
        final Constant right = positionals[1];

        Constant evaluateIdentical() {
          // Since we canonicalize constants during the evaluation, we can use
          // identical here.
          Constant result = makeBoolConstant(identical(left, right));
          if (evaluationMode == EvaluationMode.agnostic) {
            Constant weakLeft = _weakener.visitConstant(left);
            Constant weakRight = _weakener.visitConstant(right);
            if (weakLeft != null || weakRight != null) {
              Constant weakResult = makeBoolConstant(
                  identical(weakLeft ?? left, weakRight ?? right));
              if (!identical(result, weakResult)) {
                report(node, messageNonAgnosticConstant);
              }
            }
          }
          return result;
        }

        if (targetingJavaScript) {
          // In JavaScript, we lower [identical] to `===`, so we need to take
          // the double special cases into account.
          return doubleSpecialCases(left, right) ?? evaluateIdentical();
        }
        return evaluateIdentical();
      }
    } else if (target.isExtensionMember) {
      return report(node, messageConstEvalExtension);
    }

    String name = target.name.name;
    if (target is Procedure && target.isFactory) {
      if (name.isEmpty) {
        name = target.enclosingClass.name;
      } else {
        name = '${target.enclosingClass.name}.${name}';
      }
    }
    return reportInvalid(node, "Invocation of $name");
  }

  @override
  Constant visitAsExpression(AsExpression node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new AsExpression(extract(constant), env.substituteType(node.type))
            ..isForNonNullableByDefault =
                _staticTypeContext.isNonNullableByDefault);
    }
    return ensureIsSubtype(constant, evaluateDartType(node, node.type), node);
  }

  @override
  Constant visitIsExpression(IsExpression node) {
    final Constant constant = node.operand.accept(this);
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new IsExpression(extract(constant), node.type)
            ..fileOffset = node.fileOffset
            ..flags = node.flags);
    }

    DartType type = evaluateDartType(node, node.type);

    bool performIs(Constant constant, {bool strongMode}) {
      assert(strongMode != null);
      if (strongMode) {
        // In strong checking mode: if e evaluates to a value v and v has
        // runtime type S, an instance check e is T occurring in a legacy
        // library or an opted-in library is evaluated as follows:
        //
        //    If v is null and T is a legacy type,
        //       return LEGACY_SUBTYPE(T, NULL) || LEGACY_SUBTYPE(Object, T)
        //    Otherwise return NNBD_SUBTYPE(S, T)
        if (constant is NullConstant &&
            type.nullability == Nullability.legacy) {
          return typeEnvironment.isSubtypeOf(type, typeEnvironment.nullType,
                  SubtypeCheckMode.ignoringNullabilities) ||
              typeEnvironment.isSubtypeOf(typeEnvironment.objectLegacyRawType,
                  type, SubtypeCheckMode.ignoringNullabilities);
        }
        return isSubtype(constant, type, SubtypeCheckMode.withNullabilities);
      } else {
        // In weak checking mode: if e evaluates to a value v and v has runtime
        // type S, an instance check e is T occurring in a legacy library or an
        // opted-in library is evaluated as follows:
        //
        //    If v is null and T is a legacy type,
        //       return LEGACY_SUBTYPE(T, NULL) || LEGACY_SUBTYPE(Object, T)
        //    If v is null and T is not a legacy type,
        //       return NNBD_SUBTYPE(NULL, T)
        //    Otherwise return LEGACY_SUBTYPE(S, T)
        if (constant is NullConstant) {
          if (type.nullability == Nullability.legacy) {
            // `null is Null` is handled below.
            return typeEnvironment.isSubtypeOf(type, typeEnvironment.nullType,
                    SubtypeCheckMode.ignoringNullabilities) ||
                typeEnvironment.isSubtypeOf(typeEnvironment.objectLegacyRawType,
                    type, SubtypeCheckMode.ignoringNullabilities);
          } else {
            return typeEnvironment.isSubtypeOf(typeEnvironment.nullType, type,
                SubtypeCheckMode.withNullabilities);
          }
        }
        return isSubtype(
            constant, type, SubtypeCheckMode.ignoringNullabilities);
      }
    }

    switch (evaluationMode) {
      case EvaluationMode.strong:
        return makeBoolConstant(performIs(constant, strongMode: true));
      case EvaluationMode.agnostic:
        bool strongResult = performIs(constant, strongMode: true);
        Constant weakConstant = _weakener.visitConstant(constant) ?? constant;
        bool weakResult = performIs(weakConstant, strongMode: false);
        if (strongResult != weakResult) {
          return report(node, messageNonAgnosticConstant);
        }
        return makeBoolConstant(strongResult);
      case EvaluationMode.weak:
        return makeBoolConstant(performIs(constant, strongMode: false));
    }
    throw new UnsupportedError("Unexpected evaluation mode $evaluationMode");
  }

  @override
  Constant visitNot(Not node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (constant is BoolConstant) {
      return makeBoolConstant(constant != trueConstant);
    }
    if (shouldBeUnevaluated) {
      return unevaluated(node, new Not(extract(constant)));
    }
    return report(
        node,
        templateConstEvalInvalidType.withArguments(
            constant,
            typeEnvironment.coreTypes.boolLegacyRawType,
            constant.getType(_staticTypeContext),
            isNonNullableByDefault));
  }

  @override
  Constant visitSymbolLiteral(SymbolLiteral node) {
    final Reference libraryReference =
        node.value.startsWith('_') ? libraryOf(node).reference : null;
    return canonicalize(new SymbolConstant(node.value, libraryReference));
  }

  @override
  Constant visitInstantiation(Instantiation node) {
    final Constant constant = _evaluateSubexpression(node.expression);
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new Instantiation(extract(constant),
              node.typeArguments.map((t) => env.substituteType(t)).toList()));
    }
    if (constant is TearOffConstant) {
      if (node.typeArguments.length ==
          constant.procedure.function.typeParameters.length) {
        final List<DartType> typeArguments =
            convertTypes(evaluateDartTypes(node, node.typeArguments));
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
  Constant visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return report(
        node, templateConstEvalDeferredLibrary.withArguments(node.import.name));
  }

  // Helper methods:

  /// If both constants are DoubleConstant whose values would give different
  /// results from == and [identical], return the result of ==. Otherwise
  /// return null.
  Constant doubleSpecialCases(Constant a, Constant b) {
    if (a is DoubleConstant && b is DoubleConstant) {
      if (a.value.isNaN && b.value.isNaN) return falseConstant;
      if (a.value == 0.0 && b.value == 0.0) return trueConstant;
    }
    return null;
  }

  bool hasPrimitiveEqual(Constant constant) {
    if (intFolder.isInt(constant)) return true;
    DartType type = constant.getType(_staticTypeContext);
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

  bool isSubtype(Constant constant, DartType type, SubtypeCheckMode mode) {
    DartType constantType = constant.getType(_staticTypeContext);
    bool result = typeEnvironment.isSubtypeOf(constantType, type, mode);
    if (targetingJavaScript && !result) {
      if (constantType is InterfaceType &&
          constantType.classNode == typeEnvironment.coreTypes.intClass) {
        // With JS semantics, an integer is also a double.
        result = typeEnvironment.isSubtypeOf(
            new InterfaceType(typeEnvironment.coreTypes.doubleClass,
                constantType.nullability, const <DartType>[]),
            type,
            mode);
      } else if (intFolder.isInt(constant)) {
        // With JS semantics, an integer valued double is also an int.
        result = typeEnvironment.isSubtypeOf(
            new InterfaceType(typeEnvironment.coreTypes.intClass,
                constantType.nullability, const <DartType>[]),
            type,
            mode);
      }
    }
    return result;
  }

  Constant ensureIsSubtype(Constant constant, DartType type, TreeNode node) {
    bool result;
    switch (evaluationMode) {
      case EvaluationMode.strong:
        result = isSubtype(constant, type, SubtypeCheckMode.withNullabilities);
        break;
      case EvaluationMode.agnostic:
        bool strongResult =
            isSubtype(constant, type, SubtypeCheckMode.withNullabilities);
        Constant weakConstant = _weakener.visitConstant(constant) ?? constant;
        bool weakResult = isSubtype(
            weakConstant, type, SubtypeCheckMode.ignoringNullabilities);
        if (strongResult != weakResult) {
          return report(node, messageNonAgnosticConstant);
        }
        result = strongResult;
        break;
      case EvaluationMode.weak:
        result =
            isSubtype(constant, type, SubtypeCheckMode.ignoringNullabilities);
        break;
    }
    if (!result) {
      return report(
          node,
          templateConstEvalInvalidType.withArguments(constant, type,
              constant.getType(_staticTypeContext), isNonNullableByDefault));
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
    // TODO: Once the frontend guarantees that there are no free type variables
    // left over after substitution, we can enable this shortcut again:
    // if (env.isEmpty) return types;
    return types.map((t) => evaluateDartType(node, t)).toList();
  }

  DartType evaluateDartType(TreeNode node, DartType type) {
    final DartType result = env.substituteType(type);

    if (!isInstantiated(result)) {
      return report(
          node,
          templateConstEvalFreeTypeParameter.withArguments(
              type, isNonNullableByDefault));
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
    final List<Expression> positional =
        new List<Expression>(positionalArgs.length);
    final List<NamedExpression> named =
        new List<NamedExpression>(namedArgs.length);
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

  T withNewInstanceBuilder<T>(
      Class klass, List<DartType> typeArguments, T fn()) {
    InstanceBuilder old = instanceBuilder;
    try {
      instanceBuilder = new InstanceBuilder(this, klass, typeArguments);
      return fn();
    } finally {
      instanceBuilder = old;
    }
  }

  T withNewEnvironment<T>(T fn()) {
    final EvaluationEnvironment oldEnv = env;
    try {
      env = new EvaluationEnvironment();
      return fn();
    } finally {
      env = oldEnv;
    }
  }

  /// Binary operation between two operands, at least one of which is a double.
  Constant evaluateBinaryNumericOperation(
      String op, num a, num b, TreeNode node) {
    switch (op) {
      case '+':
        return new DoubleConstant(a + b);
      case '-':
        return new DoubleConstant(a - b);
      case '*':
        return new DoubleConstant(a * b);
      case '/':
        return new DoubleConstant(a / b);
      case '~/':
        if (b == 0) {
          return report(
              node, templateConstEvalZeroDivisor.withArguments(op, '$a'));
        }
        return intFolder.truncatingDivide(node, a, b);
      case '%':
        return new DoubleConstant(a % b);
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

  final List<Expression> unusedArguments = <Expression>[];

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
    assert(unusedArguments.isEmpty);
    return new InstanceConstant(klass.reference, typeArguments, fieldValues);
  }

  InstanceCreation buildUnevaluatedInstance() {
    final Map<Reference, Expression> fieldValues = <Reference, Expression>{};
    fields.forEach((Field field, Constant value) {
      fieldValues[field.reference] = evaluator.extract(value);
    });
    return new InstanceCreation(
        klass.reference, typeArguments, fieldValues, asserts, unusedArguments);
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

  /// The variables that hold unevaluated constants.
  ///
  /// Variables are removed from this set when looked up, leaving only the
  /// unread variables at the end.
  final Set<VariableDeclaration> _unreadUnevaluatedVariables =
      new Set<VariableDeclaration>();

  /// Whether the current environment is empty.
  bool get isEmpty => _typeVariables.isEmpty && _variables.isEmpty;

  void addTypeParameterValue(TypeParameter parameter, DartType value) {
    assert(!_typeVariables.containsKey(parameter));
    _typeVariables[parameter] = value;
  }

  void addVariableValue(VariableDeclaration variable, Constant value) {
    _variables[variable] = value;
    if (value is UnevaluatedConstant) {
      _unreadUnevaluatedVariables.add(variable);
    }
  }

  DartType lookupParameterValue(TypeParameter parameter) {
    final DartType value = _typeVariables[parameter];
    assert(value != null);
    return value;
  }

  Constant lookupVariable(VariableDeclaration variable) {
    Constant value = _variables[variable];
    if (value is UnevaluatedConstant) {
      _unreadUnevaluatedVariables.remove(variable);
    }
    return value;
  }

  /// The unevaluated constants of variables that were never read.
  Iterable<UnevaluatedConstant> get unevaluatedUnreadConstants {
    if (_unreadUnevaluatedVariables.isEmpty) return const [];
    return _unreadUnevaluatedVariables.map<UnevaluatedConstant>(
        (VariableDeclaration variable) => _variables[variable]);
  }

  DartType substituteType(DartType type) {
    if (_typeVariables.isEmpty) return type;
    return substitute(type, _typeVariables);
  }
}

class RedundantFileUriExpressionRemover extends Transformer {
  Uri currentFileUri = null;

  TreeNode visitFileUriExpression(FileUriExpression node) {
    if (node.fileUri == currentFileUri) {
      return node.expression.accept(this);
    } else {
      Uri oldFileUri = currentFileUri;
      currentFileUri = node.fileUri;
      node.expression = node.expression.accept(this) as Expression
        ..parent = node;
      currentFileUri = oldFileUri;
      return node;
    }
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

  @override
  bool defaultDartType(DartType node) {
    throw 'A visitor method seems to be unimplemented!';
  }

  @override
  bool visitInvalidType(InvalidType node) => true;

  @override
  bool visitDynamicType(DynamicType node) => true;

  @override
  bool visitVoidType(VoidType node) => true;

  @override
  bool visitBottomType(BottomType node) => true;

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return _availableVariables.contains(node.parameter);
  }

  @override
  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments
        .every((DartType typeArgument) => typeArgument.accept(this));
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    return node.typeArgument.accept(this);
  }

  @override
  bool visitFunctionType(FunctionType node) {
    final List<TypeParameter> parameters = node.typeParameters;
    _availableVariables.addAll(parameters);
    final bool result = node.returnType.accept(this) &&
        node.positionalParameters.every((p) => p.accept(this)) &&
        node.namedParameters.every((p) => p.type.accept(this));
    _availableVariables.removeAll(parameters);
    return result;
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return node.unalias.accept(this);
  }

  @override
  bool visitNeverType(NeverType node) => true;
}

bool _isFormalParameter(VariableDeclaration variable) {
  final TreeNode parent = variable.parent;
  if (parent is FunctionNode) {
    return parent.positionalParameters.contains(variable) ||
        parent.namedParameters.contains(variable);
  }
  return false;
}
