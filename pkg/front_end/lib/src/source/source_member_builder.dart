// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../base/common.dart';
import '../base/problems.dart' show unsupported;
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart';
import '../type_inference/type_inference_engine.dart'
    show InferenceDataForTesting;
import 'source_class_builder.dart';
import 'source_library_builder.dart';

typedef BuildNodesCallback = void Function(
    {required Member member, Member? tearOff, required BuiltMemberKind kind});

abstract class SourceMemberBuilder implements MemberBuilder {
  MemberDataForTesting? get dataForTesting;

  Iterable<MetadataBuilder>? get metadataForTesting;

  @override
  SourceLibraryBuilder get libraryBuilder;

  /// Builds the core AST structures for this member as needed for the outline.
  void buildOutlineNodes(BuildNodesCallback f);

  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners);

  /// Builds the AST nodes for this member as needed for the full compilation.
  ///
  /// This includes adding augmented bodies and augmented members.
  int buildBodyNodes(BuildNodesCallback f);

  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery});

  /// Checks the variance of type parameters [sourceClassBuilder] used in the
  /// signature of this member.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  /// Checks the signature types of this member.
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment);

  /// Returns `true` if this member is declared using the `augment` modifier.
  bool get isAugmentation;

  /// Returns `true` if this member is a member declared in an augmentation
  /// library that conflicts with a declaration in the origin library.
  bool get isConflictingAugmentationMember;
  void set isConflictingAugmentationMember(bool value);

  AugmentSuperTarget? get augmentSuperTarget;

  BodyBuilderContext createBodyBuilderContext();
}

mixin SourceMemberBuilderMixin implements SourceMemberBuilder {
  @override
  MemberDataForTesting? dataForTesting =
      retainDataForTesting ? new MemberDataForTesting() : null;

  @override
  // Coverage-ignore(suite): Not run.
  void buildOutlineNodes(BuildNodesCallback f) {
    assert(false, "Unexpected call to $runtimeType.buildMembers.");
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => false;

  @override
  bool get isConflictingAugmentationMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  void set isConflictingAugmentationMember(bool value) {
    assert(false,
        "Unexpected call to $runtimeType.isConflictingAugmentationMember=");
  }

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    throw new UnimplementedError('$runtimeType.augmentSuperTarget');
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    throw new UnimplementedError('$runtimeType.bodyBuilderContext');
  }
}

abstract class SourceMemberBuilderImpl extends MemberBuilderImpl
    implements SourceMemberBuilder {
  @override
  MemberDataForTesting? dataForTesting;

  SourceMemberBuilderImpl()
      : dataForTesting = retainDataForTesting
            ?
            // Coverage-ignore(suite): Not run.
            new MemberDataForTesting()
            : null;

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
  // Coverage-ignore(suite): Not run.
  ProcedureKind? get kind => unsupported("kind", fileOffset, fileUri);

  @override
  // Coverage-ignore(suite): Not run.
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {}

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(runtimeType);
    sb.write('(');
    if (isAugmenting) {
      sb.write('augmentation ');
    }
    if (isClassMember) {
      sb.write(classBuilder!.name);
      sb.write('.');
    }
    sb.write(name);
    sb.write(')');
    return sb.toString();
  }

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    throw new UnimplementedError('$runtimeType.augmentSuperTarget}');
  }
}

enum BuiltMemberKind {
  Constructor,
  RedirectingFactory,
  Field,
  Method,
  Factory,
  ExtensionField,
  ExtensionMethod,
  ExtensionGetter,
  ExtensionSetter,
  ExtensionOperator,
  ExtensionTypeConstructor,
  ExtensionTypeMethod,
  ExtensionTypeGetter,
  ExtensionTypeSetter,
  ExtensionTypeOperator,
  ExtensionTypeFactory,
  ExtensionTypeRedirectingFactory,
  ExtensionTypeRepresentationField,
  LateIsSetField,
  LateGetter,
  LateSetter,
}

class MemberDataForTesting {
  final InferenceDataForTesting inferenceData = new InferenceDataForTesting();
}

class AugmentSuperTarget {
  final SourceMemberBuilder declaration;
  final Member? readTarget;
  final Member? invokeTarget;
  final Member? writeTarget;

  AugmentSuperTarget(
      {required this.declaration,
      required this.readTarget,
      required this.invokeTarget,
      required this.writeTarget});
}
