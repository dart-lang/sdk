import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDriverResolutionTest);
    defineReflectiveTests(EnumTaskResolutionTest);
  });
}

@reflectiveTest
class EnumDriverResolutionTest extends DriverResolutionTest
    with EnumResolutionMixin {}

abstract class EnumResolutionMixin implements ResolutionTest {
  test_error_conflictingStaticAndInstance_index() async {
    addTestFile(r'''
enum E {
  a, index
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }
}

@reflectiveTest
class EnumTaskResolutionTest extends TaskResolutionTest
    with EnumResolutionMixin {}
