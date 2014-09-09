import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('removes precompiled snapshots', () {
    servePackages((builder) => builder.serve("foo", "1.0.0"));
    schedulePub(args: ["global", "activate", "foo"]);
    schedulePub(
        args: ["global", "deactivate", "foo"],
        output: "Deactivated package foo 1.0.0.");
    d.dir(cachePath, [d.dir('global_packages', [d.nothing('foo')])]).validate();
  });
}
