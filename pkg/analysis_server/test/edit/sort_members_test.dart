// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:plugin/manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortMembersTest);
  });
}

@reflectiveTest
class SortMembersTest extends AbstractAnalysisTest {
  SourceFileEdit fileEdit;

  @override
  bool get enableNewAnalysisDriver => false;

  @override
  void setUp() {
    super.setUp();
    createProject();
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins([server.serverPlugin]);
    handler = new EditDomainHandler(server);
  }

  test_BAD_doesNotExist() async {
    Request request =
        new EditSortMembersParams('/no/such/file.dart').toRequest('0');
    Response response = await waitResponse(request);
    expect(response,
        isResponseFailure('0', RequestErrorCode.SORT_MEMBERS_INVALID_FILE));
  }

  test_BAD_hasParseError() async {
    addTestFile('''
main() {
  print()
}
''');
    Request request = new EditSortMembersParams(testFile).toRequest('0');
    Response response = await waitResponse(request);
    expect(response,
        isResponseFailure('0', RequestErrorCode.SORT_MEMBERS_PARSE_ERRORS));
  }

  test_BAD_notDartFile() async {
    Request request =
        new EditSortMembersParams('/not-a-Dart-file.txt').toRequest('0');
    Response response = await waitResponse(request);
    expect(response,
        isResponseFailure('0', RequestErrorCode.SORT_MEMBERS_INVALID_FILE));
  }

  test_OK_afterWaitForAnalysis() async {
    addTestFile('''
class C {}
class A {}
class B {}
''');
    await waitForTasksFinished();
    return _assertSorted(r'''
class A {}
class B {}
class C {}
''');
  }

  test_OK_classMembers_method() async {
    addTestFile('''
class A {
  c() {}
  a() {}
  b() {}
}
''');
    return _assertSorted(r'''
class A {
  a() {}
  b() {}
  c() {}
}
''');
  }

  test_OK_directives() async {
    addTestFile('''
library lib;

export 'dart:bbb';
import 'dart:bbb';
export 'package:bbb/bbb.dart';
import 'bbb/bbb.dart';
export 'dart:aaa';
export 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
export 'aaa/aaa.dart';
export 'bbb/bbb.dart';
import 'dart:aaa';
import 'package:aaa/aaa.dart';
import 'aaa/aaa.dart';
part 'bbb/bbb.dart';
part 'aaa/aaa.dart';

main() {
}
''');
    return _assertSorted(r'''
library lib;

import 'dart:aaa';
import 'dart:bbb';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';

import 'aaa/aaa.dart';
import 'bbb/bbb.dart';

export 'dart:aaa';
export 'dart:bbb';

export 'package:aaa/aaa.dart';
export 'package:bbb/bbb.dart';

export 'aaa/aaa.dart';
export 'bbb/bbb.dart';

part 'aaa/aaa.dart';
part 'bbb/bbb.dart';

main() {
}
''');
  }

  test_OK_directives_withAnnotation() async {
    addTestFile('''
library lib;

export 'dart:bbb';
@MyAnnotation(1)
@MyAnnotation(2)
import 'dart:bbb';
@MyAnnotation(3)
export 'dart:aaa';
import 'dart:aaa';

class MyAnnotation {
  const MyAnnotation(_);
}
''');
    return _assertSorted(r'''
library lib;

import 'dart:aaa';
@MyAnnotation(1)
@MyAnnotation(2)
import 'dart:bbb';

@MyAnnotation(3)
export 'dart:aaa';
export 'dart:bbb';

class MyAnnotation {
  const MyAnnotation(_);
}
''');
  }

  @failingTest
  test_OK_genericFunctionTypeInComments() async {
    addFile(
        projectPath + '/analysis_options.yaml',
        '''
analyzer:
  strong-mode: true
''');
    addTestFile('''
class C {
  void caller() {
    Super s = new Super();
    takesSub(s); // <- No warning
  }

  void takesSub(Sub s) {}
}

class Sub extends Super {}

class Super {}

typedef dynamic Func(String x, String y);

Function/*=F*/ allowInterop/*<F extends Function>*/(Function/*=F*/ f) => null;

Func bar(Func f) {
  return allowInterop(f);
}
''');
    return _assertSorted('''
Function/*=F*/ allowInterop/*<F extends Function>*/(Function/*=F*/ f) => null;

Func bar(Func f) {
  return allowInterop(f);
}

typedef dynamic Func(String x, String y);

class C {
  void caller() {
    Super s = new Super();
    takesSub(s); // <- No warning
  }

  void takesSub(Sub s) {}
}

class Sub extends Super {}

class Super {}
''');
  }

  test_OK_unitMembers_class() async {
    addTestFile('''
class C {}
class A {}
class B {}
''');
    return _assertSorted(r'''
class A {}
class B {}
class C {}
''');
  }

  Future _assertSorted(String expectedCode) async {
    await _requestSort();
    String resultCode = SourceEdit.applySequence(testCode, fileEdit.edits);
    expect(resultCode, expectedCode);
  }

  Future _requestSort() async {
    Request request = new EditSortMembersParams(testFile).toRequest('0');
    Response response = await waitResponse(request);
    var result = new EditSortMembersResult.fromResponse(response);
    fileEdit = result.edit;
  }
}
