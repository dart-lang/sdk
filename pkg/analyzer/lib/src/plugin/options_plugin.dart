// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.plugin.options_plugin;

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
  ExtensionPoint<OptionsProcessor> optionsProcessorExtensionPoint;

  /// The extension point that allows plugins to register new options
  /// validators.
  ExtensionPoint<OptionsValidator> optionsValidatorExtensionPoint;

  /// All contributed options processors.
  List<OptionsProcessor> get optionsProcessors =>
      optionsProcessorExtensionPoint?.extensions ?? const <OptionsProcessor>[];

  /// All contributed options validators.
  List<OptionsValidator> get optionsValidators =>
      optionsValidatorExtensionPoint?.extensions ?? const <OptionsValidator>[];

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    optionsProcessorExtensionPoint = new ExtensionPoint<OptionsProcessor>(
        this, OPTIONS_PROCESSOR_EXTENSION_POINT, null);
    registerExtensionPoint(optionsProcessorExtensionPoint);
    optionsValidatorExtensionPoint = new ExtensionPoint<OptionsValidator>(
        this, OPTIONS_VALIDATOR_EXTENSION_POINT, null);
    registerExtensionPoint(optionsValidatorExtensionPoint);
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
}
