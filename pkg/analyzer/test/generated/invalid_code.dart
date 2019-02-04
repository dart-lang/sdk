// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';

import 'resolver_test_case.dart';

/**
 * Tests for various end-to-end cases when invalid code caused exceptions
 * in one or another Analyzer subsystem. We are not interested not in specific
 * errors generated, but we want to make sure that there is at least one,
 * and analysis finishes without exceptions.
 */
abstract class InvalidCodeTest extends ResolverTestCase {
  @override
  AnalysisOptions get defaultAnalysisOptions => new AnalysisOptionsImpl();

  /**
   * This code results in a method with the empty name, and the default
   * constructor, which also has the empty name. The `Map` in `f` initializer
   * references the empty name.
   */
  test_constructorAndMethodNameCollision() async {
    await _assertCanBeAnalyzed('''
class C {
  var f = { : };
  @ ();
}
''');
  }

  test_genericFunction_asTypeArgument_ofUnresolvedClass() async {
    await _assertCanBeAnalyzed(r'''
C<int Function()> c;
''');
  }

  Future<void> _assertCanBeAnalyzed(String text) async {
    Source source = addSource(text);
    var analysisResult = await computeAnalysisResult(source);
    expect(analysisResult.errors, isNotEmpty);
  }
}
