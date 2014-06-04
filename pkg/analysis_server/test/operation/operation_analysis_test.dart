// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.operation.analysis;

import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';

main() {
  groupSep = ' | ';

  group('errorToJson', () {
    runReflectiveTests(Test_errorToJson);
  });
}


@ReflectiveTestCase()
class Test_errorToJson {
  Source source = new SourceMock();
  AnalysisError analysisError = new AnalysisErrorMock();

  setUp() {
    // prepare Source
    when(source.fullName).thenReturn('foo.dart');
    // prepare AnalysisError
    when(analysisError.source).thenReturn(source);
    when(analysisError.errorCode).thenReturn(CompileTimeErrorCode.AMBIGUOUS_EXPORT);
    when(analysisError.message).thenReturn('my message');
    when(analysisError.offset).thenReturn(10);
    when(analysisError.length).thenReturn(20);
  }

  tearDown() {
    source = null;
    analysisError = null;
  }

  test_noCorrection() {
    when(analysisError.correction).thenReturn('my correction');
    Map<String, Object> json = errorToJson(analysisError);
    expect(json, {
      'file': 'foo.dart',
      'errorCode': 'CompileTimeErrorCode.AMBIGUOUS_EXPORT',
      'offset': 10,
      'length': 20,
      'message': 'my message',
      'correction': 'my correction'});
  }

  test_withCorrection() {
    Map<String, Object> json = errorToJson(analysisError);
    expect(json, {
      'file': 'foo.dart',
      'errorCode': 'CompileTimeErrorCode.AMBIGUOUS_EXPORT',
      'offset': 10,
      'length': 20,
      'message': 'my message'});
  }
}


class SourceMock extends TypedMock implements Source {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class AnalysisErrorMock extends TypedMock implements AnalysisError {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
