// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementationTest);
  });
}

@reflectiveTest
class ImplementationTest extends AbstractLspAnalysisServerTest {
  Future<void> test_class_excludesSelf() => _testMarkedContent('''
      abstract class ^[!A!] {}
      class B extends A {}
      class C extends A {}
    ''', expectResults: false);

  Future<void> test_class_excludesSuper() => _testMarkedContent('''
      abstract class [!A!] {}
      class ^B extends A {}
      class C extends A {}
    ''', expectResults: false);

  Future<void> test_class_sub() => _testMarkedContent('''
      abstract class ^A {}
      class /*[0*/B/*0]*/ extends A {}
      class /*[1*/C/*1]*/ extends A {}
    ''');

  Future<void> test_class_subSub() => _testMarkedContent('''
      abstract class ^A {}
      class /*[0*/B/*0]*/ extends A {}
      class /*[1*/C/*1]*/ extends A {}
      class /*[2*/D/*2]*/ extends B {}
      class /*[3*/E/*3]*/ extends B {}
      class /*[4*/F/*4]*/ extends E {}
    ''');

  Future<void> test_emptyResults() async {
    final content = '';

    await initialize();
    await openFile(mainFileUri, content);
    final res = await getImplementations(
      mainFileUri,
      startOfDocPos,
    );

    expect(res, isEmpty);
  }

  Future<void> test_getter_overriddenByField() => _testMarkedContent('''
      class B extends A {
        final String? [!a!] = null;
      }

      abstract class A {
        String? get a^;
      }
    ''');

  Future<void> test_method_excludesClassesWithoutImplementations() =>
      _testMarkedContent('''
      abstract class A {
        void ^b();
      }

      class B extends A {}

      class [!E!] extends B {}
    ''', expectResults: false);

  Future<void> test_method_excludesSelf() => _testMarkedContent('''
      abstract class A {
        void ^[!b!]();
      }

      class B extends A {
        void b() {}
      }
    ''', expectResults: false);

  Future<void> test_method_excludesSuper() => _testMarkedContent('''
      abstract class A {
        void [!b!]();
      }

      class B extends A {
        void ^b() {}
      }
    ''', expectResults: false);

  Future<void> test_method_fromCallSite() => _testMarkedContent('''
      abstract class A {
        void b();
      }

      class B extends A {
        void /*[0*/b/*0]*/() {}
      }

      class C extends A {
        void /*[1*/b/*1]*/() {}
      }

      class D extends B {
        void /*[2*/b/*2]*/() {}
      }

      class E extends B {}

      class F extends E {
        void /*[3*/b/*3]*/() {}
      }

      void fromCallSite() {
        A e = new E();
        e.^b();
      }
    ''');

  Future<void> test_method_startOfParameterList() => _testMarkedContent('''
      abstract class A {
        void m^();
      }

      class B extends A {
        void [!m!]() {}
      }
    ''');

  Future<void> test_method_startOfTypeParameterList() => _testMarkedContent('''
      abstract class A {
        void m^<T>();
      }

      class B extends A {
        void [!m!]<T>() {}
      }
    ''');

  Future<void> test_method_sub() => _testMarkedContent('''
      abstract class A {
        void ^b();
      }

      class B extends A {
        void /*[0*/b/*0]*/() {}
      }

      class C extends A {
        void /*[1*/b/*1]*/() {}
      }
    ''');

  Future<void> test_method_subSub() => _testMarkedContent('''
      abstract class A {
        void ^b();
      }

      class B extends A {
        void /*[0*/b/*0]*/() {}
      }

      class D extends B {
        void /*[1*/b/*1]*/() {}
      }

      class E extends B {}

      class F extends E {
        void /*[2*/b/*2]*/() {}
      }
    ''');

  /// Check that implementations that come from mixins in other files return the
  /// correct location for the implementation.
  Future<void> test_mixins() async {
    final mixinsContent = r'''
import 'main.dart';

mixin MyMixin implements MyInterface {
  String get [!interfaceField!] => '';
}
''';
    final content = r'''
import 'other.dart';

class A with MyMixin {}
class B with MyMixin {}
class C implements MyInterface {
  String get [!interfaceField!] => '';
}

class MyInterface {
  String get interf^aceField;
}
''';

    await _testMarkedContent(content, otherContent: mixinsContent);
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    final res = await getImplementations(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  /// Parses [content] using as [TestCode] and invokes the
  /// `textDocument/implementations` command at the marked location to verify
  /// the marked regions are returned as implementations.
  ///
  /// If [otherContent] is provided, will be written as `other.dart` alongside
  /// the file and any marked regions will also be verified.
  ///
  /// If [expectResults] is `false` then expects none of the ranges marked with
  /// `/*[0*/brackets/*0]*/` to be present in the results instead.
  Future<void> _testMarkedContent(
    String content, {
    String? otherContent,
    bool expectResults = true,
  }) async {
    final otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    final otherFileUri = pathContext.toUri(otherFilePath);
    final code = TestCode.parse(content);
    final otherCode =
        otherContent != null ? TestCode.parse(otherContent) : null;
    if (otherCode != null) {
      newFile(otherFilePath, otherCode.code);
    }

    await initialize();
    await openFile(mainFileUri, code.code);

    final res = await getImplementations(
      mainFileUri,
      code.position.position,
    );

    final expectedLocations = [
      for (final range in code.ranges)
        Location(uri: mainFileUri, range: range.range),
      if (otherCode != null)
        for (final range in otherCode.ranges)
          Location(uri: otherFileUri, range: range.range),
    ];

    if (expectResults) {
      expect(expectedLocations, isNotEmpty);
      expect(res, unorderedEquals(expectedLocations));
    } else {
      for (final location in expectedLocations) {
        expect(res, isNot(contains(location)));
      }
    }
  }
}
