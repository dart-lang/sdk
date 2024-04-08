// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/macro_declarations.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart' as macro;
import 'package:macros/src/executor.dart' as macro;
import 'package:macros/src/executor/exception_impls.dart' as macro;
import 'package:macros/src/executor/multi_executor.dart';
import 'package:meta/meta.dart';

/// The full list of [macro.ArgumentKind]s for this dart type, with type
/// arguments for [InterfaceType]s, if [includeTop] is `true` also including
/// the [InterfaceType] itself, with [macro.ArgumentKind.nullable] preceding
/// nullable types, depth first.
List<macro.ArgumentKind> _argumentKindsOfType(
  DartType type, {
  bool includeTop = true,
}) {
  return [
    if (type.nullabilitySuffix == NullabilitySuffix.question)
      macro.ArgumentKind.nullable,
    if (includeTop)
      switch (type) {
        DartType(isDartCoreBool: true) => macro.ArgumentKind.bool,
        DartType(isDartCoreDouble: true) => macro.ArgumentKind.double,
        DartType(isDartCoreInt: true) => macro.ArgumentKind.int,
        DartType(isDartCoreNum: true) => macro.ArgumentKind.num,
        DartType(isDartCoreNull: true) => macro.ArgumentKind.nil,
        DartType(isDartCoreObject: true) => macro.ArgumentKind.object,
        DartType(isDartCoreString: true) => macro.ArgumentKind.string,
        DartType(isDartCoreList: true) => macro.ArgumentKind.list,
        DartType(isDartCoreMap: true) => macro.ArgumentKind.map,
        DartType(isDartCoreSet: true) => macro.ArgumentKind.set,
        DynamicType() => macro.ArgumentKind.dynamic,
        // TODO(jakemac): Support type annotations and code objects
        _ => throw UnsupportedError('Unsupported macro type argument $type'),
      },
    if (type is InterfaceType) ...[
      for (final typeArgument in type.typeArguments)
        ..._argumentKindsOfType(typeArgument),
    ]
  ];
}

class LibraryMacroApplier {
  @visibleForTesting
  static bool testThrowExceptionTypes = false;

  @visibleForTesting
  static bool testThrowExceptionDeclarations = false;

  @visibleForTesting
  static bool testThrowExceptionDefinitions = false;

  @visibleForTesting
  static bool testThrowExceptionIntrospection = false;

  final LinkedElementFactory elementFactory;
  final MultiMacroExecutor macroExecutor;
  final bool Function(Uri) isLibraryBeingLinked;
  final DeclarationBuilder declarationBuilder;

  /// The callback to run declarations phase if the type.
  /// We do it out-of-order when the type is introspected.
  final Future<void> Function({
    required ElementImpl? targetElement,
    required OperationPerformanceImpl performance,
  }) runDeclarationsPhase;

  /// The applications that currently run the declarations phase.
  final List<_MacroApplication> _declarationsPhaseRunning = [];

  /// The map from a declaration that has declarations phase introspection
  /// cycle, to the cycle exception.
  final Map<MacroTargetElement, _MacroIntrospectionCycleException>
      _elementToIntrospectionCycleException = {};

  late final macro.TypePhaseIntrospector _typesPhaseIntrospector =
      _TypePhaseIntrospector(
    elementFactory,
    declarationBuilder,
    OperationPerformanceImpl('<typesPhaseIntrospector>'),
  );

  LibraryMacroApplier({
    required this.elementFactory,
    required this.macroExecutor,
    required this.isLibraryBeingLinked,
    required this.declarationBuilder,
    required this.runDeclarationsPhase,
  });

