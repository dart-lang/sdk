// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/formatter_options.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';

/// A set of analysis options used to control the behavior of an analysis
/// context.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisOptions {
  /// A flag indicating whether to run checks on AndroidManifest.xml file to
  /// see if it is complaint with Chrome OS.
  bool get chromeOsManifestChecks;

  /// Return the options used to control the code that is generated.
  CodeStyleOptions get codeStyleOptions;

  /// The set of features that are globally enabled for this context.
  FeatureSet get contextFeatures;

  /// A list of the names of the packages for which, if they define a
  /// legacy plugin, the legacy plugin should be enabled.
  List<String> get enabledLegacyPluginNames;

  /// The list of error processors that are to be used when reporting errors in
  /// some analysis context.
  List<ErrorProcessor> get errorProcessors;

  /// The list of exclude patterns used to exclude some sources from analysis.
  List<String> get excludePatterns;

  /// The options used to control the formatter.
  FormatterOptions get formatterOptions;

  /// Whether analysis is to generate lint warnings.
  bool get lint;

  /// A list of the lint rules that are to be run in an analysis context if
  /// [lint] is `true`.
  // ignore: analyzer_public_api_bad_type
  List<AbstractAnalysisRule> get lintRules;

  /// Whether implicit casts should be reported as potential problems.
  bool get strictCasts;

  /// Whether inference failures are allowed, off by default.
  bool get strictInference;

  /// Whether raw types (types without explicit type arguments, such as `List`)
  /// should be reported as potential problems.
  ///
  /// Raw types are a common source of `dynamic` being introduced implicitly.
  bool get strictRawTypes;

  /// Return `true` if analysis is to generate warning results (e.g. best
  /// practices and analysis based on certain annotations).
  bool get warning;

  /// Return `true` the lint with the given [name] is enabled.
  bool isLintEnabled(String name);
}
