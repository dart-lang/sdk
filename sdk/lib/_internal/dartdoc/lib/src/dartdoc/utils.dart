// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generic utility functions.
library utils;

import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as pathos;

import '../../../../compiler/implementation/mirrors/mirrors.dart';

import '../export_map.dart';

/** Turns [name] into something that's safe to use as a file name. */
String sanitize(String name) => name.replaceAll(':', '_').replaceAll('/', '_');

/** Returns the number of times [search] occurs in [text]. */
int countOccurrences(String text, String search) {
  int start = 0;
  int count = 0;

  while (true) {
    start = text.indexOf(search, start);
    if (start == -1) break;
    count++;
    // Offsetting by search length means overlapping results are not counted.
    start += search.length;
  }

  return count;
}

/** Repeats [text] [count] times, separated by [separator] if given. */
String repeat(String text, int count, {String separator}) {
  // TODO(rnystrom): Should be in corelib.
  final buffer = new StringBuffer();
  for (int i = 0; i < count; i++) {
    buffer.write(text);
    if ((i < count - 1) && (separator != null)) buffer.write(separator);
  }

  return buffer.toString();
}

/** Removes up to [indentation] leading whitespace characters from [text]. */
String unindent(String text, int indentation) {
  var start;
  for (start = 0; start < math.min(indentation, text.length); start++) {
    // Stop if we hit a non-whitespace character.
    if (text[start] != ' ') break;
  }

  return text.substring(start);
}

/** Sorts the map by the key, doing a case-insensitive comparison. */
List<Mirror> orderByName(Iterable<Mirror> list) {
  final elements = new List<Mirror>.from(list);
  elements.sort((a,b) {
    String aName = a.simpleName.toLowerCase();
    String bName = b.simpleName.toLowerCase();
    bool doma = aName.startsWith(r"$dom");
    bool domb = bName.startsWith(r"$dom");
    return doma == domb ? aName.compareTo(bName) : doma ? 1 : -1;
  });
  return elements;
}

/**
 * Joins [items] into a single, comma-separated string using [conjunction].
 * E.g. `['A', 'B', 'C']` becomes `"A, B, and C"`.
 */
String joinWithCommas(List<String> items, [String conjunction = 'and']) {
  if (items.length == 1) return items[0];
  if (items.length == 2) return "${items[0]} $conjunction ${items[1]}";
  return '${items.take(items.length - 1).join(', ')}'
    ', $conjunction ${items[items.length - 1]}';
}

void writeString(File file, String text) {
  var randomAccessFile = file.openSync(mode: FileMode.WRITE);
  randomAccessFile.writeStringSync(text);
  randomAccessFile.closeSync();
}

/**
 * Converts [uri], which should come from a Dart import or export, to a local
 * filesystem path. [basePath] is the base directory to use when converting
 * relative URIs; without it, relative URIs will not be converted. [packageRoot]
 * is the `packages` directory to use when converting `package:` URIs; without
 * it, `package:` URIs will not be converted.
 *
 * If a URI cannot be converted, this will return `null`.
 */
String importUriToPath(Uri uri, {String basePath, String packageRoot}) {
  if (uri.scheme == 'file') return pathos.fromUri(uri);

  if (basePath != null && uri.scheme == '') {
    return pathos.normalize(pathos.absolute(pathos.join(basePath, uri.path)));
  }

  if (packageRoot != null && uri.scheme == 'package') {
    return pathos.normalize(pathos.absolute(
        pathos.join(packageRoot, uri.path)));
  }

  // Ignore unsupported schemes.
  return null;
}

/**
 * If [map] contains an [Export] under [key], this merges that with [export].
 * Otherwise, it sets [key] to [export].
 */
void addOrMergeExport(Map<String, Export> map, String key, Export export) {
  if (map.containsKey(key)) {
    map[key] = map[key].merge(export);
  } else {
    map[key] = export;
  }
}

/// A pair of values.
class Pair<E, F> {
  E first;
  F last;

  Pair(this.first, this.last);

  String toString() => '($first, $last)';

  bool operator==(other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }

  int get hashCode => first.hashCode ^ last.hashCode;
}
