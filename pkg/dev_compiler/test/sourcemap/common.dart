// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:path/path.dart' as p;
import 'package:sourcemap_testing/src/stepping_helper.dart';
import 'package:testing/testing.dart';

class Data {
  Uri uri;
  late Directory outDir;
  late String testFileName;
  late AnnotatedCode code;
  late List<String> stepOutput;

  Data(this.uri);
}

abstract class ChainContextWithCleanupHelper extends ChainContext {
  Map<TestDescription, Data> cleanupHelper = {};

  @override
  Future<void> cleanUp(TestDescription description, Result result) {
    if (debugging() && result.outcome != Expectation.pass) {
      print('Not cleaning up: Running in debug-mode for non-passing test.');
      return Future.value();
    }

    var data = cleanupHelper.remove(description);
    data?.outDir.deleteSync(recursive: true);
    return Future.value();
  }

  bool debugging() => false;
}

class Setup extends Step<TestDescription, Data, ChainContext> {
  const Setup();

  @override
  String get name => 'setup';

  @override
  Future<Result<Data>> run(TestDescription input, ChainContext context) async {
    var data = Data(input.uri);
    if (context is ChainContextWithCleanupHelper) {
      context.cleanupHelper[input] = data;
    }
    return pass(data);
  }
}

class SetCwdToSdkRoot extends Step<Data, Data, ChainContext> {
  const SetCwdToSdkRoot();

  @override
  String get name => 'setCWD';

  @override
  Future<Result<Data>> run(Data input, ChainContext context) async {
    // stacktrace_helper assumes CWD is the sdk root dir.
    Directory.current = sdkRoot;
    return pass(input);
  }
}

class StepWithChrome extends Step<Data, Data, ChainContext> {
  const StepWithChrome();

  @override
  String get name => 'step';

  @override
  Future<Result<Data>> run(Data data, ChainContext context) async {
    data.stepOutput = await runChromeAndStep(
      data.outDir.path,
      data.testFileName,
      data.code,
    );
    return pass(data);
  }
}

class CheckSteps extends Step<Data, Data, ChainContext> {
  final bool debug;

  CheckSteps(this.debug);

  @override
  String get name => 'check';

  @override
  Future<Result<Data>> run(Data data, ChainContext context) async {
    checkSteps(data.outDir.path, data.stepOutput, data.code, debug: debug);
    return pass(data);
  }
}

File findInOutDir(String relative) {
  var outerDir = sdkRoot!.path;
  for (var outDir in const [
    'out/ReleaseX64',
    'xcodebuild/ReleaseX64',
    'xcodebuild/ReleaseARM64',
  ]) {
    var tryPath = p.join(outerDir, outDir, relative);
    var file = File(tryPath);
    if (file.existsSync()) return file;
  }
  throw "Couldn't find $relative. Try building more targets.";
}

String get dartExecutable {
  return Platform.resolvedExecutable;
}

String uriPathForwardSlashed(Uri uri) {
  return uri.toFilePath().replaceAll('\\', '/');
}
