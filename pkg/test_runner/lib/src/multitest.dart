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
/// error', 'compile-time error', 'runtime error', or 'static type warning'.
/// There is also a test created from only the
/// untagged lines of the file, with key "none", which is expected to pass. This
/// library extracts these tests, writes them into a temporary directory, and
/// passes them to the test runner. These tests may be referred to in the status
/// files with the pattern `[test name]/[key]`.
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
//////
/// ```dart
/// aaa
/// ddd //# 07: static type warning
/// fff
/// ```
import "dart:io";

import "path.dart";
import "test_file.dart";
import "utils.dart";

/// Until legacy multitests are ported we need to support both /// and //#
final multitestMarker = RegExp(r"//[/#]");

final _multitestOutcomes = {
  'ok',
  'syntax error',
  'compile-time error',
  'runtime error',
  // TODO(rnystrom): Remove these after Dart 1.0 tests are removed.
  'static type warning', // This is still a valid analyzer test
  'dynamic type error', // This is now a no-op
  'checked mode compile-time error' // This is now a no-op
};

void _generateTestsFromMultitest(Path filePath, Map<String, String> tests,
    Map<String, Set<String>> outcomes) {
  var contents = File(filePath.toNativePath()).readAsStringSync();

  var firstNewline = contents.indexOf('\n');
  var lineSeparator =
      (firstNewline == 0 || contents[firstNewline - 1] != '\r') ? '\n' : '\r\n';
  var lines = contents.split(lineSeparator);
  if (lines.last == '') lines.removeLast();

  // Create the set of multitests, which will have a new test added each
  // time we see a multitest line with a new key.
  var testsAsLines = <String, List<String>>{};

  // Add the default case with key "none".
  testsAsLines['none'] = [];
  outcomes['none'] = {};

  var lineCount = 0;
  for (var line in lines) {
    lineCount++;
    var annotation = Annotation.tryParse(line);
    if (annotation != null) {
      testsAsLines.putIfAbsent(
          annotation.key, () => List<String>.from(testsAsLines["none"]));
      // Add line to test with annotation.key as key, empty line to the rest.
      for (var key in testsAsLines.keys) {
        testsAsLines[key].add(annotation.key == key ? line : "");
      }
      outcomes.putIfAbsent(annotation.key, () => <String>{});
      if (annotation.rest != 'continued') {
        for (var nextOutcome in annotation.outcomes) {
          if (_multitestOutcomes.contains(nextOutcome)) {
            outcomes[annotation.key].add(nextOutcome);
          } else {
            DebugLogger.warning(
                "${filePath.toNativePath()}: Invalid expectation "
                "'$nextOutcome' on line $lineCount: $line");
          }
        }
      }
    } else {
      for (var test in testsAsLines.values) {
        test.add(line);
      }
    }
  }

  // End marker, has a final line separator so we don't need to add it after
  // joining the lines.
  var marker =
      '// Test created from multitest named ${filePath.toNativePath()}.'
      '$lineSeparator';
  for (var test in testsAsLines.values) {
    test.add(marker);
  }

  // Check that every test (other than the none case) has at least one outcome.
  var invalidTests = outcomes.keys
      .where((test) => test != 'none' && outcomes[test].isEmpty)
      .toList();
  for (var test in invalidTests) {
    DebugLogger.warning(
        "${filePath.toNativePath()}: Test $test has no valid expectation. "
        "Expected one of: ${_multitestOutcomes.toString()}");

    outcomes.remove(test);
    testsAsLines.remove(test);
  }

  // Copy all the tests into the output map tests, as multiline strings.
  for (var key in testsAsLines.keys) {
    tests[key] = testsAsLines[key].join(lineSeparator);
  }
}

