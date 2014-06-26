// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

void main() {
  initConfig();

  integration("reports previous transformers as dependencies if the "
      "transformer is transformed", () {
    // The root app just exists so that something is transformed by pkg and qux.
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "version": "1.0.0",
        "dependencies": {
          "pkg": {"path": "../pkg"},
          "qux": {"path": "../qux"}
        },
        "transformers": ["pkg", "qux"]
      })
    ]).create();

    d.dir("pkg", [
      d.pubspec({
        "name": "pkg",
        "version": "1.0.0",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"},
          "baz": {"path": "../baz"},
        },
        "transformers": [
          {"foo": {"\$include": "lib/pkg.dart"}},
          {"bar": {"\$exclude": "lib/transformer.dart"}},
          "baz"
        ]
      }),
      d.dir("lib", [
        d.file("pkg.dart", ""),
        d.file("transformer.dart", transformer())
      ])
    ]).create();

    // Even though foo and bar don't modify pkg/lib/transformer.dart themselves,
    // it may be modified to import a library that they modify or generate, so
    // pkg will depend on them.
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0"),
      d.dir("lib", [d.file("foo.dart", transformer())])
    ]).create();

    d.dir("bar", [
      d.libPubspec("bar", "1.0.0"),
      d.dir("lib", [d.file("bar.dart", transformer())])
    ]).create();

    // baz transforms pkg/lib/transformer.dart, so pkg will obviously
    // depend on it.
    d.dir("baz", [
      d.libPubspec("baz", "1.0.0"),
      d.dir("lib", [d.file("baz.dart", transformer())])
    ]).create();

    // qux doesn't transform anything in pkg, so pkg won't depend on it.
    d.dir("qux", [
      d.libPubspec("qux", "1.0.0"),
      d.dir("lib", [d.file("qux.dart", transformer())])
    ]).create();

    expectDependencies({
      'pkg': ['foo', 'bar', 'baz'], 'foo': [], 'bar': [], 'baz': [], 'qux': []
    });
  });

  integration("reports all transitive package dependencies' transformers as "
      "dependencies if the transformer is transformed", () {
    // The root app just exists so that something is transformed by pkg and qux.
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "pkg": {"path": "../pkg"},
          "qux": {"path": "../qux"}
        },
        "transformers": ["pkg"]
      })
    ]).create();

    d.dir("pkg", [
      d.pubspec({
        "name": "pkg",
        "version": "1.0.0",
        "dependencies": {
          "foo": {"path": "../foo"},
          "baz": {"path": "../baz"}
        },
        "transformers": ["baz"]
      }),
      d.dir("lib", [d.file("pkg.dart", transformer())])
    ]).create();

    // pkg depends on foo. Even though it's not transformed by foo, its
    // transformed transformer could import foo, so it has to depend on foo.
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "dependencies": {"bar": {"path": "../bar"}},
        "transformers": ["foo"]
      }),
      d.dir("lib", [d.file("foo.dart", transformer())])
    ]).create();

    // foo depends on bar, and like pkg's dependency on foo, the transformed
    // version of foo's transformer could import bar, so foo has to depend on
    // bar.
    d.dir("bar", [
      d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["bar"]
      }),
      d.dir("lib", [d.file("bar.dart", transformer())])
    ]).create();

    /// foo is transformed by baz.
    d.dir("baz", [
      d.libPubspec("baz", "1.0.0"),
      d.dir("lib", [d.file("baz.dart", transformer())])
    ]).create();

    /// qux is not part of pkg's transitive dependency tree, so pkg shouldn't
    /// depend on it.
    d.dir("qux", [
      d.pubspec({
        "name": "qux",
        "version": "1.0.0",
        "transformers": ["qux"]
      }),
      d.dir("lib", [d.file("qux.dart", transformer())])
    ]).create();

    expectDependencies({
      'pkg': ['foo', 'bar', 'baz'], 'foo': [], 'bar': [], 'baz': [], 'qux': []
    });
  });

  integration("reports previous transformers as dependencies if a "
      "nonexistent local file is imported", () {
    // The root app just exists so that something is transformed by pkg and bar.
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "pkg": {"path": "../pkg"},
          "bar": {"path": "../bar"}
        },
        "transformers": ["pkg", "bar"]
      })
    ]).create();

    d.dir("pkg", [
      d.pubspec({
        "name": "pkg",
        "version": "1.0.0",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"}
        },
        "transformers": [{"foo": {"\$include": "lib/pkg.dart"}}]
      }),
      d.dir("lib", [
        d.file("pkg.dart", ""),
        d.file("transformer.dart", transformer(["nonexistent.dart"]))
      ])
    ]).create();

    // Since pkg's transformer imports a nonexistent file, we assume that file
    // was generated by foo's transformer. Thus pkg's transformer depends on
    // foo's even though the latter doesn't transform the former.
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0"),
      d.dir("lib", [d.file("foo.dart", transformer())])
    ]).create();

    /// qux is not part of pkg's transitive dependency tree, so pkg shouldn't
    /// depend on it.
    d.dir("bar", [
      d.libPubspec("bar", "1.0.0"),
      d.dir("lib", [d.file("bar.dart", transformer())])
    ]).create();

    expectDependencies({'pkg': ['foo'], 'foo': [], 'bar': []});
  });

  integration("reports all that package's dependencies' transformers as "
      "dependencies if a non-existent file is imported from another package",
      () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "qux": {"path": "../qux"}
        },
        "transformers": ["myapp"]
      }),
      d.dir("lib", [
        d.file("myapp.dart", transformer(["package:foo/nonexistent.dart"]))
      ])
    ]).create();

    // myapp imported a nonexistent file from foo so myapp will depend on every
    // transformer transitively reachable from foo, since the nonexistent file
    // could be generated to import anything.
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "dependencies": {
          "bar": {"path": "../bar"},
          "baz": {"path": "../baz"}
        },
        "transformers": ["foo"]
      }),
      d.dir("lib", [d.file("foo.dart", transformer())])
    ]).create();

    // bar is a dependency of foo so myapp will depend on it.
    d.dir("bar", [
      d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["bar"]
      }),
      d.dir("lib", [d.file("bar.dart", transformer())])
    ]).create();

    // baz is a dependency of foo so myapp will depend on it.
    d.dir("baz", [
      d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["baz"]
      }),
      d.dir("lib", [d.file("baz.dart", transformer())])
    ]).create();

    // qux is not transitively reachable from foo so myapp won't depend on it.
    d.dir("qux", [
      d.pubspec({
        "name": "qux",
        "version": "1.0.0",
        "transformers": ["qux"]
      }),
      d.dir("lib", [d.file("qux.dart", transformer())])
    ]).create();

    expectDependencies({
      'myapp': ['foo', 'bar', 'baz'], 'foo': [], 'bar': [], 'baz': [], 'qux': []
    });
  });

  integration("reports all that package's dependencies' transformers as "
      "dependencies if a non-existent transformer is used from another package",
      () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "qux": {"path": "../qux"}
        },
        "transformers": ["myapp"]
      }),
      d.dir("lib", [
        d.file("myapp.dart", transformer(["package:foo/nonexistent.dart"]))
      ])
    ]).create();

    // myapp imported a nonexistent file from foo so myapp will depend on every
    // transformer transitively reachable from foo, since the nonexistent file
    // could be generated to import anything.
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "dependencies": {
          "bar": {"path": "../bar"},
          "baz": {"path": "../baz"}
        },
        "transformers": ["bar"]
      })
    ]).create();

    // bar is a dependency of foo so myapp will depend on it.
    d.dir("bar", [
      d.libPubspec("bar", "1.0.0"),
      d.dir("lib", [d.file("bar.dart", transformer())])
    ]).create();

    // baz is a dependency of foo so myapp will depend on it.
    d.dir("baz", [
      d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["baz"]
      }),
      d.dir("lib", [d.file("baz.dart", transformer())])
    ]).create();

    // qux is not transitively reachable from foo so myapp won't depend on it.
    d.dir("qux", [
      d.pubspec({
        "name": "qux",
        "version": "1.0.0",
        "transformers": ["qux"]
      }),
      d.dir("lib", [d.file("qux.dart", transformer())])
    ]).create();

    expectDependencies({
      'myapp': ['bar', 'baz'], 'bar': [], 'baz': [], 'qux': []
    });
  });

  test("reports dependencies on transformers in past phases", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": [
          "myapp/first",
          "myapp/second",
          "myapp/third"
        ]
      }),
      d.dir("lib", [
        d.file("first.dart", transformer()),
        d.file("second.dart", transformer()),
        d.file("third.dart", transformer())
      ])
    ]).create();

    expectDependencies({
      'myapp/first': [],
      'myapp/second': ['myapp/first'],
      'myapp/third': ['myapp/second', 'myapp/first']
    });
  });

  integration("considers the entrypoint package's dev and override "
      "dependencies", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": {"path": "../foo"}},
        "dev_dependencies": {"bar": {"path": "../bar"}},
        "dependency_overrides": {"baz": {"path": "../baz"}},
        "transformers": ["foo", "myapp"]
      }),
      d.dir("lib", [d.file("myapp.dart", transformer())])
    ]).create();

    // foo transforms myapp's transformer so it could import from bar or baz.
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": ["foo"]
      }),
      d.dir("lib", [d.file("foo.dart", transformer())])
    ]).create();

    // bar is a dev dependency that myapp could import from, so myapp should
    // depend on it.
    d.dir("bar", [
      d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["bar"]
      }),
      d.dir("lib", [d.file("bar.dart", transformer())])
    ]).create();

    // baz is an override dependency that myapp could import from, so myapp
    // should depend on it.
    d.dir("baz", [
      d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["baz"]
      }),
      d.dir("lib", [d.file("baz.dart", transformer())])
    ]).create();

    expectDependencies({
      'myapp': ['foo', 'bar', 'baz'], 'foo': [], 'bar': [], 'baz': []
    });
  });

  integration("doesn't consider a non-entrypoint package's dev and override "
      "dependencies", () {
    // myapp just exists so that pkg isn't the entrypoint.
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"pkg": {"path": "../pkg"}}
      })
    ]).create();

    d.dir("pkg", [
      d.pubspec({
        "name": "pkg",
        "dependencies": {"foo": {"path": "../foo"}},
        "dev_dependencies": {"bar": {"path": "../bar"}},
        "dependency_overrides": {"baz": {"path": "../baz"}},
        "transformers": ["foo", "pkg"]
      }),
      d.dir("lib", [d.file("pkg.dart", transformer())])
    ]).create();

    // foo transforms pkg's transformer so it could theoretcially import from
    // bar or baz. However, since pkg isn't the entrypoint, it doesn't have
    // access to them.
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": ["foo"]
      }),
      d.dir("lib", [d.file("foo.dart", transformer())])
    ]).create();

    // bar is a dev dependency that myapp can't import from, so myapp shouldn't
    // depend on it.
    d.dir("bar", [
      d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": ["bar"]
      }),
      d.dir("lib", [d.file("bar.dart", transformer())])
    ]).create();

    // baz is a dev dependency that myapp can't import from, so myapp shouldn't
    // depend on it.
    d.dir("baz", [
      d.pubspec({
        "name": "baz",
        "version": "1.0.0",
        "transformers": ["baz"]
      }),
      d.dir("lib", [d.file("baz.dart", transformer())])
    ]).create();

    expectDependencies({'pkg': ['foo'], 'foo': [], 'bar': [], 'baz': []});
  });
}