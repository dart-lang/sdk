// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.precompiler;

import '../ast.dart'
    show
        DirectMethodInvocation,
        DirectPropertyGet,
        DirectPropertySet,
        Field,
        Library,
        Member,
        MethodInvocation,
        Name,
        Procedure,
        Program,
        PropertyGet,
        PropertySet,
        TreeNode;

import '../core_types.dart' show CoreTypes;

import '../class_hierarchy.dart' show ClosedWorldClassHierarchy;

import '../visitor.dart' show Transformer;

/// Performs whole-program transformations for Dart VM precompiler.
/// Assumes strong mode and closed world.
Program transformProgram(CoreTypes coreTypes, Program program) {
  new _DevirtualizationTransformer(coreTypes, program).visitProgram(program);
  return program;
}

/// Transforms instance method invocations into direct using strong mode
/// types / interface targets and closed-world class hierarchy analysis.
class _DevirtualizationTransformer extends Transformer {
  /// Toggles tracing (useful for debugging).
  static const _trace = const bool.fromEnvironment('trace.devirtualization');

  final ClosedWorldClassHierarchy _hierarchy;
  Set<Name> _objectMemberNames;

  _DevirtualizationTransformer(CoreTypes coreTypes, Program program)
      : _hierarchy = new ClosedWorldClassHierarchy(program) {
    _objectMemberNames = new Set<Name>.from(_hierarchy
        .getInterfaceMembers(coreTypes.objectClass)
        .map((Member m) => m.name));
  }

  @override
  TreeNode visitLibrary(Library node) {
    if (_trace) {
      String external = node.isExternal ? " (external)" : "";
      print("[devirt] Processing library ${node.name}${external}");
    }
    return super.visitLibrary(node);
  }

  @override
  TreeNode visitMethodInvocation(MethodInvocation node) {
    node = super.visitMethodInvocation(node);

    Member target = node.interfaceTarget;
    if ((target != null) &&
        (target is! Field) &&
        !_objectMemberNames.contains(target.name)) {
      Member singleTarget =
          _hierarchy.getSingleTargetForInterfaceInvocation(target);
      if ((singleTarget is Procedure) && !singleTarget.isGetter) {
        if (_trace) {
          print("[devirt] Replacing ${target} with ${singleTarget}");
        }
        // TODO(dartbug.com/30480): add annotation to check for null
        return new DirectMethodInvocation(
            node.receiver, singleTarget, node.arguments);
      }
    }

    return node;
  }

  @override
  TreeNode visitPropertyGet(PropertyGet node) {
    node = super.visitPropertyGet(node);

    Member target = node.interfaceTarget;
    if ((target != null) && !_objectMemberNames.contains(target.name)) {
      Member singleTarget =
          _hierarchy.getSingleTargetForInterfaceInvocation(target);
      if (singleTarget != null) {
        if (_trace) {
          print("[devirt] Replacing ${target} with ${singleTarget}");
        }
        // TODO(dartbug.com/30480): add annotation to check for null
        return new DirectPropertyGet(node.receiver, singleTarget);
      }
    }

    return node;
  }

  @override
  TreeNode visitPropertySet(PropertySet node) {
    node = super.visitPropertySet(node);

    Member target = node.interfaceTarget;
    if (target != null) {
      Member singleTarget = _hierarchy
          .getSingleTargetForInterfaceInvocation(target, setter: true);
      if (singleTarget != null) {
        if (_trace) {
          print("[devirt] Replacing ${target} with ${singleTarget}");
        }
        // TODO(dartbug.com/30480): add annotation to check for null
        return new DirectPropertySet(node.receiver, singleTarget, node.value);
      }
    }

    return node;
  }
}
