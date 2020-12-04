// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationWithNonClassTest);
  });
}

@reflectiveTest
class AnnotationWithNonClassTest extends PubPackageResolutionTest {
  test_instance() async {
    await assertErrorsInCode('''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);

@property(123)
main() {
}
''', [
      error(CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS, 117, 8),
    ]);
  }

  test_prefixed() async {
    newFile('$testPackageLibPath/annotations.dart', content: r'''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);
''');
    await assertErrorsInCode('''
import 'annotations.dart' as pref;
@pref.property(123)
main() {
}
''', [
      error(CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS, 36, 13),
    ]);
  }
}
