library pub_cache_test;
import 'package:path/path.dart' as path;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  hostedDir(package) {
    return path.join(
        sandboxDir,
        cachePath,
        "hosted",
        "pub.dartlang.org",
        package);
  }
  integration('running pub cache list when there is no cache', () {
    schedulePub(args: ['cache', 'list'], output: '{"packages":{}}');
  });
  integration('running pub cache list on empty cache', () {
    d.dir(
        cachePath,
        [d.dir('hosted', [d.dir('pub.dartlang.org', [])])]).create();
    schedulePub(args: ['cache', 'list'], outputJson: {
      "packages": {}
    });
  });
  integration('running pub cache list', () {
    d.dir(
        cachePath,
        [
            d.dir(
                'hosted',
                [
                    d.dir(
                        'pub.dartlang.org',
                        [
                            d.dir("foo-1.2.3", [d.libPubspec("foo", "1.2.3"), d.libDir("foo")]),
                            d.dir(
                                "bar-2.0.0",
                                [d.libPubspec("bar", "2.0.0"), d.libDir("bar")])])])]).create();
    schedulePub(args: ['cache', 'list'], outputJson: {
      "packages": {
        "bar": {
          "2.0.0": {
            "location": hostedDir('bar-2.0.0')
          }
        },
        "foo": {
          "1.2.3": {
            "location": hostedDir('foo-1.2.3')
          }
        }
      }
    });
  });
  integration('includes packages containing deps with bad sources', () {
    d.dir(
        cachePath,
        [
            d.dir(
                'hosted',
                [
                    d.dir(
                        'pub.dartlang.org',
                        [d.dir("foo-1.2.3", [d.libPubspec("foo", "1.2.3", deps: {
              "bar": {
                "bad": "bar"
              }
            }), d.libDir("foo")])])])]).create();
    schedulePub(args: ['cache', 'list'], outputJson: {
      "packages": {
        "foo": {
          "1.2.3": {
            "location": hostedDir('foo-1.2.3')
          }
        }
      }
    });
  });
}
