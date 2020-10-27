// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateFileTest);
  });
}

@reflectiveTest
class CreateFileTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FILE;

  Future<void> test_forImport() async {
    await resolveTestCode('''
import 'my_file.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    var fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/home/test/lib/my_file.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(
      fileEdit.edits[0].replacement,
      contains('// TODO Implement this library.'),
    );
  }

  Future<void> test_forImport_BAD_notDart() async {
    await resolveTestCode('''
import 'my_file.txt';
''');
    await assertNoFix();
  }

  Future<void> test_forImport_inPackage_lib() async {
    await resolveTestCode('''
import 'a/bb/my_lib.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    var fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/home/test/lib/a/bb/my_lib.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(
      fileEdit.edits[0].replacement,
      contains('// TODO Implement this library.'),
    );
  }

  Future<void> test_forImport_inPackage_test() async {
    testFile = convertPath('/home/test/test/test.dart');
    await resolveTestCode('''
import 'a/bb/my_lib.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    var fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/home/test/test/a/bb/my_lib.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(
      fileEdit.edits[0].replacement,
      contains('// TODO Implement this library.'),
    );
  }

  Future<void> test_forPart() async {
    await resolveTestCode('''
library my.lib;
part 'my_part.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    var fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/home/test/lib/my_part.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement, contains('part of my.lib;'));
  }
}
