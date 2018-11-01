// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
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
  final ResultState state = ResultState.VALID;

  @override
  final TypeProvider typeProvider;

  @override
  final List<ResolvedUnitResult> units;

  ResolvedLibraryResultImpl(AnalysisSession session, String path, Uri uri,
      this.element, this.typeProvider, this.units)
      : super(session, path, uri);

  @override
  AstNode getElementDeclaration(Element element) {
    if (element.library != this.element) {
      throw ArgumentError('Element (${element.runtimeType}) $element is not '
          'defined in this library.');
    }

    if (element.isSynthetic || element.nameOffset == -1) {
      return null;
    }

    var elementPath = element.source.fullName;
    var unitResult = units.firstWhere((r) => r.path == elementPath);
    var locator = NodeLocator(element.nameOffset);
    return locator.searchWithin(unitResult.unit)?.parent;
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
