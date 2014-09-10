import 'package:path/path.dart' as p;
import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('activating a hosted package deactivates the path one', () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "1.0.0",
          contents: [
              d.dir("bin", [d.file("foo.dart", "main(args) => print('hosted');")])]);
    });
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "2.0.0"),
            d.dir("bin", [d.file("foo.dart", "main() => print('path');")])]).create();
    schedulePub(args: ["global", "activate", "foo"]);
    var path = canonicalize(p.join(sandboxDir, "foo"));
    schedulePub(args: ["global", "activate", "-spath", "../foo"], output: """
        Package foo is currently active at version 1.0.0.
        Activated foo 2.0.0 at path "$path".""");
    var pub = pubRun(global: true, args: ["foo"]);
    pub.stdout.expect("path");
    pub.shouldExit();
  });
}
