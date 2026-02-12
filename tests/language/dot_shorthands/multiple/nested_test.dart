// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Nested dot shorthands.

import '../dot_shorthand_helper.dart';

void main() {
  StaticMember<StaticMember<StaticMember>> memberMember = .memberType(
    .memberType(.member()),
  );

  StaticMemberExt<StaticMemberExt<StaticMemberExt>> memberMemberExt = .memberType(
    .memberType(.member()),
  );

  StaticMember<StaticMember<StaticMember>> memberCtor = .memberType(.new(.member()));

  StaticMemberExt<StaticMemberExt<StaticMemberExt>> memberCtorExt = .memberType(
    .new(.member()),
  );

  StaticMember<Integer> memberProperty = .property(.one);

  StaticMemberExt<Integer> memberPropertyExt = .property(.one);

  StaticMember<ConstructorClass> memberCtorMember = .ctor(
    .staticMember(.member()),
  );

  StaticMemberExt<ConstructorClass> memberCtorMemberExt = .ctor(
    .staticMemberExt(.member()),
  );

  StaticMember<ConstructorClass> memberCtorProperty = .ctor(.integer(.one));

  ConstructorClass ctorMember = .staticMember(.member());

  ConstructorClass ctorMemberExt = .staticMemberExt(.member());

  ConstructorClass ctorProperty = .integer(.one);

  ConstructorClass ctorCtor = .ctor(.new(1));

  ConstructorClass ctorCtorCtor = .ctor(.ctor(.new(1)));

  ConstructorClass ctorMemberCtor = .staticMember(.ctor(.named(x: 1)));

  ConstructorClass ctorMemberCtorExt = .staticMemberExt(.ctor(.named(x: 1)));
}
