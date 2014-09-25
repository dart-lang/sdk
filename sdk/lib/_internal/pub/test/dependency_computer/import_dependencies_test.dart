// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

void main() {
  initConfig();

  integration("reports a dependency if a transformed local file is imported",
      () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": {"path": "../foo"}},
        "transformers": [
          {"foo": {"\$include": "lib/lib.dart"}},
          "myapp"
        ]
      }),
      d.dir("lib", [
        d.file("myapp.dart", ""),
        d.file("lib.dart", ""),
        d.file("transformer.dart", transformer(["lib.dart"]))
      ])
    ]).create();

    d.dir("foo", [
      d.pubspec({"name": "foo", "version": "1.0.0"}),
      d.dir("lib", [d.file("foo.dart", transformer())])
    ]).create();

    expectDependencies({'myapp': ['foo'], 'foo': []});
  });

  integration("reports a dependency if a transformed foreign file is imported",
      () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": {"path": "../foo"}},
        "transformers": ["myapp"]
      }),
      d.dir("lib", [
        d.file("myapp.dart", ""),
        d.file("transformer.dart", transformer(["package:foo/foo.dart"]))
      ])
    ]).create();

    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": [{"foo": {"\$include": "lib/foo.dart"}}]
      }),
      d.dir("lib", [
        d.file("foo.dart", ""),
        d.file("transformer.dart", transformer())
      ])
    ]).create();

    expectDependencies({'myapp': ['foo'], 'foo': []});
  });

  integration("reports a dependency if a transformed external package file is "
      "imported from an export", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": {"path": "../foo"}},
        "transformers": ["myapp"]
      }),
      d.dir("lib", [
        d.file("myapp.dart", ""),
        d.file("transformer.dart", transformer(["local.dart"])),
        d.file("local.dart", "export 'package:foo/foo.dart';")
      ])
    ]).create();

    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": [{"foo": {"\$include": "lib/foo.dart"}}]
      }),
      d.dir("lib", [
        d.file("foo.dart", ""),
        d.file("transformer.dart", transformer())
      ])
    ]).create();

    expectDependencies({'myapp': ['foo'], 'foo': []});
  });

  integration("reports a dependency if a transformed foreign file is "
      "transitively imported", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": {"path": "../foo"}},
        "transformers": ["myapp"]
      }),
      d.dir("lib", [
        d.file("myapp.dart", ""),
        d.file("transformer.dart", transformer(["local.dart"])),
        d.file("local.dart", "import 'package:foo/foreign.dart';")
      ])
    ]).create();

    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": [{"foo": {"\$include": "lib/foo.dart"}}]
      }),
      d.dir("lib", [
        d.file("foo.dart", ""),
        d.file("transformer.dart", transformer()),
        d.file("foreign.dart", "import 'foo.dart';")
      ])
    ]).create();

    expectDependencies({'myapp': ['foo'], 'foo': []});
  });

  integration("reports a dependency if a transformed foreign file is "
      "transitively imported across packages", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": {"path": "../foo"}},
        "transformers": ["myapp"]
      }),
      d.dir("lib", [
        d.file("myapp.dart", ""),
        d.file("transformer.dart", transformer(["package:foo/foo.dart"])),
      ])
    ]).create();

    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "dependencies": {"bar": {"path": "../bar"}}
      }),
      d.dir("lib", [d.file("foo.dart", "import 'package:bar/bar.dart';")])
    ]).create();

    d.dir("bar", [
      d.pubspec({
        "name": "bar",
        "version": "1.0.0",
        "transformers": [{"bar": {"\$include": "lib/bar.dart"}}]
      }),
      d.dir("lib", [
        d.file("bar.dart", ""),
        d.file("transformer.dart", transformer())
      ])
    ]).create();

    expectDependencies({'myapp': ['bar'], 'bar': []});
  });

  integration("reports a dependency if an imported file is transformed by a "
      "different package", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": {"path": "../foo"}},
        "transformers": [
          {"foo": {'\$include': 'lib/local.dart'}},
          "myapp"
        ]
      }),
      d.dir("lib", [
        d.file("myapp.dart", ""),
        d.file("transformer.dart", transformer(["local.dart"])),
        d.file("local.dart", "")
      ])
    ]).create();

    d.dir("foo", [
      d.pubspec({"name": "foo", "version": "1.0.0"}),
      d.dir("lib", [d.file("transformer.dart", transformer())])
    ]).create();

    expectDependencies({'myapp': ['foo'], 'foo': []});
  });
}