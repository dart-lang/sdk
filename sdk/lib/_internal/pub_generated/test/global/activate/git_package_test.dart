import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('activates a package from a Git repo', () {
    ensureGit();
    d.git(
        'foo.git',
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"], output: '''
            Resolving dependencies...
            + foo 1.0.0 from git ../foo.git
            Precompiling executables...
            Loading source assets...
            Precompiled foo:foo.
            Activated foo 1.0.0 from Git repository "../foo.git".''');
  });
}
