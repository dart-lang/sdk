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
library;

import 'dart:io' as io;

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/find_type_visitor.dart';
import 'package:kernel/src/norm.dart';
import 'package:kernel/src/printer.dart'
    show AstPrinter, AstTextStrategy, defaultAstTextStrategy;
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/lowering_predicates.dart';
import '../base/common.dart';
import '../base/problems.dart';
import '../codes/cfe_codes.dart';
import '../type_inference/delayed_expressions.dart';
import '../type_inference/external_ast_helper.dart';
import '../type_inference/matching_cache.dart';
import '../type_inference/matching_expressions.dart';
import 'constant_int_folder.dart';
import 'exhaustiveness.dart';
import 'record_use.dart' as RecordUse;
import 'static_weak_references.dart' show StaticWeakReferences;

part 'constant_collection_builders.dart';

ConstantEvaluationData transformLibraries(
    Component component,
    List<Library> libraries,
    Target target,
    Map<String, String>? environmentDefines,
    TypeEnvironment typeEnvironment,
    ErrorReporter errorReporter,
    {required bool evaluateAnnotations,
    required bool enableTripleShift,
    required bool enableConstFunctions,
    required bool errorOnUnevaluatedConstant,
    required bool enableConstructorTearOff,
    ExhaustivenessDataForTesting? exhaustivenessDataForTesting}) {
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
      exhaustivenessDataForTesting: exhaustivenessDataForTesting);
  for (final Library library in libraries) {
    constantsTransformer.convertLibrary(library);
  }

  return new ConstantEvaluationData(
      constantsTransformer.constantEvaluator.getConstantCoverage(),
      constantsTransformer.constantEvaluator.visitedLibraries);
}

