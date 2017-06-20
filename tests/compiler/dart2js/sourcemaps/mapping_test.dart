// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';

import '../annotated_code_helper.dart';
import '../memory_compiler.dart';

const List<String> TESTS = const <String>[
  '''
@{main}main() {
@{main}}
''',
  '''
@{main}main() {
  @{+main}throw '';
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

@NoInline()
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

Test processTestCode(String code, {bool useNewSourceInfo}) {
  List<SourceLocation> expectedLocations = <SourceLocation>[];
  AnnotatedCode annotatedCode = new AnnotatedCode.fromText(code);
  for (Annotation annotation in annotatedCode.annotations) {
    String methodName;
    if (annotation.text.startsWith('-')) {
      // Expect only in old source maps
      if (useNewSourceInfo) continue;
      methodName = annotation.text.substring(1);
    } else if (annotation.text.startsWith('+')) {
      // Expect only in new source maps
      if (!useNewSourceInfo) continue;
      methodName = annotation.text.substring(1);
    } else {
      methodName = annotation.text;
    }
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
      int index = int.parse(arg, onError: (_) => null);
      if (index != null) {
        indices ??= <int>[];
        if (index < 0 || index >= TESTS.length * 2) {
          print('Index $index out of bounds: [0;${TESTS.length - 1}]');
        } else {
          indices.add(index);
        }
      }
    }
  }
  if (indices == null) {
    indices = new List<int>.generate(TESTS.length * 2, (i) => i);
  }
  asyncTest(() async {
    for (int index in indices) {
      bool useNewSourceInfo = index % 2 == 1;
      await runTest(
          index,
          processTestCode(TESTS[index ~/ 2],
              useNewSourceInfo: useNewSourceInfo),
          printJs: printJs,
          writeJs: writeJs,
          verbose: verbose,
          useNewSourceInfo: useNewSourceInfo);
    }
  });
}

Future runTest(int index, Test test,
    {bool printJs: false,
    bool writeJs,
    bool verbose: false,
    bool useNewSourceInfo: false}) async {
  print("--$index------------------------------------------------------------");
  print("Compiling dart2js ${useNewSourceInfo ? Flags.useNewSourceInfo : ''}\n"
      "${test.annotatedCode}");
  OutputCollector collector = new OutputCollector();
  List<String> options = <String>['--out=out.js', '--source-map=out.js.map'];
  if (useNewSourceInfo) {
    options.add(Flags.useNewSourceInfo);
  }
  CompilationResult compilationResult = await runCompiler(
      entryPoint: Uri.parse('memory:main.dart'),
      memorySourceFiles: {'main.dart': test.code},
      outputProvider: collector,
      options: options);
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
    AnnotatedCode annotatedCode = new AnnotatedCode(test.code, []);
    expectedLocations.forEach(
        (l) => annotatedCode.addAnnotation(l.lineNo, l.columnNo, l.methodName));
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
    AnnotatedCode annotatedCode = new AnnotatedCode(test.code, []);
    extraLocations.forEach(
        (l) => annotatedCode.addAnnotation(l.lineNo, l.columnNo, l.methodName));
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

  int get hashCode =>
      methodName.hashCode * 13 + lineNo.hashCode * 17 + columnNo.hashCode * 19;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SourceLocation) return false;
    return methodName == other.methodName &&
        lineNo == other.lineNo &&
        columnNo == other.columnNo;
  }

  String toString() => '$methodName:$lineNo:$columnNo';
}
