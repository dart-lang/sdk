// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart' as macro;
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/token.dart';
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
        // TODO: Support nested type arguments for collections.
        DartType(isDartCoreList: true) => macro.ArgumentKind.list,
        DartType(isDartCoreMap: true) => macro.ArgumentKind.map,
        DartType(isDartCoreSet: true) => macro.ArgumentKind.set,
        DynamicType() => macro.ArgumentKind.dynamic,
        // TODO: Support type annotations and code objects
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
      // TODO: Use downward inference to build these types and detect maps
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
  final List<_MacroApplication> _applications = [];

  late final macro.TypePhaseIntrospector _typesPhaseIntrospector =
      _TypePhaseIntrospector(elementFactory, declarationBuilder);

  LibraryMacroApplier({
    required this.elementFactory,
    required this.macroExecutor,
    required this.isLibraryBeingLinked,
    required this.declarationBuilder,
  });

  Future<void> add({
    required LibraryOrAugmentationElementImpl container,
    required ast.CompilationUnit unit,
  }) async {
    for (final declaration in unit.declarations.reversed) {
      switch (declaration) {
        case ast.ClassDeclaration():
          final element = declaration.declaredElement;
          element as ClassElementImpl;
          await _addClassLike(
            container: container,
            targetElement: element.declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.classType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
        case ast.MixinDeclaration():
          final element = declaration.declaredElement;
          element as MixinElementImpl;
          await _addClassLike(
            container: container,
            targetElement: element.declarationElement,
            classNode: declaration,
            classDeclarationKind: macro.DeclarationKind.mixinType,
            classAnnotations: declaration.metadata,
            members: declaration.members,
          );
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
          _resolveDeclaration,
          _resolveIdentifier,
          _inferOmittedType,
        )
        .trim();
  }

  Future<List<macro.MacroExecutionResult>?> executeDeclarationsPhase({
    required TypeSystemImpl typeSystem,
  }) async {
    final application = _nextForDeclarationsPhase();
    if (application == null) {
      return null;
    }

    final results = <macro.MacroExecutionResult>[];

    await _runWithCatchingExceptions(
      () async {
        final declaration = _buildDeclaration(application.targetNode);

        final introspector = _DeclarationPhaseIntrospector(
          elementFactory,
          declarationBuilder,
          typeSystem,
        );

        final result = await macroExecutor.executeDeclarationsPhase(
          application.instance,
          declaration,
          introspector,
        );

        if (result.isNotEmpty) {
          results.add(result);
        }
      },
      annotationIndex: 0, // TODO(scheglov)
      onError: (error) {
        application.targetElement.addMacroApplicationError(error);
      },
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
        final declaration = _buildDeclaration(application.targetNode);

        final result = await macroExecutor.executeTypesPhase(
          application.instance,
          declaration,
          _typesPhaseIntrospector,
        );

        if (result.isNotEmpty) {
          results.add(result);
        }
      },
      annotationIndex: 0, // TODO(scheglov)
      onError: (error) {
        application.targetElement.addMacroApplicationError(error);
      },
    );

    return results;
  }

  Future<void> _addAnnotations({
    required LibraryOrAugmentationElementImpl container,
    required ast.Declaration targetNode,
    required macro.DeclarationKind targetDeclarationKind,
    required List<ast.Annotation> annotations,
  }) async {
    final targetElement =
        targetNode.declaredElement.ifTypeOrNull<MacroTargetElement>();
    if (targetElement == null) {
      return;
    }

    for (final annotation in annotations) {
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
            annotationIndex: 0, // TODO(scheglov)
            node: importedMacro.arguments,
          );
        },
        annotationIndex: 0, // TODO(scheglov)
        onError: (error) {
          targetElement.addMacroApplicationError(error);
        },
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

      _applications.add(
        _MacroApplication(
          targetNode: targetNode,
          targetElement: targetElement,
          targetDeclarationKind: targetDeclarationKind,
          instance: instance,
          phasesToExecute: phasesToExecute,
        ),
      );
    }
  }

  Future<void> _addClassLike({
    required LibraryOrAugmentationElementImpl container,
    required MacroTargetElement targetElement,
    required ast.Declaration classNode,
    required macro.DeclarationKind classDeclarationKind,
    required List<ast.Annotation> classAnnotations,
    required List<ast.ClassMember> members,
  }) async {
    await _addAnnotations(
      container: container,
      targetNode: classNode,
      targetDeclarationKind: classDeclarationKind,
      annotations: classAnnotations,
    );

    for (final member in members.reversed) {
      await _addAnnotations(
        container: container,
        targetNode: member,
        // TODO(scheglov) incomplete
        targetDeclarationKind: macro.DeclarationKind.method,
        annotations: member.metadata,
      );
    }
  }

  macro.Declaration _buildDeclaration(ast.AstNode targetNode) {
    final fromNode = declarationBuilder.fromNode;
    switch (targetNode) {
      case ast.ClassDeclaration():
        return fromNode.classDeclaration(targetNode);
      case ast.MethodDeclaration():
        return fromNode.methodDeclaration(targetNode);
      case ast.MixinDeclaration():
        return fromNode.mixinDeclaration(targetNode);
      default:
        // TODO(scheglov) incomplete
        throw UnimplementedError('${targetNode.runtimeType}');
    }
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

  macro.TypeAnnotation _inferOmittedType(
    macro.OmittedTypeAnnotation omittedType,
  ) {
    throw UnimplementedError();
  }

  /// TODO(scheglov) Should use dependencies.
  _MacroApplication? _nextForDeclarationsPhase() {
    for (final application in _applications.reversed) {
      if (application.phasesToExecute.remove(macro.Phase.declarations)) {
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

  macro.TypeDeclaration _resolveDeclaration(macro.Identifier identifier) {
    final element = (identifier as IdentifierImpl).element;
    if (element is ClassElementImpl) {
      return declarationBuilder.fromElement.classElement(element);
    } else if (element is MixinElementImpl) {
      return declarationBuilder.fromElement.mixinElement(element);
    } else {
      throw ArgumentError('element: $element');
    }
  }

  macro.ResolvedIdentifier _resolveIdentifier(macro.Identifier identifier) {
    if (identifier is IdentifierImplFromElement) {
      // TODO(scheglov) other elements
      final element = identifier.element as InterfaceElementImpl;
      return macro.ResolvedIdentifier(
        // TODO(scheglov) other kinds
        kind: macro.IdentifierKind.topLevelMember,
        name: element.name,
        uri: element.source.uri,
        staticScope: null,
      );
    }
    throw UnimplementedError();
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

  /// Run the [body], report exceptions as [MacroApplicationError]s to [onError].
  static Future<T?> _runWithCatchingExceptions<T>(
    Future<T> Function() body, {
    required int annotationIndex,
    required void Function(MacroApplicationError) onError,
  }) async {
    try {
      return await body();
    } on MacroApplicationError catch (e) {
      onError(e);
    } on macro.RemoteException catch (e) {
      onError(
        UnknownMacroApplicationError(
          annotationIndex: annotationIndex,
          message: e.error,
          stackTrace: e.stackTrace ?? '<null>',
        ),
      );
    } catch (e, stackTrace) {
      onError(
        UnknownMacroApplicationError(
          annotationIndex: annotationIndex,
          message: e.toString(),
          stackTrace: stackTrace.toString(),
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
    throw ArgumentMacroApplicationError(
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
      super.elementFactory, super.declarationBuilder, this.typeSystem);

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
      covariant macro.IntrospectableType type) {
    // TODO: implement constructorsOf
    throw UnimplementedError();
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(
    covariant macro.IntrospectableType type,
  ) async {
    switch (type) {
      case IntrospectableClassDeclarationImpl():
        return type.element.fields
            .where((e) => !e.isSynthetic)
            .map(declarationBuilder.fromElement.fieldElement)
            .toList();
      case IntrospectableMixinDeclarationImpl():
        return type.element.fields
            .where((e) => !e.isSynthetic)
            .map(declarationBuilder.fromElement.fieldElement)
            .toList();
    }
    throw UnsupportedError('Only introspection on classes is supported');
  }

  @override
  Future<List<macro.MethodDeclaration>> methodsOf(
      covariant macro.IntrospectableType clazz) {
    // TODO: implement methodsOf
    throw UnimplementedError();
  }

  @override
  Future<macro.StaticType> resolve(macro.TypeAnnotationCode type) async {
    var dartType = _resolve(type);
    return _StaticTypeImpl(typeSystem, dartType);
  }

  @override
  Future<macro.TypeDeclaration> typeDeclarationOf(
    covariant IdentifierImpl identifier,
  ) async {
    final element = identifier.element;
    if (element is ClassElementImpl) {
      return declarationBuilder.fromElement.classElement(element);
    } else {
      throw ArgumentError('element: $element');
    }
  }

  @override
  Future<List<macro.TypeDeclaration>> typesOf(covariant macro.Library library) {
    // TODO: implement typesOf
    throw UnimplementedError();
  }

  @override
  Future<List<macro.EnumValueDeclaration>> valuesOf(
      covariant macro.IntrospectableEnum type) {
    // TODO: implement valuesOf
    throw UnimplementedError();
  }

  DartType _resolve(macro.TypeAnnotationCode type) {
    // TODO(scheglov) write tests
    if (type is macro.NamedTypeAnnotationCode) {
      final identifier = type.name as IdentifierImpl;
      final element = identifier.element;
      if (element is ClassElementImpl) {
        return element.instantiate(
          typeArguments: type.typeArguments.map(_resolve).toList(),
          nullabilitySuffix: type.isNullable
              ? NullabilitySuffix.question
              : NullabilitySuffix.none,
        );
      } else {
        // TODO(scheglov) Implement other elements.
        throw UnimplementedError('(${element.runtimeType}) $element');
      }
    } else {
      // TODO(scheglov) Implement other types.
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }
}

class _MacroApplication {
  final ast.AstNode targetNode;
  final MacroTargetElement targetElement;
  final macro.DeclarationKind targetDeclarationKind;
  final macro.MacroInstanceIdentifier instance;
  final Set<macro.Phase> phasesToExecute;

  _MacroApplication({
    required this.targetNode,
    required this.targetElement,
    required this.targetDeclarationKind,
    required this.instance,
    required this.phasesToExecute,
  });
}

class _StaticTypeImpl implements macro.StaticType {
  final TypeSystemImpl typeSystem;
  final DartType type;

  _StaticTypeImpl(this.typeSystem, this.type);

  @override
  Future<bool> isExactly(_StaticTypeImpl other) {
    // TODO: implement isExactly
    throw UnimplementedError();
  }

  @override
  Future<bool> isSubtypeOf(_StaticTypeImpl other) {
    // TODO(scheglov) write tests
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

extension<T extends InstanceElementImpl> on T {
  T get declarationElement {
    switch (augmented) {
      case T(:final T declaration):
        return declaration;
      default:
        return this;
    }
  }
}
