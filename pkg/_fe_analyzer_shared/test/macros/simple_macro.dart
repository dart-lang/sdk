// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// A very simple macro that annotates functions (or getters) with no arguments
/// and adds a print statement to the top of them.
class SimpleMacro implements FunctionDefinitionMacro {
  final int? x;
  final int? y;

  SimpleMacro([this.x, this.y]);

  SimpleMacro.named({this.x, this.y});

  @override
  FutureOr<void> buildDefinitionForFunction(
      FunctionDeclaration method, FunctionDefinitionBuilder builder) {
    if (method.namedParameters
        .followedBy(method.positionalParameters)
        .isNotEmpty) {
      throw ArgumentError(
          'This macro can only be run on functions with no arguments!');
    }
    builder.augment(FunctionBodyCode.fromString('''{
      print('x: $x, y: $y');
      return augment super();
    }'''));
  }
}
