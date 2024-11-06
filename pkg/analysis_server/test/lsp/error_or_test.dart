// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorOrTest);
    defineReflectiveTests(ErrorOrRecord2ExtensionTest);
    defineReflectiveTests(ErrorOrRecord3ExtensionTest);
    defineReflectiveTests(ErrorOrRecord4ExtensionTest);
  });
}

final errorX = error(ErrorCodes.ParseError, 'x');

final errorY = error(ErrorCodes.ParseError, 'y');

@reflectiveTest
class ErrorOrRecord2ExtensionTest {
  test_ifResults_error() {
    var called = false;
    (success(1), errorX).ifResults((_, _) => called = true);
    expect(called, isFalse);
  }

  test_ifResults_result() {
    var called = false;
    (success(1), success(2)).ifResults((a, b) {
      expect(a, 1);
      expect(b, 2);
      called = true;
    });
    expect(called, isTrue);
  }

  test_mapResults_error() async {
    var result = await (success(1), errorX).mapResults((a, b) async {
      throw 'function should not be called';
    });
    expect(result, errorX);
  }

  test_mapResults_result() async {
    var result = await (success(1), success(2)).mapResults((a, b) async {
      expect(a, 1);
      expect(b, 2);
      return success(100);
    });
    expect(result.result, 100);
  }

  test_mapResultsSync_error() async {
    var result = (success(1), errorX).mapResultsSync((a, b) {
      throw 'function should not be called';
    });
    expect(result, errorX);
  }

  test_mapResultsSync_result() async {
    var result = (success(1), success(2)).mapResultsSync((a, b) {
      expect(a, 1);
      expect(b, 2);
      return success(100);
    });
    expect(result.result, 100);
  }
}

@reflectiveTest
class ErrorOrRecord3ExtensionTest {
  test_ifResults_error() {
    var called = false;
    (success(1), success(1), errorX).ifResults((_, _, _) => called = true);
    expect(called, isFalse);
  }

  test_ifResults_result() {
    var called = false;
    (success(1), success(2), success(3)).ifResults((a, b, c) {
      expect(a, 1);
      expect(b, 2);
      expect(c, 3);
      called = true;
    });
    expect(called, isTrue);
  }

  test_mapResults_error() async {
    var result = await (success(1), success(2), errorX).mapResults((
      a,
      b,
      c,
    ) async {
      throw 'function should not be called';
    });
    expect(result, errorX);
  }

  test_mapResults_result() async {
    var result = await (success(1), success(2), success(3)).mapResults((
      a,
      b,
      c,
    ) async {
      expect(a, 1);
      expect(b, 2);
      expect(c, 3);
      return success(100);
    });
    expect(result.result, 100);
  }

  test_mapResultsSync_error() async {
    var result = (success(1), success(2), errorX).mapResultsSync((a, b, c) {
      throw 'function should not be called';
    });
    expect(result, errorX);
  }

  test_mapResultsSync_result() async {
    var result = (success(1), success(2), success(3)).mapResultsSync((a, b, c) {
      expect(a, 1);
      expect(b, 2);
      expect(c, 3);
      return success(100);
    });
    expect(result.result, 100);
  }
}

@reflectiveTest
class ErrorOrRecord4ExtensionTest {
  test_ifResults_error() {
    var called = false;
    (
      success(1),
      success(1),
      success(1),
      errorX,
    ).ifResults((_, _, _, _) => called = true);
    expect(called, isFalse);
  }

  test_ifResults_result() {
    var called = false;
    (success(1), success(2), success(3), success(4)).ifResults((a, b, c, d) {
      expect(a, 1);
      expect(b, 2);
      expect(c, 3);
      expect(d, 4);
      called = true;
    });
    expect(called, isTrue);
  }

  test_mapResults_error() async {
    var result = await (success(1), success(2), success(3), errorX).mapResults((
      a,
      b,
      c,
      d,
    ) async {
      throw 'function should not be called';
    });
    expect(result, errorX);
  }

