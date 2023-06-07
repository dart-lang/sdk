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
/// Due to the lack information which is only available in the front-end,
/// this validation is incomplete (e.g. whether an integer literal used the
/// hexadecimal syntax or not).
///
/// Furthermore due to the lowering of certain constructs in the front-end
/// (e.g. '??') we need to support a super-set of the normal constant expression
/// language.  Issue(http://dartbug.com/31799)
library fasta.constant_evaluator;

import 'dart:io' as io;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/const_canonical_type.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/norm.dart';
import 'package:kernel/src/printer.dart'
    show AstPrinter, AstTextStrategy, defaultAstTextStrategy;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/target/targets.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';

import '../../api_prototype/lowering_predicates.dart';
import '../../base/nnbd_mode.dart';
import '../fasta_codes.dart';

import '../type_inference/delayed_expressions.dart';
import '../type_inference/external_ast_helper.dart';
import '../type_inference/matching_cache.dart';
import '../type_inference/matching_expressions.dart';
import 'constant_int_folder.dart';
import 'exhaustiveness.dart';
import 'static_weak_references.dart' show StaticWeakReferences;

part 'constant_collection_builders.dart';

Component transformComponent(
    Target target,
    Component component,
    Map<String, String> environmentDefines,
    ErrorReporter errorReporter,
    EvaluationMode evaluationMode,
    {required bool evaluateAnnotations,
    required bool desugarSets,
    required bool enableTripleShift,
    required bool enableConstFunctions,
    required bool enableConstructorTearOff,
    required bool errorOnUnevaluatedConstant,
    CoreTypes? coreTypes,
    ClassHierarchy? hierarchy,
    ExhaustivenessDataForTesting? exhaustivenessDataForTesting}) {
  // ignore: unnecessary_null_comparison
  assert(evaluateAnnotations != null);
  // ignore: unnecessary_null_comparison
  assert(desugarSets != null);
  // ignore: unnecessary_null_comparison
  assert(enableTripleShift != null);
  // ignore: unnecessary_null_comparison
  assert(enableConstFunctions != null);
  // ignore: unnecessary_null_comparison
  assert(errorOnUnevaluatedConstant != null);
  // ignore: unnecessary_null_comparison
  assert(enableConstructorTearOff != null);
  coreTypes ??= new CoreTypes(component);
  hierarchy ??= new ClassHierarchy(component, coreTypes);

  final TypeEnvironment typeEnvironment =
      new TypeEnvironment(coreTypes, hierarchy);

  transformLibraries(component, component.libraries, target, environmentDefines,
      typeEnvironment, errorReporter, evaluationMode,
      enableTripleShift: enableTripleShift,
      enableConstFunctions: enableConstFunctions,
      errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
      evaluateAnnotations: evaluateAnnotations,
      enableConstructorTearOff: enableConstructorTearOff);
  return component;
}

ConstantEvaluationData transformLibraries(
    Component component,
    List<Library> libraries,
    Target target,
    Map<String, String>? environmentDefines,
    TypeEnvironment typeEnvironment,
    ErrorReporter errorReporter,
    EvaluationMode evaluationMode,
    {required bool evaluateAnnotations,
    required bool enableTripleShift,
    required bool enableConstFunctions,
    required bool errorOnUnevaluatedConstant,
    required bool enableConstructorTearOff,
    ExhaustivenessDataForTesting? exhaustivenessDataForTesting}) {
  // ignore: unnecessary_null_comparison
  assert(evaluateAnnotations != null);
  // ignore: unnecessary_null_comparison
  assert(enableTripleShift != null);
  // ignore: unnecessary_null_comparison
  assert(enableConstFunctions != null);
  // ignore: unnecessary_null_comparison
  assert(errorOnUnevaluatedConstant != null);
  // ignore: unnecessary_null_comparison
  assert(enableConstructorTearOff != null);
  final ConstantsTransformer constantsTransformer = new ConstantsTransformer(
      target,
      environmentDefines,
      evaluateAnnotations,
      enableTripleShift,
      enableConstFunctions,
      enableConstructorTearOff,
      errorOnUnevaluatedConstant,
      component,
      typeEnvironment,
      errorReporter,
      evaluationMode,
      exhaustivenessDataForTesting: exhaustivenessDataForTesting);
  for (final Library library in libraries) {
    constantsTransformer.convertLibrary(library);
  }

  return new ConstantEvaluationData(
      constantsTransformer.constantEvaluator.getConstantCoverage(),
      constantsTransformer.constantEvaluator.visitedLibraries);
}

void transformProcedure(
    Procedure procedure,
    Target target,
    Component component,
    Map<String, String>? environmentDefines,
    TypeEnvironment typeEnvironment,
    ErrorReporter errorReporter,
    EvaluationMode evaluationMode,
    {required bool evaluateAnnotations,
    required bool enableTripleShift,
    required bool enableConstFunctions,
    required bool enableConstructorTearOff,
    required bool errorOnUnevaluatedConstant}) {
  // ignore: unnecessary_null_comparison
  assert(evaluateAnnotations != null);
  // ignore: unnecessary_null_comparison
  assert(enableTripleShift != null);
  // ignore: unnecessary_null_comparison
  assert(enableConstFunctions != null);
  // ignore: unnecessary_null_comparison
  assert(errorOnUnevaluatedConstant != null);
  // ignore: unnecessary_null_comparison
  assert(enableConstructorTearOff != null);
  final ConstantsTransformer constantsTransformer = new ConstantsTransformer(
      target,
      environmentDefines,
      evaluateAnnotations,
      enableTripleShift,
      enableConstFunctions,
      enableConstructorTearOff,
      errorOnUnevaluatedConstant,
      component,
      typeEnvironment,
      errorReporter,
      evaluationMode);
  constantsTransformer.visitProcedure(procedure, null);
}

enum EvaluationMode {
  weak,
  agnostic,
  strong;

  static EvaluationMode fromNnbdMode(NnbdMode nnbdMode) {
    switch (nnbdMode) {
      case NnbdMode.Weak:
        return EvaluationMode.weak;
      case NnbdMode.Strong:
        return EvaluationMode.strong;
      case NnbdMode.Agnostic:
        return EvaluationMode.agnostic;
    }
  }
}

class ConstantWeakener extends ComputeOnceConstantVisitor<Constant?> {
  ConstantEvaluator _evaluator;

  ConstantWeakener(this._evaluator);

  @override
  Constant? processValue(Constant node, Constant? value) {
    if (value != null) {
      value = _evaluator.canonicalize(value);
    }
    return value;
  }

  @override
  Constant? defaultConstant(Constant node) => throw new UnsupportedError(
      "Unhandled constant ${node} (${node.runtimeType})");

  @override
  Constant? visitNullConstant(NullConstant node) => null;

  @override
  Constant? visitBoolConstant(BoolConstant node) => null;

  @override
  Constant? visitIntConstant(IntConstant node) => null;

  @override
  Constant? visitDoubleConstant(DoubleConstant node) => null;

  @override
  Constant? visitStringConstant(StringConstant node) => null;

  @override
  Constant? visitSymbolConstant(SymbolConstant node) => null;

