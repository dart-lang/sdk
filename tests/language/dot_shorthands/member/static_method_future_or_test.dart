// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `FutureOr<S>` denotes the same namespace as `S` for dot shorthands on
// static members.

import 'dart:async';

import '../dot_shorthand_helper.dart';

class StaticMemberFutureOrContext {
  final FutureOr<StaticMember> member;
  final FutureOr<StaticMember?> nullableMember;
  StaticMemberFutureOrContext(this.member, this.nullableMember);
  StaticMemberFutureOrContext.named({this.nullableMember}) : member = .member();
  StaticMemberFutureOrContext.optional([this.nullableMember]): member = .member();
}

class StaticMemberExtFutureOrContext {
  final FutureOr<StaticMemberExt> memberExt;
  final FutureOr<StaticMemberExt?> nullableMemberExt;
  StaticMemberExtFutureOrContext(this.memberExt, this.nullableMemberExt);
  StaticMemberExtFutureOrContext.named({this.nullableMemberExt}) : memberExt = .member();
  StaticMemberExtFutureOrContext.optional([this.nullableMemberExt]): memberExt = .member();
}

void main() {
  // Class
  FutureOr<StaticMember> member = .member();
  FutureOr<FutureOr<StaticMember>> memberNested = .member();
  FutureOr<StaticMember?> nullableMember = .memberType<String, int>("s");

  var memberList = <FutureOr<StaticMember>>[.member(), .memberType<String, int>("s")];
  var nullableMemberList = <FutureOr<StaticMember?>>[.member(), .memberType<String, int>("s")];

  var memberContextPositional = StaticMemberFutureOrContext(.member(), .memberType<String, int>("s"));
  var memberContextNamed = StaticMemberFutureOrContext.named(nullableMember: .memberType<String, int>("s"));
  var memberContextOptional = StaticMemberFutureOrContext.optional(.memberType<String, int>("s"));

  // Extension type
  FutureOr<StaticMemberExt> memberExt = .member();
  FutureOr<FutureOr<StaticMemberExt>> memberExtNested = .member();
  FutureOr<StaticMemberExt?> nullableMemberExt = .memberType<String, int>("s");

  var memberExtList = <FutureOr<StaticMemberExt>>[.member(), .memberType<String, int>("s")];
  var nullableMemberExtList = <FutureOr<StaticMemberExt?>>[.member(), .memberType<String, int>("s")];

  var memberExtContextPositional = StaticMemberExtFutureOrContext(.member(), .memberType<String, int>("s"));
  var memberExtContextNamed = StaticMemberExtFutureOrContext.named(nullableMemberExt: .memberType<String, int>("s"));
  var memberExtContextOptional = StaticMemberExtFutureOrContext.optional(.memberType<String, int>("s"));
}

