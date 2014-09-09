import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_stream.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("reports Dart parse errors", () {
    currentSchedule.timeout *= 3;
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                'web',
                [
                    d.file('file.txt', 'contents'),
                    d.file('file.dart', 'void void;'),
                    d.dir('subdir', [d.file('subfile.dart', 'void void;')])])]).create();
    var pub = startPub(args: ["build"]);
    pub.stdout.expect(startsWith("Loading source assets..."));
    pub.stdout.expect(startsWith("Building myapp..."));
    var consumeFile = consumeThrough(
        inOrder(
            ["[Error from Dart2JS]:", startsWith(p.join("web", "file.dart") + ":")]));
    var consumeSubfile = consumeThrough(
        inOrder(
            [
                "[Error from Dart2JS]:",
                startsWith(p.join("web", "subdir", "subfile.dart") + ":")]));
    pub.stderr.expect(
        either(
            inOrder([consumeFile, consumeSubfile]),
            inOrder([consumeSubfile, consumeFile])));
    pub.shouldExit(exit_codes.DATA);
    d.dir(appPath, [d.dir('build', [d.nothing('web')])]).validate();
  });
}
