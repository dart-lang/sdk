// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'io.dart';
import 'log.dart';

Future<bool> analyzeTests(String nnbdTestDir) async {
  var files = <String, _FileInfo>{};

  for (var entry in Directory(nnbdTestDir).listSync(recursive: true)) {
    if (entry is File && entry.path.endsWith(".dart")) {
      // Skip multitests since they aren't valid Dart files.
      var isTest = entry.path.endsWith("_test.dart") &&
          !readFile(entry.path).contains("//#");

      files[entry.path] = _FileInfo(entry.path, isTest: isTest);
    }
  }

  // Pre-existing multi-line errors will modify the character length in the
  // errors reported by the analyzer. Strip all errors first before updating.
  for (var file in files.values) {
    if (!dryRun) _removeErrors(file.path);
  }

  // Analyze the directory both in legacy and NNBD modes.
  var legacyErrorsFuture = _runAnalyzer(nnbdTestDir, nnbd: false);
  var nnbdErrorsFuture = _runAnalyzer(nnbdTestDir, nnbd: true);

  var legacyErrors = await legacyErrorsFuture;
  var nnbdErrors = await nnbdErrorsFuture;

  legacyErrors.forEach((path, errors) {
    // Sometimes the analysis reaches out to things like pkg/expect.
    if (!files.containsKey(path)) {
      files[path] = _FileInfo(path, isTest: false);
    }

    files[path].legacyErrors.addAll(errors);
  });

  nnbdErrors.forEach((path, errors) {
    // Sometimes the analysis reaches out to things like pkg/expect.
    if (!files.containsKey(path)) {
      files[path] = _FileInfo(path, isTest: false);
    }

    files[path].nnbdErrors.addAll(errors);
  });

  var fileCount = 0;
  var errorFileCount = 0;
  var errorCount = 0;

  plural(int count, String name) => "$count $name${count == 1 ? '' : 's'}";

  var fileNames = files.keys.toList()..sort();
  for (var fileName in fileNames) {
    var file = files[fileName];
    if (!file.isTest) continue;

    // Only insert errors that are not already present when the file is
    // analyzed as a legacy library.
    file.calculateDifferences();

    fileCount++;
    errorCount += file.addedErrors.length;
    if (file.addedErrors.length > 0) {
      var count = file.addedErrors.length;
      print("${p.relative(file.path, from: testRoot)}: " +
          plural(count, 'error'));
      errorFileCount++;
    }

    if (!dryRun) _insertErrors(file.path, file.addedErrors);
  }

  if (errorCount == 0) {
    print(green("All ${plural(fileCount, 'file')} are static error free!"));
  } else {
    print(red("Analyzed ${plural(fileCount, 'file')} and found "
        "${plural(errorCount, 'error')} "
        "in ${plural(errorFileCount, 'file')}."));
  }

  return errorCount == 0;
}

Future<Map<String, List<_StaticError>>> _runAnalyzer(String inputDir,
    {bool nnbd}) async {
  print("Analyzing ${p.relative(inputDir, from: testRoot)}"
      "${nnbd ? ' with NNBD' : ''}...");
  var result = await Process.run("dartanalyzer", [
    "--packages=${p.join(sdkRoot, '.packages')}",
    if (nnbd) "--enable-experiment=non-nullable",
    "--format=machine",
    inputDir,
  ]);
  // TODO(rnystrom): How do we pass in options from the test files?

  var errors = _StaticError.parse(result.stderr as String);
  var errorsByFile = <String, List<_StaticError>>{};
  for (var error in errors) {
    if (error.code.startsWith("HINT.")) continue;
    errorsByFile.putIfAbsent(error.file, () => []).add(error);
  }

  for (var errors in errorsByFile.values) {
    errors.sort();
  }

  return errorsByFile;
}

/// Removes pre-existing errors in the file at [path].
void _removeErrors(String path) {
  // Sanity check.
  if (!p.isWithin(testRoot, path)) {
    throw ArgumentError("$path is outside of test directory.");
  }

  var lines = readFileLines(path);
  var result = StringBuffer();
  var changed = false;

  for (var i = 0; i < lines.length; i++) {
    // Strip out previous inserted comments.
    if (!lines[i].startsWith("//|")) {
      result.writeln(lines[i]);
    } else {
      changed = true;
    }
  }

  if (changed) {
    writeFile(path, result.toString());
  }
}

/// Inserts any new errors in [errors] into the file at [path].
void _insertErrors(String path, List<_StaticError> errors) {
  // Sanity check.
  if (!p.isWithin(testRoot, path)) {
    throw ArgumentError("$path is outside of test directory.");
  }

  var lines = readFileLines(path);
  var result = StringBuffer();
  var changed = false;

  for (var i = 0; i < lines.length; i++) {
    result.writeln(lines[i]);
    // TODO(rnystrom): Inefficient.
    for (var error in errors) {
      if (error.line == i + 1) {
        result.write("//|");
        result.write(" " * (error.column - 3));
        result.write("^" * error.length);
        result.writeln(" ${error.code}");
        result.writeln("//| ${error.message}");
        changed = true;
      }
    }
  }

  if (changed) {
    writeFile(path, result.toString());
  }
}

