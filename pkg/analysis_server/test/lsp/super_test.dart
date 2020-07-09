// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperTest);
  });
}

@reflectiveTest
class SuperTest extends AbstractLspAnalysisServerTest {
  Future<void> test_className() async {
    final content = '''
class A {}

class [[B]] extends A {}

class C^ extends B {}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getSuper(
      mainFileUri,
      positionFromMarker(content),
    );

    expect(
        res,
        equals(Location(
            uri: mainFileUri.toString(), range: rangeFromMarkers(content))));
  }

  Future<void> test_insideClass() async {
    final content = '''
class A {}

class [[B]] extends A {}

class C extends B {
  ^
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getSuper(
      mainFileUri,
      positionFromMarker(content),
    );

    expect(
        res,
        equals(Location(
            uri: mainFileUri.toString(), range: rangeFromMarkers(content))));
  }

  Future<void> test_insideMethod() async {
    final content = '''
class A {
  void [[foo]]() {}
}

class B extends A {}

class C extends B {
  @override
  void foo() {
    // fo^oC
  }
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getSuper(
      mainFileUri,
      positionFromMarker(content),
    );

    expect(
        res,
        equals(Location(
            uri: mainFileUri.toString(), range: rangeFromMarkers(content))));
  }

  Future<void> test_methodName() async {
    final content = '''
class A {
  void [[foo]]() {}
}

class B extends A {}

class C extends B {
  @override
  void fo^o() {
    // fooC
  }
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getSuper(
      mainFileUri,
      positionFromMarker(content),
    );

    expect(
        res,
        equals(Location(
            uri: mainFileUri.toString(), range: rangeFromMarkers(content))));
  }

  Future<void> test_methodReturnType() async {
    final content = '''
class A {
  void [[foo]]() {}
}

class B extends A {}

class C extends B {
  @override
  vo^id foo() {
    // fooC
  }
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getSuper(
      mainFileUri,
      positionFromMarker(content),
    );

    expect(
        res,
        equals(Location(
            uri: mainFileUri.toString(), range: rangeFromMarkers(content))));
  }
}
