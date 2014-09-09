import '../descriptor.dart' as d;
import '../test_pub.dart';
const SCRIPT = """
main(List<String> args) {
  print(args.join(" "));
}
""";
main() {
  initConfig();
  integration('passes arguments to the spawned script', () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("bin", [d.file("args.dart", SCRIPT)])]).create();
    var pub = pubRun(args: ["args", "--verbose", "-m", "--", "help"]);
    pub.stdout.expect("--verbose -m -- help");
    pub.shouldExit();
  });
}
