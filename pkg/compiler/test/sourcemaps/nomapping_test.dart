// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';

import 'package:compiler/src/util/memory_compiler.dart';

const List<String> TESTS = const <String>[
  '''
main() {}
''',
];

void main(List<String> arguments) {
  bool verbose = false;
  bool writeJs = false;
  List<int>? indices;
  for (String arg in arguments) {
    if (arg == '-v') {
      verbose = true;
    } else if (arg == '--write-js') {
      writeJs = true;
    } else {
      int? index = int.tryParse(arg);
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
    indices = List<int>.generate(TESTS.length * 2, (i) => i);
  }
  asyncTest(() async {
    for (int index in indices!) {
      bool useNewSourceInfo = index % 2 == 1;
      await runTest(index, TESTS[index ~/ 2],
          writeJs: writeJs,
          verbose: verbose,
          useNewSourceInfo: useNewSourceInfo);
    }
  });
}

Future runTest(int index, String code,
    {required bool writeJs,
    bool verbose = false,
    bool useNewSourceInfo = false}) async {
  print("--$index------------------------------------------------------------");
  print("Compiling dart2js ${useNewSourceInfo ? Flags.useNewSourceInfo : ''}\n"
      "${code}");
  OutputCollector collector = OutputCollector();
  List<String> options = <String>['--out=out.js', '--source-map=out.js.map'];
  if (useNewSourceInfo) {
    options.add(Flags.useNewSourceInfo);
  }
  CompilationResult compilationResult = await runCompiler(
      entryPoint: Uri.parse('memory:main.dart'),
      memorySourceFiles: {'main.dart': code},
      outputProvider: collector,
      options: options);
  Expect.isTrue(compilationResult.isSuccess,
      "Unsuccessful compilation of test:\n${code}");
  String sourceMapText = collector.getOutput('', api.OutputType.sourceMap)!;
  final sourceMap = parse(sourceMapText) as SingleMapping;
  if (writeJs) {
    File('out.js')
        .writeAsStringSync(collector.getOutput('', api.OutputType.js)!);
    File('out.js.map').writeAsStringSync(sourceMapText);
  }
  Expect.isTrue(sourceMap.lines.isNotEmpty);
  TargetLineEntry firstLineEntry = sourceMap.lines.first;
  Expect.isTrue(firstLineEntry.entries.isNotEmpty);
  TargetEntry firstEntry = firstLineEntry.entries.first;
  Expect.isNull(
      firstEntry.sourceUrlId,
      "Unexpected first entry: "
      "${entryToString(firstLineEntry, firstEntry, sourceMap)}");
  TargetLineEntry lastLineEntry = sourceMap.lines.last;
  Expect.isTrue(lastLineEntry.entries.isNotEmpty);
  TargetEntry lastEntry = firstLineEntry.entries.last;
  Expect.isNull(
      lastEntry.sourceUrlId,
      "Unexpected last entry: "
      "${entryToString(lastLineEntry, lastEntry, sourceMap)}");
}

String entryToString(
    TargetLineEntry lineEntry, TargetEntry entry, SingleMapping mapping) {
  StringBuffer sb = StringBuffer();
  sb.write('[line=');
  sb.write(lineEntry.line);
  sb.write(',column=');
  sb.write(entry.column);
  sb.write(',');
  if (entry.sourceUrlId != null) {
    sb.write('sourceUrl=');
    sb.write(mapping.urls[entry.sourceUrlId!]);
    sb.write(',');
  }
  if (entry.sourceNameId != null) {
    sb.write('sourceName=');
    sb.write(mapping.names[entry.sourceNameId!]);
    sb.write(',');
  }
  if (entry.sourceLine != null) {
    sb.write('sourceLine=');
    sb.write(entry.sourceLine);
    sb.write(',sourceColumn=');
    sb.write(entry.sourceColumn);
  }
  sb.write(']');
  return sb.toString();
}
