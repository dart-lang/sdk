// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


void testLocalStorage() {
  forLayoutTests();
  test('GetItem', () {
    final value = window.localStorage.getItem('does not exist');
    Expect.isNull(value);
  });
  test('SetItem', () {
    final key = 'foo';
    final value = 'bar';
    window.localStorage.setItem(key, value);
    final stored = window.localStorage.getItem(key);
    Expect.equals(value, stored);
  });
}
