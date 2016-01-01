// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.plugin.linter_plugin;

import 'package:analysis_server/src/services/linter/linter.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:plugin/plugin.dart';

/// The shared linter server plugin instance.
final LinterServerPlugin linterServerPlugin = new LinterServerPlugin();

/// A plugin that defines the extension points and extensions that enhance
/// linting in the server.
class LinterServerPlugin implements Plugin {
  /// The unique identifier of this plugin.
  static const String UNIQUE_IDENTIFIER = 'linter.server';

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {
    // None.
  }

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    //
    // Register options validators.
    //
    registerExtension(
        OPTIONS_VALIDATOR_EXTENSION_POINT_ID, new LinterRuleOptionsValidator());
  }
}
