// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Multitests are Dart test scripts containing lines of the form
/// " [some dart code] //# [key]: [error type]"
///
/// To support legacy multi tests we also handle lines of the form
/// " [some dart code] /// [key]: [error type]"
///
/// For each key in the file, a new test file is made containing all the normal
/// lines of the file, and all of the multitest lines containing that key, in
/// the same order as in the source file. The new test is expected to pass if
/// the error type listed is 'ok', and to fail if the error type is 'syntax
/// error', 'compile-time error', 'runtime error', 'static type warning',
/// 'dynamic type error', or 'checked mode compile-time error'. The type error
/// tests fail only in checked mode. There is also a test created from only the
/// untagged lines of the file, with key "none", which is expected to pass. This
/// library extracts these tests, writes them into a temporary directory, and
/// passes them to the test runner. These tests may be referred to in the status
/// files with the pattern [test name]/[key].
///
/// For example, file i_am_a_multitest.dart:
///
/// ```dart
/// aaa
/// bbb //# 02: runtime error
/// ccc //# 02: continued
/// ddd //# 07: static type warning
/// eee //# 10: ok
/// fff
/// ```
///
/// Create four test files:
///
/// i_am_a_multitest_none.dart:
///
/// ```dart
/// aaa
/// fff
/// ```
///
/// i_am_a_multitest_02.dart:
///
/// ```dart
/// aaa
/// bbb //# 02: runtime error
/// ccc //# 02: continued
/// fff
/// ```
///
/// i_am_a_multitest_07.dart:
///
/// ```dart
/// aaa
/// ddd //# 07: static type warning
/// fff
/// ```
///
/// i_am_a_multitest_10.dart:
///
/// ```dart
/// aaa
/// eee //# 10: ok
/// fff
/// ```
///
/// Note that it is possible to indicate more than one acceptable outcome in
/// the case of dynamic and static type warnings
///
/// ```dart
/// aaa
/// ddd //# 07: static type warning, dynamic type error
/// fff
/// ```
import "dart:async";
import "dart:io";

import "path.dart";
import "test_suite.dart";
import "utils.dart";

/// Until legacy multitests are ported we need to support both /// and //#
final _multitestMarker = new RegExp(r"//[/#]");

final _multitestOutcomes = [
  'ok',
  'syntax error',
  'compile-time error',
  'runtime error',
  // TODO(rnystrom): Remove these after Dart 1.0 tests are removed.
  'static type warning',
  'dynamic type error',
  'checked mode compile-time error'
].toSet();

// Note: This function is called directly by:
//
//     tests/compiler/dart2js/frontend_checker.dart
//     tools/status_clean.dart
void extractTestsFromMultitest(Path filePath, Map<String, String> tests,
    Map<String, Set<String>> outcomes) {
  var contents = new File(filePath.toNativePath()).readAsStringSync();

  var firstNewline = contents.indexOf('\n');
  var lineSeparator =
      (firstNewline == 0 || contents[firstNewline - 1] != '\r') ? '\n' : '\r\n';
  var lines = contents.split(lineSeparator);
  if (lines.last == '') lines.removeLast();

  // Create the set of multitests, which will have a new test added each
  // time we see a multitest line with a new key.
  var testsAsLines = <String, List<String>>{};

  // Add the default case with key "none".
  testsAsLines['none'] = <String>[];
  outcomes['none'] = new Set<String>();

  var lineCount = 0;
  for (var line in lines) {
    lineCount++;
    var annotation = _Annotation.tryParse(line);
    if (annotation != null) {
      testsAsLines.putIfAbsent(
          annotation.key, () => new List<String>.from(testsAsLines["none"]));
      // Add line to test with annotation.key as key, empty line to the rest.
      for (var key in testsAsLines.keys) {
        testsAsLines[key].add(annotation.key == key ? line : "");
      }
      outcomes.putIfAbsent(annotation.key, () => new Set<String>());
      if (annotation.rest != 'continued') {
        for (var nextOutcome in annotation.outcomes) {
          if (_multitestOutcomes.contains(nextOutcome)) {
            outcomes[annotation.key].add(nextOutcome);
          } else {
            DebugLogger
                .warning("Warning: Invalid expectation '$nextOutcome' on line "
                    "$lineCount:\n${annotation.rest} ");
          }
        }
      }
    } else {
      for (var test in testsAsLines.values) test.add(line);
    }
  }

  // End marker, has a final line separator so we don't need to add it after
  // joining the lines.
  var marker =
      '// Test created from multitest named ${filePath.toNativePath()}.'
      '$lineSeparator';
  for (var test in testsAsLines.values) test.add(marker);

  // Check that every test (other than the none case) has at least one outcome.
  var invalidTests = outcomes.keys
      .where((test) => test != 'none' && outcomes[test].isEmpty)
      .toList();
  for (var test in invalidTests) {
    DebugLogger.warning("Warning: Test $test has no valid expectation.\n"
        "Expected one of: ${_multitestOutcomes.toString()}");

    outcomes.remove(test);
    testsAsLines.remove(test);
  }

  // Copy all the tests into the output map tests, as multiline strings.
  for (var key in testsAsLines.keys) {
    tests[key] = testsAsLines[key].join(lineSeparator);
  }
}

