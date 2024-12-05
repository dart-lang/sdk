// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';

abstract class AnalysisResultImpl implements AnalysisResult {
  @override
  final AnalysisSession session;

  AnalysisResultImpl({
    required this.session,
  });
}

/// A visitor which locates the [AstNode] which declares [element].
class DeclarationByElementLocator extends UnifyingAstVisitor<void> {
  // TODO(srawlins): This visitor could be further optimized by special casing each static
  // type of [element]. For example, for library-level elements (classes etc),
  // we can iterate over the compilation unit's declarations.

  final Element element;
  final int _nameOffset;
  AstNode? result;

  DeclarationByElementLocator(this.element) : _nameOffset = element.nameOffset;

  @override
  void visitNode(AstNode node) {
    if (result != null) return;

    if (node.endToken.end < _nameOffset || node.offset > _nameOffset) {
      return;
    }

    if (element is InterfaceElement) {
      if (node is ClassDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      } else if (node is ClassTypeAlias) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      } else if (node is EnumDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      } else if (node is MixinDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      } else if (node is ExtensionTypeDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      }
    } else if (element is ConstructorElement) {
      if (node is ConstructorDeclaration) {
        if (node.name != null) {
          if (_hasOffset2(node.name)) {
            result = node;
          }
        } else {
          if (_hasOffset(node.returnType)) {
            result = node;
          }
        }
      }
    } else if (element is ExtensionElement) {
      if (node is ExtensionDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      }
    } else if (element is FieldElement) {
      if (node is EnumConstantDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      } else if (node is VariableDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      }
    } else if (element is FunctionElement) {
      if (node is FunctionDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (element is LocalVariableElement) {
      if (node is VariableDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (element is MethodElement) {
      if (node is MethodDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (element is ParameterElement) {
      if (node is FormalParameter && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (element is PropertyAccessorElement) {
      if (node is FunctionDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      } else if (node is MethodDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      }
    } else if (element is TopLevelVariableElement) {
      if (node is VariableDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (element is TypeAliasElement) {
      if (node is GenericTypeAlias) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      }
    }

    if (result == null) {
      node.visitChildren(this);
    }
  }

  bool _hasOffset(AstNode? node) {
    return node?.offset == _nameOffset;
  }

  bool _hasOffset2(Token? token) {
    return token?.offset == _nameOffset;
  }
}

class ElementDeclarationResultImpl implements ElementDeclarationResult {
  @override
  final Element element;

  @override
  final AstNode node;

  @override
  final ParsedUnitResult? parsedUnit;

  @override
  final ResolvedUnitResult? resolvedUnit;

  ElementDeclarationResultImpl(
      this.element, this.node, this.parsedUnit, this.resolvedUnit);

  @override
  Element2 get element2 {
    if (element case Fragment fragment) {
      return fragment.element;
    } else if (element case Element2 element) {
      return element;
    }
    throw UnimplementedError('Could not compute and element');
  }
}

class ErrorsResultImpl implements ErrorsResult {
  @override
  final List<AnalysisError> errors;

  @override
  final bool isLibrary;

  @override
  final bool isMacroPart;

  @override
  final bool isPart;

  @override
  final LineInfo lineInfo;

  @override
  final AnalysisSession session;

  @override
  final Uri uri;

  @override
  File file;

  @override
  final String content;

  @override
  final AnalysisOptions analysisOptions;

  ErrorsResultImpl({
    required this.session,
    required this.file,
    required this.content,
    required this.uri,
    required this.lineInfo,
    required this.isLibrary,
    required this.isMacroPart,
    required this.isPart,
    required this.errors,
    required this.analysisOptions,
  });

  @override
  String get path => file.path;
}

class FileResultImpl extends AnalysisResultImpl implements FileResult {
  final FileState fileState;

  @override
  final String content;

  @override
  final LineInfo lineInfo;

  @override
  final bool isLibrary;

  @override
  final bool isPart;

  FileResultImpl({
    required super.session,
    required this.fileState,
  })  : content = fileState.content,
        lineInfo = fileState.lineInfo,
        isLibrary = fileState.kind is LibraryFileKind,
        isPart = fileState.kind is PartFileKind;

  @override
  AnalysisOptions get analysisOptions => fileState.analysisOptions;

  @override
  File get file => fileState.resource;

  @override
  bool get isMacroPart {
    return fileState.isMacroPart;
  }

  @override
  String get path => fileState.path;

  @override
  Uri get uri => fileState.uri;
}

class LibraryElementResultImpl implements LibraryElementResult {
  @override
  final LibraryElement element;

  LibraryElementResultImpl(this.element);

  @override
  LibraryElement2 get element2 => element as LibraryElement2;
}

class ParsedLibraryResultImpl extends AnalysisResultImpl
    implements ParsedLibraryResult {
  @override
  final List<ParsedUnitResult> units;

  ParsedLibraryResultImpl({
    required super.session,
    required this.units,
  });

  @override
  ElementDeclarationResult? getElementDeclaration(Element element) {
    if (element is CompilationUnitElement ||
        element is LibraryElement ||
        element.isSynthetic ||
        element.nameOffset == -1) {
      return null;
    }

    var elementPath = element.source!.fullName;
    var unitResult = units.firstWhere(
      (r) => r.path == elementPath,
      orElse: () {
        var elementStr = element.getDisplayString();
        throw ArgumentError('Element (${element.runtimeType}) $elementStr is '
            'not defined in this library.');
      },
    );

    var locator = DeclarationByElementLocator(element);
    unitResult.unit.accept(locator);
    var declaration = locator.result;

    if (declaration == null) {
      return null;
    }

    return ElementDeclarationResultImpl(element, declaration, unitResult, null);
  }

  @override
  ElementDeclarationResult? getElementDeclaration2(Fragment fragment) {
    if (fragment case Element element) {
      return getElementDeclaration(element);
    }
    throw UnimplementedError();
  }
}

class ParsedUnitResultImpl extends FileResultImpl implements ParsedUnitResult {
  @override
  final CompilationUnit unit;

  @override
  final List<AnalysisError> errors;

  ParsedUnitResultImpl({
    required super.session,
    required super.fileState,
    required this.unit,
    required this.errors,
  });
}

class ParseStringResultImpl implements ParseStringResult {
  @override
  final String content;

  @override
  final List<AnalysisError> errors;

  @override
  final CompilationUnit unit;

  ParseStringResultImpl(this.content, this.unit, this.errors);

  @override
  LineInfo get lineInfo => unit.lineInfo;
}

class ResolvedForCompletionResultImpl {
  final AnalysisSession analysisSession;
  final FileState fileState;
  final String path;
  final Uri uri;
  final bool exists;
  final String content;
  final LineInfo lineInfo;

  /// The full parsed unit.
  final CompilationUnit parsedUnit;

  /// The full element for the unit.
  final CompilationUnitElement unitElement;

  /// Nodes from [parsedUnit] that were resolved to provide enough context
  /// to perform completion. How much is enough depends on the location
  /// where resolution for completion was requested, and our knowledge
  /// how completion contributors work and what information they expect.
  ///
  /// This is usually a small subset of the whole unit - a method, a field.
  /// It could be even empty if the location does not provide any context
  /// information for any completion contributor, e.g. a type annotation.
  /// But it could be the whole unit as well, if the location is not something
  /// we have an optimization for.
  ///
  /// If this list is not empty, then the last node contains the requested
  /// offset. Other nodes are provided mostly FYI.
  final List<AstNode> resolvedNodes;

  ResolvedForCompletionResultImpl({
    required this.analysisSession,
    required this.fileState,
    required this.path,
    required this.uri,
    required this.exists,
    required this.content,
    required this.lineInfo,
    required this.parsedUnit,
    required this.unitElement,
    required this.resolvedNodes,
  });

  LibraryElement get libraryElement => unitElement.library;
}

class ResolvedLibraryResultImpl extends AnalysisResultImpl
    implements ResolvedLibraryResult {
  @override
  final LibraryElement element;

  @override
  final List<ResolvedUnitResult> units;

  ResolvedLibraryResultImpl({
    required super.session,
    required this.element,
    required this.units,
  });

  @override
  LibraryElement2 get element2 => element as LibraryElement2;

  @override
  TypeProvider get typeProvider => element.typeProvider;

  @override
  ElementDeclarationResult? getElementDeclaration(Element element) {
    if (element is CompilationUnitElement ||
        element is LibraryElement ||
        element.isSynthetic ||
        element.nameOffset == -1) {
      return null;
    }

    var elementPath = element.source!.fullName;
    var unitResult = units.firstWhere(
      (r) => r.path == elementPath,
      orElse: () {
        var elementStr = element.getDisplayString();
        throw ArgumentError('Element (${element.runtimeType}) $elementStr is '
            'not defined in this library.');
      },
    );

    var locator = DeclarationByElementLocator(element);
    unitResult.unit.accept(locator);
    var declaration = locator.result;

    if (declaration == null) {
      return null;
    }

    return ElementDeclarationResultImpl(element, declaration, null, unitResult);
  }

  @override
  ElementDeclarationResult? getElementDeclaration2(Fragment fragment) {
    if (fragment case Element element) {
      return getElementDeclaration(element);
    }
    throw UnimplementedError();
  }

  @override
  ResolvedUnitResult? unitWithPath(String path) {
    for (var unit in units) {
      if (unit.path == path) {
        return unit;
      }
    }
    return null;
  }
}

class ResolvedUnitResultImpl extends FileResultImpl
    implements ResolvedUnitResult {
  @override
  final CompilationUnit unit;

  @override
  final List<AnalysisError> errors;

  ResolvedUnitResultImpl({
    required super.session,
    required super.fileState,
    required this.unit,
    required this.errors,
  });

  @override
  bool get exists => fileState.exists;

  @override
  LibraryElement get libraryElement {
    return unit.declaredElement!.library;
  }

  @override
  LibraryElement2 get libraryElement2 => libraryFragment.element;

  @override
  LibraryFragment get libraryFragment => unit.declaredFragment!;

  @override
  TypeProvider get typeProvider => libraryElement.typeProvider;

  @override
  TypeSystemImpl get typeSystem => libraryElement.typeSystem as TypeSystemImpl;
}

class UnitElementResultImpl extends FileResultImpl
    implements UnitElementResult {
  @override
  final CompilationUnitElement element;

  UnitElementResultImpl({
    required super.session,
    required super.fileState,
    required this.element,
  });

  @override
  LibraryFragment get fragment => element as LibraryFragment;
}
