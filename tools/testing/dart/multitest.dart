// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multitest;

import "dart:async";
import "dart:io";

import "path.dart";
import "test_suite.dart";
import "utils.dart";

// Multitests are Dart test scripts containing lines of the form
// " [some dart code] //# [key]: [error type]"
//
// To support legacy multi tests we also handle lines of the form
// " [some dart code] /// [key]: [error type]"
//
// For each key in the file, a new test file is made containing all
// the normal lines of the file, and all of the multitest lines containing
// that key, in the same order as in the source file.  The new test is expected
// to pass if the error type listed is 'ok', or to fail if there is an error
// type of type 'compile-time error', 'runtime error', 'static type warning', or
// 'dynamic type error'.  The type error tests fail only in checked mode.
// There is also a test created from only the untagged lines of the file,
// with key "none", which is expected to pass.  This library extracts these
// tests, writes them into a temporary directory, and passes them to the test
// runner.  These tests may be referred to in the status files with the
// pattern [test name]/[key].
//
// For example: file I_am_a_multitest.dart
//   aaa
//   bbb //# 02: runtime error
//   ccc //# 02: continued
//   ddd //# 07: static type warning
//   eee //# 10: ok
//   fff
//
// should create four tests:
// I_am_a_multitest_none.dart
//   aaa
//   fff
//
// I_am_a_multitest_02.dart
//   aaa
//   bbb //# 02: runtime error
//   ccc //# 02: continued
//   fff
//
// I_am_a_multitest_07.dart
//   aaa
//   ddd //# 07: static type warning
//   fff
//
// and I_am_a_multitest_10.dart
//   aaa
//   eee //# 10: ok
//   fff
//
// Note that it is possible to indicate more than one acceptable outcome
// in the case of dynamic and static type warnings
//   aaa
//   ddd //# 07: static type warning, dynamic type error
//   fff

/// Until legacy multitests are ported we need to support both /// and //#
final _multitestMarker = new RegExp(r"//[/#]");

