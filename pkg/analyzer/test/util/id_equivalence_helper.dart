// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: this file contains code that was mostly copied from
// tests/compiler/dart2js/equivalence/id_equivalence_helper.dart
// and then tweaked to work with the analyzer.
// TODO(paulberry,johnniwinther): share this code between the analyzer and
// dart2js.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Annotation;
import 'package:front_end/src/testing/annotated_code_helper.dart';
import 'package:front_end/src/testing/id.dart'
    show ActualData, Id, IdValue, MemberId, NodeId;

/// Checks [compiledData] against the expected data in [expectedMap] derived
/// from [code].
Future<bool> checkCode<T>(
    String mode,
    Uri mainFileUri,
    Map<Uri, AnnotatedCode> code,
    MemberAnnotations<IdValue> expectedMaps,
    CompiledData compiledData,
    DataInterpreter<T> dataValidator,
    {bool filterActualData(IdValue expected, ActualData<T> actualData),
    bool fatalErrors: true}) async {
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
          reportError(
              actualData.offset,
              'EXTRA $mode DATA for ${id.descriptor}:\n '
              'object   : ${actualData.objectText}\n '
              'actual   : ${colorizeActual('${IdValue.idToString(id, actualText)}')}\n '
              'Data was expected for these ids: ${expectedMap.keys}');
          if (filterActualData == null || filterActualData(null, actualData)) {
            hasLocalFailure = true;
          }
        }
      } else {
        IdValue expected = expectedMap[id];
        String unexpectedMessage =
            dataValidator.isAsExpected(actual, expected.value);
        if (unexpectedMessage != null) {
          reportError(
              actualData.offset,
              'UNEXPECTED $mode DATA for ${id.descriptor}:\n '
              'detail  : ${colorizeMessage(unexpectedMessage)}\n '
              'object  : ${actualData.objectText}\n '
              'expected: ${colorizeExpected('$expected')}\n '
              'actual  : ${colorizeActual('${IdValue.idToString(id, actualText)}')}');
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
        String message = 'MISSING $mode DATA for ${id.descriptor}: '
            'Expected ${colorizeExpected('$expected')}';
        if (uri != null) {
          var begin = data.getOffsetFromId(id, uri);
          reportError(begin, message);
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
  for (Uri uri in neededDiffs) {
    print('--annotations diff [${uri.pathSegments.last}]-------------');
    print(data.diffCode(uri, dataValidator));
    print('----------------------------------------------------------');
  }
  if (missingIds.isNotEmpty) {
    print("MISSING ids: $missingIds.");
    hasFailure = true;
  }
  if (hasFailure && fatalErrors) {
    throw StateError('Errors found.');
  }
  return hasFailure;
}

Future<bool> checkTests<T>(
    String rawCode,
    Future<ResolvedUnitResult> resultComputer(String rawCode),
    DataComputer<T> dataComputer) async {
  AnnotatedCode code =
      new AnnotatedCode.fromText(rawCode, commentStart, commentEnd);
  var result = await resultComputer(code.sourceCode);
  var uri = result.libraryElement.source.uri;
  var marker = 'normal';
  Map<String, MemberAnnotations<IdValue>> expectedMaps = {
    marker: new MemberAnnotations<IdValue>(),
  };
  computeExpectedMap(uri, code, expectedMaps);
  MemberAnnotations<IdValue> annotations = expectedMaps[marker];
  Map<Id, ActualData<T>> actualMap = {};
  dataComputer.computeUnitData(result.unit, actualMap);
  var compiledData = CompiledData<T>(uri, {uri: actualMap}, {});
  return await checkCode(marker, uri, {uri: code}, annotations, compiledData,
      dataComputer.dataValidator);
}

/// Colorize the actual annotation [text], if ANSI colors are supported.
String colorizeActual(String text) {
  return text;
}

/// Colorize annotation delimiters [start] and [end] surrounding [text], if
/// ANSI colors are supported.
String colorizeAnnotation(String start, String text, String end) {
  return '${colorizeDelimiter(start)}$text${colorizeDelimiter(end)}';
}

/// Colorize delimiter [text], if ANSI colors are supported.
String colorizeDelimiter(String text) {
  return text;
}

/// Colorize diffs [expected] and [actual] and [delimiter], if ANSI colors are
/// supported.
String colorizeDiff(String expected, String delimiter, String actual) {
  return '${colorizeExpected(expected)}'
      '${colorizeDelimiter(delimiter)}${colorizeActual(actual)}';
}

/// Colorize an expected annotation [text], if ANSI colors are supported.
String colorizeExpected(String text) {
  return text;
}

/// Colorize a matching annotation [text], if ANSI colors are supported.
String colorizeMatch(String text) {
  return text;
}

/// Colorize a message [text], if ANSI colors are supported.
String colorizeMessage(String text) {
  return text;
}

/// Compute three [MemberAnnotations] objects from [code] specifying the
/// expected annotations we anticipate encountering; one corresponding to the
/// old implementation, one for the new implementation, and one for the new
/// implementation using strong mode.
///
/// If an annotation starts with 'ast.' it is only expected for the old
/// implementation, if it starts with 'kernel.' it is only expected for the
/// new implementation, and if it starts with 'strong.' it is only expected for
/// strong mode (using the common frontend). Otherwise it is expected for all
/// implementations.
///
/// Most nodes have the same and expectations should match this by using
/// annotations without prefixes.
void computeExpectedMap(Uri sourceUri, AnnotatedCode code,
    Map<String, MemberAnnotations<IdValue>> maps) {
  List<String> mapKeys = maps.keys.toList();
  Map<String, AnnotatedCode> split = splitByPrefixes(code, mapKeys);

  split.forEach((String marker, AnnotatedCode code) {
    MemberAnnotations<IdValue> fileAnnotations = maps[marker];
    assert(fileAnnotations != null, "No annotations for $marker in $maps");
    Map<Id, IdValue> expectedValues = fileAnnotations[sourceUri];
    for (Annotation annotation in code.annotations) {
      String text = annotation.text;
      IdValue idValue = IdValue.decode(annotation.offset, text);
      if (idValue.id.isGlobal) {
        _expectFalse(
            fileAnnotations.globalData.containsKey(idValue.id),
            "Duplicate annotations for ${idValue.id} in $marker: "
            "$idValue and ${fileAnnotations.globalData[idValue.id]}.");
        fileAnnotations.globalData[idValue.id] = idValue;
      } else {
        _expectFalse(
            expectedValues.containsKey(idValue.id),
            "Duplicate annotations for ${idValue.id} in $marker: "
            "$idValue and ${expectedValues[idValue.id]}.");
        expectedValues[idValue.id] = idValue;
      }
    }
  });
}

/// Reports [message] as an error using [spannable] as error location.
void reportError(int offset, String message) {
  print('$offset: $message');
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

void _expectFalse(bool b, String message) {
  if (b) {
    throw StateError(message);
  }
}

class CompiledData<T> {
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
    actualMap.forEach((Id id, ActualData<T> actualData) {
      String actualValue = '${actualData.value}';
      annotations
          .putIfAbsent(actualData.offset, () => [])
          .add(colorizeActual(actualValue));
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
}

abstract class DataComputer<T> {
  const DataComputer();

  DataInterpreter<T> get dataValidator;

  /// Function that computes a data mapping for [unit].
  ///
  /// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
  /// for the data origin.
  void computeUnitData(CompilationUnit unit, Map<Id, ActualData<T>> actualMap);
}

/// Interface used for interpreting annotations.
abstract class DataInterpreter<T> {
  /// Returns a textual representation of [actualData].
  String getText(T actualData);

  /// Returns `null` if [actualData] satisfies the [expectedData] annotation.
  /// Otherwise, a message is returned contain the information about the
  /// problems found.
  String isAsExpected(T actualData, String expectedData);

  /// Returns `true` if [actualData] corresponds to empty data.
  bool isEmpty(T actualData);
}

/// Data collected by [computeData].
class IdData<T> {
  final Map<Uri, AnnotatedCode> code;
  final MemberAnnotations<IdValue> expectedMaps;
  final CompiledData _compiledData;
  final MemberAnnotations<ActualData<T>> _actualMaps = new MemberAnnotations();

  IdData(this.code, this.expectedMaps, this._compiledData) {
    for (Uri uri in code.keys) {
      _actualMaps[uri] = _compiledData.actualMaps[uri] ?? <Id, ActualData<T>>{};
    }
    _actualMaps.globalData.addAll(_compiledData.globalData);
  }

  MemberAnnotations<ActualData<T>> get actualMaps => _actualMaps;
  Uri get mainUri => _compiledData.mainUri;

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
          String value1 = '$expected';
          String value2 = IdValue.idToString(id, '$actual');
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
          String value1 = '$expected';
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
    if (id is NodeId) {
      return id.value;
    } else if (id is MemberId) {
      if (id.className != null) {
        throw UnimplementedError('TODO(paulberry): handle class members');
      }
      var name = id.memberName;
      var unit =
          parseString(content: code[uri].sourceCode, throwIfDiagnostics: false)
              .unit;
      for (var declaration in unit.declarations) {
        if (declaration is FunctionDeclaration) {
          if (declaration.name.name == name) {
            return declaration.offset;
          }
        }
      }
      throw StateError('Member not found: $name');
    } else {
      throw StateError('Unexpected id ${id.runtimeType}');
    }
  }
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

  Map<Id, DataType> operator [](Uri file) {
    if (!_computedDataForEachFile.containsKey(file)) {
      _computedDataForEachFile[file] = <Id, DataType>{};
    }
    return _computedDataForEachFile[file];
  }

  void operator []=(Uri file, Map<Id, DataType> computedData) {
    _computedDataForEachFile[file] = computedData;
  }

  void forEach(void f(Uri file, Map<Id, DataType> computedData)) {
    _computedDataForEachFile.forEach(f);
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
