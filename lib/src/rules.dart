// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules;

import 'package:linter/src/linter.dart';
import 'package:linter/src/rules/camel_case_types.dart';
import 'package:linter/src/rules/empty_constructor_bodies.dart';
import 'package:linter/src/rules/library_names.dart';
import 'package:linter/src/rules/library_prefixes.dart';
import 'package:linter/src/rules/one_member_abstracts.dart';
import 'package:linter/src/rules/pub/pub_package_names.dart';
import 'package:linter/src/rules/super_goes_last.dart';
import 'package:linter/src/rules/type_init_formals.dart';
import 'package:linter/src/rules/unnecessary_brace_in_string_interp.dart';
import 'package:linter/src/rules/unnecessary_getters.dart';
import 'package:linter/src/rules/unnecessary_getters_setters.dart';

/// Map of contributed lint rules.
final Map<String, LintRule> ruleMap = {
  'camel_case_types': new CamelCaseTypes(),
  'empty_constructor_bodies': new EmptyConstructorBodies(),
  'library_names': new LibraryNames(),
  'library_prefixes': new LibraryPrefixes(),
  'one_member_abstracts': new OneMemberAbstracts(),
  'pub_package_names': new PubPackageNames(),
  'super_goes_last': new SuperGoesLast(),
  'type_init_formals': new TypeInitFormals(),
  'unnecessary_brace_in_string_interp': new UnnecessaryBraceInStringInterp(),
  'unnecessary_getters': new UnnecessaryGetters(),
  'unnecessary_getters_setters': new UnnecessaryGettersSetters()
};

/// Sorted list of contributed lint rules.
final List<LintRule> rules =
    new List<LintRule>.from(ruleMap.values, growable: false)..sort();
