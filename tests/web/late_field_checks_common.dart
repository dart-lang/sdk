// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library late_field_checks.common;

import 'package:expect/expect.dart';

// True for DDC and VM.
final bool isAlwaysChecked = !const bool.fromEnvironment('dart2js');

/// Interface for test object classes that have a field. All the test objects
/// implement this interface.
abstract class Field {
  abstract int field;
}

/// Tag interface for a class where the `late` field is also `final`.
class Final {}

/// Tag interface for a class where late field is checked.
class Checked {}

/// Tag interface for a class where the late field checks are not performed for
/// the late field.
class Trusted {}

/// The library 'name' e.g. 'LibraryCheck'
/// Nullable so it can be cleared to ensure the library's main() sets it.
String? libraryName;

String describeClass(Field object) {
  final name = '${libraryName!}.${object.runtimeType}';
  final interfaces = [
    if (object is Final) 'Final',
    'Field',
    if (object is Checked) 'Checked',
    if (object is Trusted) 'Trusted'
  ];

  return '$name implements ${interfaces.join(", ")}';
}

void test(Field Function() factory) {
  // Consistency checks.
  final o1 = factory();
  // Get the class description to ensure library name is set.
  final description = describeClass(o1);
  print('-- $description');
  Expect.isTrue(o1 is Checked || o1 is Trusted,
      'Test class must implement one of Checked or Trusted: $description');
  Expect.isFalse(o1 is Checked && o1 is Trusted,
      'Test class must not implement both of Checked or Trusted: $description');

  // Setter then Getter should not throw.
  final o2 = factory();
  o2.field = 100;
  Expect.equals(100, o2.field);

  testGetterBeforeSetter(factory());
  testDoubleSetter(factory());
}

void testGetterBeforeSetter(Field object) {
  final isChecked = isAlwaysChecked || object is Checked;

  bool threw = false;
  try {
    _sink = object.field;
  } catch (e, s) {
    threw = true;
  }

  if (threw == isChecked) return;
  _fail(object, threw, 'getter before setter');
}

void testDoubleSetter(Field object) {
  final isChecked = isAlwaysChecked || object is Checked;

  object.field = 101;
  bool threw = false;
  try {
    object.field = 102;
  } catch (e, s) {
    threw = true;
  }

  if (object is Final) {
    if (threw == isChecked) return;
    _fail(object, threw, 'double setter');
  }

  Expect.equals(102, object.field);
}

int _sink = 0;

void _fail(Field object, bool threw, String testDescription) {
  final classDescription = describeClass(object);
  if (threw) {
    Expect.fail('Should not throw for $testDescription: $classDescription');
  } else {
    Expect.fail('Failed to throw for $testDescription: $classDescription');
  }
}
