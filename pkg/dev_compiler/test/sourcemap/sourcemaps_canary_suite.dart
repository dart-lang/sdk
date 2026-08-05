// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart';

import 'sourcemaps_suite.dart';

Future<ChainContext> createContext(
  Chain suite,
  Map<String, String> environment,
) async {
  return SourceMapContext(
    environment: environment,
    moduleFormat: 'ddc',
    canary: true,
  );
}

void main(List<String> arguments) =>
    runMe(arguments, createContext, configurationPath: 'testing.json');
