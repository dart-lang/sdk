// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart' as macro;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/macro_declarations.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';

/// The full list of [macro.ArgumentKind]s for this dart type (includes the type
/// itself as well as type arguments, in source order with
/// [macro.ArgumentKind.nullable] modifiers preceding the nullable types).
List<macro.ArgumentKind> _dartTypeArgumentKinds(DartType dartType) => [
      if (dartType.nullabilitySuffix == NullabilitySuffix.question)
        macro.ArgumentKind.nullable,
      switch (dartType) {
        DartType(isDartCoreBool: true) => macro.ArgumentKind.bool,
        DartType(isDartCoreDouble: true) => macro.ArgumentKind.double,
        DartType(isDartCoreInt: true) => macro.ArgumentKind.int,
        DartType(isDartCoreNum: true) => macro.ArgumentKind.num,
        DartType(isDartCoreNull: true) => macro.ArgumentKind.nil,
        DartType(isDartCoreObject: true) => macro.ArgumentKind.object,
        DartType(isDartCoreString: true) => macro.ArgumentKind.string,
        // TODO(jakemac): Support nested type arguments for collections.
        DartType(isDartCoreList: true) => macro.ArgumentKind.list,
        DartType(isDartCoreMap: true) => macro.ArgumentKind.map,
        DartType(isDartCoreSet: true) => macro.ArgumentKind.set,
        DynamicType() => macro.ArgumentKind.dynamic,
        // TODO(jakemac): Support type annotations and code objects
        _ =>
          throw UnsupportedError('Unsupported macro type argument $dartType'),
      },
      if (dartType is ParameterizedType) ...[
        for (var type in dartType.typeArguments)
          ..._dartTypeArgumentKinds(type),
      ]
    ];

List<macro.ArgumentKind> _typeArgumentsForNode(ast.TypedLiteral node) {
  if (node.typeArguments == null) {
    return [
      // TODO(jakemac): Use downward inference to build these types and detect maps
      // versus sets.
      if (node is ast.ListLiteral || node is ast.SetOrMapLiteral)
        macro.ArgumentKind.dynamic,
      if (node is ast.SetOrMapLiteral &&
          node.elements.first is ast.MapLiteralEntry)
        macro.ArgumentKind.dynamic,
    ];
  }
  return [
    for (var type in node.typeArguments!.arguments.map((arg) => arg.type!))
      ..._dartTypeArgumentKinds(type),
  ];
}

class LibraryMacroApplier {
  final LinkedElementFactory elementFactory;
  final MultiMacroExecutor macroExecutor;
  final bool Function(Uri) isLibraryBeingLinked;
  final DeclarationBuilder declarationBuilder;

  /// The callback to run declarations phase if the type.
  /// We do it out-of-order when the type is introspected.
  final Future<void> Function({required Element? targetElement})
      runDeclarationsPhase;

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

  /// The applications that currently run the declarations phase.
  final List<_MacroApplication> _declarationsPhaseRunning = [];

  /// The identifier of the next cycle error.
  int _declarationsPhaseCycleIndex = 0;

  /// Information about a found declarations phase introspection cycle.
  /// We use it when receive diagnostics from the macro executor to report
  /// a more specific diagnostic than the exception.
  final Map<String, List<_MacroApplication>>
      _declarationsPhaseCycleApplications = {};

  late final macro.TypePhaseIntrospector _typesPhaseIntrospector =
      _TypePhaseIntrospector(elementFactory, declarationBuilder);

  LibraryMacroApplier({
    required this.elementFactory,
    required this.macroExecutor,
    required this.isLibraryBeingLinked,
    required this.declarationBuilder,
    required this.runDeclarationsPhase,
  });

