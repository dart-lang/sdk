// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSessionHelperTest);
  });
}

@reflectiveTest
class AnalysisSessionHelperTest extends BaseAnalysisDriverTest {
  AnalysisSessionHelper sessionHelper;

  @override
  void setUp() {
    super.setUp();
    sessionHelper = new AnalysisSessionHelper(driver.currentSession);
  }

  test_getClass_defined() async {
    var path = _p('/c.dart');
    var file = provider.newFile(path, r'''
class C {}
int v = 0;
''');
    String uri = file.toUri().toString();

    var element = await sessionHelper.getClass(uri, 'C');
    expect(element, isNotNull);
    expect(element.displayName, 'C');
  }

  test_getClass_defined_notClass() async {
    var path = _p('/c.dart');
    var file = provider.newFile(path, r'''
int v = 0;
''');
    String uri = file.toUri().toString();

    var element = await sessionHelper.getClass(uri, 'v');
    expect(element, isNull);
  }

  test_getClass_exported() async {
    var a = _p('/a.dart');
    var b = _p('/b.dart');
    provider.newFile(a, r'''
class A {}
''');
    var bFile = provider.newFile(b, r'''
export 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await sessionHelper.getClass(bUri, 'A');
    expect(element, isNotNull);
    expect(element.displayName, 'A');
  }

  test_getClass_imported() async {
    var a = _p('/a.dart');
    var b = _p('/b.dart');
    provider.newFile(a, r'''
class A {}
''');
    var bFile = provider.newFile(b, r'''
import 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await sessionHelper.getClass(bUri, 'A');
    expect(element, isNull);
  }

  test_getTopLevelPropertyAccessor_defined_getter() async {
    var path = _p('/test.dart');
    var file = provider.newFile(path, r'''
int get a => 0;
''');
    String uri = file.toUri().toString();

    var element = await sessionHelper.getTopLevelPropertyAccessor(uri, 'a');
    expect(element, isNotNull);
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_defined_setter() async {
    var path = _p('/test.dart');
    var file = provider.newFile(path, r'''
set a(_) {}
''');
    String uri = file.toUri().toString();

    var element = await sessionHelper.getTopLevelPropertyAccessor(uri, 'a=');
    expect(element, isNotNull);
    expect(element.kind, ElementKind.SETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_defined_variable() async {
    var path = _p('/test.dart');
    var file = provider.newFile(path, r'''
int a;
''');
    String uri = file.toUri().toString();

    var element = await sessionHelper.getTopLevelPropertyAccessor(uri, 'a');
    expect(element, isNotNull);
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_exported() async {
    var a = _p('/a.dart');
    var b = _p('/b.dart');
    provider.newFile(a, r'''
int a;
''');
    var bFile = provider.newFile(b, r'''
export 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await sessionHelper.getTopLevelPropertyAccessor(bUri, 'a');
    expect(element, isNotNull);
    expect(element.kind, ElementKind.GETTER);
    expect(element.displayName, 'a');
  }

  test_getTopLevelPropertyAccessor_imported() async {
    var a = _p('/a.dart');
    var b = _p('/b.dart');
    provider.newFile(a, r'''
int a;
''');
    var bFile = provider.newFile(b, r'''
import 'a.dart';
''');
    String bUri = bFile.toUri().toString();

    var element = await sessionHelper.getTopLevelPropertyAccessor(bUri, 'a');
    expect(element, isNull);
  }

  test_getTopLevelPropertyAccessor_notDefined() async {
    var path = _p('/test.dart');
    var file = provider.newFile(path, r'''
int a;
''');
    String uri = file.toUri().toString();

    var element = await sessionHelper.getTopLevelPropertyAccessor(uri, 'b');
    expect(element, isNull);
  }

  test_getTopLevelPropertyAccessor_notPropertyAccessor() async {
    var path = _p('/test.dart');
    var file = provider.newFile(path, r'''
int a() {}
''');
    String uri = file.toUri().toString();

    var element = await sessionHelper.getTopLevelPropertyAccessor(uri, 'a');
    expect(element, isNull);
  }

  /// Return the [provider] specific path for the given Posix [path].
  String _p(String path) => provider.convertPath(path);
}
