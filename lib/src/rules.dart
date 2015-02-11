// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library rules;

import 'package:dart_lint/src/linter.dart';
import 'package:dart_lint/src/rules/camel_case_types.dart';
import 'package:dart_lint/src/rules/empty_constructor_bodies.dart';
import 'package:dart_lint/src/rules/library_names.dart';
import 'package:dart_lint/src/rules/one_member_abstracts.dart';
import 'package:dart_lint/src/rules/super_goes_last.dart';
import 'package:dart_lint/src/rules/type_init_formals.dart';
import 'package:dart_lint/src/rules/unnecessary_brace_in_string_interp.dart';
import 'package:dart_lint/src/rules/unnecessary_getters.dart';

/// Map of contributed lint rules.
final Map<String, LintRule> ruleMap = {
  'camel_case_types': new CamelCaseTypes(),
  'empty_constructor_bodies': new EmptyConstructorBodies(),
  'library_names' : new LibraryNames(),
  'one_member_abstracts': new OneMemberAbstracts(),
  'super_goes_last': new SuperGoesLast(),
  'type_init_formals': new TypeInitFormals(),
  'unnecessary_brace_in_string_interp': new UnnecessaryBraceInStringInterp(),
  'unnecessary_getters': new UnnecessaryGetters(),
};

/// Sorted list of contributed lint rules.
final List<LintRule> rules =
    new List<LintRule>.from(ruleMap.values, growable: false)..sort();
