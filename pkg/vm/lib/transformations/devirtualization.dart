// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.cha_devirtualization;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClosedWorldClassHierarchy;

import '../metadata/direct_call.dart';

/// Devirtualization of method invocations based on the class hierarchy
/// analysis. Assumes strong mode and closed world.
Program transformProgram(CoreTypes coreTypes, Program program) {
  new CHADevirtualization(
          coreTypes, program, new ClosedWorldClassHierarchy(program))
      .visitProgram(program);
  return program;
}

/// Base class for implementing devirtualization of method invocations.
/// Subclasses should implement particular devirtualization strategy in
/// [getDirectCall] method. Once direct target is determined, the invocation
/// node is annotated with direct call metadata.
abstract class Devirtualization extends RecursiveVisitor<Null> {
  /// Toggles tracing (useful for debugging).
  static const _trace = const bool.fromEnvironment('trace.devirtualization');

  final DirectCallMetadataRepository _metadata;
  Set<Name> _objectMemberNames;

  Devirtualization(
      CoreTypes coreTypes, Program program, ClassHierarchy hierarchy)
      : _metadata = new DirectCallMetadataRepository() {
    _objectMemberNames = new Set<Name>.from(hierarchy
        .getInterfaceMembers(coreTypes.objectClass)
        .map((Member m) => m.name));
    program.addMetadataRepository(_metadata);
  }

  bool isMethod(Member member) => (member is Procedure) && !member.isGetter;

  bool isFieldOrGetter(Member member) =>
      (member is Field) || ((member is Procedure) && member.isGetter);

  bool isLegalTargetForMethodInvocation(Member target, Arguments arguments) {
    final FunctionNode func = target.function;

    final positionalArgs = arguments.positional.length;
    if ((positionalArgs < func.requiredParameterCount) ||
        (positionalArgs > func.positionalParameters.length)) {
      return false;
    }

    if (arguments.named.isNotEmpty) {
      final names = arguments.named.map((v) => v.name).toSet();
      names.removeAll(func.namedParameters.map((v) => v.name));
      if (names.isNotEmpty) {
        return false;
      }
    }

    return true;
  }

  bool hasExtraTargetForNull(DirectCallMetadata directCall) =>
      directCall.checkReceiverForNull &&
      _objectMemberNames.contains(directCall.target.name);

  DirectCallMetadata getDirectCall(TreeNode node, Member target,
      {bool setter = false});

  makeDirectCall(TreeNode node, Member target, DirectCallMetadata directCall) {
    if (_trace) {
      print("[devirt] Resolving ${target} to ${directCall.target}"
          " at ${node.location}");
    }
    _metadata.mapping[node] = directCall;
  }

  @override
  visitLibrary(Library node) {
    if (_trace) {
      String external = node.isExternal ? " (external)" : "";
      print("[devirt] Processing library ${node.name}${external}");
    }
    super.visitLibrary(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    Member target = node.interfaceTarget;
    if ((target != null) && isMethod(target)) {
      DirectCallMetadata directCall = getDirectCall(node, target);
      // TODO(dartbug.com/30480): Convert _isLegalTargetForMethodInvocation()
      // check into an assertion once front-end implements override checks.
      if ((directCall != null) &&
          isMethod(directCall.target) &&
          isLegalTargetForMethodInvocation(directCall.target, node.arguments) &&
          !hasExtraTargetForNull(directCall)) {
        makeDirectCall(node, target, directCall);
      }
    }
  }

  @override
  visitPropertyGet(PropertyGet node) {
    super.visitPropertyGet(node);

    Member target = node.interfaceTarget;
    if ((target != null) && isFieldOrGetter(target)) {
      DirectCallMetadata directCall = getDirectCall(node, target);
      if ((directCall != null) &&
          isFieldOrGetter(directCall.target) &&
          !hasExtraTargetForNull(directCall)) {
        makeDirectCall(node, target, directCall);
      }
    }
  }

  @override
  visitPropertySet(PropertySet node) {
    super.visitPropertySet(node);

    Member target = node.interfaceTarget;
    if (target != null) {
      DirectCallMetadata directCall = getDirectCall(node, target, setter: true);
      if (directCall != null) {
        makeDirectCall(node, target, directCall);
      }
    }
  }
}

/// Devirtualization based on the closed-world class hierarchy analysis.
class CHADevirtualization extends Devirtualization {
  final ClosedWorldClassHierarchy _hierarchy;

  CHADevirtualization(CoreTypes coreTypes, Program program, this._hierarchy)
      : super(coreTypes, program, _hierarchy);

  @override
  DirectCallMetadata getDirectCall(TreeNode node, Member target,
      {bool setter = false}) {
    Member singleTarget = _hierarchy
        .getSingleTargetForInterfaceInvocation(target, setter: setter);
    if (singleTarget == null) {
      return null;
    }
    return new DirectCallMetadata(singleTarget, true);
  }
}
