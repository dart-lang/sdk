// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in cascades for static member enum
// shorthands.

import '../dot_shorthand_helper.dart';

class Cascade {
  late StaticMember member;
  late StaticMemberExt memberExt;
}

class CascadeCollection {
  late List<StaticMember> memberList;
  late Set<StaticMember> memberSet;
  late Map<StaticMember, StaticMember> memberMap;
  late Map<StaticMember, (StaticMember, StaticMember)> memberMap2;

  late List<StaticMemberExt> memberExtList;
  late Set<StaticMemberExt> memberExtSet;
  late Map<StaticMemberExt, StaticMemberExt> memberExtMap;
  late Map<StaticMemberExt, (StaticMemberExt, StaticMemberExt)> memberExtMap2;
}

class CascadeMethod {
  void member(StaticMember member) => print(member);
  void memberExt(StaticMemberExt member) => print(member);
}

void main() {
  Cascade()
    ..member = .member()
    ..member = .memberType<String, int>('s')
    ..memberExt = .member()
    ..memberExt = .memberType<String, int>('s');

  dynamic mayBeNull = null;
  Cascade()
    ..member = mayBeNull ?? .member()
    ..member = mayBeNull ?? .memberType<String, int>('s')
    ..memberExt = mayBeNull ?? .member()
    ..memberExt = mayBeNull ?? .memberType<String, int>('s');

  CascadeCollection()
    ..memberList = [.member(), .memberType<String, int>('s')]
    ..memberSet = {.member(), .memberType<String, int>('s')}
    ..memberMap = {
      .member(): .member(),
      .memberType<String, int>(
        's',
      ): .memberType<String, int>('s'),
    }
    ..memberMap2 = {
      .member(): (.member(), .member()),
      .memberType<String, int>('s'): (
        .memberType<String, int>('s'),
        .memberType<String, int>('s'),
      ),
    }
    ..memberExtList = [.member(), .memberType<String, int>('s')]
    ..memberExtSet = {.member(), .memberType<String, int>('s')}
    ..memberExtMap = {
      .member(): .member(),
      .memberType<String, int>(
        's',
      ): .memberType<String, int>('s'),
    }
    ..memberExtMap2 = {
      .member(): (.member(), .member()),
      .memberType<String, int>('s'): (
        .memberType<String, int>('s'),
        .memberType<String, int>('s'),
      ),
    };

  CascadeMethod()
    ..member(.member())
    ..member(.memberType<String, int>('s'))
    ..memberExt(.member())
    ..memberExt(.memberType<String, int>('s'));

  StaticMember member = .member()..toString();
  StaticMember memberType = .memberType<String, int>('s')
    ..toString();
  StaticMemberExt memberExt = .member()..toString();
  StaticMemberExt memberTypeExt = .memberType<String, int>('s')
    ..toString();
}
