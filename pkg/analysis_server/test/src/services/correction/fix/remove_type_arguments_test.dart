// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveTypeArgumentsTest);
  });
}

@reflectiveTest
class RemoveTypeArgumentsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_TYPE_ARGUMENTS;

  Future<void> test_explicitConst() async {
    await resolveTestCode('''
main() {
  const C.named<int>();
}
class C<E> {
  const C.named();
}
''');
    await assertHasFix('''
main() {
  const C.named();
}
class C<E> {
  const C.named();
}
''');
  }

  Future<void> test_explicitNew() async {
    await resolveTestCode('''
main() {
  new C.named<int>();
}
class C<E> {
  C.named();
}
''');
    await assertHasFix('''
main() {
  new C.named();
}
class C<E> {
  C.named();
}
''');
  }

  Future<void> test_implicitConst() async {
    await resolveTestCode('''
main() {
  const C c = C.named<int>();
  print(c);
}
class C<E> {
  const C.named();
}
''');
    await assertHasFix('''
main() {
  const C c = C.named();
  print(c);
}
class C<E> {
  const C.named();
}
''');
  }

  Future<void> test_implicitNew() async {
    await resolveTestCode('''
main() {
  C.named<int>();
}
class C<E> {
  C.named();
}
''');
    await assertHasFix('''
main() {
  C.named();
}
class C<E> {
  C.named();
}
''');
  }
}