/// Split the given [multitest] into a series of separate tests for each
/// section.
///
/// Writes the resulting tests to [outputDir] and returns a list of [TestFile]s
/// for each of those generated tests.
List<TestFile> splitMultitest(
    TestFile multitest, String outputDir, Path suiteDir,
    {bool hotReload = false}) {
  // Each key in the map tests is a multitest tag or "none", and the texts of
  // the generated test is its value.
  var tests = <String, String>{};
  var outcomes = <String, Set<String>>{};
  _generateTestsFromMultitest(multitest.path, tests, outcomes);

  var sourceDir = multitest.path.directoryPath;
  var targetDir = _createMultitestDirectory(outputDir, suiteDir, sourceDir);
  assert(targetDir != null);

  // Copy all the relative imports of the multitest.
  var importsToCopy = _findAllRelativeImports(multitest.path);
  for (var relativeImport in importsToCopy) {
    var importPath = Path(relativeImport);
    // Make sure the target directory exists.
    var importDir = importPath.directoryPath;
    if (!importDir.isEmpty) {
      TestUtils.mkdirRecursive(targetDir, importDir);
    }

    // Copy file. Because some test suites may be read-only, we don't
    // want to copy the permissions, so we create the copy by writing.
    var contents =
        File(sourceDir.join(importPath).toNativePath()).readAsBytesSync();
    File(targetDir.join(importPath).toNativePath()).writeAsBytesSync(contents);
  }

  var baseFilename = multitest.path.filenameWithoutExtension;

  var testFiles = <TestFile>[];
  for (var test in tests.keys) {
    var sectionFilePath = targetDir.append('${baseFilename}_$test.dart');
    _writeFile(sectionFilePath.toNativePath(), tests[test]);

    var outcome = outcomes[test];
    var hasStaticWarning = outcome.contains('static type warning');
    var hasRuntimeError = outcome.contains('runtime error');
    var hasSyntaxError = outcome.contains('syntax error');
    var hasCompileError =
        hasSyntaxError || outcome.contains('compile-time error');

    if (hotReload && hasCompileError) {
      // Running a test that expects a compilation error with hot reloading
      // is redundant with a regular run of the test.
      continue;
    }

    // Create a [TestFile] for each split out section test.
    testFiles.add(multitest.split(sectionFilePath, test, tests[test],
        hasSyntaxError: hasSyntaxError,
        hasCompileError: hasCompileError,
        hasRuntimeError: hasRuntimeError,
        hasStaticWarning: hasStaticWarning));
  }

  return testFiles;
}

/// Writes [content] to [filePath] unless there is already a file at that path
/// with the same content.
void _writeFile(String filePath, String content) {
  var file = File(filePath);

  // Don't overwrite the file if the contents are the same. This way build
  // systems don't think it has been modified.
  if (file.existsSync()) {
    var oldContent = file.readAsStringSync();
    if (oldContent == content) return;
  }

  file.writeAsStringSync(content);
}

/// A multitest annotation in the special `//#` comment.
class Annotation {
  /// Parses the annotation in [line] or returns `null` if the line isn't a
  /// multitest annotation.
  static Annotation tryParse(String line) {
    // Do an early return with "null" if this is not a valid multitest
    // annotation.
    if (!line.contains(multitestMarker)) return null;

    var parts = line
        .split(multitestMarker)[1]
        .split(':')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.length <= 1) return null;

    return Annotation._(parts[0], parts[1]);
  }

  final String key;
  final String rest;

  // TODO(rnystrom): After Dart 1.0 is no longer supported, I don't think we
  // need to support more than a single outcome for each test.
  final List<String> outcomes = [];

  Annotation._(this.key, this.rest) {
    outcomes.addAll(rest.split(',').map((s) => s.trim()));
  }
}

/// Finds all relative imports and copies them into the directory with the
/// generated tests.
Set<String> _findAllRelativeImports(Path topLibrary) {
  var found = <String>{};
  var libraryDir = topLibrary.directoryPath;
  var relativeImportRegExp = RegExp(
      '^(?:@.*\\s+)?' // Allow for a meta-data annotation.
      '(import|part)'
      '\\s+["\']'
      '(?!(dart:|dart-ext:|data:|package:|/))' // Look-ahead: not in package.
      '([^"\']*)' // The path to the imported file.
      '["\']');

  processFile(Path filePath) {
    var file = File(filePath.toNativePath());
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
        DebugLogger.error("${filePath.toNativePath()}: "
            "Relative import in multitest containing '..' is not allowed.");
        DebugLogger.close();
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
  var path = Path(outputDir)
      .append('generated_tests')
      .append(_suiteNameFromPath(suiteDir))
      .join(relative);
  TestUtils.mkdirRecursive(Path.workingDirectory, path);
  return Path(File(path.toNativePath()).absolute.path);
}
