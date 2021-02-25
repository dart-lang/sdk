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
import 'package:kernel/type_environment.dart'
    show StaticTypeContext, TypeEnvironment;

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
  StaticTypeContext _staticTypeContext;

  AnnotateWithStaticTypes(
      Component component, CoreTypes coreTypes, ClassHierarchy hierarchy)
      : _metadata = addRepositoryTo(component),
        env = new TypeEnvironment(coreTypes, hierarchy);

  @override
  defaultMember(Member node) {
    _staticTypeContext = new StaticTypeContext(node, env);
    super.defaultMember(node);
    _staticTypeContext = null;
  }

  void annotateWithType(TreeNode node, Expression receiver) {
    _metadata.mapping[node] = new CallSiteAttributesMetadata(
        receiverType: receiver.getStaticType(_staticTypeContext));
  }

  @override
  visitPropertySet(PropertySet node) {
    super.visitPropertySet(node);

    if (hasGenericCovariantParameters(node.interfaceTarget)) {
      annotateWithType(node, node.receiver);
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    // TODO(34162): We don't need to save the type here for calls, just whether
    // or not it's a statically-checked call.
    if (node.name.text == 'call' ||
        hasGenericCovariantParameters(node.interfaceTarget)) {
      annotateWithType(node, node.receiver);
    }
  }

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
    } else if (member is Field) {
      return member.isGenericCovariantImpl;
    }

    return false;
  }
}
