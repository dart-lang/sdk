// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementationTest);
  });
}

@reflectiveTest
class ImplementationTest extends AbstractLspAnalysisServerTest {
  test_class_excludesSelf() => _testMarkedContent('''
      abstract class ^[[A]] {}
      class B extends A {}
      class C extends A {}
    ''', shouldMatch: false);

  test_class_excludesSuper() => _testMarkedContent('''
      abstract class [[A]] {}
      class ^B extends A {}
      class C extends A {}
    ''', shouldMatch: false);

  test_class_sub() => _testMarkedContent('''
      abstract class ^A {}
      class [[B]] extends A {}
      class [[C]] extends A {}
    ''');

  test_class_subSub() => _testMarkedContent('''
      abstract class ^A {}
      class [[B]] extends A {}
      class [[C]] extends A {}
      class [[D]] extends B {}
      class [[E]] extends B {}
      class [[F]] extends E {}
    ''');

  test_emptyResults() async {
    final content = '';

    await initialize();
    await openFile(mainFileUri, content);
    final res = await getImplementations(
      mainFileUri,
      startOfDocPos,
    );

    expect(res, isEmpty);
  }

  test_method_excludesClassesWithoutImplementations() => _testMarkedContent('''
      abstract class A {
        void ^b();
      }

      class B extends A {}

      class [[E]] extends B {}
    ''', shouldMatch: false);

  test_method_excludesSelf() => _testMarkedContent('''
      abstract class A {
        void ^[[b]]();
      }

      class B extends A {
        void b() {}
      }
    ''', shouldMatch: false);

  test_method_excludesSuper() => _testMarkedContent('''
      abstract class A {
        void [[b]]();
      }

      class B extends A {
        void ^b() {}
      }
    ''', shouldMatch: false);

  test_method_fromCallSite() => _testMarkedContent('''
      abstract class A {
        void b();
      }

      class B extends A {
        void [[b]]() {}
      }

      class C extends A {
        void [[b]]() {}
      }

      class D extends B {
        void [[b]]() {}
      }

      class E extends B {}

      class F extends E {
        void [[b]]() {}
      }

      void fromCallSite() {
        A e = new E();
        e.^b();
      }
    ''');

  test_method_sub() => _testMarkedContent('''
      abstract class A {
        void ^b();
      }

      class B extends A {
        void [[b]]() {}
      }

      class C extends A {
        void [[b]]() {}
      }
    ''');

  test_method_subSub() => _testMarkedContent('''
      abstract class A {
        void ^b();
      }

      class B extends A {
        void [[b]]() {}
      }

      class D extends B {
        void [[b]]() {}
      }

      class E extends B {}

      class F extends E {
        void [[b]]() {}
      }
    ''');

  test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final res = await getImplementations(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  /// Takes an input string that contains ^ at the location to invoke the
  /// textDocument/implementations command and has ranges marked with
  /// `[[brackets]]` that are expected to be included (or not, if [shouldMatch]
  /// is set to `false`) in the results.
  Future<void> _testMarkedContent(String content,
      {bool shouldMatch = true}) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final res = await getImplementations(
      mainFileUri,
      positionFromMarker(content),
    );

    final expectedLocations = rangesFromMarkers(content)
        .map((r) => Location(mainFileUri.toString(), r));

    if (shouldMatch) {
      expect(res, equals(expectedLocations));
    } else {
      expectedLocations.forEach((l) => expect(res, isNot(contains(res))));
    }
  }
}
