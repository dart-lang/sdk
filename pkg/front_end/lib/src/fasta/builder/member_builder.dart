// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.member_builder;

import 'builder.dart' show
    Builder,
    ClassBuilder,
    ModifierBuilder;

abstract class MemberBuilder extends ModifierBuilder {
  Builder parent;

  bool get isInstanceMember => isClassMember && !isStatic;

  bool get isClassMember => parent is ClassBuilder;

  bool get isTopLevel => !isClassMember;
}
