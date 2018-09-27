// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationDriverResolutionTest);
    defineReflectiveTests(InstanceCreationTaskResolutionTest);
  });
}

@reflectiveTest
class InstanceCreationDriverResolutionTest extends DriverResolutionTest
    with InstanceCreationResolutionMixin {}

abstract class InstanceCreationResolutionMixin implements ResolutionTest {
  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew() async {
    addTestFile(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
    ]);

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('Foo'),
      'Foo<int>',
      constructorName: 'bar',
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew_prefix() async {
    newFile('/test/lib/a.dart', content: '''
class Foo<X> {
  Foo.bar();
}
''');
    addTestFile('''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
}
''');
    await resolveTestFile();
    assertTestErrors([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
    ]);

    var import = findElement.import('package:test/a.dart');

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      import.importedLibrary.getType('Foo'),
      'Foo<int>',
      constructorName: 'bar',
      expectedPrefix: import.prefix,
    );
  }
}

@reflectiveTest
class InstanceCreationTaskResolutionTest extends TaskResolutionTest
    with InstanceCreationResolutionMixin {}
