// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';
import 'sourcemaps_suite.dart';

Future<ChainContext> _createContext(
  Chain suite,
  Map<String, String> environment,
) async {
  return StackTraceContext(moduleFormat: 'es6', canary: false);
}

class StackTraceContext extends ChainContextWithCleanupHelper
    implements WithCompilerState {
  final String moduleFormat;
  final bool canary;

  StackTraceContext({required this.moduleFormat, required this.canary});

  @override
  fe.InitializedCompilerState? compilerState;

  List<Step>? _steps;

  @override
  List<Step> get steps {
    return _steps ??= <Step>[
      const Setup(),
      const SetCwdToSdkRoot(),
      TestStackTrace(
        DevCompilerRunner(
          this,
          debugging: false,
          moduleFormat: moduleFormat,
          canary: canary,
        ),
        'ddc',
        ['ddc'],
      ),
    ];
  }
}

void main(List<String> arguments) {
  runMe(arguments, _createContext, configurationPath: 'testing.json');
}
