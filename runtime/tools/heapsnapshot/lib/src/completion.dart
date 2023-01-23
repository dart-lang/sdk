// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

class PostfixCompleter {
  final String text;

  PostfixCompleter(this.text);

  String? tryComplete(String partial, List<String> candidates) {
    if (!text.endsWith(partial)) throw 'caller error';
    final completion = _selectCandidate(partial, candidates);
    if (completion != null) {
      return text.substring(0, text.length - partial.length) + completion;
    }
    return null;
  }
}

String? _selectCandidate(String prefix, List<String> candidates) {
  // If there's an exact match, use that.
  if (candidates.any((candidate) => prefix == candidate)) {
    return prefix;
  }

  // Otherwise use the longest possible completion.
  candidates = candidates
      .where((c) => prefix.length < c.length && c.startsWith(prefix))
      .toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.length - a.length);
  return candidates.first;
}

final homePath = Platform.environment['HOME']!;

String? tryCompleteFileSystemEntity(
    String incompleteFilePattern, bool Function(String) consider) {
  if (incompleteFilePattern.isEmpty) return null;

  final filename = incompleteFilePattern.endsWith(path.separator)
      ? ''
      : path.basename(incompleteFilePattern);
  final dirname = incompleteFilePattern.substring(
      0, incompleteFilePattern.length - filename.length);

  final dir = dirname != ''
      ? Directory(dirname.startsWith('~/')
          ? (homePath + dirname.substring(1))
          : dirname)
      : Directory.current;

  if (dir.existsSync()) {
    final entries = dir
        .listSync()
        .where((fse) => fse is File && consider(fse.path) || fse is Directory)
        .map((fse) => path.basename(fse.path))
        .toList();
    final pc = PostfixCompleter(incompleteFilePattern);
    return pc.tryComplete(filename, entries);
  }

  return null;
}

final _spaceCodeUnit = ' '.codeUnitAt(0);

String getFirstWordWithSpaces(String text) {
  int i = 0;
  while (i < text.length && text.codeUnitAt(i) != _spaceCodeUnit) i++;
  while (i < text.length && text.codeUnitAt(i) == _spaceCodeUnit) i++;
  return text.substring(0, i);
}

String getLastWord(String text) {
  return text.substring(text.lastIndexOf(' ') + 1);
}