  @override
  Constant? visitMapConstant(MapConstant node) {
    DartType? keyType = computeConstCanonicalType(
        node.keyType, _evaluator.coreTypes,
        isNonNullableByDefault: _evaluator.isNonNullableByDefault);
    DartType? valueType = computeConstCanonicalType(
        node.valueType, _evaluator.coreTypes,
        isNonNullableByDefault: _evaluator.isNonNullableByDefault);
    List<ConstantMapEntry>? entries;
    for (int index = 0; index < node.entries.length; index++) {
      ConstantMapEntry entry = node.entries[index];
      Constant? key = visitConstant(entry.key);
      Constant? value = visitConstant(entry.value);
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
  Constant? visitListConstant(ListConstant node) {
    DartType? typeArgument = computeConstCanonicalType(
        node.typeArgument, _evaluator.coreTypes,
        isNonNullableByDefault: _evaluator.isNonNullableByDefault);
    List<Constant>? entries;
    for (int index = 0; index < node.entries.length; index++) {
      Constant? entry = visitConstant(node.entries[index]);
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
  Constant? visitSetConstant(SetConstant node) {
    DartType? typeArgument = computeConstCanonicalType(
        node.typeArgument, _evaluator.coreTypes,
        isNonNullableByDefault: _evaluator.isNonNullableByDefault);
    List<Constant>? entries;
    for (int index = 0; index < node.entries.length; index++) {
      Constant? entry = visitConstant(node.entries[index]);
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
  Constant? visitRecordConstant(RecordConstant node) {
    RecordType? recordType = computeConstCanonicalType(
            node.recordType, _evaluator.coreTypes,
            isNonNullableByDefault: _evaluator.isNonNullableByDefault)
        as RecordType?;
    List<Constant>? positional;
    for (int index = 0; index < node.positional.length; index++) {
      Constant? field = visitConstant(node.positional[index]);
      if (field != null) {
        positional ??= node.positional.toList(growable: false);
        positional[index] = field;
      }
    }
    Map<String, Constant>? named;
    for (MapEntry<String, Constant> entry in node.named.entries) {
      Constant? value = visitConstant(entry.value);
      if (value != null) {
        named ??= new Map<String, Constant>.of(node.named);
        named[entry.key] = value;
      }
    }
    if (recordType != null || positional != null || named != null) {
      return new RecordConstant(positional ?? node.positional,
          named ?? node.named, recordType ?? node.recordType);
    }
    return null;
  }

  @override
  Constant? visitInstanceConstant(InstanceConstant node) {
    List<DartType>? typeArguments;
    for (int index = 0; index < node.typeArguments.length; index++) {
      DartType? typeArgument = computeConstCanonicalType(
          node.typeArguments[index], _evaluator.coreTypes,
          isNonNullableByDefault: _evaluator.isNonNullableByDefault);
      if (typeArgument != null) {
        typeArguments ??= node.typeArguments.toList(growable: false);
        typeArguments[index] = typeArgument;
      }
    }
    Map<Reference, Constant>? fieldValues;
    for (MapEntry<Reference, Constant> entry in node.fieldValues.entries) {
      Reference reference = entry.key;
      Constant? value = visitConstant(entry.value);
      if (value != null) {
        fieldValues ??= new Map<Reference, Constant>.of(node.fieldValues);
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
  Constant? visitInstantiationConstant(InstantiationConstant node) {
    List<DartType>? types;
    for (int index = 0; index < node.types.length; index++) {
      DartType? type = computeConstCanonicalType(
          node.types[index], _evaluator.coreTypes,
          isNonNullableByDefault: _evaluator.isNonNullableByDefault);
      if (type != null) {
        types ??= node.types.toList(growable: false);
        types[index] = type;
      }
    }
    if (types != null) {
      return new InstantiationConstant(node.tearOffConstant, types);
    }
    return null;
  }

  @override
  Constant? visitStaticTearOffConstant(StaticTearOffConstant node) => null;

  @override
  Constant? visitTypeLiteralConstant(TypeLiteralConstant node) {
    DartType? type = computeConstCanonicalType(node.type, _evaluator.coreTypes,
        isNonNullableByDefault: _evaluator.isNonNullableByDefault);
    if (type != null) {
      return new TypeLiteralConstant(type);
    }
    return null;
  }

  @override
  Constant? visitUnevaluatedConstant(UnevaluatedConstant node) => null;
}

class ConstantsTransformer extends RemovingTransformer {
  final ConstantsBackend backend;
  final ConstantEvaluator constantEvaluator;
  final TypeEnvironment typeEnvironment;
  StaticTypeContext? _staticTypeContext;

  final bool evaluateAnnotations;
  final bool enableTripleShift;
  final bool enableConstFunctions;
  final bool enableConstructorTearOff;
  final bool errorOnUnevaluatedConstant;
  final bool isLateLocalLoweringEnabled;

  final ExhaustivenessDataForTesting? _exhaustivenessDataForTesting;

  /// Cache used for checking exhaustiveness.
  CfeExhaustivenessCache? _exhaustivenessCache;

  ConstantsTransformer(
      Target target,
      Map<String, String>? environmentDefines,
      this.evaluateAnnotations,
      this.enableTripleShift,
      this.enableConstFunctions,
      this.enableConstructorTearOff,
      this.errorOnUnevaluatedConstant,
      Component component,
      this.typeEnvironment,
      ErrorReporter errorReporter,
      EvaluationMode evaluationMode,
      {ExhaustivenessDataForTesting? exhaustivenessDataForTesting})
      : this.backend = target.constantsBackend,
        this.isLateLocalLoweringEnabled = target.isLateLocalLoweringEnabled(
            hasInitializer: true, isFinal: true, isPotentiallyNullable: true),
        constantEvaluator = new ConstantEvaluator(
            target.dartLibrarySupport,
            target.constantsBackend,
            component,
            environmentDefines,
            typeEnvironment,
            errorReporter,
            enableTripleShift: enableTripleShift,
            enableConstFunctions: enableConstFunctions,
            errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
            evaluationMode: evaluationMode),
        _exhaustivenessDataForTesting = exhaustivenessDataForTesting {}

  /// Whether to preserve constant [Field]s. All use-sites will be rewritten.
  bool get keepFields => backend.keepFields;

  /// Whether to preserve constant [VariableDeclaration]s. All use-sites will be
  /// rewritten.
  bool get keepLocals => backend.keepLocals;

  StaticTypeContext get staticTypeContext => _staticTypeContext!;

  Library get currentLibrary => staticTypeContext.enclosingLibrary;

  // Transform the library/class members:

  void convertLibrary(Library library) {
    _staticTypeContext =
        new StaticTypeContext.forAnnotations(library, typeEnvironment);

    _exhaustivenessCache =
        new CfeExhaustivenessCache(constantEvaluator, library);

    transformAnnotations(library.annotations, library);

    transformLibraryDependencyList(library.dependencies, library);
    transformLibraryPartList(library.parts, library);
    transformTypedefList(library.typedefs, library);
    transformClassList(library.classes, library);
    transformExtensionList(library.extensions, library);
    transformInlineClassList(library.inlineClasses, library);
    transformProcedureList(library.procedures, library);
    transformFieldList(library.fields, library);

    if (!keepFields) {
      // The transformer API does not iterate over `Library.additionalExports`,
      // so we manually delete the references to shaken nodes.
      library.additionalExports.removeWhere((Reference reference) {
        return reference.node is Field && reference.canonicalName == null;
      });
    }
    _staticTypeContext = null;
    _exhaustivenessCache = null;
  }

  @override
  LibraryPart visitLibraryPart(LibraryPart node, TreeNode? removalSentinel) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  @override
  LibraryDependency visitLibraryDependency(
      LibraryDependency node, TreeNode? removalSentinel) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  @override
  Class visitClass(Class node, TreeNode? removalSentinel) {
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext.forAnnotations(
        node.enclosingLibrary, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformFieldList(node.fields, node);
      transformTypeParameterList(node.typeParameters, node);
      transformConstructorList(node.constructors, node);
      transformProcedureList(node.procedures, node);
      transformRedirectingFactoryList(node.redirectingFactories, node);
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  Extension visitExtension(Extension node, TreeNode? removalSentinel) {
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext.forAnnotations(
        node.enclosingLibrary, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformTypeParameterList(node.typeParameters, node);
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  InlineClass visitInlineClass(InlineClass node, TreeNode? removalSentinel) {
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext.forAnnotations(
        node.enclosingLibrary, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformTypeParameterList(node.typeParameters, node);
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  int _matchCacheIndex = 0;

  MatchingCache createMatchingCache() {
    return new MatchingCache(_matchCacheIndex++, typeEnvironment.coreTypes,
        useLowering: isLateLocalLoweringEnabled);
  }

  @override
  Procedure visitProcedure(Procedure node, TreeNode? removalSentinel) {
    _matchCacheIndex = 0;
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      node.function = transform(node.function)..parent = node;
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  Constructor visitConstructor(Constructor node, TreeNode? removalSentinel) {
    _matchCacheIndex = 0;
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformInitializerList(node.initializers, node);
      node.function = transform(node.function)..parent = node;
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  Typedef visitTypedef(Typedef node, TreeNode? removalSentinel) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformTypeParameterList(node.typeParameters, node);
    });
    return node;
  }

  @override
  RedirectingFactory visitRedirectingFactory(
      RedirectingFactory node, TreeNode? removalSentinel) {
    // Currently unreachable as the compiler doesn't produce
    // RedirectingFactoryConstructor.
    _matchCacheIndex = 0;
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      node.function = transform(node.function)..parent = node;
    });
    _staticTypeContext = oldStaticTypeContext;
    return node;
  }

  @override
  TypeParameter visitTypeParameter(
      TypeParameter node, TreeNode? removalSentinel) {
    transformAnnotations(node.annotations, node);
    return node;
  }

  void transformAnnotations(List<Expression> nodes, Annotatable parent) {
    if (evaluateAnnotations && nodes.length > 0) {
      transformExpressions(nodes, parent);

      if (StaticWeakReferences.isAnnotatedWithWeakReferencePragma(
          parent, typeEnvironment.coreTypes)) {
        StaticWeakReferences.validateWeakReferenceDeclaration(
            parent, constantEvaluator.errorReporter);
      }
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
  FunctionNode visitFunctionNode(FunctionNode node, TreeNode? removalSentinel) {
    transformTypeParameterList(node.typeParameters, node);
    final int positionalParameterCount = node.positionalParameters.length;
    for (int i = 0; i < positionalParameterCount; ++i) {
      final VariableDeclaration variable = node.positionalParameters[i];
      transformAnnotations(variable.annotations, variable);
      Expression? initializer = variable.initializer;
      if (initializer != null) {
        variable.initializer =
            evaluateAndTransformWithContext(variable, initializer)
              ..parent = variable;
      }
    }
    for (final VariableDeclaration variable in node.namedParameters) {
      transformAnnotations(variable.annotations, variable);
      Expression? initializer = variable.initializer;
      if (initializer != null) {
        variable.initializer =
            evaluateAndTransformWithContext(variable, initializer)
              ..parent = variable;
      }
    }
    if (node.body != null) {
      node.body = transform(node.body!)..parent = node;
    }
    return node;
  }

  @override
  TreeNode visitFunctionDeclaration(
      FunctionDeclaration node, TreeNode? removalSentinel) {
    if (enableConstFunctions) {
      // ignore: unnecessary_null_comparison
      if (node.function != null) {
        node.function = transform(node.function)..parent = node;
      }
      constantEvaluator.env.addVariableValue(
          node.variable, new FunctionValue(node.function, null));
    } else {
      return super.visitFunctionDeclaration(node, removalSentinel);
    }
    return node;
  }

  @override
  TreeNode visitVariableDeclaration(
      VariableDeclaration node, TreeNode? removalSentinel) {
    transformAnnotations(node.annotations, node);

    Expression? initializer = node.initializer;
    if (initializer != null) {
      if (node.isConst) {
        final Constant constant = evaluateWithContext(node, initializer);
        constantEvaluator.env.addVariableValue(node, constant);
        initializer = node.initializer =
            makeConstantExpression(constant, initializer)..parent = node;

        // If this constant is inlined, remove it.
        if (!keepLocals && shouldInline(initializer)) {
          if (constant is! UnevaluatedConstant) {
            // If the constant is unevaluated we need to keep the expression,
            // so that, in the case the constant contains error but the local
            // is unused, the error will still be reported.
            return removalSentinel /*!*/ ?? node;
          }
        }
      } else {
        node.initializer = transform(initializer)..parent = node;
      }
    }
    return node;
  }

  @override
  TreeNode visitField(Field node, TreeNode? removalSentinel) {
    _matchCacheIndex = 0;
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(node, typeEnvironment);
    TreeNode result = constantEvaluator.withNewEnvironment(() {
      Expression? initializer = node.initializer;
      if (node.isConst) {
        transformAnnotations(node.annotations, node);
        initializer = node.initializer =
            evaluateAndTransformWithContext(node, initializer!)..parent = node;

        // If this constant is inlined, remove it.
        if (!keepFields && shouldInline(initializer)) {
          return removalSentinel!;
        }
      } else {
        transformAnnotations(node.annotations, node);
        if (initializer != null) {
          node.initializer = transform(initializer)..parent = node;
        }
      }
      return node;
    });
    _staticTypeContext = oldStaticTypeContext;
    return result;
  }

  // Handle use-sites of constants (and "inline" constant expressions):

  @override
  TreeNode visitSymbolLiteral(SymbolLiteral node, TreeNode? removalSentinel) {
    return makeConstantExpression(
        constantEvaluator.evaluate(staticTypeContext, node), node);
  }

  bool _isNull(Expression node) {
    return node is NullLiteral ||
        node is ConstantExpression && node.constant is NullConstant;
  }

  @override
  TreeNode visitEqualsCall(EqualsCall node, TreeNode? removalSentinel) {
    Expression left = transform(node.left);
    Expression right = transform(node.right);
    if (_isNull(left)) {
      return new EqualsNull(right)..fileOffset = node.fileOffset;
    } else if (_isNull(right)) {
      return new EqualsNull(left)..fileOffset = node.fileOffset;
    }
    node.left = left..parent = node;
    node.right = right..parent = node;
    return node;
  }

  @override
  TreeNode visitStaticGet(StaticGet node, TreeNode? removalSentinel) {
    final Member target = node.target;
    if (target is Field && target.isConst) {
      // Make sure the initializer is evaluated first.
      StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
      _staticTypeContext = new StaticTypeContext(target, typeEnvironment);
      target.initializer =
          evaluateAndTransformWithContext(target, target.initializer!)
            ..parent = target;
      _staticTypeContext = oldStaticTypeContext;
      if (shouldInline(target.initializer!)) {
        return evaluateAndTransformWithContext(node, node);
      }
    } else if (target is Procedure && target.kind == ProcedureKind.Method) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitStaticGet(node, removalSentinel);
  }

  @override
  TreeNode visitStaticTearOff(StaticTearOff node, TreeNode? removalSentinel) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  TreeNode visitConstructorTearOff(
      ConstructorTearOff node, TreeNode? removalSentinel) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  TreeNode visitRedirectingFactoryTearOff(
      RedirectingFactoryTearOff node, TreeNode? removalSentinel) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  TreeNode visitTypedefTearOff(TypedefTearOff node, TreeNode? removalSentinel) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  TreeNode visitInstantiation(Instantiation node, TreeNode? removalSentinel) {
    Instantiation result =
        super.visitInstantiation(node, removalSentinel) as Instantiation;
    Expression expression = result.expression;
    if (expression is StaticGet && expression.target.isConst) {
      // Handle [StaticGet] of constant fields also when these are not inlined.
      expression = (expression.target as Field).initializer!;
    } else if (expression is VariableGet && expression.variable.isConst) {
      // Handle [VariableGet] of constant locals also when these are not
      // inlined.
      expression = expression.variable.initializer!;
    }
    if (expression is ConstantExpression) {
      if (result.typeArguments.every(isInstantiated)) {
        return evaluateAndTransformWithContext(node, result);
      }
    }
    return node;
  }

  @override
  TreeNode visitSwitchCase(SwitchCase node, TreeNode? removalSentinel) {
    transformExpressions(node.expressions, node);
    return super.visitSwitchCase(node, removalSentinel);
  }

  @override
  TreeNode visitBlock(Block node, TreeNode? removalSentinel) {
    int storeIndex = 0;
    List<Statement> statements = node.statements;
    for (int i = 0; i < statements.length; ++i) {
      Statement statement = statements[i];
      Statement? result = transformOrRemove(statement, dummyStatement);
      if (result != null) {
        if (result is _InlinedBlock) {
          // Inline statements replaced by blocks.
          if (statements == node.statements) {
            // Make a copy of the original to avoid overwriting yet unvisited
            // statements.
            statements = new List<Statement>.of(statements, growable: false);
          }
          for (Statement statement in result.statements) {
            if (storeIndex >= node.statements.length) {
              node.statements.add(statement);
            } else {
              node.statements[storeIndex] = statement;
            }
            statement.parent = node;
            ++storeIndex;
          }
        } else {
          if (storeIndex >= node.statements.length) {
            node.statements.add(result);
          } else {
            node.statements[storeIndex] = result;
          }
          result.parent = node;
          ++storeIndex;
        }
      }
    }
    if (storeIndex < node.statements.length) {
      node.statements.length = storeIndex;
    }
    return node;
  }

  Map<PatternSwitchStatement, _PatternSwitchStatementInfo>
      _currentPatternSwitchStatementInfoMap = {};

  @override
  TreeNode visitContinueSwitchStatement(
      ContinueSwitchStatement node, TreeNode? removalSentinel) {
    SwitchCase targetSwitchCase = node.target;
    if (targetSwitchCase is PatternSwitchCase) {
      // This is continue to a pattern switch case.
      PatternSwitchStatement patternSwitchStatement =
          targetSwitchCase.parent as PatternSwitchStatement;
      _PatternSwitchStatementInfo? info =
          _currentPatternSwitchStatementInfoMap[patternSwitchStatement];
      if (info != null) {
        // The pattern switch statement has continue statements and its switch
        // case pattern-guards do not consist solely of guard-less constant
        // patterns whose value has a primitive equals method.
        PatternSwitchCase sourceSwitchCase = info.currentSwitchCase!;
        int? sourceCaseIndex = info.switchCaseIndexMap[sourceSwitchCase];
        if (sourceCaseIndex == null) {
          // The enclosing switch case is _not_ a continue target, so we need
          // to replace the continue with setting the switch index variable and
          // a jump to the generated switch statement.
          int targetCaseIndex = info.switchCaseIndexMap[targetSwitchCase]!;
          return new _InlinedBlock([
            createExpressionStatement(createVariableSet(
                info.switchIndexVariable,
                createIntLiteral(typeEnvironment.coreTypes, targetCaseIndex,
                    fileOffset: node.fileOffset),
                fileOffset: node.fileOffset)),
            createBreakStatement(info.innerLabeledStatement,
                fileOffset: node.fileOffset),
          ])
            ..fileOffset = node.fileOffset;
        }
      }
    }
    return node;
  }

  @override
  TreeNode visitPatternSwitchStatement(
      PatternSwitchStatement node, TreeNode? removalSentinel) {
    // The pattern switch statement has three different lowerings:
    //
    // 1) If the switch case pattern-guards consists solely of guard-less
    //    constant patterns whose value has a primitive equals method. For this
    //    case we generate switch using an ordinary switch statement.
    //
    //    The pattern switch statement _can_ contain continue switch statements.
    //
    //    For instance:
    //
    //      enum E { a, b, c }
    //      method(E e) {
    //        switch (e) { // PatternSwitchStatement
    //          case E.a:
    //            print('a');
    //            continue label;
    //          case E.b:
    //            print('b');
    //          label:
    //          case E.c:
    //            print('c');
    //        }
    //      }
    //
    //    is encoded as
    //
    //      enum E { a, b }
    //      method(E e) {
    //        #outer:
    //        switch (e) { // SwitchStatement
    //          case E.a:
    //            print('a');
    //            continue label;
    //          case E.a:
    //            print('a');
    //            break #outer;
    //          label:
    //          case E.b:
    //            print('b');
    //        }
    //      }
    //
    // 2) Otherwise, if the pattern switch statement does _not_ contain continue
    //    switch statements, we generate a sequence of blocks containing each
    //    case, surrounded by labeled block.
    //
    //    For instance:
    //
    //      method(o) {
    //        switch (o) { // PatternSwitchStatement
    //          case [var a]:
    //            print(a);
    //          case {1: var a}:
    //            print(a);
    //        }
    //      }
    //
    //    is encoded as
    //
    //      method(o) {
    //        #outer: {
    //          { // case [var a]:
    //            var a;
    //            if (o is List<dynamic> &&
    //                o.length == 1 &&
    //                let # = a = o[0] in true) {
    //              print(a);
    //              break #outer;
    //            }
    //          }
    //          { // case {1: var a}:
    //            var a;
    //            if (o is Map<dynamic, dynamic> &&
    //                o.length == 1 &&
    //                o.containsKey(1) &&
    //                let # = a = o[1] in true) {
    //              print(a);
    //              break #outer;
    //            }
    //          }
    //        } // end of #outer
    //      }
    //
    // 3) Otherwise, we generate a sequence of blocks containing each case,
    //    surrounded by labeled block, followed by a switch statement containing
    //    the bodies for switch cases that are targets of a continue.
    //
    //    For instance:
    //
    //      method(o) {
    //        switch (o) { // PatternSwitchStatement
    //          case [var a]:
    //          case [_, var a]:
    //            print(a);
    //            continue label1;
    //          case {1: var a}:
    //            print(a);
    //          label1:
    //          case 'b':
    //            print('b');
    //            continue label2;
    //          label2:
    //          case 'c':
    //            print('c');
    //          case 'd':
    //            print('d');
    //        }
    //      }
    //
    //    is encoded as
    //
    //      method(o) {
    //        #outer: {
    //          int #switchIndex = -1;
    //          #inner: {
    //            { // case [var a]:
    //              var a#0;
    //              var a#1;
    //              var #t1;
    //              if (o is List<dynamic> &&
    //                  o.length == 1 &&
    //                  let # = #t1 = a = o[0] in true ||
    //                  o is List<dynamic &&
    //                  o.length == 2 &&
    //                  let # = #t1 = a = o[1] in true) {
    //                var a = #t1;
    //                print(a);
    //                #switchIndex = 0;
    //                break #inner;
    //              }
    //            }
    //            { // case {1: var a}:
    //              var a;
    //              if (o is Map<dynamic, dynamic> &&
    //                  o.length == 1 &&
    //                  o.containsKey(1) &&
    //                  let a = o[1] in true) {
    //                print(a);
    //                break #outer;
    //              }
    //            }
    //            { // case 'b':
    //              if ('b' == o) {
    //                #switchIndex = 0;
    //                break #inner;
    //              }
    //            }
    //            { // case 'c':
    //              if ('c'' == o) {
    //                #switchIndex = 1;
    //                break #inner;
    //              }
    //            }
    //            { // case 'd':
    //              if ('d' == o) {
    //                print('d');
    //                break #outer;
    //              }
    //            }
    //          } // end of #inner
    //          switch (#switchIndex) {
    //            label1:
    //            case 0: // body for case 'b':
    //              print('b');
    //              continue label2;
    //            label2:
    //            case 1: // body for case 'c':
    //              print('c');
    //              break #outer;
    //          }
    //        } // end of #outer
    //      }

    // Instead calling `super.visitPatternSwitchStatement` to transform the
    // children of the [node], we transform its expression and the children of
    // its [PatternSwitchCase]s directly to collect information about continue
    // statements.
    node.expression = transform(node.expression)..parent = node;

    DartType scrutineeType = node.expressionType;

    // If `true`, the switch expressions consists solely of guard-less constant
    // patterns whose value has a primitive equals method. For this case we
    // generate switch using an ordinary switch statement.
    bool primitiveEqualConstantsOnly = true;
    bool hasContinue = false;

    Map<PatternSwitchCase, int> switchCaseIndex = {};
    // TODO(johnniwinther): Use `PatternSwitchStatement.hasDefault` instead.
    bool hasDefault = false;
    for (PatternSwitchCase switchCase in node.cases) {
      if (switchCase.isDefault) {
        hasDefault = true;
      }
      if (switchCase.labelUsers.isNotEmpty) {
        hasContinue = true;
        switchCaseIndex[switchCase] = switchCaseIndex.length;
      }
      // Constant evaluate the pattern guards.
      transformList(switchCase.patternGuards, switchCase, dummyPatternGuard);
      if (primitiveEqualConstantsOnly) {
        for (PatternGuard patternGuard in switchCase.patternGuards) {
          if (patternGuard.guard != null) {
            primitiveEqualConstantsOnly = false;
          } else {
            Pattern pattern = patternGuard.pattern;
            if (pattern is ConstantPattern) {
              Constant constant = pattern.value!;
              if (!constantEvaluator.hasPrimitiveEqual(constant,
                  allowPseudoPrimitive: false,
                  staticTypeContext: staticTypeContext)) {
                primitiveEqualConstantsOnly = false;
              }
            } else {
              primitiveEqualConstantsOnly = false;
            }
          }
        }
      }
    }

    bool isAlwaysExhaustiveType =
        computeIsAlwaysExhaustiveType(scrutineeType, typeEnvironment.coreTypes);

    Statement replacement;
    LabeledStatement? outerLabeledStatement;
    if (primitiveEqualConstantsOnly) {
      List<SwitchCase> switchCases = [];
      for (PatternSwitchCase patternSwitchCase in node.cases) {
        patternSwitchCase.body = transform(patternSwitchCase.body)
          ..parent = patternSwitchCase;

        List<int> expressionOffsets = [];
        List<Expression> expressions = [];
        for (PatternGuard patternGuard in patternSwitchCase.patternGuards) {
          ConstantPattern constantPattern =
              patternGuard.pattern as ConstantPattern;
          expressionOffsets.add(constantPattern.fileOffset);
          expressions.add(new ConstantExpression(
              constantPattern.value!, constantPattern.expressionType!)
            ..fileOffset = constantPattern.expression.fileOffset);
        }
        SwitchCase switchCase = new SwitchCase(
            expressions, expressionOffsets, patternSwitchCase.body,
            isDefault: patternSwitchCase.isDefault)
          ..fileOffset = patternSwitchCase.fileOffset;
        switchCases.add(switchCase);
        for (Statement labelUser in patternSwitchCase.labelUsers) {
          (labelUser as ContinueSwitchStatement).target = switchCase;
        }
      }

      if (isAlwaysExhaustiveType &&
          !hasDefault &&
          constantEvaluator.evaluationMode != EvaluationMode.strong) {
        if (!node.lastCaseTerminates) {
          PatternSwitchCase lastCase = node.cases.last;
          Statement body = lastCase.body;

          LabeledStatement target;
          if (node.parent is LabeledStatement) {
            target = node.parent as LabeledStatement;
          } else {
            target =
                outerLabeledStatement = new LabeledStatement(dummyStatement);
          }
          BreakStatement breakStatement =
              createBreakStatement(target, fileOffset: lastCase.fileOffset);
          if (body is Block) {
            body.statements.add(breakStatement);
          } else {
            body = createBlock([body, breakStatement],
                fileOffset: lastCase.fileOffset)
              ..parent = lastCase;
          }
        }
        switchCases.add(new SwitchCase(
            [],
            [],
            isDefault: true,
            createExpressionStatement(createThrow(createConstructorInvocation(
                typeEnvironment.coreTypes.reachabilityErrorConstructor,
                createArguments([
                  createStringLiteral(
                      messageNeverReachableSwitchStatementError.problemMessage,
                      fileOffset: node.fileOffset)
                ], fileOffset: node.fileOffset),
                fileOffset: node.fileOffset))))
          ..fileOffset = node.fileOffset);
      }

      replacement = createSwitchStatement(node.expression, switchCases,
          isExplicitlyExhaustive: !hasDefault && isAlwaysExhaustiveType,
          expressionType: scrutineeType,
          fileOffset: node.fileOffset);
    } else {
      // matchResultVariable: int RVAR = -1;
      VariableDeclaration matchResultVariable = createInitializedVariable(
          createIntLiteral(typeEnvironment.coreTypes, -1,
              fileOffset: node.fileOffset),
          typeEnvironment.coreTypes.intNonNullableRawType,
          fileOffset: node.fileOffset);
      LabeledStatement innerLabeledStatement =
          createLabeledStatement(dummyStatement, fileOffset: node.fileOffset);

      _PatternSwitchStatementInfo info = new _PatternSwitchStatementInfo(
          matchResultVariable, innerLabeledStatement, switchCaseIndex);
      _currentPatternSwitchStatementInfoMap[node] = info;
      for (PatternSwitchCase switchCase in node.cases) {
        info.currentSwitchCase = switchCase;
        switchCase.body = transform(switchCase.body)..parent = switchCase;
      }
      _currentPatternSwitchStatementInfoMap.remove(node);

      MatchingCache matchingCache = createMatchingCache();
      MatchingExpressionVisitor matchingExpressionVisitor =
          new MatchingExpressionVisitor(matchingCache,
              typeEnvironment.coreTypes, constantEvaluator.evaluationMode);
      CacheableExpression matchedExpression =
          matchingCache.createRootExpression(node.expression, scrutineeType);
      // This expression is used, even if no case reads it.
      matchedExpression.registerUse();

      List<Statement> replacementStatements = [];

      List<SwitchCase> replacementCases = [];

      List<VariableDeclaration> declaredVariableHelpers = [];

      List<Statement> cases = [];

      List<List<DelayedExpression>> matchingExpressions =
          new List.generate(node.cases.length, (int caseIndex) {
        PatternSwitchCase switchCase = node.cases[caseIndex];
        return new List.generate(switchCase.patternGuards.length,
            (int headIndex) {
          Pattern pattern = switchCase.patternGuards[headIndex].pattern;
          DelayedExpression matchingExpression = matchingExpressionVisitor
              .visitPattern(pattern, matchedExpression);
          matchingExpression.registerUse();
          return matchingExpression;
        });
      });

      // Forcefully create the matched expression so it is included even when
      // no cases read it.
      matchedExpression.createExpression(typeEnvironment,
          inCacheInitializer: false);

      // TODO(johnniwinther): Remove this when an error is reported in case of
      // variables and labels on the same switch case.
      Map<String, List<VariableDeclaration>> declaredVariablesByName = {};

      // In weak mode we need to throw on `null` for non-nullable types.
      bool needsThrowForNull = isAlwaysExhaustiveType &&
          !hasDefault &&
          constantEvaluator.evaluationMode != EvaluationMode.strong;

      for (int caseIndex = 0; caseIndex < node.cases.length; caseIndex++) {
        PatternSwitchCase switchCase = node.cases[caseIndex];
        Statement body = switchCase.body;

        // TODO(cstefantsova): Make sure an error is reported if the variables
        // declared in the heads aren't compatible to each other.
        Map<String, VariableDeclaration> caseDeclaredVariableHelpersByName = {
          for (VariableDeclaration variable in switchCase.jointVariables)
            variable.name!: createUninitializedVariable(const DynamicType(),
                // Avoid step debugging on the declaration of intermediate
                // variables.
                // TODO(johnniwinther): Find a more systematic way of omitting
                // offsets for better step debugging.
                fileOffset: TreeNode.noOffset)
        };

        bool isContinueTarget = switchCaseIndex.containsKey(switchCase);

        List<VariableDeclaration> caseVariables = [];

        // TODO(johnniwinther): Is there a way to avoid these name clashes?
        Map<String, List<VariableDeclaration>> caseVariablesByName = {};

        Expression? caseCondition;
        for (int headIndex = 0;
            headIndex < switchCase.patternGuards.length;
            headIndex++) {
          PatternGuard patternGuard = switchCase.patternGuards[headIndex];
          Pattern pattern = patternGuard.pattern;
          Expression? guard = patternGuard.guard;

          if (isContinueTarget) {
            // TODO(johnniwinther): In this case it should be an error to have
            // any variables. This is not currently reported.
            replacementStatements.addAll(pattern.declaredVariables);

            for (VariableDeclaration variable in pattern.declaredVariables) {
              (declaredVariablesByName[variable.name!] ??= []).add(variable);
            }
          } else {
            for (VariableDeclaration variable in pattern.declaredVariables) {
              (caseVariablesByName[variable.name!] ??= []).add(variable);
            }
            caseVariables.addAll(pattern.declaredVariables);
          }

          DelayedExpression matchingExpression =
              matchingExpressions[caseIndex][headIndex];
          Expression headCondition = matchingExpression
              .createExpression(typeEnvironment, inCacheInitializer: false);
          if (guard != null) {
            headCondition = createAndExpression(headCondition, guard,
                fileOffset: guard.fileOffset);
          }

          for (VariableDeclaration declaredVariable
              in pattern.declaredVariables) {
            String variableName = declaredVariable.name!;

            VariableDeclaration? variableHelper =
                caseDeclaredVariableHelpersByName[variableName];
            if (variableHelper != null) {
              // headCondition: `headCondition` &&
              //     let _ = `variableHelper` = `declaredVariable` in true
              headCondition = createAndExpression(
                  headCondition,
                  createLetEffect(
                      effect: createVariableSet(
                          variableHelper, createVariableGet(declaredVariable),
                          fileOffset: node.fileOffset),
                      result: createBoolLiteral(true,
                          fileOffset: declaredVariable.fileOffset)),
                  fileOffset: declaredVariable.fileOffset);
            }
          }

          if (caseCondition != null) {
            caseCondition = createOrExpression(caseCondition, headCondition,
                fileOffset: node.fileOffset);
          } else {
            caseCondition = headCondition;
          }
        }

        if (switchCase.isDefault) {
          if (caseCondition != null) {
            caseCondition = createOrExpression(caseCondition,
                createBoolLiteral(true, fileOffset: switchCase.fileOffset),
                fileOffset: switchCase.fileOffset);
          }
        }

        for (List<VariableDeclaration> variables
            in caseVariablesByName.values) {
          if (variables.length > 1) {
            for (int i = 0; i < variables.length; i++) {
              VariableDeclaration variable = variables[i];
              variable.isLowered = true;
              variable.name = createJoinedIntermediateName(variable.name!, i);
            }
          }
        }

        declaredVariableHelpers
            .addAll(caseDeclaredVariableHelpersByName.values);

        for (VariableDeclaration jointVariable in switchCase.jointVariables) {
          // In case of [InvalidExpression], there's an error associated with
          // the variable, and it shouldn't be initialized.
          if (jointVariable.initializer is! InvalidExpression) {
            // `jointVariable`:
            //     `jointVariable` =
            //         `declaredVariableHelper`{`declaredVariable.type`}
            //   ==> `jointVariable` = HVAR{`declaredVariable.type`}
            jointVariable.initializer = createVariableGet(
                caseDeclaredVariableHelpersByName[jointVariable.name!]!,
                promotedType: jointVariable.type)
              ..parent = jointVariable;
          }
        }
        Statement caseBlock;
        if (isContinueTarget) {
          int continueTargetIndex = switchCaseIndex[switchCase]!;

          // setMatchResult: `matchResultVariable` = `caseIndex`;
          //   ==> RVAR = `caseIndex`;
          Statement setMatchResult = createExpressionStatement(
              createVariableSet(
                  matchResultVariable,
                  createIntLiteral(
                      typeEnvironment.coreTypes, continueTargetIndex,
                      fileOffset: node.fileOffset),
                  fileOffset: node.fileOffset));

          caseBlock = createBlock([
            setMatchResult,
            createBreakStatement(innerLabeledStatement,
                fileOffset: switchCase.fileOffset),
          ], fileOffset: switchCase.fileOffset);

          SwitchCase replacementCase = createSwitchCase(
              [
                createIntLiteral(typeEnvironment.coreTypes, continueTargetIndex,
                    fileOffset: node.fileOffset)
              ],
              [
                node.fileOffset
              ],
              createBlock([
                ...switchCase.jointVariables,
                if (body is! Block || body.statements.isNotEmpty) body
              ], fileOffset: node.fileOffset),
              isDefault: switchCase.isDefault,
              fileOffset: node.fileOffset);

          for (Statement labelUser in switchCase.labelUsers) {
            if (labelUser is ContinueSwitchStatement) {
              labelUser.target = replacementCase;
            } else {
              // TODO(cstefantsova): Handle other label user types.
              return throw new UnsupportedError(
                  "Unexpected label user: ${labelUser.runtimeType}");
            }
          }

          replacementCases.add(replacementCase);
        } else {
          caseBlock = createBlock([
            ...switchCase.jointVariables,
            if (body is! Block || body.statements.isNotEmpty) body
          ], fileOffset: switchCase.fileOffset);
        }

        if (caseCondition != null) {
          caseBlock = createIfStatement(caseCondition, caseBlock,
              fileOffset: switchCase.fileOffset);
        }
        BreakStatement? breakStatement;
        if (caseIndex == node.cases.length - 1 &&
            needsThrowForNull &&
            !node.lastCaseTerminates) {
          LabeledStatement target;
          if (node.parent is LabeledStatement) {
            target = node.parent as LabeledStatement;
          } else {
            target =
                outerLabeledStatement = new LabeledStatement(dummyStatement);
          }
          breakStatement =
              createBreakStatement(target, fileOffset: switchCase.fileOffset);
        }
        cases.add(createBlock([
          ...caseVariables,
          caseBlock,
          if (breakStatement != null) breakStatement
        ], fileOffset: switchCase.fileOffset));
      }

      if (needsThrowForNull) {
        cases.add(
            createExpressionStatement(createThrow(createConstructorInvocation(
                typeEnvironment.coreTypes.reachabilityErrorConstructor,
                createArguments([
                  createStringLiteral(
                      messageNeverReachableSwitchStatementError.problemMessage,
                      fileOffset: node.fileOffset)
                ], fileOffset: node.fileOffset),
                fileOffset: node.fileOffset))));
      }

      // TODO(johnniwinther): Find a better way to avoid name clashes between
      // cases.
      for (List<VariableDeclaration> variables
          in declaredVariablesByName.values) {
        if (variables.length > 1) {
          for (int i = 1; i < variables.length; i++) {
            variables[i].name = '${variables[i].name}${"#$i"}';
          }
        }
      }

      if (hasContinue) {
        Statement casesBlock = createBlock(cases, fileOffset: node.fileOffset);
        innerLabeledStatement.body = casesBlock..parent = innerLabeledStatement;
        replacementStatements = [
          matchResultVariable,
          ...replacementStatements,
          ...matchingCache.declarations,
          ...declaredVariableHelpers,
          innerLabeledStatement,
          createSwitchStatement(
              createVariableGet(matchResultVariable), replacementCases,
              isExplicitlyExhaustive: false,
              expressionType: scrutineeType,
              fileOffset: node.fileOffset)
        ];
      } else {
        replacementStatements = [
          ...replacementStatements,
          ...matchingCache.declarations,
          ...declaredVariableHelpers,
          ...cases,
        ];
      }

      if (replacementStatements.length == 1) {
        replacement = replacementStatements.first;
      } else {
        replacement = new Block(replacementStatements)
          ..fileOffset = node.fileOffset;
      }
    }
    if (outerLabeledStatement != null) {
      outerLabeledStatement.body = replacement..parent = outerLabeledStatement;
      replacement = outerLabeledStatement;
    }

    List<PatternGuard> patternGuards = [];
    for (PatternSwitchCase switchCase in node.cases) {
      patternGuards.addAll(switchCase.patternGuards);
    }
    _checkExhaustiveness(node, replacement, scrutineeType, patternGuards,
        hasDefault: hasDefault,
        mustBeExhaustive: isAlwaysExhaustiveType,
        fileOffset: node.expression.fileOffset,
        isSwitchExpression: false);
    // TODO(johnniwinther): Avoid this work-around for [getFileUri].
    replacement.parent = node.parent;
    // TODO(johnniwinther): Avoid transform of [replacement] by generating
    //  already constant evaluated lowering.
    return transform(replacement);
  }

  void _checkExhaustiveness(TreeNode node, TreeNode replacement,
      DartType expressionType, List<PatternGuard> patternGuards,
      {required int fileOffset,
      required bool hasDefault,
      required bool mustBeExhaustive,
      required bool isSwitchExpression}) {
    StaticType type = _exhaustivenessCache!.getStaticType(
        // Treat invalid types as empty.
        expressionType is InvalidType
            ? const NeverType.nonNullable()
            : expressionType);
    List<Space> cases = [];
    PatternConverter patternConverter = new PatternConverter(
        _exhaustivenessCache!, staticTypeContext,
        hasPrimitiveEquality: (Constant constant) => constantEvaluator
            .hasPrimitiveEqual(constant, staticTypeContext: staticTypeContext));
    for (PatternGuard patternGuard in patternGuards) {
      cases.add(patternConverter.createRootSpace(type, patternGuard.pattern,
          hasGuard: patternGuard.guard != null));
    }
    List<ExhaustivenessError> errors =
        reportErrors(_exhaustivenessCache!, type, cases);
    List<ExhaustivenessError>? reportedErrors;
    if (_exhaustivenessDataForTesting != null) {
      reportedErrors = [];
    }
    Library library = currentLibrary;
    for (ExhaustivenessError error in errors) {
      if (error is UnreachableCaseError) {
        if (library.importUri.isScheme('dart') &&
            library.importUri.path == 'html') {
          // TODO(51754): Remove this.
          continue;
        }
        reportedErrors?.add(error);
        // TODO(johnniwinther): Re-enable this, pending resolution on
        // https://github.com/dart-lang/language/issues/2924
        /*constantEvaluator.errorReporter.report(
              constantEvaluator.createLocatedMessageWithOffset(
                  node,
                  patternGuards[error.index].fileOffset,
                  messageUnreachableSwitchCase));*/
      } else if (error is NonExhaustiveError &&
          !hasDefault &&
          mustBeExhaustive) {
        reportedErrors?.add(error);
        constantEvaluator.errorReporter.report(
            constantEvaluator.createLocatedMessageWithOffset(
                node,
                fileOffset,
                (isSwitchExpression
                        ? templateNonExhaustiveSwitchExpression
                        : templateNonExhaustiveSwitchStatement)
                    .withArguments(
                        expressionType,
                        error.witness.asWitness,
                        error.witness.asCorrection,
                        library.isNonNullableByDefault)));
      }
    }
    if (_exhaustivenessDataForTesting != null) {
      _exhaustivenessDataForTesting!.objectFieldLookup ??= _exhaustivenessCache;
      _exhaustivenessDataForTesting!.switchResults[replacement] =
          new ExhaustivenessResult(type, cases,
              patternGuards.map((c) => c.fileOffset).toList(), reportedErrors!);
    }
  }

  @override
  TreeNode visitSwitchStatement(
      SwitchStatement node, TreeNode? removalSentinel) {
    TreeNode result = super.visitSwitchStatement(node, removalSentinel);
    Library library = currentLibrary;
    // ignore: unnecessary_null_comparison
    if (library != null) {
      for (SwitchCase switchCase in node.cases) {
        for (Expression caseExpression in switchCase.expressions) {
          if (caseExpression is ConstantExpression) {
            if (!constantEvaluator.hasPrimitiveEqual(caseExpression.constant,
                staticTypeContext: staticTypeContext)) {
              constantEvaluator.errorReporter.report(
                  constantEvaluator.createLocatedMessage(
                      caseExpression,
                      templateConstEvalCaseImplementsEqual.withArguments(
                          caseExpression.constant,
                          staticTypeContext.nonNullable ==
                              Nullability.nonNullable)),
                  null);
            }
          } else {
            // If caseExpression is not ConstantExpression, an error is
            // reported elsewhere.
          }
        }
      }
    }
    return result;
  }

  @override
  TreeNode visitIfCaseStatement(
      IfCaseStatement node, TreeNode? removalSentinel) {
    node.expression = transform(node.expression)..parent = node;
    node.patternGuard = transform(node.patternGuard)..parent = node;

    MatchingCache matchingCache = createMatchingCache();
    MatchingExpressionVisitor matchingExpressionVisitor =
        new MatchingExpressionVisitor(matchingCache, typeEnvironment.coreTypes,
            constantEvaluator.evaluationMode);
    CacheableExpression matchedExpression = matchingCache.createRootExpression(
        node.expression, node.matchedValueType!);
    // This expression is used, even if the matching expression doesn't read it.
    matchedExpression.registerUse();

    DelayedExpression matchingExpression = matchingExpressionVisitor
        .visitPattern(node.patternGuard.pattern, matchedExpression);
    matchingExpression.registerUse();

    // Forcefully create the matched expression so it is included even when
    // matching expression doesn't read it.
    matchedExpression.createExpression(typeEnvironment,
        inCacheInitializer: false);

    Expression condition = matchingExpression.createExpression(typeEnvironment,
        inCacheInitializer: false);
    Expression? guard = node.patternGuard.guard;
    if (guard != null) {
      condition =
          createAndExpression(condition, guard, fileOffset: guard.fileOffset);
    }
    List<Statement> replacementStatements = [
      ...node.patternGuard.pattern.declaredVariables,
      ...matchingCache.declarations,
    ];
    replacementStatements.add(createIfStatement(condition, node.then,
        otherwise: node.otherwise, fileOffset: node.fileOffset));

    Statement result;
    if (replacementStatements.length > 1) {
      // If we need local declarations, create a new block to avoid naming
      // collision with declarations in the same parent block.
      result = createBlock(replacementStatements, fileOffset: node.fileOffset);
    } else {
      result = replacementStatements.single;
    }
    // TODO(johnniwinther): Avoid this work-around for [getFileUri].
    result.parent = node.parent;
    return transform(result);
  }

  @override
  TreeNode visitPatternVariableDeclaration(
      PatternVariableDeclaration node, TreeNode? removalSentinel) {
    node.initializer = transform(node.initializer)..parent = node;
    node.pattern = transform(node.pattern)..parent = node;

    MatchingCache matchingCache = createMatchingCache();
    MatchingExpressionVisitor matchingExpressionVisitor =
        new MatchingExpressionVisitor(matchingCache, typeEnvironment.coreTypes,
            constantEvaluator.evaluationMode);
    // TODO(cstefantsova): Do we need a more precise type for the variable?
    DartType matchedType = const DynamicType();
    CacheableExpression matchedExpression =
        matchingCache.createRootExpression(node.initializer, matchedType);
    // This expression is used, even if the matching expression doesn't read it.
    matchedExpression.registerUse();

    DelayedExpression matchingExpression =
        matchingExpressionVisitor.visitPattern(node.pattern, matchedExpression);

    matchingExpression.registerUse();

    // Forcefully create the matched expression so it is included even when
    // the matching expression doesn't read it.
    matchedExpression.createExpression(typeEnvironment,
        inCacheInitializer: false);

    Expression readMatchingExpression = matchingExpression
        .createExpression(typeEnvironment, inCacheInitializer: false);

    List<Statement> replacementStatements = [
      ...matchingCache.declarations,
      // TODO(cstefantsova): Provide a better diagnostic message.
      createIfStatement(
          createNot(readMatchingExpression),
          createExpressionStatement(createThrow(createConstructorInvocation(
              typeEnvironment.coreTypes.stateErrorConstructor,
              createArguments([
                createStringLiteral(messagePatternMatchingError.problemMessage,
                    fileOffset: node.fileOffset)
              ], fileOffset: node.fileOffset),
              fileOffset: node.fileOffset))),
          fileOffset: node.fileOffset),
    ];
    if (replacementStatements.length > 1) {
      // If we need local declarations, create a new block to avoid naming
      // collision with declarations in the same parent block.
      replacementStatements = [
        createBlock(replacementStatements, fileOffset: node.fileOffset)
      ];
    }
    replacementStatements = [
      ...node.pattern.declaredVariables,
      ...replacementStatements,
    ];

    _InlinedBlock inlinedBlock = new _InlinedBlock(replacementStatements)
      ..fileOffset = node.fileOffset;
    // TODO(johnniwinther): Avoid this work-around for [getFileUri].
    inlinedBlock.parent = node.parent;
    transformStatementList(replacementStatements, inlinedBlock);
    return inlinedBlock;
  }

  @override
  TreeNode visitPatternAssignment(
      PatternAssignment node, TreeNode? removalSentinel) {
    node.expression = transform(node.expression)..parent = node;
    node.pattern = transform(node.pattern)..parent = node;

    MatchingCache matchingCache = createMatchingCache();
    MatchingExpressionVisitor matchingExpressionVisitor =
        new MatchingExpressionVisitor(matchingCache, typeEnvironment.coreTypes,
            constantEvaluator.evaluationMode);
    // TODO(cstefantsova): Do we need a more precise type for the variable?
    DartType matchedType = const DynamicType();
    CacheableExpression matchedExpression =
        matchingCache.createRootExpression(node.expression, matchedType);

    DelayedExpression matchingExpression =
        matchingExpressionVisitor.visitPattern(node.pattern, matchedExpression);

    matchedExpression.registerUse();
    matchingExpression.registerUse();

    Expression readMatchedExpression = matchedExpression
        .createExpression(typeEnvironment, inCacheInitializer: false);
    List<Expression> effects = [];
    Expression readMatchingExpression = matchingExpression.createExpression(
        typeEnvironment,
        effects: effects,
        inCacheInitializer: false);

    List<Statement> replacementStatements = [
      ...node.pattern.declaredVariables,
      ...matchingCache.declarations,
      // TODO(cstefantsova): Provide a better diagnostic message.
      createIfStatement(
          createNot(readMatchingExpression),
          createExpressionStatement(createThrow(createConstructorInvocation(
              typeEnvironment.coreTypes.stateErrorConstructor,
              createArguments([
                createStringLiteral(messagePatternMatchingError.problemMessage,
                    fileOffset: node.fileOffset)
              ], fileOffset: node.fileOffset),
              fileOffset: node.fileOffset))),
          fileOffset: node.fileOffset),
      ...effects.map((e) => createExpressionStatement(e)),
    ];

    Expression result = createBlockExpression(
        createBlock(replacementStatements, fileOffset: node.fileOffset),
        readMatchedExpression,
        fileOffset: node.fileOffset);
    // TODO(johnniwinther): Avoid this work-around for [getFileUri].
    result.parent = node.parent;
    return transform(result);
  }

  @override
  TreeNode visitConstantPattern(
      ConstantPattern node, TreeNode? removalSentinel) {
    TreeNode result = super.visitConstantPattern(node, removalSentinel);
    node.value = evaluateWithContext(node, node.expression);
    return result;
  }

  @override
  TreeNode visitMapPatternEntry(
      MapPatternEntry node, TreeNode? removalSentinel) {
    TreeNode result = super.visitMapPatternEntry(node, removalSentinel);
    node.keyValue = evaluateWithContext(node, node.key);
    return result;
  }

  @override
  TreeNode visitMapPattern(MapPattern node, TreeNode? removalSentinel) {
    super.visitMapPattern(node, removalSentinel);
    Map<Constant, MapPatternEntry> keyValueMap = {};
    for (MapPatternEntry entry in node.entries) {
      if (entry is MapPatternRestEntry) continue;
      Constant keyValue = entry.keyValue!;
      MapPatternEntry? existing = keyValueMap[keyValue];
      if (existing != null) {
        constantEvaluator.errorReporter.report(
            constantEvaluator.createLocatedMessage(
                entry.key, messageEqualKeysInMapPattern),
            [
              constantEvaluator.createLocatedMessage(
                  existing.key, messageEqualKeysInMapPatternContext)
            ]);
      } else {
        keyValueMap[keyValue] = entry;
      }
    }

    return node;
  }

  @override
  TreeNode visitRelationalPattern(
      RelationalPattern node, TreeNode? removalSentinel) {
    TreeNode result = super.visitRelationalPattern(node, removalSentinel);
    node.expressionValue = evaluateWithContext(node, node.expression);
    return result;
  }

  @override
  TreeNode visitSwitchExpression(
      SwitchExpression node, TreeNode? removalSentinel) {
    super.visitSwitchExpression(node, removalSentinel);

    DartType scrutineeType = node.expressionType!;

    // If `true`, the switch expressions consists solely of guard-less constant
    // patterns whose value has a primitive equals method. For this case we
    // generate switch using an ordinary switch statement.
    bool primitiveEqualConstantsOnly = true;
    for (SwitchExpressionCase switchCase in node.cases) {
      if (primitiveEqualConstantsOnly) {
        PatternGuard patternGuard = switchCase.patternGuard;
        if (patternGuard.guard != null) {
          primitiveEqualConstantsOnly = false;
          break;
        } else {
          Pattern pattern = patternGuard.pattern;
          if (pattern is ConstantPattern) {
            Constant constant = pattern.value!;
            if (!constantEvaluator.hasPrimitiveEqual(constant,
                allowPseudoPrimitive: false,
                staticTypeContext: staticTypeContext)) {
              primitiveEqualConstantsOnly = false;
              break;
            }
          } else {
            primitiveEqualConstantsOnly = false;
            break;
          }
        }
      }
    }

    Expression replacement;
    if (primitiveEqualConstantsOnly) {
      VariableDeclaration valueVariable =
          createUninitializedVariable(node.staticType!,
              // Avoid step debugging on the declarations of the value variable.
              // TODO(johnniwinther): Find a more systematic way of omitting
              // offsets for better step debugging.
              fileOffset: TreeNode.noOffset);

      LabeledStatement labeledStatement =
          createLabeledStatement(dummyStatement, fileOffset: node.fileOffset);
      List<SwitchCase> switchCases = [];
      for (SwitchExpressionCase switchExpressionCase in node.cases) {
        List<int> expressionOffsets = [];
        List<Expression> expressions = [];
        PatternGuard patternGuard = switchExpressionCase.patternGuard;
        ConstantPattern constantPattern =
            patternGuard.pattern as ConstantPattern;
        expressionOffsets.add(constantPattern.fileOffset);
        expressions.add(new ConstantExpression(
            constantPattern.value!, constantPattern.expressionType!)
          ..fileOffset = constantPattern.expression.fileOffset);

        SwitchCase switchCase = new SwitchCase(
            expressions,
            expressionOffsets,
            createBlock([
              createExpressionStatement(createVariableSet(
                  valueVariable, switchExpressionCase.expression,
                  fileOffset: switchExpressionCase.expression.fileOffset)),
              createBreakStatement(labeledStatement,
                  fileOffset: switchExpressionCase.expression.fileOffset),
            ], fileOffset: switchExpressionCase.fileOffset),
            isDefault: false)
          ..fileOffset = switchExpressionCase.fileOffset
          ..fileOffset;
        switchCases.add(switchCase);
      }
      if (constantEvaluator.evaluationMode != EvaluationMode.strong) {
        switchCases.add(new SwitchCase(
            [],
            [],
            isDefault: true,
            createExpressionStatement(createThrow(createConstructorInvocation(
                typeEnvironment.coreTypes.reachabilityErrorConstructor,
                createArguments([
                  createStringLiteral(
                      messageNeverReachableSwitchExpressionError.problemMessage,
                      fileOffset: node.fileOffset)
                ], fileOffset: node.fileOffset),
                fileOffset: node.fileOffset))))
          ..fileOffset = node.fileOffset);
      }

      labeledStatement.body = createSwitchStatement(
          node.expression, switchCases,
          isExplicitlyExhaustive: true,
          expressionType: scrutineeType,
          fileOffset: node.fileOffset)
        ..parent = labeledStatement;
      replacement = createBlockExpression(
          createBlock([
            valueVariable,
            labeledStatement,
          ], fileOffset: node.fileOffset),
          createVariableGet(valueVariable),
          fileOffset: node.fileOffset);
    } else {
      MatchingCache matchingCache = createMatchingCache();
      MatchingExpressionVisitor matchingExpressionVisitor =
          new MatchingExpressionVisitor(matchingCache,
              typeEnvironment.coreTypes, constantEvaluator.evaluationMode);
      CacheableExpression matchedExpression =
          matchingCache.createRootExpression(node.expression, scrutineeType);
      // This expression is used, even if no case reads it.
      matchedExpression.registerUse();

      LabeledStatement labeledStatement =
          createLabeledStatement(dummyStatement, fileOffset: node.fileOffset);

      // valueVariable: `valueType` valueVariable;
      VariableDeclaration valueVariable =
          createUninitializedVariable(node.staticType!,
              // Avoid step debugging on the declaration of the value variable.
              // TODO(johnniwinther): Find a more systematic way of omitting
              // offsets for better step debugging.
              fileOffset: TreeNode.noOffset);

      List<Statement> cases = [];

      List<DelayedExpression> matchingExpressions =
          new List.generate(node.cases.length, (int caseIndex) {
        SwitchExpressionCase switchCase = node.cases[caseIndex];
        DelayedExpression matchingExpression = matchingExpressionVisitor
            .visitPattern(switchCase.patternGuard.pattern, matchedExpression);
        matchingExpression.registerUse();
        return matchingExpression;
      });

      // Forcefully create the matched expression so it is included even when
      // no cases read it.
      matchedExpression.createExpression(typeEnvironment,
          inCacheInitializer: false);

      for (int caseIndex = 0; caseIndex < node.cases.length; caseIndex++) {
        SwitchExpressionCase switchCase = node.cases[caseIndex];
        Expression body = switchCase.expression;

        PatternGuard patternGuard = switchCase.patternGuard;
        Pattern pattern = patternGuard.pattern;
        Expression? guard = patternGuard.guard;

        DelayedExpression matchingExpression = matchingExpressions[caseIndex];
        Expression caseCondition = matchingExpression
            .createExpression(typeEnvironment, inCacheInitializer: false);
        if (guard != null) {
          caseCondition = createAndExpression(caseCondition, guard,
              fileOffset: guard.fileOffset);
        }

        cases.add(createBlock([
          ...pattern.declaredVariables,
          createIfStatement(
              caseCondition,
              createBlock([
                createExpressionStatement(createVariableSet(valueVariable, body,
                    // Avoid step debugging on the assignment to the value
                    // variable.
                    // TODO(johnniwinther): Find a more systematic way of
                    //  omitting offsets for better step debugging.
                    fileOffset: TreeNode.noOffset)),
                createBreakStatement(labeledStatement,
                    fileOffset: switchCase.fileOffset),
              ], fileOffset: switchCase.fileOffset),
              fileOffset: switchCase.fileOffset)
        ], fileOffset: switchCase.fileOffset));
      }
      if (constantEvaluator.evaluationMode != EvaluationMode.strong) {
        cases.add(
            createExpressionStatement(createThrow(createConstructorInvocation(
                typeEnvironment.coreTypes.reachabilityErrorConstructor,
                createArguments([
                  createStringLiteral(
                      messageNeverReachableSwitchExpressionError.problemMessage,
                      fileOffset: node.fileOffset)
                ], fileOffset: node.fileOffset),
                fileOffset: node.fileOffset))));
      }

      labeledStatement.body = createBlock(cases, fileOffset: node.fileOffset)
        ..parent = labeledStatement;
      replacement = createBlockExpression(
          createBlock([
            valueVariable,
            ...matchingCache.declarations,
            labeledStatement,
          ], fileOffset: node.fileOffset),
          createVariableGet(valueVariable),
          fileOffset: node.fileOffset);
    }

    List<PatternGuard> patternGuards = [];
    for (SwitchExpressionCase switchCase in node.cases) {
      patternGuards.add(switchCase.patternGuard);
    }
    _checkExhaustiveness(node, replacement, scrutineeType, patternGuards,
        hasDefault: false,
        // Don't check exhaustiveness on erroneous expressions.
        mustBeExhaustive: scrutineeType is! InvalidType,
        fileOffset: node.expression.fileOffset,
        isSwitchExpression: true);

    // TODO(johnniwinther): Avoid this work-around for [getFileUri].
    replacement.parent = node.parent;
    // TODO(johnniwinther): Avoid transform of [replacement] by generating
    //  already constant evaluated lowering.
    return transform(replacement);
  }

  @override
  TreeNode visitVariableGet(VariableGet node, TreeNode? removalSentinel) {
    final VariableDeclaration variable = node.variable;
    if (variable.isConst) {
      variable.initializer =
          evaluateAndTransformWithContext(variable, variable.initializer!)
            ..parent = variable;
      if (shouldInline(variable.initializer!)) {
        return evaluateAndTransformWithContext(node, node);
      }
    }
    return super.visitVariableGet(node, removalSentinel);
  }

  @override
  TreeNode visitListLiteral(ListLiteral node, TreeNode? removalSentinel) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitListLiteral(node, removalSentinel);
  }

  @override
  TreeNode visitRecordLiteral(RecordLiteral node, TreeNode? removalSentinel) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    } else {
      // A record literal is a compile-time constant expression if and only
      // if all its field expressions are compile-time constant expressions. If
      // any of its field expressions are unevaluated constants then the entire
      // record is an unevaluated constant.

      bool allConstant = true;
      bool hasUnevaluated = false;

      List<Constant> positional = [];

      for (int i = 0; i < node.positional.length; i++) {
        Expression result = transform(node.positional[i]);
        node.positional[i] = result..parent = node;
        if (allConstant && result is ConstantExpression) {
          positional.add(result.constant);
          if (result.constant is UnevaluatedConstant) {
            hasUnevaluated = true;
          }
        } else {
          allConstant = false;
        }
      }

      Map<String, Constant> named = {};
      for (NamedExpression expression in node.named) {
        Expression result = transform(expression.value);
        expression.value = result..parent = expression;
        if (allConstant && result is ConstantExpression) {
          named[expression.name] = result.constant;
          if (result.constant is UnevaluatedConstant) {
            hasUnevaluated = true;
          }
        } else {
          allConstant = false;
        }
      }

      if (allConstant) {
        if (hasUnevaluated) {
          return makeConstantExpression(new UnevaluatedConstant(node), node);
        } else {
          Constant constant = constantEvaluator.canonicalize(
              new RecordConstant(positional, named, node.recordType));
          return makeConstantExpression(constant, node);
        }
      }
      return node;
    }
  }

  @override
  TreeNode visitStringConcatenation(
      StringConcatenation node, TreeNode? removalSentinel) {
    bool allConstant = true;
    for (int index = 0; index < node.expressions.length; index++) {
      Expression expression = node.expressions[index];
      Expression result = transform(expression);
      node.expressions[index] = result..parent = node;
      if (allConstant) {
        if (result is ConstantExpression) {
          DartType staticType = result.type;
          if (staticType is NullType ||
              staticType is InterfaceType &&
                  (staticType.classReference ==
                          typeEnvironment.coreTypes.boolClass.reference ||
                      staticType.classReference ==
                          typeEnvironment.coreTypes.intClass.reference ||
                      staticType.classReference ==
                          typeEnvironment.coreTypes.doubleClass.reference ||
                      staticType.classReference ==
                          typeEnvironment.coreTypes.stringClass.reference)) {
            // Ok
          } else {
            allConstant = false;
          }
        } else if (result is! BasicLiteral) {
          allConstant = false;
        }
      }
    }
    if (allConstant) {
      return evaluateAndTransformWithContext(node, node);
    }
    return node;
  }

  @override
  TreeNode visitListConcatenation(
      ListConcatenation node, TreeNode? removalSentinel) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  TreeNode visitSetLiteral(SetLiteral node, TreeNode? removalSentinel) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitSetLiteral(node, removalSentinel);
  }

  @override
  TreeNode visitSetConcatenation(
      SetConcatenation node, TreeNode? removalSentinel) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  TreeNode visitMapLiteral(MapLiteral node, TreeNode? removalSentinel) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitMapLiteral(node, removalSentinel);
  }

  @override
  TreeNode visitTypeLiteral(TypeLiteral node, TreeNode? removalSentinel) {
    if (!containsFreeTypeVariables(node.type)) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitTypeLiteral(node, removalSentinel);
  }

  @override
  TreeNode visitMapConcatenation(
      MapConcatenation node, TreeNode? removalSentinel) {
    return evaluateAndTransformWithContext(node, node);
  }

  @override
  TreeNode visitConstructorInvocation(
      ConstructorInvocation node, TreeNode? removalSentinel) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    return super.visitConstructorInvocation(node, removalSentinel);
  }

  @override
  TreeNode visitStaticInvocation(
      StaticInvocation node, TreeNode? removalSentinel) {
    if (node.isConst) {
      return evaluateAndTransformWithContext(node, node);
    }
    final TreeNode result = super.visitStaticInvocation(node, removalSentinel);
    // Validation of weak references assumes
    // arguments are already constant evaluated.
    if (StaticWeakReferences.isAnnotatedWithWeakReferencePragma(
        node.target, typeEnvironment.coreTypes)) {
      StaticWeakReferences.validateWeakReferenceUse(
          node, constantEvaluator.errorReporter);
    }
    return result;
  }

  @override
  TreeNode visitConstantExpression(
      ConstantExpression node, TreeNode? removalSentinel) {
    Constant constant = node.constant;
    if (constant is UnevaluatedConstant && constantEvaluator.hasEnvironment) {
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
      return constantEvaluator.evaluate(staticTypeContext, node);
    }

    return constantEvaluator.evaluate(staticTypeContext, node,
        contextNode: treeContext);
  }

  Expression makeConstantExpression(Constant constant, Expression node) {
    if (constant is UnevaluatedConstant &&
        constant.expression is InvalidExpression) {
      return constant.expression;
    }
    return new ConstantExpression(
        constant, node.getStaticType(staticTypeContext))
      ..fileOffset = node.fileOffset;
  }

  bool shouldInline(Expression initializer) {
    if (backend.alwaysInlineConstants) {
      return true;
    }
    if (initializer is ConstantExpression) {
      return backend.shouldInlineConstant(initializer);
    }
    return true;
  }
}

class ConstantEvaluator implements ExpressionVisitor<Constant> {
  final DartLibrarySupport dartLibrarySupport;
  final ConstantsBackend backend;
  final NumberSemantics numberSemantics;
  late ConstantIntFolder intFolder;
  Map<String, String>? _environmentDefines;
  final bool errorOnUnevaluatedConstant;
  final Component component;
  final CoreTypes coreTypes;
  final TypeEnvironment typeEnvironment;
  StaticTypeContext? _staticTypeContext;
  final ErrorReporter errorReporter;
  final EvaluationMode evaluationMode;

  final bool enableTripleShift;
  final bool enableConstFunctions;

  final Map<Constant, Constant> canonicalizationCache;
  final Map<Node, Constant?> nodeCache;

  late Map<Class, bool> primitiveEqualCache;
  late Map<Class, bool> primitiveHashCodeCache;

  /// Classes that are considered having a primitive equals but where the
  /// `operator ==` is actually defined through as custom method. For instance
  /// the `Symbol` class. When lowering a pattern switch to a regular switch,
  /// these are not allowed.
  late Set<Class> pseudoPrimitiveClasses;

  final NullConstant nullConstant = new NullConstant();
  final BoolConstant trueConstant = new BoolConstant(true);
  final BoolConstant falseConstant = new BoolConstant(false);

  final Set<Library> visitedLibraries = {};

  InstanceBuilder? instanceBuilder;
  EvaluationEnvironment env;
  Map<Constant, Constant> lowered = new Map<Constant, Constant>.identity();

  bool seenUnevaluatedChild = false; // Any children that were left unevaluated?
  int lazyDepth = -1; // Current nesting depth of lazy regions.

  bool get shouldBeUnevaluated => seenUnevaluatedChild || lazyDepth != 0;

  bool get targetingJavaScript => numberSemantics == NumberSemantics.js;

  bool get isNonNullableByDefault =>
      staticTypeContext.nonNullable == Nullability.nonNullable;

  StaticTypeContext get staticTypeContext => _staticTypeContext!;

  Library get currentLibrary => staticTypeContext.enclosingLibrary;

  late ConstantWeakener _weakener;

  ConstantEvaluator(this.dartLibrarySupport, this.backend, this.component,
      this._environmentDefines, this.typeEnvironment, this.errorReporter,
      {this.enableTripleShift = false,
      this.enableConstFunctions = false,
      this.errorOnUnevaluatedConstant = false,
      this.evaluationMode = EvaluationMode.weak})
      : numberSemantics = backend.numberSemantics,
        coreTypes = typeEnvironment.coreTypes,
        canonicalizationCache = <Constant, Constant>{},
        nodeCache = <Node, Constant?>{},
        env = new EvaluationEnvironment() {
    if (_environmentDefines == null && !backend.supportsUnevaluatedConstants) {
      throw new ArgumentError(
          "No 'environmentDefines' passed to the constant evaluator but the "
          "ConstantsBackend does not support unevaluated constants.");
    }
    intFolder = new ConstantIntFolder.forSemantics(this, numberSemantics);
    pseudoPrimitiveClasses = <Class>{
      coreTypes.internalSymbolClass,
      coreTypes.symbolClass,
      coreTypes.typeClass,
    };
    primitiveEqualCache = <Class, bool>{
      coreTypes.boolClass: true,
      coreTypes.doubleClass: false,
      coreTypes.intClass: true,
      coreTypes.internalSymbolClass: true,
      coreTypes.listClass: true,
      coreTypes.mapClass: true,
      coreTypes.objectClass: true,
      coreTypes.setClass: true,
      coreTypes.stringClass: true,
      coreTypes.symbolClass: true,
      coreTypes.typeClass: true,
    };
    primitiveHashCodeCache = <Class, bool>{...primitiveEqualCache};
    _weakener = new ConstantWeakener(this);
  }

  Map<String, String>? _supportedLibrariesCache;

  Map<String, String> _computeSupportedLibraries() {
    Map<String, String> map = {};
    for (Library library in component.libraries) {
      if (library.importUri.isScheme('dart')) {
        map[library.importUri.path] =
            DartLibrarySupport.getDartLibrarySupportValue(
                library.importUri.path,
                libraryExists: true,
                isSynthetic: library.isSynthetic,
                isUnsupported: library.isUnsupported,
                dartLibrarySupport: dartLibrarySupport);
      }
    }
    return map;
  }

  String? lookupEnvironment(String key) {
    if (DartLibrarySupport.isDartLibraryQualifier(key)) {
      String libraryName = DartLibrarySupport.getDartLibraryName(key);
      String? value = (_supportedLibrariesCache ??=
          _computeSupportedLibraries())[libraryName];
      return value ?? "";
    }
    return _environmentDefines![key];
  }

  bool hasEnvironmentKey(String key) {
    if (key.startsWith(DartLibrarySupport.dartLibraryPrefix)) {
      return true;
    }
    return _environmentDefines!.containsKey(key);
  }

  bool get hasEnvironment => _environmentDefines != null;

  DartType convertType(DartType type) {
    switch (evaluationMode) {
      case EvaluationMode.strong:
      case EvaluationMode.agnostic:
        return norm(coreTypes, type);
      case EvaluationMode.weak:
        type = norm(coreTypes, type);
        return computeConstCanonicalType(type, coreTypes,
                isNonNullableByDefault: isNonNullableByDefault) ??
            type;
    }
  }

  List<DartType> convertTypes(List<DartType> types) {
    switch (evaluationMode) {
      case EvaluationMode.strong:
      case EvaluationMode.agnostic:
        return types.map((DartType type) => norm(coreTypes, type)).toList();
      case EvaluationMode.weak:
        return types.map((DartType type) {
          type = norm(coreTypes, type);
          return computeConstCanonicalType(type, coreTypes,
                  isNonNullableByDefault: isNonNullableByDefault) ??
              type;
        }).toList();
    }
  }

  LocatedMessage createLocatedMessage(TreeNode? node, Message message) {
    Uri? uri = getFileUri(node);
    if (uri == null) {
      // TODO(johnniwinther): Ensure that we always have a uri.
      return message.withoutLocation();
    }
    int offset = getFileOffset(uri, node);
    return message.withLocation(uri, offset, noLength);
  }

  LocatedMessage createLocatedMessageWithOffset(
      TreeNode? node, int offset, Message message) {
    Uri? uri = getFileUri(node);
    if (uri == null) {
      // TODO(johnniwinther): Ensure that we always have a uri.
      return message.withoutLocation();
    }
    return message.withLocation(uri, offset, noLength);
  }

  // TODO(johnniwinther): Avoid this by adding a current file uri field.
  Uri? getFileUri(TreeNode? node) {
    while (node != null) {
      if (node is FileUriNode) {
        return node.fileUri;
      }
      node = node.parent;
    }
    return null;
  }

  int getFileOffset(Uri? uri, TreeNode? node) {
    if (uri == null) return TreeNode.noOffset;
    while (node != null && node.fileOffset == TreeNode.noOffset) {
      node = node.parent;
    }
    return node == null ? TreeNode.noOffset : node.fileOffset;
  }

  /// Evaluates [f] with [staticTypeContext] as the current static type context.
  T inStaticTypeContext<T>(
      StaticTypeContext staticTypeContext, T Function() f) {
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = staticTypeContext;
    T result = f();
    _staticTypeContext = oldStaticTypeContext;
    return result;
  }

  /// Evaluate [node] and possibly cache the evaluation result.
  /// Returns UnevaluatedConstant if the constant could not be evaluated.
  /// If the expression in the UnevaluatedConstant is an InvalidExpression,
  /// an error occurred during constant evaluation.
  Constant evaluate(StaticTypeContext context, Expression node,
      {TreeNode? contextNode}) {
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = context;
    Constant result = _evaluate(node, contextNode: contextNode);
    _staticTypeContext = oldStaticTypeContext;
    return result;
  }

  Constant _evaluate(Expression node, {TreeNode? contextNode}) {
    seenUnevaluatedChild = false;
    lazyDepth = 0;
    Constant result = _evaluateSubexpression(node);
    if (result is AbortConstant) {
      if (result is _AbortDueToErrorConstant) {
        final LocatedMessage locatedMessageActualError =
            createLocatedMessage(result.node, result.message);
        if (result.isEvaluationError) {
          final List<LocatedMessage> contextMessages = <LocatedMessage>[
            locatedMessageActualError
          ];
          if (result.context != null) contextMessages.addAll(result.context!);
          if (contextNode != null && contextNode != result.node) {
            contextMessages.add(
                createLocatedMessage(contextNode, messageConstEvalContext));
          }

          {
            final LocatedMessage locatedMessage =
                createLocatedMessage(node, messageConstEvalStartingPoint);
            errorReporter.report(locatedMessage, contextMessages);
          }
        } else {
          errorReporter.report(locatedMessageActualError);
        }
        return new UnevaluatedConstant(
            new InvalidExpression(result.message.problemMessage));
      }
      if (result is _AbortDueToThrowConstant) {
        final Object value = result.throwValue;
        Message? message;
        if (value is Constant) {
          message = templateConstEvalUnhandledException.withArguments(
              value, isNonNullableByDefault);
        } else if (value is Error) {
          message = templateConstEvalUnhandledCoreException
              .withArguments(value.toString());
        }
        assert(message != null);

        final LocatedMessage locatedMessageActualError =
            createLocatedMessage(result.node, message!);
        final List<LocatedMessage> contextMessages = <LocatedMessage>[
          locatedMessageActualError
        ];
        {
          final LocatedMessage locatedMessage =
              createLocatedMessage(node, messageConstEvalStartingPoint);
          errorReporter.report(locatedMessage, contextMessages);
        }
        return new UnevaluatedConstant(
            new InvalidExpression(message.problemMessage));
      }
      if (result is _AbortDueToInvalidExpressionConstant) {
        return new UnevaluatedConstant(
            // Create a new [InvalidExpression] without the expression, which
            // might now have lost the needed context. For instance references
            // to variables no longer in scope.
            new InvalidExpression(result.node.message));
      }
      throw "Unexpected error constant";
    }
    if (result is UnevaluatedConstant) {
      if (errorOnUnevaluatedConstant) {
        return createEvaluationErrorConstant(node, messageConstEvalUnevaluated);
      }
      return canonicalize(new UnevaluatedConstant(
          removeRedundantFileUriExpressions(result.expression)));
    }
    return result;
  }

  /// Execute a function body using the [StatementConstantEvaluator].
  Constant executeBody(Statement statement) {
    StatementConstantEvaluator statementEvaluator =
        new StatementConstantEvaluator(this);
    ExecutionStatus status = statement.accept(statementEvaluator);
    if (status is ReturnStatus) {
      Constant? value = status.value;
      if (value == null) {
        // Void return type from executing the function body.
        return new NullConstant();
      }
      return value;
    } else if (status is AbortStatus) {
      return status.error;
    } else if (status is ProceedStatus) {
      // No return statement in function body with void return type.
      return new NullConstant();
    }
    return createEvaluationErrorConstant(
        statement,
        templateConstEvalError.withArguments(
            'No valid constant returned from the execution of the '
            'statement.'));
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant? executeConstructorBody(Constructor constructor) {
    final Statement body = constructor.function.body!;
    StatementConstantEvaluator statementEvaluator =
        new StatementConstantEvaluator(this);
    ExecutionStatus status = body.accept(statementEvaluator);
    if (status is AbortStatus) {
      return status.error;
    } else if (status is ReturnStatus) {
      if (status.value == null) return null;
      // Should not be reachable.
      return createEvaluationErrorConstant(
          constructor,
          templateConstEvalError
              .withArguments("Constructors can't have a return value."));
    } else if (status is! ProceedStatus) {
      return createEvaluationErrorConstant(
          constructor,
          templateConstEvalError
              .withArguments("Invalid execution status of constructor body."));
    }
    return null;
  }

  /// Create an error-constant indicating that an error has been detected during
  /// constant evaluation.
  AbortConstant createEvaluationErrorConstant(TreeNode node, Message message,
      {List<LocatedMessage>? context}) {
    return new _AbortDueToErrorConstant(node, message,
        context: context, isEvaluationError: true);
  }

  /// Create an error-constant indicating that an non-constant expression has
  /// been found.
  AbortConstant createExpressionErrorConstant(TreeNode node, Message message,
      {List<LocatedMessage>? context}) {
    return new _AbortDueToErrorConstant(node, message,
        context: context, isEvaluationError: false);
  }

  /// Produce an unevaluated constant node for an expression.
  Constant unevaluated(Expression original, Expression replacement) {
    replacement.fileOffset = original.fileOffset;
    return new UnevaluatedConstant(
        new FileUriExpression(replacement, getFileUri(original)!)
          ..fileOffset = original.fileOffset);
  }

  Expression removeRedundantFileUriExpressions(Expression node) {
    return node.accept(new RedundantFileUriExpressionRemover()) as Expression;
  }

  /// Wrap a constant in a ConstantExpression.
  ///
  /// For use with unevaluated constants.
  ConstantExpression _wrap(Constant constant) {
    return new ConstantExpression(constant);
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

  Map<Uri, Set<Reference>> _constructorCoverage = {};

  ConstantCoverage getConstantCoverage() {
    return new ConstantCoverage(_constructorCoverage);
  }

  void _recordConstructorCoverage(Constructor constructor, TreeNode caller) {
    Uri currentUri = getFileUri(caller)!;
    Set<Reference> uriCoverage = _constructorCoverage[currentUri] ??= {};
    uriCoverage.add(constructor.reference);
  }

  /// Evaluate [node] and possibly cache the evaluation result.
  ///
  /// Returns [_AbortDueToErrorConstant] or
  /// [_AbortDueToInvalidExpressionConstant] (both of which is an
  /// [AbortConstant]) if the expression can't be evaluated.
  /// As such the return value should be checked (e.g. `is AbortConstant`)
  /// before further use.
  Constant _evaluateSubexpression(Expression node) {
    if (node is ConstantExpression) {
      if (node.constant is! UnevaluatedConstant) {
        // ConstantExpressions just pointing to an actual constant can be
        // short-circuited. Note that it's accepted instead of just returned to
        // get canonicalization.
        return node.accept(this);
      }
    } else if (node is BasicLiteral) {
      // Basic literals (string literals, int literals, double literals,
      // bool literals and null literals) can be short-circuited too.
      return node.accept(this);
    }

    bool wasUnevaluated = seenUnevaluatedChild;
    seenUnevaluatedChild = false;
    Constant result;
    if (env.isEmpty) {
      // We only try to evaluate the same [node] *once* within an empty
      // environment.
      // For const functions, recompute getters instead of using the cached
      // value.
      bool isGetter = node is InstanceGet;
      if (nodeCache.containsKey(node) && !(enableConstFunctions && isGetter)) {
        Constant? cachedResult = nodeCache[node];
        if (cachedResult == null) {
          // [null] is a sentinel value only used when still evaluating the same
          // node.
          return createEvaluationErrorConstant(
              node, messageConstEvalCircularity);
        }
        result = cachedResult;
      } else {
        nodeCache[node] = null;
        Constant evaluatedResult = node.accept(this);
        if (evaluatedResult is AbortConstant) {
          nodeCache.remove(node);
          return evaluatedResult;
        } else if (lazyDepth == 0) {
          nodeCache[node] = evaluatedResult;
        } else {
          // Don't cache nodes evaluated in a lazy region, since these are not
          // themselves unevaluated but just part of an unevaluated constant.
          nodeCache.remove(node);
        }
        result = evaluatedResult;
      }
    } else {
      bool sentinelInserted = false;
      if (nodeCache.containsKey(node)) {
        bool isRecursiveFunctionCall = node is InstanceInvocation ||
            node is FunctionInvocation ||
            node is LocalFunctionInvocation ||
            node is StaticInvocation;
        if (nodeCache[node] == null &&
            !(enableConstFunctions && isRecursiveFunctionCall)) {
          // recursive call
          return createEvaluationErrorConstant(
              node, messageConstEvalCircularity);
        }
        // else we've seen the node before and come to a result -> we won't
        // go into an infinite loop here either.
      } else {
        // We haven't seen this node before. Risk of loop.
        nodeCache[node] = null;
        sentinelInserted = true;
      }
      Constant evaluatedResult = node.accept(this);
      if (sentinelInserted) {
        nodeCache.remove(node);
      }
      if (evaluatedResult is AbortConstant) {
        return evaluatedResult;
      }
      result = evaluatedResult;
    }
    seenUnevaluatedChild = wasUnevaluated || result is UnevaluatedConstant;
    return result;
  }

  Constant _evaluateNullableSubexpression(Expression? node) {
    if (node == null) return nullConstant;
    return _evaluateSubexpression(node);
  }

  // TODO(johnniwinther): Remove this and handle each expression directly.
  @override
  Constant defaultExpression(Expression node) {
    // Only a subset of the expression language is valid for constant
    // evaluation.
    return createExpressionErrorConstant(node, messageNotAConstantExpression);
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
    DartType? type = _evaluateDartType(node, node.type);
    if (type != null) {
      type = convertType(type);
    }
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(type != null);
    return canonicalize(new TypeLiteralConstant(type));
  }

  @override
  Constant visitConstantExpression(ConstantExpression node) {
    Constant constant = node.constant;
    Constant result = constant;
    if (constant is UnevaluatedConstant) {
      if (hasEnvironment) {
        result = _evaluateSubexpression(constant.expression);
        if (result is AbortConstant) return result;
      } else {
        // Still no environment. Doing anything is just wasted time.
        result = constant;
      }
    }
    // If there were already constants in the AST then we make sure we
    // re-canonicalize them.  After running the transformer we will therefore
    // have a fully-canonicalized constant DAG with roots coming from the
    // [ConstantExpression] nodes in the AST.
    return canonicalize(result);
  }

  @override
  Constant visitListLiteral(ListLiteral node) {
    if (!node.isConst && !enableConstFunctions) {
      return createExpressionErrorConstant(
          node,
          templateNotConstantExpression
              .withArguments('Non-constant list literal'));
    }

    DartType? type = _evaluateDartType(node, node.typeArgument);
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(type != null);

    final ListConstantBuilder builder = new ListConstantBuilder(
        node, convertType(type), this,
        isMutable: !node.isConst);
    // These expressions are at the same level, so one of them being
    // unevaluated doesn't mean a sibling is or has an unevaluated child.
    // We therefore reset it before each call, combine it and set it correctly
    // at the end.
    bool wasOrBecameUnevaluated = seenUnevaluatedChild;
    for (Expression element in node.expressions) {
      seenUnevaluatedChild = false;
      AbortConstant? error = builder.add(element);
      wasOrBecameUnevaluated |= seenUnevaluatedChild;
      if (error != null) return error;
    }
    seenUnevaluatedChild = wasOrBecameUnevaluated;
    return builder.build();
  }

  @override
  Constant visitRecordLiteral(RecordLiteral node) {
    // A record literal is a compile-time constant expression if and only
    // if all its field expressions are compile-time constant expressions.
    //
    // This visitor is called when the context requires the literal to be
    // constant, so we report an error on the expressions when these are not
    // constants.

    List<Constant>? positional = _evaluatePositionalArguments(node.positional);
    if (positional == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(positional != null);

    Map<String, Constant>? named = _evaluateNamedArguments(node.named);
    if (named == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(named != null);

    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new RecordLiteral([
            for (Constant c in positional) _wrap(c),
          ], [
            for (String key in named.keys)
              new NamedExpression(key, _wrap(named[key]!)),
          ], node.recordType, isConst: true));
    }
    return canonicalize(new RecordConstant(
        positional, named, env.substituteType(node.recordType) as RecordType));
  }

  @override
  Constant visitListConcatenation(ListConcatenation node) {
    final ListConstantBuilder builder =
        new ListConstantBuilder(node, convertType(node.typeArgument), this);
    for (Expression list in node.lists) {
      AbortConstant? error = builder.addSpread(list);
      if (error != null) return error;
    }
    return builder.build();
  }

  @override
  Constant visitSetLiteral(SetLiteral node) {
    if (!node.isConst) {
      return createExpressionErrorConstant(
          node,
          templateNotConstantExpression
              .withArguments('Non-constant set literal'));
    }

    DartType? type = _evaluateDartType(node, node.typeArgument);
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(type != null);

    final SetConstantBuilder builder =
        new SetConstantBuilder(node, convertType(type), this);
    // These expressions are at the same level, so one of them being
    // unevaluated doesn't mean a sibling is or has an unevaluated child.
    // We therefore reset it before each call, combine it and set it correctly
    // at the end.
    bool wasOrBecameUnevaluated = seenUnevaluatedChild;
    for (Expression element in node.expressions) {
      seenUnevaluatedChild = false;
      AbortConstant? error = builder.add(element);
      wasOrBecameUnevaluated |= seenUnevaluatedChild;
      if (error != null) return error;
    }
    seenUnevaluatedChild = wasOrBecameUnevaluated;
    return builder.build();
  }

  @override
  Constant visitSetConcatenation(SetConcatenation node) {
    final SetConstantBuilder builder =
        new SetConstantBuilder(node, convertType(node.typeArgument), this);
    for (Expression set_ in node.sets) {
      AbortConstant? error = builder.addSpread(set_);
      if (error != null) return error;
    }
    return builder.build();
  }

  @override
  Constant visitMapLiteral(MapLiteral node) {
    if (!node.isConst) {
      return createExpressionErrorConstant(
          node,
          templateNotConstantExpression
              .withArguments('Non-constant map literal'));
    }

    DartType? keyType = _evaluateDartType(node, node.keyType);
    if (keyType == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(keyType != null);

    DartType? valueType = _evaluateDartType(node, node.valueType);
    if (valueType == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(valueType != null);

    final MapConstantBuilder builder = new MapConstantBuilder(
        node, convertType(keyType), convertType(valueType), this);
    // These expressions are at the same level, so one of them being
    // unevaluated doesn't mean a sibling is or has an unevaluated child.
    // We therefore reset it before each call, combine it and set it correctly
    // at the end.
    bool wasOrBecameUnevaluated = seenUnevaluatedChild;
    for (MapLiteralEntry element in node.entries) {
      seenUnevaluatedChild = false;
      AbortConstant? error = builder.add(element);
      wasOrBecameUnevaluated |= seenUnevaluatedChild;
      if (error != null) return error;
    }
    seenUnevaluatedChild = wasOrBecameUnevaluated;
    return builder.build();
  }

  @override
  Constant visitMapConcatenation(MapConcatenation node) {
    final MapConstantBuilder builder = new MapConstantBuilder(
        node, convertType(node.keyType), convertType(node.valueType), this);
    for (Expression map in node.maps) {
      AbortConstant? error = builder.addSpread(map);
      if (error != null) return error;
    }
    return builder.build();
  }

  @override
  Constant visitFunctionExpression(FunctionExpression node) {
    if (enableConstFunctions) {
      return new FunctionValue(node.function, env);
    }
    return createExpressionErrorConstant(node,
        templateNotConstantExpression.withArguments('Function expression'));
  }

  @override
  Constant visitConstructorInvocation(ConstructorInvocation node) {
    if (!node.isConst && !enableConstFunctions) {
      return createExpressionErrorConstant(
          node, templateNotConstantExpression.withArguments('New expression'));
    }

    final Constructor constructor = node.target;
    AbortConstant? error =
        checkConstructorConst(node, constructor, messageNonConstConstructor);
    if (error != null) return error;

    final Class klass = constructor.enclosingClass;
    if (klass.isAbstract) {
      // Probably unreachable.
      return createExpressionErrorConstant(
          node, templateAbstractClassInstantiation.withArguments(klass.name));
    }

    final List<Constant>? positional =
        _evaluatePositionalArguments(node.arguments.positional);
    if (positional == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(positional != null);

    final Map<String, Constant>? named =
        _evaluateNamedArguments(node.arguments.named);
    if (named == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(named != null);

    bool isSymbol = klass == coreTypes.internalSymbolClass;
    if (isSymbol && shouldBeUnevaluated) {
      return unevaluated(
          node,
          new ConstructorInvocation(constructor,
              unevaluatedArguments(positional, named, node.arguments.types),
              isConst: true));
    }

    // Special case the dart:core's Symbol class here and convert it to a
    // [SymbolConstant].  For invalid values we report a compile-time error.
    if (isSymbol) {
      final Constant nameValue = positional.single;

      // For libraries with null safety Symbol constructor accepts arbitrary
      // string as argument.
      if (nameValue is StringConstant &&
          (isNonNullableByDefault || isValidSymbolName(nameValue.value))) {
        return canonicalize(new SymbolConstant(nameValue.value, null));
      }
      return createEvaluationErrorConstant(
          node.arguments.positional.first,
          templateConstEvalInvalidSymbolName.withArguments(
              nameValue, isNonNullableByDefault));
    }

    List<DartType>? types = _evaluateTypeArguments(node, node.arguments);
    if (types == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(types != null);

    final List<DartType> typeArguments = convertTypes(types);

    // Fill in any missing type arguments with "dynamic".
    for (int i = typeArguments.length; i < klass.typeParameters.length; i++) {
      // Probably unreachable.
      typeArguments.add(const DynamicType());
    }

    // Start building a new instance.
    return withNewInstanceBuilder(klass, typeArguments, () {
      // "Run" the constructor (and any super constructor calls), which will
      // initialize the fields of the new instance.
      if (shouldBeUnevaluated) {
        enterLazy();
        AbortConstant? error = handleConstructorInvocation(
            constructor, typeArguments, positional, named, node);
        if (error != null) return error;
        leaveLazy();
        return unevaluated(node, instanceBuilder!.buildUnevaluatedInstance());
      }
      AbortConstant? error = handleConstructorInvocation(
          constructor, typeArguments, positional, named, node);
      if (error != null) return error;
      if (shouldBeUnevaluated) {
        return unevaluated(node, instanceBuilder!.buildUnevaluatedInstance());
      }
      return canonicalize(instanceBuilder!.buildInstance());
    });
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant? checkConstructorConst(
      TreeNode node, Constructor constructor, Message messageIfNonConst) {
    if (!constructor.isConst) {
      return createExpressionErrorConstant(node, messageIfNonConst);
    }
    if (constructor.function.body != null &&
        constructor.function.body is! EmptyStatement &&
        !enableConstFunctions) {
      // Probably unreachable.
      return createExpressionErrorConstant(
          node, messageConstConstructorWithBody);
    } else if (constructor.isExternal) {
      return createEvaluationErrorConstant(
          node, messageConstEvalExternalConstructor);
    }
    return null;
  }

  @override
  Constant visitInstanceCreation(InstanceCreation node) {
    return withNewInstanceBuilder(
        node.classNode, convertTypes(node.typeArguments), () {
      for (AssertStatement statement in node.asserts) {
        AbortConstant? error = checkAssert(statement);
        if (error != null) return error;
      }
      AbortConstant? error;
      for (MapEntry<Reference, Expression> entry in node.fieldValues.entries) {
        Reference fieldRef = entry.key;
        Expression value = entry.value;
        Constant constant = _evaluateSubexpression(value);
        if (constant is AbortConstant) {
          error = constant;
          break;
        }
        instanceBuilder!.setFieldValue(fieldRef.asField, constant);
      }
      if (error != null) return error;
      for (Expression value in node.unusedArguments) {
        if (error != null) return error;
        Constant constant = _evaluateSubexpression(value);
        if (constant is AbortConstant) {
          error ??= constant;
          return error;
        }
        if (constant is UnevaluatedConstant) {
          instanceBuilder!.unusedArguments.add(_wrap(constant));
        }
      }
      if (error != null) return error;
      if (shouldBeUnevaluated) {
        return unevaluated(node, instanceBuilder!.buildUnevaluatedInstance());
      }
      // We can get here when re-evaluating a previously unevaluated constant.
      return canonicalize(instanceBuilder!.buildInstance());
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

    const Set<String> operatorNames = const <String>{
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
    };

    // ignore: unnecessary_null_comparison
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

  static const Set<String> nonUsableKeywords = const <String>{
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
  };

  bool isValidPublicIdentifier(String name) {
    return publicIdentifierRegExp.hasMatch(name) &&
        !nonUsableKeywords.contains(name);
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant? handleConstructorInvocation(
      Constructor constructor,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments,
      TreeNode caller) {
    return withNewEnvironment(() {
      final Class klass = constructor.enclosingClass;
      final FunctionNode function = constructor.function;

      // Mark in file of the caller that we evaluate this specific constructor.
      _recordConstructorCoverage(constructor, caller);

      // We simulate now the constructor invocation.

      // Step 1) Map type arguments and normal arguments from caller to
      //         callee.
      for (int i = 0; i < klass.typeParameters.length; i++) {
        env.addTypeParameterValue(klass.typeParameters[i], typeArguments[i]);
      }
      for (int i = 0; i < function.positionalParameters.length; i++) {
        final VariableDeclaration parameter = function.positionalParameters[i];
        final Constant value = (i < positionalArguments.length)
            ? positionalArguments[i]
            // TODO(johnniwinther): This should call [_evaluateSubexpression].
            : _evaluateNullableSubexpression(parameter.initializer);
        if (value is AbortConstant) return value;
        env.addVariableValue(parameter, value);
      }
      for (final VariableDeclaration parameter in function.namedParameters) {
        final Constant value = namedArguments[parameter.name] ??
            // TODO(johnniwinther): This should call [_evaluateSubexpression].
            _evaluateNullableSubexpression(parameter.initializer);
        if (value is AbortConstant) return value;
        env.addVariableValue(parameter, value);
      }

      // Step 2) Run all initializers (including super calls) with environment
      //         setup.
      for (final Field field in klass.fields) {
        if (!field.isStatic) {
          Constant constant = _evaluateNullableSubexpression(field.initializer);
          if (constant is AbortConstant) return constant;
          instanceBuilder!.setFieldValue(field, constant);
        }
      }
      for (final Initializer init in constructor.initializers) {
        if (init is FieldInitializer) {
          Constant constant = _evaluateSubexpression(init.value);
          if (constant is AbortConstant) return constant;
          instanceBuilder!.setFieldValue(init.field, constant);
        } else if (init is LocalInitializer) {
          final VariableDeclaration variable = init.variable;
          Constant constant = _evaluateSubexpression(variable.initializer!);
          if (constant is AbortConstant) return constant;
          env.addVariableValue(variable, constant);
        } else if (init is SuperInitializer) {
          AbortConstant? error = checkConstructorConst(
              init, init.target, messageConstConstructorWithNonConstSuper);
          if (error != null) return error;
          List<DartType>? types = _evaluateSuperTypeArguments(
              init, constructor.enclosingClass.supertype!);
          if (types == null) {
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);
          // ignore: unnecessary_null_comparison
          assert(types != null);

          List<Constant>? positionalArguments =
              _evaluatePositionalArguments(init.arguments.positional);
          if (positionalArguments == null) {
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);
          // ignore: unnecessary_null_comparison
          assert(positionalArguments != null);
          Map<String, Constant>? namedArguments =
              _evaluateNamedArguments(init.arguments.named);
          if (namedArguments == null) {
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);
          // ignore: unnecessary_null_comparison
          assert(namedArguments != null);
          error = handleConstructorInvocation(
              init.target, types, positionalArguments, namedArguments, caller);
          if (error != null) return error;
        } else if (init is RedirectingInitializer) {
          // Since a redirecting constructor targets a constructor of the same
          // class, we pass the same [typeArguments].

          AbortConstant? error = checkConstructorConst(
              init, init.target, messageConstConstructorRedirectionToNonConst);
          if (error != null) return error;
          List<Constant>? positionalArguments =
              _evaluatePositionalArguments(init.arguments.positional);
          if (positionalArguments == null) {
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);
          // ignore: unnecessary_null_comparison
          assert(positionalArguments != null);

          Map<String, Constant>? namedArguments =
              _evaluateNamedArguments(init.arguments.named);
          if (namedArguments == null) {
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);
          // ignore: unnecessary_null_comparison
          assert(namedArguments != null);

          error = handleConstructorInvocation(init.target, typeArguments,
              positionalArguments, namedArguments, caller);
          if (error != null) return error;
        } else if (init is AssertInitializer) {
          AbortConstant? error = checkAssert(init.statement);
          if (error != null) return error;
        } else {
          // InvalidInitializer or new Initializers.
          // Probably unreachable. InvalidInitializer is (currently) only
          // created for classes with no constructors that doesn't have a
          // super that takes no arguments. It thus cannot be const.
          // Explicit constructors with incorrect super calls will get a
          // ShadowInvalidInitializer which is actually a LocalInitializer.
          assert(
              false,
              'No support for handling initializer of type '
              '"${init.runtimeType}".');
          return createEvaluationErrorConstant(
              init, messageNotAConstantExpression);
        }
      }

      for (UnevaluatedConstant constant in env.unevaluatedUnreadConstants) {
        instanceBuilder!.unusedArguments.add(_wrap(constant));
      }

      // ignore: unnecessary_null_comparison
      if (enableConstFunctions && constructor.function != null) {
        AbortConstant? error = executeConstructorBody(constructor);
        if (error != null) return error;
      }

      return null;
    });
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant? checkAssert(AssertStatement statement) {
    final Constant condition = _evaluateSubexpression(statement.condition);
    if (condition is AbortConstant) return condition;

    if (shouldBeUnevaluated) {
      Expression? message = null;
      if (statement.message != null) {
        enterLazy();
        Constant constant = _evaluateSubexpression(statement.message!);
        if (constant is AbortConstant) return constant;
        message = _wrap(constant);
        leaveLazy();
      }
      instanceBuilder!.asserts.add(new AssertStatement(_wrap(condition),
          message: message,
          conditionStartOffset: statement.conditionStartOffset,
          conditionEndOffset: statement.conditionEndOffset));
    } else if (condition is BoolConstant) {
      if (!condition.value) {
        if (statement.message == null) {
          return createEvaluationErrorConstant(
              statement.condition, messageConstEvalFailedAssertion);
        }
        final Constant message = _evaluateSubexpression(statement.message!);
        if (message is AbortConstant) return message;
        if (shouldBeUnevaluated) {
          instanceBuilder!.asserts.add(new AssertStatement(_wrap(condition),
              message: _wrap(message),
              conditionStartOffset: statement.conditionStartOffset,
              conditionEndOffset: statement.conditionEndOffset));
        } else if (message is StringConstant) {
          return createEvaluationErrorConstant(
              statement.condition,
              templateConstEvalFailedAssertionWithMessage
                  .withArguments(message.value));
        } else if (message is NullConstant) {
          return createEvaluationErrorConstant(
              statement.condition, messageConstEvalFailedAssertion);
        } else {
          return createEvaluationErrorConstant(statement.message!,
              messageConstEvalFailedAssertionWithNonStringMessage);
        }
      }
    } else {
      return createEvaluationErrorConstant(
          statement.condition,
          templateConstEvalInvalidType.withArguments(
              condition,
              typeEnvironment.coreTypes.boolLegacyRawType,
              condition.getType(staticTypeContext),
              isNonNullableByDefault));
    }

    return null;
  }

  @override
  Constant visitInvalidExpression(InvalidExpression node) {
    return new _AbortDueToInvalidExpressionConstant(node);
  }

  @override
  Constant visitDynamicInvocation(DynamicInvocation node) {
    // We have no support for generic method invocation at the moment.
    if (node.arguments.types.isNotEmpty) {
      return createExpressionErrorConstant(node,
          templateNotConstantExpression.withArguments("Dynamic invocation"));
    }

    // We have no support for method invocation with named arguments at the
    // moment.
    if (node.arguments.named.isNotEmpty) {
      return createExpressionErrorConstant(node,
          templateNotConstantExpression.withArguments("Dynamic invocation"));
    }

    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    final List<Constant>? positionalArguments =
        _evaluatePositionalArguments(node.arguments.positional);

    if (positionalArguments == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(positionalArguments != null);

    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new DynamicInvocation(
              node.kind,
              _wrap(receiver),
              node.name,
              unevaluatedArguments(
                  positionalArguments, {}, node.arguments.types))
            ..fileOffset = node.fileOffset);
    }

    return _handleInvocation(node, node.name, receiver, positionalArguments,
        arguments: node.arguments);
  }

  @override
  Constant visitInstanceInvocation(InstanceInvocation node) {
    // We have no support for generic method invocation at the moment.
    if (node.arguments.types.isNotEmpty) {
      return createExpressionErrorConstant(node,
          templateNotConstantExpression.withArguments("Instance invocation"));
    }

    // We have no support for method invocation with named arguments at the
    // moment.
    if (node.arguments.named.isNotEmpty) {
      return createExpressionErrorConstant(node,
          templateNotConstantExpression.withArguments("Instance invocation"));
    }

    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    final List<Constant>? positionalArguments =
        _evaluatePositionalArguments(node.arguments.positional);

    if (positionalArguments == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(positionalArguments != null);

    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new InstanceInvocation(
              node.kind,
              _wrap(receiver),
              node.name,
              unevaluatedArguments(
                  positionalArguments, {}, node.arguments.types),
              functionType: node.functionType,
              interfaceTarget: node.interfaceTarget)
            ..fileOffset = node.fileOffset
            ..flags = node.flags);
    }

    return _handleInvocation(node, node.name, receiver, positionalArguments,
        arguments: node.arguments);
  }

  @override
  Constant visitFunctionInvocation(FunctionInvocation node) {
    if (!enableConstFunctions) {
      return createExpressionErrorConstant(node,
          templateNotConstantExpression.withArguments('Function invocation'));
    }

    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;

    return _evaluateFunctionInvocation(node, receiver, node.arguments);
  }

  @override
  Constant visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    if (!enableConstFunctions) {
      return createExpressionErrorConstant(
          node,
          templateNotConstantExpression
              .withArguments('Local function invocation'));
    }

    final Constant receiver = env.lookupVariable(node.variable)!;
    // ignore: unnecessary_null_comparison
    assert(receiver != null);
    if (receiver is AbortConstant) return receiver;

    return _evaluateFunctionInvocation(node, receiver, node.arguments);
  }

  Constant _evaluateFunctionInvocation(
      TreeNode node, Constant receiver, Arguments arguments) {
    final List<Constant>? positional =
        _evaluatePositionalArguments(arguments.positional);

    if (positional == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(positional != null);

    // Evaluate type arguments of the function invoked.
    List<DartType>? types = _evaluateTypeArguments(node, arguments);
    if (types == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(types != null);

    // Evaluate named arguments of the function invoked.
    final Map<String, Constant>? named =
        _evaluateNamedArguments(arguments.named);
    if (named == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(named != null);

    if (receiver is FunctionValue) {
      return _handleFunctionInvocation(
          receiver.function, types, positional, named,
          functionEnvironment: receiver.environment);
    } else {
      return createEvaluationErrorConstant(
          node,
          templateConstEvalError
              .withArguments('Function invocation with invalid receiver.'));
    }
  }

  @override
  Constant visitEqualsCall(EqualsCall node) {
    final Constant left = _evaluateSubexpression(node.left);
    if (left is AbortConstant) return left;
    final Constant right = _evaluateSubexpression(node.right);
    if (right is AbortConstant) return right;
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new EqualsCall(_wrap(left), _wrap(right),
              functionType: node.functionType,
              interfaceTarget: node.interfaceTarget)
            ..fileOffset = node.fileOffset);
    }

    return _handleEquals(node, left, right);
  }

  @override
  Constant visitEqualsNull(EqualsNull node) {
    final Constant expression = _evaluateSubexpression(node.expression);
    if (expression is AbortConstant) return expression;

    if (shouldBeUnevaluated) {
      return unevaluated(node,
          new EqualsNull(_wrap(expression))..fileOffset = node.fileOffset);
    }

    return _handleEquals(node, expression, nullConstant);
  }

  Constant _handleEquals(Expression node, Constant left, Constant right) {
    if (staticTypeContext.enablePrimitiveEquality) {
      if (hasPrimitiveEqual(left, staticTypeContext: staticTypeContext) ||
          left is DoubleConstant ||
          right is NullConstant) {
        return doubleSpecialCases(left, right) ??
            makeBoolConstant(left == right);
      } else {
        return createEvaluationErrorConstant(
            node,
            templateConstEvalEqualsOperandNotPrimitiveEquality.withArguments(
                left, left.getType(staticTypeContext), isNonNullableByDefault));
      }
    } else {
      if (left is NullConstant ||
          left is BoolConstant ||
          left is IntConstant ||
          left is DoubleConstant ||
          left is StringConstant ||
          right is NullConstant) {
        // [DoubleConstant] uses [identical] to determine equality, so we need
        // to take the special cases into account.
        return doubleSpecialCases(left, right) ??
            makeBoolConstant(left == right);
      } else {
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidEqualsOperandType.withArguments(
                left, left.getType(staticTypeContext), isNonNullableByDefault));
      }
    }
  }

  Constant _handleInvocation(Expression node, Name name, Constant receiver,
      List<Constant> positionalArguments,
      {required Arguments arguments}) {
    final String op = name.text;

    // TODO(kallentu): Handle all constant toString methods.
    if (receiver is PrimitiveConstant &&
        op == 'toString' &&
        enableConstFunctions) {
      return new StringConstant(receiver.value.toString());
    }

    // Handle == and != first (it's common between all types). Since `a != b` is
    // parsed as `!(a == b)` it is handled implicitly through ==.
    if (positionalArguments.length == 1 && op == '==') {
      final Constant right = positionalArguments[0];
      return _handleEquals(node, receiver, right);
    }

    // This is a white-listed set of methods we need to support on constants.
    if (receiver is StringConstant) {
      if (positionalArguments.length == 1) {
        final Constant other = positionalArguments[0];
        switch (op) {
          case '+':
            if (other is StringConstant) {
              return canonicalize(
                  new StringConstant(receiver.value + other.value));
            }
            return createEvaluationErrorConstant(
                node,
                templateConstEvalInvalidBinaryOperandType.withArguments(
                    '+',
                    receiver,
                    typeEnvironment.coreTypes.stringLegacyRawType,
                    other.getType(staticTypeContext),
                    isNonNullableByDefault));
          case '[]':
            if (enableConstFunctions) {
              int? index = intFolder.asInt(other);
              if (index != null) {
                if (index < 0 || index >= receiver.value.length) {
                  return new _AbortDueToThrowConstant(
                      node, new RangeError.index(index, receiver.value));
                }
                return canonicalize(new StringConstant(receiver.value[index]));
              }
              return createEvaluationErrorConstant(
                  node,
                  templateConstEvalInvalidBinaryOperandType.withArguments(
                      '[]',
                      receiver,
                      typeEnvironment.coreTypes.intNonNullableRawType,
                      other.getType(staticTypeContext),
                      isNonNullableByDefault));
            }
        }
      }
    } else if (intFolder.isInt(receiver)) {
      if (positionalArguments.length == 0) {
        return canonicalize(intFolder.foldUnaryOperator(node, op, receiver));
      } else if (positionalArguments.length == 1) {
        final Constant other = positionalArguments[0];
        if (intFolder.isInt(other)) {
          return canonicalize(
              intFolder.foldBinaryOperator(node, op, receiver, other));
        } else if (other is DoubleConstant) {
          if ((op == '|' || op == '&' || op == '^') ||
              (op == '<<' || op == '>>' || op == '>>>')) {
            return createEvaluationErrorConstant(
                node,
                templateConstEvalInvalidBinaryOperandType.withArguments(
                    op,
                    other,
                    typeEnvironment.coreTypes.intLegacyRawType,
                    other.getType(staticTypeContext),
                    isNonNullableByDefault));
          }
          num receiverValue = (receiver as PrimitiveConstant<num>).value;
          return canonicalize(evaluateBinaryNumericOperation(
              op, receiverValue, other.value, node));
        }
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.numLegacyRawType,
                other.getType(staticTypeContext),
                isNonNullableByDefault));
      }
    } else if (receiver is DoubleConstant) {
      if ((op == '|' || op == '&' || op == '^') ||
          (op == '<<' || op == '>>' || op == '>>>')) {
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.intLegacyRawType,
                receiver.getType(staticTypeContext),
                isNonNullableByDefault));
      }
      if (positionalArguments.length == 0) {
        switch (op) {
          case 'unary-':
            return canonicalize(new DoubleConstant(-receiver.value));
        }
      } else if (positionalArguments.length == 1) {
        final Constant other = positionalArguments[0];

        if (other is IntConstant || other is DoubleConstant) {
          final num value = (other as PrimitiveConstant<num>).value;
          return canonicalize(
              evaluateBinaryNumericOperation(op, receiver.value, value, node));
        }
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.numLegacyRawType,
                other.getType(staticTypeContext),
                isNonNullableByDefault));
      }
    } else if (receiver is BoolConstant) {
      if (positionalArguments.length == 1) {
        final Constant other = positionalArguments[0];
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
      return createEvaluationErrorConstant(node, messageConstEvalNullValue);
    } else if (receiver is ListConstant && enableConstFunctions) {
      if (positionalArguments.length == 1) {
        final Constant other = positionalArguments[0];
        switch (op) {
          case '[]':
            int? index = intFolder.asInt(other);
            if (index != null) {
              if (index < 0 || index >= receiver.entries.length) {
                return new _AbortDueToThrowConstant(
                    node, new RangeError.index(index, receiver.entries));
              }
              return receiver.entries[index];
            }
            return createEvaluationErrorConstant(
                node,
                templateConstEvalInvalidBinaryOperandType.withArguments(
                    '[]',
                    receiver,
                    typeEnvironment.coreTypes.intNonNullableRawType,
                    other.getType(staticTypeContext),
                    isNonNullableByDefault));
          case 'add':
            if (receiver is MutableListConstant) {
              receiver.entries.add(other);
              return receiver;
            }
            return new _AbortDueToThrowConstant(node, new UnsupportedError(op));
        }
      }
    } else if (receiver is MapConstant && enableConstFunctions) {
      if (positionalArguments.length == 1) {
        final Constant other = positionalArguments[0];
        switch (op) {
          case '[]':
            for (ConstantMapEntry entry in receiver.entries) {
              if (entry.key == other) {
                return entry.value;
              }
            }
            return new NullConstant();
        }
      }
    } else if (enableConstFunctions) {
      // Evaluate type arguments of the method invoked.
      List<DartType>? typeArguments = _evaluateTypeArguments(node, arguments);
      if (typeArguments == null) {
        AbortConstant error = _gotError!;
        _gotError = null;
        return error;
      }
      assert(_gotError == null);
      // ignore: unnecessary_null_comparison
      assert(typeArguments != null);

      // Evaluate named arguments of the method invoked.
      final Map<String, Constant>? namedArguments =
          _evaluateNamedArguments(arguments.named);
      if (namedArguments == null) {
        AbortConstant error = _gotError!;
        _gotError = null;
        return error;
      }
      assert(_gotError == null);
      // ignore: unnecessary_null_comparison
      assert(namedArguments != null);

      if (receiver is FunctionValue && name == Name.callName) {
        return _handleFunctionInvocation(receiver.function, typeArguments,
            positionalArguments, namedArguments,
            functionEnvironment: receiver.environment);
      } else if (receiver is InstanceConstant) {
        final Class instanceClass = receiver.classNode;
        final Member member =
            typeEnvironment.hierarchy.getDispatchTarget(instanceClass, name)!;
        final FunctionNode? function = member.function;

        // TODO(kallentu): Implement [Object] class methods which have backend
        // specific functions that cannot be run by the constant evaluator.
        final bool isObjectMember = member.enclosingClass != null &&
            member.enclosingClass!.name == "Object";
        if (function != null && !isObjectMember) {
          // TODO(johnniwinther): Make [typeArguments] and [namedArguments]
          // required and non-nullable.
          return withNewInstanceBuilder(instanceClass, typeArguments, () {
            final EvaluationEnvironment newEnv = new EvaluationEnvironment();
            for (int i = 0; i < instanceClass.typeParameters.length; i++) {
              newEnv.addTypeParameterValue(
                  instanceClass.typeParameters[i], receiver.typeArguments[i]);
            }

            // Ensure that fields are visible for instance access.
            receiver.fieldValues.forEach((Reference fieldRef, Constant value) =>
                instanceBuilder!.setFieldValue(fieldRef.asField, value));
            return _handleFunctionInvocation(function, receiver.typeArguments,
                positionalArguments, namedArguments,
                functionEnvironment: newEnv);
          });
        }

        switch (op) {
          case 'toString':
            // Default value for toString() of instances.
            return new StringConstant("Instance of "
                "'${receiver.classReference.toText(defaultAstTextStrategy)}'");
        }
      }
    }

    return createEvaluationErrorConstant(
        node,
        templateConstEvalInvalidMethodInvocation.withArguments(
            op, receiver, isNonNullableByDefault));
  }

  @override
  Constant visitLogicalExpression(LogicalExpression node) {
    final Constant left = _evaluateSubexpression(node.left);
    if (left is AbortConstant) return left;
    if (shouldBeUnevaluated) {
      enterLazy();
      Constant right = _evaluateSubexpression(node.right);
      if (right is AbortConstant) return right;
      leaveLazy();
      return unevaluated(node,
          new LogicalExpression(_wrap(left), node.operatorEnum, _wrap(right)));
    }
    switch (node.operatorEnum) {
      case LogicalExpressionOperator.OR:
        if (left is BoolConstant) {
          if (left.value) return trueConstant;

          final Constant right = _evaluateSubexpression(node.right);
          if (right is AbortConstant) return right;
          if (right is BoolConstant || right is UnevaluatedConstant) {
            return right;
          }

          return createEvaluationErrorConstant(
              node,
              templateConstEvalInvalidBinaryOperandType.withArguments(
                  logicalExpressionOperatorToString(node.operatorEnum),
                  left,
                  typeEnvironment.coreTypes.boolLegacyRawType,
                  right.getType(staticTypeContext),
                  isNonNullableByDefault));
        }
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                logicalExpressionOperatorToString(node.operatorEnum),
                left,
                isNonNullableByDefault));
      case LogicalExpressionOperator.AND:
        if (left is BoolConstant) {
          if (!left.value) return falseConstant;

          final Constant right = _evaluateSubexpression(node.right);
          if (right is AbortConstant) return right;
          if (right is BoolConstant || right is UnevaluatedConstant) {
            return right;
          }

          return createEvaluationErrorConstant(
              node,
              templateConstEvalInvalidBinaryOperandType.withArguments(
                  logicalExpressionOperatorToString(node.operatorEnum),
                  left,
                  typeEnvironment.coreTypes.boolLegacyRawType,
                  right.getType(staticTypeContext),
                  isNonNullableByDefault));
        }
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                logicalExpressionOperatorToString(node.operatorEnum),
                left,
                isNonNullableByDefault));
      default:
        // Probably unreachable.
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidMethodInvocation.withArguments(
                logicalExpressionOperatorToString(node.operatorEnum),
                left,
                isNonNullableByDefault));
    }
  }

  @override
  Constant visitConditionalExpression(ConditionalExpression node) {
    final Constant condition = _evaluateSubexpression(node.condition);
    if (condition is AbortConstant) return condition;
    if (condition == trueConstant) {
      return _evaluateSubexpression(node.then);
    } else if (condition == falseConstant) {
      return _evaluateSubexpression(node.otherwise);
    } else if (shouldBeUnevaluated) {
      enterLazy();
      Constant then = _evaluateSubexpression(node.then);
      if (then is AbortConstant) return then;
      Constant otherwise = _evaluateSubexpression(node.otherwise);
      if (otherwise is AbortConstant) return otherwise;
      leaveLazy();
      return unevaluated(
          node,
          new ConditionalExpression(_wrap(condition), _wrap(then),
              _wrap(otherwise), env.substituteType(node.staticType)));
    } else {
      return createEvaluationErrorConstant(
          node.condition,
          templateConstEvalInvalidType.withArguments(
              condition,
              typeEnvironment.coreTypes.boolLegacyRawType,
              condition.getType(staticTypeContext),
              isNonNullableByDefault));
    }
  }

  @override
  Constant visitInstanceGet(InstanceGet node) {
    if (node.receiver is ThisExpression) {
      // Probably unreachable unless trying to evaluate non-const stuff as
      // const.
      // Access "this" during instance creation.
      if (instanceBuilder == null) {
        return createEvaluationErrorConstant(
            node, messageNotAConstantExpression);
      }

      for (final MapEntry<Field, Constant> entry
          in instanceBuilder!.fields.entries) {
        final Field field = entry.key;
        if (field.name == node.name) {
          return entry.value;
        }
      }

      // Meant as a "stable backstop for situations where Fasta fails to
      // rewrite various erroneous constructs into invalid expressions".
      // Probably unreachable.
      return createEvaluationErrorConstant(
          node,
          templateConstEvalError.withArguments(
              'Could not evaluate field get ${node.name} on incomplete '
              'instance'));
    }

    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    if (receiver is StringConstant && node.name.text == 'length') {
      return canonicalize(intFolder.makeIntConstant(receiver.value.length));
    } else if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new InstanceGet(node.kind, _wrap(receiver), node.name,
              resultType: node.resultType,
              interfaceTarget: node.interfaceTarget));
    } else if (receiver is NullConstant) {
      return createEvaluationErrorConstant(node, messageConstEvalNullValue);
    } else if (receiver is ListConstant && enableConstFunctions) {
      switch (node.name.text) {
        case 'first':
          if (receiver.entries.isEmpty) {
            return new _AbortDueToThrowConstant(
                node, new StateError('No element'));
          }
          return receiver.entries.first;
        case 'isEmpty':
          return new BoolConstant(receiver.entries.isEmpty);
        case 'isNotEmpty':
          return new BoolConstant(receiver.entries.isNotEmpty);
        // TODO(kallentu): case 'iterator'
        case 'last':
          if (receiver.entries.isEmpty) {
            return new _AbortDueToThrowConstant(
                node, new StateError('No element'));
          }
          return receiver.entries.last;
        case 'length':
          return new IntConstant(receiver.entries.length);
        // TODO(kallentu): case 'reversed'
        case 'single':
          if (receiver.entries.isEmpty) {
            return new _AbortDueToThrowConstant(
                node, new StateError('No element'));
          } else if (receiver.entries.length > 1) {
            return new _AbortDueToThrowConstant(
                node, new StateError('Too many elements'));
          }
          return receiver.entries.single;
      }
    } else if (receiver is InstanceConstant && enableConstFunctions) {
      for (final MapEntry<Reference, Constant> entry
          in receiver.fieldValues.entries) {
        final Field field = entry.key.asField;
        if (field.name == node.name) {
          return entry.value;
        }
      }
    }
    return createEvaluationErrorConstant(
        node,
        templateConstEvalInvalidPropertyGet.withArguments(
            node.name.text, receiver, isNonNullableByDefault));
  }

  @override
  Constant visitRecordIndexGet(RecordIndexGet node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    if (receiver is RecordConstant && enableConstFunctions) {
      if (node.index >= receiver.positional.length) {
        return new _AbortDueToThrowConstant(node, new StateError('No element'));
      }
      return receiver.positional[node.index];
    }
    return createEvaluationErrorConstant(
        node,
        templateConstEvalInvalidRecordIndexGet.withArguments(
            "${node.index}", receiver, isNonNullableByDefault));
  }

  @override
  Constant visitRecordNameGet(RecordNameGet node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    if (receiver is RecordConstant && enableConstFunctions) {
      Constant? result = receiver.named[node.name];
      if (result == null) {
        return new _AbortDueToThrowConstant(node, new StateError('No element'));
      } else {
        return result;
      }
    }
    return createEvaluationErrorConstant(
        node,
        templateConstEvalInvalidRecordNameGet.withArguments(
            node.name, receiver, isNonNullableByDefault));
  }

  @override
  Constant visitDynamicGet(DynamicGet node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    if (receiver is StringConstant && node.name.text == 'length') {
      return canonicalize(intFolder.makeIntConstant(receiver.value.length));
    } else if (shouldBeUnevaluated) {
      return unevaluated(
          node, new DynamicGet(node.kind, _wrap(receiver), node.name));
    } else if (receiver is NullConstant) {
      return createEvaluationErrorConstant(node, messageConstEvalNullValue);
    }
    return createEvaluationErrorConstant(
        node,
        templateConstEvalInvalidPropertyGet.withArguments(
            node.name.text, receiver, isNonNullableByDefault));
  }

  @override
  Constant visitInstanceTearOff(InstanceTearOff node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    return createEvaluationErrorConstant(
        node,
        templateConstEvalInvalidPropertyGet.withArguments(
            node.name.text, receiver, isNonNullableByDefault));
  }

  @override
  Constant visitFunctionTearOff(FunctionTearOff node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    return createEvaluationErrorConstant(
        node,
        templateConstEvalInvalidPropertyGet.withArguments(
            Name.callName.text, receiver, isNonNullableByDefault));
  }

  @override
  Constant visitLet(Let node) {
    Constant value = _evaluateSubexpression(node.variable.initializer!);
    if (value is AbortConstant) return value;
    env.addVariableValue(node.variable, value);
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
    if (enableConstFunctions) {
      return env.lookupVariable(variable) ??
          createEvaluationErrorConstant(
              node,
              templateConstEvalGetterNotFound
                  .withArguments(variable.name ?? ''));
    } else {
      if (variable.parent is Let ||
          variable.parent is LocalInitializer ||
          _isFormalParameter(variable)) {
        return env.lookupVariable(node.variable) ??
            createEvaluationErrorConstant(
                node,
                templateConstEvalNonConstantVariableGet
                    .withArguments(variable.name ?? ''));
      }
      if (variable.isConst) {
        return _evaluateSubexpression(variable.initializer!);
      }
    }
    return createExpressionErrorConstant(
        node,
        templateNotConstantExpression
            .withArguments('Read of a non-const variable'));
  }

  @override
  Constant visitVariableSet(VariableSet node) {
    if (enableConstFunctions) {
      final VariableDeclaration variable = node.variable;
      Constant value = _evaluateSubexpression(node.value);
      if (value is AbortConstant) return value;
      Constant? result = env.updateVariableValue(variable, value);
      if (result != null) {
        return result;
      }
      return createEvaluationErrorConstant(
          node,
          templateConstEvalError
              .withArguments('Variable set of an unknown value.'));
    }
    return defaultExpression(node);
  }

  /// Computes the constant for [expression] defined in the context of [member].
  ///
  /// This compute the constant as seen in the current evaluation mode even when
  /// the constant is defined in a library compiled with the agnostic evaluation
  /// mode.
  Constant evaluateExpressionInContext(Member member, Expression expression) {
    StaticTypeContext? oldStaticTypeContext = _staticTypeContext;
    _staticTypeContext = new StaticTypeContext(member, typeEnvironment);
    Constant constant = _evaluateSubexpression(expression);
    if (constant is! AbortConstant) {
      if (staticTypeContext.nonNullableByDefaultCompiledMode ==
              NonNullableByDefaultCompiledMode.Agnostic &&
          evaluationMode == EvaluationMode.weak) {
        constant = _weakener.visitConstant(constant) ?? constant;
      }
    }
    _staticTypeContext = oldStaticTypeContext;
    return constant;
  }

  @override
  Constant visitStaticGet(StaticGet node) {
    return withNewEnvironment(() {
      final Member target = node.target;
      visitedLibraries.add(target.enclosingLibrary);
      if (target is Field) {
        if (target.isConst) {
          return evaluateExpressionInContext(target, target.initializer!);
        }
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidStaticInvocation
                .withArguments(target.name.text));
      } else if (target is Procedure && target.kind == ProcedureKind.Method) {
        // TODO(johnniwinther): Remove this. This should never occur.
        return canonicalize(new StaticTearOffConstant(target));
      } else {
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidStaticInvocation
                .withArguments(target.name.text));
      }
    });
  }

  @override
  Constant visitStaticTearOff(StaticTearOff node) {
    return canonicalize(new StaticTearOffConstant(node.target));
  }

  @override
  Constant visitStringConcatenation(StringConcatenation node) {
    final List<Object> concatenated = <Object>[new StringBuffer()];
    for (int i = 0; i < node.expressions.length; i++) {
      Constant constant = _evaluateSubexpression(node.expressions[i]);
      if (constant is AbortConstant) return constant;
      if (constant is PrimitiveConstant) {
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
        return createEvaluationErrorConstant(
            node,
            templateConstEvalInvalidStringInterpolationOperand.withArguments(
                constant, isNonNullableByDefault));
      }
    }
    if (concatenated.length > 1) {
      final List<Expression> expressions =
          new List<Expression>.generate(concatenated.length, (int i) {
        Object value = concatenated[i];
        if (value is StringBuffer) {
          return new ConstantExpression(
              canonicalize(new StringConstant(value.toString())));
        } else {
          // The value is either unevaluated constant or a non-primitive
          // constant in an unevaluated expression.
          return _wrap(value as Constant);
        }
      }, growable: false);
      return unevaluated(node, new StringConcatenation(expressions));
    }
    return canonicalize(new StringConstant(concatenated.single.toString()));
  }

  Constant _getFromEnvironmentDefaultValue(Procedure target) {
    VariableDeclaration variable = target.function.namedParameters
        .singleWhere((v) => v.name == 'defaultValue');
    return evaluateExpressionInContext(target, variable.initializer!);
  }

  Constant _handleFromEnvironment(
      Procedure target, StringConstant name, Map<String, Constant> named) {
    String? value = lookupEnvironment(name.value);
    Constant? defaultValue = named["defaultValue"];
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
          // Probably unreachable.
          boolConstant = falseConstant;
        }
      } else {
        boolConstant = _getFromEnvironmentDefaultValue(target);
      }
      return boolConstant;
    } else if (target.enclosingClass == coreTypes.intClass) {
      int? intValue = value != null ? int.tryParse(value) : null;
      Constant intConstant;
      if (intValue != null) {
        bool negated = value!.startsWith('-');
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
    // Unreachable until fromEnvironment is added to other classes in dart:core
    // than bool, int and String.
    throw new UnsupportedError(
        'Unexpected fromEnvironment constructor: $target');
  }

  Constant _handleHasEnvironment(StringConstant name) {
    return hasEnvironmentKey(name.value) ? trueConstant : falseConstant;
  }

  @override
  Constant visitStaticInvocation(StaticInvocation node) {
    final Procedure target = node.target;
    final Arguments arguments = node.arguments;
    List<DartType>? types = _evaluateTypeArguments(node, arguments);
    if (types == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(types != null);

    final List<DartType> typeArguments = convertTypes(types);

    final List<Constant>? positional =
        _evaluatePositionalArguments(arguments.positional);
    if (positional == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(positional != null);

    final Map<String, Constant>? named =
        _evaluateNamedArguments(arguments.named);
    if (named == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(named != null);

    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new StaticInvocation(
              target, unevaluatedArguments(positional, named, arguments.types),
              isConst: true));
    }
    if (target.kind == ProcedureKind.Factory) {
      if (target.isConst) {
        if (target.enclosingLibrary == coreTypes.coreLibrary &&
            positional.length == 1 &&
            (target.name.text == "fromEnvironment" ||
                target.name.text == "hasEnvironment")) {
          if (hasEnvironment) {
            // Evaluate environment constant.
            Constant name = positional.single;
            if (name is StringConstant) {
              if (target.name.text == "fromEnvironment") {
                return _handleFromEnvironment(target, name, named);
              } else {
                return _handleHasEnvironment(name);
              }
            } else if (name is NullConstant) {
              return createEvaluationErrorConstant(
                  node, messageConstEvalNullValue);
            }
          } else {
            // Leave environment constant unevaluated.
            return unevaluated(
                node,
                new StaticInvocation(target,
                    unevaluatedArguments(positional, named, arguments.types),
                    isConst: true));
          }
        } else if (target.isExternal) {
          return createEvaluationErrorConstant(
              node, messageConstEvalExternalFactory);
        } else if (enableConstFunctions) {
          return _handleFunctionInvocation(
              node.target.function, typeArguments, positional, named);
        } else {
          return createExpressionErrorConstant(
              node,
              templateNotConstantExpression
                  .withArguments('Non-redirecting const factory invocation'));
        }
      } else {
        if (enableConstFunctions) {
          return _handleFunctionInvocation(
              node.target.function, typeArguments, positional, named);
        } else if (!node.isConst) {
          return createExpressionErrorConstant(node,
              templateNotConstantExpression.withArguments('New expression'));
        } else {
          return createEvaluationErrorConstant(
              node,
              templateNotConstantExpression
                  .withArguments('Non-const factory invocation'));
        }
      }
    } else if (target.name.text == 'identical') {
      // Ensure the "identical()" function comes from dart:core.
      final TreeNode? parent = target.parent;
      if (parent is Library && parent == coreTypes.coreLibrary) {
        final Constant left = positional[0];
        final Constant right = positional[1];

        Constant evaluateIdentical() {
          // Since we canonicalize constants during the evaluation, we can use
          // identical here.
          Constant result = makeBoolConstant(identical(left, right));
          if (evaluationMode == EvaluationMode.agnostic) {
            Constant? weakLeft = _weakener.visitConstant(left);
            Constant? weakRight = _weakener.visitConstant(right);
            if (weakLeft != null || weakRight != null) {
              Constant weakResult = makeBoolConstant(
                  identical(weakLeft ?? left, weakRight ?? right));
              if (!identical(result, weakResult)) {
                return createEvaluationErrorConstant(
                    node, messageNonAgnosticConstant);
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
      return createEvaluationErrorConstant(node, messageConstEvalExtension);
    } else if (enableConstFunctions && target.kind == ProcedureKind.Method) {
      return _handleFunctionInvocation(
          node.target.function, typeArguments, positional, named);
    }

    return createExpressionErrorConstant(
        node, templateNotConstantExpression.withArguments('Static invocation'));
  }

  Constant _handleFunctionInvocation(
      FunctionNode function,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments,
      {EvaluationEnvironment? functionEnvironment}) {
    Constant executeFunction() {
      // Map arguments from caller to callee.
      for (int i = 0; i < function.typeParameters.length; i++) {
        env.addTypeParameterValue(function.typeParameters[i], typeArguments[i]);
      }
      for (int i = 0; i < function.positionalParameters.length; i++) {
        final VariableDeclaration parameter = function.positionalParameters[i];
        final Constant value = (i < positionalArguments.length)
            ? positionalArguments[i]
            // TODO(johnniwinther): This should call [_evaluateSubexpression].
            : _evaluateNullableSubexpression(parameter.initializer);
        if (value is AbortConstant) return value;
        env.addVariableValue(parameter, value);
      }
      for (final VariableDeclaration parameter in function.namedParameters) {
        final Constant value = namedArguments[parameter.name] ??
            // TODO(johnniwinther): This should call [_evaluateSubexpression].
            _evaluateNullableSubexpression(parameter.initializer);
        if (value is AbortConstant) return value;
        env.addVariableValue(parameter, value);
      }

      final Constant result = executeBody(function.body!);
      if (result is NullConstant &&
          function.returnType.nullability == Nullability.nonNullable) {
        // Ensure that the evaluated constant returned is not null if the
        // function has a non-nullable return type.
        return createEvaluationErrorConstant(
            function,
            templateConstEvalInvalidType.withArguments(
                result,
                function.returnType,
                result.getType(staticTypeContext),
                isNonNullableByDefault));
      }
      return result;
    }

    if (functionEnvironment != null) {
      return withEnvironment(functionEnvironment, executeFunction);
    }
    return withNewEnvironment(executeFunction);
  }

  @override
  Constant visitAsExpression(AsExpression node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (constant is AbortConstant) return constant;
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new AsExpression(_wrap(constant), env.substituteType(node.type))
            ..isForNonNullableByDefault =
                staticTypeContext.isNonNullableByDefault);
    }
    DartType? type = _evaluateDartType(node, node.type);
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(type != null);
    return ensureIsSubtype(constant, type, node);
  }

  @override
  Constant visitIsExpression(IsExpression node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (constant is AbortConstant) return constant;
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new IsExpression(_wrap(constant), env.substituteType(node.type))
            ..fileOffset = node.fileOffset
            ..flags = node.flags);
    }

    DartType? type = _evaluateDartType(node, node.type);
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    // ignore: unnecessary_null_comparison
    assert(type != null);

    bool performIs(Constant constant, {required bool strongMode}) {
      // ignore: unnecessary_null_comparison
      assert(strongMode != null);
      if (strongMode) {
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
            return typeEnvironment.isSubtypeOf(type, const NullType(),
                    SubtypeCheckMode.ignoringNullabilities) ||
                typeEnvironment.isSubtypeOf(typeEnvironment.objectLegacyRawType,
                    type, SubtypeCheckMode.ignoringNullabilities);
          } else {
            return typeEnvironment.isSubtypeOf(
                const NullType(), type, SubtypeCheckMode.withNullabilities);
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
          return createEvaluationErrorConstant(
              node, messageNonAgnosticConstant);
        }
        return makeBoolConstant(strongResult);
      case EvaluationMode.weak:
        return makeBoolConstant(performIs(constant, strongMode: false));
    }
  }

  @override
  Constant visitNot(Not node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (constant is AbortConstant) return constant;
    if (constant is BoolConstant) {
      return makeBoolConstant(constant != trueConstant);
    }
    if (shouldBeUnevaluated) {
      return unevaluated(node, new Not(_wrap(constant)));
    }
    return createEvaluationErrorConstant(
        node,
        templateConstEvalInvalidType.withArguments(
            constant,
            typeEnvironment.coreTypes.boolLegacyRawType,
            constant.getType(staticTypeContext),
            isNonNullableByDefault));
  }

  @override
  Constant visitNullCheck(NullCheck node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (constant is AbortConstant) return constant;
    if (constant is NullConstant) {
      return createEvaluationErrorConstant(node, messageConstEvalNonNull);
    }
    if (shouldBeUnevaluated) {
      return unevaluated(node, new NullCheck(_wrap(constant)));
    }
    return constant;
  }

  @override
  Constant visitSymbolLiteral(SymbolLiteral node) {
    final Reference? libraryReference =
        node.value.startsWith('_') ? currentLibrary.reference : null;
    return canonicalize(new SymbolConstant(node.value, libraryReference));
  }

  @override
  Constant visitThrow(Throw node) {
    if (enableConstFunctions) {
      final Constant value = _evaluateSubexpression(node.expression);
      if (value is AbortConstant) return value;
      return new _AbortDueToThrowConstant(node, value);
    }
    return defaultExpression(node);
  }

  @override
  Constant visitInstantiation(Instantiation node) {
    Constant constant = _evaluateSubexpression(node.expression);
    if (constant is AbortConstant) return constant;
    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new Instantiation(_wrap(constant),
              node.typeArguments.map((t) => env.substituteType(t)).toList()));
    }
    List<TypeParameter>? typeParameters;
    if (constant is TearOffConstant) {
      Member target = constant.target;
      if (target is Procedure) {
        typeParameters = target.function.typeParameters;
      } else if (target is Constructor) {
        typeParameters = target.enclosingClass.typeParameters;
      }
    } else if (constant is TypedefTearOffConstant) {
      typeParameters = constant.parameters;
    }
    if (typeParameters != null) {
      if (node.typeArguments.length == typeParameters.length) {
        List<DartType>? types = _evaluateDartTypes(node, node.typeArguments);
        if (types == null) {
          AbortConstant error = _gotError!;
          _gotError = null;
          return error;
        }
        assert(_gotError == null);
        // ignore: unnecessary_null_comparison
        assert(types != null);

        return canonicalize(
            new InstantiationConstant(constant, convertTypes(types)));
      } else {
        // Probably unreachable.
        return createEvaluationErrorConstant(
            node,
            templateConstEvalError.withArguments(
                'The number of type arguments supplied in the partial '
                'instantiation does not match the number of type arguments '
                'of the $constant.'));
      }
    }
    // The inner expression in an instantiation can never be null, since
    // instantiations are only inferred on direct references to declarations.
    // Probably unreachable.
    return createEvaluationErrorConstant(
        node,
        templateConstEvalError.withArguments(
            'Only tear-off constants can be partially instantiated.'));
  }

  @override
  Constant visitConstructorTearOff(ConstructorTearOff node) {
    return canonicalize(new ConstructorTearOffConstant(node.target));
  }

  @override
  Constant visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    return canonicalize(new RedirectingFactoryTearOffConstant(node.target));
  }

  @override
  Constant visitTypedefTearOff(TypedefTearOff node) {
    final Constant constant = _evaluateSubexpression(node.expression);
    if (constant is TearOffConstant) {
      FreshTypeParameters freshTypeParameters =
          getFreshTypeParameters(node.typeParameters);
      List<TypeParameter> typeParameters =
          freshTypeParameters.freshTypeParameters;
      List<DartType> typeArguments = new List<DartType>.generate(
          node.typeArguments.length,
          (int i) => freshTypeParameters.substitute(node.typeArguments[i]),
          growable: false);
      return canonicalize(
          new TypedefTearOffConstant(typeParameters, constant, typeArguments));
    } else {
      // Probably unreachable.
      return createEvaluationErrorConstant(
          node,
          templateConstEvalError.withArguments(
              "Unsupported typedef tearoff target: ${constant}."));
    }
  }

  @override
  Constant visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return createEvaluationErrorConstant(node,
        templateConstEvalDeferredLibrary.withArguments(node.import.name!));
  }

  // Helper methods:

  /// If both constants are DoubleConstant whose values would give different
  /// results from == and [identical], return the result of ==. Otherwise
  /// return null.
  Constant? doubleSpecialCases(Constant a, Constant b) {
    if (a is DoubleConstant && b is DoubleConstant) {
      if (a.value.isNaN && b.value.isNaN) return falseConstant;
      if (a.value == 0.0 && b.value == 0.0) return trueConstant;
    }

    if (a is DoubleConstant && b is IntConstant) {
      return makeBoolConstant(a.value == b.value);
    }

    if (a is IntConstant && b is DoubleConstant) {
      return makeBoolConstant(a.value == b.value);
    }
    return null;
  }

  bool hasPrimitiveEqual(Constant constant,
      {bool allowPseudoPrimitive = true,
      required StaticTypeContext staticTypeContext}) {
    if (intFolder.isInt(constant)) return true;
    if (constant is RecordConstant) {
      bool nonPrimitiveEqualsFound = false;
      for (Constant field in constant.positional) {
        if (!hasPrimitiveEqual(field,
            allowPseudoPrimitive: allowPseudoPrimitive,
            staticTypeContext: staticTypeContext)) {
          nonPrimitiveEqualsFound = true;
          break;
        }
      }
      for (Constant field in constant.named.values) {
        if (!hasPrimitiveEqual(field,
            allowPseudoPrimitive: allowPseudoPrimitive,
            staticTypeContext: staticTypeContext)) {
          nonPrimitiveEqualsFound = true;
          break;
        }
      }
      if (nonPrimitiveEqualsFound) {
        return false;
      }
    }
    DartType type = constant.getType(staticTypeContext);
    if (type is InterfaceType) {
      Class cls = type.classNode;
      bool result = classHasPrimitiveEqual(cls);
      if (result && !allowPseudoPrimitive) {
        result = !pseudoPrimitiveClasses.contains(cls);
      }
      if (result && staticTypeContext.enablePrimitiveEquality) {
        result = classHasPrimitiveHashCode(cls);
      }
      return result;
    }
    return true;
  }

  bool classHasPrimitiveEqual(Class klass) {
    bool? cached = primitiveEqualCache[klass];
    if (cached != null) return cached;
    for (Procedure procedure in klass.procedures) {
      if (procedure.kind == ProcedureKind.Operator &&
          procedure.name.text == '==' &&
          !procedure.isAbstract &&
          !procedure.isForwardingStub) {
        return primitiveEqualCache[klass] = false;
      }
    }
    if (klass.supertype == null) return true; // To be on the safe side
    return primitiveEqualCache[klass] =
        classHasPrimitiveEqual(klass.supertype!.classNode);
  }

  bool classHasPrimitiveHashCode(Class klass) {
    bool? cached = primitiveHashCodeCache[klass];
    if (cached != null) return cached;
    for (Procedure procedure in klass.procedures) {
      if (procedure.kind == ProcedureKind.Getter &&
          procedure.name.text == 'hashCode' &&
          !procedure.isAbstract &&
          !procedure.isForwardingStub) {
        return primitiveHashCodeCache[klass] = false;
      }
    }
    for (Field field in klass.fields) {
      if (field.name.text == 'hashCode') {
        return primitiveHashCodeCache[klass] = false;
      }
    }
    if (klass.supertype == null) return true; // To be on the safe side
    return primitiveHashCodeCache[klass] =
        classHasPrimitiveHashCode(klass.supertype!.classNode);
  }

  BoolConstant makeBoolConstant(bool value) =>
      value ? trueConstant : falseConstant;

  bool isSubtype(Constant constant, DartType type, SubtypeCheckMode mode) {
    DartType constantType = constant.getType(staticTypeContext);
    if (mode == SubtypeCheckMode.ignoringNullabilities) {
      constantType = rawLegacyErasure(constantType) ?? constantType;
    }
    bool result = typeEnvironment.isSubtypeOf(constantType, type, mode);
    if (targetingJavaScript && !result) {
      if (constantType is InterfaceType &&
          constantType.classNode == typeEnvironment.coreTypes.intClass) {
        // Probably unreachable.
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

  /// Note that this returns an error-constant on error and as such the
  /// return value should be checked.
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
          return createEvaluationErrorConstant(
              node, messageNonAgnosticConstant);
        }
        result = strongResult;
        break;
      case EvaluationMode.weak:
        result =
            isSubtype(constant, type, SubtypeCheckMode.ignoringNullabilities);
        break;
    }
    if (!result) {
      return createEvaluationErrorConstant(
          node,
          templateConstEvalInvalidType.withArguments(constant, type,
              constant.getType(staticTypeContext), isNonNullableByDefault));
    }
    return constant;
  }

  /// Returns the types on success and null on failure.
  /// Note that on failure an errorConstant is saved in [_gotError].
  List<DartType>? _evaluateTypeArguments(TreeNode node, Arguments arguments) {
    return _evaluateDartTypes(node, arguments.types);
  }

  /// Returns the types on success and null on failure.
  /// Note that on failure an errorConstant is saved in [_gotError].
  List<DartType>? _evaluateSuperTypeArguments(TreeNode node, Supertype type) {
    return _evaluateDartTypes(node, type.typeArguments);
  }

  /// Upon failure in certain procedure calls (e.g. [_evaluateDartTypes]) the
  /// "error"-constant is saved here. Normally this should be null.
  /// Once a caller calls such a procedure and it gives an error here,
  /// the caller should fetch it an null-out this variable.
  AbortConstant? _gotError;

  /// Returns the types on success and null on failure.
  /// Note that on failure an errorConstant is saved in [_gotError].
  List<DartType>? _evaluateDartTypes(TreeNode node, List<DartType> types) {
    // TODO: Once the frontend guarantees that there are no free type variables
    // left over after substitution, we can enable this shortcut again:
    // if (env.isEmpty) return types;
    List<DartType> result =
        new List<DartType>.filled(types.length, dummyDartType, growable: true);
    for (int i = 0; i < types.length; i++) {
      DartType? type = _evaluateDartType(node, types[i]);
      if (type == null) {
        return null;
      }
      assert(_gotError == null);
      // ignore: unnecessary_null_comparison
      assert(type != null);
      result[i] = type;
    }
    return result;
  }

  /// Returns the type on success and null on failure.
  /// Note that on failure an errorConstant is saved in [_gotError].
  DartType? _evaluateDartType(TreeNode node, DartType type) {
    final DartType result = env.substituteType(type);

    if (!isInstantiated(result)) {
      // TODO(johnniwinther): Maybe we should always report this in the body
      // builder. Currently we report some, because we need to handle
      // potentially constant types, but we should be able to handle all (or
      // none) in the body builder.
      _gotError = createExpressionErrorConstant(
          node, messageTypeVariableInConstantContext);
      return null;
    }

    return result;
  }

  /// Returns the [positional] arguments on success and null on failure.
  /// Note that on failure an errorConstant is saved in [_gotError].
  List<Constant>? _evaluatePositionalArguments(List<Expression> positional) {
    List<Constant> result = new List<Constant>.filled(
        positional.length, dummyConstant,
        growable: true);
    // These expressions are at the same level, so one of them being
    // unevaluated doesn't mean a sibling is or has an unevaluated child.
    // We therefore reset it before each call, combine it and set it correctly
    // at the end.
    bool wasOrBecameUnevaluated = seenUnevaluatedChild;
    for (int i = 0; i < positional.length; i++) {
      seenUnevaluatedChild = false;
      Constant constant = _evaluateSubexpression(positional[i]);
      wasOrBecameUnevaluated |= seenUnevaluatedChild;
      if (constant is AbortConstant) {
        _gotError = constant;
        return null;
      }
      result[i] = constant;
    }
    seenUnevaluatedChild = wasOrBecameUnevaluated;
    return result;
  }

  /// Returns the [named] arguments on success and null on failure.
  /// Note that on failure an errorConstant is saved in [_gotError].
  Map<String, Constant>? _evaluateNamedArguments(List<NamedExpression> named) {
    if (named.isEmpty) return const <String, Constant>{};

    final Map<String, Constant> result = {};
    // These expressions are at the same level, so one of them being
    // unevaluated doesn't mean a sibling is or has an unevaluated child.
    // We therefore reset it before each call, combine it and set it correctly
    // at the end.
    bool wasOrBecameUnevaluated = seenUnevaluatedChild;
    for (NamedExpression pair in named) {
      if (_gotError != null) return null;
      seenUnevaluatedChild = false;
      Constant constant = _evaluateSubexpression(pair.value);
      wasOrBecameUnevaluated |= seenUnevaluatedChild;
      if (constant is AbortConstant) {
        _gotError = constant;
        return null;
      }
      result[pair.name] = constant;
    }
    if (_gotError != null) return null;
    seenUnevaluatedChild = wasOrBecameUnevaluated;
    return result;
  }

  Arguments unevaluatedArguments(List<Constant> positionalArgs,
      Map<String, Constant> namedArgs, List<DartType> types) {
    final List<Expression> positional =
        new List<Expression>.filled(positionalArgs.length, dummyExpression);
    final List<NamedExpression> named = new List<NamedExpression>.filled(
        namedArgs.length, dummyNamedExpression);
    for (int i = 0; i < positionalArgs.length; ++i) {
      positional[i] = _wrap(positionalArgs[i]);
    }
    int i = 0;
    namedArgs.forEach((String name, Constant value) {
      named[i++] = new NamedExpression(name, _wrap(value));
    });
    return new Arguments(positional, named: named, types: types);
  }

  Constant canonicalize(Constant constant) {
    // Don't use putIfAbsent to avoid the context allocation needed
    // for the closure.
    return canonicalizationCache[constant] ??= constant;
  }

  T withNewInstanceBuilder<T>(
      Class klass, List<DartType> typeArguments, T fn()) {
    InstanceBuilder? old = instanceBuilder;
    instanceBuilder = new InstanceBuilder(this, klass, typeArguments);
    T result = fn();
    instanceBuilder = old;
    return result;
  }

  T withNewEnvironment<T>(T fn()) {
    final EvaluationEnvironment oldEnv = env;
    if (enableConstFunctions) {
      env = new EvaluationEnvironment.withParent(env);
    } else {
      env = new EvaluationEnvironment();
    }
    T result = fn();
    env = oldEnv;
    return result;
  }

  T withEnvironment<T>(EvaluationEnvironment newEnv, T fn()) {
    final EvaluationEnvironment oldEnv = env;
    env = newEnv;
    T result = fn();
    env = oldEnv;
    return result;
  }

  /// Binary operation between two operands, at least one of which is a double.
  Constant evaluateBinaryNumericOperation(
      String op, num a, num b, Expression node) {
    switch (op) {
      case '+':
        return new DoubleConstant((a + b) as double);
      case '-':
        return new DoubleConstant((a - b) as double);
      case '*':
        return new DoubleConstant((a * b) as double);
      case '/':
        return new DoubleConstant(a / b);
      case '~/':
        if (b == 0) {
          return createEvaluationErrorConstant(
              node, templateConstEvalZeroDivisor.withArguments(op, '$a'));
        }
        return intFolder.truncatingDivide(node, a, b);
      case '%':
        return new DoubleConstant((a % b) as double);
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

    // Probably unreachable.
    return createExpressionErrorConstant(node,
        templateNotConstantExpression.withArguments("Binary '$op' operation"));
  }

  @override
  Constant defaultBasicLiteral(BasicLiteral node) => defaultExpression(node);

  @override
  Constant visitAwaitExpression(AwaitExpression node) =>
      defaultExpression(node);

  @override
  Constant visitBlockExpression(BlockExpression node) =>
      defaultExpression(node);

  @override
  Constant visitDynamicSet(DynamicSet node) => defaultExpression(node);

  @override
  Constant visitInstanceGetterInvocation(InstanceGetterInvocation node) =>
      defaultExpression(node);

  @override
  Constant visitInstanceSet(InstanceSet node) => defaultExpression(node);

  @override
  Constant visitLoadLibrary(LoadLibrary node) => defaultExpression(node);

  @override
  Constant visitRethrow(Rethrow node) => defaultExpression(node);

  @override
  Constant visitStaticSet(StaticSet node) => defaultExpression(node);

  @override
  Constant visitAbstractSuperMethodInvocation(
          AbstractSuperMethodInvocation node) =>
      defaultExpression(node);

  @override
  Constant visitSuperMethodInvocation(SuperMethodInvocation node) =>
      defaultExpression(node);

  @override
  Constant visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node) =>
      defaultExpression(node);

  @override
  Constant visitAbstractSuperPropertySet(AbstractSuperPropertySet node) =>
      defaultExpression(node);

  @override
  Constant visitSuperPropertyGet(SuperPropertyGet node) =>
      defaultExpression(node);

  @override
  Constant visitSuperPropertySet(SuperPropertySet node) =>
      defaultExpression(node);

  @override
  Constant visitThisExpression(ThisExpression node) => defaultExpression(node);

  @override
  Constant visitSwitchExpression(SwitchExpression node) {
    return createExpressionErrorConstant(
        node, templateNotConstantExpression.withArguments('Switch expression'));
  }

  @override
  Constant visitPatternAssignment(PatternAssignment node) {
    return createExpressionErrorConstant(node,
        templateNotConstantExpression.withArguments('Pattern assignment'));
  }
}

class StatementConstantEvaluator extends StatementVisitor<ExecutionStatus> {
  ConstantEvaluator exprEvaluator;

