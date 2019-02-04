// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/hint_code_test.dart' show metaLibraryStub;
import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidRequiredParamTest);
  });
}

@reflectiveTest
class InvalidRequiredParamTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  void reset() {
    super.resetWith(packages: [
      ['meta', metaLibraryStub]
    ]);
  }

  test_namedParameter_withDefault() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m({@required a = 1}) => null;
''', [HintCode.INVALID_REQUIRED_PARAM]);
  }

  test_positionalParameter_withDefault() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m([@required a = 1]) => null;
''', [HintCode.INVALID_REQUIRED_PARAM]);
  }

  test_ppositionalParameter_noDefault() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m([@required a]) => null;
''', [HintCode.INVALID_REQUIRED_PARAM]);
  }

  test_requiredParameter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

m(@required a) => null;
''', [HintCode.INVALID_REQUIRED_PARAM]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

m1() => null;
m2(a) => null;
m3([a]) => null;
m4({a}) => null;
m5({@required a}) => null;
m6({a, @required b}) => null;
''');
  }
}
