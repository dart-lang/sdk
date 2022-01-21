// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:supported.by.spec';
import 'dart:unsupported.by.spec';
import 'dart:unsupported.by.target';

import 'import_default_lib.dart'
    if (dart.library.supported.by.spec) 'import_supported.by.spec_lib.dart'
    if (dart.library._supported.by.target) 'import_supported.by.target_lib.dart'
    if (dart.library.unsupported.by.target) 'import_unsupported.by.target_lib.dart'
    if (dart.library.unsupported.by.spec) 'import_unsupported.by.spec_lib.dart'
    if (dart.library._unsupported.by.spec_internal) 'import_unsupported.by.spec_internal_lib.dart'
    as from_supported_by_spec_first;

import 'import_default_lib.dart'
    if (dart.library.unsupported.by.target) 'import_unsupported.by.target_lib.dart'
    if (dart.library.unsupported.by.spec) 'import_unsupported.by.spec_lib.dart'
    if (dart.library._unsupported.by.spec_internal) 'import_unsupported.by.spec_internal_lib.dart'
    if (dart.library._supported.by.target) 'import_supported.by.target_lib.dart'
    if (dart.library.supported.by.spec) 'import_supported.by.spec_lib.dart'
    as from_supported_by_target;

import 'import_default_lib.dart'
    if (dart.library.unsupported.by.spec) 'import_unsupported.by.spec_lib.dart'
    if (dart.library.unsupported.by.target) 'import_unsupported.by.target_lib.dart'
    if (dart.library._unsupported.by.spec_internal) 'import_unsupported.by.spec_internal_lib.dart'
    if (dart.library.supported.by.spec) 'import_supported.by.spec_lib.dart'
    if (dart.library._supported.by.target) 'import_supported.by.target_lib.dart'
    as from_supported_by_spec_last;

main() {
  supportedBySpec();
  supportedByTarget(); // Exported through dart:supported.by.spec
  unsupportedBySpec();
  unsupportedByTarget();
  unsupportedBySpecInternal(); // Exported through dart:unsupported.by.spec

  expect('supported.by.spec', from_supported_by_spec_first.field);
  expect('supported.by.target', from_supported_by_target.field);
  expect('supported.by.spec', from_supported_by_spec_last.field);

  // `dart:supported.by.spec` is supported by the libraries specification.
  expect(true, const bool.fromEnvironment('dart.library.supported.by.spec'));
  // `dart:_supported.by.target` is internal and therefore not supported by
  // the libraries specification, but the test target supports it explicitly.
  expect(true, const bool.fromEnvironment('dart.library._supported.by.target'));
  // `dart:unsupported.by.spec` is unsupported by the libraries specification.
  expect(false, const bool.fromEnvironment('dart.library.unsupported.by.spec'));
  // `dart:unsupported.by.target` is unsupported by the libraries specification,
  // but the test target explicitly marks it as unsupported.
  expect(
      false, const bool.fromEnvironment('dart.library.unsupported.by.target'));
  // `dart:_unsupported.by.spec_internal` is internal and therefore not
  // supported by the libraries specification.
  expect(false,
      const bool.fromEnvironment('dart.library._unsupported.by.spec_internal'));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
