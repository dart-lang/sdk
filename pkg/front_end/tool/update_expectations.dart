// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'fasta.dart' as fasta;

const List<String> standardSuites = <String>[
  'strong',
  'outline',
  'weak',
  'text_serialization',
  'textual_outline',
];

const List<String> specialSuites = <String>[
  'expression',
  'incremental_load_from_dill',
];

Future<void> runStandardSuites([List<String> args]) async {
  // Assert that 'strong' is the first suite - we use the assumption below.
  assert(standardSuites.first == 'strong', "Suite 'strong' most be the first.");
  bool first = true;
  for (String suite in standardSuites) {
    List<String> tests = args == null
        ? [suite]
        : args.map((String arg) => '${suite}/$arg').toList();
    await fasta.main([
      'testing',
      ...tests,
      // Only update comments in the first suite. Note that this only works
      // if the first compilation is a full compilation, i.e. not outline,
      // because comments are generated during body building and inference.
      if (first) '-DupdateComments=true',
      '-DupdateExpectations=true'
    ]);
    first = false;
  }
}

main(List<String> args) async {
  if (args.isEmpty) {
    await runStandardSuites();
    for (String suite in specialSuites) {
      await fasta.main(['testing', suite, '-DupdateExpectations=true']);
    }
  } else {
    List<String> standardTests = <String>[];
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
        standardTests.add(arg);
      }
    }
    if (standardTests.isNotEmpty) {
      await runStandardSuites(args);
    }
  }
}
