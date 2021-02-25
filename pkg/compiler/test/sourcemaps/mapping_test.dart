// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';

import '../helpers/memory_compiler.dart';

const List<String> TESTS = const <String>[
  '''
@{main}main() {
@{main}}
''',
  '''
@{main}main() {
  @{main}throw '';
@{main}}
''',
  '''
@{main}main() {
  @{main}return 0;
@{main}}
''',
  '''
import 'package:expect/expect.dart';
@{main}main() {
  @{main}test();
@{main}}

@pragma('dart2js:noInline')
@{test}test() {
@{test}}
''',
];

class Test {
  final String annotatedCode;
  final String code;
  final List<SourceLocation> expectedLocations;

  Test(this.annotatedCode, this.code, this.expectedLocations);
}

Test processTestCode(String code) {
  List<SourceLocation> expectedLocations = <SourceLocation>[];
  AnnotatedCode annotatedCode = new AnnotatedCode.fromText(code);
  for (Annotation annotation in annotatedCode.annotations) {
    String methodName = annotation.text;
    expectedLocations.add(
        new SourceLocation(methodName, annotation.lineNo, annotation.columnNo));
  }
  return new Test(code, annotatedCode.sourceCode, expectedLocations);
}

void main(List<String> arguments) {
  bool verbose = false;
  bool printJs = false;
  bool writeJs = false;
  List<int> indices;
  for (String arg in arguments) {
    if (arg == '-v') {
      verbose = true;
    } else if (arg == '--print-js') {
      printJs = true;
    } else if (arg == '--write-js') {
      writeJs = true;
    } else {
      int index = int.tryParse(arg);
      if (index != null) {
        indices ??= <int>[];
        if (index < 0 || index >= TESTS.length) {
          print('Index $index out of bounds: [0;${TESTS.length - 1}]');
        } else {
          indices.add(index);
        }
      }
    }
  }
  if (indices == null) {
    indices = new List<int>.generate(TESTS.length, (i) => i);
  }
  asyncTest(() async {
    for (int index in indices) {
      await runTest(index, processTestCode(TESTS[index]),
          printJs: printJs, writeJs: writeJs, verbose: verbose);
    }
  });
}

Future runTest(int index, Test test,
    {bool printJs: false, bool writeJs, bool verbose: false}) async {
  print("--$index------------------------------------------------------------");
  print("Compiling dart2js\n ${test.annotatedCode}");
  OutputCollector collector = new OutputCollector();
  List<String> options = <String>['--out=out.js', '--source-map=out.js.map'];
  CompilationResult compilationResult = await runCompiler(
      entryPoint: Uri.parse('memory:main.dart'),
      memorySourceFiles: {'main.dart': test.code},
      outputProvider: collector,
      options: options,
      unsafeToTouchSourceFiles: true);
  Expect.isTrue(compilationResult.isSuccess,
      "Unsuccessful compilation of test:\n${test.code}");
  String sourceMapText = collector.getOutput('', OutputType.sourceMap);
  SingleMapping sourceMap = parse(sourceMapText);
  if (writeJs) {
    new File('out.js')
        .writeAsStringSync(collector.getOutput('', OutputType.js));
    new File('out.js.map').writeAsStringSync(sourceMapText);
  }

  Set<SourceLocation> expectedLocations = test.expectedLocations.toSet();
  List<SourceLocation> actualLocations = <SourceLocation>[];
  List<SourceLocation> extraLocations = <SourceLocation>[];
  for (TargetLineEntry targetLineEntry in sourceMap.lines) {
    for (TargetEntry targetEntry in targetLineEntry.entries) {
      if (targetEntry.sourceUrlId != null &&
          sourceMap.urls[targetEntry.sourceUrlId] == 'memory:main.dart') {
        String methodName;
        if (targetEntry.sourceNameId != null) {
          methodName = sourceMap.names[targetEntry.sourceNameId];
        }
        SourceLocation location = new SourceLocation(methodName,
            targetEntry.sourceLine + 1, targetEntry.sourceColumn + 1);
        actualLocations.add(location);
        if (!expectedLocations.remove(location)) {
          extraLocations.add(location);
        }
      }
    }
  }

  if (expectedLocations.isNotEmpty) {
    print('--Missing source locations:---------------------------------------');
    AnnotatedCode annotatedCode = new AnnotatedCode(test.code, test.code, []);
    expectedLocations.forEach((l) => annotatedCode.addAnnotation(
        l.lineNo, l.columnNo, '/*', l.methodName, '*/'));
    print(annotatedCode.toText());
    print('------------------------------------------------------------------');
    Expect.isTrue(
        expectedLocations.isEmpty,
        "Missing source locations:\n${test.code}\n"
        "Actual:\n${actualLocations.join('\n')}\n"
        "Missing:\n${expectedLocations.join('\n')}\n");
  }
  if (extraLocations.isNotEmpty) {
    print('--Extra source locations:-----------------------------------------');
    AnnotatedCode annotatedCode = new AnnotatedCode(test.code, test.code, []);
    extraLocations.forEach((l) => annotatedCode.addAnnotation(
        l.lineNo, l.columnNo, '/*', l.methodName, '*/'));
    print(annotatedCode.toText());
    print('------------------------------------------------------------------');
    Expect.isTrue(
        extraLocations.isEmpty,
        "Extra source locations:\n${test.code}\n"
        "Actual:\n${actualLocations.join('\n')}\n"
        "Extra:\n${extraLocations.join('\n')}\n");
  }
}

class SourceLocation {
  final String methodName;
  final int lineNo;
  final int columnNo;

  SourceLocation(this.methodName, this.lineNo, this.columnNo);

  @override
  int get hashCode =>
      methodName.hashCode * 13 + lineNo.hashCode * 17 + columnNo.hashCode * 19;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SourceLocation) return false;
    return methodName == other.methodName &&
        lineNo == other.lineNo &&
        columnNo == other.columnNo;
  }

  @override
  String toString() => '$methodName:$lineNo:$columnNo';
}
