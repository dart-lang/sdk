// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("multitest");

#import("dart:io");
#import("test_suite.dart");

// Multitests are Dart test scripts containing lines of the form
// " [some dart code] /// [key]: [error type]"
//
// For each key in the file, a new test file is made containing all
// the normal lines of the file, and all of the multitest lines containing
// that key, in the same order as in the source file.  The new test
// is expected to fail if there is a non-empty error type listed, of
// type 'compile-time error', 'runtime error', 'static type warning', or
// 'dynamic type error'.  The type error tests fail only in checked mode.
// There is also a test created from only the untagged lines of the file,
// with key "none", which is expected to pass.  This library extracts these
// tests, writes them into a temporary directory, and passes them to the test
// runner.  These tests may be referred to in the status files with the
// pattern [test name]/[key].
//
// For example: file I_am_a_multitest.dart
//   aaa
//   bbb /// 02: runtime error
//   ccc /// 02: continued
//   ddd /// 07: static type warning
//   eee
//
// should create three tests:
// I_am_a_multitest_none.dart
//   aaa
//   eee
//
// I_am_a_multitest_02.dart
//   aaa
//   bbb /// 02: runtime error
//   ccc /// 02: continued
//   eee
//
// and I_am_a_multitest_07.dart
//   aaa
//   ddd /// 07: static type warning
//   eee
//
// Note that it is possible to indicate more than one acceptable outcome
// in the case of dynamic and static type warnings
//   aaa
//   ddd /// 07: static type warning, dynamic type error
//   eee

void ExtractTestsFromMultitest(String filename,
                               Map<String, String> tests,
                               Map<String, Set<String>> outcomes) {
  // Read the entire file into a byte buffer and transform it to a
  // String. This will treat the file as ascii but the only parts
  // we are interested in will be ascii in any case.
  RandomAccessFile file = (new File(filename)).openSync(FileMode.READ);
  List chars = new List(file.lengthSync());
  int offset = 0;
  while (offset != chars.length) {
    offset += file.readListSync(chars, offset, chars.length - offset);
  }
  file.closeSync();
  String contents = new String.fromCharCodes(chars);
  chars = null;
  int first_newline = contents.indexOf('\n');
  final String line_separator =
      (first_newline == 0 || contents[first_newline - 1] != '\r')
      ? '\n'
      : '\r\n';
  List<String> lines = contents.split(line_separator);
  if (lines.last() == '') lines.removeLast();
  contents = null;
  Set<String> validMultitestOutcomes = new Set<String>.from(
      ['compile-time error', 'runtime error',
       'static type warning', 'dynamic type error']);

  List<String> testTemplate = new List<String>();
  testTemplate.add('// Test created from multitest named $filename.');
  // Create the set of multitests, which will have a new test added each
  // time we see a multitest line with a new key.
  Map<String, List<String>> testsAsLines = new Map<String, List<String>>();

  int lineCount = 0;
  for (String line in lines) {
    lineCount++;
    var annotation = new _Annotation.from(line);
    if (annotation != null) {
      testsAsLines.putIfAbsent(annotation.key,
          () => new List<String>.from(testTemplate)).add(line);
      outcomes.putIfAbsent(annotation.key, 
          () => new Set<String>());
      if (annotation.rest == 'continued') {
        continue;
      } else {
        for (String nextOutcome in annotation.outcomesList) {
          outcomes[annotation.key].add(nextOutcome);  
          if (!validMultitestOutcomes.contains(nextOutcome)) {
            // TODO(zundel): fix long line
            Expect.fail(
              "Invalid test directive '$nextOutcome' on line ${lineCount}: ${annotation.rest} ");
          }
        }
      }
    } else {
      testTemplate.add(line);
      for (var test in testsAsLines.getValues()) test.add(line);
    }
  }

  // Check that every key (other than the none case) has at least one outcome
  for (var outcomeKey in outcomes.getKeys()) {
    if (outcomeKey != 'none' && outcomes[outcomeKey].isEmpty()) {
      // TODO(zundel): fix long line
      Expect.fail("Test ${outcomeKey} has no valid annotated outcomes. Expected one of: ${validMultitestOutcomes.toString()}");
    }
  }

  // Add the template, with no multitest lines, as a test with key 'none'.
  testsAsLines['none'] = testTemplate;
  outcomes['none'] = new Set<String>();

  // Copy all the tests into the output map tests, as multiline strings.
  for (String key in testsAsLines.getKeys()) {
    tests[key] =
        Strings.join(testsAsLines[key], line_separator) + line_separator;
  }
}

// Represents a mutlitest annotation in the special /// comment.
class _Annotation {
  String key;
  String rest;
  List<String> outcomesList;
  _Annotation() {}
  factory _Annotation.from(String line) {
    if (!line.contains('///')) {
      return null;
    }
    var annotation = new _Annotation();
    var parts = line.split('///')[1].split(':').map((s) => s.trim());
    annotation.key = parts[0];
    annotation.rest = parts[1];
    annotation.outcomesList = annotation.rest.split(',')
        .map((s) => s.trim());
    return annotation;
  }
}

