// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/utilities/scoped_set.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ScopedSetTest);
  });
}

@reflectiveTest
class ScopedSetTest {
  test_clearEachScope() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.add(0);
    set.pushScope(copyCurrent: true);
    set.clearEachScope();
    expect(set.isInScope(0), false);
    set.popScope();
    expect(set.isInScope(0), false);
  }

  test_doScoped_actionPerformed() {
    final set = ScopedSet<int>();
    bool ran = false;
    set.doScoped(action: () {
      ran = true;
    });
    expect(ran, true);
  }

  test_doScoped_actionThrows() {
    final set = ScopedSet<int>();
    bool threw;
    try {
      set.doScoped(action: () {
        set.add(0);
        throw '';
      });
    } catch (_) {
      threw = true;
    }

    expect(threw, true);
    expect(set.isInScope(0), false);
  }

  test_doScoped_copyCurrent() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.add(0);
    set.doScoped(
        copyCurrent: true,
        action: () {
          set.add(1);
          expect(set.isInScope(0), true);
          expect(set.isInScope(1), true);
        });
    expect(set.isInScope(0), true);
    expect(set.isInScope(1), false);
  }

  test_doScoped_elements() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.doScoped(
        elements: [0, 1],
        action: () {
          expect(set.isInScope(0), true);
          expect(set.isInScope(1), true);
        });
    expect(set.isInScope(0), false);
    expect(set.isInScope(1), false);
  }

  test_doScoped_newScope() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.add(0);
    set.doScoped(action: () {
      set.add(1);
      expect(set.isInScope(0), false);
      expect(set.isInScope(1), true);
    });
    expect(set.isInScope(0), true);
    expect(set.isInScope(1), false);
  }

  test_initiallyEmpty() {
    final set = ScopedSet<int>();
    expect(set.isInScope(0), false);
    expect(set.isInScope(1), false);
  }

  test_popScope_copyCurrent() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.add(0);
    set.pushScope(copyCurrent: true);
    set.popScope();
    expect(set.isInScope(0), true);
  }

  test_popScope_element() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.add(0);
    set.pushScope();
    set.popScope();
    expect(set.isInScope(0), true);
  }

  test_popScope_empty() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.pushScope();
    set.add(0);
    set.popScope();
    expect(set.isInScope(0), false);
  }

  test_pushScope_add() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.add(0);
    expect(set.isInScope(0), true);
  }

  test_pushScope_copyCurrent() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.add(0);
    set.pushScope(copyCurrent: true);
    expect(set.isInScope(0), true);
  }

  test_pushScope_empty() {
    final set = ScopedSet<int>();
    set.pushScope();
    expect(set.isInScope(0), false);
  }

  test_pushScope_empty2() {
    final set = ScopedSet<int>();
    set.pushScope();
    set.add(0);
    set.pushScope();
    expect(set.isInScope(0), false);
  }

  test_pushScope_withElements() {
    final set = ScopedSet<int>();
    set.pushScope(elements: [0, 1]);
    expect(set.isInScope(0), true);
    expect(set.isInScope(1), true);
  }

  test_removeFromAllScopes() {
    final set = ScopedSet<int>();
    set.pushScope(elements: [0, 1]);
    set.pushScope(copyCurrent: true);
    set.removeFromAllScopes(0);
    expect(set.isInScope(0), false);
    expect(set.isInScope(1), true);
    set.popScope();
    expect(set.isInScope(0), false);
    expect(set.isInScope(1), true);
  }
}
