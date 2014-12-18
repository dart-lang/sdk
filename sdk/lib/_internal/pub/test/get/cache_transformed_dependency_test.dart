// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

const HAS_INPUT_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class HasInputTransformer extends Transformer {
  HasInputTransformer.asPlugin();

  bool get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    return Future.wait([
      transform.hasInput(new AssetId("foo", "lib/foo.dart")),
      transform.hasInput(new AssetId("foo", "lib/does/not/exist.dart"))
    ]).then((results) {
      transform.addOutput(new Asset.fromString(
          transform.primaryInput.id,
          "lib/foo.dart: \${results.first}, "
              "lib/does/not/exist.dart: \${results.last}"));
    });
  }
}
""";

main() {
  initConfig();

  integration("caches a transformed dependency", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);
    });

    d.appDir({"foo": "1.2.3"}).create();

    pubGet(output: contains("Precompiled foo."));

    d.dir(appPath, [
      d.dir(".pub/deps/debug/foo/lib", [
        d.file("foo.dart", "final message = 'Goodbye!';")
      ])
    ]).validate();
  });

  integration("caches a dependency transformed by its dependency", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'bar': '1.2.3'},
          pubspec: {'transformers': ['bar']},
          contents: [
        d.dir("lib", [
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);

      builder.serve("bar", "1.2.3",
          deps: {'barback': 'any'},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye"))
        ])
      ]);
    });

    d.appDir({"foo": "1.2.3"}).create();

    pubGet(output: contains("Precompiled foo."));

    d.dir(appPath, [
      d.dir(".pub/deps/debug/foo/lib", [
        d.file("foo.dart", "final message = 'Goodbye!';")
      ])
    ]).validate();
  });

  integration("doesn't cache an untransformed dependency", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          contents: [
        d.dir("lib", [
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);
    });

    d.appDir({"foo": "1.2.3"}).create();

    pubGet(output: isNot(contains("Precompiled foo.")));

    d.dir(appPath, [d.nothing(".pub/deps")]).validate();
  });

  integration("recaches when the dependency is updated", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);

      builder.serve("foo", "1.2.4",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "See ya")),
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);
    });

    d.appDir({"foo": "1.2.3"}).create();

    pubGet(output: contains("Precompiled foo."));

    d.dir(appPath, [
      d.dir(".pub/deps/debug/foo/lib", [
        d.file("foo.dart", "final message = 'Goodbye!';")
      ])
    ]).validate();

    // Upgrade to the new version of foo.
    d.appDir({"foo": "1.2.4"}).create();

    pubGet(output: contains("Precompiled foo."));

    d.dir(appPath, [
      d.dir(".pub/deps/debug/foo/lib", [
        d.file("foo.dart", "final message = 'See ya!';")
      ])
    ]).validate();
  });

  integration("recaches when a transitive dependency is updated", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {
            'barback': 'any',
            'bar': 'any'
          },
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);

      builder.serve("bar", "5.6.7");
    });

    d.appDir({"foo": "1.2.3"}).create();
    pubGet(output: contains("Precompiled foo."));

    servePackages((builder) => builder.serve("bar", "6.0.0"));
    pubUpgrade(output: contains("Precompiled foo."));
  });

  integration("doesn't recache when an unrelated dependency is updated", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);

      builder.serve("bar", "5.6.7");
    });

    d.appDir({"foo": "1.2.3"}).create();
    pubGet(output: contains("Precompiled foo."));

    servePackages((builder) => builder.serve("bar", "6.0.0"));
    pubUpgrade(output: isNot(contains("Precompiled foo.")));
  });

  integration("caches the dependency in debug mode", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", MODE_TRANSFORMER),
          d.file("foo.dart", "final mode = 'MODE';")
        ])
      ]);
    });

    d.appDir({"foo": "1.2.3"}).create();

    pubGet(output: contains("Precompiled foo."));

    d.dir(appPath, [
      d.dir(".pub/deps/debug/foo/lib", [
        d.file("foo.dart", "final mode = 'debug';")
      ])
    ]).validate();
  });

  integration("loads code from the cache", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);
    });

    d.dir(appPath, [
      d.appPubspec({"foo": "1.2.3"}),
      d.dir('bin', [
        d.file('script.dart', """
          import 'package:foo/foo.dart';

          void main() => print(message);""")
      ])
    ]).create();

    pubGet(output: contains("Precompiled foo."));

    d.dir(appPath, [
      d.dir(".pub/deps/debug/foo/lib", [
        d.file("foo.dart", "final message = 'Modified!';")
      ])
    ]).create();

    var pub = pubRun(args: ["script"]);
    pub.stdout.expect("Modified!");
    pub.shouldExit();
  });

  integration("doesn't re-transform code loaded from the cache", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);
    });

    d.dir(appPath, [
      d.appPubspec({"foo": "1.2.3"}),
      d.dir('bin', [
        d.file('script.dart', """
          import 'package:foo/foo.dart';

          void main() => print(message);""")
      ])
    ]).create();

    pubGet(output: contains("Precompiled foo."));

    // Manually reset the cache to its original state to prove that the
    // transformer won't be run again on it.
    d.dir(appPath, [
      d.dir(".pub/deps/debug/foo/lib", [
        d.file("foo.dart", "final message = 'Hello!';")
      ])
    ]).create();

    var pub = pubRun(args: ["script"]);
    pub.stdout.expect("Hello!");
    pub.shouldExit();
  });

  // Regression test for issue 21087.
  integration("hasInput works for static packages", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
          d.file("foo.dart", "void main() => print('Hello!');")
        ])
      ]);
    });

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": "1.2.3"},
        "transformers": ["myapp/src/transformer"]
      }),
      d.dir("lib", [d.dir("src", [
        d.file("transformer.dart", HAS_INPUT_TRANSFORMER)
      ])]),
      d.dir("web", [
        d.file("foo.txt", "foo")
      ])
    ]).create();

    pubGet(output: contains("Precompiled foo."));

    pubServe();
    requestShouldSucceed("foo.txt",
        "lib/foo.dart: true, lib/does/not/exist.dart: false");
    endPubServe();
  });

  // Regression test for issue 21810.
  integration("decaches when the dependency is updated to something "
      "untransformed", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          deps: {'barback': 'any'},
          pubspec: {'transformers': ['foo']},
          contents: [
        d.dir("lib", [
          d.file("transformer.dart", replaceTransformer("Hello", "Goodbye")),
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);

      builder.serve("foo", "1.2.4",
          deps: {'barback': 'any'},
          contents: [
        d.dir("lib", [
          d.file("foo.dart", "final message = 'Hello!';")
        ])
      ]);
    });

    d.appDir({"foo": "1.2.3"}).create();

    pubGet(output: contains("Precompiled foo."));

    d.dir(appPath, [
      d.dir(".pub/deps/debug/foo/lib", [
        d.file("foo.dart", "final message = 'Goodbye!';")
      ])
    ]).validate();

    // Upgrade to the new version of foo.
    d.appDir({"foo": "1.2.4"}).create();

    pubGet(output: isNot(contains("Precompiled foo.")));

    d.dir(appPath, [
      d.nothing(".pub/deps/debug/foo")
    ]).validate();
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
