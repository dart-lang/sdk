// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/element/name_union.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementNameUnionTest);
  });
}

@reflectiveTest
class ElementNameUnionTest extends PubPackageResolutionTest {
  test_it() async {
    await _checkLibrary('dart:async');
    await _checkLibrary('dart:core');
    await _checkLibrary('dart:math');
  }

  Future<void> _checkLibrary(String uriStr) async {
    final analysisContext = contextFor(testFile);
    final analysisSession = analysisContext.currentSession;

    final result = await analysisSession.getLibraryByUri(uriStr);
    result as LibraryElementResult;
    final element = result.element;

    final union = ElementNameUnion.forLibrary(element);
    element.accept(
      _ElementVisitor(union),
    );
  }
}

/// Checks that the name of every interesting element is in [union].
class _ElementVisitor extends GeneralizingElementVisitor<void> {
  final ElementNameUnion union;

  _ElementVisitor(this.union);

  @override
  void visitElement(Element element) {
    final enclosing = element.enclosingElement2;
    if (enclosing is CompilationUnitElement ||
        element is FieldElement ||
        element is MethodElement ||
        element is PropertyAccessorElement) {
      final name = element.name;
      if (name != null) {
        expect(union.contains(name), isTrue, reason: name);
        // Might fail, but probably we don't have such names.
        expect(union.contains('Z$name'), isFalse, reason: name);
      }
    }

    super.visitElement(element);
  }
}
