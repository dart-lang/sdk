// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDomainGetErrorsTest);
  });
}

/// Tests that when an SDK path is specified on the command-line (via the
/// `--sdk` argument) that the specified SDK is used.
@reflectiveTest
class AnalysisDomainGetErrorsTest
    extends AbstractAnalysisServerIntegrationTest {
  String createNonStandardSdk() {
    var sdkPath = path.join(sourceDirectory.path, 'sdk');

    Directory(path.join(sdkPath, 'lib', 'core')).createSync(recursive: true);
    Directory(path.join(sdkPath, 'lib', 'async')).createSync(recursive: true);
    Directory(path.join(sdkPath, 'lib', 'fake')).createSync(recursive: true);

    File(path.join(sdkPath, 'version')).writeAsStringSync('2.12.0');

    File(path.join(sdkPath, 'lib', 'core', 'core.dart')).writeAsStringSync(r'''
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

    File(path.join(sdkPath, 'lib', 'async', 'async.dart'))
        .writeAsStringSync(r'''
library dart.async;
class Future<T> {}
''');

    File(path.join(sdkPath, 'lib', 'fake', 'fake.dart')).writeAsStringSync(r'''
class Fake {} 
''');

    var libsDir = path.join(
      sdkPath,
      'lib',
      '_internal',
      'sdk_library_metadata',
      'lib',
    );
    Directory(libsDir).createSync(recursive: true);
    File(path.join(libsDir, 'libraries.dart')).writeAsStringSync(r'''
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
    var sdkPath = createNonStandardSdk();
    return server.start(
        diagnosticPort: diagnosticPort,
        sdkPath: sdkPath,
        servicesPort: servicesPort);
  }

  Future test_getErrors() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
import 'dart:core';
import 'dart:fake';
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;
    var errors = currentAnalysisErrors[pathname];
    expect(errors, hasLength(1));
    expect(errors[0].code, 'unused_import');
  }
}
