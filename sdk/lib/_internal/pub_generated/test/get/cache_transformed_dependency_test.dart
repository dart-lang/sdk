library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
const MODE_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class ModeTransformer extends Transformer {
  final BarbackSettings _settings;

  ModeTransformer.asPlugin(this._settings);

  String get allowedExtensions => '.dart';

  void apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      transform.addOutput(new Asset.fromString(
          transform.primaryInput.id,
          contents.replaceAll("MODE", _settings.mode.name)));
    });
  }
}
""";
main() {
  initConfig();
  integration("caches a transformed dependency", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');
      builder.serve("foo", "1.2.3", deps: {
        'barback': 'any'
      }, pubspec: {
        'transformers': ['foo']
      },
          contents: [
              d.dir(
                  "lib",
                  [
                      d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
                      d.file("foo.dart", "final message = 'Hello!';")])]);
    });
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet(output: contains("Precompiled foo."));
    d.dir(
        appPath,
        [
            d.dir(
                ".pub/deps/debug/foo/lib",
                [d.file("foo.dart", "final message = 'Goodbye!';")])]).validate();
  });
  integration("caches a dependency transformed by its dependency", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');
      builder.serve("foo", "1.2.3", deps: {
        'bar': '1.2.3'
      }, pubspec: {
        'transformers': ['bar']
      },
          contents: [d.dir("lib", [d.file("foo.dart", "final message = 'Hello!';")])]);
      builder.serve("bar", "1.2.3", deps: {
        'barback': 'any'
      },
          contents: [
              d.dir(
                  "lib",
                  [d.file("transformer.dart", replaceTransformer("Hello", "Goodbye"))])]);
    });
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet(output: contains("Precompiled foo."));
    d.dir(
        appPath,
        [
            d.dir(
                ".pub/deps/debug/foo/lib",
                [d.file("foo.dart", "final message = 'Goodbye!';")])]).validate();
  });
  integration("doesn't cache an untransformed dependency", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');
      builder.serve(
          "foo",
          "1.2.3",
          contents: [d.dir("lib", [d.file("foo.dart", "final message = 'Hello!';")])]);
    });
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet(output: isNot(contains("Precompiled foo.")));
    d.dir(appPath, [d.nothing(".pub/deps")]).validate();
  });
  integration("recaches when the dependency is updated", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');
      builder.serve("foo", "1.2.3", deps: {
        'barback': 'any'
      }, pubspec: {
        'transformers': ['foo']
      },
          contents: [
              d.dir(
                  "lib",
                  [
                      d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
                      d.file("foo.dart", "final message = 'Hello!';")])]);
      builder.serve("foo", "1.2.4", deps: {
        'barback': 'any'
      }, pubspec: {
        'transformers': ['foo']
      },
          contents: [
              d.dir(
                  "lib",
                  [
                      d.file("transformer.dart", replaceTransformer("Hello", "See ya")),
                      d.file("foo.dart", "final message = 'Hello!';")])]);
    });
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet(output: contains("Precompiled foo."));
    d.dir(
        appPath,
        [
            d.dir(
                ".pub/deps/debug/foo/lib",
                [d.file("foo.dart", "final message = 'Goodbye!';")])]).validate();
    d.appDir({
      "foo": "1.2.4"
    }).create();
    pubGet(output: contains("Precompiled foo."));
    d.dir(
        appPath,
        [
            d.dir(
                ".pub/deps/debug/foo/lib",
                [d.file("foo.dart", "final message = 'See ya!';")])]).validate();
  });
  integration("recaches when a transitive dependency is updated", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');
      builder.serve("foo", "1.2.3", deps: {
        'barback': 'any',
        'bar': 'any'
      }, pubspec: {
        'transformers': ['foo']
      },
          contents: [
              d.dir(
                  "lib",
                  [
                      d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
                      d.file("foo.dart", "final message = 'Hello!';")])]);
      builder.serve("bar", "5.6.7");
    });
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet(output: contains("Precompiled foo."));
    servePackages((builder) => builder.serve("bar", "6.0.0"));
    pubUpgrade(output: contains("Precompiled foo."));
  });
  integration("doesn't recache when an unrelated dependency is updated", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');
      builder.serve("foo", "1.2.3", deps: {
        'barback': 'any'
      }, pubspec: {
        'transformers': ['foo']
      },
          contents: [
              d.dir(
                  "lib",
                  [
                      d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
                      d.file("foo.dart", "final message = 'Hello!';")])]);
      builder.serve("bar", "5.6.7");
    });
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet(output: contains("Precompiled foo."));
    servePackages((builder) => builder.serve("bar", "6.0.0"));
    pubUpgrade(output: isNot(contains("Precompiled foo.")));
  });
  integration("caches the dependency in debug mode", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');
      builder.serve("foo", "1.2.3", deps: {
        'barback': 'any'
      }, pubspec: {
        'transformers': ['foo']
      },
          contents: [
              d.dir(
                  "lib",
                  [
                      d.file("transformer.dart", MODE_TRANSFORMER),
                      d.file("foo.dart", "final mode = 'MODE';")])]);
    });
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet(output: contains("Precompiled foo."));
    d.dir(
        appPath,
        [
            d.dir(
                ".pub/deps/debug/foo/lib",
                [d.file("foo.dart", "final mode = 'debug';")])]).validate();
  });
}
String replaceTransformer(String input, String output) {
  return """
import 'dart:async';

import 'package:barback/barback.dart';

class ReplaceTransformer extends Transformer {
  ReplaceTransformer.asPlugin();

  String get allowedExtensions => '.dart';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      transform.addOutput(new Asset.fromString(
          transform.primaryInput.id,
          contents.replaceAll("$input", "$output")));
    });
  }
}
""";
}