  Future<void> add({
    required LibraryBuilder libraryBuilder,
    required LibraryOrAugmentationElementImpl container,
    required ast.CompilationUnitImpl unit,
  }) async {
    for (final directive in unit.directives.reversed) {
      switch (directive) {
        case ast.LibraryDirectiveImpl():
          await _addAnnotations(
            libraryBuilder: libraryBuilder,
            container: container,
            targetNode: directive,
            targetNodeElement: libraryBuilder.element,
            targetDeclarationKind: macro.DeclarationKind.library,
            annotations: directive.metadata,
          );
        default:
          break;
      }
    }

    for (final declaration in unit.declarations.reversed) {
      switch (declaration) {
        case ast.ClassDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryBuilder: libraryBuilder,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.classType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
        case ast.ClassTypeAliasImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryBuilder: libraryBuilder,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.classType,
            classAnnotations: declaration.metadata,
            members: const [],
          );
        case ast.EnumDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryBuilder: libraryBuilder,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.enumType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
          for (final constant in declaration.constants.reversed) {
            await _addAnnotations(
              libraryBuilder: libraryBuilder,
              container: container,
              targetNode: constant,
              targetNodeElement: constant.declaredElement,
              targetDeclarationKind: macro.DeclarationKind.enumValue,
              annotations: constant.metadata,
            );
          }
        case ast.ExtensionDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryBuilder: libraryBuilder,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.extension,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
        case ast.ExtensionTypeDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryBuilder: libraryBuilder,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.extensionType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
        case ast.FunctionDeclarationImpl():
          await _addAnnotations(
            libraryBuilder: libraryBuilder,
            container: container,
            targetNode: declaration,
            targetNodeElement: declaration.declaredElement,
            targetDeclarationKind: macro.DeclarationKind.function,
            annotations: declaration.metadata,
          );
        case ast.FunctionTypeAliasImpl():
          // TODO(scheglov): implement it
          break;
        case ast.GenericTypeAliasImpl():
          await _addAnnotations(
            libraryBuilder: libraryBuilder,
            container: container,
            targetNode: declaration,
            targetNodeElement: declaration.declaredElement,
            targetDeclarationKind: macro.DeclarationKind.typeAlias,
            annotations: declaration.metadata,
          );
        case ast.MixinDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryBuilder: libraryBuilder,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.mixinType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
        case ast.TopLevelVariableDeclarationImpl():
          final variables = declaration.variables.variables;
          for (final variable in variables.reversed) {
            await _addAnnotations(
              libraryBuilder: libraryBuilder,
              container: container,
              targetNode: variable,
              targetNodeElement: variable.declaredElement,
              targetDeclarationKind: macro.DeclarationKind.variable,
              annotations: declaration.metadata,
            );
          }
      }
    }
  }

  /// Builds the augmentation library code for [results].
  String? buildAugmentationLibraryCode(
    Uri augmentedLibraryUri,
    List<macro.MacroExecutionResult> results,
  ) {
    if (results.isEmpty) {
      return null;
    }

    return macroExecutor.buildAugmentationLibrary(
      augmentedLibraryUri,
      results,
      declarationBuilder.typeDeclarationOf,
      declarationBuilder.resolveIdentifier,
      declarationBuilder.inferOmittedType,
    );
  }

  Future<List<macro.MacroExecutionResult>?> executeDeclarationsPhase({
    required LibraryBuilder libraryBuilder,
    required ElementImpl? targetElement,
    required OperationPerformanceImpl performance,
  }) async {
    if (targetElement != null) {
      for (var i = 0; i < _declarationsPhaseRunning.length; i++) {
        var running = _declarationsPhaseRunning[i];
        if (running.target.element == targetElement) {
          var applications = _declarationsPhaseRunning.sublist(i);
          var exception = _MacroIntrospectionCycleException(
            'Declarations phase introspection cycle.',
            applications: applications,
          );

          // Mark all applications as having introspection cycle.
          // So, every introspection of these elements will throw.
          for (var application in applications) {
            var element = application.target.element;
            _elementToIntrospectionCycleException[element] = exception;
          }

          throw exception;
        }
      }
    }

    final application = _nextForDeclarationsPhase(
      libraryBuilder: libraryBuilder,
      targetElement: targetElement,
    );
    if (application == null) {
      return null;
    }

    _declarationsPhaseRunning.add(application);

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final target = _buildTarget(application.target.node);

        final introspector = _DeclarationPhaseIntrospector(
          elementFactory,
          declarationBuilder,
          performance,
          this,
          libraryBuilder.element.typeSystem,
        );

        final result = await macroExecutor.executeDeclarationsPhase(
          application.instance,
          target,
          introspector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }

        if (testThrowExceptionDeclarations) {
          throw 'Intentional exception';
        }
      },
      targetElement: application.target.element,
      annotationIndex: application.annotationIndex,
    );

    _declarationsPhaseRunning.remove(application);
    return results;
  }

  Future<List<macro.MacroExecutionResult>?> executeDefinitionsPhase({
    required LibraryBuilder libraryBuilder,
    required OperationPerformanceImpl performance,
  }) async {
    final application = _nextForDefinitionsPhase(
      libraryBuilder: libraryBuilder,
    );
    if (application == null) {
      return null;
    }

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final target = _buildTarget(application.target.node);

        final introspector = _DefinitionPhaseIntrospector(
          elementFactory,
          declarationBuilder,
          performance,
          this,
          application.target.library.element.typeSystem,
        );

        final result = await macroExecutor.executeDefinitionsPhase(
          application.instance,
          target,
          introspector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }

        if (testThrowExceptionDefinitions) {
          throw 'Intentional exception';
        }
      },
      targetElement: application.target.element,
      annotationIndex: application.annotationIndex,
    );

    return results;
  }

  Future<List<macro.MacroExecutionResult>?> executeTypesPhase({
    required LibraryBuilder libraryBuilder,
  }) async {
    final application = _nextForTypesPhase(
      libraryBuilder: libraryBuilder,
    );
    if (application == null) {
      return null;
    }

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final target = _buildTarget(application.target.node);

        final result = await macroExecutor.executeTypesPhase(
          application.instance,
          target,
          _typesPhaseIntrospector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }

        if (testThrowExceptionTypes) {
          throw 'Intentional exception';
        }
      },
      targetElement: application.target.element,
      annotationIndex: application.annotationIndex,
    );

    return results;
  }

  Future<void> _addAnnotations({
    required LibraryBuilder libraryBuilder,
    required LibraryOrAugmentationElementImpl container,
    required ast.AstNode targetNode,
    required Element? targetNodeElement,
    required macro.DeclarationKind targetDeclarationKind,
    required List<ast.Annotation> annotations,
  }) async {
    if (targetNode is ast.FieldDeclaration) {
      for (final field in targetNode.fields.variables) {
        await _addAnnotations(
          libraryBuilder: libraryBuilder,
          container: container,
          targetNode: field,
          targetNodeElement: field.declaredElement,
          targetDeclarationKind: macro.DeclarationKind.field,
          annotations: annotations,
        );
      }
      return;
    }

    final targetElement = targetNodeElement.ifTypeOrNull<MacroTargetElement>();
    if (targetElement == null) {
      return;
    }

    final macroTarget = _MacroTarget(
      library: libraryBuilder,
      node: targetNode,
      element: targetElement,
    );

    for (final (annotationIndex, annotation) in annotations.indexed) {
      final importedMacro = _importedMacro(
        container: container,
        annotation: annotation,
      );
      if (importedMacro == null) {
        continue;
      }

      final constructorElement = importedMacro.constructorElement;
      if (constructorElement == null) {
        continue;
      }

      final instance = await _runWithCatchingExceptions(
        () async {
          final arguments = _buildArguments(
            annotationIndex: annotationIndex,
            constructor: constructorElement,
            node: importedMacro.arguments,
          );

          return await importedMacro.bundleExecutor.instantiate(
            libraryUri: importedMacro.macroLibrary.source.uri,
            className: importedMacro.macroClass.name,
            constructorName: importedMacro.constructorName ?? '',
            arguments: arguments,
          );
        },
        targetElement: targetElement,
        annotationIndex: annotationIndex,
      );
      if (instance == null) {
        continue;
      }

      final phasesToExecute = macro.Phase.values.where((phase) {
        return instance.shouldExecute(targetDeclarationKind, phase);
      }).toSet();

      if (!instance.supportsDeclarationKind(targetDeclarationKind)) {
        macroTarget.element.addMacroDiagnostic(
          InvalidMacroTargetDiagnostic(
            annotationIndex: annotationIndex,
            supportedKinds: macro.DeclarationKind.values
                .where(instance.supportsDeclarationKind)
                .map((e) => e.name)
                .toList(),
          ),
        );
        return;
      }

      final application = _MacroApplication(
        target: macroTarget,
        annotationIndex: annotationIndex,
        annotationNode: annotation,
        instance: instance,
        phasesToExecute: phasesToExecute,
      );

      libraryBuilder._applications.add(application);
    }
  }

  Future<void> _addClassLike({
    required LibraryBuilder libraryBuilder,
    required LibraryOrAugmentationElementImpl container,
    required MacroTargetElement targetElement,
    required ast.Declaration classNode,
    required macro.DeclarationKind classDeclarationKind,
    required List<ast.Annotation> classAnnotations,
    required List<ast.ClassMember> members,
  }) async {
    await _addAnnotations(
      libraryBuilder: libraryBuilder,
      container: container,
      targetNode: classNode,
      targetNodeElement: classNode.declaredElement,
      targetDeclarationKind: classDeclarationKind,
      annotations: classAnnotations,
    );

    for (final member in members.reversed) {
      final memberDeclarationKind = switch (member) {
        ast.ConstructorDeclaration() => macro.DeclarationKind.constructor,
        ast.FieldDeclaration() => macro.DeclarationKind.field,
        ast.MethodDeclaration() => macro.DeclarationKind.method,
      };
      await _addAnnotations(
        libraryBuilder: libraryBuilder,
        container: container,
        targetNode: member,
        targetNodeElement: member.declaredElement,
        targetDeclarationKind: memberDeclarationKind,
        annotations: member.metadata,
      );
    }
  }

  void _addDiagnostics(
    _MacroApplication application,
    macro.MacroExecutionResult result,
  ) {
    MacroDiagnosticMessage convertMessage(
      macro.DiagnosticMessage message,
    ) {
      MacroDiagnosticTarget target;
      switch (message.target) {
        case macro.DeclarationDiagnosticTarget macroTarget:
          final element = (macroTarget.declaration as HasElement).element;
          target = ElementMacroDiagnosticTarget(element: element);
        case macro.TypeAnnotationDiagnosticTarget macroTarget:
          target = _typeAnnotationTarget(application, macroTarget);
        case macro.MetadataAnnotationDiagnosticTarget macroTarget:
          var annotation =
              macroTarget.metadataAnnotation as MetadataAnnotationImpl;
          target = ElementAnnotationMacroDiagnosticTarget(
            element: annotation.element,
            annotationIndex: annotation.annotationIndex,
          );
        case null:
          target = ApplicationMacroDiagnosticTarget(
            annotationIndex: application.annotationIndex,
          );
      }

      return MacroDiagnosticMessage(
        target: target,
        message: message.message,
      );
    }

    for (final diagnostic in result.diagnostics) {
      application.target.element.addMacroDiagnostic(
        MacroDiagnostic(
          severity: diagnostic.severity,
          message: convertMessage(diagnostic.message),
          contextMessages:
              diagnostic.contextMessages.map(convertMessage).toList(),
          correctionMessage: diagnostic.correctionMessage,
        ),
      );
    }

    bool addIntrospectionCycle(macro.MacroException? exception) {
      if (exception is! _MacroIntrospectionCycleException) {
        return false;
      }

      var introspectedElement = application.lastIntrospectedElement;
      if (introspectedElement == null) {
        return false;
      }

      var applications = exception.applications;
      final components = applications.map((application) {
        return DeclarationsIntrospectionCycleComponent(
          element: application.target.element,
          annotationIndex: application.annotationIndex,
          introspectedElement: application.lastIntrospectedElement!,
        );
      }).toList();

      // Report only for this application.
      // Introspections of every cycle component will report it too.
      // Macro implementations can catch and ignore introspection exceptions.
      application.target.element.addMacroDiagnostic(
        DeclarationsIntrospectionCycleDiagnostic(
          annotationIndex: application.annotationIndex,
          introspectedElement: introspectedElement,
          components: components,
        ),
      );
      return true;
    }

    if (result.exception case var exception?) {
      var reported = addIntrospectionCycle(exception);
      if (!reported) {
        application.target.element.addMacroDiagnostic(
          ExceptionMacroDiagnostic(
            annotationIndex: application.annotationIndex,
            message: exception.message,
            stackTrace: exception.stackTrace ?? '<null>',
          ),
        );
      }
    }
  }

  macro.MacroTarget _buildTarget(ast.AstNode node) {
    return declarationBuilder.buildTarget(node);
  }

  /// If [annotation] references a macro, invokes the right callback.
  _AnnotationMacro? _importedMacro({
    required LibraryOrAugmentationElementImpl container,
    required ast.Annotation annotation,
  }) {
    final arguments = annotation.arguments;
    if (arguments == null) {
      return null;
    }

    final String? prefix;
    final String name;
    final String? constructorName;
    final nameNode = annotation.name;
    if (nameNode is ast.SimpleIdentifier) {
      prefix = null;
      name = nameNode.name;
      constructorName = annotation.constructorName?.name;
    } else if (nameNode is ast.PrefixedIdentifier) {
      final importPrefixCandidate = nameNode.prefix.name;
      final hasImportPrefix = container.libraryImports.any(
          (import) => import.prefix?.element.name == importPrefixCandidate);
      if (hasImportPrefix) {
        prefix = importPrefixCandidate;
        name = nameNode.identifier.name;
        constructorName = annotation.constructorName?.name;
      } else {
        prefix = null;
        name = nameNode.prefix.name;
        constructorName = nameNode.identifier.name;
      }
    } else {
      throw StateError('${nameNode.runtimeType} $nameNode');
    }

    for (final import in container.libraryImports) {
      if (import.prefix?.element.name != prefix) {
        continue;
      }

      final importedLibrary = import.importedLibrary;
      if (importedLibrary == null) {
        continue;
      }

      // Skip if a library that is being linked.
      final importedUri = importedLibrary.source.uri;
      if (isLibraryBeingLinked(importedUri)) {
        continue;
      }

      final macroClass = importedLibrary.scope.lookup(name).getter;
      if (macroClass is! ClassElementImpl) {
        continue;
      }

      final macroLibrary = macroClass.library;
      final bundleExecutor = macroLibrary.bundleMacroExecutor;
      if (bundleExecutor == null) {
        continue;
      }

      if (macroClass.isMacro) {
        return _AnnotationMacro(
          macroLibrary: macroLibrary,
          bundleExecutor: bundleExecutor,
          macroClass: macroClass,
          constructorName: constructorName,
          arguments: arguments,
        );
      }
    }
    return null;
  }

  _MacroApplication? _nextForDeclarationsPhase({
    required LibraryBuilder libraryBuilder,
    required Element? targetElement,
  }) {
    final applications = libraryBuilder._applications;
    for (var i = applications.length - 1; i >= 0; i--) {
      final application = applications[i];
      if (targetElement != null) {
        final applicationElement = application.target.element;
        if (!identical(applicationElement, targetElement) &&
            !identical(applicationElement.enclosingElement, targetElement)) {
          continue;
        }
      }
      if (application.phasesToExecute.remove(macro.Phase.declarations)) {
        return application;
      }
    }

    return null;
  }

  _MacroApplication? _nextForDefinitionsPhase({
    required LibraryBuilder libraryBuilder,
  }) {
    final applications = libraryBuilder._applications;
    for (var i = applications.length - 1; i >= 0; i--) {
      final application = applications[i];
      if (application.phasesToExecute.remove(macro.Phase.definitions)) {
        return application;
      }
    }
    return null;
  }

  _MacroApplication? _nextForTypesPhase({
    required LibraryBuilder libraryBuilder,
  }) {
    final applications = libraryBuilder._applications;
    for (var i = applications.length - 1; i >= 0; i--) {
      final application = applications[i];
      if (application.phasesToExecute.remove(macro.Phase.types)) {
        return application;
      }
    }
    return null;
  }

  MacroDiagnosticTarget _typeAnnotationTarget(
    _MacroApplication application,
    macro.TypeAnnotationDiagnosticTarget macroTarget,
  ) {
    switch (macroTarget.typeAnnotation) {
      case TypeAnnotationWithLocation typeAnnotation:
        return TypeAnnotationMacroDiagnosticTarget(
          location: typeAnnotation.location,
        );
    }

    // We don't know anything better.
    return ApplicationMacroDiagnosticTarget(
      annotationIndex: application.annotationIndex,
    );
  }

  static macro.Arguments _buildArguments({
    required int annotationIndex,
    required ConstructorElement constructor,
    required ast.ArgumentList node,
  }) {
    final allParameters = constructor.parameters;
    final namedParameters = allParameters
        .where((e) => e.isNamed)
        .map((e) => MapEntry(e.name, e))
        .mapFromEntries;
    final positionalParameters =
        allParameters.where((e) => e.isPositional).toList();
    var positionalParameterIndex = 0;

    final positional = <macro.Argument>[];
    final named = <String, macro.Argument>{};
    for (var i = 0; i < node.arguments.length; ++i) {
      final ParameterElement? parameter;
      String? namedArgumentName;
      final ast.Expression expressionToEvaluate;
      final argument = node.arguments[i];
      if (argument is ast.NamedExpression) {
        namedArgumentName = argument.name.label.name;
        expressionToEvaluate = argument.expression;
        parameter = namedParameters.remove(namedArgumentName);
      } else {
        expressionToEvaluate = argument;
        parameter = positionalParameters.elementAtOrNull(
          positionalParameterIndex++,
        );
      }

      final contextType = parameter?.type ?? DynamicTypeImpl.instance;
      final evaluation = _ArgumentEvaluation(
        annotationIndex: annotationIndex,
        argumentIndex: i,
      );
      final value = evaluation.evaluate(contextType, expressionToEvaluate);

      if (namedArgumentName != null) {
        named[namedArgumentName] = value;
      } else {
        positional.add(value);
      }
    }
    return macro.Arguments(positional, named);
  }

  /// Run the [body], report [AnalyzerMacroDiagnostic]s to [onDiagnostic].
  static Future<T?> _runWithCatchingExceptions<T>(
    Future<T> Function() body, {
    required MacroTargetElement targetElement,
    required int annotationIndex,
  }) async {
    try {
      return await body();
    } on AnalyzerMacroDiagnostic catch (e) {
      targetElement.addMacroDiagnostic(e);
    } on macro.MacroException catch (e) {
      targetElement.addMacroDiagnostic(
        ExceptionMacroDiagnostic(
          annotationIndex: annotationIndex,
          message: e.message,
          stackTrace: e.stackTrace ?? '<null>',
        ),
      );
    } catch (e, stackTrace) {
      targetElement.addMacroDiagnostic(
        ExceptionMacroDiagnostic(
          annotationIndex: annotationIndex,
          message: '$e',
          stackTrace: '$stackTrace',
        ),
      );
    }
    return null;
  }
}