  Future<void> add({
    required LibraryElementImpl libraryElement,
    required LibraryOrAugmentationElementImpl container,
    required ast.CompilationUnitImpl unit,
  }) async {
    for (final declaration in unit.declarations.reversed) {
      switch (declaration) {
        case ast.ClassDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryElement: libraryElement,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.classType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
        case ast.ClassTypeAliasImpl():
          // TODO(scheglov): implement it
          break;
        case ast.EnumDeclarationImpl():
          // TODO(scheglov): implement it
          break;
        case ast.ExtensionDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryElement: libraryElement,
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
            libraryElement: libraryElement,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.extensionType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
        case ast.FunctionDeclarationImpl():
          await _addAnnotations(
            libraryElement: libraryElement,
            container: container,
            targetNode: declaration,
            targetDeclarationKind: macro.DeclarationKind.function,
            annotations: declaration.metadata,
          );
        case ast.FunctionTypeAliasImpl():
          // TODO(scheglov): implement it
          break;
        case ast.GenericTypeAliasImpl():
          // TODO(scheglov): implement it
          break;
        case ast.MixinDeclarationImpl():
          final element = declaration.declaredElement!;
          final declarationElement = element.augmented?.declaration ?? element;
          await _addClassLike(
            libraryElement: libraryElement,
            container: container,
            targetElement: declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.mixinType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
        case ast.TopLevelVariableDeclarationImpl():
          // TODO(scheglov): implement it
          break;
      }
    }
  }

  /// Builds the augmentation library code for [results].
  String? buildAugmentationLibraryCode(
    List<macro.MacroExecutionResult> results,
  ) {
    if (results.isEmpty) {
      return null;
    }

    return macroExecutor
        .buildAugmentationLibrary(
          results,
          declarationBuilder.typeDeclarationOf,
          declarationBuilder.resolveIdentifier,
          declarationBuilder.inferOmittedType,
        )
        .trim();
  }

  Future<List<macro.MacroExecutionResult>?> executeDeclarationsPhase({
    required LibraryElementImpl library,
    required Element? targetElement,
  }) async {
    if (targetElement != null) {
      for (final running in _declarationsPhaseRunning.indexed) {
        if (running.$2.target.element == targetElement) {
          final id = 'DPI${_declarationsPhaseCycleIndex++}';
          _declarationsPhaseCycleApplications[id] =
              _declarationsPhaseRunning.skip(running.$1).toList();
          throw StateError('[$id] Declarations phase introspection cycle.');
        }
      }
    }

    final application = _nextForDeclarationsPhase(
      library: library,
      targetElement: targetElement,
    );
    if (application == null) {
      return null;
    }

    _declarationsPhaseRunning.add(application);

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final declaration = _buildDeclaration(application.target.node);

        final introspector = _DeclarationPhaseIntrospector(
          elementFactory,
          declarationBuilder,
          this,
          library.typeSystem,
        );

        final result = await macroExecutor.executeDeclarationsPhase(
          application.instance,
          declaration,
          introspector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }
      },
      targetElement: application.target.element,
      annotationIndex: application.annotationIndex,
    );

