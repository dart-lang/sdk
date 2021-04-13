// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceReturnTypeFutureTest);
  });
}

@reflectiveTest
class ReplaceReturnTypeFutureTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_RETURN_TYPE_FUTURE;

  Future<void> test_adjacentNodes_withImport() async {
    await resolveTestCode('''
import 'dart:async';
var v;int main() async => 0;
''');
    await assertHasFix('''
import 'dart:async';
var v;Future<int> main() async => 0;
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  Future<void> test_adjacentNodes_withoutImport() async {
    await resolveTestCode('''
var v;int main() async => 0;
''');
    await assertHasFix('''
var v;Future<int> main() async => 0;
''');
  }

  Future<void> test_complexTypeName_withImport() async {
    await resolveTestCode('''
import 'dart:async';
List<int> main() async {
}
''');
    await assertHasFix('''
import 'dart:async';
Future<List<int>> main() async {
}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  @failingTest
  Future<void> test_complexTypeName_withoutImport() async {
    await resolveTestCode('''
List<int> main() async {
}
''');
    await assertHasFix('''
import 'dart:async';

Future<List<int>> main() async {
}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  Future<void> test_importedWithPrefix() async {
    await resolveTestCode('''
import 'dart:async' as al;
int main() async {
}
''');
    await assertHasFix('''
import 'dart:async' as al;
al.Future<int> main() async {
}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  Future<void> test_simpleTypeName_withImport() async {
    await resolveTestCode('''
import 'dart:async';
int main() async => 0;
''');
    await assertHasFix('''
import 'dart:async';
Future<int> main() async => 0;
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  @failingTest
  Future<void> test_simpleTypeName_withoutImport() async {
    await resolveTestCode('''
int main() async => 0;
''');
    await assertHasFix('''
import 'dart:async';

Future<int> main() async => 0;
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  Future<void> test_withLibraryDirective_withImport() async {
    await resolveTestCode('''
library main;
import 'dart:async';
int main() async {
}
''');
    await assertHasFix('''
library main;
import 'dart:async';
Future<int> main() async {
}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  Future<void> test_withLibraryDirective_withoutImport() async {
    await resolveTestCode('''
library main;
int main() async {
}
''');
    await assertHasFix('''
library main;
Future<int> main() async {
}
''');
  }
}
