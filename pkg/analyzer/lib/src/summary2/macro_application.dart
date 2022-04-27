// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';

class LibraryMacroApplier {
  final MultiMacroExecutor macroExecutor;
  final LibraryBuilder libraryBuilder;

  final Map<MacroTargetElement, List<MacroApplication>> _applications =
      Map.identity();

  final Map<ClassDeclaration, macro.ClassDeclaration> _classDeclarations = {};

  LibraryMacroApplier(this.macroExecutor, this.libraryBuilder);

  Linker get _linker => libraryBuilder.linker;

  /// Fill [_applications]s with macro applications.
  Future<void> buildApplications() async {
    for (final unitElement in libraryBuilder.element.units) {
      for (final classElement in unitElement.classes) {
        classElement as ClassElementImpl;
        final classNode = _linker.elementNodes[classElement];
        // TODO(scheglov) support other declarations
        if (classNode is ClassDeclaration) {
          await _buildApplications(
            classElement,
            classNode.metadata,
            () => getClassDeclaration(classNode),
          );
        }
      }
    }
  }

  /// TODO(scheglov) check `shouldExecute`.
  /// TODO(scheglov) check `supportsDeclarationKind`.
  Future<String?> executeTypesPhase() async {
    final results = <macro.MacroExecutionResult>[];
    for (final unitElement in libraryBuilder.element.units) {
      for (final classElement in unitElement.classes) {
        classElement as ClassElementImpl;
        final applications = _applications[classElement];
        if (applications != null) {
          for (final application in applications) {
            await _runWithCatchingExceptions(
              () async {
                final result = await application.instance.executeTypesPhase();
                if (result.isNotEmpty) {
                  results.add(result);
                }
              },
              annotationIndex: application.annotationIndex,
              onError: (error) {
                classElement.macroApplicationErrors.add(error);
              },
            );
          }
        }
      }
    }

    if (results.isNotEmpty) {
      final code = macroExecutor.buildAugmentationLibrary(
        results,
        _resolveIdentifier,
        _inferOmittedType,
      );
      return code.trim();
    }
    return null;
  }

  /// TODO(scheglov) Do we need this caching?
  /// Or do we need it only during macro applications creation?
  macro.ClassDeclaration getClassDeclaration(ClassDeclaration node) {
    return _classDeclarations[node] ??= _buildClassDeclaration(node);
  }

  /// If there are any macro applications in [annotations], record for the
  /// [targetElement] in [_applications], for future execution.
  Future<void> _buildApplications(
    MacroTargetElement targetElement,
    List<Annotation> annotations,
    macro.Declaration Function() getDeclaration,
  ) async {
    final applications = <MacroApplication>[];
    for (var i = 0; i < annotations.length; i++) {
      final annotation = annotations[i];
      final macroElement = _importedMacroElement(annotation.name);
      final argumentsNode = annotation.arguments;
      if (macroElement is ClassElementImpl && argumentsNode != null) {
        final importedLibrary = macroElement.library;
        final macroExecutor = importedLibrary.bundleMacroExecutor;
        if (macroExecutor != null) {
          await _runWithCatchingExceptions(
            () async {
              final arguments = _buildArguments(
                annotationIndex: i,
                node: argumentsNode,
              );
              final declaration = getDeclaration();
              final macroInstance = await macroExecutor.instantiate(
                libraryUri: macroElement.librarySource.uri,
                className: macroElement.name,
                constructorName: '', // TODO
                arguments: arguments,
                declaration: declaration,
                identifierResolver: _FakeIdentifierResolver(),
              );
              applications.add(
                MacroApplication(
                  annotationIndex: i,
                  instance: macroInstance,
                ),
              );
            },
            annotationIndex: i,
            onError: (error) {
              targetElement.macroApplicationErrors.add(error);
            },
          );
        }
      }
    }
    if (applications.isNotEmpty) {
      _applications[targetElement] = applications;
    }
  }

