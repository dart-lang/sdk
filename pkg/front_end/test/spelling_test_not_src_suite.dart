// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart' show Chain, runMe;

import 'spelling_test_base.dart';

import 'spell_checking_utils.dart' as spell;

import 'testing_utils.dart' show checkEnvironment;

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<SpellContext> createContext(
    Chain suite, Map<String, String> environment) async {
  const Set<String> knownEnvironmentKeys = {"interactive", "onlyInGit"};
  checkEnvironment(environment, knownEnvironmentKeys);

  bool interactive = environment["interactive"] == "true";
  bool onlyInGit = environment["onlyInGit"] != "false";
  return new SpellContextTest(interactive: interactive, onlyInGit: onlyInGit);
}

class SpellContextTest extends SpellContext {
  SpellContextTest({bool interactive, bool onlyInGit})
      : super(interactive: interactive, onlyInGit: onlyInGit);

  @override
  List<spell.Dictionaries> get dictionaries => const <spell.Dictionaries>[
        spell.Dictionaries.common,
        spell.Dictionaries.cfeCode,
        spell.Dictionaries.cfeTests
      ];

  @override
  bool get onlyDenylisted => false;

  @override
  String get repoRelativeSuitePath =>
      "pkg/front_end/test/spelling_test_not_src_suite.dart";
}
