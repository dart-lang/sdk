// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDeprecatedNewInCommentReferenceBulkTest);
    defineReflectiveTests(RemoveDeprecatedNewInCommentReferenceTest);
  });
}

@reflectiveTest
class RemoveDeprecatedNewInCommentReferenceBulkTest
    extends BulkFixProcessorTest {
  Future<void> test_named() async {
    await resolveTestCode('''
/// See [new A.named].
class A {
  A.named();
}
''');
    await assertHasFix('''
/// See [A.named].
class A {
  A.named();
}
''');
  }
}

@reflectiveTest
class RemoveDeprecatedNewInCommentReferenceTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_DEPRECATED_NEW_IN_COMMENT_REFERENCE;

  Future<void> test_named() async {
    await resolveTestCode('''
/// See [new A.named].
class A {
  A.named();
}
''');
    await assertHasFix('''
/// See [A.named].
class A {
  A.named();
}
''');
  }

  Future<void> test_prefixedUnnamed() async {
    await resolveTestCode('''
/// See [new self.A].
import '' as self;
class A {}
''');
    await assertHasFix('''
/// See [self.A.new].
import '' as self;
class A {}
''');
  }

  Future<void> test_unnamed() async {
    await resolveTestCode('''
/// See [new A].
class A {}
''');
    await assertHasFix('''
/// See [A.new].
class A {}
''');
  }
}
