import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('deactivates an active Git package', () {
    ensureGit();
    d.git(
        'foo.git',
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"]);
    schedulePub(
        args: ["global", "deactivate", "foo"],
        output: 'Deactivated package foo 1.0.0 from Git repository "../foo.git".');
  });
}
