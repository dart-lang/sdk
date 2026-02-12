// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in an if-null `??` expression.

import 'package:expect/expect.dart';

import '../dot_shorthand_helper.dart';

StaticMember memberTest(StaticMember? member) => member ?? .member();

StaticMember memberTypeTest(StaticMember? member) => member ?? .memberType<String, int>("s");

void noContextLHSContext(StaticMember? member) {
  member ?? .member();
  member ?? .memberType<String, int>("s");
}

StaticMemberExt memberExtTest(StaticMemberExt? member) => member ?? .member();

StaticMemberExt memberExtTypeTest(StaticMemberExt? member) => member ?? .memberType<String, int>("s");

void noContextLHSContextExt(StaticMemberExt? member) {
  member ?? .member();
  member ?? .memberType<String, int>("s");
}

void main() {
  // Class
  var memberDefault = StaticMember.memberType<int, int>(100);

  Expect.isNotNull(memberTest(null));
  Expect.equals(memberTest(memberDefault), memberDefault);

  Expect.isNotNull(memberTypeTest(null));
  Expect.equals(memberTypeTest(memberDefault), memberDefault);

  noContextLHSContext(null);
  noContextLHSContext(memberDefault);

  StaticMember possiblyNullable = .memberNullable() ?? memberDefault;
  StaticMember possiblyNullableWithType = .memberTypeNullable<String, int>("s") ?? memberDefault;

  // Extension type
  var memberExtDefault = StaticMemberExt.memberType(100);

  Expect.isNotNull(memberExtTest(null));
  Expect.equals(memberExtTest(memberExtDefault), memberExtDefault);

  Expect.isNotNull(memberExtTypeTest(null));
  Expect.equals(memberExtTypeTest(memberExtDefault), memberExtDefault);

  noContextLHSContextExt(null);
  noContextLHSContextExt(memberExtDefault);

  StaticMemberExt possiblyNullableExt = .memberNullable() ?? memberExtDefault;
  StaticMemberExt possiblyNullableExtWithType = .memberTypeNullable<String, int>("s") ?? memberExtDefault;
}