// Find all relative imports and copy them into the dir that contains
// the generated tests.
Set<String> _findAllRelativeImports(String topLibrary) {
  Set<String> toSearch = new Set<String>.from([topLibrary]);
  Set<String> foundImports = new HashSet<String>();
  String pathSep = Platform.pathSeparator;
  int end = topLibrary.lastIndexOf(pathSep);
  String libraryDir = topLibrary.substring(0, end);

  // Matches #import( or #source( followed by " or ' followed by anything
  // except dart: or /, at the beginning of a line.
  RegExp relativeImportRegExp =
      const RegExp('^#(import|source)[(]["\'](?!(dart:|/))([^"\']*)["\']');
  while (!toSearch.isEmpty()) {
    var thisPass = toSearch;
    toSearch = new HashSet<String>();
    for (String filename in thisPass) {
      File f = new File(filename);
      for (String line in f.readAsLinesSync()) {
        Match match = relativeImportRegExp.firstMatch(line);
        if (match != null) {
          String relativePath = match.group(3);
          if (foundImports.contains(relativePath)) {
            continue;
          }
          if (relativePath.contains(@'\.\.')) {
            // This is just for safety reasons, we don't want
            // to unintentionally clobber files relative to the destination
            // dir when copying them ove.
            Expect.fail("relative paths containing .. are not allowed.");
          }
          foundImports.add(relativePath);
          toSearch.add('$libraryDir/$relativePath');
        }
      }
    }
  }
  return foundImports;
}

void DoMultitest(String filename,
                 String outputDir,
                 String testDir,
                 // TODO(zundel): Are the boolean flags now redundant
                 // with the 'multitestOutcome' field?
                 Function doTest(String filename,
                                 bool isNegative,
                                 [bool isNegativeIfChecked,
                                  bool hasFatalTypeErrors,
                                  bool hasRuntimeErrors,
                                  Set<String> multitestOutcome]),
                 Function multitestDone) {
  // Each new test is a single String value in the Map tests.
  Map<String, String> tests = new Map<String, String>();
  Map<String, Set<String>> outcomes = new Map<String, Set<String>>();
  ExtractTestsFromMultitest(filename, tests, outcomes);

  String directory = CreateMultitestDirectory(outputDir, testDir);
  Expect.isNotNull(directory);
  String pathSep = Platform.pathSeparator;
  int start = filename.lastIndexOf(pathSep) + 1;
  int end = filename.indexOf('.dart', start);
  String baseFilename = filename.substring(start, end);
  String sourceDirectory = filename.substring(0, start - 1);
  Set<String> importsToCopy = _findAllRelativeImports(filename);
  Directory destDir = new Directory("directory");
  for (String import in importsToCopy) {
    File source = new File('$sourceDirectory/$import');
    var dest = new File('$directory/$import');
    var basenameStart = import.lastIndexOf('/');
    if (basenameStart > 0) {
      // make sure we have a dir for it
      var importDir = import.substring(0, basenameStart);
      TestUtils.mkdirRecursive(directory, importDir);
    }
    TestUtils.copyFile(source, dest);
  }
  for (String key in tests.getKeys()) {
    final String multitestFilename = '$directory/${baseFilename}_$key.dart';
    final File file = new File(multitestFilename);

    file.createSync();
    RandomAccessFile openedFile = file.openSync(FileMode.WRITE);
    var bytes = tests[key].charCodes();
    openedFile.writeListSync(bytes, 0, bytes.length);
    openedFile.closeSync();
    Set<String> outcome = outcomes[key];
    bool enableFatalTypeErrors = outcome.contains('static type warning');
    bool hasRuntimeErrors = outcome.contains('runtime error');
    bool isNegative = hasRuntimeErrors
        || outcome.contains('compile-time error');
    bool isNegativeIfChecked = outcome.contains('dynamic type error');
    doTest(multitestFilename,
           isNegative,
           isNegativeIfChecked,
           enableFatalTypeErrors,
           hasRuntimeErrors,
           outcome);
  }
  multitestDone();
}


String CreateMultitestDirectory(String outputDir, String testDir) {
  final String generatedTestDirectory = 'generated_tests';
  Directory generatedTestDir = new Directory('$outputDir/generated_tests');
  if (!new Directory(outputDir).existsSync()) {
    new Directory(outputDir).createSync();
  }
  if (!generatedTestDir.existsSync()) {
    generatedTestDir.createSync();
  }
  var split = testDir.split('/');
  if (split.last() == 'src') {
    // TODO(sigmund): remove this once all tests are migrated to use
    // TestSuite.forDirectory.
    split.removeLast();
  }
  String path = '${generatedTestDir.path}/${split.last()}';
  Directory dir = new Directory(path);
  if (!dir.existsSync()) {
    dir.createSync();
  }
  return path;
}
