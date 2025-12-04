// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test where the constructor parameter is in scope and whether it has its
/// public or private name.

// SharedOptions=--enable-experiment=private-named-parameters

import 'package:expect/expect.dart';

String _foo = 'top-level private';
String foo = 'top-level public';

class C {
  String _foo;
  String privateInInitializer;
  String publicInInitializer;
  String? privateInBody;
  String? publicInBody;

  String Function() capturePrivateInInitializer;
  String Function() capturePublicInInitializer;
  String Function()? capturePrivateInBody;
  String Function()? capturePublicInBody;

  C({required this._foo})
    : privateInInitializer = _foo,
      publicInInitializer = foo,
      capturePrivateInInitializer = (() => _foo),
      capturePublicInInitializer = (() => foo) {
    capturePrivateInBody = () => _foo;
    capturePublicInBody = () => foo;
    this._foo = 'assigned';
    privateInBody = _foo;
    publicInBody = foo;
  }
}

void main() {
  var c = C(foo: 'parameter');
  Expect.equals(c._foo, 'assigned');

  // The private name is in scope in the initializer list.
  Expect.equals(c.privateInInitializer, 'parameter');

  // The public name is not in scope in the initializer list, so we find the
  // outer one instead.
  Expect.equals(c.publicInInitializer, 'top-level public');

  // Inside the body, the parameter is not in scope and the private name refers
  // to the instance field.
  Expect.equals(c.privateInBody, 'assigned');

  // The public name is not in scope in the body, so we find the outer one
  // instead.
  Expect.equals(c.publicInBody, 'top-level public');

  // The initializer list captures the parameter (with private name) so doesn't
  // see the mutation of the instance field.
  Expect.equals(c.capturePrivateInInitializer(), 'parameter');

  // The public name is not in scope in the initializer list, so we capture the
  // outer one instead.
  Expect.equals(c.capturePublicInInitializer(), 'top-level public');

  // The body captures the instance field (with private name).
  Expect.equals(c.capturePrivateInBody!(), 'assigned');

  // The public name is not in scope in the body, so we capture the outer one
  // instead.
  Expect.equals(c.capturePublicInBody!(), 'top-level public');
}
