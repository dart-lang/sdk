// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart';

import 'stacktrace_suite.dart';

Future<ChainContext> _createContext(
  Chain suite,
  Map<String, String> environment,
) async {
  return StackTraceContext(moduleFormat: 'ddc', canary: true);
}

void main(List<String> arguments) {
  runMe(arguments, _createContext, configurationPath: 'testing.json');
}
