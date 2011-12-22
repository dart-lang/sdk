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
    StringInputStream stubsStream =
        new StringInputStream(stubs.openInputStream());
    FileOutputStream resultStream = result.openOutputStream();
    var origLine;

    void writeResultLine(String line) {
      resultStream.write(line.charCodes());
      resultStream.write('\n'.charCodes());
    }

    // Step 3: Copy in the rest of the original file.
    void copyThirdPart() {
      origLine = origStream.readLine();
      while (origLine != null) {
        writeResultLine(origLine);
        origLine = origStream.readLine();
      }
    }

    // Step 2: Copy in the generated stubs code.
    void copySecondPart() {
      var stubsLine = stubsStream.readLine();
      while (stubsLine != null) {
        writeResultLine(stubsLine);
        stubsLine = stubsStream.readLine();
      }
    }

    // Step 1: Copy first comments and imports from original file.
    void copyFirstPart() {
      origLine = origStream.readLine();
      while (origLine != null) {
        origLine = origLine.trim();
        if (origLine.isEmpty() ||
            origLine.startsWith('//') ||
            origLine.startsWith('#')) {
          writeResultLine(origLine);
          origLine = origStream.readLine();
        } else {
          origStream.lineHandler = null;
          // Start copying from the stubs file.
          stubsStream.lineHandler = copySecondPart;
          stubsStream.closeHandler = () {
            // When the stubs file is all read continue with the rest
            // of the original file including the pending line.
            writeResultLine(origLine);
            origStream.lineHandler = copyThirdPart;
          };
          return;
        }
      }
    }

    origStream.lineHandler = copyFirstPart;
    origStream.closeHandler = () {
      // Done generating file when all data has been read from the
      // original file.
      resultStream.close();
      onGenerated(resultPath);
    };
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
    Process dartcProcess = new Process.start(dartcPath, args);
    dartcProcess.exitHandler = (int exitCode) {
      combineFiles(filename, stubsPath, onGenerated);
    };
  }

  void processFile(String filename) {
    // Only run the tests that match the pattern.
    RegExp pattern = configuration['selectors'][suiteName];
    if (!pattern.hasMatch(filename)) return;
    var optionsFromFile = optionsFromFile(filename);
    Function createTestCase = makeTestCaseCreator(optionsFromFile);

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
