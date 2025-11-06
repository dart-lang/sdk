// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/common.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart';
import '../type_inference/type_inference_engine.dart'
    show InferenceDataForTesting;
import 'source_class_builder.dart';
import 'source_library_builder.dart';

typedef BuildNodesCallback =
    void Function({
      required Member member,
      Member? tearOff,
      required BuiltMemberKind kind,
    });

/// [BuildNodesCallback] that doesn't add the member nodes.
void noAddBuildNodesCallback({
  required Member member,
  Member? tearOff,
  required BuiltMemberKind kind,
}) {}

abstract class SourceMemberBuilder implements MemberBuilder {
  MemberDataForTesting? get dataForTesting;

  Iterable<MetadataBuilder>? get metadataForTesting;

  @override
  SourceLibraryBuilder get libraryBuilder;

  @override
  Uri get fileUri;

  bool get isFinal;

  // TODO(johnniwinther): Avoid this or define a clear semantics.
  bool get isSynthesized;

  /// Builds the core AST structures for this member as needed for the outline.
  void buildOutlineNodes(BuildNodesCallback f);

  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  );

  /// Builds the AST nodes for this member as needed for the full compilation.
  ///
  /// This includes adding augmented bodies and augmented members.
  int buildBodyNodes(BuildNodesCallback f);

  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  });

  /// Checks the variance of type parameters [sourceClassBuilder] used in the
  /// signature of this member.
  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  );

  /// Checks the signature types of this member.
  void checkTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  );
}

mixin SourceMemberBuilderMixin implements SourceMemberBuilder {
  @override
  MemberDataForTesting? dataForTesting = retainDataForTesting
      ? new MemberDataForTesting()
      : null;

  @override
  // Coverage-ignore(suite): Not run.
  void buildOutlineNodes(BuildNodesCallback f) {
    assert(false, "Unexpected call to $runtimeType.buildMembers.");
  }

  @override
  // Coverage-ignore(suite): Not run.
  int buildBodyNodes(BuildNodesCallback f) {
    return 0;
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

  @override
  // Coverage-ignore(suite): Not run.
  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {}

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(runtimeType);
    sb.write('(');
    if (isClassMember) {
      sb.write(classBuilder!.name);
      sb.write('.');
    }
    sb.write(name);
    sb.write(')');
    return sb.toString();
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
  LateBackingField,
  LateIsSetField,
  LateGetter,
  LateSetter,
}

class MemberDataForTesting {
  final InferenceDataForTesting inferenceData = new InferenceDataForTesting();
}

// Coverage-ignore(suite): Not run.
class AugmentSuperTarget {
  final SourceMemberBuilder declaration;
  final Member? readTarget;
  final Member? invokeTarget;
  final Member? writeTarget;

  AugmentSuperTarget({
    required this.declaration,
    required this.readTarget,
    required this.invokeTarget,
    required this.writeTarget,
  });
}
