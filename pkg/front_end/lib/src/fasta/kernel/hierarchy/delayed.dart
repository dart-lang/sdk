// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/src/legacy_erasure.dart';

import '../../source/source_class_builder.dart';
import 'class_member.dart';
import 'members_builder.dart';
import 'members_node.dart';

abstract class DelayedCheck {
  void check(ClassMembersBuilder membersBuilder);
}

class DelayedOverrideCheck implements DelayedCheck {
  final SourceClassBuilder _classBuilder;
  final ClassMember _declaredMember;
  final Set<ClassMember> _overriddenMembers;

  DelayedOverrideCheck(
      this._classBuilder, this._declaredMember, this._overriddenMembers);

  @override
  void check(ClassMembersBuilder membersBuilder) {
    Member declaredMember = _declaredMember.getMember(membersBuilder);

    /// If [_declaredMember] is a class member that is declared in an opt-in
    /// library but inherited to [_classBuilder] through an opt-out class then
    /// we need to apply legacy erasure to the declared type to get the
    /// inherited type.
    ///
    /// For interface members this is handled by member signatures but since
    /// these are abstract they will never be the inherited class member.
    ///
    /// For instance:
    ///
    ///    // Opt in:
    ///    class Super {
    ///      int extendedMethod(int i, {required int j}) => i;
    ///    }
    ///    class Mixin {
    ///      int mixedInMethod(int i, {required int j}) => i;
    ///    }
    ///    // Opt out:
    ///    class Legacy extends Super with Mixin {}
    ///    // Opt in:
    ///    class Class extends Legacy {
    ///      // Valid overrides since the type of `Legacy.extendedMethod` is
    ///      // `int* Function(int*, {int* j})`.
    ///      int? extendedMethod(int? i, {int? j}) => i;
    ///      // Valid overrides since the type of `Legacy.mixedInMethod` is
    ///      // `int* Function(int*, {int* j})`.
    ///      int? mixedInMethod(int? i, {int? j}) => i;
    ///    }
    ///
    bool declaredNeedsLegacyErasure =
        needsLegacyErasure(_classBuilder.cls, declaredMember.enclosingClass!);
    void callback(Member interfaceMember, bool isSetter) {
      _classBuilder.checkOverride(membersBuilder.hierarchyBuilder.types,
          membersBuilder, declaredMember, interfaceMember, isSetter, callback,
          isInterfaceCheck: !_classBuilder.isMixinApplication,
          declaredNeedsLegacyErasure: declaredNeedsLegacyErasure);
    }

    for (ClassMember overriddenMember in _overriddenMembers) {
      callback(
          overriddenMember.getMember(membersBuilder), _declaredMember.isSetter);
    }
  }
}

class DelayedGetterSetterCheck implements DelayedCheck {
  final SourceClassBuilder classBuilder;
  final ClassMember getter;
  final ClassMember setter;

  const DelayedGetterSetterCheck(this.classBuilder, this.getter, this.setter);

  @override
  void check(ClassMembersBuilder membersBuilder) {
    classBuilder.checkGetterSetter(membersBuilder.hierarchyBuilder.types,
        getter.getMember(membersBuilder), setter.getMember(membersBuilder));
  }
}

class DelayedTypeComputation {
  final ClassMembersNodeBuilder builder;
  final ClassMember declaredMember;
  final Set<ClassMember> overriddenMembers;
  bool _computed = false;

  DelayedTypeComputation(
      this.builder, this.declaredMember, this.overriddenMembers)
      : assert(declaredMember.isSourceDeclaration);

  void compute(ClassMembersBuilder membersBuilder) {
    if (_computed) return;
    declaredMember.inferType(membersBuilder);
    _computed = true;
    if (declaredMember.isField) {
      builder.inferFieldSignature(
          membersBuilder, declaredMember, overriddenMembers);
    } else if (declaredMember.isGetter) {
      builder.inferGetterSignature(
          membersBuilder, declaredMember, overriddenMembers);
    } else if (declaredMember.isSetter) {
      builder.inferSetterSignature(
          membersBuilder, declaredMember, overriddenMembers);
    } else {
      builder.inferMethodSignature(
          membersBuilder, declaredMember, overriddenMembers);
    }
  }

  @override
  String toString() => 'DelayedTypeComputation('
      '${builder.classBuilder.name},$declaredMember,$overriddenMembers)';
}
