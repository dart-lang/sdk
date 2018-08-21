// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This transformation annotates call sites with the receiver type.
// This is done to avoid reimplementing [Expression.getStaticType] in
// C++.
// We don't annotate all call-sites, but only those where VM could benefit from
// knowing static type of the receiver.
library vm.transformations.call_site_annotator;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart' show TypeEnvironment;

import '../metadata/call_site_attributes.dart';

CallSiteAttributesMetadataRepository addRepositoryTo(Component component) {
  return component.metadata.putIfAbsent(
      CallSiteAttributesMetadataRepository.repositoryTag,
      () => new CallSiteAttributesMetadataRepository());
}

void transformLibraries(Component component, List<Library> libraries,
    CoreTypes coreTypes, ClassHierarchy hierarchy) {
  final transformer =
      new AnnotateWithStaticTypes(component, coreTypes, hierarchy);
  libraries.forEach(transformer.visitLibrary);
}

class AnnotateWithStaticTypes extends RecursiveVisitor<Null> {
  final CallSiteAttributesMetadataRepository _metadata;
  final TypeEnvironment env;

  AnnotateWithStaticTypes(
      Component component, CoreTypes coreTypes, ClassHierarchy hierarchy)
      : _metadata = addRepositoryTo(component),
        env = new TypeEnvironment(coreTypes, hierarchy, strongMode: true);

  @override
  visitProcedure(Procedure proc) {
    if (!proc.isStatic) {
      env.thisType = proc.enclosingClass?.thisType;
    }
    super.visitProcedure(proc);
    env.thisType = null;
  }

  @override
  visitConstructor(Constructor proc) {
    env.thisType = proc.enclosingClass?.thisType;
    super.visitConstructor(proc);
    env.thisType = null;
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    if (shouldAnnotate(node)) {
      _metadata.mapping[node] = new CallSiteAttributesMetadata(
          receiverType: node.receiver.getStaticType(env));
    }
  }

  // TODO(vegorov) handle setters as well.
  // TODO(34162): We don't need to save the type here, just whether or not it's
  // a statically-checked call.
  static bool shouldAnnotate(MethodInvocation node) =>
      (node.interfaceTarget != null &&
          hasGenericCovariantParameters(node.interfaceTarget)) ||
      node.name.name == "call";

  /// Return [true] if the given list of [VariableDeclaration] contains
  /// any annotated with generic-covariant-impl.
  static bool containsGenericCovariantImpl(List<VariableDeclaration> decls) =>
      decls.any((p) => p.isGenericCovariantImpl);

  /// Returns [true] if the given [member] has any parameters annotated with
  /// generic-covariant-impl attribute.
  static bool hasGenericCovariantParameters(Member member) {
    if (member is Procedure) {
      return containsGenericCovariantImpl(
              member.function.positionalParameters) ||
          containsGenericCovariantImpl(member.function.namedParameters);
    }

    return false;
  }
}
