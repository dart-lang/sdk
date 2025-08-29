// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'utils/suite_utils.dart' show internalMain;
import 'testing/environment_keys.dart';
import 'testing/suite.dart';

Future<FastaContext> createContext(
  Chain suite,
  Map<String, String> environment,
) {
  environment[EnvironmentKeys.compilationMode] = CompileMode.modular.name;
  return FastaContext.create(suite, environment);
}

Future<void> main([List<String> arguments = const []]) async {
  await internalMain(
    createContext,
    arguments: arguments,
    displayName: "modular suite",
    configurationPath: "../testing.json",
  );
}
