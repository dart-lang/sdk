// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("stub_generator_test_config");

#import("../../tools/testing/dart/test_suite.dart");

class StubGeneratorTestSuite extends StandardTestSuite {
  String dartcPath;

  StubGeneratorTestSuite(Map configuration)
      : super(configuration,
              "stub-generator",
              "tests/stub-generator/src",
              ["tests/stub-generator/stub-generator.status"]) {
    try {
      dartcPath = TestUtils.dartcCompilationShellPath(configuration);
    } catch (var e) {
      // ignore
    }
  }

  void combineFiles(String filename,
                    String stubsFile,
                    Function onGenerated) {
    File orig = new File(filename);
    File stubs = new File(stubsFile);
    Expect.isTrue(filename.endsWith(".dart"));
    String baseName = filename.substring(0, filename.length - 5);
    String resultPath = '${baseName}-generatedTest.dart';
    File result = new File(resultPath);
    StringInputStream origStream =
        new StringInputStream(orig.openInputStream());
    FileOutputStream resultStream = result.openOutputStream();

    // First copy first comments and imports from original file.
    var origLine = origStream.readLine();
    while (origLine != null) {
      origLine = origLine.trim();
      if (origLine.isEmpty() ||
          origLine.startsWith('//') ||
          origLine.startsWith('#')) {
        resultStream.write(origLine.charCodes());
        resultStream.write('\n'.charCodes());
        origLine = origStream.readLine();
      } else {
        break;
      }
    }

    // Then copy in the generated stubs code.
    StringInputStream stubsStream =
        new StringInputStream(stubs.openInputStream());
    var stubsLine = stubsStream.readLine();
    while (stubsLine != null) {
      resultStream.write(stubsLine.charCodes());
      resultStream.write('\n'.charCodes());
      stubsLine = stubsStream.readLine();
    }

    // Then copy in the rest of the original file.
    while (origLine != null) {
      resultStream.write(origLine.charCodes());
      resultStream.write('\n'.charCodes());
      origLine = origStream.readLine();
    }

    // Done.
    resultStream.close();
    onGenerated(resultPath);
  }

  void generateTestCase(String filename,
                        String interfaceFile,
                        String classes,
                        Function onGenerated) {
    testGeneratorStarted();
    Directory temp = new Directory('');
    temp.createTempSync();
    File stubsOutFile = new File("${temp.path}/${interfaceFile}");
    stubsOutFile.createSync();
    String stubsPath = stubsOutFile.fullPathSync();
    List<String> args = [filename,
                         '-noincremental',
                         '-out', temp.path,
                         '-isolate-stub-out', stubsPath,
                         '-generate-isolate-stubs', classes ];
    if (configuration['verbose']) {
      print("# $dartcPath ${Strings.join(args, ' ')}");
    }
    Process dartcProcess = new Process(dartcPath, args);
    dartcProcess.exitHandler = (int exitCode) {
      combineFiles(filename, stubsPath, onGenerated);
    };
    dartcProcess.start();
  }

  void processFile(String filename) {
    // Only run the tests that match the pattern.
    RegExp pattern = configuration['selectors'][suiteName];
    if (!pattern.hasMatch(filename)) return;
    var optionsFromFile = optionsFromFile(filename);
    var timeout = configuration['timeout'];
    Function createTestCase = makeTestCaseCreator(optionsFromFile, timeout);

    if (filename.endsWith("-generatedTest.dart")) {
      if (dartcPath == null) {
        createTestCase(filename, optionsFromFile['isNegative']);
      }
    } else if (filename.endsWith("Test.dart")) {
      if (dartcPath != null) {
        String isolateStubsOptions = optionsFromFile['isolateStubs'];
        List<String> splitIsolateStubsOptions = isolateStubsOptions.split(':');
        Expect.equals(2, splitIsolateStubsOptions.length);
        String interfaceFile = splitIsolateStubsOptions[0];
        String classes = splitIsolateStubsOptions[1];
        generateTestCase(filename, interfaceFile, classes, (String filename) {
          createTestCase(filename, optionsFromFile['isNegative']);
          testGeneratorDone();
        });
      }
    }
  }
}
