// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateFileTest);
  });
}

@reflectiveTest
class CreateFileTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_FILE;

  test_forImport() async {
    await resolveTestUnit('''
import 'my_file.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/home/test/lib/my_file.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(
      fileEdit.edits[0].replacement,
      contains('// TODO Implement this library.'),
    );
  }

  test_forImport_BAD_notDart() async {
    await resolveTestUnit('''
import 'my_file.txt';
''');
    await assertNoFix();
  }

  test_forImport_inPackage_lib() async {
    await resolveTestUnit('''
import 'a/bb/my_lib.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/home/test/lib/a/bb/my_lib.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(
      fileEdit.edits[0].replacement,
      contains('// TODO Implement this library.'),
    );
  }

  test_forImport_inPackage_test() async {
    testFile = convertPath('/home/test/test/test.dart');
    await resolveTestUnit('''
import 'a/bb/my_lib.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/home/test/test/a/bb/my_lib.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(
      fileEdit.edits[0].replacement,
      contains('// TODO Implement this library.'),
    );
  }

  test_forPart() async {
    await resolveTestUnit('''
library my.lib;
part 'my_part.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/home/test/lib/my_part.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement, contains('part of my.lib;'));
  }
}
