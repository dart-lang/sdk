// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic tests for the dart2js-only polyfill for WeakReference and Finalizer API
// for the dart2js backends.

import 'package:expect/minitest.dart';

import 'dart:js_interop_unsafe';
import 'dart:js_interop';

class Foo {
  int close() {
    return 42; // no-op, dropped return value.
  }
}

void callback(Foo f) {
  f.close();
}

main() {
  // Remove global bindings to simulate a JavaScript environment before these
  // bindings were added.
  globalContext.delete('WeakRef'.toJS);
  globalContext.delete('FinalizationRegistry'.toJS);

  test('weak reference', () {
    var list = ["foo"];
    var weakRef = WeakReference<List<String>>(list);
    expect(weakRef.target, equals(list));

    // JavaScript API throws when the representation of target is not 'object'
    // in the compiled JavaScript. The polyfill does not check argument
    // types. This verifies that the polyfill is being used.
    WeakReference<String>("foo");
    WeakReference<int>(1);
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

    // JavaScript API throws when target and detach token are not objects.  The
    // polyfill does not check argument types. This verifies the polyfill is
    // being used.
    finalizer.attach("token string value", foo);
    finalizer.detach("detach string value");
  });
}
