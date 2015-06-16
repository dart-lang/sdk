// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.plugin_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:linter/src/plugin/linter_plugin.dart';
import 'package:plugin/manager.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';

main() {
  groupSep = ' | ';

  defineTests();
}

/// Default contributed lint rules.
var builtinRules = [
  'camel_case_types',
  'constant_identifier_names',
  'empty_constructor_bodies',
  'library_names',
  'library_prefixes',
  'non_constant_identifier_names',
  'one_member_abstracts',
  'slash_for_doc_comments',
  'super_goes_last',
  'type_init_formals',
  'unnecessary_brace_in_string_interp'
];

/// Plugin tests
defineTests() {
  group('plugin', () {
    test('contributed rules', () {
      LinterPlugin linterPlugin = newTestPlugin();
      var contributedRules = linterPlugin.lintRules.map((rule) => rule.name);
      expect(contributedRules, unorderedEquals(builtinRules));
    });

    // Verify that if options are processed only explicitly enabled rules are
    // in the lint rule registry.
    test('option processing', () {
      LinterPlugin linterPlugin = newTestPlugin();

      var src = '''
rules:
  style_guide:
    camel_case_types: true
    constant_identifier_names: true
    empty_constructor_bodies: false
''';
      var yaml = loadYamlNode(src);

      AnalysisEngine.instance.optionsPlugin.optionsProcessors
          .forEach((op) => op.optionsProcessed({'linter': yaml}));
      var rules = linterPlugin.lintRules.map((rule) => rule.name);
      expect(rules,
          unorderedEquals(['camel_case_types', 'constant_identifier_names']));
    });
  });
}

LinterPlugin newTestPlugin() {
  LinterPlugin linterPlugin = new LinterPlugin();
  ExtensionManager manager = new ExtensionManager();
  manager.processPlugins(new List.from(AnalysisEngine.instance.supportedPlugins)
    ..add(linterPlugin));
  return linterPlugin;
}
