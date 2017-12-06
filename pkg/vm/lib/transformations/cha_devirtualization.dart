// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.cha_devirtualization;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/class_hierarchy.dart' show ClosedWorldClassHierarchy;

import '../metadata/direct_call.dart';

/// Devirtualization of method invocations based on the class hierarchy
/// analysis. Assumes strong mode and closed world.
Program transformProgram(CoreTypes coreTypes, Program program) {
  new _Devirtualization(coreTypes, program).visitProgram(program);
  return program;
}

/// Resolves targets of instance method invocations, property getter
/// invocations and property setters invocations using strong mode
/// types / interface targets and closed-world class hierarchy analysis.
/// If direct target is determined, the invocation node is annotated
/// with direct call metadata.
class _Devirtualization extends RecursiveVisitor<Null> {
  /// Toggles tracing (useful for debugging).
  static const _trace = const bool.fromEnvironment('trace.devirtualization');

  final ClosedWorldClassHierarchy _hierarchy;
  final DirectCallMetadataRepository _metadata;
  Set<Name> _objectMemberNames;

  _Devirtualization(CoreTypes coreTypes, Program program)
      : _hierarchy = new ClosedWorldClassHierarchy(program),
        _metadata = new DirectCallMetadataRepository() {
    _objectMemberNames = new Set<Name>.from(_hierarchy
        .getInterfaceMembers(coreTypes.objectClass)
        .map((Member m) => m.name));
    program.addMetadataRepository(_metadata);
  }

  bool _isMethod(Member member) => (member is Procedure) && !member.isGetter;

  bool _isFieldOrGetter(Member member) =>
      (member is Field) || ((member is Procedure) && member.isGetter);

  bool _isLegalTargetForMethodInvocation(Member target, Arguments arguments) {
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

  _makeDirectCall(TreeNode node, Member target, Member singleTarget) {
    if (_trace) {
      print("[devirt] Resolving ${target} to ${singleTarget}");
    }
    _metadata.mapping[node] = new DirectCallMetadata(singleTarget, true);
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
    if ((target != null) &&
        _isMethod(target) &&
        !_objectMemberNames.contains(target.name)) {
      Member singleTarget =
          _hierarchy.getSingleTargetForInterfaceInvocation(target);
      // TODO(dartbug.com/30480): Convert _isLegalTargetForMethodInvocation()
      // check into an assertion once front-end implements override checks.
      if ((singleTarget != null) &&
          _isMethod(singleTarget) &&
          _isLegalTargetForMethodInvocation(singleTarget, node.arguments)) {
        _makeDirectCall(node, target, singleTarget);
      }
    }
  }

  @override
  visitPropertyGet(PropertyGet node) {
    super.visitPropertyGet(node);

    Member target = node.interfaceTarget;
    if ((target != null) &&
        _isFieldOrGetter(target) &&
        !_objectMemberNames.contains(target.name)) {
      Member singleTarget =
          _hierarchy.getSingleTargetForInterfaceInvocation(target);
      if ((singleTarget != null) && _isFieldOrGetter(singleTarget)) {
        _makeDirectCall(node, target, singleTarget);
      }
    }
  }

  @override
  visitPropertySet(PropertySet node) {
    super.visitPropertySet(node);

    Member target = node.interfaceTarget;
    if (target != null) {
      Member singleTarget = _hierarchy
          .getSingleTargetForInterfaceInvocation(target, setter: true);
      if (singleTarget != null) {
        _makeDirectCall(node, target, singleTarget);
      }
    }
  }
}
