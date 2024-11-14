// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart' show Chain;

import 'utils/suite_utils.dart';
import 'spell_checking_utils.dart' as spell;
import 'spelling_test_base.dart';
import 'testing_utils.dart' show checkEnvironment;

void main([List<String> arguments = const []]) => internalMain(createContext,
    arguments: arguments,
    displayName: "spelling test src suite",
    configurationPath: "../testing.json");

Future<SpellContext> createContext(
    Chain suite, Map<String, String> environment) {
  const Set<String> knownEnvironmentKeys = {"interactive", "onlyInGit"};
  checkEnvironment(environment, knownEnvironmentKeys);

  bool interactive = environment["interactive"] == "true";
  bool onlyInGit = environment["onlyInGit"] != "false";
  return new Future.value(
      new SpellContextSource(interactive: interactive, onlyInGit: onlyInGit));
}

class SpellContextSource extends SpellContext {
  SpellContextSource({required bool interactive, required bool onlyInGit})
      : super(interactive: interactive, onlyInGit: onlyInGit);

  @override
  List<spell.Dictionaries> get dictionaries => const <spell.Dictionaries>[
        spell.Dictionaries.common,
        spell.Dictionaries.cfeCode
      ];

  @override
  bool get onlyDenylisted => false;

  @override
  String get repoRelativeSuitePath =>
      "pkg/front_end/test/spelling_test_src_suite.dart";
}
