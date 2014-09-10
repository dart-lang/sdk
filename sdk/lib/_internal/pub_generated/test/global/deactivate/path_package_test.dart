import 'package:path/path.dart' as p;
import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('deactivates an active path package', () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(args: ["global", "activate", "--source", "path", "../foo"]);
    var path = canonicalize(p.join(sandboxDir, "foo"));
    schedulePub(
        args: ["global", "deactivate", "foo"],
        output: 'Deactivated package foo 1.0.0 at path "$path".');
  });
}
