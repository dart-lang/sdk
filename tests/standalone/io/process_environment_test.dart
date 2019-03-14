// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

const String childFile = 'process_environment_lib.dart';
const String fakeKey = 'Artificial';
const String fakeValue = 'fakepath';

void main() async {
  Map<String, String> environ = Platform.environment;
  String baseDirectory = path.dirname(Platform.script.path);
  //DETACHED PROCESS WITHOUT includeParentEnvironment
  var WithoutEnviron = await Process.start(
      Platform.executable, [path.join(baseDirectory, childFile)],
      mode: ProcessStartMode.detachedWithStdio,
      includeParentEnvironment: false,
      environment: <String, String>{fakeKey: fakeValue});

  Map<String, String> notInclude = new Map();
  await for (final line in WithoutEnviron.stdout
      .transform(systemEncoding.decoder)
      .transform(LineSplitter())) {
    notInclude = RestoreToMap(line);
  }

  //Ensure the child process has the passed environment
  Expect.isTrue(notInclude.length >= 1);
  Expect.isTrue(notInclude.keys.contains(fakeKey));

  //DETACHED PROCESS WITH includeParentEnvironment
  var WithEnviron = await Process.start(
      Platform.executable, [path.join(baseDirectory, childFile)],
      mode: ProcessStartMode.detachedWithStdio,
      includeParentEnvironment: true,
      environment: <String, String>{fakeKey: fakeValue});

  Map<String, String> include = new Map();
  await for (final line in WithEnviron.stdout
      .transform(systemEncoding.decoder)
      .transform(LineSplitter())) {
    include = RestoreToMap(line);
  }

  //Parent environment and one fake path
  Expect.isTrue(include.length == environ.length + 1);
  Expect.isTrue(include[fakeKey] == fakeValue);
}

Map<String, String> RestoreToMap(String s) {
  s = s.substring(1, s.length - 1);
  Map<String, String> result = new Map();
  for (String line in s.split(", ")) {
    var i = line.indexOf(": ");
    result.putIfAbsent(line.substring(0, i), () => line.substring(i + 2));
  }
  return result;
}
