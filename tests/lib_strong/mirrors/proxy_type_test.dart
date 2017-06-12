// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.proxy_type;

import 'dart:mirrors';
import 'package:expect/expect.dart';

// This test is much longer that is strictly necessary to test
// InstanceMirror.type in the face of a reflectee overriding runtimeType, but
// shows a case where one might have legimate reason to override runtimeType.
// See section 2.2 in Mark Miller's Robust Composition: Towards a Unfied
// Approach to Access Control and Concurrency Control.

class Alice {
  Bob bob = new Bob();
  Carol carol = new Carol();
  sayFooUnattenuated() {
    bob.foo(carol);
  }

  sayFooAttenuated() {
    bool enabled = true;
    bool gate() => enabled;
    bob.foo(new CarolCaretaker(carol, gate));
    enabled = false; // Attenuate a capability
  }

  sayBar() {
    bob.bar();
  }
}

class Bob {
  Carol savedCarol;
  foo(Carol carol) {
    savedCarol = carol; // Store a capability
    carol.foo();
  }

  bar() {
    savedCarol.foo();
  }
}

class Carol {
  foo() => 'c';
}

typedef bool Gate();

class CarolCaretaker implements Carol {
  final Carol _carol;
  final Gate _gate;
  CarolCaretaker(this._carol, this._gate);

  foo() {
    if (!_gate()) throw new NoSuchMethodError(this, #foo, [], {});
    return _carol.foo();
  }

  Type get runtimeType => Carol;
}

main() {
  Alice alice1 = new Alice();
  alice1.sayFooUnattenuated();
  alice1.sayBar(); // Bob still has authority to use Carol

  Alice alice2 = new Alice();
  alice2.sayFooAttenuated();
  Expect.throws(() => alice2.sayBar(), (e) => e is NoSuchMethodError,
      'Authority should have been attenuated');

  // At the base level, a caretaker for a Carol masquerades as a Carol.
  CarolCaretaker caretaker = new CarolCaretaker(new Carol(), () => true);
  Expect.isTrue(caretaker is Carol);
  Expect.equals(Carol, caretaker.runtimeType);

  // At the reflective level, the caretaker is distinguishable.
  Expect.equals(reflectClass(CarolCaretaker), reflect(caretaker).type);
}
