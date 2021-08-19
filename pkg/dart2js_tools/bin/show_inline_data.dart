// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2js_tools/src/util.dart';

/// Script to show a text representation of the inlining data attached to
/// source-map files.
///
/// This expands the push/pop operations and checks simple invariants (e.g. that
/// the stack is always empty at the beginning of a function).
main(List<String> args) {
  if (args.length != 1) {
    print('usage: show_inline_data.dart <js-file>');
    exit(1);
  }
  var uri = Uri.base.resolve(args[0]);
  var provider = new CachingFileProvider();

  var mapping = provider.mappingFor(uri);
  var starts = functionStarts(provider.sourcesFor(uri));
  var file = provider.fileFor(uri);
  var frames = mapping.frames;
  var offsets = frames.keys.toList()..sort();
  var sb = new StringBuffer();
  int depth = 0;
  int lastFunctionStart = null;
  for (var offset in offsets) {
    int functionStart = nextFunctionStart(starts, offset, lastFunctionStart);
    if (lastFunctionStart == null || functionStart > lastFunctionStart) {
      sb.write('\n${location(starts[functionStart], file)}: function start\n');

      if (depth != 0) {
        sb.write(
            "[31m[invalid] function start with non-zero depth: $depth[0m\n");
      }
      lastFunctionStart = functionStart;
    }

    var offsetPrefix = '${location(offset, file)}:';
    var pad = ' ' * offsetPrefix.length;
    sb.write(offsetPrefix);
    bool first = true;
    for (var frame in frames[offset]) {
      if (!first) sb.write('$pad');
      sb.write(' $frame\n');
      first = false;
      if (frame.isPush) depth++;
      if (frame.isPop) depth--;
      if (frame.isEmpty && depth != 0) {
        sb.write("[31m[invalid] pop-empty with non-zero depth: $depth[0m\n");
      }
      if (!frame.isEmpty && depth == 0) {
        sb.write("[31m[invalid] non-empty pop with zero depth: $depth[0m\n");
      }
      if (depth < 0) {
        sb.write("[31m[invalid] negative depth: $depth[0m\n");
      }
    }
  }
  print('$sb');
}

var _functionDeclarationRegExp = new RegExp(r':( )?function\(');

List<int> functionStarts(String sources) {
  List<int> result = [];
  int index = sources.indexOf(_functionDeclarationRegExp);
  while (index != -1) {
    result.add(index + 2);
    index = sources.indexOf(_functionDeclarationRegExp, index + 1);
  }
  return result;
}

int nextFunctionStart(List<int> starts, int offset, int last) {
  int j = last ?? 0;
  for (; j < starts.length && starts[j] <= offset; j++);
  return j - 1;
}

String location(int offset, file) {
  var line = file.getLine(offset) + 1;
  var column = file.getColumn(offset) + 1;
  var location = '$offset ($line:$column)';
  return location + (' ' * (16 - location.length));
}
