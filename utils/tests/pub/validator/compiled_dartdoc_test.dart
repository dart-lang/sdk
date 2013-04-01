// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../../pub/entrypoint.dart';
import '../../../pub/validator.dart';
import '../../../pub/validator/compiled_dartdoc.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator compiledDartdoc(Entrypoint entrypoint) =>
  new CompiledDartdocValidator(entrypoint);

main() {
  initConfig();

  group('should consider a package valid if it', () {
    setUp(d.validPackage.create);

    integration('looks normal', () => expectNoValidationError(compiledDartdoc));

    integration('has most but not all files from compiling dartdoc', () {
      d.dir(appPath, [
        d.dir("doc-out", [
          d.file("nav.json", ""),
          d.file("index.html", ""),
          d.file("styles.css", ""),
          d.file("dart-logo-small.png", "")
        ])
      ]).create();
      expectNoValidationError(compiledDartdoc);
    });
  });

  integration('should consider a package invalid if it contains compiled '
      'dartdoc', () {
    d.validPackage.create();

    d.dir(appPath, [
      d.dir('doc-out', [
        d.file('nav.json', ''),
        d.file('index.html', ''),
        d.file('styles.css', ''),
        d.file('dart-logo-small.png', ''),
        d.file('client-live-nav.js', '')
      ])
    ]).create();

    expectValidationWarning(compiledDartdoc);
  });
}