/// This mixin is added to [LibraryBuilder] to make it a container with
/// macro applications, but at the same time don't expose internals of
/// [_MacroApplication].
mixin MacroApplicationsContainer {
  /// The reversed queue of macro applications to apply.
  ///
  /// We add classes before methods, and methods in the reverse order,
  /// classes in the reverse order, annotations in the direct order.
  ///
  /// We iterate from the end looking for the next application to apply.
  /// This way we ensure two ordering rules:
  /// 1. inner before outer
  /// 2. right to left
  /// 3. source order
  final List<_MacroApplication> _applications = [];
}

class _AnnotationMacro {
  final LibraryElementImpl macroLibrary;
  final BundleMacroExecutor bundleExecutor;
  final ClassElementImpl macroClass;
  final String? constructorName;
  final ast.ArgumentList arguments;

  _AnnotationMacro({
    required this.macroLibrary,
    required this.bundleExecutor,
    required this.macroClass,
    required this.constructorName,
    required this.arguments,
  });

  ConstructorElement? get constructorElement {
    return macroClass.getNamedConstructor(constructorName ?? '');
  }
}

/// Helper class for evaluating arguments for a single constructor based
/// macro application.
class _ArgumentEvaluation {
  final int annotationIndex;
  final int argumentIndex;

  _ArgumentEvaluation({
    required this.annotationIndex,
    required this.argumentIndex,
  });

