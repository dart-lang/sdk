import 'package:testing/testing.dart';

import 'common.dart';
import 'ddc_common.dart';
import 'sourcemaps_ddc_suite.dart' as ddc;

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return StackTraceContext();
}

class StackTraceContext extends ChainContextWithCleanupHelper {
  @override
  final List<Step> steps = <Step>[
    const Setup(),
    const SetCwdToSdkRoot(),
    const TestStackTrace(
        ddc.DevCompilerRunner(debugging: false, absoluteRoot: false),
        "ddc",
        ["ddc", "ddk"]),
  ];
}

void main(List<String> arguments) =>
    runMe(arguments, createContext, "testing.json");
