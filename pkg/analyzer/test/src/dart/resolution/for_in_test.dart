import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInDriverResolutionTest);
    defineReflectiveTests(ForInTaskResolutionTest);
  });
}

@reflectiveTest
class ForInDriverResolutionTest extends DriverResolutionTest
    with ForInResolutionMixin {}

abstract class ForInResolutionMixin implements ResolutionTest {
  test_importPrefix_asIterable() async {
    addTestFile(r'''
import 'dart:async' as p;

main() {
  for (var x in p) {}
}
''');
    await resolveTestFile();
    assertHasTestErrors();

    var xRef = findNode.simple('x in');
    expect(xRef.staticElement, isNotNull);

    var pRef = findNode.simple('p) {}');
    assertElement(pRef, findElement.import('dart:async').prefix);
    assertTypeNull(pRef);
  }
}

@reflectiveTest
class ForInTaskResolutionTest extends TaskResolutionTest
    with ForInResolutionMixin {}