  macro.Argument evaluate(DartType contextType, ast.Expression node) {
    if (node is ast.AdjacentStrings) {
      return macro.StringArgument(node.strings
          .map((e) => evaluate(contextType, e))
          .map((arg) => arg.value)
          .join());
    } else if (node is ast.BooleanLiteral) {
      return macro.BoolArgument(node.value);
    } else if (node is ast.DoubleLiteral) {
      return macro.DoubleArgument(node.value);
    } else if (node is ast.IntegerLiteral) {
      return macro.IntArgument(node.value!);
    } else if (node is ast.ListLiteral) {
      return _listLiteral(contextType, node);
    } else if (node is ast.NullLiteral) {
      return macro.NullArgument();
    } else if (node is ast.PrefixExpression &&
        node.operator.type == TokenType.MINUS) {
      final operandValue = evaluate(contextType, node.operand);
      if (operandValue is macro.DoubleArgument) {
        return macro.DoubleArgument(-operandValue.value);
      } else if (operandValue is macro.IntArgument) {
        return macro.IntArgument(-operandValue.value);
      }
    } else if (node is ast.SetOrMapLiteral) {
      return _setOrMapLiteral(contextType, node);
    } else if (node is ast.SimpleStringLiteral) {
      return macro.StringArgument(node.value);
    }
    _throwError(node, 'Not supported: ${node.runtimeType}');
  }

