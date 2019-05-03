// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorParamTypeMismatchTest);
  });
}

/// TODO(paulberry): move other tests from [CheckedModeCompileTimeErrorCodeTest]
/// to this class.
@reflectiveTest
class ConstConstructorParamTypeMismatchTest extends DriverResolutionTest {
  test_int_to_double_reference_from_other_library_other_file_after() async {
    addTestFile('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
    newFile('/test/lib/other.dart', content: '''
import 'test.dart';
class D {
  final C c;
  const D(this.c);
}
const D constant2 = const D(constant);
''');
    await resolveTestFile();
    assertNoTestErrors();
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_int_to_double_reference_from_other_library_other_file_before() async {
    addTestFile('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
    newFile('/test/lib/other.dart', content: '''
import 'test.dart';
class D {
  final C c;
  const D(this.c);
}
const D constant2 = const D(constant);
''');
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_int_to_double_single_library() async {
    addTestFile('''
class C {
  final double d;
  const C(this.d);
}
const C constant = const C(0);
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_int_to_double_via_default_value_other_file_after() async {
    addTestFile('''
import 'other.dart';

void main() {
  const c = C();
}
''');
    newFile('/test/lib/other.dart', content: '''
class C {
  final double x;
  const C([this.x = 0]);
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_int_to_double_via_default_value_other_file_before() async {
    addTestFile('''
import 'other.dart';

void main() {
  const c = C();
}
''');
    newFile('/test/lib/other.dart', content: '''
class C {
  final double x;
  const C([this.x = 0]);
}
''');
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
    await resolveTestFile();
    assertNoTestErrors();
  }
}
