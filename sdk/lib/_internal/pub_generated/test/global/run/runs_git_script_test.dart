import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('runs a script in a git package', () {
    ensureGit();
    d.git(
        'foo.git',
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"]);
    var pub = pubRun(global: true, args: ["foo"]);
    pub.stdout.expect("ok");
    pub.shouldExit();
  });
}
