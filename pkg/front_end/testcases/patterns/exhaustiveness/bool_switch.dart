// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void exhaustiveSwitch(bool b) {
  switch (b) /* Ok */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveSwitch1(bool b) {
  switch (b) /* Error */ {
    case true:
      print('true');
      break;
  }
}

void nonExhaustiveSwitch2(bool b) {
  switch (b) /* Error */ {
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(bool b) {
  switch (b) /* Ok */ {
    case true:
      print('true');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(bool? b) {
  switch (b) /* Ok */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(bool? b) {
  switch (b) /* Error */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveNullableSwitch2(bool? b) {
  switch (b) /* Error */ {
    case true:
      print('true');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(bool b) {
  switch (b) /* Ok */ {
    case true:
      print('true1');
      break;
    case false:
      print('false');
      break;
    case true: // Unreachable
      print('true2');
      break;
  }
}

void unreachableCase2(bool b) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (b) /* Error */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3(bool? b) {
  switch (b) /* Ok */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
    case null:
      print('null1');
      break;
    case null: // Unreachable
      print('null2');
      break;
  }
}