  /// Return the macro element referenced by the [node].
  ElementImpl? _importedMacroElement(Identifier node) {
    final String? prefix;
    final String name;
    if (node is PrefixedIdentifier) {
      prefix = node.prefix.name;
      name = node.identifier.name;
    } else if (node is SimpleIdentifier) {
      prefix = null;
      name = node.name;
    } else {
      throw StateError('${node.runtimeType} $node');
    }

    for (final import in libraryBuilder.element.imports) {
      if (import.prefix?.name != prefix) {
        continue;
      }

      final importedLibrary = import.importedLibrary;
      if (importedLibrary == null) {
        continue;
      }

      // Skip if a library that is being linked.
      final importedUri = importedLibrary.source.uri;
      if (_linker.builders.containsKey(importedUri)) {
        continue;
      }

      final lookupResult = importedLibrary.scope.lookup(name);
      final element = lookupResult.getter;
      if (element is ClassElementImpl && element.isMacro) {
        return element;
      }
    }
    return null;
  }

  macro.TypeAnnotation _inferOmittedType(
    macro.OmittedTypeAnnotation omittedType,
  ) {
    throw UnimplementedError();
  }

  macro.ResolvedIdentifier _resolveIdentifier(macro.Identifier identifier) {
    throw UnimplementedError();
  }

  static macro.Arguments _buildArguments({
    required int annotationIndex,
    required ArgumentList node,
  }) {
    final positional = <Object?>[];
    final named = <String, Object?>{};
    for (var i = 0; i < node.arguments.length; ++i) {
      final argument = node.arguments[i];
      final evaluation = _ArgumentEvaluation(
        annotationIndex: annotationIndex,
        argumentIndex: i,
      );
      if (argument is NamedExpression) {
        final value = evaluation.evaluate(argument.expression);
        named[argument.name.label.name] = value;
      } else {
        final value = evaluation.evaluate(argument);
        positional.add(value);
      }
    }
    return macro.Arguments(positional, named);
  }

  static macro.ClassDeclarationImpl _buildClassDeclaration(
    ClassDeclaration node,
  ) {
    return macro.ClassDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _buildIdentifier(node.name),
      typeParameters: _buildTypeParameters(node.typeParameters),
      interfaces: _buildTypeAnnotations(node.implementsClause?.interfaces),
      isAbstract: node.abstractKeyword != null,
      isExternal: false,
      mixins: _buildTypeAnnotations(node.withClause?.mixinTypes),
      superclass: node.extendsClause?.superclass.mapOrNull(
        _buildTypeAnnotation,
      ),
    );
  }

  static macro.FunctionTypeParameterImpl _buildFormalParameter(
    FormalParameter node,
  ) {
    if (node is DefaultFormalParameter) {
      node = node.parameter;
    }

    final macro.TypeAnnotationImpl typeAnnotation;
    if (node is SimpleFormalParameter) {
      typeAnnotation = _buildTypeAnnotation(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.FunctionTypeParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      name: node.identifier?.name,
      type: typeAnnotation,
    );
  }

  static macro.IdentifierImpl _buildIdentifier(Identifier node) {
    final String name;
    if (node is SimpleIdentifier) {
      name = node.name;
    } else {
      name = (node as PrefixedIdentifier).identifier.name;
    }
    return _IdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: name,
    );
  }

  static macro.TypeAnnotationImpl _buildTypeAnnotation(TypeAnnotation? node) {
    if (node == null) {
      return macro.OmittedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
      );
    } else if (node is GenericFunctionType) {
      return macro.FunctionTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        isNullable: node.question != null,
        namedParameters: node.parameters.parameters
            .where((e) => e.isNamed)
            .map(_buildFormalParameter)
            .toList(),
        positionalParameters: node.parameters.parameters
            .where((e) => e.isPositional)
            .map(_buildFormalParameter)
            .toList(),
        returnType: _buildTypeAnnotation(node.returnType),
        typeParameters: _buildTypeParameters(node.typeParameters),
      );
    } else if (node is NamedType) {
      return macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: _buildIdentifier(node.name),
        isNullable: node.question != null,
        typeArguments: _buildTypeAnnotations(node.typeArguments?.arguments),
      );
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  static List<macro.TypeAnnotationImpl> _buildTypeAnnotations(
    List<TypeAnnotation>? elements,
  ) {
    if (elements != null) {
      return elements.map(_buildTypeAnnotation).toList();
    } else {
      return const [];
    }
  }

  static macro.TypeParameterDeclarationImpl _buildTypeParameter(
    TypeParameter node,
  ) {
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _buildIdentifier(node.name),
      bound: node.bound?.mapOrNull(_buildTypeAnnotation),
    );
  }

  static List<macro.TypeParameterDeclarationImpl> _buildTypeParameters(
    TypeParameterList? typeParameterList,
  ) {
    if (typeParameterList != null) {
      return typeParameterList.typeParameters.map(_buildTypeParameter).toList();
    } else {
      return const [];
    }
  }

  /// Run the [body], report exceptions as [MacroApplicationError]s to [onError].
  static Future<void> _runWithCatchingExceptions<T>(
    Future<T> Function() body, {
    required int annotationIndex,
    required void Function(MacroApplicationError) onError,
  }) async {
    try {
      await body();
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
  }
}