  StatementConstantEvaluator(this.exprEvaluator) {
    if (!exprEvaluator.enableConstFunctions) {
      throw new UnsupportedError("Const functions feature is not enabled.");
    }
  }

  /// Evaluate the expression using the [ConstantEvaluator].
  Constant evaluate(Expression expr) => expr.accept(exprEvaluator);

  @override
  ExecutionStatus defaultStatement(Statement node) {
    throw new UnsupportedError(
        'Statement constant evaluation does not support ${node.runtimeType}.');
  }

  @override
  ExecutionStatus visitAssertBlock(AssertBlock node) => defaultStatement(node);

  @override
  ExecutionStatus visitAssertStatement(AssertStatement node) {
    AbortConstant? error = exprEvaluator.checkAssert(node);
    if (error != null) return new AbortStatus(error);
    return const ProceedStatus();
  }

  @override
  ExecutionStatus visitBlock(Block node) {
    return exprEvaluator.withNewEnvironment(() {
      for (Statement statement in node.statements) {
        final ExecutionStatus status = statement.accept(this);
        if (status is! ProceedStatus) return status;
      }
      return const ProceedStatus();
    });
  }

  @override
  ExecutionStatus visitBreakStatement(BreakStatement node) =>
      new BreakStatus(node.target);

  @override
  ExecutionStatus visitContinueSwitchStatement(ContinueSwitchStatement node) =>
      node.target.body.accept(this);

