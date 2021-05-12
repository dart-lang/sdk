// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N use_test_throws_matchers`

import 'package:test_api/test_api.dart';

f() {
  try {
    f();
    fail('fail'); // LINT
  } catch (e) {}

  try {
    f();
  } catch (e) {}

  try {
    f();
    fail('fail'); // OK
  } catch (e) {
    expect(e, null);
  } finally {
    print('hello');
  }

  try {
    f();
    fail('fail'); // OK
  } on Exception catch (e) {
    expect(e, null);
  } catch (e) {
    expect(e, null);
  }
}
