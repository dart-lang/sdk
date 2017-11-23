import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';
import 'sourcemaps_ddc_suite.dart' as ddc;

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new StackTraceContext();
}

class StackTraceContext extends ChainContextWithCleanupHelper {
  final List<Step> steps = <Step>[
    const Setup(),
    const SetCwdToSdkRoot(),
    const TestStackTrace(const ddc.RunDdc(), "ddc."),
  ];
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
