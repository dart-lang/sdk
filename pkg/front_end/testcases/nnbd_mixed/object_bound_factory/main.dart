// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

import 'opt_in_lib.dart';

main() {
  new Class1.redirect();
  new Class1.constRedirect();
  const Class1.constRedirect();
  new Class1.fact();

  new Class2.redirect();
  new Class2.constRedirect();
  const Class2.constRedirect();
  new Class2.fact();

  new Class3.redirect();
  new Class3.constRedirect();
  const Class3.constRedirect();
  new Class3.fact();

  new Class4.redirect();
  new Class4.constRedirect();
  const Class4.constRedirect();
  new Class4.fact();

  new Class5.redirect();
  new Class5.constRedirect();
  const Class5.constRedirect();
  new Class5.fact();

  testOptIn();
}
