// @dart = 2.9

import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';
import 'sourcemaps_ddk_suite.dart' as ddk;

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return StackTraceContext();
}

class StackTraceContext extends ChainContextWithCleanupHelper
    implements WithCompilerState {
  @override
  fe.InitializedCompilerState compilerState;

  List<Step> _steps;

  @override
  List<Step> get steps {
    return _steps ??= <Step>[
      const Setup(),
      const SetCwdToSdkRoot(),
      TestStackTrace(ddk.DevCompilerRunner(this, debugging: false), 'ddk',
          const ['ddk', 'ddc']),
    ];
  }
}

void main(List<String> arguments) =>
    runMe(arguments, createContext, configurationPath: 'testing.json');
