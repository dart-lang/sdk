import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('ignores previously activated git commit', () {
    ensureGit();
    d.git('foo.git', [d.libPubspec("foo", "1.0.0")]).create();
    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"], output: '''
            Resolving dependencies...
            + foo 1.0.0 from git ../foo.git
            Precompiling executables...
            Loading source assets...
            Activated foo 1.0.0 from Git repository "../foo.git".''');
    d.git('foo.git', [d.libPubspec("foo", "1.0.1")]).commit();
    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"], output: '''
            Package foo is currently active from Git repository "../foo.git".
            Resolving dependencies...
            + foo 1.0.1 from git ../foo.git
            Precompiling executables...
            Loading source assets...
            Activated foo 1.0.1 from Git repository "../foo.git".''');
  });
}
