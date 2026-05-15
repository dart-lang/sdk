// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnInGeneratorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnInGeneratorTest extends PubPackageResolutionTest {
  test_async() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async {
  return 0;
}
''');
  }

  test_asyncStar_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async* {
  return 0;
//^^^^^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
}
''');
  }

  test_asyncStar_blockBody_noValue() async {
    await resolveTestCodeWithDiagnostics(r'''
Stream<int> f() async* {
  return;
}
''');
  }

  test_asyncStar_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async* => 0;
//         ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
  }

  test_sync() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  return 0;
}
''');
  }

  test_syncStar_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
f() sync* {
  return 0;
//^^^^^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
}
''');
  }

  test_syncStar_blockBody_noValue() async {
    await resolveTestCodeWithDiagnostics(r'''
Iterable<int> f() sync* {
  return;
}
''');
  }

  test_syncStar_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
f() sync* => 0;
//        ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
  }
}