class MacroApplication {
  final int annotationIndex;
  final MacroClassInstance instance;

  MacroApplication({
    required this.annotationIndex,
    required this.instance,
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

  Object? evaluate(Expression node) {
    if (node is AdjacentStrings) {
      return node.strings.map(evaluate).join('');
    } else if (node is BooleanLiteral) {
      return node.value;
    } else if (node is DoubleLiteral) {
      return node.value;
    } else if (node is IntegerLiteral) {
      return node.value;
    } else if (node is ListLiteral) {
      return node.elements.cast<Expression>().map(evaluate).toList();
    } else if (node is NullLiteral) {
      return null;
    } else if (node is PrefixExpression &&
        node.operator.type == TokenType.MINUS) {
      final operandValue = evaluate(node.operand);
      if (operandValue is double) {
        return -operandValue;
      } else if (operandValue is int) {
        return -operandValue;
      }
    } else if (node is SetOrMapLiteral) {
      return _setOrMapLiteral(node);
    } else if (node is SimpleStringLiteral) {
      return node.value;
    }
    _throwError(node, 'Not supported: ${node.runtimeType}');
  }

  Object _setOrMapLiteral(SetOrMapLiteral node) {
    if (node.elements.every((e) => e is Expression)) {
      final result = <Object?>{};
      for (final element in node.elements) {
        if (element is! Expression) {
          _throwError(element, 'Expression expected');
        }
        final value = evaluate(element);
        result.add(value);
      }
      return result;
    }

    final result = <Object?, Object?>{};
    for (final element in node.elements) {
      if (element is! MapLiteralEntry) {
        _throwError(element, 'MapLiteralEntry expected');
      }
      final key = evaluate(element.key);
      final value = evaluate(element.value);
      result[key] = value;
    }
    return result;
  }

  Never _throwError(AstNode node, String message) {
    throw ArgumentMacroApplicationError(
      annotationIndex: annotationIndex,
      argumentIndex: argumentIndex,
      message: message,
    );
  }
}

class _FakeIdentifierResolver extends macro.IdentifierResolver {
  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) {
    // TODO: implement resolveIdentifier
    throw UnimplementedError();
  }
}

class _IdentifierImpl extends macro.IdentifierImpl {
  _IdentifierImpl({required int id, required String name})
      : super(id: id, name: name);
}

extension on macro.MacroExecutionResult {
  bool get isNotEmpty =>
      libraryAugmentations.isNotEmpty || classAugmentations.isNotEmpty;
}

extension _IfNotNull<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    final self = this;
    return self != null ? mapper(self) : null;
  }
}