  test_mapResults_result() async {
    var result = await (
      success(1),
      success(2),
      success(3),
      success(4),
    ).mapResults((a, b, c, d) async {
      expect(a, 1);
      expect(b, 2);
      expect(c, 3);
      expect(d, 4);
      return success(100);
    });
    expect(result.result, 100);
  }

  test_mapResultsSync_error() async {
    var result = (success(1), success(2), success(3), errorX).mapResultsSync((
      a,
      b,
      c,
      d,
    ) {
      throw 'function should not be called';
    });
    expect(result, errorX);
  }

  test_mapResultsSync_result() async {
    var result = (
      success(1),
      success(2),
      success(3),
      success(4),
    ).mapResultsSync((a, b, c, d) {
      expect(a, 1);
      expect(b, 2);
      expect(c, 3);
      expect(d, 4);
      return success(100);
    });
    expect(result.result, 100);
  }
}

@reflectiveTest
class ErrorOrTest {
  test_error_forError() {
    expect(errorX.error.message, 'x');
  }

  test_error_forResult() {
    expect(() => success(1).error, throwsStateError);
    expect(() => success(null).error, throwsStateError);
  }

  test_errorOrNull_error() {
    expect(errorX.errorOrNull, isNotNull);
    expect(errorX.errorOrNull!.message, 'x');
  }

  test_errorOrNull_null() {
    expect(success(1).errorOrNull, isNull);
    expect(success(null).errorOrNull, isNull);
  }

  test_ifError_error() {
    var called = false;
    errorX.ifError((_) => called = true);
    expect(called, isTrue);
  }

  test_ifError_result() {
    var called = false;
    success(1).ifError((_) => called = true);
    expect(called, isFalse);
  }

  test_ifResult_error() {
    var called = false;
    errorX.ifResult((_) => called = true);
    expect(called, isFalse);
  }

  test_ifResult_result() {
    var called = false;
    success(1).ifResult((_) => called = true);
    expect(called, isTrue);
  }

  test_isErrorisResult_error() {
    expect(errorX.isError, isTrue);
    expect(errorX.isResult, isFalse);
  }

  test_isErrorisResult_result() {
    expect(success(1).isError, isFalse);
    expect(success(1).isResult, isTrue);
    expect(success(null).isError, isFalse);
    expect(success(null).isResult, isTrue);
  }

  test_iterableExtension_errorOrResults_noError() {
    expect([success(1), success('x')].errorOrResults.result, [1, 'x']);
  }

  test_iterableExtension_errorOrResults_oneError() {
    expect([success(1), errorX].errorOrResults, errorX);
  }

  test_iterableExtension_errorOrResults_twoErrors() {
    expect([errorX, errorY].errorOrResults, errorX);
  }

  test_mapResult_error() async {
    var result = await errorX.mapResult((_) async => success(1));
    expect(result.isError, isTrue);
  }

  test_mapResult_result() async {
    var result = await success(1).mapResult((_) async => success(2));
    expect(result.isError, isFalse);
    expect(result.result, 2);
  }

  test_mapResultSync_error() async {
    var result = errorX.mapResultSync((_) => success(1));
    expect(result.isError, isTrue);
  }

  test_mapResultSync_result() async {
    var result = success(1).mapResultSync((_) => success(2));
    expect(result.isError, isFalse);
    expect(result.result, 2);
  }

  test_result_forError() {
    expect(() => errorX.result, throwsStateError);
  }

  test_result_forResult() {
    expect(success(1).result, 1);
    expect(success('x').result, 'x');
    expect(success(null).result, isNull);
  }

  test_resultOrNull_null() {
    expect(errorX.resultOrNull, null);
  }

  test_resultOrNull_nullResult() {
    expect(success(null).resultOrNull, null);
  }

  test_resultOrNull_result() {
    expect(success(1).resultOrNull, 1);
    expect(success('x').resultOrNull, 'x');
  }
}
