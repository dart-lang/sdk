import 'usage_exception.dart';
import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart' as dart;
import 'package:dart2js_info/src/io.dart';

/// Command that converts a `--dump-info` JSON output into a format ingested by Devtools.
///
/// Achieves this by converting an [dart.AllInfo] tree into a [vm.ProgramInfo]
/// tree, which is then converted into the format ingested by DevTools via a
/// [TreeMap] intermediary. Initially built to enable display of code size
/// distribution from all info in a dart web app.
class DevtoolsFormatCommand extends Command<void> with PrintUsageException {
  @override
  final String name = "to_devtools_format";
  @override
  final String description =
      "Converts dart2js info into a format accepted by Dart Devtools' "
      "app size analysis panel.";

  @override
  void run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing argument: info.data or info.json');
    }
    await infoFromFile(args.first);
  }
}
