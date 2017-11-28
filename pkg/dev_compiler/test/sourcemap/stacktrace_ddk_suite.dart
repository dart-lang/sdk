import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';
import 'sourcemaps_ddk_suite.dart' as ddk;

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new StackTraceContext();
}

class StackTraceContext extends ChainContextWithCleanupHelper {
  final List<Step> steps = <Step>[
    const Setup(),
    const SetCwdToSdkRoot(),
    const TestStackTrace(
        const ddk.RunDdc(false), "ddk.", const ["ddk.", "ddc."]),
  ];
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
