// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for client code that wants to consume options contributed to the
/// analysis options file.
library analyzer.plugin.options;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/plugin/options_plugin.dart';
import 'package:plugin/plugin.dart';
import 'package:yaml/yaml.dart';

/// The identifier of the extension point that allows plugins to access
/// options defined in the analysis options file. The object used as an
/// extension must be an [OptionsProcessor].
final String OPTIONS_PROCESSOR_EXTENSION_POINT_ID = Plugin.join(
    OptionsPlugin.UNIQUE_IDENTIFIER,
    OptionsPlugin.OPTIONS_PROCESSOR_EXTENSION_POINT);

/// The identifier of the extension point that allows plugins to validate
/// options defined in the analysis options file. The object used as an
/// extension must be an [OptionsValidator].
final String OPTIONS_VALIDATOR_EXTENSION_POINT_ID = Plugin.join(
    OptionsPlugin.UNIQUE_IDENTIFIER,
    OptionsPlugin.OPTIONS_VALIDATOR_EXTENSION_POINT);

/// Processes options defined in the analysis options file.
///
/// Clients may implement this class when implementing plugins.
///
/// The options file format is intentionally very open-ended, giving clients
/// utmost flexibility in defining their own options.  The only hardfast
/// expectation is that options files will contain a mapping from Strings
/// (identifying 'scopes') to associated options.  For example, the given
/// content
///
///     linter:
///       rules:
///         camel_case_types: true
///     compiler:
///       resolver:
///         useMultiPackage: true
///       packagePaths:
///         - /foo/bar/pkg
///         - /bar/baz/pkg
///
/// defines two scopes, `linter` and `compiler`.  Parsing would result in a
/// map, mapping the `linter` and `compiler` scope identifiers to their
/// respective parsed option node contents. Extracting values is a simple
/// matter of inspecting the parsed nodes.  For example, testing whether the
/// compiler's resolver is set to use the `useMultiPackage` option might look
/// something like this (eliding error-checking):
///
///     bool useMultiPackage =
///         options['compiler']['resolver']['useMultiPackage'];
abstract class OptionsProcessor {
  /// Called when an error occurs in processing options.
  void onError(Exception exception);

  /// Called when an options file is processed.
  ///
  /// The options file is processed on analyzer initialization and
  /// subsequently when the file is changed on disk.  In the event of a
  /// change notification, note that the notification simply indicates
  /// a change on disk. Content in specific option scopes may or may not
  /// be different. It is up to the implementer to check whether specific
  /// options have changed and to handle those changes appropriately. In
  /// addition to the [options] map, the associated analysis [context] is
  /// provided as well to allow for context-specific configuration.
  void optionsProcessed(AnalysisContext context, Map<String, Object> options);
}

/// Validates options as defined in an analysis options file.
///
/// Clients may implement this class when implementing plugins.
///
/// See [OptionsProcessor] for a description of the options file format.
///
abstract class OptionsValidator {
  /// Validate [options], reporting any errors to the given [reporter].
  void validate(ErrorReporter reporter, Map<String, YamlNode> options);
}
