// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart' show Chain;

import 'utils/suite_utils.dart';
import 'spell_checking_utils.dart' as spell;
import 'spelling_test_base.dart';

void main([List<String> arguments = const []]) => internalMain(
  createContext,
  arguments: arguments,
  displayName: "spelling test not src suite",
  configurationPath: "../testing.json",
);

Future<SpellContext> createContext(
  Chain suite,
  Map<String, String> environment,
) {
  return new Future.value(
    new SpellContextTest(SpellOptions.create(environment)),
  );
}

class SpellContextTest extends SpellContext {
  new(super.spellOptions);

  @override
  List<spell.Dictionaries> get dictionaries => const <spell.Dictionaries>[
    spell.Dictionaries.common,
    spell.Dictionaries.cfeCode,
    spell.Dictionaries.cfeTests,
  ];

  @override
  bool get onlyDenylisted => false;

  @override
  String get repoRelativeSuitePath =>
      "pkg/front_end/test/spelling_test_not_src_suite.dart";
}