  macro.ListArgument _listLiteral(
    DartType contextType,
    ast.ListLiteral node,
  ) {
    final DartType elementType;
    switch (contextType) {
      case InterfaceType(isDartCoreList: true):
        elementType = contextType.typeArguments[0];
      default:
        _throwError(node, 'Expected context type List');
    }

    final typeArguments = _argumentKindsOfType(
      contextType,
      includeTop: false,
    );

    return macro.ListArgument(
      node.elements
          .cast<ast.Expression>()
          .map((e) => evaluate(elementType, e))
          .toList(),
      typeArguments,
    );
  }

  macro.Argument _setOrMapLiteral(
    DartType contextType,
    ast.SetOrMapLiteral node,
  ) {
    final typeArguments = _argumentKindsOfType(
      contextType,
      includeTop: false,
    );

    switch (contextType) {
      case InterfaceType(isDartCoreMap: true):
        final keyType = contextType.typeArguments[0];
        final valueType = contextType.typeArguments[1];
        final result = <macro.Argument, macro.Argument>{};
        for (final element in node.elements) {
          if (element is! ast.MapLiteralEntry) {
            _throwError(element, 'MapLiteralEntry expected');
          }
          final key = evaluate(keyType, element.key);
          final value = evaluate(valueType, element.value);
          result[key] = value;
        }
        return macro.MapArgument(result, typeArguments);
      case InterfaceType(isDartCoreSet: true):
        final elementType = contextType.typeArguments[0];
        final result = <macro.Argument>[];
        for (final element in node.elements) {
          if (element is! ast.Expression) {
            _throwError(element, 'Expression expected');
          }
          final value = evaluate(elementType, element);
          result.add(value);
        }
        return macro.SetArgument(result, typeArguments);
      default:
        _throwError(node, 'Expected context type Map or Set');
    }
  }

