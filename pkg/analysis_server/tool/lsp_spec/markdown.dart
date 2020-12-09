// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final _methodNamesPattern = RegExp(
    r'''_(?:Notification|Request):?_:?(?:\r?\n)+\* method: ['`](.*?)[`'],?\r?\n''',
    multiLine: true);
final _typeScriptBlockPattern =
    RegExp(r'\B```typescript([\S\s]*?)\n\s*```', multiLine: true);

List<String> extractMethodNames(String spec) {
  return _methodNamesPattern
      .allMatches(spec)
      .map((m) => m.group(1).trim())
      .toList();
}

/// Extracts fenced code blocks that are explicitly marked as TypeScript from a
/// markdown document.
List<String> extractTypeScriptBlocks(String text) {
  return _typeScriptBlockPattern
      .allMatches(text)
      .map((m) => m.group(1).trim())
      .toList();
}
