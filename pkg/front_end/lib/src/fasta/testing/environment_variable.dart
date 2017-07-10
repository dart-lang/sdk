// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.testing.environment_variable;

import 'dart:async' show Future;

import 'dart:io' show Directory, File, Platform;

import '../deprecated_problems.dart' show deprecated_inputError;

class EnvironmentVariable {
  final String name;

  final String what;

  const EnvironmentVariable(this.name, this.what);

  Future<String> get value async {
    String value = Platform.environment[name];
    if (value == null) return variableNotDefined();
    await validate(value);
    return value;
  }

  Future<Null> validate(String value) => new Future<Null>.value();

  variableNotDefined() {
    deprecated_inputError(
        null, null, "The environment variable '$name' isn't defined. $what");
  }
}

class EnvironmentVariableFile extends EnvironmentVariable {
  const EnvironmentVariableFile(String name, String what) : super(name, what);

  Future<Null> validate(String value) async {
    if (!await new File(value).exists()) notFound(value);
    return null;
  }

  notFound(String value) {
    deprecated_inputError(
        null,
        null,
        "The environment variable '$name' has the value "
        "'$value', that isn't a file. $what");
  }
}

class EnvironmentVariableDirectory extends EnvironmentVariable {
  const EnvironmentVariableDirectory(String name, String what)
      : super(name, what);

  Future<Null> validate(String value) async {
    if (!await new Directory(value).exists()) notFound(value);
    return null;
  }

  notFound(String value) {
    deprecated_inputError(
        null,
        null,
        "The environment variable '$name' has the value "
        "'$value', that isn't a directory. $what");
  }
}

Future<bool> fileExists(Uri base, String path) async {
  return await new File.fromUri(base.resolve(path)).exists();
}
