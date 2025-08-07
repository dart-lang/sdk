// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

/// Options (keys) that can be specified in an analysis options file.
final class AnalysisOptionsFile {
  // Top-level options.
  static const String analyzer = 'analyzer';
  static const String codeStyle = 'code-style';
  static const String formatter = 'formatter';
  static const String linter = 'linter';

  /// The shared key for top-level plugins and `analyzer`-level plugins.
  static const String plugins = 'plugins';

  // `analyzer` analysis options.
  static const String cannotIgnore = 'cannot-ignore';
  static const String enableExperiment = 'enable-experiment';
  static const String errors = 'errors';
  static const String exclude = 'exclude';
  static const String include = 'include';
  static const String language = 'language';
  static const String optionalChecks = 'optional-checks';
  static const String strongMode = 'strong-mode';

  // Optional checks options.
  static const String chromeOsManifestChecks = 'chrome-os-manifest-checks';

  // Strong mode options (see AnalysisOptionsImpl for documentation).
  static const String declarationCasts = 'declaration-casts';
  static const String implicitCasts = 'implicit-casts';
  static const String implicitDynamic = 'implicit-dynamic';

  // Language options (see AnalysisOptionsImpl for documentation).
  static const String strictCasts = 'strict-casts';
  static const String strictInference = 'strict-inference';
  static const String strictRawTypes = 'strict-raw-types';

  // Code style options.
  static const String format = 'format';

  /// Ways to say `ignore`.
  static const List<String> ignoreSynonyms = ['ignore', 'false'];

  /// Valid error `severity`s.
  static final List<String> severities = List.unmodifiable(severityMap.keys);

  /// Ways to say `include`.
  static const List<String> includeSynonyms = ['include', 'true'];

  // Formatter options.
  static const String pageWidth = 'page_width';
  static const String trailingCommas = 'trailing_commas';

  // Linter options.
  static const String rules = 'rules';

  // Plugins options.
  static const String diagnostics = 'diagnostics';
  static const String path = 'path';
  static const String version = 'version';

  /// Supported 'plugins' options.
  static const Set<String> pluginsOptions = {diagnostics, path, version};

  static const String propagateLinterExceptions = 'propagate-linter-exceptions';

  /// Ways to say `true` or `false`.
  static const List<String> trueOrFalse = ['true', 'false'];

  /// Supported top-level `analyzer` options.
  static const Set<String> analyzerOptions = {
    cannotIgnore,
    enableExperiment,
    errors,
    exclude,
    language,
    optionalChecks,
    plugins,
    strongMode,
  };

  /// Supported `analyzer` strong-mode options.
  ///
  /// This section is deprecated.
  static const Set<String> strongModeOptions = {
    declarationCasts,
    implicitCasts,
    implicitDynamic,
  };

  /// Supported `analyzer` language options.
  static const Set<String> languageOptions = {
    strictCasts,
    strictInference,
    strictRawTypes,
  };

  /// Supported 'linter' options.
  static const Set<String> linterOptions = {rules};

  /// Supported 'analyzer' optional checks options.
  static const Set<String> optionalChecksOptions = {
    chromeOsManifestChecks,
    propagateLinterExceptions,
  };

  /// Proposed values for a `true` or `false` option.
  static String get trueOrFalseProposal =>
      AnalysisOptionsFile.trueOrFalse.quotedAndCommaSeparatedWithAnd;
}
