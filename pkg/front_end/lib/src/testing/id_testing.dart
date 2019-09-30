// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'annotated_code_helper.dart';
import 'id.dart';
import '../fasta/colors.dart' as colors;

const String cfeMarker = 'cfe';
const String dart2jsMarker = 'dart2js';
const String analyzerMarker = 'analyzer';

/// Markers used in annotated tests shard by CFE, analyzer and dart2js.
const List<String> sharedMarkers = [
  cfeMarker,
  dart2jsMarker,
  analyzerMarker,
];

/// `true` if ANSI colors are supported by stdout.
bool useColors = stdout.supportsAnsiEscapes;

/// Colorize a message [text], if ANSI colors are supported.
String colorizeMessage(String text) {
  if (useColors) {
    return '${colors.YELLOW_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize a matching annotation [text], if ANSI colors are supported.
String colorizeMatch(String text) {
  if (useColors) {
    return '${colors.BLUE_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize a single annotation [text], if ANSI colors are supported.
String colorizeSingle(String text) {
  if (useColors) {
    return '${colors.GREEN_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize the actual annotation [text], if ANSI colors are supported.
String colorizeActual(String text) {
  if (useColors) {
    return '${colors.RED_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize an expected annotation [text], if ANSI colors are supported.
String colorizeExpected(String text) {
  if (useColors) {
    return '${colors.GREEN_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize delimiter [text], if ANSI colors are supported.
String colorizeDelimiter(String text) {
  if (useColors) {
    return '${colors.YELLOW_COLOR}${text}${colors.DEFAULT_COLOR}';
  } else {
    return text;
  }
}

/// Colorize diffs [expected] and [actual] and [delimiter], if ANSI colors are
/// supported.
String colorizeDiff(String expected, String delimiter, String actual) {
  return '${colorizeExpected(expected)}'
      '${colorizeDelimiter(delimiter)}${colorizeActual(actual)}';
}

/// Colorize annotation delimiters [start] and [end] surrounding [text], if
/// ANSI colors are supported.
String colorizeAnnotation(String start, String text, String end) {
  return '${colorizeDelimiter(start)}$text${colorizeDelimiter(end)}';
}

/// Encapsulates the member data computed for each source file of interest.
/// It's a glorified wrapper around a map of maps, but written this way to
/// provide a little more information about what it's doing. [DataType] refers
/// to the type this map is holding -- it is either [IdValue] or [ActualData].
class MemberAnnotations<DataType> {
  /// For each Uri, we create a map associating an element id with its
  /// corresponding annotations.
  final Map<Uri, Map<Id, DataType>> _computedDataForEachFile =
      new Map<Uri, Map<Id, DataType>>();

  /// Member or class annotations that don't refer to any of the user files.
  final Map<Id, DataType> globalData = <Id, DataType>{};

  void operator []=(Uri file, Map<Id, DataType> computedData) {
    _computedDataForEachFile[file] = computedData;
  }

  void forEach(void f(Uri file, Map<Id, DataType> computedData)) {
    _computedDataForEachFile.forEach(f);
  }

  Map<Id, DataType> operator [](Uri file) {
    if (!_computedDataForEachFile.containsKey(file)) {
      _computedDataForEachFile[file] = <Id, DataType>{};
    }
    return _computedDataForEachFile[file];
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('MemberAnnotations(');
    String comma = '';
    if (_computedDataForEachFile.isNotEmpty &&
        (_computedDataForEachFile.length > 1 ||
            _computedDataForEachFile.values.single.isNotEmpty)) {
      sb.write('data:{');
      _computedDataForEachFile.forEach((Uri uri, Map<Id, DataType> data) {
        sb.write(comma);
        sb.write('$uri:');
        sb.write(data);
        comma = ',';
      });
      sb.write('}');
    }
    if (globalData.isNotEmpty) {
      sb.write(comma);
      sb.write('global:');
      sb.write(globalData);
    }
    sb.write(')');
    return sb.toString();
  }
}

/// Compute a [MemberAnnotations] object from [code] for each marker in [maps]
/// specifying the expected annotations.
///
/// If an annotation starts with a marker, it is only expected for the
/// corresponding test configuration. Otherwise it is expected for all
/// configurations.
// TODO(johnniwinther): Support an empty marker set.
void computeExpectedMap(Uri sourceUri, String filename, AnnotatedCode code,
    Map<String, MemberAnnotations<IdValue>> maps,
    {void onFailure(String message)}) {
  List<String> mapKeys = maps.keys.toList();
  Map<String, AnnotatedCode> split = splitByPrefixes(code, mapKeys);

  split.forEach((String marker, AnnotatedCode code) {
    MemberAnnotations<IdValue> fileAnnotations = maps[marker];
    assert(fileAnnotations != null, "No annotations for $marker in $maps");
    Map<Id, IdValue> expectedValues = fileAnnotations[sourceUri];
    for (Annotation annotation in code.annotations) {
      String text = annotation.text;
      IdValue idValue = IdValue.decode(sourceUri, annotation.offset, text);
      if (idValue.id.isGlobal) {
        if (fileAnnotations.globalData.containsKey(idValue.id)) {
          onFailure("Error in test '$filename': "
              "Duplicate annotations for ${idValue.id} in $marker: "
              "${idValue} and ${fileAnnotations.globalData[idValue.id]}.");
        }
        fileAnnotations.globalData[idValue.id] = idValue;
      } else {
        if (expectedValues.containsKey(idValue.id)) {
          onFailure("Error in test '$filename': "
              "Duplicate annotations for ${idValue.id} in $marker: "
              "${idValue} and ${expectedValues[idValue.id]}.");
        }
        expectedValues[idValue.id] = idValue;
      }
    }
  });
}

/// Creates a [TestData] object for the annotated test in [testFile].
///
/// If [testFile] is a file, use that directly. If it's a directory include
/// everything in that directory.
///
/// If [testLibDirectory] is not `null`, files in [testLibDirectory] with the
/// [testFile] name as a prefix are included.
TestData computeTestData(FileSystemEntity testFile,
    {Iterable<String> supportedMarkers,
    Uri createUriForFileName(String fileName),
    void onFailure(String message)}) {
  Uri entryPoint = createUriForFileName('main.dart');

  String testName;
  File mainTestFile;
  Uri testFileUri = testFile.uri;
  Map<String, File> additionalFiles;
  if (testFile is File) {
    testName = testFileUri.pathSegments.last;
    mainTestFile = testFile;
  } else if (testFile is Directory) {
    testName = testFileUri.pathSegments[testFileUri.pathSegments.length - 2];
    additionalFiles = new Map<String, File>();
    for (FileSystemEntity entry in testFile.listSync(recursive: true)) {
      if (entry is! File) continue;
      if (entry.uri.pathSegments.last == "main.dart") {
        mainTestFile = entry;
      } else {
        additionalFiles[entry.uri.path.substring(testFile.uri.path.length)] =
            entry;
      }
    }
    assert(
        mainTestFile != null, "No 'main.dart' test file found for $testFile.");
  }

  String annotatedCode = new File.fromUri(mainTestFile.uri).readAsStringSync();
  Map<Uri, AnnotatedCode> code = {
    entryPoint:
        new AnnotatedCode.fromText(annotatedCode, commentStart, commentEnd)
  };
  Map<String, MemberAnnotations<IdValue>> expectedMaps = {};
  for (String testMarker in supportedMarkers) {
    expectedMaps[testMarker] = new MemberAnnotations<IdValue>();
  }
  computeExpectedMap(entryPoint, testFile.uri.pathSegments.last,
      code[entryPoint], expectedMaps,
      onFailure: onFailure);
  Map<String, String> memorySourceFiles = {
    entryPoint.path: code[entryPoint].sourceCode
  };

  if (additionalFiles != null) {
    for (MapEntry<String, File> additionalFileData in additionalFiles.entries) {
      String libFileName = additionalFileData.key;
      File libEntity = additionalFileData.value;
      Uri libFileUri = createUriForFileName(libFileName);
      String libCode = libEntity.readAsStringSync();
      AnnotatedCode annotatedLibCode =
          new AnnotatedCode.fromText(libCode, commentStart, commentEnd);
      memorySourceFiles[libFileUri.path] = annotatedLibCode.sourceCode;
      code[libFileUri] = annotatedLibCode;
      computeExpectedMap(
          libFileUri, libFileName, annotatedLibCode, expectedMaps,
          onFailure: onFailure);
    }
  }

  return new TestData(
      testName, testFileUri, entryPoint, memorySourceFiles, code, expectedMaps);
}

/// Data for an annotated test.
class TestData {
  final String name;
  final Uri testFileUri;
  final Uri entryPoint;
  final Map<String, String> memorySourceFiles;
  final Map<Uri, AnnotatedCode> code;
  final Map<String, MemberAnnotations<IdValue>> expectedMaps;

  TestData(this.name, this.testFileUri, this.entryPoint, this.memorySourceFiles,
      this.code, this.expectedMaps);
}

/// The actual result computed for an annotated test.
abstract class CompiledData<T> {
  final Uri mainUri;

  /// For each Uri, a map associating an element id with the instrumentation
  /// data we've collected for it.
  final Map<Uri, Map<Id, ActualData<T>>> actualMaps;

  /// Collected instrumentation data that doesn't refer to any of the user
  /// files.  (E.g. information the test has collected about files in
  /// `dart:core`).
  final Map<Id, ActualData<T>> globalData;

  CompiledData(this.mainUri, this.actualMaps, this.globalData);

  Map<int, List<String>> computeAnnotations(Uri uri) {
    Map<Id, ActualData<T>> actualMap = actualMaps[uri];
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMap.forEach((Id id, ActualData<T> data) {
      String value1 = '${data.value}';
      annotations
          .putIfAbsent(data.offset, () => [])
          .add(colorizeActual(value1));
    });
    return annotations;
  }

  Map<int, List<String>> computeDiffAnnotationsAgainst(
      Map<Id, ActualData<T>> thisMap, Map<Id, ActualData<T>> otherMap, Uri uri,
      {bool includeMatches: false}) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    thisMap.forEach((Id id, ActualData<T> thisData) {
      ActualData<T> otherData = otherMap[id];
      String thisValue = '${thisData.value}';
      if (thisData.value != otherData?.value) {
        String otherValue = '${otherData?.value ?? '---'}';
        annotations
            .putIfAbsent(thisData.offset, () => [])
            .add(colorizeDiff(thisValue, ' | ', otherValue));
      } else if (includeMatches) {
        annotations
            .putIfAbsent(thisData.offset, () => [])
            .add(colorizeMatch(thisValue));
      }
    });
    otherMap.forEach((Id id, ActualData<T> otherData) {
      if (!thisMap.containsKey(id)) {
        String thisValue = '---';
        String otherValue = '${otherData.value}';
        annotations
            .putIfAbsent(otherData.offset, () => [])
            .add(colorizeDiff(thisValue, ' | ', otherValue));
      }
    });
    return annotations;
  }

  int getOffsetFromId(Id id, Uri uri);

  void reportError(Uri uri, int offset, String message, {bool succinct: false});
}

/// Interface used for interpreting annotations.
abstract class DataInterpreter<T> {
  /// Returns `null` if [actualData] satisfies the [expectedData] annotation.
  /// Otherwise, a message is returned contain the information about the
  /// problems found.
  String isAsExpected(T actualData, String expectedData);

  /// Returns `true` if [actualData] corresponds to empty data.
  bool isEmpty(T actualData);

  /// Returns a textual representation of [actualData].
  String getText(T actualData);
}

/// Default data interpreter for string data.
class StringDataInterpreter implements DataInterpreter<String> {
  const StringDataInterpreter();

  @override
  String isAsExpected(String actualData, String expectedData) {
    actualData ??= '';
    expectedData ??= '';
    if (actualData != expectedData) {
      return "Expected $expectedData, found $actualData";
    }
    return null;
  }

  @override
  bool isEmpty(String actualData) {
    return actualData == '';
  }

  @override
  String getText(String actualData) {
    return actualData;
  }
}

String withAnnotations(String sourceCode, Map<int, List<String>> annotations) {
  StringBuffer sb = new StringBuffer();
  int end = 0;
  for (int offset in annotations.keys.toList()..sort()) {
    if (offset >= sourceCode.length) {
      sb.write('...');
      return sb.toString();
    }
    if (offset > end) {
      sb.write(sourceCode.substring(end, offset));
    }
    for (String annotation in annotations[offset]) {
      sb.write(colorizeAnnotation('/*', annotation, '*/'));
    }
    end = offset;
  }
  if (end < sourceCode.length) {
    sb.write(sourceCode.substring(end));
  }
  return sb.toString();
}

/// Computed and expected data for an annotated test. This is used for checking
/// and displaying results of an annotated test.
class IdData<T> {
  final Map<Uri, AnnotatedCode> code;
  final MemberAnnotations<IdValue> expectedMaps;
  final CompiledData<T> _compiledData;
  final MemberAnnotations<ActualData<T>> _actualMaps = new MemberAnnotations();

  IdData(this.code, this.expectedMaps, this._compiledData) {
    for (Uri uri in code.keys) {
      _actualMaps[uri] = _compiledData.actualMaps[uri] ?? <Id, ActualData<T>>{};
    }
    _actualMaps.globalData.addAll(_compiledData.globalData);
  }

  Uri get mainUri => _compiledData.mainUri;
  MemberAnnotations<ActualData<T>> get actualMaps => _actualMaps;

  String actualCode(Uri uri) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMaps[uri].forEach((Id id, ActualData<T> data) {
      annotations.putIfAbsent(data.offset, () => []).add('${data.value}');
    });
    return withAnnotations(code[uri].sourceCode, annotations);
  }

  String diffCode(Uri uri, DataInterpreter<T> dataValidator) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMaps[uri].forEach((Id id, ActualData<T> data) {
      IdValue expectedValue = expectedMaps[uri][id];
      T actualValue = data.value;
      String unexpectedMessage =
          dataValidator.isAsExpected(actualValue, expectedValue?.value);
      if (unexpectedMessage != null) {
        String expected = expectedValue?.toString() ?? '';
        String actual = dataValidator.getText(actualValue);
        int offset = getOffsetFromId(id, uri);
        if (offset != null) {
          String value1 = '${expected}';
          String value2 = IdValue.idToString(id, '${actual}');
          annotations
              .putIfAbsent(offset, () => [])
              .add(colorizeDiff(value1, ' | ', value2));
        }
      }
    });
    expectedMaps[uri].forEach((Id id, IdValue expected) {
      if (!actualMaps[uri].containsKey(id)) {
        int offset = getOffsetFromId(id, uri);
        if (offset != null) {
          String value1 = '${expected}';
          String value2 = '---';
          annotations
              .putIfAbsent(offset, () => [])
              .add(colorizeDiff(value1, ' | ', value2));
        }
      }
    });
    return withAnnotations(code[uri].sourceCode, annotations);
  }

  int getOffsetFromId(Id id, Uri uri) {
    return _compiledData.getOffsetFromId(id, uri);
  }
}

/// Checks [compiledData] against the expected data in [expectedMaps] derived
/// from [code].
Future<bool> checkCode<T>(
    String modeName,
    Uri mainFileUri,
    Map<Uri, AnnotatedCode> code,
    MemberAnnotations<IdValue> expectedMaps,
    CompiledData<T> compiledData,
    DataInterpreter<T> dataValidator,
    {bool filterActualData(IdValue expected, ActualData<T> actualData),
    bool fatalErrors: true,
    bool succinct: false,
    void onFailure(String message)}) async {
  IdData<T> data = new IdData<T>(code, expectedMaps, compiledData);
  bool hasFailure = false;
  Set<Uri> neededDiffs = new Set<Uri>();

  void checkActualMap(
      Map<Id, ActualData<T>> actualMap, Map<Id, IdValue> expectedMap,
      [Uri uri]) {
    bool hasLocalFailure = false;
    actualMap.forEach((Id id, ActualData<T> actualData) {
      T actual = actualData.value;
      String actualText = dataValidator.getText(actual);

      if (!expectedMap.containsKey(id)) {
        if (!dataValidator.isEmpty(actual)) {
          String actualValueText = IdValue.idToString(id, actualText);
          compiledData.reportError(
              actualData.uri,
              actualData.offset,
              succinct
                  ? 'EXTRA $modeName DATA for ${id.descriptor}'
                  : 'EXTRA $modeName DATA for ${id.descriptor}:\n '
                      'object   : ${actualData.objectText}\n '
                      'actual   : ${colorizeActual(actualValueText)}\n '
                      'Data was expected for these ids: ${expectedMap.keys}',
              succinct: succinct);
          if (filterActualData == null || filterActualData(null, actualData)) {
            hasLocalFailure = true;
          }
        }
      } else {
        IdValue expected = expectedMap[id];
        String unexpectedMessage =
            dataValidator.isAsExpected(actual, expected.value);
        if (unexpectedMessage != null) {
          String actualValueText = IdValue.idToString(id, actualText);
          compiledData.reportError(
              actualData.uri,
              actualData.offset,
              succinct
                  ? 'UNEXPECTED $modeName DATA for ${id.descriptor}'
                  : 'UNEXPECTED $modeName DATA for ${id.descriptor}:\n '
                      'detail  : ${colorizeMessage(unexpectedMessage)}\n '
                      'object  : ${actualData.objectText}\n '
                      'expected: ${colorizeExpected('$expected')}\n '
                      'actual  : ${colorizeActual(actualValueText)}',
              succinct: succinct);
          if (filterActualData == null ||
              filterActualData(expected, actualData)) {
            hasLocalFailure = true;
          }
        }
      }
    });
    if (hasLocalFailure) {
      hasFailure = true;
      if (uri != null) {
        neededDiffs.add(uri);
      }
    }
  }

  data.actualMaps.forEach((Uri uri, Map<Id, ActualData<T>> actualMap) {
    checkActualMap(actualMap, data.expectedMaps[uri], uri);
  });
  checkActualMap(data.actualMaps.globalData, data.expectedMaps.globalData);

  Set<Id> missingIds = new Set<Id>();
  void checkMissing(
      Map<Id, IdValue> expectedMap, Map<Id, ActualData<T>> actualMap,
      [Uri uri]) {
    expectedMap.forEach((Id id, IdValue expected) {
      if (!actualMap.containsKey(id)) {
        missingIds.add(id);
        String message = 'MISSING $modeName DATA for ${id.descriptor}: '
            'Expected ${colorizeExpected('$expected')}';
        if (uri != null) {
          compiledData.reportError(
              uri, compiledData.getOffsetFromId(id, uri), message,
              succinct: succinct);
        } else {
          print(message);
        }
      }
    });
    if (missingIds.isNotEmpty && uri != null) {
      neededDiffs.add(uri);
    }
  }

  data.expectedMaps.forEach((Uri uri, Map<Id, IdValue> expectedMap) {
    checkMissing(expectedMap, data.actualMaps[uri], uri);
  });
  checkMissing(data.expectedMaps.globalData, data.actualMaps.globalData);
  if (!succinct) {
    for (Uri uri in neededDiffs) {
      print('--annotations diff [${uri.pathSegments.last}]-------------');
      print(data.diffCode(uri, dataValidator));
      print('----------------------------------------------------------');
    }
  }
  if (missingIds.isNotEmpty) {
    print("MISSING ids: ${missingIds}.");
    hasFailure = true;
  }
  if (hasFailure && fatalErrors) {
    onFailure('Errors found.');
  }
  return hasFailure;
}

typedef Future<bool> RunTestFunction(TestData testData,
    {bool testAfterFailures, bool verbose, bool succinct, bool printCode});

/// Check code for all tests in [dataDir] using [runTest].
Future runTests(Directory dataDir,
    {List<String> args: const <String>[],
    int shards: 1,
    int shardIndex: 0,
    void onTest(Uri uri),
    Iterable<String> supportedMarkers,
    Uri createUriForFileName(String fileName),
    void onFailure(String message),
    RunTestFunction runTest}) async {
  // TODO(johnniwinther): Support --show to show actual data for an input.
  args = args.toList();
  bool verbose = args.remove('-v');
  bool succinct = args.remove('-s');
  bool shouldContinue = args.remove('-c');
  bool testAfterFailures = args.remove('-a');
  bool printCode = args.remove('-p');
  bool continued = false;
  bool hasFailures = false;

  String relativeDir = dataDir.uri.path.replaceAll(Uri.base.path, '');
  print('Data dir: ${relativeDir}');
  List<FileSystemEntity> entities = dataDir.listSync();
  if (shards > 1) {
    int start = entities.length * shardIndex ~/ shards;
    int end = entities.length * (shardIndex + 1) ~/ shards;
    entities = entities.sublist(start, end);
  }
  int testCount = 0;
  for (FileSystemEntity entity in entities) {
    String name = entity.uri.pathSegments.last;
    if (entity is Directory) {
      name = entity.uri.pathSegments[entity.uri.pathSegments.length - 2];
    }
    if (args.isNotEmpty && !args.contains(name) && !continued) continue;
    if (shouldContinue) continued = true;
    testCount++;

    if (onTest != null) {
      onTest(entity.uri);
    }
    print('----------------------------------------------------------------');

    TestData testData = computeTestData(entity,
        supportedMarkers: supportedMarkers,
        createUriForFileName: createUriForFileName,
        onFailure: onFailure);
    print('Test: ${testData.testFileUri}');

    if (await runTest(testData,
        testAfterFailures: testAfterFailures,
        verbose: verbose,
        succinct: succinct,
        printCode: printCode)) {
      hasFailures = true;
    }
  }
  if (hasFailures) {
    onFailure('Errors found.');
  }
  if (testCount == 0) {
    onFailure("No files were tested.");
  }
}