  Never _throwError(ast.AstNode node, String message) {
    throw ArgumentMacroDiagnostic(
      annotationIndex: annotationIndex,
      argumentIndex: argumentIndex,
      message: message,
    );
  }
}

class _DeclarationPhaseIntrospector extends _TypePhaseIntrospector
    implements macro.DeclarationPhaseIntrospector {
  final LibraryMacroApplier applier;
  final TypeSystemImpl typeSystem;

  _DeclarationPhaseIntrospector(
    super.elementFactory,
    super.declarationBuilder,
    super.performance,
    this.applier,
    this.typeSystem,
  );

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
    covariant macro.TypeDeclaration type,
  ) async {
    performance.getDataInt('constructorsOf').increment();

    final element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    if (element case InterfaceElement(:final augmented?)) {
      return augmented.constructors
          .map((e) => e.declaration as ConstructorElementImpl)
          .map(declarationBuilder.declarationOfElement)
          .whereType<macro.ConstructorDeclaration>()
          .toList();
    }
    return [];
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(
    macro.TypeDeclaration type,
  ) async {
    if (LibraryMacroApplier.testThrowExceptionIntrospection) {
      throw 'Intentional exception';
    }

    final element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    if (element case InstanceElement(:final augmented?)) {
      return augmented.fields
          .whereNot((e) => e.isSynthetic)
          .map((e) => e.declaration as FieldElementImpl)
          .map(declarationBuilder.declarationOfElement)
          .whereType<macro.FieldDeclaration>()
          .toList();
    }
    // TODO(scheglov): can we test this?
    throw StateError('Unexpected: ${type.runtimeType}');
  }

  @override
  Future<List<macro.MethodDeclaration>> methodsOf(
    macro.TypeDeclaration type,
  ) async {
    performance.getDataInt('methodsOf').increment();

    final element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    if (element case InstanceElement(:final augmented?)) {
      return [
        ...augmented.accessors.whereNot((e) => e.isSynthetic),
        ...augmented.methods,
      ]
          .map((e) => e.declaration as ExecutableElementImpl)
          .map(declarationBuilder.declarationOfElement)
          .whereType<macro.MethodDeclaration>()
          .toList();
    }
    // TODO(scheglov): can we test this?
    throw StateError('Unexpected: ${type.runtimeType}');
  }

  @override
  Future<macro.StaticType> resolve(macro.TypeAnnotationCode typeCode) async {
    performance.getDataInt('resolve').increment();
    final type = declarationBuilder.resolveType(typeCode);
    return _StaticTypeImpl(typeSystem, type);
  }

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(
    macro.Identifier identifier,
  ) async {
    performance.getDataInt('typeDeclarationOf').increment();
    return declarationBuilder.typeDeclarationOf(identifier);
  }

  @override
  Future<List<macro.TypeDeclaration>> typesOf(
    covariant LibraryImplFromElement library,
  ) async {
    return library.element.topLevelElements
        .map((e) => declarationBuilder.declarationOfElement(e))
        .whereType<macro.TypeDeclaration>()
        .toList();
  }

  @override
  Future<List<macro.EnumValueDeclaration>> valuesOf(
    covariant macro.EnumDeclaration type,
  ) async {
    final element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    element as EnumElementImpl;
    // TODO(scheglov): use augmented
    return element.constants
        .map(declarationBuilder.declarationOfElement)
        .whereType<macro.EnumValueDeclaration>()
        .toList();
  }

  Future<void> _runDeclarationsPhase(ElementImpl element) async {
    // Don't run for the current element.
    final current = applier._declarationsPhaseRunning.lastOrNull;
    if (current?.target.element == element) {
      return;
    }

    current?.lastIntrospectedElement = element;
    await applier.runDeclarationsPhase(
      targetElement: element,
      performance: performance,
    );

    // We might have detected a cycle for this target element.
    // Either just now, or before.
    var exception = applier._elementToIntrospectionCycleException[element];
    if (exception != null) {
      throw exception;
    }
  }
}

