// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

/// This returns the offset used for finding the corresponding AST node.
///
/// - If the fragment is named, the [Fragment.nameOffset] is used.
/// - If the fragment is a a [ConstructorFragment] for an unnamed constructor,
/// the [ConstructorFragment.typeNameOffset] is used.
/// - If the fragment is an unnamed [ExtensionFragment], the
/// [ExtensionFragment.offset] is used.
int? _getFragmentNameOffset(Fragment fragment) {
  var nameOffset = fragment.nameOffset;
  if (nameOffset == null) {
    if (fragment is ConstructorFragment) {
      nameOffset = fragment.typeNameOffset;
    } else if (fragment is ExtensionFragment) {
      nameOffset = fragment.offset;
    }
  }
  return nameOffset;
}

abstract class AnalysisResultImpl implements AnalysisResult {
  @override
  final AnalysisSession session;

  AnalysisResultImpl({required this.session});
}

/// A visitor which locates the [AstNode] which declares [element].
class DeclarationByElementLocator extends UnifyingAstVisitor<void> {
  // TODO(srawlins): This visitor could be further optimized by special casing each static
  // type of [element]. For example, for library-level elements (classes etc),
  // we can iterate over the compilation unit's declarations.

  final Fragment fragment;
  final int _nameOffset;
  AstNode? result;

  DeclarationByElementLocator(this.fragment, this._nameOffset);

