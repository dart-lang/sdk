// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.member_builder;

import 'builder.dart' show Builder, ClassBuilder, ModifierBuilder;

abstract class MemberBuilder extends ModifierBuilder {
  /// For top-level members, the parent is set correctly during
  /// construction. However, for class members, the parent is initially the
  /// library and updated later.
  Builder parent;

  String get name;

  MemberBuilder(Builder parent, int charOffset)
      : parent = parent,
        super(parent, charOffset);

  bool get isInstanceMember => isClassMember && !isStatic;

  bool get isClassMember => parent is ClassBuilder;

  bool get isTopLevel => !isClassMember;

  bool get isNative => false;

  bool get isRedirectingGenerativeConstructor => false;

  @override
  String get fullNameForErrors => name;
}
