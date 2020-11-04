// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:testing/testing.dart' show Chain, ChainContext, Step, runMe;

import '../../utils/scanner_chain.dart' show Read, Scan;

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new ScannerContext();
}

class ScannerContext extends ChainContext {
  final List<Step> steps = const <Step>[
    const Read(),
    const Scan(),
  ];
}

main(List<String> arguments) =>
    runMe(arguments, createContext, configurationPath: "../../../testing.json");
