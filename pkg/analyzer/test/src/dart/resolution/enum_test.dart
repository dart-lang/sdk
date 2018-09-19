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

  test_inference_listLiteral() async {
    addTestFile(r'''
enum E1 {a, b}
enum E2 {a, b}

var v = [E1.a, E2.b];
''');
    await resolveTestFile();
    assertNoTestErrors();

    var v = findElement.topVar('v');
    assertElementTypeString(v.type, 'List<Object>');
  }
}

@reflectiveTest
class EnumTaskResolutionTest extends TaskResolutionTest
    with EnumResolutionMixin {}