class _FileInfo {
  final String path;
  final bool isTest;

  final Set<_StaticError> legacyErrors = {};
  final Set<_StaticError> nnbdErrors = {};

  final List<_StaticError> removedErrors = [];
  final List<_StaticError> addedErrors = [];

  _FileInfo(this.path, {this.isTest});

  void calculateDifferences() {
    removedErrors.addAll(legacyErrors.toSet().difference(nnbdErrors.toSet()));
    addedErrors.addAll(nnbdErrors.toSet().difference(legacyErrors.toSet()));
  }
}

class _StaticError implements Comparable<_StaticError> {
  static List<_StaticError> parse(String stderr) {
    List<String> splitMachineError(String line) {
      var field = StringBuffer();
      var result = <String>[];
      var escaped = false;
      for (var i = 0; i < line.length; i++) {
        var c = line[i];
        if (!escaped && c == '\\') {
          escaped = true;
          continue;
        }
        escaped = false;
        if (c == '|') {
          result.add(field.toString());
          field = StringBuffer();
          continue;
        }
        field.write(c);
      }
      result.add(field.toString());
      return result;
    }

    var errors = <_StaticError>[];
    for (var line in stderr.split("\n")) {
      if (line.isEmpty) continue;

      var fields = splitMachineError(line);

      // Lines without enough fields are other output we don't care about.
      if (fields.length >= 8) {
        var error = _StaticError(fields[3],
            line: int.parse(fields[4]),
            column: int.parse(fields[5]),
            length: int.parse(fields[6]),
            code: "${fields[1]}.${fields[2]}",
            message: fields[7]);

        errors.add(error);
      } else {
        print(line);
      }
    }

    return errors;
  }

  final String file;

  /// The one-based line number of the beginning of the error's location.
  final int line;

  /// The one-based column number of the beginning of the error's location.
  final int column;

  /// The number of characters in the error location.
  ///
  /// This is optional. The CFE only reports error location, but not length.
  final int length;

  /// The expected analyzer error code for the error or `null` if this error
  /// isn't expected to be reported by analyzer.
  final String code;

  /// The expected CFE error message or `null` if this error isn't expected to
  /// be reported by the CFE.
  final String message;

  /// Creates a new StaticError at the given location with the given expected
  /// error code and message.
  ///
  /// In order to make it easier to incrementally add error tests before a
  /// feature is fully implemented or specified, an error expectation can be in
  /// an "unspecified" state for either or both platforms by having the error
  /// code or message be the special string "unspecified". When an unspecified
  /// error is tested, a front end is expected to report *some* error on that
  /// error's line, but it can be any location, error code, or message.
  _StaticError(this.file,
      {this.line, this.column, this.length, this.code, this.message}) {
    // Must have a location.
    assert(line != null);
    assert(column != null);

    // Must have at least one piece of description.
    assert(code != null || message != null);
  }

  /// A textual description of this error's location.
  String get location {
    var result = "line $line, column $column";
    if (length != null) result += ", length $length";
    return result;
  }

  String toString() => "Error $code in $file at $location: $message";

  String toStringWithoutPath() => "[$location] $code: $message";

  /// Orders errors primarily by location, then by other fields if needed.
  @override
  int compareTo(_StaticError other) {
    if (file != other.file) return file.compareTo(other.file);
    if (line != other.line) return line.compareTo(other.line);
    if (column != other.column) return column.compareTo(other.column);

    // Sort no length after all other lengths.
    if (length == null && other.length != null) return 1;
    if (length != null && other.length == null) return -1;
    if (length != other.length) return length.compareTo(other.length);

    var thisCode = code ?? "";
    var otherCode = other.code ?? "";
    if (thisCode != otherCode) return thisCode.compareTo(otherCode);

    var thisMessage = message ?? "";
    var otherMessage = other.message ?? "";
    return thisMessage.compareTo(otherMessage);
  }

  bool operator ==(dynamic other) =>
      other is _StaticError &&
      file == other.file &&
      line == other.line &&
      column == other.column &&
      length == other.length &&
      normalizeCode(code) == normalizeCode(other.code);

  int get hashCode =>
      line.hashCode ^
      column.hashCode ^
      length.hashCode ^
      normalizeCode(code).hashCode;

  String normalizeCode(String code) {
    // Pre-NNBD has a limited form of implicit downcast checking for
    // constructors.
    if (code == "COMPILE_TIME_ERROR.INVALID_CAST_NEW_EXPR") {
      return "STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE";
    }

    return code;
  }
}
