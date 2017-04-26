// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/base/instrumentation.dart' as fasta;
import 'package:front_end/src/fasta/compiler_context.dart' as fasta;
import 'package:front_end/src/fasta/testing/validating_instrumentation.dart'
    as fasta;
import 'package:kernel/kernel.dart' as fasta;
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

import '../../dart/analysis/base.dart';

Future<Null> main() async {
  await _runFrontEndInferenceTests();
}

/**
 * Expects that the [Platform.script] is a test inside of `pkg/analyzer/test`
 * folder, and return the absolute path of the `pkg` folder.
 */
String _findPkgRoot() {
  String scriptPath = pathos.fromUri(Platform.script);
  List<String> parts = pathos.split(scriptPath);
  for (int i = 0; i < parts.length - 2; i++) {
    if (parts[i] == 'pkg' &&
        parts[i + 1] == 'analyzer' &&
        parts[i + 2] == 'test') {
      return pathos.joinAll(parts.sublist(0, i + 1));
    }
  }
  throw new StateError('Unable to find sdk/pkg/ in $scriptPath');
}

Future<Null> _runFrontEndInferenceTests() async {
  String pkgPath = _findPkgRoot();
  String fePath = pathos.join(pkgPath, 'front_end', 'testcases', 'inference');
  List<File> dartFiles = new Directory(fePath)
      .listSync()
      .where((entry) => entry is File && entry.path.endsWith('.dart'))
      .map((entry) => entry as File)
      .toList();

  for (File file in dartFiles) {
    var test = new _FrontEndInferenceTest();
    await test.setUp();
    try {
      String code = file.readAsStringSync();
      await test.runTest(file.path, code);
    } catch (_) {
      print(_);
    } finally {
      await test.tearDown();
    }
  }
}

class _FrontEndInferenceTest extends BaseAnalysisDriverTest {
  Future<Null> runTest(String path, String code) async {
    var uri = provider.pathContext.toUri(path);

    List<int> lineStarts = new LineInfo.fromContent(code).lineStarts;
    fasta.CompilerContext.current.uriToSource[uri.toString()] =
        new fasta.Source(lineStarts, UTF8.encode(code));

    var validation = new fasta.ValidatingInstrumentation();
    await validation.loadExpectations(uri);

    driver.test.instrumentation = new _Instrumentation(validation);
    provider.newFile(path, code);
    await driver.getResult(path);

    validation.finish();

    if (validation.hasProblems) {
      var problem = validation.problemsAsString;
      fail(problem);
    }
  }
}

class _Instrumentation implements fasta.Instrumentation {
  final fasta.Instrumentation instrumentation;
  final Set<String> _seenKeys = new Set<String>();

  _Instrumentation(this.instrumentation);

  @override
  void record(
      Uri uri, int offset, String property, fasta.InstrumentationValue value) {
    // Analyzer's resolver reports many of instance creations twice.
    if (_seenKeys.add('$uri:$offset:$property')) {
      instrumentation.record(uri, offset, property, value);
    }
  }
}
