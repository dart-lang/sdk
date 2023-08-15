// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/reference.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferenceTest);
  });
}

@reflectiveTest
class ReferenceTest {
  void test_addingAndRemoving() {
    Reference root = Reference.root();

    // First child: foo.
    final firstCallFoo = root.getChild("foo");
    final secondCallFoo = root.getChild("foo");
    final thirdCallFoo = root["foo"];
    expect(secondCallFoo, same(firstCallFoo));
    expect(thirdCallFoo, same(firstCallFoo));
    expect(firstCallFoo.name, "foo");
    expect(root.childrenUnionForTesting, same(firstCallFoo));
    expect(root.children, hasLength(1));

    // Second child: bar.
    final firstCallBar = root.getChild("bar");
    final secondCallBar = root.getChild("bar");
    final thirdCallBar = root["bar"];
    expect(secondCallBar, same(firstCallBar));
    expect(thirdCallBar, same(firstCallBar));
    expect(firstCallBar.name, "bar");
    expect(root.childrenUnionForTesting, isA<Map<String, Reference>>());
    expect(root.children, hasLength(2));

    // Asking again returns the same.
    {
      final foo1 = root.getChild("foo");
      final foo2 = root["foo"];
      final bar1 = root.getChild("bar");
      final bar2 = root["bar"];
      expect(foo1, same(firstCallFoo));
      expect(foo2, same(firstCallFoo));
      expect(bar1, same(firstCallBar));
      expect(bar2, same(firstCallBar));
      expect(root.childrenUnionForTesting, isA<Map<String, Reference>>());
    }

    // Foo can have children.
    {
      final foo = root.getChild("foo");
      expect(foo.childrenUnionForTesting, isNull);
      final fooChild1 = foo.getChild("child1");
      expect(foo.childrenUnionForTesting, same(fooChild1));
      final fooChild1Again = foo.getChild("child1");
      expect(foo.childrenUnionForTesting, same(fooChild1));
      final fooChild2 = foo.getChild("child2");
      expect(foo.childrenUnionForTesting, isA<Map<String, Reference>>());
      final fooChild2Again = foo.getChild("child2");
      expect(foo.childrenUnionForTesting, isA<Map<String, Reference>>());
      expect(foo, same(firstCallFoo));
      expect(fooChild1, same(fooChild1Again));
      expect(fooChild1.name, "child1");
      expect(fooChild2, same(fooChild2Again));
      expect(fooChild2.name, "child2");
      expect(foo.children, hasLength(2));
    }

    // Removing foo works, retains bar, and root then has 1 child.
    {
      final foo1 = root.removeChild("foo");
      final foo2 = root["foo"];
      final bar1 = root.getChild("bar");
      final bar2 = root["bar"];
      expect(foo1, same(firstCallFoo));
      expect(foo1!.children, hasLength(2));
      expect(foo2, isNull);
      expect(bar1, same(firstCallBar));
      expect(bar2, same(firstCallBar));
      expect(root.children, hasLength(1));
      expect(root.childrenUnionForTesting, isA<Reference>());
      expect(root.childrenUnionForTesting, same(firstCallBar));
    }

    // Re-adding a foo is different than the initial one.
    {
      expect(root.childrenUnionForTesting, same(firstCallBar));
      final foo1 = root.getChild("foo");
      expect(root.childrenUnionForTesting, isA<Map<String, Reference>>());
      final foo2 = root["foo"];
      final bar1 = root.getChild("bar");
      final bar2 = root["bar"];
      expect(foo1.children, hasLength(0));
      expect(foo1.name, "foo");
      expect(identical(foo1, firstCallFoo), isFalse);
      expect(foo2, same(foo1));
      expect(bar1, same(firstCallBar));
      expect(bar2, same(firstCallBar));
      expect(root.children, hasLength(2));
    }
  }

  void test_rootDoesntContainFooBeforeAdded() {
    Reference root = Reference.root();
    expect(root["foo"], isNull);
    expect(root["foo"], isNull);
    expect(root.children, isEmpty);
    expect(root.childrenUnionForTesting, isNull);
  }

  void test_rootInitiallyEmpty() {
    Reference root = Reference.root();
    expect(root.children, isEmpty);
    expect(root.childrenUnionForTesting, isNull);
  }
}
