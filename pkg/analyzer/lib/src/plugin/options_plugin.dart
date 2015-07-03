// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.plugin.options;

import 'package:analyzer/plugin/options.dart';
import 'package:plugin/plugin.dart';

/// A plugin that defines the extension points and extensions that are defined
/// by applications that want to consume options defined in the analysis
/// options file.
class OptionsPlugin implements Plugin {

  /// The simple identifier of the extension point that allows plugins to
  /// register new options processors.
  static const String OPTIONS_PROCESSOR_EXTENSION_POINT = 'optionsProcessor';

  /// The unique identifier of this plugin.
  static const String UNIQUE_IDENTIFIER = 'options.core';

  /// The extension point that allows plugins to register new options processors.
  ExtensionPoint optionsProcessorExtensionPoint;

  /// All contributed options processors.
  List<OptionsProcessor> get optionsProcessors =>
      optionsProcessorExtensionPoint.extensions;

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    optionsProcessorExtensionPoint = registerExtensionPoint(
        OPTIONS_PROCESSOR_EXTENSION_POINT, _validateOptionsProcessorExtension);
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    // There are no default extensions.
  }

  /// Validate the given extension by throwing an [ExtensionError] if it is not a
  /// valid options processor.
  void _validateOptionsProcessorExtension(Object extension) {
    if (extension is! OptionsProcessor) {
      String id = optionsProcessorExtensionPoint.uniqueIdentifier;
      throw new ExtensionError('Extensions to $id must be an OptionsProcessor');
    }
  }
}
