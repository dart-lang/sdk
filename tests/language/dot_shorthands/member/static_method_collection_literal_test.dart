// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in collection literals.
// Testing with static method shorthands.

import '../dot_shorthand_helper.dart';

void main() {
  var memberList = <StaticMember>[.member(), .memberType<String, int>('s'), .member()];
  var memberSet = <StaticMember>{.member(), .memberType<String, int>('s')};
  var memberMap = <StaticMember, StaticMember>{
    .member(): .memberType<String, int>('s'),
    .memberType<String, int>('s'): .memberType<String, int>('s'),
  };
  var memberMap2 = <StaticMember, (StaticMember, StaticMember)>{
    .member(): (.member(), .memberType<String, int>('s')),
    .memberType<String, int>('s'): (.memberType<String, int>('s'), .memberType<String, int>('s')),
  };

  var memberExtList = <StaticMemberExt>[
    .member(),
    .memberType<String, int>('s'),
    .member(),
  ];
  var memberExtSet = <StaticMemberExt>{.member(), .memberType<String, int>('s')};
  var memberExtMap = <StaticMemberExt, StaticMemberExt>{
    .member(): .memberType<String, int>('s'),
    .memberType<String, int>('s'): .memberType<String, int>('s'),
  };
  var memberExtMap2 = <StaticMemberExt, (StaticMemberExt, StaticMemberExt)>{
    .member(): (.member(), .memberType<String, int>('s')),
    .memberType<String, int>('s'): (.memberType<String, int>('s'), .memberType<String, int>('s')),
  };
}