class _DefinitionPhaseIntrospector extends _DeclarationPhaseIntrospector
    implements macro.DefinitionPhaseIntrospector {
  _DefinitionPhaseIntrospector(
    super.elementFactory,
    super.declarationBuilder,
    super.performance,
    super.applier,
    super.typeSystem,
  );

  @override
  Future<macro.Declaration> declarationOf(
    covariant macro.Identifier identifier,
  ) async {
    return declarationBuilder.declarationOf(identifier);
  }

  @override
  Future<macro.TypeAnnotation> inferType(
    covariant macro.OmittedTypeAnnotation omittedType,
  ) async {
    return declarationBuilder.inferOmittedType(omittedType);
  }

  @override
  Future<List<macro.Declaration>> topLevelDeclarationsOf(
    covariant LibraryImplFromElement library,
  ) async {
    return library.element.topLevelElements
        .whereNot((e) => e.isSynthetic)
        .map((e) => declarationBuilder.declarationOfElement(e))
        .whereType<macro.Declaration>()
        .toList();
  }
}

class _MacroApplication {
  final _MacroTarget target;
  final int annotationIndex;
  final ast.Annotation annotationNode;
  final macro.MacroInstanceIdentifier instance;
  final Set<macro.Phase> phasesToExecute;
  ElementImpl? lastIntrospectedElement;

