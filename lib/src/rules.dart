// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules;

import 'dart:collection';

import 'package:linter/src/config.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/rules/camel_case_types.dart';
import 'package:linter/src/rules/constant_identifier_names.dart';
import 'package:linter/src/rules/empty_constructor_bodies.dart';
import 'package:linter/src/rules/library_names.dart';
import 'package:linter/src/rules/library_prefixes.dart';
import 'package:linter/src/rules/non_constant_identifier_names.dart';
import 'package:linter/src/rules/one_member_abstracts.dart';
import 'package:linter/src/rules/package_prefixed_library_names.dart';
import 'package:linter/src/rules/pub/package_names.dart';
import 'package:linter/src/rules/slash_for_doc_comments.dart';
import 'package:linter/src/rules/super_goes_last.dart';
import 'package:linter/src/rules/type_init_formals.dart';
import 'package:linter/src/rules/unnecessary_brace_in_string_interp.dart';
import 'package:linter/src/rules/unnecessary_getters_setters.dart';

final Registry ruleRegistry = new Registry()
  ..register(new CamelCaseTypes())
  ..register(new ConstantIdentifierNames())
  ..register(new EmptyConstructorBodies())
  ..register(new LibraryNames())
  ..register(new LibraryPrefixes())
  ..register(new NonConstantIdentifierNames())
  ..register(new OneMemberAbstracts())
  ..register(new PackagePrefixedLibraryNames())
  ..register(new PubPackageNames())
  ..register(new SlashForDocComments())
  ..register(new SuperGoesLast())
  ..register(new TypeInitFormals())
  ..register(new UnnecessaryBraceInStringInterp())
  // Disabled pending fix: https://github.com/dart-lang/linter/issues/35
  //..register(new UnnecessaryGetters())
  ..register(new UnnecessaryGettersSetters());

/// Registry of contributed lint rules.
class Registry extends Object with IterableMixin<LintRule> {
  Map<String, LintRule> _ruleMap = <String, LintRule>{};

  @override
  Iterator<LintRule> get iterator => _ruleMap.values.iterator;

  Iterable<LintRule> get rules => _ruleMap.values;

  LintRule operator [](String key) => _ruleMap[key];

  Iterable<LintRule> enabled(LintConfig config) => rules
      .where((rule) => !config.ruleConfigs.any((rc) => rc.disables(rule.name)));

  register(LintRule rule) => _ruleMap[rule.name] = rule;
}
