// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic tests for the WeakReference and Finalizer API for the web backends.
// Does not trigger garbage collection to heavily test the functionality.

import 'package:expect/minitest.dart';

class Foo {
  int close() {
    return 42; // no-op, dropped return value.
  }
}

void callback(Foo f) {
  f.close();
}

main() {
  test('weak reference', () {
    var list = ["foo"];
    var weakRef = WeakReference<List<String>>(list);
    expect(weakRef.target, equals(list));

    // Javascript API throws when the representation of target is not 'object'
    // in the compiled Javascript.
    expect(() => WeakReference<String>("foo"), throws);
    expect(() => WeakReference<int>(1), throws);
  });

  test('finalizer', () {
    var finalizer = Finalizer<Foo>(callback);
    var list = ["foo"];
    var foo = Foo();
    // Should not cause errors to attach or detach
    finalizer.attach(list, foo);
    finalizer.attach(list, foo, detach: list);
    finalizer.detach(list);

    // Should not cause errors to use a different detach token
    var detachList = [1, 2, 3];
    finalizer.attach(list, foo, detach: detachList);
    finalizer.detach(detachList);

    // JavaScript API returns false when unknown target detached.
    // Should not cause an error to detach unknown token.
    var unknownList = [2, 4, 6];
    finalizer.detach(unknownList);

    // JavaScript API throws when target and detach token are not objects.
    expect(() => finalizer.attach("token string value", foo), throws);
    expect(() => finalizer.detach("detach string value"), throws);
  });
}