    _declarationsPhaseRunning.remove(application);
    return results;
  }

  Future<List<macro.MacroExecutionResult>?> executeDefinitionsPhase() async {
    final application = _nextForDefinitionsPhase();
    if (application == null) {
      return null;
    }

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final declaration = _buildDeclaration(application.target.node);

        final introspector = _DefinitionPhaseIntrospector(
          elementFactory,
          declarationBuilder,
          this,
          application.target.library.typeSystem,
        );

        final result = await macroExecutor.executeDefinitionsPhase(
          application.instance,
          declaration,
          introspector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }
      },
      targetElement: application.target.element,
      annotationIndex: application.annotationIndex,
    );

    return results;
  }

  Future<List<macro.MacroExecutionResult>?> executeTypesPhase() async {
    final application = _nextForTypesPhase();
    if (application == null) {
      return null;
    }

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final declaration = _buildDeclaration(application.target.node);

        final result = await macroExecutor.executeTypesPhase(
          application.instance,
          declaration,
          _typesPhaseIntrospector,
        );

        _addDiagnostics(application, result);
        if (result.isNotEmpty) {
          results.add(result);
        }
      },
      targetElement: application.target.element,
      annotationIndex: application.annotationIndex,
    );

    return results;
  }

  Future<void> _addAnnotations({
    required LibraryElementImpl libraryElement,
    required LibraryOrAugmentationElementImpl container,
    required ast.Declaration targetNode,
    required macro.DeclarationKind targetDeclarationKind,
    required List<ast.Annotation> annotations,
  }) async {
    if (targetNode is ast.FieldDeclaration) {
      for (final field in targetNode.fields.variables) {
        await _addAnnotations(
          libraryElement: libraryElement,
          container: container,
          targetNode: field,
          targetDeclarationKind: macro.DeclarationKind.field,
          annotations: annotations,
        );
      }
      return;
    }

    final targetElement =
        targetNode.declaredElement.ifTypeOrNull<MacroTargetElement>();
    if (targetElement == null) {
      return;
    }

    final macroTarget = _MacroTarget(
      library: libraryElement,
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

      final arguments = await _runWithCatchingExceptions(
        () async {
          return _buildArguments(
            annotationIndex: annotationIndex,
            node: importedMacro.arguments,
          );
        },
        targetElement: targetElement,
        annotationIndex: annotationIndex,
      );
      if (arguments == null) {
        continue;
      }

      final instance = await importedMacro.bundleExecutor.instantiate(
        libraryUri: importedMacro.macroLibrary.source.uri,
        className: importedMacro.macroClass.name,
        constructorName: importedMacro.constructorName ?? '',
        arguments: arguments,
      );

      final phasesToExecute = macro.Phase.values.where((phase) {
        return instance.shouldExecute(targetDeclarationKind, phase);
      }).toSet();

      final application = _MacroApplication(
        target: macroTarget,
        annotationIndex: annotationIndex,
        annotationNode: annotation,
        instance: instance,
        phasesToExecute: phasesToExecute,
      );

      _applications.add(application);
    }
  }

  Future<void> _addClassLike({
    required LibraryElementImpl libraryElement,
    required LibraryOrAugmentationElementImpl container,
    required MacroTargetElement targetElement,
    required ast.Declaration classNode,
    required macro.DeclarationKind classDeclarationKind,
    required List<ast.Annotation> classAnnotations,
    required List<ast.ClassMember> members,
  }) async {
    await _addAnnotations(
      libraryElement: libraryElement,
      container: container,
      targetNode: classNode,
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
        libraryElement: libraryElement,
        container: container,
        targetNode: member,
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
        default:
          target = ApplicationMacroDiagnosticTarget(
            annotationIndex: application.annotationIndex,
          );
      }

      return MacroDiagnosticMessage(
        target: target,
        message: message.message,
      );
    }

    bool addAsDeclarationsPhaseIntrospectionCycle(
      macro.Diagnostic diagnostic,
    ) {
      final pattern = RegExp(r'\[(DPI\d+)\] ');
      final match = pattern.firstMatch(diagnostic.message.message);
      if (match == null) {
        return false;
      }

      final id = match.group(1);
      final applications = _declarationsPhaseCycleApplications[id];
      if (applications == null) {
        return false;
      }

      final components = applications.map((application) {
        return DeclarationsIntrospectionCycleComponent(
          element: application.target.element,
          annotationIndex: application.annotationIndex,
        );
      }).toList();

      // Report the cycle at the first element.
      final firstElement = applications.first.target.element;
      firstElement.addMacroDiagnostic(
        DeclarationsIntrospectionCycleDiagnostic(
          components: components,
        ),
      );
      return true;
    }

    for (final diagnostic in result.diagnostics) {
      if (addAsDeclarationsPhaseIntrospectionCycle(diagnostic)) {
        continue;
      }

      application.target.element.addMacroDiagnostic(
        MacroDiagnostic(
          severity: diagnostic.severity,
          message: convertMessage(diagnostic.message),
          contextMessages:
              diagnostic.contextMessages.map(convertMessage).toList(),
        ),
      );
    }
  }

  macro.Declaration _buildDeclaration(ast.AstNode node) {
    return declarationBuilder.buildDeclaration(node);
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
    required LibraryElementImpl library,
    required Element? targetElement,
  }) {
    for (final application in _applications.reversed) {
      if (targetElement != null) {
        final applicationElement = application.target.element;
        if (applicationElement != targetElement &&
            applicationElement.enclosingElement != targetElement) {
          continue;
        }
      }
      if (application.phasesToExecute.remove(macro.Phase.declarations)) {
        return application;
      }
    }
    return null;
  }

  _MacroApplication? _nextForDefinitionsPhase() {
    for (final application in _applications.reversed) {
      if (application.phasesToExecute.remove(macro.Phase.definitions)) {
        return application;
      }
    }
    return null;
  }

  _MacroApplication? _nextForTypesPhase() {
    for (final application in _applications.reversed) {
      if (application.phasesToExecute.remove(macro.Phase.types)) {
        return application;
      }
    }
    return null;
  }

  static macro.Arguments _buildArguments({
    required int annotationIndex,
    required ast.ArgumentList node,
  }) {
    final positional = <macro.Argument>[];
    final named = <String, macro.Argument>{};
    for (var i = 0; i < node.arguments.length; ++i) {
      final argument = node.arguments[i];
      final evaluation = _ArgumentEvaluation(
        annotationIndex: annotationIndex,
        argumentIndex: i,
      );
      if (argument is ast.NamedExpression) {
        final value = evaluation.evaluate(argument.expression);
        named[argument.name.label.name] = value;
      } else {
        final value = evaluation.evaluate(argument);
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
    } on macro.RemoteException catch (e) {
      targetElement.addMacroDiagnostic(
        ExceptionMacroDiagnostic(
          annotationIndex: annotationIndex,
          message: e.error,
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

  macro.Argument evaluate(ast.Expression node) {
    if (node is ast.AdjacentStrings) {
      return macro.StringArgument(
          node.strings.map(evaluate).map((arg) => arg.value).join(''));
    } else if (node is ast.BooleanLiteral) {
      return macro.BoolArgument(node.value);
    } else if (node is ast.DoubleLiteral) {
      return macro.DoubleArgument(node.value);
    } else if (node is ast.IntegerLiteral) {
      return macro.IntArgument(node.value!);
    } else if (node is ast.ListLiteral) {
      final typeArguments = _typeArgumentsForNode(node);
      return macro.ListArgument(
          node.elements.cast<ast.Expression>().map(evaluate).toList(),
          typeArguments);
    } else if (node is ast.NullLiteral) {
      return macro.NullArgument();
    } else if (node is ast.PrefixExpression &&
        node.operator.type == TokenType.MINUS) {
      final operandValue = evaluate(node.operand);
      if (operandValue is macro.DoubleArgument) {
        return macro.DoubleArgument(-operandValue.value);
      } else if (operandValue is macro.IntArgument) {
        return macro.IntArgument(-operandValue.value);
      }
    } else if (node is ast.SetOrMapLiteral) {
      return _setOrMapLiteral(node);
    } else if (node is ast.SimpleStringLiteral) {
      return macro.StringArgument(node.value);
    }
    _throwError(node, 'Not supported: ${node.runtimeType}');
  }

  macro.Argument _setOrMapLiteral(ast.SetOrMapLiteral node) {
    final typeArguments = _typeArgumentsForNode(node);

    if (node.elements.every((e) => e is ast.Expression)) {
      final result = <macro.Argument>[];
      for (final element in node.elements) {
        if (element is! ast.Expression) {
          _throwError(element, 'Expression expected');
        }
        final value = evaluate(element);
        result.add(value);
      }
      return macro.SetArgument(result, typeArguments);
    }

    final result = <macro.Argument, macro.Argument>{};
    for (final element in node.elements) {
      if (element is! ast.MapLiteralEntry) {
        _throwError(element, 'MapLiteralEntry expected');
      }
      final key = evaluate(element.key);
      final value = evaluate(element.value);
      result[key] = value;
    }
    return macro.MapArgument(result, typeArguments);
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
    this.applier,
    this.typeSystem,
  );

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
    covariant macro.TypeDeclaration type,
  ) async {
    final element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    if (element case InterfaceElement(:final augmented?)) {
      return augmented.constructors
          .map((e) => e.declaration as ConstructorElementImpl)
          .map(declarationBuilder.fromElement.constructorElement)
          .toList();
    }
    return [];
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(
    macro.TypeDeclaration type,
  ) async {
    final element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    if (element case InstanceElement(:final augmented?)) {
      return augmented.fields
          .whereNot((e) => e.isSynthetic)
          .map((e) => e.declaration as FieldElementImpl)
          .map(declarationBuilder.fromElement.fieldElement)
          .toList();
    }
    // TODO(scheglov): can we test this?
    throw StateError('Unexpected: ${type.runtimeType}');
  }

  @override
  Future<List<macro.MethodDeclaration>> methodsOf(
    macro.TypeDeclaration type,
  ) async {
    final element = (type as HasElement).element;
    await _runDeclarationsPhase(element);

    if (element case InstanceElement(:final augmented?)) {
      return [
        ...augmented.accessors.whereNot((e) => e.isSynthetic),
        ...augmented.methods,
      ]
          .map((e) => e.declaration as ExecutableElementImpl)
          .map(declarationBuilder.fromElement.methodElement)
          .toList();
    }
    // TODO(scheglov): can we test this?
    throw StateError('Unexpected: ${type.runtimeType}');
  }

  @override
  Future<macro.StaticType> resolve(macro.TypeAnnotationCode typeCode) async {
    final type = declarationBuilder.resolveType(typeCode);
    return _StaticTypeImpl(typeSystem, type);
  }

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(
    macro.Identifier identifier,
  ) async {
    return declarationBuilder.typeDeclarationOf(identifier);
  }

  @override
  Future<List<macro.TypeDeclaration>> typesOf(covariant macro.Library library) {
    // TODO(jakemac): implement typesOf
    throw UnimplementedError();
  }

  @override
  Future<List<macro.EnumValueDeclaration>> valuesOf(
      covariant macro.EnumDeclaration type) {
    // TODO(jakemac): implement valuesOf
    throw UnimplementedError();
  }

  Future<void> _runDeclarationsPhase(ElementImpl element) async {
    // Don't run for the current element.
    final current = applier._declarationsPhaseRunning.lastOrNull;
    if (current?.target.element == element) {
      return;
    }

    await applier.runDeclarationsPhase(
      targetElement: element,
    );
  }
}

class _DefinitionPhaseIntrospector extends _DeclarationPhaseIntrospector
    implements macro.DefinitionPhaseIntrospector {
  _DefinitionPhaseIntrospector(
    super.elementFactory,
    super.declarationBuilder,
    super.applier,
    super.typeSystem,
  );

  @override
  Future<macro.Declaration> declarationOf(
    covariant macro.Identifier identifier,
  ) {
    // TODO(scheglov): implement declarationOf
    throw UnimplementedError();
  }

  @override
  Future<macro.TypeAnnotation> inferType(
    covariant macro.OmittedTypeAnnotation omittedType,
  ) {
    // TODO(scheglov): implement inferType
    throw UnimplementedError();
  }

  @override
  Future<List<macro.Declaration>> topLevelDeclarationsOf(
    covariant macro.Library library,
  ) {
    // TODO(scheglov): implement topLevelDeclarationsOf
    throw UnimplementedError();
  }

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(
    macro.Identifier identifier,
  ) async {
    return await super.typeDeclarationOf(identifier);
  }
}

class _MacroApplication {
  final _MacroTarget target;
  final int annotationIndex;
  final ast.Annotation annotationNode;
  final macro.MacroInstanceIdentifier instance;
  final Set<macro.Phase> phasesToExecute;

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

class _MacroTarget {
  final LibraryElementImpl library;
  final ast.Declaration node;
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
    // TODO(scheglov): write tests
    return Future.value(
      typeSystem.isSubtypeOf(type, other.type),
    );
  }
}

class _TypePhaseIntrospector implements macro.TypePhaseIntrospector {
  final LinkedElementFactory elementFactory;
  final DeclarationBuilder declarationBuilder;

  _TypePhaseIntrospector(
    this.elementFactory,
    this.declarationBuilder,
  );

  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) async {
    final libraryElement = elementFactory.libraryOfUri2(library);
    final element = libraryElement.scope.lookup(name).getter!;
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
