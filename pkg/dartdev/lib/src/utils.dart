// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

/// For commands where we are able to initialize the [ArgParser], this value
/// is used as the usageLineLength.
int get dartdevUsageLineLength =>
    stdout.hasTerminal ? stdout.terminalColumns : null;

/// Given a data structure which is a Map of String to dynamic values, return
/// the same structure (`Map<String, dynamic>`) with the correct runtime types.
Map<String, dynamic> castStringKeyedMap(dynamic untyped) {
  final Map<dynamic, dynamic> map = untyped as Map<dynamic, dynamic>;
  return map?.cast<String, dynamic>();
}

/// Emit the given word with the correct pluralization.
String pluralize(String word, int count) => count == 1 ? word : '${word}s';

/// Make an absolute [filePath] relative to [dir] (for display purposes).
String relativePath(String filePath, Directory dir) {
  var root = dir.absolute.path;
  if (filePath.startsWith(root)) {
    return filePath.substring(root.length + 1);
  }
  return filePath;
}

/// String utility to trim some suffix from the end of a [String].
String trimEnd(String s, String suffix) {
  if (s != null && suffix != null && suffix.isNotEmpty && s.endsWith(suffix)) {
    return s.substring(0, s.length - suffix.length);
  }
  return s;
}

/// Static util methods used in dartdev to potentially modify the order of the
/// arguments passed into dartdev.
class PubUtils {
  /// If [doModifyArgs] returns true, then this method returns a modified copy
  /// of the argument list, 'help' is removed from the interior of the list, and
  /// '--help' is added to the end of the list of arguments. This method returns
  /// a modified copy of the list, the list itself is not modified.
  static List<String> modifyArgs(List<String> args) => List.from(args)
    ..remove('help')
    ..add('--help');

  /// If ... help pub ..., and no other verb (such as 'analyze') appears before
  /// the ... help pub ... in the argument list, then return true.
  static bool shouldModifyArgs(List<String> args, List<String> allCmds) =>
      args != null &&
      allCmds != null &&
      args.isNotEmpty &&
      allCmds.isNotEmpty &&
      args.firstWhere((arg) => allCmds.contains(arg)) == 'help' &&
      args.contains('help') &&
      args.contains('pub') &&
      args.indexOf('help') + 1 == args.indexOf('pub');
}

extension FileSystemEntityExtension on FileSystemEntity {
  String get name => p.basename(path);

  bool get isDartFile => this is File && p.extension(path) == '.dart';
}
