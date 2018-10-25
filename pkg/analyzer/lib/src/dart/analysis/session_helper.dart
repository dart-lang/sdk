// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

/// A wrapper around [AnalysisSession] that provides additional utilities.
///
/// The methods in this class that return analysis results will throw an
/// [InconsistentAnalysisException] if the result to be returned might be
/// inconsistent with any previously returned results.
class AnalysisSessionHelper {
  final AnalysisSession session;

  AnalysisSessionHelper(this.session);

  /// Return the [ClassElement] with the given [className] that is exported
  /// from the library with the given [libraryUri], or `null` if the library
  /// does not export a class with such name.
  Future<ClassElement> getClass(String libraryUri, String className) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var libraryElement = await session.getLibraryByUri(libraryUri);
    var element = libraryElement.exportNamespace.get(className);
    if (element is ClassElement) {
      return element;
    } else {
      return null;
    }
  }

  /// Return the declaration of the [element], or `null` is the [element]
  /// is synthetic.
  Future<ElementDeclarationResult> getElementDeclaration(
      Element element) async {
    if (element.isSynthetic || element.nameOffset == -1) {
      return null;
    }

    var path = element.source.fullName;
    var resolveResult = await session.getResolvedAst(path);
    var unit = resolveResult.unit;
    var locator = NodeLocator(element.nameOffset);
    var declaration = locator.searchWithin(unit)?.parent;

    return ElementDeclarationResult(resolveResult, declaration);
  }

  /// Return the [PropertyAccessorElement] with the given [name] that is
  /// exported from the library with the given [uri], or `null` if the
  /// library does not export a top-level accessor with such name.
  Future<PropertyAccessorElement> getTopLevelPropertyAccessor(
      String uri, String name) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var libraryElement = await session.getLibraryByUri(uri);
    var element = libraryElement.exportNamespace.get(name);
    if (element is PropertyAccessorElement) {
      return element;
    } else {
      return null;
    }
  }
}

/// The result of searching an [Element] declaration in the resolved AST for
/// the file where it is defined.
class ElementDeclarationResult {
  final ResolveResult resolveResult;
  final AstNode declaration;

  ElementDeclarationResult(this.resolveResult, this.declaration);
}
