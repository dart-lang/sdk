// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic usages of enum shorthands with static members in classes and extension
// types.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

class StaticMemberContext {
  final StaticMember? clas;
  StaticMemberContext(this.clas);
  StaticMemberContext.named({this.clas});
  StaticMemberContext.optional([this.clas]);
}

class StaticMemberExtContext {
  final StaticMemberExt? ext;
  StaticMemberExtContext(this.ext);
  StaticMemberExtContext.named({this.ext});
  StaticMemberExtContext.optional([this.ext]);
}

void main() {
  StaticMember<int> s = .member();
  StaticMemberContext(.member());
  StaticMemberContext.named(clas: .member());
  StaticMemberContext.optional(.member());

  StaticMember<String> sTypeParameters = .memberType("s");
  StaticMemberContext(.memberType("s"));
  StaticMemberContext.named(clas: .memberType("s"));
  StaticMemberContext.optional(.memberType("s"));

  StaticMemberExt<int> sExt = .member();
  StaticMemberExtContext(.member());
  StaticMemberExtContext.named(ext: .member());
  StaticMemberExtContext.optional(.member());

  StaticMemberExt<String> sTypeParametersExt = .memberType("s");
  StaticMemberExtContext(.memberType("s"));
  StaticMemberExtContext.named(ext: .memberType("s"));
  StaticMemberExtContext.optional(.memberType("s"));

  <StaticMember>[.member(), .memberType('s')];
  <StaticMember?>[.member(), .memberType('s')];
  <StaticMemberExt>[.member(), .memberType('s')];
  <StaticMemberExt?>[.member(), .memberType('s')];
}
