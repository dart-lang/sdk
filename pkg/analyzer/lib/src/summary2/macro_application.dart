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
import 'package:analyzer/src/summary2/macro_injected_impl.dart' as injected;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart' as macro;
import 'package:macros/src/executor.dart' as macro;
import 'package:macros/src/executor/exception_impls.dart' as macro;
import 'package:macros/src/executor/introspection_impls.dart' as macro;
import 'package:macros/src/executor/multi_executor.dart';
import 'package:macros/src/executor/remote_instance.dart' as macro;
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
      for (var typeArgument in type.typeArguments)
        ..._argumentKindsOfType(typeArgument),
    ]
  ];
}

class ApplicationResult {
  final _MacroApplication application;
  final List<macro.MacroExecutionResult> results;

  ApplicationResult(this.application, this.results);

  MacroTargetElement get targetElement {
    return application.target.element;
  }
}

// TODO(scheglov): The name is deceptive, this is not for a single library.
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

  /// The applications that currently run.
  ///
  /// There can be more than one, because during the declarations phase we
  /// can start introspecting another declaration, which runs the declarations
  /// phase for that another declaration.
  final List<_MacroApplication> _runningApplications = [];

  /// The map from a declaration that has declarations phase introspection
  /// cycle, to the cycle exception.
  final Map<MacroTargetElement, _MacroIntrospectionCycleException>
      _elementToIntrospectionCycleException = {};

  late final macro.TypePhaseIntrospector _typesPhaseIntrospector =
      _TypePhaseIntrospector(
    this,
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

  /// The currently running macro application.
  _MacroApplication? get currentApplication {
    return _runningApplications.lastOrNull;
  }

  Future<void> add({
    required LibraryBuilder libraryBuilder,
    required CompilationUnitElementImpl container,
    required ast.CompilationUnitImpl unit,
  }) async {
    for (var directive in unit.directives.reversed) {
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

    for (var declaration in unit.declarations.reversed) {
      switch (declaration) {
        case ast.ClassDeclarationImpl():
          var element = declaration.declaredElement!;
          var declarationElement = element.augmented.declaration;
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
          var element = declaration.declaredElement!;
          var declarationElement = element.augmented.declaration;
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
          var element = declaration.declaredElement!;
          var declarationElement = element.augmented.declaration;
          await _addClassLike(
            libraryBuilder: libraryBuilder,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.enumType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
          for (var constant in declaration.constants.reversed) {
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
          var element = declaration.declaredElement!;
          var declarationElement = element.augmented.declaration;
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
          var element = declaration.declaredElement!;
          var declarationElement = element.augmented.declaration;
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
          var element = declaration.declaredElement!;
          var declarationElement = element.augmented.declaration;
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
          var variables = declaration.variables.variables;
          for (var variable in variables.reversed) {
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

  void disposeMacroApplications({
    required LibraryBuilder libraryBuilder,
  }) {
    for (var application in libraryBuilder._applications) {
      var instance = application.instance;
      if (instance is macro.MacroInstanceIdentifier) {
        macroExecutor.disposeMacro(instance);
      }
    }
  }

  Future<ApplicationResult?> executeDeclarationsPhase({
    required LibraryBuilder libraryBuilder,
    required ElementImpl? targetElement,
    required OperationPerformanceImpl performance,
  }) async {
    if (targetElement != null) {
      for (var i = 0; i < _runningApplications.length; i++) {
        var running = _runningApplications[i];
        if (running.target.element == targetElement) {
          var applications = _runningApplications.sublist(i);
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

    var application = _nextForDeclarationsPhase(
      libraryBuilder: libraryBuilder,
      targetElement: targetElement,
    );
    if (application == null) {
      return null;
    }

    _runningApplications.add(application);
    var results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        var target = _buildTarget(application.target.node);

        var introspector = _DeclarationPhaseIntrospector(
          this,
          elementFactory,
          declarationBuilder,
          performance,
          libraryBuilder.element.typeSystem,
        );

        var instance = application.instance;
        macro.MacroExecutionResult result;
        if (instance is macro.MacroInstanceIdentifier) {
          result = await macroExecutor.executeDeclarationsPhase(
            instance,
            target,
            introspector,
          );
        } else if (instance is injected.RunningMacro) {
          result = await instance.executeDeclarationsPhase(
            target,
            introspector,
          );
        } else {
          throw UnimplementedError('$instance');
        }

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

    _runningApplications.removeLast();
    return ApplicationResult(application, results);
  }

  Future<ApplicationResult?> executeDefinitionsPhase({
    required LibraryBuilder libraryBuilder,
    required OperationPerformanceImpl performance,
  }) async {
    var application = _nextForDefinitionsPhase(
      libraryBuilder: libraryBuilder,
    );
    if (application == null) {
      return null;
    }

    _runningApplications.add(application);
    var results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        var target = _buildTarget(application.target.node);

        var introspector = _DefinitionPhaseIntrospector(
          this,
          elementFactory,
          declarationBuilder,
          performance,
          application.target.library.element.typeSystem,
        );

        macro.MacroExecutionResult result;
        var instance = application.instance;
        if (instance is macro.MacroInstanceIdentifier) {
          result = await macroExecutor.executeDefinitionsPhase(
            instance,
            target,
            introspector,
          );
        } else if (instance is injected.RunningMacro) {
          result = await instance.executeDefinitionsPhase(
            target,
            introspector,
          );
        } else {
          throw UnimplementedError('$instance');
        }

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

    _runningApplications.removeLast();
    return ApplicationResult(application, results);
  }

  Future<ApplicationResult?> executeTypesPhase({
    required LibraryBuilder libraryBuilder,
  }) async {
    var application = _nextForTypesPhase(
      libraryBuilder: libraryBuilder,
    );
    if (application == null) {
      return null;
    }

    _runningApplications.add(application);
    var results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        var target = _buildTarget(application.target.node);

        macro.MacroExecutionResult result;
        var instance = application.instance;

        if (instance is macro.MacroInstanceIdentifier) {
          result = await macroExecutor.executeTypesPhase(
            instance,
            target,
            _typesPhaseIntrospector,
          );
        } else if (instance is injected.RunningMacro) {
          result = await instance.executeTypesPhase(
            target,
            _typesPhaseIntrospector,
          );
        } else {
          throw UnimplementedError('$instance');
        }

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

    _runningApplications.removeLast();
    return ApplicationResult(application, results);
  }

  Future<void> _addAnnotations({
    required LibraryBuilder libraryBuilder,
    required CompilationUnitElementImpl container,
    required ast.AstNode targetNode,
    required Element? targetNodeElement,
    required macro.DeclarationKind targetDeclarationKind,
    required List<ast.Annotation> annotations,
  }) async {
    if (targetNode is ast.FieldDeclaration) {
      for (var field in targetNode.fields.variables) {
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

    var targetElement = targetNodeElement.ifTypeOrNull<MacroTargetElement>();
    if (targetElement == null) {
      return;
    }

    var macroTarget = _MacroTarget(
      library: libraryBuilder,
      node: targetNode,
      element: targetElement,
    );

    if (injected.macroImplementation == null) {
      await _addAnnotationsDefault(
        libraryBuilder: libraryBuilder,
        container: container,
        annotations: annotations,
        macroTarget: macroTarget,
        targetDeclarationKind: targetDeclarationKind,
      );
    } else {
      await _addAnnotationsInjected(
        libraryBuilder: libraryBuilder,
        container: container,
        annotations: annotations,
        macroTarget: macroTarget,
        targetDeclarationKind: targetDeclarationKind,
      );
    }
  }

  Future<void> _addAnnotationsDefault({
    required LibraryBuilder libraryBuilder,
    required CompilationUnitElementImpl container,
    required List<ast.Annotation> annotations,
    required _MacroTarget macroTarget,
    required macro.DeclarationKind targetDeclarationKind,
  }) async {
    for (var (annotationIndex, annotation) in annotations.indexed) {
      var importedMacro = _importedMacro(
        container: container,
        annotation: annotation,
      );
      if (importedMacro == null) {
        continue;
      }

      var constructorElement = importedMacro.constructorElement;
      if (constructorElement == null) {
        continue;
      }

      var instance = await _runWithCatchingExceptions(
        () async {
          var arguments = _buildArguments(
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
        targetElement: macroTarget.element,
        annotationIndex: annotationIndex,
      );
      if (instance == null) {
        continue;
      }

      var phasesToExecute = macro.Phase.values.where((phase) {
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

      var application = _MacroApplication(
        target: macroTarget,
        annotationIndex: annotationIndex,
        annotationNode: annotation,
        instance: instance,
        phasesToExecute: phasesToExecute,
      );

      libraryBuilder._applications.add(application);
    }
  }

  Future<void> _addAnnotationsInjected({
    required LibraryBuilder libraryBuilder,
    required CompilationUnitElementImpl container,
    required List<ast.Annotation> annotations,
    required _MacroTarget macroTarget,
    required macro.DeclarationKind targetDeclarationKind,
  }) async {
    var macroPackageConfigs = injected.macroImplementation!.packageConfigs;
    for (var (annotationIndex, annotation) in annotations.indexed) {
      var macroClassAndConstructorName = _lookupMacroClassAndConstructorName(
        container: container,
        annotation: annotation,
      );
      if (macroClassAndConstructorName == null) continue;
      var macroUri = macroClassAndConstructorName.$1.librarySource.uri;
      var macroName = annotation.name.name;
      if (!macroPackageConfigs.isMacro(
          macroClassAndConstructorName.$1.librarySource.uri,
          annotation.name.name)) {
        continue;
      }

      var instance =
          injected.macroImplementation!.runner.run(macroUri, macroName);
      var application = _MacroApplication(
        target: macroTarget,
        annotationIndex: annotationIndex,
        annotationNode: annotation,
        instance: instance,
        phasesToExecute: {
          macro.Phase.types,
          macro.Phase.declarations,
          macro.Phase.definitions
        },
      );

      libraryBuilder._applications.add(application);
    }
  }

  Future<void> _addClassLike({
    required LibraryBuilder libraryBuilder,
    required CompilationUnitElementImpl container,
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

    for (var member in members.reversed) {
      var memberDeclarationKind = switch (member) {
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
          var element = (macroTarget.declaration as HasElement).element;
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

    for (var diagnostic in result.diagnostics) {
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
      var components = applications.map((application) {
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
    required CompilationUnitElementImpl container,
    required ast.Annotation annotation,
  }) {
    var arguments = annotation.arguments;
    if (arguments == null) {
      return null;
    }

    var macroClassAndConstructorName = _lookupMacroClassAndConstructorName(
      container: container,
      annotation: annotation,
    );
    if (macroClassAndConstructorName == null) return null;
    var macroClass = macroClassAndConstructorName.$1;
    var macroLibrary = macroClass.library;
    var bundleExecutor = macroLibrary.bundleMacroExecutor;
    if (bundleExecutor == null) {
      return null;
    }

    if (!macroClass.isMacro) return null;

    return _AnnotationMacro(
      macroLibrary: macroLibrary,
      bundleExecutor: bundleExecutor,
      macroClass: macroClass,
      constructorName: macroClassAndConstructorName.$2,
      arguments: arguments,
    );
  }

  (ClassElementImpl, String?)? _lookupMacroClassAndConstructorName({
    required CompilationUnitElementImpl container,
    required ast.Annotation annotation,
  }) {
    String? prefix;
    String name;
    String? constructorName;
    var nameNode = annotation.name;
    if (nameNode is ast.SimpleIdentifier) {
      prefix = null;
      name = nameNode.name;
      constructorName = annotation.constructorName?.name;
    } else if (nameNode is ast.PrefixedIdentifier) {
      var importPrefixCandidate = nameNode.prefix.name;
      var hasImportPrefix = container.libraryImports.any(
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

    for (var import in container.libraryImports) {
      if (import.prefix?.element.name != prefix) {
        continue;
      }

      var importedLibrary = import.importedLibrary;
      if (importedLibrary == null) {
        continue;
      }

      // Skip if a library that is being linked.
      var importedUri = importedLibrary.source.uri;
      if (isLibraryBeingLinked(importedUri)) {
        continue;
      }

      var macroClass = importedLibrary.exportNamespace.get(name);
      if (macroClass is ClassElementImpl) {
        return (macroClass, constructorName);
      }
    }
    return null;
  }

  _MacroApplication<Object>? _nextForDeclarationsPhase({
    required LibraryBuilder libraryBuilder,
    required Element? targetElement,
  }) {
    var applications = libraryBuilder._applications;
    for (var i = applications.length - 1; i >= 0; i--) {
      var application = applications[i];
      if (targetElement != null) {
        var applicationElement = application.target.element;
        if (!identical(applicationElement, targetElement) &&
            !identical(applicationElement.enclosingElement3, targetElement)) {
          continue;
        }
      }
      if (application.phasesToExecute.remove(macro.Phase.declarations)) {
        return application;
      }
    }

    return null;
  }

  _MacroApplication<Object>? _nextForDefinitionsPhase({
    required LibraryBuilder libraryBuilder,
  }) {
    var applications = libraryBuilder._applications;
    for (var i = applications.length - 1; i >= 0; i--) {
      var application = applications[i];
      if (application.phasesToExecute.remove(macro.Phase.definitions)) {
        return application;
      }
    }
    return null;
  }

  _MacroApplication<Object>? _nextForTypesPhase({
    required LibraryBuilder libraryBuilder,
  }) {
    var applications = libraryBuilder._applications;
    for (var i = applications.length - 1; i >= 0; i--) {
      var application = applications[i];
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
    var allParameters = constructor.parameters;
    var namedParameters = allParameters
        .where((e) => e.isNamed)
        .map((e) => MapEntry(e.name, e))
        .mapFromEntries;
    var positionalParameters =
        allParameters.where((e) => e.isPositional).toList();
    var positionalParameterIndex = 0;

    var positional = <macro.Argument>[];
    var named = <String, macro.Argument>{};
    for (var i = 0; i < node.arguments.length; ++i) {
      ParameterElement? parameter;
      String? namedArgumentName;
      ast.Expression expressionToEvaluate;
      var argument = node.arguments[i];
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

      var contextType = parameter?.type ?? DynamicTypeImpl.instance;
      var evaluation = _ArgumentEvaluation(
        annotationIndex: annotationIndex,
        argumentIndex: i,
      );
      var value = evaluation.evaluate(contextType, expressionToEvaluate);

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
  final List<_MacroApplication<Object>> _applications = [];
}

/// Facts about applying macros in a library.
class MacroProcessing {
  bool hasAnyIntrospection = false;
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
      var operandValue = evaluate(contextType, node.operand);
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
    DartType elementType;
    switch (contextType) {
      case InterfaceType(isDartCoreList: true):
        elementType = contextType.typeArguments[0];
      default:
        _throwError(node, 'Expected context type List');
    }

    var typeArguments = _argumentKindsOfType(
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
    var typeArguments = _argumentKindsOfType(
      contextType,
      includeTop: false,
    );

    switch (contextType) {
      case InterfaceType(isDartCoreMap: true):
        var keyType = contextType.typeArguments[0];
        var valueType = contextType.typeArguments[1];
        var result = <macro.Argument, macro.Argument>{};
        for (var element in node.elements) {
          if (element is! ast.MapLiteralEntry) {
            _throwError(element, 'MapLiteralEntry expected');
          }
          var key = evaluate(keyType, element.key);
          var value = evaluate(valueType, element.value);
          result[key] = value;
        }
        return macro.MapArgument(result, typeArguments);
      case InterfaceType(isDartCoreSet: true):
        var elementType = contextType.typeArguments[0];
        var result = <macro.Argument>[];
        for (var element in node.elements) {
          if (element is! ast.Expression) {
            _throwError(element, 'Expression expected');
          }
          var value = evaluate(elementType, element);
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
  final TypeSystemImpl typeSystem;

  _DeclarationPhaseIntrospector(
    super.applier,
    super.elementFactory,
    super.declarationBuilder,
    super.performance,
    this.typeSystem,
  );

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
    covariant macro.TypeDeclaration type,
  ) async {
    performance.getDataInt('constructorsOf').increment();

    var element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    macroProcessing?.hasAnyIntrospection = true;
    if (element case InterfaceElement(:var augmented)) {
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

    var element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    macroProcessing?.hasAnyIntrospection = true;
    if (element case InstanceElement(:var augmented)) {
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

    var element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    macroProcessing?.hasAnyIntrospection = true;
    if (element case InstanceElement(:var augmented)) {
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
    macroProcessing?.hasAnyIntrospection = true;
    var type = declarationBuilder.resolveType(typeCode);
    return _dartTypeToStaticType(type);
  }

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(
    macro.Identifier identifier,
  ) async {
    performance.getDataInt('typeDeclarationOf').increment();
    macroProcessing?.hasAnyIntrospection = true;
    return declarationBuilder.typeDeclarationOf(identifier);
  }

  @override
  Future<List<macro.TypeDeclaration>> typesOf(
    covariant LibraryImplFromElement library,
  ) async {
    macroProcessing?.hasAnyIntrospection = true;
    return library.element.topLevelElements
        .map((e) => declarationBuilder.declarationOfElement(e))
        .whereType<macro.TypeDeclaration>()
        .toList();
  }

  @override
  Future<List<macro.EnumValueDeclaration>> valuesOf(
    covariant macro.EnumDeclaration type,
  ) async {
    var element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    element as EnumElementImpl;
    macroProcessing?.hasAnyIntrospection = true;

    // TODO(scheglov): use augmented
    return element.constants
        .map(declarationBuilder.declarationOfElement)
        .whereType<macro.EnumValueDeclaration>()
        .toList();
  }

  macro.StaticTypeImpl _dartTypeToStaticType(DartType type) {
    if (type is InterfaceType) {
      var element = type.element;
      var declaration = declarationBuilder.declarationOfElement(element);

      return _InterfaceTypeImpl(
        macro.RemoteInstance.uniqueId,
        typeSystem: typeSystem,
        introspector: this,
        type: type,
        declaration: declaration as macro.ParameterizedTypeDeclarationImpl,
        typeArguments: [
          for (final type in type.typeArguments) _dartTypeToStaticType(type),
        ],
      );
    } else {
      return _StaticTypeImpl(
        macro.RemoteInstance.uniqueId,
        typeSystem: typeSystem,
        introspector: this,
        type: type,
      );
    }
  }

  Future<void> _runDeclarationsPhase(ElementImpl element) async {
    // Don't run for the current element.
    var current = applier._runningApplications.lastOrNull;
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
    super.applier,
    super.elementFactory,
    super.declarationBuilder,
    super.performance,
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
    macroProcessing?.hasAnyIntrospection = true;
    return library.element.topLevelElements
        .whereNot((e) => e.isSynthetic)
        .map((e) => declarationBuilder.declarationOfElement(e))
        .whereType<macro.Declaration>()
        .toList();
  }
}

class _InterfaceTypeImpl extends _StaticTypeImpl
    implements macro.NamedStaticTypeImpl {
  @override
  final macro.ParameterizedTypeDeclarationImpl declaration;

  @override
  final List<macro.StaticTypeImpl> typeArguments;

  _InterfaceTypeImpl(
    super.id, {
    required super.typeSystem,
    required super.introspector,
    required InterfaceType super.type,
    required this.declaration,
    required this.typeArguments,
  });
}

class _MacroApplication<I> {
  final _MacroTarget target;
  final int annotationIndex;
  final ast.Annotation annotationNode;
  final I instance;
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

class _StaticTypeImpl extends macro.StaticTypeImpl {
  final TypeSystemImpl typeSystem;
  final _DeclarationPhaseIntrospector introspector;
  final DartType type;

  _StaticTypeImpl(
    super.id, {
    required this.typeSystem,
    required this.introspector,
    required this.type,
  });

  @override
  Future<macro.NamedStaticType?> asInstanceOf(
      macro.TypeDeclaration declaration) {
    InterfaceType? result;

    if (declaration case HasElement(:var element)) {
      if (element is InterfaceElementImpl) {
        result = type.asInstanceOf(element);
      }
    }

    return Future.value(switch (result) {
      var type? =>
        introspector._dartTypeToStaticType(type) as _InterfaceTypeImpl,
      _ => null,
    });
  }

  @override
  Future<bool> isExactly(_StaticTypeImpl other) {
    var result = type == other.type;
    return Future.value(result);
  }

  @override
  Future<bool> isSubtypeOf(_StaticTypeImpl other) {
    var result = typeSystem.isSubtypeOf(type, other.type);
    return Future.value(result);
  }
}

class _TypePhaseIntrospector implements macro.TypePhaseIntrospector {
  final LibraryMacroApplier applier;
  final LinkedElementFactory elementFactory;
  final DeclarationBuilder declarationBuilder;
  final OperationPerformanceImpl performance;

  _TypePhaseIntrospector(
    this.applier,
    this.elementFactory,
    this.declarationBuilder,
    this.performance,
  );

  MacroProcessing? get macroProcessing {
    return applier.currentApplication?.target.library.macroProcessing;
  }

  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) async {
    var libraryElement = elementFactory.libraryOfUri2(library);
    macroProcessing?.hasAnyIntrospection = true;

    var element = libraryElement.exportNamespace.get(name);
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
      extendsTypeAugmentations.isNotEmpty ||
      interfaceAugmentations.isNotEmpty ||
      libraryAugmentations.isNotEmpty ||
      mixinAugmentations.isNotEmpty ||
      typeAugmentations.isNotEmpty;
}
