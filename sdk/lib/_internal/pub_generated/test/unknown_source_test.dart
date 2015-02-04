// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

library pub_tests;

import 'dart:convert';

import 'descriptor.dart' as d;
import 'test_pub.dart';

main() {
  initConfig();

  forBothPubGetAndUpgrade((command) {
    integration('fails gracefully on a dependency from an unknown source', () {
      d.appDir({
        "foo": {
          "bad": "foo"
        }
      }).create();

      pubCommand(
          command,
          error: 'Package myapp depends on foo from unknown source "bad".');
    });

    integration(
        'fails gracefully on transitive dependency from an unknown ' 'source',
        () {
      d.dir(
          'foo',
          [d.libDir('foo', 'foo 0.0.1'), d.libPubspec('foo', '0.0.1', deps: {
          "bar": {
            "bad": "bar"
          }
        })]).create();

      d.appDir({
        "foo": {
          "path": "../foo"
        }
      }).create();

      pubCommand(
          command,
          error: 'Package foo depends on bar from unknown source "bad".');
    });

    integration('ignores unknown source in lockfile', () {
      d.dir('foo', [d.libDir('foo'), d.libPubspec('foo', '0.0.1')]).create();

      // Depend on "foo" from a valid source.
      d.dir(appPath, [d.appPubspec({
          "foo": {
            "path": "../foo"
          }
        })]).create();

      // But lock it to a bad one.
      d.dir(appPath, [d.file("pubspec.lock", JSON.encode({
          'packages': {
            'foo': {
              'version': '0.0.0',
              'source': 'bad',
              'description': {
                'name': 'foo'
              }
            }
          }
        }))]).create();

      pubCommand(command);

      // Should upgrade to the new one.
      d.dir(
          packagesPath,
          [d.dir("foo", [d.file("foo.dart", 'main() => "foo";')])]).validate();
    });
  });
}
