import 'package:path/path.dart' as path;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('runs a Dart application in the entrypoint package', () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "tool",
                [
                    d.file("app.dart", "main() => print('tool');"),
                    d.dir("sub", [d.file("app.dart", "main() => print('sub');")])])]).create();
    var pub = pubRun(args: [path.join("tool", "app")]);
    pub.stdout.expect("tool");
    pub.shouldExit();
    pub = pubRun(args: [path.join("tool", "sub", "app")]);
    pub.stdout.expect("sub");
    pub.shouldExit();
  });
}
