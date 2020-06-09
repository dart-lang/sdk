// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as p;

/// Emit the given word with the correct pluralization.
String pluralize(String word, int count) => count == 1 ? word : '${word}s';

/// String utility to trim some suffix from the end of a [String].
String trimEnd(String s, String suffix) {
  if (s != null && suffix != null && suffix.isNotEmpty && s.endsWith(suffix)) {
    return s.substring(0, s.length - suffix.length);
  }
  return s;
}

/// Given a data structure which is a Map of String to dynamic values, return
/// the same structure (`Map<String, dynamic>`) with the correct runtime types.
Map<String, dynamic> castStringKeyedMap(dynamic untyped) {
  final Map<dynamic, dynamic> map = untyped as Map<dynamic, dynamic>;
  return map?.cast<String, dynamic>();
}

extension FileSystemEntityExtension on FileSystemEntity {
  String get name => p.basename(path);

  bool get isDartFile => this is File && p.extension(path) == '.dart';
}
