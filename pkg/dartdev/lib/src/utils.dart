// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

/// For commands where we are able to initialize the [ArgParser], this value
/// is used as the usageLineLength.
int? get dartdevUsageLineLength =>
    stdout.hasTerminal ? stdout.terminalColumns : null;

/// Global options for dartdev.
///
///  ** READ THIS BEFORE MODIFYING **
///
/// Adding or changing behavior for global flags may have consequences for
/// integration with the VM.  Check `runtime/bin/main_options.cc` in the
/// Dart SDK if adding or changing any flags.  This is most important for
/// those that are intended to be run without a script such as
/// `dart --disable-analytics` as there is special handling.  Any flags
/// added here should also be tested by hand with a compiled SDK as unit tests
/// running `dartdev.dart` directly do not hit that code path.
ArgParser globalDartdevOptionsParser({bool verbose = false}) {
  var argParser = ArgParser(
    usageLineLength: dartdevUsageLineLength,
    allowTrailingOptions: false,
  );
  argParser.addFlag('verbose',
      abbr: 'v', negatable: false, help: 'Show additional command output.');
  argParser.addFlag('version',
      negatable: false, help: 'Print the Dart SDK version.');
  argParser.addFlag('enable-analytics',
      negatable: false, help: 'Enable analytics.');
  argParser.addFlag('disable-analytics',
      negatable: false, help: 'Disable analytics.');
  argParser.addFlag('disable-telemetry',
      negatable: false, help: 'Disable telemetry.', hide: true);

  argParser.addFlag('diagnostics',
      negatable: false, help: 'Show tool diagnostic output.', hide: !verbose);

  argParser.addFlag(
    'analytics',
    defaultsTo: true,
    negatable: true,
    help: 'Allow or disallow analytics for this `dart *` run without '
        'changing the analytics configuration.  '
        'Deprecated: use `--suppress-analytics` instead.',
    hide: true,
  );

  argParser.addFlag(
    'suppress-analytics',
    negatable: false,
    help: 'Disallow analytics for this `dart *` run without changing the '
        'analytics configuration.',
  );
  return argParser;
}

/// Try parsing [maybeUri] as a file uri or [maybeUri] itself if that fails.
String maybeUriToFilename(String maybeUri) {
  try {
    return Uri.parse(maybeUri).toFilePath();
  } catch (_) {
    return maybeUri;
  }
}

/// Given a data structure which is a Map of String to dynamic values, return
/// the same structure (`Map<String, dynamic>`) with the correct runtime types.
Map<String, dynamic> castStringKeyedMap(dynamic untyped) {
  final Map<dynamic, dynamic> map = untyped! as Map<dynamic, dynamic>;
  return map.cast<String, dynamic>();
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
String trimEnd(String s, String? suffix) {
  if (suffix != null && suffix.isNotEmpty && s.endsWith(suffix)) {
    return s.substring(0, s.length - suffix.length);
  }
  return s;
}

extension FileSystemEntityExtension on FileSystemEntity {
  String get name => p.basename(path);

  bool get isDartFile => this is File && p.extension(path) == '.dart';
}

/// Wraps [text] to the given [width], if provided.
String wrapText(String text, {int? width}) {
  if (width == null) {
    return text;
  }

  var buffer = StringBuffer();
  var lineMaxEndIndex = width;
  var lineStartIndex = 0;

  while (true) {
    if (lineMaxEndIndex >= text.length) {
      buffer.write(text.substring(lineStartIndex, text.length));
      break;
    } else {
      var lastSpaceIndex = text.lastIndexOf(' ', lineMaxEndIndex);
      if (lastSpaceIndex == -1 || lastSpaceIndex <= lineStartIndex) {
        // No space between [lineStartIndex] and [lineMaxEndIndex]. Get the
        // _next_ space.
        lastSpaceIndex = text.indexOf(' ', lineMaxEndIndex);
        if (lastSpaceIndex == -1) {
          // No space at all after [lineStartIndex].
          lastSpaceIndex = text.length;
          buffer.write(text.substring(lineStartIndex, lastSpaceIndex));
          break;
        }
      }
      buffer.write(text.substring(lineStartIndex, lastSpaceIndex));
      buffer.writeln();
      lineStartIndex = lastSpaceIndex + 1;
    }
    lineMaxEndIndex = lineStartIndex + width;
  }
  return buffer.toString();
}

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp(r'^[a-z_][a-z\d_]*$');

// non-contextual dart keywords.
// https://dart.dev/guides/language/language-tour#keywords
const Set<String> _keywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'inout',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'native',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'out',
  'part',
  'patch',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'source',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};

/// Whether [name] is a valid Pub package.
bool isValidPackageName(String name) =>
    _identifierRegExp.hasMatch(name) && !_keywords.contains(name);

/// Convert a directory name into a reasonably legal pub package name.
String normalizeProjectName(String name) {
  name = name.replaceAll('-', '_').replaceAll(' ', '_');
  // Strip any extension (like .dart).
  var dotIndex = name.indexOf('.');
  if (dotIndex >= 0) {
    name = name.substring(0, dotIndex);
  }
  return name;
}

/// A utility class to generate a markdown table into a string.
///
/// To use this class:
///
/// ```
/// var table = MarkdownTable();
/// for (var foo in foos) {
///   table.startRow()
///     ..cell(foo.bar)
///     ..cell(foo.baz.toStringAsFixed(1), right: true)
///     ..cell(foo.qux);
/// }
/// print(table.finish());
/// ```
class MarkdownTable {
  static const int defaultMaxWidth = 90;
  static const int _minWidth = 3;

  final List<List<_MarkdownCell>> _data = [];

  MarkdownRow startRow() {
    _data.add([]);
    return MarkdownRow(this);
  }

  String finish() {
    if (_data.isEmpty) return '';
    var header = _data.first;

    var widths = <int>[];

    for (int col = 0; col < header.length; col++) {
      var width = _data.map((row) {
        var item = row.length >= col ? row[col] : null;
        return item?.value.length ?? 0;
      }).reduce(math.max);
      widths.add(math.max(width, _minWidth));
    }

    var buffer = StringBuffer();

    for (var row in _data) {
      buffer.write('| ');
      for (int col = 0; col < row.length; col++) {
        if (col != 0) buffer.write(' | ');
        var cell = row[col];
        var width = math.min(widths[col], defaultMaxWidth);
        var value = cell.value;
        buffer.write(cell.right ? value.padLeft(width) : value.padRight(width));
      }
      buffer.writeln(' |');

      if (row == _data.first) {
        // Write the alignment row.
        buffer.write('| ');
        for (int col = 0; col < row.length; col++) {
          if (col != 0) buffer.write(' | ');
          var cell = row[col];
          var width = math.min(widths[col], defaultMaxWidth);
          var value = cell.right ? '--:' : '---';
          buffer.write(value.padLeft(width, '-'));
        }
        buffer.writeln(' |');
      }
    }

    return buffer.toString();
  }
}

/// Used to build a row in a markdown table.
class MarkdownRow {
  final MarkdownTable _table;

  MarkdownRow(this._table);

  void cell(String value, {bool right = false}) {
    _table._data.last.add(_MarkdownCell(value, right));
  }
}

class _MarkdownCell {
  final String value;
  final bool right;

  _MarkdownCell(this.value, this.right);
}
