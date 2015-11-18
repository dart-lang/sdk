// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.plugin.options;

import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/plugin/task.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:plugin/plugin.dart';

/// A plugin that defines the extension points and extensions that are defined
/// by applications that want to consume options defined in the analysis
/// options file.
class OptionsPlugin implements Plugin {
  /// The simple identifier of the extension point that allows plugins to
  /// register new options processors.
  static const String OPTIONS_PROCESSOR_EXTENSION_POINT = 'optionsProcessor';

  /// The simple identifier of the extension point that allows plugins to
  /// register new options validators.
  static const String OPTIONS_VALIDATOR_EXTENSION_POINT = 'optionsValidator';

  /// The unique identifier of this plugin.
  static const String UNIQUE_IDENTIFIER = 'options.core';

  /// The extension point that allows plugins to register new options
  /// processors.
  ExtensionPoint optionsProcessorExtensionPoint;

  /// The extension point that allows plugins to register new options
  /// validators.
  ExtensionPoint optionsValidatorExtensionPoint;

  /// All contributed options processors.
  List<OptionsProcessor> get optionsProcessors =>
      optionsProcessorExtensionPoint?.extensions ?? const [];

  /// All contributed options validators.
  List<OptionsValidator> get optionsValidators =>
      optionsValidatorExtensionPoint?.extensions ?? const [];

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    optionsProcessorExtensionPoint = registerExtensionPoint(
        OPTIONS_PROCESSOR_EXTENSION_POINT, _validateOptionsProcessorExtension);
    optionsValidatorExtensionPoint = registerExtensionPoint(
        OPTIONS_VALIDATOR_EXTENSION_POINT, _validateOptionsValidatorExtension);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    // Analyze options files.
    registerExtension(
        TASK_EXTENSION_POINT_ID, GenerateOptionsErrorsTask.DESCRIPTOR);
    // Validate analyzer analysis options.
    registerExtension(
        OPTIONS_VALIDATOR_EXTENSION_POINT_ID, new AnalyzerOptionsValidator());
  }

  /// Validate the given extension by throwing an [ExtensionError] if it is not
  /// a valid options processor.
  void _validateOptionsProcessorExtension(Object extension) {
    if (extension is! OptionsProcessor) {
      String id = optionsProcessorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError('Extensions to $id must be an OptionsProcessor');
    }
  }

  /// Validate the given extension by throwing an [ExtensionError] if it is not
  /// a valid options validator.
  void _validateOptionsValidatorExtension(Object extension) {
    if (extension is! OptionsValidator) {
      String id = optionsValidatorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError('Extensions to $id must be an OptionsValidator');
    }
  }
}