// Coverage-ignore(suite): Only run from expression compilation.
void transformProcedure(
    Procedure procedure,
    Target target,
    Component component,
    Map<String, String>? environmentDefines,
    TypeEnvironment typeEnvironment,
    ErrorReporter errorReporter,
    {required bool evaluateAnnotations,
    required bool enableTripleShift,
    required bool enableConstFunctions,
    required bool enableConstructorTearOff,
    required bool errorOnUnevaluatedConstant}) {
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
      errorReporter);
  constantsTransformer.convertProcedure(procedure);
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
            errorOnUnevaluatedConstant: errorOnUnevaluatedConstant),
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
    transformExtensionTypeDeclarationList(
        library.extensionTypeDeclarations, library);
    transformProcedureList(library.procedures, library);
    transformFieldList(library.fields, library);

    if (!keepFields) {
      // Coverage-ignore: `keepFields` is currently always true. Maybe it should
      // just be removed?
      // The transformer API does not iterate over `Library.additionalExports`,
      // so we manually delete the references to shaken nodes.
      library.additionalExports.removeWhere((Reference reference) {
        return reference.node is Field && reference.canonicalName == null;
      });
    }
    _staticTypeContext = null;
    _exhaustivenessCache = null;
  }

  // Coverage-ignore(suite): Only run from expression compilation.
  Procedure convertProcedure(Procedure node) {
    _exhaustivenessCache =
        new CfeExhaustivenessCache(constantEvaluator, node.enclosingLibrary);
    Procedure result = visitProcedure(node, null);
    _exhaustivenessCache = null;
    return result;
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
  ExtensionTypeDeclaration visitExtensionTypeDeclaration(
      ExtensionTypeDeclaration node, TreeNode? removalSentinel) {
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
      final Iterable<InstanceConstant> resourceAnnotations =
          RecordUse.findRecordUseAnnotation(parent);
      if (resourceAnnotations.isNotEmpty) {
        // Coverage-ignore-block(suite): Not run.
        RecordUse.validateRecordUseDeclaration(
          parent,
          constantEvaluator.errorReporter,
          resourceAnnotations,
        );
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
      node.function = transform(node.function)..parent = node;
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
        if (!keepFields &&
            // Coverage-ignore(suite): Not run.
            shouldInline(initializer)) {
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
    } else if (target is Procedure) {
      if (target.kind == ProcedureKind.Method) {
        // Coverage-ignore-block(suite): Not run.
        return evaluateAndTransformWithContext(node, node);
      } else if (target.kind == ProcedureKind.Getter && enableConstFunctions) {
        return evaluateAndTransformWithContext(node, node);
      }
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
      // Coverage-ignore-block(suite): Not run.
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
          new MatchingExpressionVisitor(
              matchingCache, typeEnvironment.coreTypes);
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
      bool needsThrowForNull = false;
      bool forUnsoundness = false;
      if (isAlwaysExhaustiveType && !hasDefault) {
        if (currentLibrary.languageVersion <= const Version(3, 2)) {
          needsThrowForNull = forUnsoundness = true;
        }
      }

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
          // TODO(johnniwinther): Support irrefutable tail optimization here?
          Expression headCondition = matchingExpression
              .createExpression(typeEnvironment, inCacheInitializer: false);
          if (guard != null) {
            headCondition = createAndExpression(headCondition, guard,
                fileOffset: TreeNode.noOffset);
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
              // Coverage-ignore-block(suite): Not run.
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
          // Coverage-ignore-block(suite): Not run.
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
          if (breakStatement != null)
            // Coverage-ignore(suite): Not run.
            breakStatement
        ], fileOffset: switchCase.fileOffset));
      }

      if (needsThrowForNull) {
        cases.add(createExpressionStatement(createThrow(
            createConstructorInvocation(
                typeEnvironment.coreTypes.reachabilityErrorConstructor,
                createArguments([
                  createStringLiteral(
                      forUnsoundness
                          ? codeUnsoundSwitchStatementError.problemMessage
                          :
                          // Coverage-ignore(suite): Not run.
                          codeNeverReachableSwitchStatementError.problemMessage,
                      fileOffset: node.fileOffset)
                ], fileOffset: node.fileOffset),
                fileOffset: node.fileOffset),
            forErrorHandling: true)));
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
        // Coverage-ignore-block(suite): Not run.
        replacement = replacementStatements.first;
      } else {
        replacement = new Block(replacementStatements)
          ..fileOffset = node.fileOffset;
      }
    }
    if (outerLabeledStatement != null) {
      // Coverage-ignore-block(suite): Not run.
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
    List<bool> caseIsGuarded = [];
    List<Space> caseSpaces = [];
    PatternConverter patternConverter = new PatternConverter(
        currentLibrary.languageVersion,
        _exhaustivenessCache!,
        staticTypeContext,
        hasPrimitiveEquality: (Constant constant) => constantEvaluator
            .hasPrimitiveEqual(constant, staticTypeContext: staticTypeContext));
    for (PatternGuard patternGuard in patternGuards) {
      caseIsGuarded.add(patternGuard.guard != null);
      caseSpaces
          .add(patternConverter.createRootSpace(type, patternGuard.pattern));
    }
    // Coverage-ignore(suite): Not run.
    List<CaseUnreachability>? caseUnreachabilities =
        retainDataForTesting ? [] : null;
    NonExhaustiveness? nonExhaustiveness = computeExhaustiveness(
        _exhaustivenessCache!, type, caseIsGuarded, caseSpaces,
        caseUnreachabilities: caseUnreachabilities);
    NonExhaustiveness? reportedNonExhaustiveness;
    if (nonExhaustiveness != null && !hasDefault && mustBeExhaustive) {
      reportedNonExhaustiveness = nonExhaustiveness;
      constantEvaluator.errorReporter.report(
          constantEvaluator.createLocatedMessageWithOffset(
              node,
              fileOffset,
              (isSwitchExpression
                      ? codeNonExhaustiveSwitchExpression
                      : codeNonExhaustiveSwitchStatement)
                  .withArguments(
                      expressionType,
                      nonExhaustiveness.witnesses.first.asWitness,
                      nonExhaustiveness.witnesses.first.asCorrection)));
    }
    if (_exhaustivenessDataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      _exhaustivenessDataForTesting.objectFieldLookup ??= _exhaustivenessCache;
      _exhaustivenessDataForTesting.switchResults[replacement] =
          new ExhaustivenessResult(
              type,
              caseSpaces,
              patternGuards.map((c) => c.fileOffset).toList(),
              {
                for (CaseUnreachability caseUnreachability
                    in caseUnreachabilities!)
                  caseUnreachability.index
              },
              reportedNonExhaustiveness);
    }
  }

  @override
  TreeNode visitSwitchStatement(
      SwitchStatement node, TreeNode? removalSentinel) {
    TreeNode result = super.visitSwitchStatement(node, removalSentinel);
    for (SwitchCase switchCase in node.cases) {
      for (Expression caseExpression in switchCase.expressions) {
        if (caseExpression is ConstantExpression) {
          if (!constantEvaluator.hasPrimitiveEqual(caseExpression.constant,
              staticTypeContext: staticTypeContext)) {
            constantEvaluator.errorReporter.report(
                constantEvaluator.createLocatedMessage(
                    caseExpression,
                    codeConstEvalCaseImplementsEqual
                        .withArguments(caseExpression.constant)),
                null);
          }
        } else {
          // [caseExpression] is not [ConstantExpression].
          assert(constantEvaluator.errorReporter.hasSeenError);
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
        new MatchingExpressionVisitor(matchingCache, typeEnvironment.coreTypes);
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

    Expression condition;
    Expression? guard = node.patternGuard.guard;
    Statement then = node.then;
    if (guard == null && matchingExpression.hasIrrefutableTail) {
      // TODO(johnniwinther): Support irrefutable tails with guards.
      List<Statement> statements = [];
      List<Expression> expressionEffects = [];
      List<Statement> statementEffects = [];
      condition = matchingExpression.createExpressionAndStatements(
              typeEnvironment, statements,
              expressionEffects: expressionEffects,
              statementEffects: statementEffects) ??
          // We emit the full if statement even when the expression is known to
          // match to ensure that for instance code coverage still works as
          // normal for the else statement.
          //
          // For instance:
          //
          //    bool b1 = ...
          //    if (b1 case var b2) {
          //      print(b2);
          //    } else {
          //      print(b1); // This is dead code.
          //    }
          //
          // If we inlined the then-statement, code coverage wouldn't show that
          // the else-statement is not covered.
          createBoolLiteral(true, fileOffset: node.fileOffset);
      if (statements.isNotEmpty ||
          // Coverage-ignore(suite): Not run.
          expressionEffects.isNotEmpty ||
          // Coverage-ignore(suite): Not run.
          statementEffects.isNotEmpty) {
        then = createBlock([
          ...statements,
          ...expressionEffects.map(createExpressionStatement),
          ...statementEffects,
          then,
        ], fileOffset: node.fileOffset);
      }
    } else {
      condition = matchingExpression.createExpression(typeEnvironment,
          inCacheInitializer: false);
      if (guard != null) {
        condition = createAndExpression(condition, guard,
            fileOffset: TreeNode.noOffset);
      }
    }

    List<Statement> cacheVariables = [...matchingCache.declarations];
    Iterable<Statement> declarations =
        node.patternGuard.pattern.declaredVariables;
    Statement ifStatement;
    if (declarations.isNotEmpty) {
      // If we need local declarations, create a new block to avoid naming
      // collision with declarations in the same parent block.
      ifStatement = createBlock([
        ...declarations,
        createIfStatement(condition, then,
            otherwise: node.otherwise, fileOffset: node.fileOffset)
      ], fileOffset: node.fileOffset);
    } else {
      ifStatement = createIfStatement(condition, then,
          otherwise: node.otherwise, fileOffset: node.fileOffset);
    }
    return transform(createBlock([...cacheVariables, ifStatement],
        fileOffset: node.fileOffset)
      ..parent = node.parent);
  }

  @override
  TreeNode visitPatternVariableDeclaration(
      PatternVariableDeclaration node, TreeNode? removalSentinel) {
    node.initializer = transform(node.initializer)..parent = node;
    node.pattern = transform(node.pattern)..parent = node;

    MatchingCache matchingCache = createMatchingCache();
    MatchingExpressionVisitor matchingExpressionVisitor =
        new MatchingExpressionVisitor(matchingCache, typeEnvironment.coreTypes);
    DartType matchedType = node.matchedValueType!;
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

    List<Statement> replacementStatements;
    if (matchingExpression.isEffectOnly) {
      replacementStatements = [];
      matchingExpression.createStatements(
          typeEnvironment, replacementStatements);
      replacementStatements = [
        ...matchingCache.declarations,
        ...replacementStatements,
      ];
    } else {
      Expression readMatchingExpression = matchingExpression
          .createExpression(typeEnvironment, inCacheInitializer: false);
      replacementStatements = [
        ...matchingCache.declarations,
        // TODO(cstefantsova): Provide a better diagnostic message.
        createIfStatement(
            createNot(readMatchingExpression),
            createExpressionStatement(createThrow(
                createConstructorInvocation(
                    typeEnvironment.coreTypes.stateErrorConstructor,
                    createArguments([
                      createStringLiteral(
                          codePatternMatchingError.problemMessage,
                          fileOffset: node.fileOffset)
                    ], fileOffset: node.fileOffset),
                    fileOffset: node.fileOffset),
                forErrorHandling: true)),
            fileOffset: node.fileOffset),
      ];
    }
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
        new MatchingExpressionVisitor(matchingCache, typeEnvironment.coreTypes);
    DartType matchedType = node.matchedValueType!;
    CacheableExpression matchedExpression =
        matchingCache.createRootExpression(node.expression, matchedType);

    DelayedExpression matchingExpression =
        matchingExpressionVisitor.visitPattern(node.pattern, matchedExpression);

    matchedExpression.registerUse();
    matchingExpression.registerUse();

    Expression readMatchedExpression = matchedExpression
        .createExpression(typeEnvironment, inCacheInitializer: false);

    List<Statement> replacementStatements;
    if (matchingExpression.isEffectOnly) {
      List<Statement> effects = [];
      replacementStatements = [];
      matchingExpression.createStatements(
          typeEnvironment, replacementStatements,
          effects: effects);
      replacementStatements = [
        ...matchingCache.declarations,
        ...node.pattern.declaredVariables,
        ...replacementStatements,
        ...effects,
      ];
    } else {
      List<Expression> effects = [];
      Expression readMatchingExpression = matchingExpression.createExpression(
          typeEnvironment,
          effects: effects,
          inCacheInitializer: false);

      replacementStatements = [
        ...matchingCache.declarations,
        ...node.pattern.declaredVariables,
        // TODO(cstefantsova): Provide a better diagnostic message.
        createIfStatement(
            createNot(readMatchingExpression),
            createExpressionStatement(createThrow(
                createConstructorInvocation(
                    typeEnvironment.coreTypes.stateErrorConstructor,
                    createArguments([
                      createStringLiteral(
                          codePatternMatchingError.problemMessage,
                          fileOffset: node.fileOffset)
                    ], fileOffset: node.fileOffset),
                    fileOffset: node.fileOffset),
                forErrorHandling: true)),
            fileOffset: node.fileOffset),
        ...effects.map(
            // Coverage-ignore(suite): Not run.
            (e) => createExpressionStatement(e)),
      ];
    }

    Expression result = createBlockExpression(
        createBlock(replacementStatements, fileOffset: node.fileOffset),
        readMatchedExpression,
        fileOffset: node.fileOffset);
    // TODO(johnniwinther): Avoid this work-around for [getFileUri].
    result.parent = node.parent;
    return transform(result);
  }

  @override
  TreeNode visitExpressionStatement(
      ExpressionStatement node, TreeNode? removalSentinel) {
    Expression expression = transform(node.expression);
    if (expression is BlockExpression) {
      // This avoids unnecessary [BlockExpression]s created by the lowering of
      // [PatternAssignment]s for effect.
      if (_exhaustivenessDataForTesting != null) {
        // Coverage-ignore-block(suite): Not run.
        ExhaustivenessResult? result =
            _exhaustivenessDataForTesting.switchResults[expression];
        if (result != null) {
          _exhaustivenessDataForTesting.switchResults[expression.body] = result;
        }
      }
      return expression.body;
    }
    node.expression = expression..parent = node;
    return node;
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
                entry.key, codeEqualKeysInMapPattern),
            [
              constantEvaluator.createLocatedMessage(
                  existing.key, codeEqualKeysInMapPatternContext)
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
          new MatchingExpressionVisitor(
              matchingCache, typeEnvironment.coreTypes);
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

        Expression caseCondition;
        DelayedExpression matchingExpression = matchingExpressions[caseIndex];
        List<Statement>? tailStatements;
        if (guard == null && matchingExpression.hasIrrefutableTail) {
          // TODO(johnniwinther): Support irrefutable tails with guards.
          List<Statement> statements = [];
          List<Expression> expressionEffects = [];
          List<Statement> statementEffects = [];
          caseCondition = matchingExpression.createExpressionAndStatements(
                  typeEnvironment, statements,
                  expressionEffects: expressionEffects,
                  statementEffects: statementEffects) ??
              // TODO(johnniwinther): Avoid generating the if-statement in this
              // case.
              createBoolLiteral(true, fileOffset: node.fileOffset);
          if (statements.isNotEmpty ||
              // Coverage-ignore(suite): Not run.
              expressionEffects.isNotEmpty ||
              // Coverage-ignore(suite): Not run.
              statementEffects.isNotEmpty) {
            tailStatements = [
              ...statements,
              ...expressionEffects.map(createExpressionStatement),
              ...statementEffects,
            ];
          }
        } else {
          caseCondition = matchingExpression.createExpression(typeEnvironment,
              inCacheInitializer: false);
          if (guard != null) {
            caseCondition = createAndExpression(caseCondition, guard,
                fileOffset: TreeNode.noOffset);
          }
        }

        cases.add(createBlock([
          ...pattern.declaredVariables,
          createIfStatement(
              caseCondition,
              createBlock([
                ...?tailStatements,
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
      bool forUnsoundness = false;
      bool needsThrow = false;
      if (currentLibrary.languageVersion <= const Version(3, 2)) {
        needsThrow = forUnsoundness = true;
      }
      if (needsThrow) {
        cases.add(createExpressionStatement(createThrow(
            createConstructorInvocation(
                typeEnvironment.coreTypes.reachabilityErrorConstructor,
                createArguments([
                  createStringLiteral(
                      forUnsoundness
                          ? codeUnsoundSwitchExpressionError.problemMessage
                          :
                          // Coverage-ignore(suite): Not run.
                          codeNeverReachableSwitchExpressionError
                              .problemMessage,
                      fileOffset: node.fileOffset)
                ], fileOffset: node.fileOffset),
                fileOffset: node.fileOffset),
            forErrorHandling: true)));
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
          // Coverage-ignore-block(suite): Not run.
          return makeConstantExpression(new UnevaluatedConstant(node), node);
        } else {
          Constant constant = constantEvaluator.canonicalize(
              new RecordConstant.fromTypeContext(
                  positional, named, staticTypeContext));
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
    if (!containsFreeTypeParameters(node.type)) {
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
      // Coverage-ignore-block(suite): Not run.
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
    ConstantExpression constantExpression =
        new ConstantExpression(constant, node.getStaticType(staticTypeContext))
          ..fileOffset = node.fileOffset;
    if (node is FileUriExpression) {
      return new FileUriConstantExpression(constantExpression.constant,
          type: constantExpression.type, fileUri: node.fileUri)
        ..fileOffset = node.fileOffset;
    } else if (node is FileUriConstantExpression) {
      return new FileUriConstantExpression(constantExpression.constant,
          type: constantExpression.type, fileUri: node.fileUri)
        ..fileOffset = node.fileOffset;
    }
    return constantExpression;
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

  final bool enableTripleShift;
  final bool enableAsserts;
  final bool enableConstFunctions;
  bool inExtensionTypeConstConstructor = false;

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

  StaticTypeContext get staticTypeContext => _staticTypeContext!;

  Library get currentLibrary => staticTypeContext.enclosingLibrary;

  ConstantEvaluator(this.dartLibrarySupport, this.backend, this.component,
      this._environmentDefines, this.typeEnvironment, this.errorReporter,
      {this.enableTripleShift = false,
      this.enableConstFunctions = false,
      this.enableAsserts = true,
      this.errorOnUnevaluatedConstant = false})
      : numberSemantics = backend.numberSemantics,
        coreTypes = typeEnvironment.coreTypes,
        canonicalizationCache = <Constant, Constant>{},
        nodeCache = <Node, Constant?>{},
        env = new EvaluationEnvironment() {
    if (_environmentDefines == null && !backend.supportsUnevaluatedConstants) {
      throw new ArgumentError(
          "No 'environmentDefines' passed to the constant evaluator but the "
              "ConstantsBackend does not support unevaluated constants.",
          "_environmentDefines");
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
  }

  Map<String, String>? _supportedLibrariesCache;

  Map<String, String> _computeSupportedLibraries() => {
        for (Library library in component.libraries)
          if (library.importUri.isScheme('dart') &&
              DartLibrarySupport.isDartLibrarySupported(library.importUri.path,
                  libraryExists: true,
                  isSynthetic: library.isSynthetic,
                  isUnsupported: library.isUnsupported,
                  dartLibrarySupport: dartLibrarySupport))
            (DartLibrarySupport.dartLibraryPrefix + library.importUri.path):
                "true"
      };

  String? lookupEnvironment(String key) {
    if (DartLibrarySupport.isDartLibraryQualifier(key)) {
      return (_supportedLibrariesCache ??= _computeSupportedLibraries())[key];
    }
    return _environmentDefines![key];
  }

  bool hasEnvironmentKey(String key) {
    if (DartLibrarySupport.isDartLibraryQualifier(key)) {
      // Coverage-ignore-block(suite): Not run.
      return (_supportedLibrariesCache ??= _computeSupportedLibraries())
          .containsKey(key);
    }
    return _environmentDefines!.containsKey(key);
  }

  bool get hasEnvironment => _environmentDefines != null;

  DartType convertType(DartType type) {
    return norm(coreTypes, type);
  }

  List<DartType> convertTypes(List<DartType> types) {
    return types.map((DartType type) => norm(coreTypes, type)).toList();
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
      // Coverage-ignore-block(suite): Not run.
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
          if (result.context != null) {
            // Coverage-ignore-block(suite): Not run.
            contextMessages.addAll(result.context!);
          }
          if (contextNode != null && contextNode != result.node) {
            contextMessages
                .add(createLocatedMessage(contextNode, codeConstEvalContext));
          }

          {
            final LocatedMessage locatedMessage =
                createLocatedMessage(node, codeConstEvalStartingPoint);
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
          message = codeConstEvalUnhandledException.withArguments(value);
        } else if (value is Error) {
          message = codeConstEvalUnhandledCoreException
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
              createLocatedMessage(node, codeConstEvalStartingPoint);
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
        // Coverage-ignore-block(suite): Not run.
        return createEvaluationErrorConstant(node, codeConstEvalUnevaluated);
      }
      return canonicalize(new UnevaluatedConstant(
          removeRedundantFileUriExpressions(result.expression)));
    }
    return result;
  }

  /// Execute a function body using the [StatementConstantEvaluator].
  Constant executeBody(Statement statement) {
    if (!enableConstFunctions && !inExtensionTypeConstConstructor) {
      throw new UnsupportedError("Statement evaluation is only supported when "
          "in extension type const constructors or when the const functions "
          "feature is enabled.");
    }
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
    // Coverage-ignore(suite): Not run.
    return createEvaluationErrorConstant(
        statement,
        codeConstEvalError.withArguments(
            'No valid constant returned from the execution of the '
            'statement.'));
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant? executeConstructorBody(Constructor constructor) {
    if (!enableConstFunctions &&
        // Coverage-ignore(suite): Not run.
        !inExtensionTypeConstConstructor) {
      throw new UnsupportedError("Statement evaluation is only supported when "
          "in extension type const constructors or when the const functions "
          "feature is enabled.");
    }
    final Statement body = constructor.function.body!;
    StatementConstantEvaluator statementEvaluator =
        new StatementConstantEvaluator(this);
    ExecutionStatus status = body.accept(statementEvaluator);
    if (status is AbortStatus) {
      return status.error;
    } else if (status is ReturnStatus) {
      if (status.value == null) return null;
      // Coverage-ignore: Should not be reachable.
      return createEvaluationErrorConstant(
          constructor,
          codeConstEvalError
              .withArguments("Constructors can't have a return value."));
    } else if (status is! ProceedStatus) {
      // Coverage-ignore-block(suite): Not run.
      return createEvaluationErrorConstant(
          constructor,
          codeConstEvalError
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
      // Coverage-ignore-block(suite): Not run.
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
          return createEvaluationErrorConstant(node, codeConstEvalCircularity);
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
          return createEvaluationErrorConstant(node, codeConstEvalCircularity);
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

  Constant _notAConstantExpression(Expression node) {
    // Only a subset of the expression language is valid for constant
    // evaluation.
    return createExpressionErrorConstant(node, codeNotAConstantExpression);
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
      return createExpressionErrorConstant(node,
          codeNotConstantExpression.withArguments('Non-constant list literal'));
    }

    DartType? type = _evaluateDartType(node, node.typeArgument);
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    final ListConstantBuilder builder = new ListConstantBuilder(
        node, convertType(type), this,
        isMutable: !node.isConst);
    // These expressions are at the same level, so one of them being
    // unevaluated doesn't mean a sibling is or has an unevaluated child.
    // We therefore reset it before each call, combine it and set it correctly
    // at the end.
    bool wasOrBecameUnevaluated = seenUnevaluatedChild;
    for (int i = 0; i < node.expressions.length; i++) {
      Expression element = node.expressions[i];
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

    Map<String, Constant>? named = _evaluateNamedArguments(node.named);
    if (named == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    if (shouldBeUnevaluated) {
      // Coverage-ignore-block(suite): Not run.
      return unevaluated(
          node,
          new RecordLiteral([
            for (Constant c in positional) _wrap(c),
          ], [
            for (String key in named.keys)
              new NamedExpression(key, _wrap(named[key]!)),
          ], node.recordType, isConst: true));
    }
    return canonicalize(new RecordConstant.fromTypeContext(
        positional, named, staticTypeContext));
  }

  @override
  Constant visitListConcatenation(ListConcatenation node) {
    DartType? type = _evaluateDartType(node, node.typeArgument);
    if (type == null) {
      // Coverage-ignore-block(suite): Not run.
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    final ListConstantBuilder builder =
        new ListConstantBuilder(node, convertType(type), this);
    for (Expression list in node.lists) {
      AbortConstant? error = builder.addSpread(list);
      if (error != null) return error;
    }
    return builder.build();
  }

  @override
  Constant visitSetLiteral(SetLiteral node) {
    if (!node.isConst) {
      return createExpressionErrorConstant(node,
          codeNotConstantExpression.withArguments('Non-constant set literal'));
    }

    DartType? type = _evaluateDartType(node, node.typeArgument);
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

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
    DartType? type = _evaluateDartType(node, node.typeArgument);
    if (type == null) {
      // Coverage-ignore-block(suite): Not run.
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    final SetConstantBuilder builder =
        new SetConstantBuilder(node, convertType(type), this);
    for (Expression set_ in node.sets) {
      AbortConstant? error = builder.addSpread(set_);
      if (error != null) return error;
    }
    return builder.build();
  }

  @override
  Constant visitMapLiteral(MapLiteral node) {
    if (!node.isConst) {
      return createExpressionErrorConstant(node,
          codeNotConstantExpression.withArguments('Non-constant map literal'));
    }

    DartType? keyType = _evaluateDartType(node, node.keyType);
    if (keyType == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    DartType? valueType = _evaluateDartType(node, node.valueType);
    if (valueType == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

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
    DartType? keyType = _evaluateDartType(node, node.keyType);
    if (keyType == null) {
      // Coverage-ignore-block(suite): Not run.
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    DartType? valueType = _evaluateDartType(node, node.valueType);
    if (valueType == null) {
      // Coverage-ignore-block(suite): Not run.
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    final MapConstantBuilder builder = new MapConstantBuilder(
        node, convertType(keyType), convertType(valueType), this);
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
    return createExpressionErrorConstant(
        node, codeNotConstantExpression.withArguments('Function expression'));
  }

  @override
  Constant visitConstructorInvocation(ConstructorInvocation node) {
    if (!node.isConst && !enableConstFunctions) {
      return createExpressionErrorConstant(
          node, codeNotConstantExpression.withArguments('New expression'));
    }

    final Constructor constructor = node.target;
    AbortConstant? error =
        checkConstructorConst(node, constructor, codeNonConstConstructor);
    if (error != null) return error;

    final Class klass = constructor.enclosingClass;
    if (klass.isAbstract) {
      // Coverage-ignore: Probably unreachable.
      return createExpressionErrorConstant(
          node, codeAbstractClassInstantiation.withArguments(klass.name));
    }

    final List<Constant>? positional =
        _evaluatePositionalArguments(node.arguments.positional);
    if (positional == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    final Map<String, Constant>? named =
        _evaluateNamedArguments(node.arguments.named);
    if (named == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    bool isSymbol = klass == coreTypes.internalSymbolClass;
    if (isSymbol && shouldBeUnevaluated) {
      // Coverage-ignore-block(suite): Not run.
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
      if (nameValue is StringConstant) {
        return canonicalize(new SymbolConstant(nameValue.value, null));
      }
      // Coverage-ignore(suite): Not run.
      return createEvaluationErrorConstant(node.arguments.positional.first,
          codeConstEvalInvalidSymbolName.withArguments(nameValue));
    }

    List<DartType>? types = _evaluateTypeArguments(node, node.arguments);
    if (types == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    final List<DartType> typeArguments = convertTypes(types);

    // Fill in any missing type arguments with "dynamic".
    for (int i = typeArguments.length;
        i < klass.typeParameters.length;
        // Coverage-ignore(suite): Not run.
        i++) {
      // Coverage-ignore: Probably unreachable.
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
      TreeNode node, Constructor constructor, Message codeIfNonConst) {
    if (!constructor.isConst) {
      return createExpressionErrorConstant(node, codeIfNonConst);
    }
    if (constructor.function.body != null &&
        constructor.function.body is! EmptyStatement &&
        !enableConstFunctions) {
      // Coverage-ignore: Probably unreachable.
      return createExpressionErrorConstant(node, codeConstConstructorWithBody);
    } else if (constructor.isExternal) {
      return createEvaluationErrorConstant(
          node, codeConstEvalExternalConstructor);
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
        // Coverage-ignore-block(suite): Not run.
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
        // Coverage-ignore-block(suite): Not run.
        return unevaluated(node, instanceBuilder!.buildUnevaluatedInstance());
      }
      // We can get here when re-evaluating a previously unevaluated constant.
      return canonicalize(instanceBuilder!.buildInstance());
    });
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
              init, init.target, codeConstConstructorWithNonConstSuper);
          if (error != null) return error;
          List<DartType>? types = _evaluateSuperTypeArguments(
              init, constructor.enclosingClass.supertype!);
          if (types == null) {
            // Coverage-ignore-block(suite): Not run.
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);

          List<Constant>? positionalArguments =
              _evaluatePositionalArguments(init.arguments.positional);
          if (positionalArguments == null) {
            // Coverage-ignore-block(suite): Not run.
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);
          Map<String, Constant>? namedArguments =
              _evaluateNamedArguments(init.arguments.named);
          if (namedArguments == null) {
            // Coverage-ignore-block(suite): Not run.
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);
          error = handleConstructorInvocation(
              init.target, types, positionalArguments, namedArguments, caller);
          if (error != null) return error;
        } else if (init is RedirectingInitializer) {
          // Since a redirecting constructor targets a constructor of the same
          // class, we pass the same [typeArguments].

          AbortConstant? error = checkConstructorConst(
              init, init.target, codeConstConstructorRedirectionToNonConst);
          if (error != null) return error;
          List<Constant>? positionalArguments =
              _evaluatePositionalArguments(init.arguments.positional);
          if (positionalArguments == null) {
            // Coverage-ignore-block(suite): Not run.
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);

          Map<String, Constant>? namedArguments =
              _evaluateNamedArguments(init.arguments.named);
          if (namedArguments == null) {
            // Coverage-ignore-block(suite): Not run.
            AbortConstant error = _gotError!;
            _gotError = null;
            return error;
          }
          assert(_gotError == null);

          error = handleConstructorInvocation(init.target, typeArguments,
              positionalArguments, namedArguments, caller);
          if (error != null) return error;
        } else if (init is AssertInitializer) {
          AbortConstant? error = checkAssert(init.statement);
          if (error != null) return error;
        } else {
          // Coverage-ignore-block: Probably unreachable.
          // InvalidInitializer or new Initializers.
          // InvalidInitializer is (currently) only
          // created for classes with no constructors that doesn't have a
          // super that takes no arguments. It thus cannot be const.
          // Explicit constructors with incorrect super calls will get a
          // ShadowInvalidInitializer which is actually a LocalInitializer.
          assert(
              false,
              'No support for handling initializer of type '
              '"${init.runtimeType}".');
          return createEvaluationErrorConstant(
              init, codeNotAConstantExpression);
        }
      }

      for (UnevaluatedConstant constant in env.unevaluatedUnreadConstants) {
        // Coverage-ignore-block(suite): Not run.
        instanceBuilder!.unusedArguments.add(_wrap(constant));
      }

      if (enableConstFunctions) {
        AbortConstant? error = executeConstructorBody(constructor);
        if (error != null) return error;
      }

      return null;
    });
  }

  /// Returns [null] on success and an error-"constant" on failure, as such the
  /// return value should be checked.
  AbortConstant? checkAssert(AssertStatement statement) {
    if (!enableAsserts) return null;
    final Constant condition = _evaluateSubexpression(statement.condition);
    if (condition is AbortConstant) return condition;

    if (shouldBeUnevaluated) {
      if (instanceBuilder != null) {
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
      } else {
        assert(inExtensionTypeConstConstructor);
        return null;
      }
    } else if (condition is BoolConstant) {
      if (!condition.value) {
        if (statement.message == null) {
          return createEvaluationErrorConstant(
              statement.condition, codeConstEvalFailedAssertion);
        }
        final Constant message = _evaluateSubexpression(statement.message!);
        if (message is AbortConstant) return message;
        if (shouldBeUnevaluated) {
          // Coverage-ignore-block(suite): Not run.
          instanceBuilder!.asserts.add(new AssertStatement(_wrap(condition),
              message: _wrap(message),
              conditionStartOffset: statement.conditionStartOffset,
              conditionEndOffset: statement.conditionEndOffset));
        } else if (message is StringConstant) {
          return createEvaluationErrorConstant(
              statement.condition,
              codeConstEvalFailedAssertionWithMessage
                  .withArguments(message.value));
        } else if (message is NullConstant) {
          return createEvaluationErrorConstant(
              statement.condition, codeConstEvalFailedAssertion);
        } else {
          return createEvaluationErrorConstant(statement.message!,
              codeConstEvalFailedAssertionWithNonStringMessage);
        }
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      return createEvaluationErrorConstant(
          statement.condition,
          codeConstEvalInvalidType.withArguments(
              condition,
              typeEnvironment.coreTypes.boolNonNullableRawType,
              condition.getType(staticTypeContext)));
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
      return createExpressionErrorConstant(
          node, codeNotConstantExpression.withArguments("Dynamic invocation"));
    }

    // We have no support for method invocation with named arguments at the
    // moment.
    if (node.arguments.named.isNotEmpty) {
      return createExpressionErrorConstant(
          node, codeNotConstantExpression.withArguments("Dynamic invocation"));
    }

    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    final List<Constant>? positionalArguments =
        _evaluatePositionalArguments(node.arguments.positional);

    if (positionalArguments == null) {
      // Coverage-ignore-block(suite): Not run.
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    if (shouldBeUnevaluated) {
      // Coverage-ignore-block(suite): Not run.
      return unevaluated(
          node,
          new DynamicInvocation(
              node.kind,
              _wrap(receiver),
              node.name,
              unevaluatedArguments(
                  positionalArguments, {}, node.arguments.types))
            ..fileOffset = node.fileOffset
            ..flags = node.flags);
    }

    return _handleInvocation(node, node.name, receiver, positionalArguments,
        arguments: node.arguments);
  }

  @override
  Constant visitInstanceInvocation(InstanceInvocation node) {
    // We have no support for generic method invocation at the moment.
    if (node.arguments.types.isNotEmpty) {
      return createExpressionErrorConstant(
          node, codeNotConstantExpression.withArguments("Instance invocation"));
    }

    // We have no support for method invocation with named arguments at the
    // moment.
    if (node.arguments.named.isNotEmpty) {
      return createExpressionErrorConstant(
          node, codeNotConstantExpression.withArguments("Instance invocation"));
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

    if (shouldBeUnevaluated) {
      // Coverage-ignore-block(suite): Not run.
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
      return createExpressionErrorConstant(
          node, codeNotConstantExpression.withArguments('Function invocation'));
    }

    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;

    return _evaluateFunctionInvocation(node, receiver, node.arguments);
  }

  @override
  Constant visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    if (!enableConstFunctions) {
      return createExpressionErrorConstant(node,
          codeNotConstantExpression.withArguments('Local function invocation'));
    }

    final Constant receiver = env.lookupVariable(node.variable)!;
    if (receiver is AbortConstant) return receiver;

    return _evaluateFunctionInvocation(node, receiver, node.arguments);
  }

  Constant _evaluateFunctionInvocation(
      TreeNode node, Constant receiver, Arguments arguments) {
    final List<Constant>? positional =
        _evaluatePositionalArguments(arguments.positional);

    if (positional == null) {
      // Coverage-ignore-block(suite): Not run.
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    // Evaluate type arguments of the function invoked.
    List<DartType>? types = _evaluateTypeArguments(node, arguments);
    if (types == null) {
      // Coverage-ignore-block(suite): Not run.
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    // Evaluate named arguments of the function invoked.
    final Map<String, Constant>? named =
        _evaluateNamedArguments(arguments.named);
    if (named == null) {
      // Coverage-ignore-block(suite): Not run.
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    if (receiver is FunctionValue) {
      return _handleFunctionInvocation(
          receiver.function, types, positional, named,
          functionEnvironment: receiver.environment);
    } else {
      // Coverage-ignore-block(suite): Not run.
      return createEvaluationErrorConstant(
          node,
          codeConstEvalError
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
      // Coverage-ignore-block(suite): Not run.
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
            codeConstEvalEqualsOperandNotPrimitiveEquality.withArguments(
                left, left.getType(staticTypeContext)));
      }
    } else {
      if (left is NullConstant ||
          left is BoolConstant ||
          left is IntConstant ||
          left is DoubleConstant ||
          left is StringConstant ||
          right is NullConstant) {
        // Coverage-ignore-block(suite): Not run.
        // [DoubleConstant] uses [identical] to determine equality, so we need
        // to take the special cases into account.
        return doubleSpecialCases(left, right) ??
            makeBoolConstant(left == right);
      } else {
        return createEvaluationErrorConstant(
            node,
            codeConstEvalInvalidEqualsOperandType.withArguments(
                left, left.getType(staticTypeContext)));
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
      // Coverage-ignore-block(suite): Not run.
      return new StringConstant(receiver.value.toString());
    }

    // Handle == and != first (it's common between all types). Since `a != b` is
    // parsed as `!(a == b)` it is handled implicitly through ==.
    if (positionalArguments.length == 1 && op == '==') {
      // Coverage-ignore-block(suite): Not run.
      final Constant right = positionalArguments[0];
      return _handleEquals(node, receiver, right);
    }

    // This is an allow-listed set of methods we need to support on constants.
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
                codeConstEvalInvalidBinaryOperandType.withArguments(
                    '+',
                    receiver,
                    typeEnvironment.coreTypes.stringNonNullableRawType,
                    other.getType(staticTypeContext)));
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
              // Coverage-ignore(suite): Not run.
              return createEvaluationErrorConstant(
                  node,
                  codeConstEvalInvalidBinaryOperandType.withArguments(
                      '[]',
                      receiver,
                      typeEnvironment.coreTypes.intNonNullableRawType,
                      other.getType(staticTypeContext)));
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
                codeConstEvalInvalidBinaryOperandType.withArguments(
                    op,
                    other,
                    typeEnvironment.coreTypes.intNonNullableRawType,
                    other.getType(staticTypeContext)));
          }
          num receiverValue = (receiver as PrimitiveConstant<num>).value;
          return canonicalize(evaluateBinaryNumericOperation(
              op, receiverValue, other.value, node));
        }
        return createEvaluationErrorConstant(
            node,
            codeConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.numNonNullableRawType,
                other.getType(staticTypeContext)));
      }
    } else if (receiver is DoubleConstant) {
      if ((op == '|' || op == '&' || op == '^') ||
          (op == '<<' || op == '>>' || op == '>>>')) {
        return createEvaluationErrorConstant(
            node,
            codeConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.intNonNullableRawType,
                receiver.getType(staticTypeContext)));
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
        // Coverage-ignore(suite): Not run.
        return createEvaluationErrorConstant(
            node,
            codeConstEvalInvalidBinaryOperandType.withArguments(
                op,
                receiver,
                typeEnvironment.coreTypes.numNonNullableRawType,
                other.getType(staticTypeContext)));
      }
    } else if (receiver is BoolConstant) {
      if (positionalArguments.length == 1) {
        final Constant other = positionalArguments[0];
        if (other is BoolConstant) {
          switch (op) {
            case '|':
              return canonicalize(
                  makeBoolConstant(receiver.value || other.value));
            case '&':
              return canonicalize(
                  makeBoolConstant(receiver.value && other.value));
            case '^':
              return canonicalize(
                  makeBoolConstant(receiver.value != other.value));
          }
        }
      }
    } else if (receiver is NullConstant) {
      return createEvaluationErrorConstant(node, codeConstEvalNullValue);
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
            // Coverage-ignore(suite): Not run.
            return createEvaluationErrorConstant(
                node,
                codeConstEvalInvalidBinaryOperandType.withArguments(
                    '[]',
                    receiver,
                    typeEnvironment.coreTypes.intNonNullableRawType,
                    other.getType(staticTypeContext)));
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
        // Coverage-ignore-block(suite): Not run.
        AbortConstant error = _gotError!;
        _gotError = null;
        return error;
      }
      assert(_gotError == null);

      // Evaluate named arguments of the method invoked.
      final Map<String, Constant>? namedArguments =
          _evaluateNamedArguments(arguments.named);
      if (namedArguments == null) {
        // Coverage-ignore-block(suite): Not run.
        AbortConstant error = _gotError!;
        _gotError = null;
        return error;
      }
      assert(_gotError == null);

      if (receiver is FunctionValue &&
          // Coverage-ignore(suite): Not run.
          name == Name.callName) {
        // Coverage-ignore-block(suite): Not run.
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
        node, codeConstEvalInvalidMethodInvocation.withArguments(op, receiver));
  }

  @override
  Constant visitLogicalExpression(LogicalExpression node) {
    final Constant left = _evaluateSubexpression(node.left);
    if (left is AbortConstant) return left;
    if (shouldBeUnevaluated) {
      // Coverage-ignore-block(suite): Not run.
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
          if (right is BoolConstant ||
              // Coverage-ignore(suite): Not run.
              right is UnevaluatedConstant) {
            return right;
          }
          // Coverage-ignore(suite): Not run.
          return createEvaluationErrorConstant(
              node,
              codeConstEvalInvalidBinaryOperandType.withArguments(
                  logicalExpressionOperatorToString(node.operatorEnum),
                  left,
                  typeEnvironment.coreTypes.boolNonNullableRawType,
                  right.getType(staticTypeContext)));
        }
        // Coverage-ignore(suite): Not run.
        return createEvaluationErrorConstant(
            node,
            codeConstEvalInvalidMethodInvocation.withArguments(
                logicalExpressionOperatorToString(node.operatorEnum), left));
      case LogicalExpressionOperator.AND:
        if (left is BoolConstant) {
          if (!left.value) return falseConstant;

          final Constant right = _evaluateSubexpression(node.right);
          if (right is AbortConstant) return right;
          if (right is BoolConstant ||
              // Coverage-ignore(suite): Not run.
              right is UnevaluatedConstant) {
            return right;
          }
          // Coverage-ignore(suite): Not run.
          return createEvaluationErrorConstant(
              node,
              codeConstEvalInvalidBinaryOperandType.withArguments(
                  logicalExpressionOperatorToString(node.operatorEnum),
                  left,
                  typeEnvironment.coreTypes.boolNonNullableRawType,
                  right.getType(staticTypeContext)));
        }
        // Coverage-ignore(suite): Not run.
        return createEvaluationErrorConstant(
            node,
            codeConstEvalInvalidMethodInvocation.withArguments(
                logicalExpressionOperatorToString(node.operatorEnum), left));
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
      // Coverage-ignore-block(suite): Not run.
      return createEvaluationErrorConstant(
          node.condition,
          codeConstEvalInvalidType.withArguments(
              condition,
              typeEnvironment.coreTypes.boolNonNullableRawType,
              condition.getType(staticTypeContext)));
    }
  }

  @override
  Constant visitInstanceGet(InstanceGet node) {
    if (node.receiver is ThisExpression) {
      // Coverage-ignore: Probably unreachable unless trying to evaluate
      // non-const stuff as const.
      // Access "this" during instance creation.
      if (instanceBuilder == null) {
        return createEvaluationErrorConstant(node, codeNotAConstantExpression);
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
      // Coverage-ignore: Probably unreachable.
      return createEvaluationErrorConstant(
          node,
          codeConstEvalError.withArguments(
              'Could not evaluate field get ${node.name} on incomplete '
              'instance'));
    }

    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    if (receiver is StringConstant && node.name.text == 'length') {
      return canonicalize(intFolder.makeIntConstant(receiver.value.length));
    } else if (shouldBeUnevaluated) {
      // Coverage-ignore-block(suite): Not run.
      return unevaluated(
          node,
          new InstanceGet(node.kind, _wrap(receiver), node.name,
              resultType: node.resultType,
              interfaceTarget: node.interfaceTarget));
    } else if (receiver is NullConstant) {
      return createEvaluationErrorConstant(node, codeConstEvalNullValue);
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
        codeConstEvalInvalidPropertyGet.withArguments(
            node.name.text, receiver));
  }

  @override
  Constant visitRecordIndexGet(RecordIndexGet node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    if (receiver is RecordConstant && enableConstFunctions) {
      // Coverage-ignore-block(suite): Not run.
      if (node.index >= receiver.positional.length) {
        return new _AbortDueToThrowConstant(node, new StateError('No element'));
      }
      return receiver.positional[node.index];
    }
    return createEvaluationErrorConstant(
        node,
        codeConstEvalInvalidRecordIndexGet.withArguments(
            "${node.index}", receiver));
  }

  @override
  Constant visitRecordNameGet(RecordNameGet node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    if (receiver is RecordConstant && enableConstFunctions) {
      // Coverage-ignore-block(suite): Not run.
      Constant? result = receiver.named[node.name];
      if (result == null) {
        return new _AbortDueToThrowConstant(node, new StateError('No element'));
      } else {
        return result;
      }
    }
    return createEvaluationErrorConstant(node,
        codeConstEvalInvalidRecordNameGet.withArguments(node.name, receiver));
  }

  @override
  Constant visitDynamicGet(DynamicGet node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    if (receiver is StringConstant && node.name.text == 'length') {
      return canonicalize(intFolder.makeIntConstant(receiver.value.length));
    }
    // Coverage-ignore(suite): Not run.
    else if (shouldBeUnevaluated) {
      return unevaluated(
          node, new DynamicGet(node.kind, _wrap(receiver), node.name));
    } else if (receiver is NullConstant) {
      return createEvaluationErrorConstant(node, codeConstEvalNullValue);
    }
    // Coverage-ignore(suite): Not run.
    return createEvaluationErrorConstant(
        node,
        codeConstEvalInvalidPropertyGet.withArguments(
            node.name.text, receiver));
  }

  @override
  Constant visitInstanceTearOff(InstanceTearOff node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    return createEvaluationErrorConstant(
        node,
        codeConstEvalInvalidPropertyGet.withArguments(
            node.name.text, receiver));
  }

  @override
  Constant visitFunctionTearOff(FunctionTearOff node) {
    final Constant receiver = _evaluateSubexpression(node.receiver);
    if (receiver is AbortConstant) return receiver;
    // Coverage-ignore(suite): Not run.
    return createEvaluationErrorConstant(
        node,
        codeConstEvalInvalidPropertyGet.withArguments(
            Name.callName.text, receiver));
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
    if (enableConstFunctions || inExtensionTypeConstConstructor) {
      return env.lookupVariable(variable) ??
          // Coverage-ignore(suite): Not run.
          createEvaluationErrorConstant(node,
              codeConstEvalGetterNotFound.withArguments(variable.name ?? ''));
    } else {
      if (variable.parent is Let ||
          variable.parent is LocalInitializer ||
          _isFormalParameter(variable)) {
        return env.lookupVariable(node.variable) ??
            createEvaluationErrorConstant(
                node,
                codeConstEvalNonConstantVariableGet
                    .withArguments(variable.name ?? ''));
      }
      if (variable.isConst) {
        return _evaluateSubexpression(variable.initializer!);
      }
    }
    return createExpressionErrorConstant(
        node,
        codeNotConstantExpression
            .withArguments('Read of a non-const variable'));
  }

  @override
  Constant visitVariableSet(VariableSet node) {
    if (enableConstFunctions || inExtensionTypeConstConstructor) {
      final VariableDeclaration variable = node.variable;
      Constant value = _evaluateSubexpression(node.value);
      if (value is AbortConstant) return value;
      Constant? result = env.updateVariableValue(variable, value);
      if (result != null) {
        return result;
      }
      // Coverage-ignore(suite): Not run.
      return createEvaluationErrorConstant(
          node,
          codeConstEvalError
              .withArguments('Variable set of an unknown value.'));
    }
    return _notAConstantExpression(node);
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
    _staticTypeContext = oldStaticTypeContext;
    return constant;
  }

  @override
  Constant visitStaticGet(StaticGet node) {
    final Member target = node.target;
    visitedLibraries.add(target.enclosingLibrary);
    if (target is Field && target.isConst) {
      return withNewEnvironment(
          () => evaluateExpressionInContext(target, target.initializer!));
    } else if (target is Procedure) {
      if (target.kind == ProcedureKind.Method) {
        // Coverage-ignore-block(suite): Not run.
        // TODO(johnniwinther): Remove this. This should never occur.
        return canonicalize(new StaticTearOffConstant(target));
      } else if (target.kind == ProcedureKind.Getter && enableConstFunctions) {
        return _handleFunctionInvocation(target.function, [], [], {});
      }
    }
    return createEvaluationErrorConstant(node,
        codeConstEvalInvalidStaticInvocation.withArguments(target.name.text));
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
          // Coverage-ignore-block(suite): Not run.
          concatenated.add(new StringBuffer(value));
        }
      } else if (shouldBeUnevaluated) {
        // Coverage-ignore-block(suite): Not run.
        // The constant is either unevaluated or a non-primitive in an
        // unevaluated context. In both cases we defer the evaluation and/or
        // error reporting till later.
        concatenated.add(constant);
      } else {
        return createEvaluationErrorConstant(
            node,
            codeConstEvalInvalidStringInterpolationOperand
                .withArguments(constant));
      }
    }
    if (concatenated.length > 1) {
      // Coverage-ignore-block(suite): Not run.
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
        }
        // Coverage-ignore(suite): Not run.
        else if (defaultValue is NullConstant) {
          boolConstant = nullConstant;
        } else {
          // Coverage-ignore: Probably unreachable.
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
          // Coverage-ignore-block(suite): Not run.
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
          // Coverage-ignore-block(suite): Not run.
          stringConstant = nullConstant;
        }
      } else {
        stringConstant = _getFromEnvironmentDefaultValue(target);
      }
      return stringConstant;
    }
    // Coverage-ignore: Unreachable until fromEnvironment is added to other
    // classes in dart:core than bool, int and String.
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

    final List<DartType> typeArguments = convertTypes(types);

    final List<Constant>? positional =
        _evaluatePositionalArguments(arguments.positional);
    if (positional == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    final Map<String, Constant>? named =
        _evaluateNamedArguments(arguments.named);
    if (named == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    if (shouldBeUnevaluated) {
      return unevaluated(
          node,
          new StaticInvocation(
              target, unevaluatedArguments(positional, named, arguments.types),
              isConst: node.isConst));
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
            }
            // Coverage-ignore(suite): Not run.
            else if (name is NullConstant) {
              return createEvaluationErrorConstant(
                  node, codeConstEvalNullValue);
            }
          } else {
            // Leave environment constant unevaluated.
            return unevaluated(
                node,
                new StaticInvocation(target,
                    unevaluatedArguments(positional, named, arguments.types),
                    isConst: node.isConst));
          }
        } else if (target.isExternal) {
          return createEvaluationErrorConstant(
              node, codeConstEvalExternalFactory);
        } else if (enableConstFunctions) {
          return _handleFunctionInvocation(
              node.target.function, typeArguments, positional, named);
        } else {
          return createExpressionErrorConstant(
              node,
              codeNotConstantExpression
                  .withArguments('Non-redirecting const factory invocation'));
        }
      } else {
        if (enableConstFunctions) {
          return _handleFunctionInvocation(
              node.target.function, typeArguments, positional, named);
        } else if (!node.isConst) {
          return createExpressionErrorConstant(
              node, codeNotConstantExpression.withArguments('New expression'));
        } else {
          // Coverage-ignore-block(suite): Not run.
          return createEvaluationErrorConstant(
              node,
              codeNotConstantExpression
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
          return makeBoolConstant(identical(left, right));
        }

        if (targetingJavaScript) {
          // In JavaScript, we lower [identical] to `===`, so we need to take
          // the double special cases into account.
          return doubleSpecialCases(left, right) ?? evaluateIdentical();
        }
        return evaluateIdentical();
      }
    } else if (target.isExtensionTypeMember) {
      if (target.isConst) {
        bool oldInExtensionTypeConstructor = inExtensionTypeConstConstructor;
        inExtensionTypeConstConstructor = true;
        Constant result = _handleFunctionInvocation(
            node.target.function, typeArguments, positional, named);
        inExtensionTypeConstConstructor = oldInExtensionTypeConstructor;
        if (shouldBeUnevaluated) {
          return unevaluated(
              node,
              new StaticInvocation(target,
                  unevaluatedArguments(positional, named, arguments.types),
                  isConst: node.isConst));
        }
        return result;
      } else {
        return createEvaluationErrorConstant(
            node,
            codeNotConstantExpression.withArguments(
                'Invocation of non-const extension type member'));
      }
    } else if (target.isExtensionMember) {
      return createEvaluationErrorConstant(node, codeConstEvalExtension);
    } else if (enableConstFunctions && target.kind == ProcedureKind.Method) {
      return _handleFunctionInvocation(
          node.target.function, typeArguments, positional, named);
    }

    return createExpressionErrorConstant(
        node, codeNotConstantExpression.withArguments('Static invocation'));
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
        // Coverage-ignore-block(suite): Not run.
        // Ensure that the evaluated constant returned is not null if the
        // function has a non-nullable return type.
        return createEvaluationErrorConstant(
            function,
            codeConstEvalInvalidType.withArguments(result, function.returnType,
                result.getType(staticTypeContext)));
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
      // Coverage-ignore-block(suite): Not run.
      return unevaluated(node,
          new AsExpression(_wrap(constant), env.substituteType(node.type)));
    }
    DartType? type = _evaluateDartType(node, node.type);
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);
    return ensureIsSubtype(constant, type, node);
  }

  @override
  Constant visitIsExpression(IsExpression node) {
    final Constant constant = _evaluateSubexpression(node.operand);
    if (constant is AbortConstant) return constant;
    if (shouldBeUnevaluated) {
      // Coverage-ignore-block(suite): Not run.
      return unevaluated(
          node,
          new IsExpression(_wrap(constant), env.substituteType(node.type))
            ..fileOffset = node.fileOffset);
    }

    DartType? type = _evaluateDartType(node, node.type);
    if (type == null) {
      AbortConstant error = _gotError!;
      _gotError = null;
      return error;
    }
    assert(_gotError == null);

    bool performIs(Constant constant, {required bool strongMode}) {
      if (strongMode) {
        return isSubtype(constant, type);
      } else {
        // Coverage-ignore-block(suite): Not run.
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
          return typeEnvironment.isSubtypeOf(const NullType(), type);
        }
        return isSubtype(constant, type);
      }
    }

    return makeBoolConstant(performIs(constant, strongMode: true));
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
    // Coverage-ignore(suite): Not run.
    return createEvaluationErrorConstant(
        node,
        codeConstEvalInvalidType.withArguments(
            constant,
            typeEnvironment.coreTypes.boolNonNullableRawType,
            constant.getType(staticTypeContext)));
  }

  @override
  Constant visitNullCheck(NullCheck node) {
    if (enableConstFunctions) {
      final Constant constant = _evaluateSubexpression(node.operand);
      if (constant is AbortConstant) return constant;
      if (constant is NullConstant) {
        return createEvaluationErrorConstant(node, codeConstEvalNonNull);
      }
      // Coverage-ignore(suite): Not run.
      if (shouldBeUnevaluated) {
        return unevaluated(node, new NullCheck(_wrap(constant)));
      }
      return constant;
    } else {
      return _notAConstantExpression(node);
    }
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
    return _notAConstantExpression(node);
  }

  @override
  Constant visitInstantiation(Instantiation node) {
    Constant constant = _evaluateSubexpression(node.expression);
    if (constant is AbortConstant) return constant;
    if (shouldBeUnevaluated) {
      // Coverage-ignore-block(suite): Not run.
      return unevaluated(
          node,
          new Instantiation(_wrap(constant),
              node.typeArguments.map((t) => env.substituteType(t)).toList()));
    }

    int? typeParameterCount;
    if (constant is TearOffConstant) {
      Member target = constant.target;
      if (target is Procedure) {
        typeParameterCount = target.function.typeParameters.length;
      } else if (target is Constructor) {
        typeParameterCount = target.enclosingClass.typeParameters.length;
      }
    } else if (constant is TypedefTearOffConstant) {
      typeParameterCount = constant.parameters.length;
    }
    if (typeParameterCount != null) {
      if (node.typeArguments.length == typeParameterCount) {
        List<DartType>? types = _evaluateDartTypes(node, node.typeArguments);
        if (types == null) {
          AbortConstant error = _gotError!;
          _gotError = null;
          return error;
        }
        assert(_gotError == null);

        return canonicalize(
            new InstantiationConstant(constant, convertTypes(types)));
      } else {
        // Coverage-ignore: Probably unreachable.
        return createEvaluationErrorConstant(
            node,
            codeConstEvalError.withArguments(
                'The number of type arguments supplied in the partial '
                'instantiation does not match the number of type arguments '
                'of the $constant.'));
      }
    }
    // The inner expression in an instantiation can never be null, since
    // instantiations are only inferred on direct references to declarations.
    // Coverage-ignore: Probably unreachable.
    return createEvaluationErrorConstant(
        node,
        codeConstEvalError.withArguments(
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
      FreshStructuralParameters freshTypeParameters =
          getFreshStructuralParameters(node.structuralParameters);
      List<StructuralParameter> typeParameters =
          freshTypeParameters.freshTypeParameters;
      List<DartType> typeArguments = new List<DartType>.generate(
          node.typeArguments.length,
          (int i) => freshTypeParameters.substitute(node.typeArguments[i]),
          growable: false);
      return canonicalize(
          new TypedefTearOffConstant(typeParameters, constant, typeArguments));
    } else {
      // Coverage-ignore: Probably unreachable.
      return createEvaluationErrorConstant(
          node,
          codeConstEvalError.withArguments(
              "Unsupported typedef tearoff target: ${constant}."));
    }
  }

  @override
  Constant visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return createEvaluationErrorConstant(
        node, codeConstEvalDeferredLibrary.withArguments(node.import.name!));
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

  bool isSubtype(Constant constant, DartType type) {
    DartType constantType =
        constant.getType(staticTypeContext).extensionTypeErasure;
    if (type is RecordType && constant is RecordConstant) {
      if (type.positional.length != constant.positional.length ||
          type.named.length != constant.named.length ||
          !type.named.every(
              (namedType) => constant.named.containsKey(namedType.name))) {
        return false;
      }
      for (int i = 0; i < type.positional.length; i++) {
        final DartType fieldType = type.positional[i];
        final Constant fieldValue = constant.positional[i];
        if (!isSubtype(fieldValue, fieldType)) return false;
      }
      for (int i = 0; i < type.named.length; i++) {
        final NamedType namedFieldType = type.named[i];
        final Constant fieldValue = constant.named[namedFieldType.name]!;
        if (!isSubtype(fieldValue, namedFieldType.type)) return false;
      }
      return true;
    }
    bool result = typeEnvironment.isSubtypeOf(constantType, type);
    if (targetingJavaScript && !result) {
      if (constantType is InterfaceType &&
          constantType.classNode == typeEnvironment.coreTypes.intClass) {
        // Coverage-ignore: Probably unreachable.
        // With JS semantics, an integer is also a double.
        result = typeEnvironment.isSubtypeOf(
            new InterfaceType(typeEnvironment.coreTypes.doubleClass,
                constantType.nullability, const <DartType>[]),
            type);
      } else if (intFolder.isInt(constant)) {
        // With JS semantics, an integer valued double is also an int.
        result = typeEnvironment.isSubtypeOf(
            new InterfaceType(typeEnvironment.coreTypes.intClass,
                constantType.nullability, const <DartType>[]),
            type);
      }
    }
    return result;
  }

  /// Note that this returns an error-constant on error and as such the
  /// return value should be checked.
  Constant ensureIsSubtype(Constant constant, DartType type, TreeNode node) {
    bool result = isSubtype(constant, type);
    if (!result) {
      return createEvaluationErrorConstant(
          node,
          codeConstEvalInvalidType.withArguments(
              constant, type, constant.getType(staticTypeContext)));
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
    // TODO: Once the frontend guarantees that there are no free type parameters
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
      result[i] = type;
    }
    return result;
  }

  /// Returns the reified type on success and null on failure.
  /// Note that on failure an errorConstant is saved in [_gotError].
  DartType? _evaluateDartType(TreeNode node, DartType type) {
    final DartType result = env.substituteType(type.extensionTypeErasure);

    if (!isInstantiated(result)) {
      // TODO(johnniwinther): Maybe we should always report this in the body
      // builder. Currently we report some, because we need to handle
      // potentially constant types, but we should be able to handle all (or
      // none) in the body builder.
      _gotError = createExpressionErrorConstant(
          node, codeTypeVariableInConstantContext);
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
    for (int i = 0; i < named.length; i++) {
      NamedExpression pair = named[i];
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
    namedArgs.forEach(
        // Coverage-ignore(suite): Not run.
        (String name, Constant value) {
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
    if (enableConstFunctions || inExtensionTypeConstConstructor) {
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
              node, codeConstEvalZeroDivisor.withArguments(op, '$a'));
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

    // Coverage-ignore: Probably unreachable.
    return createExpressionErrorConstant(node,
        codeNotConstantExpression.withArguments("Binary '$op' operation"));
  }

  @override
  Constant visitAwaitExpression(AwaitExpression node) =>
      _notAConstantExpression(node);

  @override
  Constant visitBlockExpression(BlockExpression node) =>
      _notAConstantExpression(node);

  @override
  Constant visitDynamicSet(DynamicSet node) => _notAConstantExpression(node);

  @override
  Constant visitInstanceGetterInvocation(InstanceGetterInvocation node) =>
      _notAConstantExpression(node);

  @override
  Constant visitInstanceSet(InstanceSet node) => _notAConstantExpression(node);

  @override
  Constant visitLoadLibrary(LoadLibrary node) => _notAConstantExpression(node);

  @override
  Constant visitRethrow(Rethrow node) => _notAConstantExpression(node);

  @override
  Constant visitStaticSet(StaticSet node) => _notAConstantExpression(node);

  @override
  // Coverage-ignore(suite): Not run.
  Constant visitAbstractSuperMethodInvocation(
          AbstractSuperMethodInvocation node) =>
      _notAConstantExpression(node);

  @override
  Constant visitSuperMethodInvocation(SuperMethodInvocation node) =>
      _notAConstantExpression(node);

  @override
  // Coverage-ignore(suite): Not run.
  Constant visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node) =>
      _notAConstantExpression(node);

  @override
  // Coverage-ignore(suite): Not run.
  Constant visitAbstractSuperPropertySet(AbstractSuperPropertySet node) =>
      _notAConstantExpression(node);

  @override
  Constant visitSuperPropertyGet(SuperPropertyGet node) =>
      _notAConstantExpression(node);

  @override
  Constant visitSuperPropertySet(SuperPropertySet node) =>
      _notAConstantExpression(node);

  @override
  Constant visitThisExpression(ThisExpression node) =>
      _notAConstantExpression(node);

  @override
  // Coverage-ignore(suite): Not run.
  Constant visitSwitchExpression(SwitchExpression node) {
    return createExpressionErrorConstant(
        node, codeNotConstantExpression.withArguments('Switch expression'));
  }

  @override
  // Coverage-ignore(suite): Not run.
  Constant visitPatternAssignment(PatternAssignment node) {
    return createExpressionErrorConstant(
        node, codeNotConstantExpression.withArguments('Pattern assignment'));
  }

  @override
  Constant visitAuxiliaryExpression(AuxiliaryExpression node) {
    throw new UnsupportedError(
        "Unsupported auxiliary expression ${node} (${node.runtimeType}).");
  }
}

class StatementConstantEvaluator implements StatementVisitor<ExecutionStatus> {
  ConstantEvaluator exprEvaluator;

  StatementConstantEvaluator(this.exprEvaluator);

  /// Evaluate the expression using the [ConstantEvaluator].
  Constant evaluate(Expression expr) => expr.accept(exprEvaluator);

  @override
  // Coverage-ignore(suite): Not run.
  ExecutionStatus visitAssertBlock(AssertBlock node) {
    if (!exprEvaluator.enableAsserts) return const ProceedStatus();
    throw new UnsupportedError(
        'Statement constant evaluation does not support ${node.runtimeType}.');
  }

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
      // Coverage-ignore-block(suite): Not run.
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
    if (condition is AbortConstant) {
      // Coverage-ignore-block(suite): Not run.
      return new AbortStatus(condition);
    }
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

    if (condition is AbortConstant) {
      // Coverage-ignore-block(suite): Not run.
      return new AbortStatus(condition);
    }
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
    if (value is AbortConstant) {
      // Coverage-ignore-block(suite): Not run.
      return new AbortStatus(value);
    }

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
          if (exprEvaluator.typeEnvironment
                  .isSubtypeOf(throwType!, catchClause.guard) ||
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
    if (condition is AbortConstant) {
      // Coverage-ignore-block(suite): Not run.
      return new AbortStatus(condition);
    }
    assert(condition is BoolConstant);
    return const ProceedStatus();
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExecutionStatus visitForInStatement(ForInStatement node) {
    return new AbortStatus(exprEvaluator.createEvaluationErrorConstant(
        node, codeConstEvalError.withArguments('For-in statement.')));
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExecutionStatus visitIfCaseStatement(IfCaseStatement node) {
    return new AbortStatus(exprEvaluator.createEvaluationErrorConstant(
        node, codeConstEvalError.withArguments('If-case statement.')));
  }

  @override
  ExecutionStatus visitPatternSwitchStatement(PatternSwitchStatement node) {
    return new AbortStatus(exprEvaluator.createEvaluationErrorConstant(
        node, codeConstEvalError.withArguments('Pattern switch statement.')));
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExecutionStatus visitPatternVariableDeclaration(
      PatternVariableDeclaration node) {
    return new AbortStatus(exprEvaluator.createEvaluationErrorConstant(node,
        codeConstEvalError.withArguments('Pattern variable declaration.')));
  }

  @override
  // Coverage-ignore(suite): Not run.
  ExecutionStatus visitYieldStatement(YieldStatement node) {
    return new AbortStatus(exprEvaluator.createEvaluationErrorConstant(
        node, codeConstEvalError.withArguments('Yield statement.')));
  }

  @override
  ExecutionStatus visitAuxiliaryStatement(AuxiliaryStatement node) {
    throw new UnsupportedError(
        "Unsupported auxiliary statement ${node} (${node.runtimeType}).");
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
  final Map<TypeParameter, DartType> _typeParameters =
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
    if (_parent != null && !_parent.isEmpty) return false;
    return _typeParameters.isEmpty && _variables.isEmpty;
  }

  void addTypeParameterValue(TypeParameter parameter, DartType value) {
    assert(!_typeParameters.containsKey(parameter));
    _typeParameters[parameter] = value;
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
    // Coverage-ignore(suite): Not run.
    return _unreadUnevaluatedVariables.map<UnevaluatedConstant>(
        (VariableDeclaration variable) =>
            _variables[variable]!.value as UnevaluatedConstant);
  }

  DartType substituteType(DartType type) {
    if (_typeParameters.isEmpty) return _parent?.substituteType(type) ?? type;
    final DartType substitutedType = substitute(type, _typeParameters);
    if (identical(substitutedType, type) && _parent != null) {
      // No distinct type created, substitute type in parent.
      return _parent.substituteType(type);
    }
    return substitutedType;
  }
}

class RedundantFileUriExpressionRemover extends Transformer {
  Uri? currentFileUri = null;

  @override
  TreeNode visitFileUriExpression(FileUriExpression node) {
    if (node.fileUri == currentFileUri) {
      // Coverage-ignore-block(suite): Not run.
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
class FunctionValue implements AuxiliaryConstant {
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
  R acceptReference<R>(ConstantReferenceVisitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) {
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

abstract class AbortConstant implements AuxiliaryConstant {}

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
  R acceptReference<R>(ConstantReferenceVisitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) {
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
  R acceptReference<R>(ConstantReferenceVisitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) {
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
  R acceptReference<R>(ConstantReferenceVisitor<R> v) {
    throw new UnimplementedError();
  }

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) {
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

  /// `true` if the reporter supports a query to [hasSeenError].
  bool get supportsTrackingReportedErrors;

  /// `true` if a compile-time error has been reported.
  bool get hasSeenError;
}

// Coverage-ignore(suite): Not run.
class SimpleErrorReporter implements ErrorReporter {
  const SimpleErrorReporter();

  @override
  bool get supportsTrackingReportedErrors => false;

  @override
  bool get hasSeenError {
    return unsupported("SimpleErrorReporter.hasSeenError", -1, null);
  }

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
  return !type.accept(new HasUninstantiatedVisitor());
}

class HasUninstantiatedVisitor extends FindTypeVisitor {
  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return true;
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
