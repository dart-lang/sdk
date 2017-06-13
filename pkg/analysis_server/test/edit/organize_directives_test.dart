// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:plugin/manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeDirectivesTest);
  });
}

@reflectiveTest
class OrganizeDirectivesTest extends AbstractAnalysisTest {
  SourceFileEdit fileEdit;

  @override
  void setUp() {
    super.setUp();
    createProject();
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins([server.serverPlugin]);
    handler = new EditDomainHandler(server);
  }

  @failingTest
  Future test_BAD_doesNotExist() async {
    // The analysis driver fails to return an error
    Request request =
        new EditOrganizeDirectivesParams('/no/such/file.dart').toRequest('0');
    Response response = await waitResponse(request);
    expect(
        response, isResponseFailure('0', RequestErrorCode.FILE_NOT_ANALYZED));
  }

  Future test_BAD_hasParseError() async {
    addTestFile('''
import 'dart:async'

main() {}
''');
    Request request = new EditOrganizeDirectivesParams(testFile).toRequest('0');
    Response response = await waitResponse(request);
    expect(response,
        isResponseFailure('0', RequestErrorCode.ORGANIZE_DIRECTIVES_ERROR));
  }

  Future test_BAD_notDartFile() async {
    Request request =
        new EditOrganizeDirectivesParams('/not-a-Dart-file.txt').toRequest('0');
    Response response = await waitResponse(request);
    expect(
        response, isResponseFailure('0', RequestErrorCode.FILE_NOT_ANALYZED));
  }

  Future test_OK_remove_duplicateImports_withSamePrefix() {
    addTestFile('''
library lib;

import 'dart:async' as async;
import 'dart:async' as async;

main() {
  async.Future f;
}
''');
    return _assertOrganized(r'''
library lib;

import 'dart:async' as async;

main() {
  async.Future f;
}
''');
  }

  Future test_OK_remove_unresolvedDirectives() {
    addFile('$testFolder/existing_part1.dart', 'part of lib;');
    addFile('$testFolder/existing_part2.dart', 'part of lib;');
    addTestFile('''
library lib;

export 'dart:noSuchExportSdkLibrary';
export 'dart:async';
export 'package:noSuchExportPackage/andLib.dart';
export 'dart:math';

import 'dart:async';
import 'dart:noSuchImportSdkLibrary';
import 'dart:math';
import 'package:noSuchImportPackage/andLib.dart';

part 'existing_part1.dart';
part 'no_such_part.dart';
part 'existing_part2.dart';

main(Future f) {
  print(PI);
}
''');
    return _assertOrganized(r'''
library lib;

import 'dart:async';
import 'dart:math';

export 'dart:async';
export 'dart:math';

part 'existing_part1.dart';
part 'existing_part2.dart';

main(Future f) {
  print(PI);
}
''');
  }

  Future test_OK_remove_unusedImports() {
    addTestFile('''
library lib;

import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:collection';

main() {
  print(PI);
  new HashMap();
}
''');
    return _assertOrganized(r'''
library lib;

import 'dart:collection';
import 'dart:math';

main() {
  print(PI);
  new HashMap();
}
''');
  }

  Future _assertOrganized(String expectedCode) async {
    await _requestOrganize();
    String resultCode = SourceEdit.applySequence(testCode, fileEdit.edits);
    expect(resultCode, expectedCode);
  }

  Future _requestOrganize() async {
    Request request = new EditOrganizeDirectivesParams(testFile).toRequest('0');
    Response response = await waitResponse(request);
    var result = new EditOrganizeDirectivesResult.fromResponse(response);
    fileEdit = result.edit;
  }
}
