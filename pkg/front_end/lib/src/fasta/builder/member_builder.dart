// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.member_builder;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../../base/common.dart';

import '../kernel/class_hierarchy_builder.dart';
import '../modifier.dart';
import '../problems.dart' show unsupported;
import '../type_inference/type_inference_engine.dart'
    show InferenceDataForTesting;

import 'builder.dart';
import 'class_builder.dart';
import 'declaration_builder.dart';
import 'extension_builder.dart';
import 'library_builder.dart';
import 'modifier_builder.dart';

abstract class MemberBuilder implements ModifierBuilder {
  bool get isAssignable;

  void set parent(Builder value);

  LibraryBuilder get library;

  /// The [Member] built by this builder;
  Member get member;

  /// The [Member] to use when reading from this member builder.
  ///
  /// For a field, a getter or a regular method this is the [member] itself.
  /// For an instance extension method this is special tear-off function. For
  /// a constructor, an operator, a factory or a setter this is `null`.
  Member get readTarget;

  /// The [Member] to use when write to this member builder.
  ///
  /// For an assignable field or a setter this is the [member] itself. For
  /// a constructor, a non-assignable field, a getter, an operator or a regular
  /// method this is `null`.
  Member get writeTarget;

  /// The [Member] to use when invoking this member builder.
  ///
  /// For a constructor, a field, a regular method, a getter an operator or
  /// a factory this is the [member] itself. For a setter this is `null`.
  Member get invokeTarget;

  /// The members from this builder that are accessible in exports through
  /// the name of the builder.
  ///
  /// This is used to allow a single builder to create separate members for
  /// the getter and setter capabilities.
  Iterable<Member> get exportedMembers;

  // TODO(johnniwinther): Remove this and create a [ProcedureBuilder] interface.
  ProcedureKind get kind;

  bool get isExternal;

  bool get isAbstract;

  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes);

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
}

abstract class MemberBuilderImpl extends ModifierBuilderImpl
    implements MemberBuilder {
  /// For top-level members, the parent is set correctly during
  /// construction. However, for class members, the parent is initially the
  /// library and updated later.
  @override
  Builder parent;

  @override
  String get name;

  MemberDataForTesting dataForTesting;

  MemberBuilderImpl(this.parent, int charOffset, [Uri fileUri])
      : dataForTesting =
            retainDataForTesting ? new MemberDataForTesting() : null,
        super(parent, charOffset, fileUri);

  @override
  bool get isDeclarationInstanceMember => isDeclarationMember && !isStatic;

  @override
  bool get isClassInstanceMember => isClassMember && !isStatic;

  @override
  bool get isExtensionInstanceMember => isExtensionMember && !isStatic;

  @override
  bool get isDeclarationMember => parent is DeclarationBuilder;

  @override
  bool get isClassMember => parent is ClassBuilder;

  @override
  bool get isExtensionMember => parent is ExtensionBuilder;

  @override
  bool get isTopLevel => !isDeclarationMember;

  @override
  bool get isNative => false;

  bool get isRedirectingGenerativeConstructor => false;

  @override
  bool get isExternal => (modifiers & externalMask) != 0;

  @override
  bool get isAbstract => (modifiers & abstractMask) != 0;

  @override
  LibraryBuilder get library {
    if (parent is LibraryBuilder) {
      LibraryBuilder library = parent;
      return library.partOfLibrary ?? library;
    } else if (parent is ExtensionBuilder) {
      ExtensionBuilder extension = parent;
      return extension.library;
    } else {
      ClassBuilder cls = parent;
      return cls.library;
    }
  }

  // TODO(johnniwinther): Remove this and create a [ProcedureBuilder] interface.
  @override
  ProcedureKind get kind => unsupported("kind", charOffset, fileUri);

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {}

  /// Builds the core AST structures for this member as needed for the outline.
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f);

  @override
  String get fullNameForErrors => name;

  @override
  StringBuffer printOn(StringBuffer buffer) {
    if (isClassMember) {
      buffer.write(classBuilder.name);
      buffer.write('.');
    }
    buffer.write(name);
    return buffer;
  }

  ClassBuilder get classBuilder => parent is ClassBuilder ? parent : null;
}

enum BuiltMemberKind {
  Constructor,
  RedirectingFactory,
  Field,
  Method,
  ExtensionField,
  ExtensionMethod,
  ExtensionGetter,
  ExtensionSetter,
  ExtensionOperator,
  ExtensionTearOff,
  LateIsSetField,
  LateGetter,
  LateSetter,
}

class MemberDataForTesting {
  final InferenceDataForTesting inferenceData = new InferenceDataForTesting();

  MemberBuilder patchForTesting;
}

/// Base class for implementing [ClassMember] for a [MemberBuilder].
abstract class BuilderClassMember implements ClassMember {
  MemberBuilderImpl get memberBuilder;

  @override
  int get charOffset => memberBuilder.charOffset;

  @override
  ClassBuilder get classBuilder => memberBuilder.classBuilder;

  @override
  Uri get fileUri => memberBuilder.fileUri;

  @override
  Name get name => memberBuilder.member.name;

  @override
  String get fullName {
    String suffix = isSetter ? "=" : "";
    String className = classBuilder?.fullNameForErrors;
    return className == null
        ? "${fullNameForErrors}$suffix"
        : "${className}.${fullNameForErrors}$suffix";
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
  bool get needsComputation => false;

  @override
  bool get isSynthesized => false;

  @override
  bool get isInternalImplementation => false;

  @override
  bool get isInheritableConflict => false;

  @override
  ClassMember withParent(ClassBuilder classBuilder) =>
      throw new UnsupportedError("$runtimeType.withParent");

  @override
  bool get hasDeclarations => false;

  @override
  List<ClassMember> get declarations =>
      throw new UnsupportedError("$runtimeType.declarations");

  @override
  ClassMember get abstract => this;

  @override
  ClassMember get concrete => this;

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}
