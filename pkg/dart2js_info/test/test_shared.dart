// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

Future<String> helloWorldDumpInfo() async =>
    resolveTestFileContent('hello_world/hello_world.js.info.json');

Future<String> helloWorldDeferredDumpInfo() async => resolveTestFileContent(
    'hello_world_deferred/hello_world_deferred.js.info.json');

Future<String> resolveTestFileContent(String filePath) async =>
    (await resolveTestFile(filePath)).readAsStringSync();

Future<File> resolveTestFile(String filePath) async {
  final mainLibraryUri = await Isolate.resolvePackageUri(
      Uri.parse('package:dart2js_info/info.dart'));
  return File.fromUri(mainLibraryUri!.resolve('../test/$filePath'));
}
