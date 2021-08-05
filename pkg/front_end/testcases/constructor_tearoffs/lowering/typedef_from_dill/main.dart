// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

typedef H<X, Y> = A<Y>;

// TODO(johnniwinther): Use 'var' here when dependency on inferred parameter
// types is handled.
dynamic H_new = H.new;
dynamic H_named = H.named;
dynamic H_fact = H.fact;
dynamic H_redirect = H.redirect;

dynamic F_new = F.new;
dynamic F_named = F.named;
dynamic F_fact = F.fact;
dynamic F_redirect = F.redirect;

main() {
  expect(true, identical(F_new, F_new_lib));
  expect(false, identical(F_new, F_named_lib));
  expect(false, identical(F_new, F_fact_lib));
  expect(false, identical(F_new, F_redirect_lib));
  expect(false, identical(F_new, G_new_lib));
  expect(false, identical(F_new, G_named_lib));
  expect(false, identical(F_new, G_fact_lib));
  expect(false, identical(F_new, G_redirect_lib));
  expect(false, identical(F_new, H_new));
  expect(false, identical(F_new, H_named));
  expect(false, identical(F_new, H_fact));
  expect(false, identical(F_new, H_redirect));

  expect(false, identical(F_named, F_new_lib));
  expect(true, identical(F_named, F_named_lib));
  expect(false, identical(F_named, F_fact_lib));
  expect(false, identical(F_named, F_redirect_lib));
  expect(false, identical(F_named, G_new_lib));
  expect(false, identical(F_named, G_named_lib));
  expect(false, identical(F_named, G_fact_lib));
  expect(false, identical(F_named, G_redirect_lib));
  expect(false, identical(F_named, H_new));
  expect(false, identical(F_named, H_named));
  expect(false, identical(F_named, H_fact));
  expect(false, identical(F_named, H_redirect));

  expect(false, identical(F_fact, F_new_lib));
  expect(false, identical(F_fact, F_named_lib));
  expect(true, identical(F_fact, F_fact_lib));
  expect(false, identical(F_fact, F_redirect_lib));
  expect(false, identical(F_fact, G_new_lib));
  expect(false, identical(F_fact, G_named_lib));
  expect(false, identical(F_fact, G_fact_lib));
  expect(false, identical(F_fact, G_redirect_lib));
  expect(false, identical(F_fact, H_new));
  expect(false, identical(F_fact, H_named));
  expect(false, identical(F_fact, H_fact));
  expect(false, identical(F_fact, H_redirect));

  expect(false, identical(F_redirect, F_new_lib));
  expect(false, identical(F_redirect, F_named_lib));
  expect(false, identical(F_redirect, F_fact_lib));
  expect(true, identical(F_redirect, F_redirect_lib));
  expect(false, identical(F_redirect, G_new_lib));
  expect(false, identical(F_redirect, G_named_lib));
  expect(false, identical(F_redirect, G_fact_lib));
  expect(false, identical(F_redirect, G_redirect_lib));
  expect(false, identical(F_redirect, H_new));
  expect(false, identical(F_redirect, H_named));
  expect(false, identical(F_redirect, H_fact));
  expect(false, identical(F_redirect, H_redirect));
}


expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
