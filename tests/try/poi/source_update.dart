// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.source_update;

/// Returns [updates] expanded to full compilation units/source files.
///
/// [updates] is a convenient way to write updates/patches to a single source
/// file without repeating common parts.
///
/// For example:
///   ["head ", ["v1", "v2"], " tail"]
/// expands to:
///   ["head v1 tail", "head v2 tail"]
List<String> expandUpdates(List updates) {
  int outputCount = updates.firstWhere((e) => e is Iterable).length;
  List<StringBuffer> result = new List<StringBuffer>(outputCount);
  for (int i = 0; i < outputCount; i++) {
    result[i] = new StringBuffer();
  }
  for (var chunk in updates) {
    if (chunk is Iterable) {
      int segmentCount = 0;
      for (var segment in chunk) {
        result[segmentCount++].write(segment);
      }
      if (segmentCount != outputCount) {
        throw new ArgumentError(
            "Expected ${outputCount} segments, "
            "but found ${segmentCount} in $chunk");
      }
    } else {
      for (StringBuffer buffer in result) {
        buffer.write(chunk);
      }
    }
  }

  return result.map((e) => '$e').toList();
}

/// Returns [files] split into multiple named files. The keys in the returned
/// map are filenames, the values are the files' content.
///
/// Names are indicated by a line on the form "==> filename <==". Spaces are
/// significant. For example, given this input:
///
///     ==> file1.dart <==
///     First line of file 1.
///     Second line of file 1.
///     Third line of file 1.
///     ==> empty.dart <==
///     ==> file2.dart <==
///     First line of file 2.
///     Second line of file 2.
///     Third line of file 2.
///
/// This function would return:
///
///     {
///       "file1.dart": """
///     First line of file 1.
///     Second line of file 1.
///     Third line of file 1.
///     """,
///
///       "empty.dart":"",
///
///       "file2.dart":"""
///     First line of file 2.
///     Second line of file 2.
///     Third line of file 2.
///     """
///     }
Map<String, String> splitFiles(String files) {
  Map<String, String> result = <String, String>{};
  String currentName;
  List<String> content;
  void finishFile() {
    if (currentName != null) {
      if (result.containsKey(currentName)) {
        throw new ArgumentError("Duplicated filename $currentName in $files");
      }
      result[currentName] = content.join('');
    }
    content = null;
  }
  void processDirective(String line) {
    finishFile();
    if (line.length < 8 || !line.endsWith(" <==\n")) {
      throw new ArgumentError(
          "Malformed line: expected '==> ... <==', but got: '$line'");
    }
    currentName = line.substring(4, line.length - 5);
    content = <String>[];
  }
  for (String line in splitLines(files)) {
    if (line.startsWith("==>")) {
      processDirective(line);
    } else {
      content.add(line);
    }
  }
  finishFile();
  return result;
}

/// Split [text] into lines preserving trailing newlines (unlike
/// String.split("\n"). Also, if [text] is empty, return an empty list (unlike
/// String.split("\n")).
List<String> splitLines(String text) {
  return text.split(new RegExp('^', multiLine: true));
}

/// Expand a file with diffs in common merge conflict format into a [List] that
/// can be passed to [expandUpdates].
///
/// For example:
///     first
///     <<<<<<<
///     v1
///     =======
///     v2
///     =======
///     v3
///     >>>>>>>
///     last
///
/// Would be expanded to something equivalent to:
///
///     ["first\n", ["v1\n", "v2\n", "v3\n"], "last\n"]
List expandDiff(String text) {
  List result = [new StringBuffer()];
  bool inDiff = false;
  for (String line in splitLines(text)) {
    if (inDiff) {
      if (line.startsWith("=======")) {
        result.last.add(new StringBuffer());
      } else if (line.startsWith(">>>>>>>")) {
        inDiff = false;
        result.add(new StringBuffer());
      } else {
        result.last.last.write(line);
      }
    } else if (line.startsWith("<<<<<<<")) {
      inDiff = true;
      result.add(<StringBuffer>[new StringBuffer()]);
    } else {
      result.last.write(line);
    }
  }
  return result;
}
