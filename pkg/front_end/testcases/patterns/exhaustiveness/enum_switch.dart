// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { a, b, c }

void exhaustiveSwitch(Enum e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch1(Enum e) {
  switch (e) /* Error */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitch2(Enum e) {
  switch (e) /* Error */ {
    case Enum.a:
      print('a');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch3(Enum e) {
  switch (e) /* Error */ {
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch4(Enum e) {
  switch (e) /* Error */ {
    case Enum.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(Enum e) {
  switch (e) /* Ok */ {
    case Enum.b:
      print('b');
      break;
    default:
      print('a|c');
      break;
  }
}

void exhaustiveNullableSwitch(Enum? e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(Enum? e) {
  switch (e) /* Error */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveNullableSwitch2(Enum? e) {
  switch (e) /* Error */ {
    case Enum.a:
      print('a');
      break;
    case Enum.c:
      print('c');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(Enum e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a1');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.a: // Unreachable
      print('a2');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void unreachableCase2(Enum e) {
  switch (e) /* Non-exhaustive */ {
    case Enum.a:
      print('a1');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.a: // Unreachable
      print('a2');
      break;
  }
}

void unreachableCase3(Enum e) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (e) /* Error */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase4(Enum? e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
    case null:
      print('null1');
      break;
    case null: // Unreachable
      print('null2');
      break;
  }
}

enum GenericEnum<T> {
  a<int>(),
  b<String>(),
  c<bool>(),
}

void exhaustiveGenericSwitch(GenericEnum<dynamic> e) {
  switch (e) /* Ok */ {
    case GenericEnum.a:
      print('a');
      break;
    case GenericEnum.b:
      print('b');
      break;
    case GenericEnum.c:
      print('c');
      break;
  }
}

void exhaustiveGenericSwitchTyped(GenericEnum<int> e) {
  switch (e) /* Ok */ {
    case GenericEnum.a:
      print('a');
      break;
  }
}
