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

  integration("reports no dependencies if no transformers are used", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        }
      })]).create();

    d.dir("foo", [d.libPubspec("foo", "1.0.0")]).create();

    expectDependencies({});
  });

  integration(
      "reports no dependencies if a transformer is used in a "
          "package that doesn't expose a transformer",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": ["foo"]
      })]).create();

    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("lib", [d.file("foo.dart", transformer())])]).create();

    expectDependencies({
      "foo": []
    });
  });

  integration("reports no dependencies for non-file/package imports", () {
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
              "lib",
              [
                  d.file(
                      "myapp.dart",
                      transformer(
                          ["dart:async", "http://dartlang.org/nonexistent.dart"]))])]).create();

    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("lib", [d.file("foo.dart", transformer())])]).create();

    expectDependencies({
      "myapp": []
    });
  });

  integration("reports no dependencies for a single self transformer", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": ["myapp"]
      }), d.dir("lib", [d.file("myapp.dart", transformer())])]).create();

    expectDependencies({
      "myapp": []
    });
  });

  integration(
      "reports no dependencies if a transformer applies to files that "
          "aren't used by the exposed transformer",
      () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "path": "../foo"
          }
        },
        "transformers": [{
            "foo": {
              "\$include": "lib/myapp.dart"
            }
          }, {
            "foo": {
              "\$exclude": "lib/transformer.dart"
            }
          }, "myapp"]
      }),
          d.dir(
              "lib",
              [
                  d.file("myapp.dart", ""),
                  d.file("transformer.dart", transformer())])]).create();

    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("lib", [d.file("foo.dart", transformer())])]).create();

    expectDependencies({
      "myapp": [],
      "foo": []
    });
  });

  integration(
      "reports no dependencies if a transformer applies to a "
          "dependency's files that aren't used by the exposed transformer",
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
              "lib",
              [
                  d.file("myapp.dart", ""),
                  d.file("transformer.dart", transformer(["package:foo/foo.dart"]))])]).create();

    d.dir("foo", [d.pubspec({
        "name": "foo",
        "version": "1.0.0",
        "transformers": [{
            "foo": {
              "\$exclude": "lib/foo.dart"
            }
          }]
      }),
          d.dir(
              "lib",
              [d.file("foo.dart", ""), d.file("transformer.dart", transformer())])]).create();

    expectDependencies({
      'myapp': [],
      'foo': []
    });
  });

  test("reports no dependencies on transformers in future phases", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": [{
            "myapp/first": {
              "\$include": "lib/myapp.dart"
            }
          }, {
            "myapp/second": {
              "\$include": "lib/first.dart"
            }
          }, {
            "myapp/third": {
              "\$include": "lib/second.dart"
            }
          }]
      }),
          d.dir(
              "lib",
              [
                  d.file("myapp.dart", ""),
                  d.file("first.dart", transformer()),
                  d.file("second.dart", transformer()),
                  d.file("third.dart", transformer())])]).create();

    expectDependencies({
      'myapp/first': [],
      'myapp/second': [],
      'myapp/third': []
    });
  });
}
