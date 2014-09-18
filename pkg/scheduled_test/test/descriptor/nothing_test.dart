// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import 'utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

  expectTestsPass("nothing().create() does nothing", () {
    test('test', () {
      scheduleSandbox();

      d.nothing('foo').create();

      schedule(() {
        expect(new File(path.join(sandbox, 'foo')).exists(),
            completion(isFalse));
      });

      schedule(() {
        expect(new Directory(path.join(sandbox, 'foo')).exists(),
            completion(isFalse));
      });
    });
  });

  expectTestsPass("nothing().validate() succeeds if nothing's there", () {
    test('test', () {
      scheduleSandbox();

      d.nothing('foo').validate();
    });
  });

  expectTestFails("nothing().validate() fails if there's a file", () {
    scheduleSandbox();
    d.file('name.txt', 'contents').create();
    d.nothing('name.txt').validate();
  }, (errors) {
    expect(errors.single, new isInstanceOf<ScheduleError>());
    expect(errors.single.error.toString(),
        matches(r"^Expected nothing to exist at '[^']+[\\/]name.txt', but "
                r"found a file\.$"));
  });

  expectTestFails("nothing().validate() fails if there's a directory", () {
    scheduleSandbox();
    d.dir('dir').create();
    d.nothing('dir').validate();
  }, (errors) {
    expect(errors.single, new isInstanceOf<ScheduleError>());
    expect(errors.single.error.toString(),
        matches(r"^Expected nothing to exist at '[^']+[\\/]dir', but found a "
            r"directory\.$"));
  });

  expectTestFails("nothing().validate() fails if there's a broken link", () {
    scheduleSandbox();
    schedule(() {
      new Link(path.join(sandbox, 'link')).createSync('nonexistent');
    });
    d.nothing('link').validate();
  }, (errors) {
    expect(errors.single, new isInstanceOf<ScheduleError>());
    expect(errors.single.error.toString(),
        matches(r"^Expected nothing to exist at '[^']+[\\/]link', but found "
            r"a link\.$"));
  });
}
