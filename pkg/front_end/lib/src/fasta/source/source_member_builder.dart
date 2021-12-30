// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.member_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../../base/common.dart';
import '../builder/builder.dart';
import '../builder/declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../kernel/kernel_helper.dart';
import '../problems.dart' show unsupported;
import '../source/source_library_builder.dart';
import '../type_inference/type_inference_engine.dart'
    show InferenceDataForTesting;
import '../util/helpers.dart' show DelayedActionPerformer;

abstract class SourceMemberBuilder implements MemberBuilder {
  MemberDataForTesting? get dataForTesting;

  /// Builds the core AST structures for this member as needed for the outline.
  void buildMembers(
      SourceLibraryBuilder library, void Function(Member, BuiltMemberKind) f);

  void buildOutlineExpressions(
      SourceLibraryBuilder library,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes);
}

mixin SourceMemberBuilderMixin implements SourceMemberBuilder {
  @override
  MemberDataForTesting? dataForTesting =
      retainDataForTesting ? new MemberDataForTesting() : null;

  @override
  void buildMembers(
      SourceLibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    assert(false, "Unexpected call to $runtimeType.buildMembers.");
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

  bool get isRedirectingGenerativeConstructor => false;

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

  // TODO(johnniwinther): Remove this and create a [ProcedureBuilder] interface.
  @override
  ProcedureKind? get kind => unsupported("kind", charOffset, fileUri);

  @override
  void buildOutlineExpressions(
      SourceLibraryBuilder library,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {}

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

  MemberBuilder? patchForTesting;
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