void ExtractTestsFromMultitest(Path filePath, Map<String, String> tests,
    Map<String, Set<String>> outcomes) {
  // Read the entire file into a byte buffer and transform it to a
  // String. This will treat the file as ascii but the only parts
  // we are interested in will be ascii in any case.
  var bytes = new File(filePath.toNativePath()).readAsBytesSync();
  var contents = decodeUtf8(bytes);
  var firstNewline = contents.indexOf('\n');
  var lineSeparator =
      (firstNewline == 0 || contents[firstNewline - 1] != '\r') ? '\n' : '\r\n';
  var lines = contents.split(lineSeparator);
  if (lines.last == '') lines.removeLast();
  bytes = null;
  contents = null;
  var validMultitestOutcomes = [
    'ok',
    'compile-time error',
    'runtime error',
    'static type warning',
    'dynamic type error',
    'checked mode compile-time error'
  ].toSet();

  // Create the set of multitests, which will have a new test added each
  // time we see a multitest line with a new key.
  var testsAsLines = <String, List<String>>{};

  // Add the default case with key "none".
  testsAsLines['none'] = <String>[];
  outcomes['none'] = new Set<String>();

  var lineCount = 0;
  for (var line in lines) {
    lineCount++;
    var annotation = new _Annotation.from(line);
    if (annotation != null) {
      testsAsLines.putIfAbsent(
          annotation.key, () => new List<String>.from(testsAsLines["none"]));
      // Add line to test with annotation.key as key, empty line to the rest.
      for (var key in testsAsLines.keys) {
        testsAsLines[key].add(annotation.key == key ? line : "");
      }
      outcomes.putIfAbsent(annotation.key, () => new Set<String>());
      if (annotation.rest != 'continued') {
        for (String nextOutcome in annotation.outcomesList) {
          if (validMultitestOutcomes.contains(nextOutcome)) {
            outcomes[annotation.key].add(nextOutcome);
          } else {
            DebugLogger.warning(
                "Warning: Invalid test directive '$nextOutcome' on line "
                "${lineCount}:\n${annotation.rest} ");
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

  var keysToDelete = <String>[];
  // Check that every key (other than the none case) has at least one outcome
  for (var outcomeKey in outcomes.keys) {
    if (outcomeKey != 'none' && outcomes[outcomeKey].isEmpty) {
      DebugLogger.warning(
          "Warning: Test ${outcomeKey} has no valid annotated outcomes.\n"
          "Expected one of: ${validMultitestOutcomes.toString()}");
      // If this multitest doesn't have an outcome, mark the multitest for
      // deletion.
      keysToDelete.add(outcomeKey);
    }
  }
  // If a key/multitest was marked for deletion, do the necessary cleanup.
  keysToDelete.forEach(outcomes.remove);
  keysToDelete.forEach(testsAsLines.remove);

  // Copy all the tests into the output map tests, as multiline strings.
  for (var key in testsAsLines.keys) {
    tests[key] = testsAsLines[key].join(lineSeparator);
  }
}

// Represents a mutlitest annotation in the special //# comment.
class _Annotation {
  String key;
  String rest;
  List<String> outcomesList;
  _Annotation() {}
  factory _Annotation.from(String line) {
    // Do an early return with "null" if this is not a valid multitest
    // annotation.
    if (!line.contains(_multitestMarker)) {
      return null;
    }
    var parts = line
        .split(_multitestMarker)[1]
        .split(':')
        .map((s) => s.trim())
        .where((s) => s.length > 0)
        .toList();
    if (parts.length <= 1) {
      return null;
    }

    var annotation = new _Annotation();
    annotation.key = parts[0];
    annotation.rest = parts[1];
    annotation.outcomesList =
        annotation.rest.split(',').map((s) => s.trim()).toList();
    return annotation;
  }
}

// Find all relative imports and copy them into the dir that contains
// the generated tests.
Set<String> _findAllRelativeImports(Path topLibrary) {
  var toSearch = [topLibrary].toSet();
  var foundImports = new Set<String>();
  var libraryDir = topLibrary.directoryPath;
  var relativeImportRegExp = new RegExp(
      '^(?:@.*\\s+)?' // Allow for a meta-data annotation.
      '(import|part)'
      '\\s+["\']'
      '(?!(dart:|dart-ext:|data:|package:|/))' // Look-ahead: not in package.
      '([^"\']*)' // The path to the imported file.
      '["\']');
  while (!toSearch.isEmpty) {
    var thisPass = toSearch;
    toSearch = new Set<Path>();
    for (Path filename in thisPass) {
      File f = new File(filename.toNativePath());
      for (String line in f.readAsLinesSync()) {
        Match match = relativeImportRegExp.firstMatch(line);
        if (match != null) {
          Path relativePath = new Path(match.group(3));
          if (foundImports.contains(relativePath.toString())) {
            continue;
          }
          if (relativePath.toString().contains('..')) {
            // This is just for safety reasons, we don't want
            // to unintentionally clobber files relative to the destination
            // dir when copying them ove.
            print("relative paths containing .. are not allowed.");
            exit(1);
          }
          foundImports.add(relativePath.toString());
          toSearch.add(libraryDir.join(relativePath));
        }
      }
    }
  }
  return foundImports;
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
  Map<String, String> tests = new Map<String, String>();
  Map<String, Set<String>> outcomes = new Map<String, Set<String>>();
  ExtractTestsFromMultitest(filePath, tests, outcomes);

  Path sourceDir = filePath.directoryPath;
  Path targetDir = createMultitestDirectory(outputDir, suiteDir, sourceDir);
  assert(targetDir != null);

  // Copy all the relative imports of the multitest.
  Set<String> importsToCopy = _findAllRelativeImports(filePath);
  List<Future> futureCopies = [];
  for (String relativeImport in importsToCopy) {
    Path importPath = new Path(relativeImport);
    // Make sure the target directory exists.
    Path importDir = importPath.directoryPath;
    if (!importDir.isEmpty) {
      TestUtils.mkdirRecursive(targetDir, importDir);
    }
    // Copy file.
    futureCopies.add(TestUtils.copyFile(
        sourceDir.join(importPath), targetDir.join(importPath)));
  }

  // Wait until all imports are copied before scheduling test cases.
  return Future.wait(futureCopies).then((_) {
    String baseFilename = filePath.filenameWithoutExtension;
    for (String key in tests.keys) {
      final Path multitestFilename =
          targetDir.append('${baseFilename}_$key.dart');
      writeFile(multitestFilename.toNativePath(), tests[key]);
      Set<String> outcome = outcomes[key];
      bool hasStaticWarning = outcome.contains('static type warning');
      bool hasRuntimeErrors = outcome.contains('runtime error');
      bool hasCompileError = outcome.contains('compile-time error');
      bool isNegativeIfChecked = outcome.contains('dynamic type error');
      bool hasCompileErrorIfChecked =
          outcome.contains('checked mode compile-time error');
      if (hotReload) {
        if (hasCompileError || hasCompileErrorIfChecked) {
          // Running a test that expects a compilation error with hot reloading
          // is redundant with a regular run of the test.
          continue;
        }
      }
      doTest(multitestFilename, filePath, hasCompileError, hasRuntimeErrors,
          isNegativeIfChecked: isNegativeIfChecked,
          hasCompileErrorIfChecked: hasCompileErrorIfChecked,
          hasStaticWarning: hasStaticWarning,
          multitestKey: key);
    }

    return null;
  });
}

String suiteNameFromPath(Path suiteDir) {
  var split = suiteDir.segments();
  // co19 test suite is at tests/co19/src.
  if (split.last == 'src') {
    split.removeLast();
  }
  return split.last;
}

Path createMultitestDirectory(String outputDir, Path suiteDir, Path sourceDir) {
  Path relative = sourceDir.relativeTo(suiteDir);
  Path path = new Path(outputDir)
      .append('generated_tests')
      .append(suiteNameFromPath(suiteDir))
      .join(relative);
  TestUtils.mkdirRecursive(Path.workingDirectory, path);
  return new Path(new File(path.toNativePath()).absolute.path);
}
