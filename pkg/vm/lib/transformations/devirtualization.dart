// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.cha_devirtualization;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchySubtypes, ClosedWorldClassHierarchy;

import '../metadata/direct_call.dart';

/// Devirtualization of method invocations based on the class hierarchy
/// analysis. Assumes strong mode and closed world.
Component transformComponent(CoreTypes coreTypes, Component component) {
  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}
  ClosedWorldClassHierarchy hierarchy = new ClassHierarchy(component, coreTypes,
      onAmbiguousSupertypes: ignoreAmbiguousSupertypes);
  final hierarchySubtypes = hierarchy.computeSubtypesInformation();
  new CHADevirtualization(coreTypes, component, hierarchy, hierarchySubtypes)
      .visitComponent(component);
  return component;
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
      CoreTypes coreTypes, Component component, ClassHierarchy hierarchy)
      : _metadata = new DirectCallMetadataRepository() {
    _objectMemberNames = new Set<Name>.from(hierarchy
        .getInterfaceMembers(coreTypes.objectClass)
        .map((Member m) => m.name));
    component.addMetadataRepository(_metadata);
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

    if (arguments.named.isNotEmpty || func.namedParameters.isNotEmpty) {
      final names = arguments.named.map((v) => v.name).toSet();
      for (var param in func.namedParameters) {
        final passed = names.remove(param.name);
        if (param.isRequired && !passed) {
          return false;
        }
      }
      if (names.isNotEmpty) {
        return false;
      }
    }

    if (arguments.types.isNotEmpty &&
        arguments.types.length != func.typeParameters.length) {
      return false;
    }

    return true;
  }

  bool hasExtraTargetForNull(DirectCallMetadata directCall) =>
      directCall.checkReceiverForNull &&
      _objectMemberNames.contains(directCall.target.name);

  DirectCallMetadata getDirectCall(TreeNode node, Member interfaceTarget,
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
      print("[devirt] Processing library ${node.name}");
    }
    super.visitLibrary(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final Member target = node.interfaceTarget;
    if (target != null && !isMethod(target)) {
      return;
    }

    final DirectCallMetadata directCall = getDirectCall(node, target);

    // TODO(alexmarkov): Convert _isLegalTargetForMethodInvocation()
    // check into an assertion once front-end implements all override checks.
    if ((directCall != null) &&
        isMethod(directCall.target) &&
        isLegalTargetForMethodInvocation(directCall.target, node.arguments) &&
        !hasExtraTargetForNull(directCall)) {
      makeDirectCall(node, target, directCall);
    }
  }

  @override
  visitPropertyGet(PropertyGet node) {
    super.visitPropertyGet(node);

    final Member target = node.interfaceTarget;
    if (target != null && !isFieldOrGetter(target)) {
      return;
    }

    final DirectCallMetadata directCall = getDirectCall(node, target);

    if ((directCall != null) &&
        isFieldOrGetter(directCall.target) &&
        !hasExtraTargetForNull(directCall)) {
      makeDirectCall(node, target, directCall);
    }
  }

  @override
  visitPropertySet(PropertySet node) {
    super.visitPropertySet(node);

    final Member target = node.interfaceTarget;
    final DirectCallMetadata directCall =
        getDirectCall(node, target, setter: true);
    if (directCall != null) {
      makeDirectCall(node, target, directCall);
    }
  }
}

/// Devirtualization based on the closed-world class hierarchy analysis.
class CHADevirtualization extends Devirtualization {
  final ClassHierarchySubtypes _hierarchySubtype;

  CHADevirtualization(CoreTypes coreTypes, Component component,
      ClosedWorldClassHierarchy hierarchy, this._hierarchySubtype)
      : super(coreTypes, component, hierarchy);

  @override
  DirectCallMetadata getDirectCall(TreeNode node, Member interfaceTarget,
      {bool setter = false}) {
    if (interfaceTarget == null) {
      return null;
    }
    Member singleTarget = _hierarchySubtype
        .getSingleTargetForInterfaceInvocation(interfaceTarget, setter: setter);
    if (singleTarget == null) {
      return null;
    }
    return new DirectCallMetadata(singleTarget, true);
  }
}
