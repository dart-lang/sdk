// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart' show Chain, runMe;

import 'spell_checking_utils.dart' as spell;
import 'spelling_test_base.dart' show SpellContext, SpellOptions;

void main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<SpellContext> createContext(
  Chain suite,
  Map<String, String> environment,
) {
  return new Future.value(
    new SpellContextExternal(SpellOptions.create(environment)),
  );
}

class SpellContextExternal extends SpellContext {
  new(super.spellOptions);

  @override
  List<spell.Dictionaries> get dictionaries => const <spell.Dictionaries>[];

  @override
  bool get onlyDenylisted => true;

  @override
  String get repoRelativeSuitePath =>
      "pkg/front_end/test/spelling_test_external_targets.dart";
}
