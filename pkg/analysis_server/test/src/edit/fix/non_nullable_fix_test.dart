// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableFixTest);
  });
}

@reflectiveTest
class NonNullableFixTest extends AbstractAnalysisTest {
  int requestId = 30;

  path.Context context;

  DartFixListener listener;

  String get nextRequestId => (++requestId).toString();

  Future<EditDartfixResult> performFix(
      {List<String> included, String outputDir}) async {
    final id = nextRequestId;
    final params = EditDartfixParams(included);
    params.includedFixes = ['non-nullable'];
    params.outputDir = outputDir;
    Request request = Request(id, 'edit.dartfix', params.toJson());
    Response response = await EditDartFix(server, request).compute();
    expect(response.id, id);
    expect(response.error, isNull);
    return EditDartfixResult.fromResponse(response);
  }

  @override
  Future<void> setUp() async {
    context = path.style == path.Style.windows
        // On Windows, ensure that the current drive matches
        // the drive inserted by MemoryResourceProvider.convertPath
        // so that packages are mapped to the correct drive
        ? path.Context(current: 'C:\\project')
        : path.Context(current: '/project');
    resourceProvider = MemoryResourceProvider(context: context);
    super.setUp();
    newFile('/project/bin/bin.dart', content: 'var x = 1;');
    newFile('/project/lib/lib1.dart', content: 'var x = 1;');
    newFile('/project/lib/lib2.dart', content: 'var x = 1;');
    newFile('/project/lib/src/lib3.dart', content: 'var x = 1;');
    newFile('/project/test/test.dart', content: 'var x = 1;');
    newFile('/project2/bin/bin.dart', content: 'var x = 1;');
    newFile('/project2/lib/lib1.dart', content: 'var x = 1;');
    newFile('/project2/lib/lib2.dart', content: 'var x = 1;');
    newFile('/project2/lib/src/lib3.dart', content: 'var x = 1;');
    newFile('/project2/test/test.dart', content: 'var x = 1;');
    // Compute the analysis results.
    server.setAnalysisRoots(
        '0', [resourceProvider.pathContext.dirname(testFile)], [], {});
    await server
        .getAnalysisDriver(testFile)
        .currentSession
        .getResolvedUnit(testFile);
    listener = DartFixListener(server);
  }

  test_included_multipleRelativeDirectories() async {
    NonNullableFix fix =
        NonNullableFix(listener, '.', included: ['lib', 'test']);
    expect(fix.includedRoot, equals(convertPath('/project')));
  }

  test_included_multipleRelativeDirectories_nonCanonical() async {
    NonNullableFix fix = NonNullableFix(listener, '.',
        included: ['../project2/lib', '../project2/lib/src']);
    expect(fix.includedRoot, equals(convertPath('/project2/lib')));
  }

  test_included_multipleRelativeDirectories_nonCanonical_atFilesystemRoot() async {
    NonNullableFix fix = NonNullableFix(listener, '.',
        included: ['../project2/lib', '../project/lib']);
    expect(fix.includedRoot, equals(convertPath('/')));
  }

  test_included_multipleRelativeDirectories_subAndSuperDirectories() async {
    NonNullableFix fix = NonNullableFix(listener, '.', included: ['lib', '.']);
    expect(fix.includedRoot, equals(convertPath('/project')));
  }

  test_included_multipleRelativeFiles() async {
    NonNullableFix fix = NonNullableFix(listener, '.',
        included: ['lib/lib1.dart', 'test/test.dart']);
    expect(fix.includedRoot, equals(convertPath('/project')));
  }

  test_included_multipleRelativeFiles_sameDirectory() async {
    NonNullableFix fix = NonNullableFix(listener, '.',
        included: ['lib/lib1.dart', 'lib/lib2.dart']);
    expect(fix.includedRoot, equals(convertPath('/project/lib')));
  }

  test_included_multipleRelativeFilesAndDirectories() async {
    NonNullableFix fix = NonNullableFix(listener, '.',
        included: ['lib/lib1.dart', 'lib/src', '../project/lib/src/lib3.dart']);
    expect(fix.includedRoot, equals(convertPath('/project/lib')));
  }

  test_included_singleAbsoluteDirectory() async {
    NonNullableFix fix = NonNullableFix(listener, '.', included: ['/project']);
    expect(fix.includedRoot, equals(convertPath('/project')));
  }

  test_included_singleAbsoluteFile() async {
    NonNullableFix fix =
        NonNullableFix(listener, '.', included: ['/project/bin/bin.dart']);
    expect(fix.includedRoot, equals(convertPath('/project/bin')));
  }

  test_included_singleRelativeDirectory() async {
    NonNullableFix fix = NonNullableFix(listener, '.', included: ['.']);
    expect(fix.includedRoot, equals(convertPath('/project')));
  }

  test_outputDirContainsFilesRootedAtProjectPath() async {
    createProject();
    Folder outputDir = getFolder('/outputDir');
    await performFix(included: [projectPath], outputDir: outputDir.path);
    expect(outputDir.exists, true);
    expect(getFile('/outputDir/bin/bin.html').exists, isTrue);
    expect(getFile('/outputDir/lib/lib1.html').exists, isTrue);
    expect(getFile('/outputDir/lib/lib2.html').exists, isTrue);
    expect(getFile('/outputDir/lib/src/lib3.html').exists, isTrue);
    expect(getFile('/outputDir/test/test.html').exists, isTrue);
  }

  test_outputDirContainsFilesRootedInASubdirectory() async {
    createProject();
    Folder outputDir = getFolder('/outputDir');
    await performFix(
        included: [context.join(projectPath, 'lib')],
        outputDir: outputDir.path);
    expect(outputDir.exists, true);
    expect(getFile('/outputDir/lib1.html').exists, isTrue);
    expect(getFile('/outputDir/lib2.html').exists, isTrue);
    expect(getFile('/outputDir/src/lib3.html').exists, isTrue);
  }

  test_outputDirContainsFilesRootedInParentOfSingleFile() async {
    createProject();
    Folder outputDir = getFolder('/outputDir');
    await performFix(
        included: [context.join(projectPath, 'lib', 'lib2.dart')],
        outputDir: outputDir.path);
    expect(outputDir.exists, true);
    expect(outputDir.getChildAssumingFile('lib2.html').exists, isTrue);
  }
}
