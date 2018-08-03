// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Script to update the dart2js status lines for all tests running with the
// $dart2js_with_kernel test configuration.

import 'dart:io';
import 'package:args/args.dart';
import 'update_from_log.dart' as update_script;

const List<String> strongSuites = const <String>[
  'language_2',
  'corelib_2',
];

const List<String> nonStrongSuites = const <String>[
  'dart2js_native',
  'dart2js_extra',
  'language',
  'corelib',
  'html',
];

main(List<String> args) {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true)
    ..addFlag('with-fast-startup')
    ..addFlag('fast-startup')
    ..addFlag('strong')
    ..addFlag('with-checked-mode')
    ..addFlag('checked-mode')
    ..addFlag('checked');
  ArgResults argResults = argParser.parse(args);
  bool fastStartup =
      argResults['with-fast-startup'] || argResults['fast-startup'];
  bool strong = argResults['strong'];
  bool checkedMode = argResults['with-checked-mode'] ||
      argResults['checked-mode'] ||
      argResults['checked'];
  List<String> suites = argResults.rest;
  if (suites.isEmpty) {
    if (strong) {
      suites = strongSuites;
    } else {
      suites = nonStrongSuites;
    }
    if (Platform.isWindows) {
      // TODO(johnniwinther): Running drt seems to be broken on Windows.
      suites = new List<String>.from(suites)..remove('html');
    }
  } else {
    bool failure = false;
    for (String suite in suites) {
      if (strongSuites.contains(suite) && nonStrongSuites.contains(suite)) {
        print("Unknown suite '$suite'");
        failure = true;
      }
    }
    if (failure) {
      exit(1);
    }
  }

  Directory tmp = Directory.systemTemp.createTempSync('update_all');

  String python = Platform.isWindows ? 'python.exe' : 'python';

  updateSuiteWithFlags(
      String name, String suite, String runtime, List<String> args) {
    if (strong) {
      name = "$name-strong";
      args.add('--strong');
    }

    print("  - $name tests");
    List<String> testArgs = [
      './tools/test.py',
      '-m',
      'release',
      '-c',
      'dart2js',
      '-r',
      runtime,
      '--dart2js-batch',
      '--dart2js-with-kernel'
    ];
    testArgs.addAll(args);
    testArgs.add(suite);
    String temp = '${tmp.path}/$suite-$name.txt';
    ProcessResult result = Process.runSync(python, testArgs);
    String stdout = result.stdout.toString();
    new File(temp).writeAsStringSync(stdout);
    print(temp);
    update_script.main([name, temp]);
  }

  updateSuite(String suite) {
    String runtime = "d8";
    if (suite == "html") {
      runtime = "drt";
    }
    print("update suite: \u001b[32m$suite\u001b[0m");

    updateSuiteWithFlags(
        'minified', suite, runtime, ["--minified", "--use-sdk"]);
    updateSuiteWithFlags('host-checked', suite, runtime, ["--host-checked"]);
    if (fastStartup) {
      updateSuiteWithFlags('fast-startup', suite, runtime, ["--fast-startup"]);
    }
    if (checkedMode) {
      updateSuiteWithFlags('checked-mode', suite, runtime, ["--checked"]);
    }
  }

  print('build create_sdk');
  ProcessResult result = Process
      .runSync(python, ['./tools/build.py', '-m', 'release', 'create_sdk']);
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    exit(1);
  }

  suites.forEach(updateSuite);

  tmp.deleteSync(recursive: true);
}
