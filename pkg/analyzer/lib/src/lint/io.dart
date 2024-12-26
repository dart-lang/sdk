// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/util.dart';
import 'package:path/path.dart' as p;

/// A shared sink for standard error reporting.
StringSink errorSink = stderr;

/// A shared sink for standard out reporting.
StringSink outSink = stdout;

/// Returns `true` if this [entry] is a Dart file.
bool isDartFile(FileSystemEntity entry) => isDartFileName(entry.path);

/// Returns `true` if this [entry] is a pubspec file.
bool isPubspecFile(FileSystemEntity entry) =>
    isPubspecFileName(p.basename(entry.path));

/// Synchronously read the contents of the file at the given [path] as a string.
String readFile(String path) => File(path).readAsStringSync();
