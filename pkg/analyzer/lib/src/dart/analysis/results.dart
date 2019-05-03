// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/generated/resolver.dart';

abstract class AnalysisResultImpl implements AnalysisResult {
  @override
  final AnalysisSession session;

  @override
  final String path;

  @override
  final Uri uri;

  AnalysisResultImpl(this.session, this.path, this.uri);
}

class ElementDeclarationResultImpl implements ElementDeclarationResult {
  @override
  final Element element;

  @override
  final AstNode node;

  @override
  final ParsedUnitResult parsedUnit;

  @override
  final ResolvedUnitResult resolvedUnit;

  ElementDeclarationResultImpl(
      this.element, this.node, this.parsedUnit, this.resolvedUnit);
}

class ErrorsResultImpl extends FileResultImpl implements ErrorsResult {
  @override
  final List<AnalysisError> errors;

  ErrorsResultImpl(AnalysisSession session, String path, Uri uri,
      LineInfo lineInfo, bool isPart, this.errors)
      : super(session, path, uri, lineInfo, isPart);
}

class FileResultImpl extends AnalysisResultImpl implements FileResult {
  @override
  final LineInfo lineInfo;

  @override
  final bool isPart;

  FileResultImpl(
      AnalysisSession session, String path, Uri uri, this.lineInfo, this.isPart)
      : super(session, path, uri);

  @override
  ResultState get state => ResultState.VALID;
}

class ParsedLibraryResultImpl extends AnalysisResultImpl
    implements ParsedLibraryResult {
  @override
  final List<ParsedUnitResult> units;

  ParsedLibraryResultImpl(
      AnalysisSession session, String path, Uri uri, this.units)
      : super(session, path, uri);

  ParsedLibraryResultImpl.external(AnalysisSession session, Uri uri)
      : this(session, null, uri, null);

  @Deprecated('This factory exists temporary until AnalysisSession migration.')
  factory ParsedLibraryResultImpl.tmp(LibraryElement library) {
    var session = library.session;
    if (session != null) {
      return session.getParsedLibraryByElement(library);
    } else {
      var analysisContext = library.context;
      var units = <ParsedUnitResult>[];
      for (var unitElement in library.units) {
        var unitSource = unitElement.source;

        if (!analysisContext.exists(unitSource)) {
          continue;
        }

        var content = analysisContext.getContents(unitSource).data;
        var lineInfo = analysisContext.getLineInfo(unitSource);
        var unit = analysisContext.parseCompilationUnit(unitSource);
        units.add(ParsedUnitResultImpl(
            null,
            unitSource.fullName,
            unitSource.uri,
            content,
            lineInfo,
            unitSource != library.source,
            unit, const []));
      }
      var libraryPath = library.source.fullName;
      return ParsedLibraryResultImpl(
          null, libraryPath, library.source.uri, units);
    }
  }

  @override
  ResultState get state {
    if (path == null) {
      return ResultState.NOT_A_FILE;
    }
    return ResultState.VALID;
  }

  @override
  ElementDeclarationResult getElementDeclaration(Element element) {
    if (state != ResultState.VALID) {
      throw StateError('The result is not valid: $state');
    }

    var elementPath = element.source.fullName;
    var unitResult = units.firstWhere(
      (r) => r.path == elementPath,
      orElse: () {
        throw ArgumentError('Element (${element.runtimeType}) $element is not '
            'defined in this library.');
      },
    );

    if (element.isSynthetic || element.nameOffset == -1) {
      return null;
    }

    var locator = _DeclarationByElementLocator(element);
    unitResult.unit.accept(locator);
    var declaration = locator.result;

    return ElementDeclarationResultImpl(element, declaration, unitResult, null);
  }
}

class ParsedUnitResultImpl extends FileResultImpl implements ParsedUnitResult {
  @override
  final String content;

  @override
  final CompilationUnit unit;

  @override
  final List<AnalysisError> errors;

  ParsedUnitResultImpl(AnalysisSession session, String path, Uri uri,
      this.content, LineInfo lineInfo, bool isPart, this.unit, this.errors)
      : super(session, path, uri, lineInfo, isPart);

  @override
  ResultState get state => ResultState.VALID;
}