  @override
  ExecutionStatus visitDoStatement(DoStatement node) {
    Constant condition;
    do {
      ExecutionStatus status = node.body.accept(this);
      if (status is! ProceedStatus) return status;
      condition = evaluate(node.condition);
    } while (condition is BoolConstant && condition.value);

    if (condition is AbortConstant) {
      return new AbortStatus(condition);
    }
    assert(condition is BoolConstant);
    return const ProceedStatus();
  }

  @override
  ExecutionStatus visitEmptyStatement(EmptyStatement node) =>
      const ProceedStatus();

  @override
  ExecutionStatus visitFunctionDeclaration(FunctionDeclaration node) {
    final EvaluationEnvironment newEnv =
        new EvaluationEnvironment.withParent(exprEvaluator.env);
    newEnv.addVariableValue(
        node.variable, new FunctionValue(node.function, null));
    final FunctionValue function = new FunctionValue(node.function, newEnv);
    exprEvaluator.env.addVariableValue(node.variable, function);
    return const ProceedStatus();
  }

  @override
  ExecutionStatus visitIfStatement(IfStatement node) {
    Constant condition = evaluate(node.condition);
    if (condition is AbortConstant) return new AbortStatus(condition);
    assert(condition is BoolConstant);
    if ((condition as BoolConstant).value) {
      return node.then.accept(this);
    } else if (node.otherwise != null) {
      return node.otherwise!.accept(this);
    }
    return const ProceedStatus();
  }

