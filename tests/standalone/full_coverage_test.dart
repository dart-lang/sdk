// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests fork a second VM process that runs the script
// ``tools/full-coverage.dart'' and verifies that the tool
// produces the expeced output.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

final String coverageScript = "tools/full-coverage.dart";
final String packageRoot = Platform.packageRoot;
final List dartBaseArgs = ['--package-root=${packageRoot}', '--checked',];

// With line numbers starting at 0, the list of hits can be understood as
// follows:
// * -1: No coverage data on this line.
// *  0: No hits on this line.
// *  1: ``Some'' hits on this line.
final coverageTests = [
  {
    'name': 'faculty',
    'program': '''
dummy () {
  for (int i = 0; i < 100; i++) {
    print(i);
  }
}

int fac(int n) {
  int f = 1;
  for (int i = 1; i <= n; i++) {
    f *= i;
  }
  return f;
}

main() {
  if (false) {
    dummy(11);
  } else {
    fac(10);
  }
}
''',
    'expectedHits': [-1, 0, 0, -1, -1, -1, -1, -1, 1, 1, -1, -1, -1, -1, -1, -1,
                     0, -1, 1, -1, -1]
  },{
    'name': 'closures',
    'program': '''
main() {
  foo(bar) {
    bar();
  }

  foo(() {
    print("in closure");
  });
}
''',
    'expectedHits': [-1, -1, 1, -1, -1, 1, 1, -1, -1]
  }
];


String prepareEnv() {
  Directory testDir = Directory.systemTemp.createTempSync("coverage-");
  for (var coverageProg in coverageTests) {
    var coverageProgDir = new Directory(
        path.join(testDir.path, coverageProg["name"]))
      ..createSync();
    var f = new File(path.join(coverageProgDir.path,
        "${coverageProg['name']}.dart"));
    f.writeAsStringSync(coverageProg["program"], mode: FileMode.WRITE);
  }
  return testDir.path;
}


destroyEnv(base) => new Directory(base).deleteSync(recursive: true);


generateCoverage(String workingDirectory) {
  for (var coverageProg in coverageTests) {
    var progPath = path.join(workingDirectory, coverageProg['name']);
    var script = path.join(progPath, "${coverageProg['name']}.dart");
    var dartArgs = new List.from(dartBaseArgs)
      ..addAll(['--coverage-dir=${progPath}', '${script}']);
    var result = Process.runSync(Platform.executable, dartArgs);
    expect(result.exitCode, 0);
  }
}


Future<Process> convertCoverage(String programDir, String format) {
  var dartArgs = new List.from(dartBaseArgs)
      ..addAll([
        coverageScript,
        '--package-root=${packageRoot}',
        '--in=${programDir}',
        format
      ]);
  return Process.start(Platform.executable, dartArgs);
}


class PrettyPrintDescriptor {
  var _programPath;
  var _validFormat = new RegExp(r"^\s*\d*\|.*$", multiLine: true);
  var _pattern = new RegExp(r"^\s*(\d+)\|", multiLine: true);

  PrettyPrintDescriptor(this._programPath);

  get sectionStart => _programPath;
  get sectionEnd => '/';
  get coverageParameter => '--pretty-print';

  hitData(line) {
    expect(_validFormat.hasMatch(line), isTrue);
    var match = _pattern.firstMatch(line);
    var result = -1;
    if (match != null) {
      result = (int.parse(match.group(1)) != 0) ? 1 : 0;
    }
    return [result];
  }
}


class LcovDescriptor {
  var _pattern = new RegExp(r"^DA:(\d+),(\d+)$", multiLine: true);
  var _programPath;
  var _line_nr = 0;

  LcovDescriptor(this._programPath);

  get sectionStart => 'SF:${_programPath}';
  get sectionEnd => 'end_of_record';
  get coverageParameter => '--lcov';

  hitData(line) {
    expect(_pattern.hasMatch(line), isTrue);
    var match = _pattern.firstMatch(line);
    // Lcov data starts at line 1, we start at 0.
    var out_line = int.parse(match[1]) - 1;
    var hitCount = int.parse(match[2]);
    var result = [];
    for ( ; _line_nr < out_line; _line_nr++) {
      result.add(-1);
    }
    result.add((hitCount != 0) ? 1 : 0);
    _line_nr++;
    return result;
  }
}


Stream filterHitData(input, descriptor) {
  bool in_program_section = false;
  return input.where((line) {
    if (in_program_section) {
      if (line.startsWith(descriptor.sectionEnd)) {
        in_program_section = false;
        return false;
      }
      return true;
    }
    if (line.startsWith(descriptor.sectionStart)) {
      in_program_section = true;
    }
    return false;
  }).map((line) {
    return descriptor.hitData(line);
  });
}


testCoverage(String programDir, String programPath, descriptor,
             List expectedHitMap) {
  var p = convertCoverage(programDir, descriptor.coverageParameter);
  expect(p.then((process) {
    var hitStream = filterHitData(
        process.stdout.transform(UTF8.decoder)
                      .transform(const LineSplitter()),
        descriptor);
    var hitMap = [];
    var subscription = hitStream.listen((data) {
      // Flatten results.
      data.forEach((e) => hitMap.add(e));
    });
    expect(subscription.asFuture().then((_) {
      hitMap.forEach((e) {
        expect(e, expectedHitMap.removeAt(0));
      });
      // Make sure that there are only lines left that do not contain coverage
      // data.
      expectedHitMap.forEach((e) => expect(e, -1));
    }), completes);
  }), completes);
}


main() {
  String testingDirectory;

  setUp(() {
    testingDirectory = prepareEnv();
  });

  tearDown(() => destroyEnv(testingDirectory));

  test('CoverageTests', () {
    generateCoverage(testingDirectory);

    coverageTests.forEach((cTest) {
      String programDir = path.join(testingDirectory, cTest['name']);
      String programPath = path.join(programDir, "${cTest['name']}.dart");
      testCoverage(programDir, programPath,
                   new LcovDescriptor(programPath),
                   new List.from(cTest['expectedHits']));
      testCoverage(programDir, programPath,
                   new PrettyPrintDescriptor(programPath),
                   new List.from(cTest['expectedHits']));
    });
  });
}