Future doMultitest(Path filePath, String outputDir, Path suiteDir,
    CreateTest doTest, bool hotReload) {
  void writeFile(String filepath, String content) {
    final File file = new File(filepath);

    if (file.existsSync()) {
      var oldContent = file.readAsStringSync();
      if (oldContent == content) {
        // Don't write to the file if the content is the same
        return;
      }
    }
    file.writeAsStringSync(content);
  }

  // Each new test is a single String value in the Map tests.
  var tests = <String, String>{};
  var outcomes = <String, Set<String>>{};
  extractTestsFromMultitest(filePath, tests, outcomes);

  var sourceDir = filePath.directoryPath;
  var targetDir = _createMultitestDirectory(outputDir, suiteDir, sourceDir);
  assert(targetDir != null);

  // Copy all the relative imports of the multitest.
  var importsToCopy = _findAllRelativeImports(filePath);
  var futureCopies = <Future>[];
  for (var relativeImport in importsToCopy) {
    var importPath = new Path(relativeImport);
    // Make sure the target directory exists.
    var importDir = importPath.directoryPath;
    if (!importDir.isEmpty) {
      TestUtils.mkdirRecursive(targetDir, importDir);
    }

    // Copy file.
    futureCopies.add(TestUtils.copyFile(
        sourceDir.join(importPath), targetDir.join(importPath)));
  }

  // Wait until all imports are copied before scheduling test cases.
  return Future.wait(futureCopies).then((_) {
    var baseFilename = filePath.filenameWithoutExtension;
    for (var key in tests.keys) {
      var multitestFilename = targetDir.append('${baseFilename}_$key.dart');
      writeFile(multitestFilename.toNativePath(), tests[key]);

      var outcome = outcomes[key];
      var hasStaticWarning = outcome.contains('static type warning');
      var hasRuntimeError = outcome.contains('runtime error');
      var hasSyntaxError = outcome.contains('syntax error');
      var hasCompileError =
          hasSyntaxError || outcome.contains('compile-time error');
      var isNegativeIfChecked = outcome.contains('dynamic type error');
      var hasCompileErrorIfChecked =
          outcome.contains('checked mode compile-time error');

      if (hotReload) {
        if (hasCompileError || hasCompileErrorIfChecked) {
          // Running a test that expects a compilation error with hot reloading
          // is redundant with a regular run of the test.
          continue;
        }
      }

      doTest(multitestFilename, filePath,
          hasSyntaxError: hasSyntaxError,
          hasCompileError: hasCompileError,
          hasRuntimeError: hasRuntimeError,
          isNegativeIfChecked: isNegativeIfChecked,
          hasCompileErrorIfChecked: hasCompileErrorIfChecked,
          hasStaticWarning: hasStaticWarning,
          multitestKey: key);
    }

    return null;
  });
}

/// A multitest annotation in the special `//#` comment.
class _Annotation {
  /// Parses the annotation in [line] or returns `null` if the line isn't a
  /// multitest annotation.
  static _Annotation tryParse(String line) {
    // Do an early return with "null" if this is not a valid multitest
    // annotation.
    if (!line.contains(_multitestMarker)) return null;

    var parts = line
        .split(_multitestMarker)[1]
        .split(':')
        .map((s) => s.trim())
        .where((s) => s.length > 0)
        .toList();

    if (parts.length <= 1) return null;

    return new _Annotation._(parts[0], parts[1]);
  }

  final String key;
  final String rest;

  // TODO(rnystrom): After Dart 1.0 is no longer supported, I don't think we
  // need to support more than a single outcome for each test.
  final List<String> outcomes = [];

  _Annotation._(this.key, this.rest) {
    outcomes.addAll(rest.split(',').map((s) => s.trim()));
  }
}

/// Finds all relative imports and copies them into the directory with the
/// generated tests.
Set<String> _findAllRelativeImports(Path topLibrary) {
  var found = new Set<String>();
  var libraryDir = topLibrary.directoryPath;
  var relativeImportRegExp = new RegExp(
      '^(?:@.*\\s+)?' // Allow for a meta-data annotation.
      '(import|part)'
      '\\s+["\']'
      '(?!(dart:|dart-ext:|data:|package:|/))' // Look-ahead: not in package.
      '([^"\']*)' // The path to the imported file.
      '["\']');

  processFile(Path filePath) {
    var file = new File(filePath.toNativePath());
    for (var line in file.readAsLinesSync()) {
      var match = relativeImportRegExp.firstMatch(line);
      if (match == null) continue;
      var relativePath = match.group(3);

      // If a multitest deliberately imports a non-existent file, don't try to
      // include it.
      if (relativePath.contains("nonexistent")) continue;

      // Handle import cycles.
      if (!found.add(relativePath)) continue;

      if (relativePath.contains("..")) {
        // This is just for safety reasons, we don't want to unintentionally
        // clobber files relative to the destination dir when copying them
        // over.
        print("Relative import in multitest containing '..' is not allowed.");
        exit(1);
      }

      processFile(libraryDir.append(relativePath));
    }
  }

  processFile(topLibrary);

  return found;
}

String _suiteNameFromPath(Path suiteDir) {
  var split = suiteDir.segments();

  // co19 test suite is at tests/co19/src.
  if (split.last == 'src') split.removeLast();

  return split.last;
}

Path _createMultitestDirectory(
    String outputDir, Path suiteDir, Path sourceDir) {
  var relative = sourceDir.relativeTo(suiteDir);
  var path = new Path(outputDir)
      .append('generated_tests')
      .append(_suiteNameFromPath(suiteDir))
      .join(relative);
  TestUtils.mkdirRecursive(Path.workingDirectory, path);
  return new Path(new File(path.toNativePath()).absolute.path);
}