  @override
  ExecutionStatus visitForStatement(ForStatement node) {
    for (VariableDeclaration variable in node.variables) {
      final ExecutionStatus status = variable.accept(this);
      if (status is! ProceedStatus) return status;
    }

    Constant? condition =
        node.condition != null ? evaluate(node.condition!) : null;
    while (node.condition == null || condition is BoolConstant) {
      if (condition is BoolConstant && !condition.value) break;

      final ExecutionStatus status = node.body.accept(this);
      if (status is! ProceedStatus) return status;

      for (Expression update in node.updates) {
        Constant updateConstant = evaluate(update);
        if (updateConstant is AbortConstant) {
          return new AbortStatus(updateConstant);
        }
      }

      if (node.condition != null) {
        condition = evaluate(node.condition!);
      }
    }

    if (condition is AbortConstant) return new AbortStatus(condition);
    assert(condition is BoolConstant);
    return const ProceedStatus();
  }

  @override
  ExecutionStatus visitExpressionStatement(ExpressionStatement node) {
    Constant value = evaluate(node.expression);
    if (value is AbortConstant) return new AbortStatus(value);
    return const ProceedStatus();
  }

  @override
  ExecutionStatus visitLabeledStatement(LabeledStatement node) {
    final ExecutionStatus status = node.body.accept(this);
    if (status is BreakStatus && status.target == node) {
      return const ProceedStatus();
    }
    return status;
  }

