// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.member_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../../base/common.dart';
import '../builder/builder.dart';
import '../builder/declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../kernel/kernel_helper.dart';
import '../modifier.dart';
import '../problems.dart' show unsupported;
import '../source/source_library_builder.dart';
import '../type_inference/type_inference_engine.dart'
    show InferenceDataForTesting;
import '../util/helpers.dart' show DelayedActionPerformer;
import 'source_class_builder.dart';

abstract class SourceMemberBuilder implements MemberBuilder {
  MemberDataForTesting? get dataForTesting;

  @override
  SourceLibraryBuilder get libraryBuilder;

  /// Builds the core AST structures for this member as needed for the outline.
  void buildMembers(void Function(Member, BuiltMemberKind) f);

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners);

  /// Checks the variance of type parameters [sourceClassBuilder] used in the
  /// signature of this member.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  /// Checks the signature types of this member.
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment);

  /// Returns `true` if this member is an augmentation.
  bool get isAugmentation;

  /// Returns `true` if this member is a member declared in an augmentation
  /// library that conflicts with a member in the origin library.
  bool get isConflictingAugmentationMember;
  void set isConflictingAugmentationMember(bool value);
}

mixin SourceMemberBuilderMixin implements SourceMemberBuilder {
  @override
  MemberDataForTesting? dataForTesting =
      retainDataForTesting ? new MemberDataForTesting() : null;

  @override
  void buildMembers(void Function(Member, BuiltMemberKind) f) {
    assert(false, "Unexpected call to $runtimeType.buildMembers.");
  }

  @override
  bool get isAugmentation => false;

  @override
  bool get isConflictingAugmentationMember => false;

  @override
  void set isConflictingAugmentationMember(bool value) {
    assert(false,
        "Unexpected call to $runtimeType.isConflictingAugmentationMember=");
  }
}

abstract class SourceMemberBuilderImpl extends MemberBuilderImpl
    implements SourceMemberBuilder {
  @override
  MemberDataForTesting? dataForTesting;

  SourceMemberBuilderImpl(Builder parent, int charOffset, [Uri? fileUri])
      : dataForTesting =
            retainDataForTesting ? new MemberDataForTesting() : null,
        super(parent, charOffset, fileUri);

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  bool get isRedirectingGenerativeConstructor => false;

  @override
  bool get isAugmentation => modifiers & augmentMask != 0;

  bool? _isConflictingSetter;

  @override
  bool get isConflictingSetter {
    return _isConflictingSetter ??= false;
  }

  void set isConflictingSetter(bool value) {
    assert(_isConflictingSetter == null,
        '$this.isConflictingSetter has already been fixed.');
    _isConflictingSetter = value;
  }

  bool? _isConflictingAugmentationMember;

  @override
  bool get isConflictingAugmentationMember {
    return _isConflictingAugmentationMember ??= false;
  }

  @override
  void set isConflictingAugmentationMember(bool value) {
    assert(_isConflictingAugmentationMember == null,
        '$this.isConflictingAugmentationMember has already been fixed.');
    _isConflictingAugmentationMember = value;
  }

  // TODO(johnniwinther): Remove this and create a [ProcedureBuilder] interface.
  @override
  ProcedureKind? get kind => unsupported("kind", charOffset, fileUri);

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {}

  @override
  StringBuffer printOn(StringBuffer buffer) {
    if (isClassMember) {
      buffer.write(classBuilder!.name);
      buffer.write('.');
    }
    buffer.write(name);
    return buffer;
  }

  /// The builder for the enclosing class or extension, if any.
  DeclarationBuilder? get declarationBuilder =>
      parent is DeclarationBuilder ? parent as DeclarationBuilder : null;
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
}

/// If the name of [member] is private, update it to use the library reference
/// of [libraryBuilder].
// TODO(johnniwinther): Avoid having to update private names by setting
// the correct library reference when creating parts.
void updatePrivateMemberName(Member member, LibraryBuilder libraryBuilder) {
  if (member.name.isPrivate) {
    member.name = new Name(member.name.text, libraryBuilder.library);
  }
}
