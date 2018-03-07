// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sourcemap_testing/src/annotated_code_helper.dart';
import 'package:sourcemap_testing/src/stepping_helper.dart';
import 'package:testing/testing.dart';

class Data {
  Uri uri;
  Directory outDir;
  AnnotatedCode code;
  List<String> d8Output;
}

abstract class ChainContextWithCleanupHelper extends ChainContext {
  Map<TestDescription, Data> cleanupHelper = {};

  void cleanUp(TestDescription description, Result result) {
    if (debugging() && result.outcome != Expectation.Pass) {
      print("Not cleaning up: Running in debug-mode for non-passing test.");
      return;
    }

    Data data = cleanupHelper.remove(description);
    data?.outDir?.deleteSync(recursive: true);
  }

  bool debugging() => false;
}

class Setup extends Step<TestDescription, Data, ChainContext> {
  const Setup();

  String get name => "setup";

  Future<Result<Data>> run(TestDescription input, ChainContext context) async {
    Data data = new Data()..uri = input.uri;
    if (context is ChainContextWithCleanupHelper) {
      context.cleanupHelper[input] = data;
    }
    return pass(data);
  }
}

class SetCwdToSdkRoot extends Step<Data, Data, ChainContext> {
  const SetCwdToSdkRoot();

  String get name => "setCWD";

  Future<Result<Data>> run(Data input, ChainContext context) async {
    // stacktrace_helper assumes CWD is the sdk root dir.
    Directory.current = sdkRoot;
    return pass(input);
  }
}

class StepWithD8 extends Step<Data, Data, ChainContext> {
  const StepWithD8();

  String get name => "step";

  Future<Result<Data>> run(Data data, ChainContext context) async {
    var outWrapperPath = path.join(data.outDir.path, "wrapper.js");
    ProcessResult runResult =
        runD8AndStep(data.outDir.path, data.code, ['--module', outWrapperPath]);
    data.d8Output = (runResult.stdout as String).split("\n");
    return pass(data);
  }
}

class CheckSteps extends Step<Data, Data, ChainContext> {
  final bool debug;

  CheckSteps(this.debug);

  String get name => "check";

  Future<Result<Data>> run(Data data, ChainContext context) async {
    checkD8Steps(data.outDir.path, data.d8Output, data.code, debug: debug);
    return pass(data);
  }
}

File findInOutDir(String relative) {
  var outerDir = sdkRoot.path;
  for (var outDir in const ["out/ReleaseX64", "xcodebuild/ReleaseX64"]) {
    var tryPath = path.join(outerDir, outDir, relative);
    File file = new File(tryPath);
    if (file.existsSync()) return file;
  }
  throw "Couldn't find $relative. Try building more targets.";
}

String get dartExecutable {
  return Platform.resolvedExecutable;
}

String uriPathForwardSlashed(Uri uri) {
  return uri.toFilePath().replaceAll("\\", "/");
}
