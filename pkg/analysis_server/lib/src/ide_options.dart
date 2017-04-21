// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';

/// A set of options used to configure the behavior of IDE functionality.
abstract class IdeOptions {
  factory IdeOptions.from(AnalysisServerOptions options) => new IdeOptionsImpl()
    ..generateFlutterWidgetChildrenBoilerPlate =
        options.enableVerboseFlutterCompletions;

  /// Whether to generate boilerplate for lists of Flutter Widget children.
  /// See: https://github.com/flutter/flutter-intellij/issues/463
  bool get generateFlutterWidgetChildrenBoilerPlate;
}

class IdeOptionsImpl implements IdeOptions {
  /// Initialize a newly created set of options with default values.
  IdeOptionsImpl();

  @override
  bool generateFlutterWidgetChildrenBoilerPlate = false;
}