  _MacroApplication({
    required this.target,
    required this.annotationIndex,
    required this.annotationNode,
    required this.instance,
    required this.phasesToExecute,
  });

  bool get hasDeclarationsPhase {
    return phasesToExecute.contains(macro.Phase.declarations);
  }

  void removeDeclarationsPhase() {
    phasesToExecute.remove(macro.Phase.declarations);
  }
}

final class _MacroIntrospectionCycleException
    extends macro.MacroIntrospectionCycleExceptionImpl {
  final List<_MacroApplication> applications;

  _MacroIntrospectionCycleException(
    super.message, {
    required this.applications,
  });
}

class _MacroTarget {
  final LibraryBuilder library;
  final ast.AstNode node;
  final MacroTargetElement element;

  _MacroTarget({
    required this.library,
    required this.node,
    required this.element,
  });
}

class _StaticTypeImpl implements macro.StaticType {
  final TypeSystemImpl typeSystem;
  final DartType type;

  _StaticTypeImpl(this.typeSystem, this.type);

  @override
  Future<bool> isExactly(_StaticTypeImpl other) {
    final result = type == other.type;
    return Future.value(result);
  }

  @override
  Future<bool> isSubtypeOf(_StaticTypeImpl other) {
    final result = typeSystem.isSubtypeOf(type, other.type);
    return Future.value(result);
  }
}

class _TypePhaseIntrospector implements macro.TypePhaseIntrospector {
  final LinkedElementFactory elementFactory;
  final DeclarationBuilder declarationBuilder;
  final OperationPerformanceImpl performance;

  _TypePhaseIntrospector(
    this.elementFactory,
    this.declarationBuilder,
    this.performance,
  );

  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) async {
    final libraryElement = elementFactory.libraryOfUri2(library);
    final lookup = libraryElement.scope.lookup(name);
    var element = lookup.getter ?? lookup.setter;
    if (element is PropertyAccessorElement && element.isSynthetic) {
      element = element.variable2;
    }
    if (element == null) {
      throw macro.MacroImplementationExceptionImpl(
        [
          'Unresolved identifier.',
          'library: $library',
          'name: $name',
        ].join('\n'),
        stackTrace: StackTrace.current.toString(),
      );
    }
    return declarationBuilder.fromElement.identifier(element);
  }
}

extension on macro.MacroExecutionResult {
  bool get isNotEmpty =>
      enumValueAugmentations.isNotEmpty ||
      interfaceAugmentations.isNotEmpty ||
      libraryAugmentations.isNotEmpty ||
      mixinAugmentations.isNotEmpty ||
      typeAugmentations.isNotEmpty;
}