  @override
  ExecutionStatus visitReturnStatement(ReturnStatement node) {
    Constant? result;
    if (node.expression != null) {
      result = evaluate(node.expression!);
      if (result is AbortConstant) return new AbortStatus(result);
    }
    return new ReturnStatus(result);
  }

  @override
  ExecutionStatus visitSwitchStatement(SwitchStatement node) {
    final Constant value = evaluate(node.expression);
    if (value is AbortConstant) return new AbortStatus(value);

    for (SwitchCase switchCase in node.cases) {
      if (switchCase.isDefault) return switchCase.body.accept(this);
      for (Expression expr in switchCase.expressions) {
        final Constant caseValue = evaluate(expr);
        if (value == caseValue) return switchCase.body.accept(this);
      }
    }
    return const ProceedStatus();
  }

  @override
  ExecutionStatus visitTryCatch(TryCatch node) {
    final ExecutionStatus tryStatus = node.body.accept(this);
    if (tryStatus is AbortStatus) {
      final Constant error = tryStatus.error;
      if (error is _AbortDueToThrowConstant) {
        final Object throwValue = error.throwValue;
        final DartType defaultType =
            exprEvaluator.typeEnvironment.coreTypes.objectNonNullableRawType;

        DartType? throwType;
        if (throwValue is Constant) {
          throwType = throwValue.getType(exprEvaluator.staticTypeContext);
        } else if (throwValue is StateError) {
          final Class stateErrorClass = exprEvaluator
              .coreTypes.coreLibrary.classes
              .firstWhere((Class klass) => klass.name == 'StateError');
          throwType =
              new InterfaceType(stateErrorClass, Nullability.nonNullable);
        } else if (throwValue is RangeError) {
          final Class rangeErrorClass = exprEvaluator
              .coreTypes.coreLibrary.classes
              .firstWhere((Class klass) => klass.name == 'RangeError');
          throwType =
              new InterfaceType(rangeErrorClass, Nullability.nonNullable);
        }
        assert(throwType != null);

        for (Catch catchClause in node.catches) {
          if (exprEvaluator.typeEnvironment.isSubtypeOf(throwType!,
                  catchClause.guard, SubtypeCheckMode.withNullabilities) ||
              catchClause.guard == defaultType) {
            return exprEvaluator.withNewEnvironment(() {
              if (catchClause.exception != null) {
                // TODO(kallentu): Store non-constant exceptions.
                if (throwValue is Constant) {
                  exprEvaluator.env
                      .addVariableValue(catchClause.exception!, throwValue);
                }
              }
              // TODO(kallentu): Store appropriate stack trace in environment.
              return catchClause.body.accept(this);
            });
          }
        }
      }
    }
    return tryStatus;
  }

