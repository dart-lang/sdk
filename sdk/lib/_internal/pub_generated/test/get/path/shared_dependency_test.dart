import 'package:path/path.dart' as path;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("shared dependency with same path", () {
    d.dir(
        "shared",
        [d.libDir("shared"), d.libPubspec("shared", "0.0.1")]).create();
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "0.0.1", deps: {
        "shared": {
          "path": "../shared"
        }
      })]).create();
    d.dir("bar", [d.libDir("bar"), d.libPubspec("bar", "0.0.1", deps: {
        "shared": {
          "path": "../shared"
        }
      })]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        },
        "bar": {
          "path": "../bar"
        }
      })]).create();
    pubGet();
    d.dir(
        packagesPath,
        [
            d.dir("foo", [d.file("foo.dart", 'main() => "foo";')]),
            d.dir("bar", [d.file("bar.dart", 'main() => "bar";')]),
            d.dir("shared", [d.file("shared.dart", 'main() => "shared";')])]).validate();
  });
  integration("shared dependency with paths that normalize the same", () {
    d.dir(
        "shared",
        [d.libDir("shared"), d.libPubspec("shared", "0.0.1")]).create();
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "0.0.1", deps: {
        "shared": {
          "path": "../shared"
        }
      })]).create();
    d.dir("bar", [d.libDir("bar"), d.libPubspec("bar", "0.0.1", deps: {
        "shared": {
          "path": "../././shared"
        }
      })]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        },
        "bar": {
          "path": "../bar"
        }
      })]).create();
    pubGet();
    d.dir(
        packagesPath,
        [
            d.dir("foo", [d.file("foo.dart", 'main() => "foo";')]),
            d.dir("bar", [d.file("bar.dart", 'main() => "bar";')]),
            d.dir("shared", [d.file("shared.dart", 'main() => "shared";')])]).validate();
  });
  integration("shared dependency with absolute and relative path", () {
    d.dir(
        "shared",
        [d.libDir("shared"), d.libPubspec("shared", "0.0.1")]).create();
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "0.0.1", deps: {
        "shared": {
          "path": "../shared"
        }
      })]).create();
    d.dir("bar", [d.libDir("bar"), d.libPubspec("bar", "0.0.1", deps: {
        "shared": {
          "path": path.join(sandboxDir, "shared")
        }
      })]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        },
        "bar": {
          "path": "../bar"
        }
      })]).create();
    pubGet();
    d.dir(
        packagesPath,
        [
            d.dir("foo", [d.file("foo.dart", 'main() => "foo";')]),
            d.dir("bar", [d.file("bar.dart", 'main() => "bar";')]),
            d.dir("shared", [d.file("shared.dart", 'main() => "shared";')])]).validate();
  });
}
