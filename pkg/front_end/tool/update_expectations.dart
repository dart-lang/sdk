// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'fasta.dart' as fasta;

const List<String> standardSuites = <String>[
  'strong',
  'outline',
  'weak',
  'text_serialization',
];

const List<String> specialSuites = <String>[
  'expression',
  'incremental_load_from_dill',
];

Future<void> runStandardSuites([String arg]) async {
  // Assert that 'strong' is the first suite - we use the assumption below.
  assert(specialSuites.first == 'strong', "Suite 'strong' most be the first.");
  bool first = true;
  for (String suite in standardSuites) {
    await fasta.main([
      'testing',
      arg != null ? '${suite}/$arg' : suite,
      // Only update comments in the first suite. Note that this only works
      // if the first compilation is a full compilation, i.e. not outline,
      // because comments are generated during body building and inference.
      if (first)
        '-DupdateComments=true',
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
        runStandardSuites(arg);
      }
    }
  }
}