  @override
  ExecutionStatus visitTryFinally(TryFinally node) {
    final ExecutionStatus tryStatus = node.body.accept(this);
    final ExecutionStatus finallyStatus = node.finalizer.accept(this);
    if (finallyStatus is! ProceedStatus) return finallyStatus;
    return tryStatus;
  }

  @override
  ExecutionStatus visitVariableDeclaration(VariableDeclaration node) {
    Constant value;
    if (node.initializer != null) {
      value = evaluate(node.initializer!);
      if (value is AbortConstant) return new AbortStatus(value);
    } else {
      value = new NullConstant();
    }
    exprEvaluator.env.addVariableValue(node, value);
    return const ProceedStatus();
  }

  @override
  ExecutionStatus visitWhileStatement(WhileStatement node) {
    Constant condition = evaluate(node.condition);
    while (condition is BoolConstant && condition.value) {
      final ExecutionStatus status = node.body.accept(this);
      if (status is! ProceedStatus) return status;
      condition = evaluate(node.condition);
    }
    if (condition is AbortConstant) return new AbortStatus(condition);
    assert(condition is BoolConstant);
    return const ProceedStatus();
  }
}

class ConstantCoverage {
  final Map<Uri, Set<Reference>> constructorCoverage;

  ConstantCoverage(this.constructorCoverage);
}

class ConstantEvaluationData {
  final ConstantCoverage coverage;
  final Set<Library> visitedLibraries;

