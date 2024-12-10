// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';

abstract class MemberBuilder implements Builder {
  String get name;

  bool get isAssignable;

  LibraryBuilder get libraryBuilder;

  /// The declared name of this member.
  ///
  /// For extension and extension type members this is different from the
  /// name of the generated members.
  ///
  /// For instance for
  ///
  ///     extension E {
  ///       get foo => null;
  ///     }
  ///     extension type E(int id) {
  ///       get foo => null;
  ///     }
  ///
  /// the [memberName] is `foo` for bother getters, but the name of the
  /// generated members is `E|foo` and `ET|foo`, respectively.
  Name get memberName;

  /// The [Member] to use when reading from this member builder.
  ///
  /// For a field, a getter or a regular method this is the member itself.
  /// For an instance extension method this is special tear-off function. For
  /// a constructor, an operator, a factory or a setter this is `null`.
  Member? get readTarget;

  /// The [Member] to use when write to this member builder.
  ///
  /// For an assignable field or a setter this is the member itself. For
  /// a constructor, a non-assignable field, a getter, an operator or a regular
  /// method this is `null`.
  Member? get writeTarget;

  /// The [Member] to use when invoking this member builder.
  ///
  /// For a constructor, a field, a regular method, a getter, an operator or
  /// a factory this is the member itself. For a setter this is `null`.
  Member? get invokeTarget;

  /// The references to the members from this builder that are accessible in
  /// exports through the name of the builder.
  ///
  /// This is used to allow a single builder to create separate members for
  /// the getter and setter capabilities.
  Iterable<Reference> get exportedMemberReferences;

  @override
  bool get isExternal;

  bool get isAbstract;

  /// Returns `true` if this member is a setter that conflicts with the implicit
  /// setter of a field.
  bool get isConflictingSetter;

  /// Returns the [ClassMember]s for the non-setter members created for this
  /// member builder.
  ///
  /// This is normally the member itself, if not a setter, but for instance for
  /// lowered late fields this can be synthesized members.
  List<ClassMember> get localMembers;

  /// Returns the [ClassMember]s for the setters created for this member
  /// builder.
  ///
  /// This is normally the member itself, if a setter, but for instance
  /// lowered late fields this can be synthesized setters.
  List<ClassMember> get localSetters;

  /// The builder for the enclosing class or extension type declaration, if any.
  ///
  /// Unused in interface; left in on purpose.
  DeclarationBuilder? get declarationBuilder;

  /// The builder for the enclosing class, if any.
  ClassBuilder? get classBuilder;

  /// Returns the [Annotatable] nodes that hold the annotations declared on this
  /// member.
  Iterable<Annotatable> get annotatables;

  /// Returns `true` is this member is a property, i.e. a field, getter or
  /// setter.
  bool get isProperty;
}

abstract class MemberBuilderImpl extends BuilderImpl implements MemberBuilder {
  @override
  Uri get fileUri;

  @override
  ClassBuilder? get classBuilder => declarationBuilder is ClassBuilder
      ? declarationBuilder as ClassBuilder
      : null;

  @override
  bool get isDeclarationInstanceMember => isDeclarationMember && !isStatic;

  @override
  bool get isClassInstanceMember => isClassMember && !isStatic;

  @override
  bool get isExtensionInstanceMember => isExtensionMember && !isStatic;

  @override
  bool get isExtensionTypeInstanceMember => isExtensionTypeMember && !isStatic;

  @override
  bool get isDeclarationMember => parent is DeclarationBuilder;

  @override
  bool get isClassMember => parent is ClassBuilder;

  @override
  bool get isExtensionMember => parent is ExtensionBuilder;

  @override
  bool get isExtensionTypeMember => parent is ExtensionTypeDeclarationBuilder;

  @override
  bool get isTopLevel => !isDeclarationMember;

  @override
  bool get isConflictingSetter => false;

  @override
  String get fullNameForErrors => name;
}

/// Base class for implementing [ClassMember] for a [MemberBuilder].
abstract class BuilderClassMember implements ClassMember {
  MemberBuilderImpl get memberBuilder;

  @override
  int get charOffset => memberBuilder.fileOffset;

  @override
  DeclarationBuilder get declarationBuilder =>
      memberBuilder.declarationBuilder!;

  @override
  Uri get fileUri => memberBuilder.fileUri;

  @override
  bool get isExtensionTypeMember => memberBuilder.isExtensionTypeMember;

  @override
  Name get name => memberBuilder.memberName;

  @override
  String get fullName {
    String suffix = isSetter ? "=" : "";
    String className = declarationBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}$suffix";
  }

  @override
  String get fullNameForErrors => memberBuilder.fullNameForErrors;

  @override
  bool get isDuplicate => memberBuilder.isDuplicate;

  @override
  bool get isField => memberBuilder.isField;

  @override
  bool get isGetter => memberBuilder.isGetter;

  @override
  bool get isSetter => memberBuilder.isSetter;

  @override
  bool get isStatic => memberBuilder.isStatic;

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return declarationBuilder == objectClass;
  }

  @override
  bool get isAbstract => memberBuilder.isAbstract;

  @override
  bool get isSynthesized => false;

  @override
  bool get isInternalImplementation => false;

  @override
  bool get isNoSuchMethodForwarder => false;

  @override
  bool get hasDeclarations => false;

  @override
  bool get forSetter => memberKind == ClassMemberKind.Setter;

  @override
  bool get isProperty => memberKind != ClassMemberKind.Method;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError("$runtimeType.declarations");

  @override
  ClassMember get interfaceMember => this;

  @override
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    if (isStatic) {
      // Coverage-ignore-block(suite): Not run.
      return new StaticMemberResult(getMember(membersBuilder), memberKind,
          isDeclaredAsField: memberBuilder.isField,
          fullName:
              '${declarationBuilder.name}.${memberBuilder.memberName.text}');
    } else if (memberBuilder.isExtensionTypeMember) {
      ExtensionTypeDeclaration extensionTypeDeclaration =
          (declarationBuilder as ExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration;
      Member member = getTearOff(membersBuilder) ?? getMember(membersBuilder);
      return new ExtensionTypeMemberResult(
          extensionTypeDeclaration, member, memberKind, name,
          isDeclaredAsField: memberBuilder.isField);
    } else {
      return new TypeDeclarationInstanceMemberResult(
          getMember(membersBuilder), memberKind,
          isDeclaredAsField: memberBuilder.isField);
    }
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}
