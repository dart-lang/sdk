// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/dependencies/reachable_source_collector.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReachableSourceCollectorTest);
  });
}

@reflectiveTest
class ReachableSourceCollectorTest extends AbstractContextTest {
  Map<String, List<String>> importsFor(Source source) =>
      new ReachableSourceCollector(source, null).collectSources();

  test_null_context() {
    Source lib = addSource('/lib.dart', '');
    expect(() => new ReachableSourceCollector(lib, null),
        throwsA(new isInstanceOf<ArgumentError>()));
  }

  @failingTest
  test_null_source() {
    // See https://github.com/dart-lang/sdk/issues/29311
    fail('The analysis.getReachableSources is not implemented.');
    expect(() => new ReachableSourceCollector(null, null),
        throwsA(new isInstanceOf<ArgumentError>()));
  }

  @failingTest
  test_sources() {
    // See https://github.com/dart-lang/sdk/issues/29311
    fail('The analysis.getReachableSources is not implemented.');
    Source lib1 = addSource(
        '/lib1.dart',
        '''
import "lib2.dart";
import "dart:html";''');
    Source lib2 = addSource('/lib2.dart', 'import "lib1.dart";');

    Source lib3 = addSource('/lib3.dart', 'import "lib4.dart";');
    addSource('/lib4.dart', 'import "lib3.dart";');

    Map<String, List<String>> imports = importsFor(lib1);

    // Verify keys.
    expect(
        imports.keys,
        unorderedEquals([
          'dart:_internal',
          'dart:async',
          'dart:core',
          'dart:html',
          'dart:math',
          'file:///lib1.dart',
          'file:///lib2.dart',
        ]));
    // Values.
    expect(imports['file:///lib1.dart'],
        unorderedEquals(['dart:core', 'dart:html', 'file:///lib2.dart']));

    // Check transitivity.
    expect(importsFor(lib2).keys, contains('dart:html'));

    // Cycles should be OK.
    expect(
        importsFor(lib3).keys,
        unorderedEquals([
          'dart:_internal',
          'dart:async',
          'dart:core',
          'dart:math',
          'file:///lib3.dart',
          'file:///lib4.dart'
        ]));
  }
}
