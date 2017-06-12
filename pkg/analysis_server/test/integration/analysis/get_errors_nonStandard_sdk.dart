// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../mock_sdk.dart';
import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDomainGetErrorsTest);
  });
}

/**
 * Tests that when an SDK path is specified on the command-line (via the `--sdk`
 * argument) that the specified SDK is used.
 */
@reflectiveTest
class AnalysisDomainGetErrorsTest
    extends AbstractAnalysisServerIntegrationTest {
  String createNonStandardSdk() {
    MockSdkLibrary fakeLibrary =
        new MockSdkLibrary('dart:fake', '/lib/fake/fake.dart', '');
    String sdkPath = path.join(sourceDirectory.path, 'sdk');
    StringBuffer librariesContent = new StringBuffer();
    librariesContent.writeln(
        'final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {');
    MockSdk.LIBRARIES.toList()
      ..add(fakeLibrary)
      ..forEach((SdkLibrary library) {
        List<String> components = path.posix.split(library.path);
        components[0] = sdkPath;
        String libraryPath = path.joinAll(components);
        new Directory(path.dirname(libraryPath)).createSync(recursive: true);
        new File(libraryPath)
            .writeAsStringSync((library as MockSdkLibrary).content);

        String relativePath = path.joinAll(components.sublist(2));
        librariesContent.write('"');
        librariesContent
            .write(library.shortName.substring(5)); // Remove the 'dart:' prefix
        librariesContent.write('": const LibraryInfo("');
        librariesContent.write(relativePath);
        librariesContent.writeln('"),');
      });
    librariesContent.writeln('};');

    String librariesPath = path.joinAll([
      sdkPath,
      'lib',
      '_internal',
      'sdk_library_metadata',
      'lib',
      'libraries.dart'
    ]);
    new Directory(path.dirname(librariesPath)).createSync(recursive: true);
    new File(librariesPath).writeAsStringSync(librariesContent.toString());

    return sdkPath;
  }

  @override
  Future startServer(
      {bool checked: true, int diagnosticPort, int servicesPort}) {
    String sdkPath = createNonStandardSdk();
    return server.start(
        checked: checked,
        diagnosticPort: diagnosticPort,
        sdkPath: sdkPath,
        servicesPort: servicesPort);
  }

  Future test_getErrors() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
import 'dart:core';
import 'dart:fake';
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;
    List<AnalysisError> errors = currentAnalysisErrors[pathname];
    expect(errors, hasLength(1));
    expect(errors[0].code, 'unused_import');
  }
}