  ConstantEvaluationData(this.coverage, this.visitedLibraries);
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
      fieldValues[field.fieldReference] = value;
    });
    assert(unusedArguments.isEmpty);
    return new InstanceConstant(klass.reference, typeArguments, fieldValues);
  }

  InstanceCreation buildUnevaluatedInstance() {
    final Map<Reference, Expression> fieldValues = <Reference, Expression>{};
    fields.forEach((Field field, Constant value) {
      fieldValues[field.fieldReference] = evaluator._wrap(value);
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

  /// The references to values of the parameters/variables in scope.
  final Map<VariableDeclaration, EvaluationReference> _variables =
      <VariableDeclaration, EvaluationReference>{};

  /// The variables that hold unevaluated constants.
  ///
  /// Variables are removed from this set when looked up, leaving only the
  /// unread variables at the end.
  final Set<VariableDeclaration> _unreadUnevaluatedVariables =
      new Set<VariableDeclaration>();

  final EvaluationEnvironment? _parent;

  EvaluationEnvironment() : _parent = null;

  EvaluationEnvironment.withParent(this._parent);

  /// Whether the current environment is empty.
  bool get isEmpty {
    // Since we look up variables in enclosing environment, the environment
    // is not empty if its parent is not empty.
    if (_parent != null && !_parent!.isEmpty) return false;
    return _typeVariables.isEmpty && _variables.isEmpty;
  }

  void addTypeParameterValue(TypeParameter parameter, DartType value) {
    assert(!_typeVariables.containsKey(parameter));
    _typeVariables[parameter] = value;
  }

  void addVariableValue(VariableDeclaration variable, Constant value) {
    _variables[variable] = new EvaluationReference(value);
    if (value is UnevaluatedConstant) {
      _unreadUnevaluatedVariables.add(variable);
    }
  }

  Constant? updateVariableValue(VariableDeclaration variable, Constant value) {
    EvaluationReference? reference = _variables[variable];
    if (reference != null) {
      reference.value = value;
      return value;
    }
    return _parent?.updateVariableValue(variable, value);
  }

  Constant? lookupVariable(VariableDeclaration variable) {
    Constant? value = _variables[variable]?.value;
    if (value is UnevaluatedConstant) {
      _unreadUnevaluatedVariables.remove(variable);
    } else if (value == null) {
      return _parent?.lookupVariable(variable);
    }
    return value;
  }

  /// The unevaluated constants of variables that were never read.
  Iterable<UnevaluatedConstant> get unevaluatedUnreadConstants {
    if (_unreadUnevaluatedVariables.isEmpty) return const [];
    return _unreadUnevaluatedVariables.map<UnevaluatedConstant>(
        (VariableDeclaration variable) =>
            _variables[variable]!.value as UnevaluatedConstant);
  }

  DartType substituteType(DartType type) {
    if (_typeVariables.isEmpty) return _parent?.substituteType(type) ?? type;
    final DartType substitutedType = substitute(type, _typeVariables);
    if (identical(substitutedType, type) && _parent != null) {
      // No distinct type created, substitute type in parent.
      return _parent!.substituteType(type);
    }
    return substitutedType;
  }
}

class RedundantFileUriExpressionRemover extends Transformer {
  Uri? currentFileUri = null;

  @override
  TreeNode visitFileUriExpression(FileUriExpression node) {
    if (node.fileUri == currentFileUri) {
      return node.expression.accept(this);
    } else {
      Uri? oldFileUri = currentFileUri;
      currentFileUri = node.fileUri;
      node.expression = transform(node.expression)..parent = node;
      currentFileUri = oldFileUri;
      return node;
    }
  }
}

/// Location that stores a value in the [ConstantEvaluator].
class EvaluationReference {
  Constant value;

  EvaluationReference(this.value);
}

/// Represents a status for statement execution.
abstract class ExecutionStatus {
  const ExecutionStatus();
}

/// Status that the statement completed execution successfully.
class ProceedStatus extends ExecutionStatus {
  const ProceedStatus();
}

/// Status that the statement returned a valid [Constant] value.
class ReturnStatus extends ExecutionStatus {
  final Constant? value;

  ReturnStatus(this.value);
}

/// Status with an exception or error that the statement has thrown.
class AbortStatus extends ExecutionStatus {
  final AbortConstant error;

  AbortStatus(this.error);
}

/// Status that the statement breaks out of an enclosing [LabeledStatement].
class BreakStatus extends ExecutionStatus {
  final LabeledStatement target;

  BreakStatus(this.target);
}

/// Mutable lists used within the [ConstantEvaluator].
class MutableListConstant extends ListConstant {
  MutableListConstant(DartType typeArgument, List<Constant> entries)
      : super(typeArgument, entries);

  @override
  String toString() => 'MutableListConstant(${toStringInternal()})';
}

/// An intermediate result that is used for invoking function nodes with their
/// respective environment within the [ConstantEvaluator].
class FunctionValue implements Constant {
  final FunctionNode function;
  final EvaluationEnvironment? environment;

  FunctionValue(this.function, this.environment);

  @override
  R accept<R>(ConstantVisitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference<R>(Visitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference1<R, A>(Visitor1<R, A> v, A arg) {
    throw new UnimplementedError();
  }

  @override
  DartType getType(StaticTypeContext context) {
    throw new UnimplementedError();
  }

  @override
  String leakingDebugToString() {
    throw new UnimplementedError();
  }

  @override
  String toString() {
    throw new UnimplementedError();
  }

  @override
  String toStringInternal() {
    throw new UnimplementedError();
  }

  @override
  String toText(AstTextStrategy strategy) {
    throw new UnimplementedError();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    throw new UnimplementedError();
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    throw new UnimplementedError();
  }
}

abstract class AbortConstant implements Constant {}

class _AbortDueToErrorConstant extends AbortConstant {
  final TreeNode node;
  final Message message;
  final List<LocatedMessage>? context;
  final bool isEvaluationError;

  _AbortDueToErrorConstant(this.node, this.message,
      {this.context, required this.isEvaluationError});

  @override
  R accept<R>(ConstantVisitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference<R>(Visitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference1<R, A>(Visitor1<R, A> v, A arg) {
    throw new UnimplementedError();
  }

  @override
  DartType getType(StaticTypeContext context) {
    throw new UnimplementedError();
  }

  @override
  String leakingDebugToString() {
    throw new UnimplementedError();
  }

  @override
  String toString() {
    throw new UnimplementedError();
  }

  @override
  String toStringInternal() {
    throw new UnimplementedError();
  }

  @override
  String toText(AstTextStrategy strategy) {
    throw new UnimplementedError();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    throw new UnimplementedError();
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    throw new UnimplementedError();
  }
}

class _AbortDueToInvalidExpressionConstant extends AbortConstant {
  final InvalidExpression node;

  _AbortDueToInvalidExpressionConstant(this.node);

  @override
  R accept<R>(ConstantVisitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference<R>(Visitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference1<R, A>(Visitor1<R, A> v, A arg) {
    throw new UnimplementedError();
  }

  @override
  DartType getType(StaticTypeContext context) {
    throw new UnimplementedError();
  }

  @override
  String leakingDebugToString() {
    throw new UnimplementedError();
  }

  @override
  String toString() {
    throw new UnimplementedError();
  }

  @override
  String toStringInternal() {
    throw new UnimplementedError();
  }

  @override
  String toText(AstTextStrategy strategy) {
    throw new UnimplementedError();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    throw new UnimplementedError();
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    throw new UnimplementedError();
  }
}

class _AbortDueToThrowConstant extends AbortConstant {
  final TreeNode node;
  final Object throwValue;

  _AbortDueToThrowConstant(this.node, this.throwValue);

  @override
  R accept<R>(ConstantVisitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference<R>(Visitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference1<R, A>(Visitor1<R, A> v, A arg) {
    throw new UnimplementedError();
  }

  @override
  DartType getType(StaticTypeContext context) {
    throw new UnimplementedError();
  }

  @override
  String leakingDebugToString() {
    throw new UnimplementedError();
  }

  @override
  String toString() {
    throw new UnimplementedError();
  }

  @override
  String toStringInternal() {
    throw new UnimplementedError();
  }

  @override
  String toText(AstTextStrategy strategy) {
    throw new UnimplementedError();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    throw new UnimplementedError();
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    throw new UnimplementedError();
  }
}

abstract class ErrorReporter {
  const ErrorReporter();

  void report(LocatedMessage message, [List<LocatedMessage>? context]);
}

class SimpleErrorReporter implements ErrorReporter {
  const SimpleErrorReporter();

  @override
  void report(LocatedMessage message, [List<LocatedMessage>? context]) {
    _report(message);
    if (context != null) {
      for (LocatedMessage contextMessage in context) {
        _report(contextMessage);
      }
    }
  }

  void _report(LocatedMessage message) {
    reportMessage(message.uri, message.charOffset, message.problemMessage);
  }

  void reportMessage(Uri? uri, int offset, String message) {
    io.exitCode = 42;
    io.stderr.writeln('$uri:$offset Constant evaluation error: $message');
  }
}

bool isInstantiated(DartType type) {
  return type.accept(new IsInstantiatedVisitor());
}

class IsInstantiatedVisitor implements DartTypeVisitor<bool> {
  final _availableVariables = new Set<TypeParameter>();

  bool isInstantiated(DartType type) {
    return type.accept(this);
  }

  @override
  bool defaultDartType(DartType node) {
    // Probably unreachable.
    throw 'A visitor method seems to be unimplemented!';
  }

  @override
  bool visitInvalidType(InvalidType node) => true;

  @override
  bool visitDynamicType(DynamicType node) => true;

  @override
  bool visitVoidType(VoidType node) => true;

  @override
  bool visitNullType(NullType node) => true;

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
    // Probably unreachable.
    return node.unalias.accept(this);
  }

  @override
  bool visitNeverType(NeverType node) => true;

  @override
  bool visitRecordType(RecordType node) {
    return node.positional.every((p) => p.accept(this)) &&
        node.named.every((p) => p.type.accept(this));
  }

  @override
  bool visitExtensionType(ExtensionType node) {
    return node.typeArguments
        .every((DartType typeArgument) => typeArgument.accept(this));
  }

  @override
  bool visitInlineType(InlineType node) {
    return node.typeArguments
        .every((DartType typeArgument) => typeArgument.accept(this));
  }

  @override
  bool visitIntersectionType(IntersectionType node) {
    return node.left.accept(this) && node.right.accept(this);
  }
}

bool _isFormalParameter(VariableDeclaration variable) {
  final TreeNode? parent = variable.parent;
  if (parent is FunctionNode) {
    return parent.positionalParameters.contains(variable) ||
        parent.namedParameters.contains(variable);
  }
  return false;
}

class _InlinedBlock extends Block {
  _InlinedBlock(List<Statement> statements) : super(statements);
}

/// Information about a currently transformed [PatternSwitchStatement].
class _PatternSwitchStatementInfo {
  /// The variable used as the switch expression in the generated
  /// [SwitchStatement].
  final VariableDeclaration switchIndexVariable;

  /// The labeled statement that wraps the case matching.
  ///
  /// This is used as a break target to jump to the generated switch statement
  /// for a continue statement from outside the generated switch statement.
  final LabeledStatement innerLabeledStatement;

  /// Map from [PatternSwitchCase]s that are continue targets to the index
  /// used for there body in the generated [SwitchStatement].
  final Map<PatternSwitchCase, int> switchCaseIndexMap;

  /// The [PatternSwitchCase] currently being transformed.
  PatternSwitchCase? currentSwitchCase;

  _PatternSwitchStatementInfo(this.switchIndexVariable,
      this.innerLabeledStatement, this.switchCaseIndexMap);
}

enum PrimitiveEquality {
  None,
  EqualsOnly,
  HashCodeOnly,
  EqualsAndHashCode,
}

extension on StaticTypeContext {
  bool get enablePrimitiveEquality =>
      enclosingLibrary.languageVersion.major >= 3;
}
