// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'fasta.dart' as fasta;

const List<String> standardSuites = <String>[
  'weak',
  'outline',
  'strong',
  'modular',
  'textual_outline',
];

const List<String> specialSuites = <String>[
  'expression',
  'incremental',
  'parser',
];

Future<void> runStandardSuites([List<String>? args]) async {
  // Assert that 'strong' is the first suite - we use the assumption below.
  assert(standardSuites.first == 'weak', "Suite 'weak' most be the first.");

  List<String> testingArguments = [];
  for (String suite in standardSuites) {
    List<String> tests = args == null
        ? [suite]
        : args.map((String arg) => '${suite}/$arg').toList();
    testingArguments.addAll(tests);
  }
  await fasta.main([
    'testing',
    ...testingArguments,
    // Only update comments in the first suite. Note that this only works
    // if the first compilation is a full compilation, i.e. not outline,
    // because comments are generated during body building and inference.
    '-DupdateComments=true',
    '-DupdateExpectations=true',
  ]);
}

Future<void> runAllSpecialSuites([List<String>? args]) async {
  List<String> testingArguments = [];
  for (String suite in specialSuites) {
    List<String> tests = args == null
        ? [suite]
        : args.map((String arg) => '${suite}/$arg').toList();
    testingArguments.addAll(tests);
  }
  await fasta.main([
    'testing',
    ...testingArguments,
    '-DupdateExpectations=true',
  ]);
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    await runStandardSuites();
    await runAllSpecialSuites();
  } else {
    List<String> standardTests = <String>[];
    List<String> wildcardSpecialTests = <String>[];
    for (String arg in args) {
      bool isSpecial = false;
      for (String suite in specialSuites) {
        if (arg.startsWith('$suite/')) {
          await fasta.main(['testing', arg, '-DupdateExpectations=true']);
          isSpecial = true;
          break;
        }
      }
      if (!isSpecial) {
        wildcardSpecialTests.add(arg);
        standardTests.add(arg);
      }
    }
    if (wildcardSpecialTests.isNotEmpty) {
      await runAllSpecialSuites(wildcardSpecialTests);
    }
    if (standardTests.isNotEmpty) {
      await runStandardSuites(standardTests);
    }
  }
}
