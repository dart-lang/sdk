// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.plugin.linter_plugin;

import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:linter/plugin/linter.dart';
import 'package:linter/src/config.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/rules/camel_case_types.dart';
import 'package:linter/src/rules/constant_identifier_names.dart';
import 'package:linter/src/rules/empty_constructor_bodies.dart';
import 'package:linter/src/rules/library_names.dart';
import 'package:linter/src/rules/library_prefixes.dart';
import 'package:linter/src/rules/non_constant_identifier_names.dart';
import 'package:linter/src/rules/one_member_abstracts.dart';
import 'package:linter/src/rules/slash_for_doc_comments.dart';
import 'package:linter/src/rules/super_goes_last.dart';
import 'package:linter/src/rules/type_init_formals.dart';
import 'package:linter/src/rules/unnecessary_brace_in_string_interp.dart';
import 'package:plugin/plugin.dart';

/// The shared linter plugin instance.
final LinterPlugin linterPlugin = new LinterPlugin();

/// A plugin that defines the extension points and extensions that are
/// inherently defined by the linter.
class LinterPlugin implements Plugin {

  static const List<Linter> _noLints = const <Linter>[];

  /// The unique identifier of this plugin.
  static const String UNIQUE_IDENTIFIER = 'linter.core';

  /// The simple identifier of the extension point that allows plugins to
  /// register new lint rules.
  static const String LINT_RULE_EXTENSION_POINT = 'rule';

  /// The extension point that allows plugins to register new lint rules.
  ExtensionPoint lintRuleExtensionPoint;

  /// An options processor for creating lint configs from analysis options.
  AnalysisOptionsProcessor _optionsProcessor;

  LinterPlugin() {
    _optionsProcessor = new AnalysisOptionsProcessor(this);
  }

  /// Return a list of all contributed lint rules.
  List<LintRule> get contributedRules => lintRuleExtensionPoint.extensions;

  /// Cached config (temporary to support legacy `lintRules` getter).
  LintConfig _config;

  /// Return a list of enabled lint rules.
  ///
  /// By default this list includes all [contributedRules].  Specific lints
  /// can be enabled/disabled (and in the future further configured) through
  /// a specified analysis options file.
  @deprecated // Use lintRegistry
  List<LintRule> get lintRules => _getRules(_config);

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    lintRuleExtensionPoint = registerExtensionPoint(
        LINT_RULE_EXTENSION_POINT, _validateTaskExtension);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    // A subset of rules that we are considering enabled by "default".
    [
      new CamelCaseTypes(),
      new ConstantIdentifierNames(),
      new EmptyConstructorBodies(),
      new LibraryNames(),
      new LibraryPrefixes(),
      new NonConstantIdentifierNames(),
      new OneMemberAbstracts(),
      new SlashForDocComments(),
      new SuperGoesLast(),
      new TypeInitFormals(),
      new UnnecessaryBraceInStringInterp()
    ].forEach((LintRule rule) =>
        registerExtension(LINT_RULE_EXTENSION_POINT_ID, rule));
    registerExtension(OPTIONS_PROCESSOR_EXTENSION_POINT_ID, _optionsProcessor);
  }

  List<Linter> registerLints(AnalysisContext context, LintConfig config) {
    _config = config;
    return lintRegistry[context] = _getRules(config);
  }

  List<Linter> _getRules(LintConfig config) {
    if (config != null) {
      return ruleRegistry.enabled(config).toList();
    }
    return _noLints;
  }

  void _validateTaskExtension(Object extension) {
    if (extension is! LintRule) {
      String id = lintRuleExtensionPoint.uniqueIdentifier;
      throw new ExtensionError('Extensions to $id must implement LintRule');
    }
  }
}
