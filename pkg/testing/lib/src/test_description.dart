// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.test_description;

import 'dart:io' show File, FileSystemEntity;

abstract class TestDescription implements Comparable<TestDescription> {
  Uri get uri;

  String get shortName;

  int compareTo(TestDescription other) => "$uri".compareTo("${other.uri}");
}

class FileBasedTestDescription extends TestDescription {
  final Uri root;
  final File file;
  final Uri output;

  /// If non-null, this is a generated multitest, and the set contains the
  /// expected outcomes.
  Set<String> multitestExpectations;

  FileBasedTestDescription(this.root, this.file, {this.output});

  @override
  Uri get uri => file.uri;

  @override
  String get shortName {
    String baseName = "$uri".substring("$root".length);
    return baseName.substring(0, baseName.length - ".dart".length);
  }

  String get escapedName => shortName.replaceAll("/", "__");

  void writeImportOn(StringSink sink) {
    sink.write("import '");
    sink.write(uri);
    sink.write("' as ");
    sink.write(escapedName);
    sink.writeln(" show main;");
  }

  void writeClosureOn(StringSink sink) {
    sink.write('    "');
    sink.write(shortName);
    sink.write('": ');
    sink.write(escapedName);
    sink.writeln('.main,');
  }

  static FileBasedTestDescription from(Uri root, FileSystemEntity entity,
      {Pattern pattern}) {
    if (entity is! File) return null;
    pattern ??= "_test.dart";
    String path = entity.uri.path;
    bool hasMatch = false;
    if (pattern is String) {
      if (path.endsWith(pattern)) hasMatch = true;
    } else if (path.contains(pattern)) {
      hasMatch = true;
    }
    return hasMatch ? new FileBasedTestDescription(root, entity) : null;
  }

  String formatError(String message) {
    String base = Uri.base.toFilePath();
    String path = uri.toFilePath();
    if (path.startsWith(base)) {
      path = path.substring(base.length);
    }
    return "$path:$message";
  }
}
