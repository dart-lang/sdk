// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.member_builder;

import 'package:kernel/ast.dart';

import '../kernel/hierarchy/class_member.dart';
import '../modifier.dart';
import 'builder.dart';
import 'class_builder.dart';
import 'declaration_builder.dart';
import 'extension_builder.dart';
import 'extension_type_declaration_builder.dart';
import 'library_builder.dart';
import 'modifier_builder.dart';

abstract class MemberBuilder implements ModifierBuilder {
  @override
  String get name;

  bool get isAssignable;

  void set parent(Builder? value);

  LibraryBuilder get libraryBuilder;

  /// The [Member] built by this builder;
  Member get member;

  /// The [Member] to use when reading from this member builder.
  ///
  /// For a field, a getter or a regular method this is the [member] itself.
  /// For an instance extension method this is special tear-off function. For
  /// a constructor, an operator, a factory or a setter this is `null`.
  Member? get readTarget;

  /// The [Member] to use when write to this member builder.
  ///
  /// For an assignable field or a setter this is the [member] itself. For
  /// a constructor, a non-assignable field, a getter, an operator or a regular
  /// method this is `null`.
  Member? get writeTarget;

  /// The [Member] to use when invoking this member builder.
  ///
  /// For a constructor, a field, a regular method, a getter, an operator or
  /// a factory this is the [member] itself. For a setter this is `null`.
  Member? get invokeTarget;

  /// The members from this builder that are accessible in exports through
  /// the name of the builder.
  ///
  /// This is used to allow a single builder to create separate members for
  /// the getter and setter capabilities.
  Iterable<Member> get exportedMembers;

  // TODO(johnniwinther): Remove this and create a [ProcedureBuilder] interface.
  ProcedureKind? get kind;

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

  /// The builder for the enclosing class, if any.
  ClassBuilder? get classBuilder;

  /// Returns the [Annotatable] nodes that hold the annotations declared on this
  /// member.
  Iterable<Annotatable> get annotatables;
}

abstract class MemberBuilderImpl extends ModifierBuilderImpl
    implements MemberBuilder {
  @override
  String get name;

  /// For top-level members, the parent is set correctly during
  /// construction. However, for class members, the parent is initially the
  /// library and updated later.
  @override
  Builder? parent;

  @override
  final Uri fileUri;

  MemberBuilderImpl(this.parent, int charOffset, [Uri? fileUri])
      : this.fileUri = (fileUri ?? parent?.fileUri)!,
        super(parent, charOffset);

  @override
  ClassBuilder? get classBuilder =>
      parent is ClassBuilder ? parent as ClassBuilder : null;

  @override
  LibraryBuilder get libraryBuilder {
    if (parent is LibraryBuilder) {
      LibraryBuilder library = parent as LibraryBuilder;
      return library.partOfLibrary ?? library;
    } else if (parent is ExtensionBuilder) {
      ExtensionBuilder extension = parent as ExtensionBuilder;
      return extension.libraryBuilder;
    } else if (parent is ExtensionTypeDeclarationBuilder) {
      ExtensionTypeDeclarationBuilder extensionTypeDeclaration =
          parent as ExtensionTypeDeclarationBuilder;
      return extensionTypeDeclaration.libraryBuilder;
    } else {
      ClassBuilder cls = parent as ClassBuilder;
      return cls.libraryBuilder;
    }
  }

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
  bool get isNative => false;

  @override
  bool get isExternal => (modifiers & externalMask) != 0;

  @override
  bool get isAbstract => (modifiers & abstractMask) != 0;

  @override
  bool get isConflictingSetter => false;

  @override
  String get fullNameForErrors => name;
}

/// Base class for implementing [ClassMember] for a [MemberBuilder].
abstract class BuilderClassMember implements ClassMember {
  MemberBuilderImpl get memberBuilder;

  @override
  int get charOffset => memberBuilder.charOffset;

  @override
  ClassBuilder get classBuilder => memberBuilder.classBuilder!;

  @override
  Uri get fileUri => memberBuilder.fileUri;

  @override
  Name get name => memberBuilder.member.name;

  @override
  String get fullName {
    String suffix = isSetter ? "=" : "";
    String className = classBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}$suffix";
  }

  @override
  String get fullNameForErrors => memberBuilder.fullNameForErrors;

  @override
  bool get isAssignable => memberBuilder.isAssignable;

  @override
  bool get isConst => memberBuilder.isConst;

  @override
  bool get isDuplicate => memberBuilder.isDuplicate;

  @override
  bool get isField => memberBuilder.isField;

  @override
  bool get isFinal => memberBuilder.isFinal;

  @override
  bool get isGetter => memberBuilder.isGetter;

  @override
  bool get isSetter => memberBuilder.isSetter;

  @override
  bool get isStatic => memberBuilder.isStatic;

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return classBuilder == objectClass;
  }

  @override
  bool get isAbstract => memberBuilder.member.isAbstract;

  @override
  bool get isSynthesized => false;

  @override
  bool get isInternalImplementation => false;

  @override
  bool get isNoSuchMethodForwarder => false;

  @override
  bool get hasDeclarations => false;

  @override
  List<ClassMember> get declarations =>
      throw new UnsupportedError("$runtimeType.declarations");

  @override
  ClassMember get interfaceMember => this;

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}
