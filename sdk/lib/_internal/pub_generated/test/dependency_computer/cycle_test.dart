// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

void main() {
  initConfig();

  integration(
      "allows a package dependency cycle that's unrelated to " "transformers",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": ["myapp/first", "myapp/second"]
      }),
          d.dir(
              'lib',
              [
                  d.file("first.dart", transformer()),
                  d.file("second.dart", transformer())])]).create();

    d.dir("foo", [d.libPubspec("foo", "1.0.0", deps: {
        "bar": {
          "path": "../bar"
        }
      })]).create();

    d.dir("bar", [d.libPubspec("bar", "1.0.0", deps: {
        "baz": {
          "path": "../baz"
        }
      })]).create();

    d.dir("baz", [d.libPubspec("baz", "1.0.0", deps: {
        "foo": {
          "path": "../foo"
        }
      })]).create();

    expectDependencies({
      'myapp/first': [],
      'myapp/second': ['myapp/first']
    });
  });

  integration(
      "disallows a package dependency cycle that may be related to " "transformers",
      () {
    // Two layers of myapp transformers are necessary here because otherwise pub
    // will figure out that the transformer doesn't import "foo" and thus
    // doesn't transitively import itself. Import loops are tested below.
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": ["myapp/first", "myapp/second"]
      }),
          d.dir(
              'lib',
              [
                  d.file("first.dart", transformer()),
                  d.file("second.dart", transformer())])]).create();

    d.dir("foo", [d.libPubspec("foo", "1.0.0", deps: {
        "bar": {
          "path": "../bar"
        }
      })]).create();

    d.dir("bar", [d.libPubspec("bar", "1.0.0", deps: {
        "myapp": {
          "path": "../myapp"
        }
      })]).create();

    expectCycleException(
        [
            "myapp is transformed by myapp/second",
            "myapp depends on foo",
            "foo depends on bar",
            "bar depends on myapp",
            "myapp is transformed by myapp/first"]);
  });

  integration("disallows a transformation dependency cycle", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": ["foo"]
      }), d.dir('lib', [d.file("myapp.dart", transformer())])]).create();

    d.dir("foo", [d.pubspec({
        "name": "foo",
        "dependencies": {
          "bar": {
            "path": "../bar"
          }
        },
        "transformers": ["bar"]
      }), d.dir('lib', [d.file("foo.dart", transformer())])]).create();

    d.dir("bar", [d.pubspec({
        "name": "bar",
        "dependencies": {
          "myapp": {
            "path": "../myapp"
          }
        },
        "transformers": ["myapp"]
      }), d.dir('lib', [d.file("bar.dart", transformer())])]).create();

    expectCycleException(
        [
            "bar is transformed by myapp",
            "myapp is transformed by foo",
            "foo is transformed by bar"]);
  });

  integration(
      "allows a cross-package import cycle that's unrelated to " "transformers",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": ["myapp"]
      }),
          d.dir(
              'lib',
              [d.file("myapp.dart", transformer(['package:foo/foo.dart']))])]).create();

    d.dir("foo", [d.libPubspec("foo", "1.0.0", deps: {
        "bar": {
          "path": "../bar"
        }
      }),
          d.dir('lib', [d.file("foo.dart", "import 'package:bar/bar.dart';")])]).create();

    d.dir("bar", [d.libPubspec("bar", "1.0.0", deps: {
        "baz": {
          "path": "../baz"
        }
      }),
          d.dir('lib', [d.file("bar.dart", "import 'package:baz/baz.dart';")])]).create();

    d.dir("baz", [d.libPubspec("baz", "1.0.0", deps: {
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir('lib', [d.file("baz.dart", "import 'package:foo/foo.dart';")])]).create();

    expectDependencies({
      'myapp': []
    });
  });

  integration(
      "disallows a cross-package import cycle that's related to " "transformers",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": ["myapp"]
      }),
          d.dir(
              'lib',
              [d.file("myapp.dart", transformer(['package:foo/foo.dart']))])]).create();

    d.dir("foo", [d.libPubspec("foo", "1.0.0", deps: {
        "bar": {
          "path": "../bar"
        }
      }),
          d.dir('lib', [d.file("foo.dart", "import 'package:bar/bar.dart';")])]).create();

    d.dir("bar", [d.libPubspec("bar", "1.0.0", deps: {
        "myapp": {
          "path": "../myapp"
        }
      }),
          d.dir(
              'lib',
              [d.file("bar.dart", "import 'package:myapp/myapp.dart';")])]).create();

    expectCycleException(
        [
            "myapp is transformed by myapp",
            "myapp depends on foo",
            "foo depends on bar",
            "bar depends on myapp"]);
  });

  integration(
      "allows a single-package import cycle that's unrelated to " "transformers",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": ["myapp"]
      }),
          d.dir(
              'lib',
              [
                  d.file("myapp.dart", transformer(['foo.dart'])),
                  d.file("foo.dart", "import 'bar.dart';"),
                  d.file("bar.dart", "import 'baz.dart';"),
                  d.file("baz.dart", "import 'foo.dart';")])]).create();

    expectDependencies({
      'myapp': []
    });
  });

  integration(
      "allows a single-package import cycle that's related to " "transformers",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": ["myapp"]
      }),
          d.dir(
              'lib',
              [
                  d.file("myapp.dart", transformer(['foo.dart'])),
                  d.file("foo.dart", "import 'bar.dart';"),
                  d.file("bar.dart", "import 'myapp.dart';"),])]).create();

    expectDependencies({
      'myapp': []
    });
  });
}
