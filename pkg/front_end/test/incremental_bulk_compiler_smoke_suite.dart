// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart' show Chain;

import 'utils/suite_utils.dart';
import 'incremental_bulk_compiler_full.dart' show Context;

void main([List<String> arguments = const []]) => internalMain(createContext,
    arguments: arguments,
    displayName: "incremental bulk compiler smoke suite",
    configurationPath: "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) {
  return new Future.value(new Context());
}
