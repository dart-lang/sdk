// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing the == and != behaviour for dot shorthands with static members.

import '../dot_shorthand_helper.dart';

void main() {
  // Enum
  StaticMember member = .member();

  bool eq = member == .member();
  bool neq = member != .member();

  if (member == .member()) print('ok');
  if (member != .member()) print('ok');

  StaticMember<String> memberType = .memberType<String, int>('s');

  bool eqType = memberType == .memberType<String, int>('s');
  bool neqType = memberType != .memberType<String, int>('s');

  if (memberType == .memberType<String, int>('s')) print('ok');
  if (memberType != .memberType<String, int>('s')) print('ok');
}
