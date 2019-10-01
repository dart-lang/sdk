// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
    var sdkPath = path.join(sourceDirectory.path, 'sdk');

    new Directory(path.join(sdkPath, 'lib', 'core'))
        .createSync(recursive: true);
    new Directory(path.join(sdkPath, 'lib', 'async'))
        .createSync(recursive: true);
    new Directory(path.join(sdkPath, 'lib', 'fake'))
        .createSync(recursive: true);

    new File(path.join(sdkPath, 'lib', 'core', 'core.dart'))
        .writeAsStringSync(r'''
library dart.core;
import 'dart:async';
class bool {}
class double {}
class int {}
class num {}
class Object {}
class Iterable<E> {}
class Map<K, V> {}
class Null {}
class String {}
class Type {}
''');

    new File(path.join(sdkPath, 'lib', 'async', 'async.dart'))
        .writeAsStringSync(r'''
library dart.async;
class Future<T> {}
''');

    new File(path.join(sdkPath, 'lib', 'fake', 'fake.dart'))
        .writeAsStringSync(r'''
class Fake {} 
''');

    var libsDir = path.join(
      sdkPath,
      'lib',
      '_internal',
      'sdk_library_metadata',
      'lib',
    );
    new Directory(libsDir).createSync(recursive: true);
    new File(path.join(libsDir, 'libraries.dart')).writeAsStringSync(r'''
final LIBRARIES = const <String, LibraryInfo> {
  "core":  const LibraryInfo("core/core.dart"),
  "async": const LibraryInfo("async/async.dart"),
  "fake":  const LibraryInfo("fake/fake.dart"),
};
''');

    return sdkPath;
  }

  @override
  Future startServer({int diagnosticPort, int servicesPort}) {
    String sdkPath = createNonStandardSdk();
    return server.start(
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
