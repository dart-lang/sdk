// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.plugin_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/services/lint.dart';
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
      expect(linterPlugin.contributedRules.map((rule) => rule.name),
          unorderedEquals(builtinRules));
    });

    // Verify that if options are processed only explicitly enabled rules are
    // in the lint rule registry.
    test('option processing', () {
      var src = '''
rules:
  style_guide:
    camel_case_types: true
    constant_identifier_names: true
    empty_constructor_bodies: false
''';
      var yaml = loadYamlNode(src);
      var context = new AnalysisContextImpl();
      AnalysisEngine.instance.optionsPlugin.optionsProcessors
          .forEach((op) => op.optionsProcessed(context, {'linter': yaml}));
      var rules = getLints(context).map((rule) => rule.name);
      expect(rules,
          unorderedEquals(['camel_case_types', 'constant_identifier_names']));

      var src2 = '''
rules:
  - camel_case_types
''';
      var yaml2 = loadYamlNode(src2);
      var context2 = new AnalysisContextImpl();
      AnalysisEngine.instance.optionsPlugin.optionsProcessors
          .forEach((op) => op.optionsProcessed(context2, {'linter': yaml2}));
      var rules2 = getLints(context2).map((rule) => rule.name);
      expect(rules2, unorderedEquals(['camel_case_types']));
    });
  });
}

List<Linter> getLints(AnalysisContext context) =>
    context.getConfigurationData(LinterPlugin.CONFIGURED_LINTS_KEY) ?? [];

LinterPlugin newTestPlugin() {
  LinterPlugin linterPlugin = new LinterPlugin();
  ExtensionManager manager = new ExtensionManager();
  manager.processPlugins(new List.from(AnalysisEngine.instance.supportedPlugins)
    ..add(linterPlugin));
  return linterPlugin;
}
