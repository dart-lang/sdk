// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeDirectivesTest);
  });
}

@reflectiveTest
class OrganizeDirectivesTest extends PubPackageAnalysisServerTest {
  late SourceFileEdit fileEdit;

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  @failingTest
  Future test_BAD_doesNotExist() async {
    // The analysis driver fails to return an error
    var request =
        EditOrganizeDirectivesParams(convertPath('/no/such/file.dart'))
            .toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.FILE_NOT_ANALYZED,
    );
  }

  Future test_BAD_hasParseError() async {
    addTestFile('''
import 'dart:async'

void f() {}
''');
    var request = EditOrganizeDirectivesParams(testFile.path).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.ORGANIZE_DIRECTIVES_ERROR,
    );
  }

  Future test_BAD_notDartFile() async {
    var request = EditOrganizeDirectivesParams(
      convertPath('/not-a-Dart-file.txt'),
    ).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.FILE_NOT_ANALYZED,
    );
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditOrganizeDirectivesParams('test.dart').toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        EditOrganizeDirectivesParams(convertPath('/foo/../bar/test.dart'))
            .toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future test_keep_unresolvedDirectives() {
    var code = r'''
import 'dart:noSuchImportSdkLibrary';

import 'package:noSuchImportPackage/andLib.dart';

export 'dart:noSuchExportSdkLibrary';

export 'package:noSuchExportPackage/andLib.dart';

part 'no_such_part.dart';
''';
    addTestFile(code);
    return _assertOrganized(code);
  }

  Future test_OK_remove_duplicateImports_withSamePrefix() {
    addTestFile('''
library lib;

import 'dart:async' as async;
import 'dart:async' as async;

void f() {
  async.Future f;
}
''');
    return _assertOrganized(r'''
library lib;

import 'dart:async' as async;

void f() {
  async.Future f;
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

void f() {
  print(pi);
  new HashMap();
}
''');
    return _assertOrganized(r'''
library lib;

import 'dart:collection';
import 'dart:math';

void f() {
  print(pi);
  new HashMap();
}
''');
  }

  Future _assertOrganized(String expectedCode) async {
    await _requestOrganize();
    var resultCode = SourceEdit.applySequence(testFileContent, fileEdit.edits);
    expect(resultCode, expectedCode);
  }

  Future _requestOrganize() async {
    var request = EditOrganizeDirectivesParams(testFile.path).toRequest('0');
    var response = await handleSuccessfulRequest(request);
    var result = EditOrganizeDirectivesResult.fromResponse(response);
    fileEdit = result.edit;
  }
}
