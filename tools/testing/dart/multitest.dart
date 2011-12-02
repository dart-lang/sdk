// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("multitest");

// Multitests are Dart test scripts containing lines of the form
// " [some dart code] /// [key]: [error type]"
//
// For each key in the file, a new test file is made containing all
// the normal lines of the file, and all of the multitest lines containing
// that key, in the same order as in the source file.  The new test
// is expected to fail if there is a non-empty error type listed, of
// type 'compile-time error', 'runtime error', 'static type error', or
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
//   ddd /// 07: static type error
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
//   ddd /// 07: static type error
//   eee

void ExtractTestsFromMultitest(String filename,
                               Map<String, String> tests,
                               Map<String, String> outcomes) {
  // Read the entire file into a byte buffer and transform it to a
  // String. This will treat the file as ascii but the only parts
  // we are interested in will be ascii in any case.
  File file = new File(filename);
  file.openSync();
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
       'static type error', 'dynamic type error', '']);
  
  List<String> testTemplate = new List<String>();
  testTemplate.add('// Test created from multitest named $filename.');
  // Create the set of multitests, which will have a new test added each
  // time we see a multitest line with a new key.
  Map<String, List<String>> testsAsLines = new Map<String, List<String>>();

  // Matches #import( or #source( followed by " or ' followed by anything
  // except dart: or /, at the beginning of a line.
  RegExp relativeImportRegExp =
      const RegExp('^#(import|source)[(]["\'](?!(dart:|/))');
  for (String line in lines) {
    if (line.contains('///')) {
      var parts = line.split('///')[1].split(':');
      var key = parts[0].trim();
      var rest = parts[1].trim();
      if (testsAsLines.containsKey(key)) {
        Expect.equals('continued', rest);
        testsAsLines[key].add(line);
      } else {
        (testsAsLines[key] = new List<String>.from(testTemplate)).add(line);
        outcomes[key] = rest;
        Expect.isTrue(validMultitestOutcomes.contains(rest));
      }
    } else {
      testTemplate.add(line);
      for (var test in testsAsLines.getValues()) test.add(line);
    }
    // Warn if any import or source tags have relative paths.
    if (relativeImportRegExp.hasMatch(line)) {
      print('Warning: Multitest cannot contain relative imports:');
      print('    $filename: $line');
    }
  }
  // Add the template, with no multitest lines, as a test with key 'none'.
  testsAsLines['none'] = testTemplate;
  outcomes['none'] = '';
  
  // Copy all the tests into the output map tests, as multiline strings.
  for (String key in testsAsLines.getKeys()) {
    tests[key] =
        Strings.join(testsAsLines[key], line_separator) + line_separator;
  }
}


void DoMultitest(String filename,
                 String buildDir,
                 String testDir,
                 bool supportsFatalTypeErrors,
                 Function doTest(String filename,
                                 bool isNegative,
                                 [bool isNegativeIfChecked]),
                 Function multitestDone) {
  // Each new test is a single String value in the Map tests.
  Map<String, String> tests = new Map<String, String>();
  Map<String, String> outcomes = new Map<String, String>();
  ExtractTestsFromMultitest(filename, tests, outcomes);

  String directory = CreateMultitestDirectory(buildDir, testDir);
  String pathSeparator = new Platform().pathSeparator();
  int start = filename.lastIndexOf(pathSeparator) + 1;
  int end = filename.indexOf('.dart', start);
  String baseFilename = filename.substring(start, end);
  Iterator currentKey = tests.getKeys().iterator();
  WriteMultitestToFileAndQueueIt(tests,
                                 outcomes,
                                 supportsFatalTypeErrors,
                                 currentKey,
                                 '$directory$pathSeparator$baseFilename',
                                 doTest,
                                 multitestDone);
}


// Write multiple tests to files, using tail recursion in a callback
// to serialize the file operations, rather than opening all files at once.
WriteMultitestToFileAndQueueIt(Map<String, String> tests,
                               Map<String, String> outcomes,
                               bool supportsFatalTypeErrors,
                               Iterator currentKey,
                               String basePath,
                               Function doTest,
                               Function done) {
  if (!currentKey.hasNext()) {
    done();
    return;
  }
  final String key = currentKey.next();
  final String filename = '${basePath}_$key.dart';
  final File file = new File(filename);
  file.errorHandler = (error) {
    Expect.fail("Error creating temp file: $error");
  };
  file.createHandler = () {
    file.open(writable: true);
  };
  file.openHandler =  () {
    var bytes = tests[key].charCodes();
    file.writeList(bytes, 0, bytes.length);
  };
  file.noPendingWriteHandler =() {
    file.close();
  };
  file.closeHandler = () {
    var outcome = outcomes[key];
    bool enableFatalTypeErrors = (supportsFatalTypeErrors &&
                                  outcome.contains('static type error'));
    bool isNegative = (outcome.contains('compile-time error') ||
                       outcome.contains('runtime error') ||
                       enableFatalTypeErrors);
    bool isNegativeIfChecked = outcome.contains('type error');
    doTest(filename,
           isNegative,
           isNegativeIfChecked,
           enableFatalTypeErrors);
    WriteMultitestToFileAndQueueIt(tests,
                                   outcomes,
                                   supportsFatalTypeErrors,
                                   currentKey,
                                   basePath,
                                   doTest,
                                   done);
  };
  file.create();
}

String CreateMultitestDirectory(String buildDir, String testDir) {
  final String generatedTestDirectory = 'generated_tests/';
  Directory parent_dir = new Directory(buildDir + generatedTestDirectory);
  if (!parent_dir.existsSync()) {
    parent_dir.createSync();
  }
  var split = testDir.split(new Platform().pathSeparator());
  var lastComponent = split.removeLast();
  Expect.isTrue(lastComponent == 'src');
  String path = parent_dir.path + split.last();
  Directory dir = new Directory(path);
  if (!dir.existsSync()) {
    dir.createSync();
  }
  return path;
}
