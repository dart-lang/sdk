// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';

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
    testFile = '/my/project/bin/test.dart';
    await resolveTestUnit('''
import 'my_file.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/my/project/bin/my_file.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement, contains('library my_file;'));
  }

  test_forImport_BAD_inPackage_lib_justLib() async {
    newFile('/projects/my_package/pubspec.yaml', content: 'name: my_package');
    testFile = '/projects/my_package/test.dart';
    await resolveTestUnit('''
import 'lib';
''');
    await assertNoFix();
  }

  test_forImport_BAD_notDart() async {
    testFile = '/my/project/bin/test.dart';
    await resolveTestUnit('''
import 'my_file.txt';
''');
    await assertNoFix();
  }

  test_forImport_inPackage_lib() async {
    newFile('/projects/my_package/pubspec.yaml', content: 'name: my_package');
    testFile = '/projects/my_package/lib/test.dart';
    newFolder('/projects/my_package/lib');
    await resolveTestUnit('''
import 'a/bb/c_cc/my_lib.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file,
        convertPath('/projects/my_package/lib/a/bb/c_cc/my_lib.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement,
        contains('library my_package.a.bb.c_cc.my_lib;'));
  }

  test_forImport_inPackage_test() async {
    newFile('/projects/my_package/pubspec.yaml', content: 'name: my_package');
    testFile = '/projects/my_package/test/misc/test_all.dart';
    await resolveTestUnit('''
import 'a/bb/my_lib.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file,
        convertPath('/projects/my_package/test/misc/a/bb/my_lib.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement,
        contains('library my_package.test.misc.a.bb.my_lib;'));
  }

  test_forPart() async {
    testFile = convertPath('/my/project/bin/test.dart');
    await resolveTestUnit('''
library my.lib;
part 'my_part.dart';
''');
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/my/project/bin/my_part.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement, contains('part of my.lib;'));
  }

  test_forPart_inPackageLib() async {
    // TODO(brianwilkerson) Unify this test with the method _configureMyPkg in
    // import_library_project_test.dart.
    newFile('/my/pubspec.yaml', content: r'''
name: my_test
''');
    testFile = '/my/lib/test.dart';
    addTestSource('''
library my.lib;
part 'my_part.dart';
''', Uri.parse('package:my/test.dart'));
    // configure SourceFactory
    UriResolver pkgResolver = new PackageMapUriResolver(resourceProvider, {
      'my': <Folder>[getFolder('/my/lib')],
    });
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(sdk), pkgResolver, resourceResolver]);
    driver.configure(sourceFactory: sourceFactory);
    testAnalysisResult = await driver.getResult(convertPath(testFile));
    testUnit = testAnalysisResult.unit;
    // prepare fix
    await assertHasFixWithoutApplying();
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, convertPath('/my/lib/my_part.dart'));
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement, contains('part of my.lib;'));
  }
}