class ResolvedLibraryResultImpl extends AnalysisResultImpl
    implements ResolvedLibraryResult {
  @override
  final LibraryElement element;

  @override
  final TypeProvider typeProvider;

  @override
  final List<ResolvedUnitResult> units;

  ResolvedLibraryResultImpl(AnalysisSession session, String path, Uri uri,
      this.element, this.typeProvider, this.units)
      : super(session, path, uri);

  ResolvedLibraryResultImpl.external(AnalysisSession session, Uri uri)
      : this(session, null, uri, null, null, null);

  @override
  ResultState get state {
    if (path == null) {
      return ResultState.NOT_A_FILE;
    }
    return ResultState.VALID;
  }

  @override
  ElementDeclarationResult getElementDeclaration(Element element) {
    if (state != ResultState.VALID) {
      throw StateError('The result is not valid: $state');
    }

    var elementPath = element.source.fullName;
    var unitResult = units.firstWhere(
      (r) => r.path == elementPath,
      orElse: () {
        throw ArgumentError('Element (${element.runtimeType}) $element is not '
            'defined in this library.');
      },
    );

    if (element.isSynthetic || element.nameOffset == -1) {
      return null;
    }

    var locator = _DeclarationByElementLocator(element);
    unitResult.unit.accept(locator);
    var declaration = locator.result;

    return ElementDeclarationResultImpl(element, declaration, null, unitResult);
  }

  @Deprecated('This method exists temporary until AnalysisSession migration.')
  static Future<ResolvedLibraryResult> tmp(LibraryElement library) async {
    var session = library.session;
    if (session != null) {
      return session.getResolvedLibraryByElement(library);
    } else {
      var units = <ResolvedUnitResult>[];
      var analysisContext = library.context;
      for (var unitElement in library.units) {
        var unitSource = unitElement.source;

        if (!analysisContext.exists(unitSource)) {
          continue;
        }

        var path = unitSource.fullName;
        var content = analysisContext.getContents(unitSource).data;
        var lineInfo = analysisContext.getLineInfo(unitSource);
        var unit = analysisContext.resolveCompilationUnit(unitSource, library);
        units.add(ResolvedUnitResultImpl(null, path, unitSource.uri, true,
            content, lineInfo, unitSource != library.source, unit, const []));
      }
      var libraryPath = library.source.fullName;
      return ResolvedLibraryResultImpl(null, libraryPath, library.source.uri,
          library, library.context.typeProvider, units);
    }
  }
}

class ResolvedUnitResultImpl extends FileResultImpl
    implements ResolvedUnitResult {
  /// Return `true` if the file exists.
  final bool exists;

  @override
  final String content;

  @override
  final CompilationUnit unit;

  @override
  final List<AnalysisError> errors;

  ResolvedUnitResultImpl(
      AnalysisSession session,
      String path,
      Uri uri,
      this.exists,
      this.content,
      LineInfo lineInfo,
      bool isPart,
      this.unit,
      this.errors)
      : super(session, path, uri, lineInfo, isPart);

  @override
  LibraryElement get libraryElement => unit.declaredElement.library;

  @override
  ResultState get state => exists ? ResultState.VALID : ResultState.NOT_A_FILE;

  @override
  TypeProvider get typeProvider => unit.declaredElement.context.typeProvider;

  @override
  TypeSystem get typeSystem => unit.declaredElement.context.typeSystem;
}

class UnitElementResultImpl extends AnalysisResultImpl
    implements UnitElementResult {
  @override
  final String signature;

  @override
  final CompilationUnitElement element;

  UnitElementResultImpl(AnalysisSession session, String path, Uri uri,
      this.signature, this.element)
      : super(session, path, uri);

  @override
  ResultState get state => ResultState.VALID;
}

class _DeclarationByElementLocator extends GeneralizingAstVisitor<void> {
  final Element element;
  AstNode result;

  _DeclarationByElementLocator(this.element);

  @override
  void visitNode(AstNode node) {
    if (result != null) return;

    if (element is ClassElement) {
      if (node is ClassOrMixinDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      } else if (node is ClassTypeAlias) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      } else if (node is EnumDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      }
    } else if (element is ConstructorElement) {
      if (node is ConstructorDeclaration) {
        if (node.name != null) {
          if (_hasOffset(node.name)) {
            result = node;
          }
        } else {
          if (_hasOffset(node.returnType)) {
            result = node;
          }
        }
      }
    } else if (element is FieldElement) {
      if (node is EnumConstantDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      } else if (node is VariableDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      }
    } else if (element is FunctionElement) {
      if (node is FunctionDeclaration && _hasOffset(node.name)) {
        result = node;
      }
    } else if (element is LocalVariableElement) {
      if (node is VariableDeclaration && _hasOffset(node.name)) {
        result = node;
      }
    } else if (element is MethodElement) {
      if (node is MethodDeclaration && _hasOffset(node.name)) {
        result = node;
      }
    } else if (element is ParameterElement) {
      if (node is FormalParameter && _hasOffset(node.identifier)) {
        result = node;
      }
    } else if (element is PropertyAccessorElement) {
      if (node is FunctionDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      } else if (node is MethodDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      }
    } else if (element is TopLevelVariableElement) {
      if (node is VariableDeclaration && _hasOffset(node.name)) {
        result = node;
      }
    }

    super.visitNode(node);
  }

  bool _hasOffset(AstNode node) {
    return node?.offset == element.nameOffset;
  }
}
