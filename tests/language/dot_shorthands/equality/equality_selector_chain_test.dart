// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing the == and != behaviour for dot shorthands with selector chains.

import '../dot_shorthand_helper.dart';

void main() {
  StaticMember member = .member();

  bool eqField = member == .member().field;
  bool eqMethod = member == .member().method();
  bool eqMixed = member == .member().method().field;
  bool eqMixed2 = member == .member().field.method();

  bool neqField = member != .member().field;
  bool neqMethod = member != .member().method();
  bool neqMixed = member != .member().method().field;
  bool neqMixed2 = member != .member().field.method();

  if (member == .member().field) print('ok');
  if (member == .member().method()) print('ok');
  if (member == .member().method().field) print('ok');
  if (member == .member().field.method()) print('ok');

  if (member != .member().field) print('ok');
  if (member != .member().method()) print('ok');
  if (member != .member().method().field) print('ok');
  if (member != .member().field.method()) print('ok');

  ConstructorWithNonFinal ctor = ConstructorWithNonFinal(1);

  bool eqCtorField = ctor == .new(1).field;
  bool eqCtorMethod = ctor == .new(1).method();
  bool eqCtorMixed = ctor == .new(1).method().field;
  bool eqCtorMixed2 = ctor == .new(1).field.method();

  bool neqCtorField = ctor != .new(1).field;
  bool neqCtorMethod = ctor != .new(1).method();
  bool neqCtorMixed = ctor != .new(1).method().field;
  bool neqCtorMixed2 = ctor != .new(1).field.method();

  if (ctor == .new(1).field) print('ok');
  if (ctor == .new(1).method()) print('ok');
  if (ctor == .new(1).method().field) print('ok');
  if (ctor == .new(1).field.method()) print('ok');

  if (ctor != .new(1).field) print('ok');
  if (ctor != .new(1).method()) print('ok');
  if (ctor != .new(1).method().field) print('ok');
  if (ctor != .new(1).field.method()) print('ok');
}
