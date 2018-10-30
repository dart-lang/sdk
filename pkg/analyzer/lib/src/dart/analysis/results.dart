// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// TODO(scheglov) Rename to AnalysisResultImpl
abstract class BaseAnalysisResult implements AnalysisResult {
  @override
  final AnalysisSession session;

  @override
  final String path;

  @override
  final Uri uri;

  BaseAnalysisResult(this.session, this.path, this.uri);
}

class ResolvedLibraryResultImpl extends BaseAnalysisResult
    implements ResolvedLibraryResult {
  @override
  final LibraryElement element;

  @override
  final ResultState state = ResultState.VALID;

  @override
  final TypeProvider typeProvider;

  @override
  final List<ResolveResult> units;

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
