library pub_tests;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';
import '../lib/src/exit_codes.dart' as exit_codes;
import '../lib/src/sdk.dart' as sdk;
import 'test_pub.dart';
main() {
  initConfig();
  integration('parse the real SDK "version" file', () {
    var pubPath = path.join(
        sdk.rootDirectory,
        'bin',
        Platform.operatingSystem == "windows" ? "pub.bat" : "pub");
    var pub = new ScheduledProcess.start(pubPath, ['version']);
    pub.stdout.expect(startsWith("Pub"));
    pub.shouldExit(exit_codes.SUCCESS);
  });
}