  @override
  void visitNode(AstNode node) {
    if (result != null) return;

    if (node.endToken.end < _nameOffset || node.offset > _nameOffset) {
      return;
    }

    if (fragment is InterfaceFragment) {
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
    } else if (fragment is ConstructorFragment) {
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
    } else if (fragment is ExtensionFragment) {
      if (node is ExtensionDeclaration) {
        if (_hasOffset2(node.name ?? node.extensionKeyword)) {
          result = node;
        }
      }
    } else if (fragment is FieldFragment) {
      if (node is EnumConstantDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      } else if (node is VariableDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      }
    } else if (fragment is TopLevelFunctionFragment) {
      if (node is FunctionDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (fragment is LocalFunctionFragment) {
      if (node is FunctionDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (fragment is LocalVariableFragment) {
      if (node is VariableDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (fragment is MethodFragment) {
      if (node is MethodDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (fragment is FormalParameterFragment) {
      if (node is FormalParameter && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (fragment is PropertyAccessorFragment) {
      if (node is FunctionDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      } else if (node is MethodDeclaration) {
        if (_hasOffset2(node.name)) {
          result = node;
        }
      }
    } else if (fragment is TopLevelVariableFragment) {
      if (node is VariableDeclaration && _hasOffset2(node.name)) {
        result = node;
      }
    } else if (fragment is TypeAliasFragment) {
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

class ElementDeclarationResultImpl
    implements
        // ignore:deprecated_member_use_from_same_package
        ElementDeclarationResult,
        FragmentDeclarationResult {
  @override
  final Fragment fragment;

  @override
  final AstNode node;

  @override
  final ParsedUnitResult? parsedUnit;

  @override
  final ResolvedUnitResult? resolvedUnit;

  ElementDeclarationResultImpl(
    this.fragment,
    this.node,
    this.parsedUnit,
    this.resolvedUnit,
  );
}

class ErrorsResultImpl implements ErrorsResult {
  @override
  final List<Diagnostic> diagnostics;

  @override
  final bool isLibrary;

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
    required this.isPart,
    required this.diagnostics,
    required this.analysisOptions,
  });

  @override
  List<Diagnostic> get errors => diagnostics;

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

  FileResultImpl({required super.session, required this.fileState})
    : content = fileState.content,
      lineInfo = fileState.lineInfo,
      isLibrary = fileState.kind is LibraryFileKind,
      isPart = fileState.kind is PartFileKind;

  @override
  AnalysisOptions get analysisOptions => fileState.analysisOptions;

  @override
  File get file => fileState.resource;

  @override
  String get path => fileState.path;

  @override
  Uri get uri => fileState.uri;
}

class LibraryElementResultImpl implements LibraryElementResult {
  @override
  final LibraryElementImpl element;

  LibraryElementResultImpl(this.element);

  @override
  @Deprecated('Use element instead')
  LibraryElement get element2 => element;
}

class MissingSdkLibraryResultImpl implements MissingSdkLibraryResult {
  @override
  final Uri missingUri;

  MissingSdkLibraryResultImpl({required this.missingUri});
}

class ParsedLibraryResultImpl extends AnalysisResultImpl
    implements ParsedLibraryResult {
  @override
  final List<ParsedUnitResult> units;

  ParsedLibraryResultImpl({required super.session, required this.units});

  @Deprecated('Use getFragmentDeclaration() instead')
  @override
  ElementDeclarationResultImpl? getElementDeclaration2(Fragment fragment) {
    return getFragmentDeclaration(fragment);
  }

  @override
  ElementDeclarationResultImpl? getFragmentDeclaration(Fragment fragment) {
    var nameOffset = _getFragmentNameOffset(fragment);
    if (fragment is LibraryFragment || nameOffset == null) {
      return null;
    }

    var elementPath = fragment.libraryFragment!.source.fullName;
    var unitResult = units.firstWhere(
      (r) => r.path == elementPath,
      orElse: () {
        var elementStr = fragment.element.displayName;
        throw ArgumentError(
          'Element (${fragment.runtimeType}) $elementStr is '
          'not defined in this library.',
        );
      },
    );

    var locator = DeclarationByElementLocator(fragment, nameOffset);
    unitResult.unit.accept(locator);
    var declaration = locator.result;

    if (declaration == null) {
      return null;
    }

    return ElementDeclarationResultImpl(
      fragment,
      declaration,
      unitResult,
      null,
    );
  }
}

class ParsedUnitResultImpl extends FileResultImpl implements ParsedUnitResult {
  @override
  final CompilationUnit unit;

  @override
  final List<Diagnostic> diagnostics;

  ParsedUnitResultImpl({
    required super.session,
    required super.fileState,
    required this.unit,
    required this.diagnostics,
  });

  @override
  List<Diagnostic> get errors => diagnostics;
}

class ParseStringResultImpl implements ParseStringResult {
  @override
  final String content;

  @override
  final List<Diagnostic> errors;

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
  final LibraryFragment unitElement;

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
}

class ResolvedLibraryResultImpl extends AnalysisResultImpl
    implements ResolvedLibraryResult {
  @override
  final LibraryElementImpl element;

  @override
  final List<ResolvedUnitResult> units;

  ResolvedLibraryResultImpl({
    required super.session,
    required this.element,
    required this.units,
  });

  @override
  @Deprecated('Use element instead')
  LibraryElement get element2 => element;

  @override
  TypeProviderImpl get typeProvider => element.typeProvider;

  @Deprecated('Use getFragmentDeclaration() instead')
  @override
  ElementDeclarationResultImpl? getElementDeclaration2(Fragment fragment) {
    return getFragmentDeclaration(fragment);
  }

  @override
  ElementDeclarationResultImpl? getFragmentDeclaration(Fragment fragment) {
    var nameOffset = _getFragmentNameOffset(fragment);
    if (fragment is LibraryFragment || nameOffset == null) {
      return null;
    }

    var elementPath = fragment.libraryFragment!.source.fullName;
    var unitResult = units.firstWhere(
      (r) => r.path == elementPath,
      orElse: () {
        var elementStr = fragment.element.displayName.ifNotEmptyOrElse(
          fragment.element.displayString(),
        );
        throw ArgumentError(
          'Element (${fragment.runtimeType}) $elementStr is '
          'not defined in this library.',
        );
      },
    );

    var locator = DeclarationByElementLocator(fragment, nameOffset);
    unitResult.unit.accept(locator);
    var declaration = locator.result;

    if (declaration == null) {
      return null;
    }

    return ElementDeclarationResultImpl(
      fragment,
      declaration,
      null,
      unitResult,
    );
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
  final CompilationUnitImpl unit;

  @override
  final List<Diagnostic> diagnostics;

  ResolvedUnitResultImpl({
    required super.session,
    required super.fileState,
    required this.unit,
    required this.diagnostics,
  });

  @override
  List<Diagnostic> get errors => diagnostics;

  @override
  bool get exists => fileState.exists;

  @override
  LibraryElementImpl get libraryElement {
    return libraryFragment.element;
  }

  @override
  @Deprecated('Use libraryElement instead')
  LibraryElement get libraryElement2 => libraryElement;

  @override
  LibraryFragmentImpl get libraryFragment => unit.declaredFragment!;

  @override
  TypeProviderImpl get typeProvider => libraryElement.typeProvider;

  @override
  TypeSystemImpl get typeSystem => libraryElement.typeSystem;
}

class UnitElementResultImpl extends FileResultImpl
    implements UnitElementResult {
  @override
  final LibraryFragmentImpl fragment;

  UnitElementResultImpl({
    required super.session,
    required super.fileState,
    required this.fragment,
  });
}
