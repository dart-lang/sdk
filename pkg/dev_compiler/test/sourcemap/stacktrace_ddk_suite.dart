import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';
import 'sourcemaps_ddk_suite.dart' as ddk;

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new StackTraceContext();
}

class StackTraceContext extends ChainContextWithCleanupHelper
    implements WithCompilerState {
  fe.InitializedCompilerState compilerState;

  List<Step> _steps;

  List<Step> get steps {
    return _steps ??= <Step>[
      const Setup(),
      const SetCwdToSdkRoot(),
      new TestStackTrace(
          new ddk.RunDdc(this, false), "ddk.", const ["ddk.", "ddc."]),
    ];
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
