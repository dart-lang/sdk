// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.discover;

import 'dart:io' show Directory, FileSystemEntity, Platform, Process;

import 'dart:async' show Future, Stream, StreamController, StreamSubscription;

import '../testing.dart' show FileBasedTestDescription;

final Uri packageConfig = computePackageConfig();

final Uri dartSdk = computeDartSdk();

/// Common arguments when running a dart program. Returns a copy that can
/// safely be modified by caller.
List<String> get dartArguments =>
    <String>["-c", "--packages=${packageConfig.toFilePath()}"];

Stream<FileBasedTestDescription> listTests(List<Uri> testRoots,
    {Pattern pattern}) {
  StreamController<FileBasedTestDescription> controller =
      new StreamController<FileBasedTestDescription>();
  Map<Uri, StreamSubscription> subscriptions = <Uri, StreamSubscription>{};
  for (Uri testRootUri in testRoots) {
    subscriptions[testRootUri] = null;
    Directory testRoot = new Directory.fromUri(testRootUri);
    testRoot.exists().then((bool exists) {
      if (exists) {
        Stream<FileSystemEntity> stream =
            testRoot.list(recursive: true, followLinks: false);
        var subscription = stream.listen((FileSystemEntity entity) {
          FileBasedTestDescription description = FileBasedTestDescription
              .from(testRootUri, entity, pattern: pattern);
          if (description != null) {
            controller.add(description);
          }
        }, onError: (error, StackTrace trace) {
          controller.addError(error, trace);
        }, onDone: () {
          subscriptions.remove(testRootUri);
          if (subscriptions.isEmpty) {
            controller.close(); // TODO(ahe): catchError???
          }
        });
        subscriptions[testRootUri] = subscription;
      } else {
        controller.addError("$testRootUri isn't a directory");
        subscriptions.remove(testRootUri);
      }
      if (subscriptions.isEmpty) {
        controller.close(); // TODO(ahe): catchError???
      }
    });
  }
  return controller.stream;
}

Uri computePackageConfig() {
  String path = Platform.packageConfig;
  if (path != null) return Uri.base.resolve(path);
  return Uri.base.resolve(".packages");
}

// TODO(eernst): Use `bool.hasEnvironment` below when possible;
// for now we use a dual `defaultValue` rewrite.
const _dartSdk = (String.fromEnvironment("DART_SDK", defaultValue: "1") ==
        String.fromEnvironment("DART_SDK", defaultValue: "2"))
    ? String.fromEnvironment("DART_SDK")
    : null;

Uri computeDartSdk() {
  String dartSdkPath = Platform.environment["DART_SDK"] ?? _dartSdk;
  if (dartSdkPath != null) {
    return Uri.base.resolveUri(new Uri.file(dartSdkPath));
  } else {
    return Uri.base
        .resolveUri(new Uri.file(Platform.resolvedExecutable))
        .resolve("../");
  }
}

Future<Process> startDart(Uri program,
    [List<String> arguments, List<String> vmArguments]) {
  List<String> allArguments = <String>[];
  allArguments.addAll(vmArguments ?? dartArguments);
  allArguments.add(program.toFilePath());
  if (arguments != null) {
    allArguments.addAll(arguments);
  }
  return Process.start(Platform.resolvedExecutable, allArguments);
}
