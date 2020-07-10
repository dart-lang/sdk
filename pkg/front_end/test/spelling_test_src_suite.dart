// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:testing/testing.dart' show Chain, runMe;

import 'spelling_test_base.dart';

import 'spell_checking_utils.dart' as spell;

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<SpellContext> createContext(
    Chain suite, Map<String, String> environment) async {
  bool interactive = environment["interactive"] == "true";
  return new SpellContextSource(interactive: interactive);
}

class SpellContextSource extends SpellContext {
  SpellContextSource({bool interactive}) : super(interactive: interactive);

  @override
  List<spell.Dictionaries> get dictionaries => const <spell.Dictionaries>[
        spell.Dictionaries.common,
        spell.Dictionaries.cfeCode
      ];

  @override
  bool get onlyDenylisted => false;
}
