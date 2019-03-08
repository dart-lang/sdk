// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/builder/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

class SourceLibraryBuilder extends LibraryBuilder {
  final Linker linker;
  final LinkedBundleContext bundleContext;
  final Reference reference;

  SourceLibraryBuilder(this.linker, this.bundleContext, Uri uri, this.reference)
      : super(uri, reference);

  void addSyntheticConstructors() {
    for (var declaration in scope.map.values) {
      var reference = declaration.reference;
      var node = reference.node;

      if (node.kind != LinkedNodeKind.classDeclaration) continue;

      // Skip the class if it already has a constructor.
      if (node.classOrMixinDeclaration_members
          .any((n) => n.kind == LinkedNodeKind.constructorDeclaration)) {
        continue;
      }

      node.classOrMixinDeclaration_members.add(
        LinkedNodeBuilder.constructorDeclaration(
          constructorDeclaration_parameters:
              LinkedNodeBuilder.formalParameterList(),
        )..isSynthetic = true,
      );
    }
  }

  void resolveTypes() {
    for (var unit in units) {
      for (var node in unit.node.compilationUnit_declarations) {
        if (node.kind == LinkedNodeKind.classDeclaration) {
          var extendsClause = node.classDeclaration_extendsClause;
          if (extendsClause != null) {
            _resolveTypeName(
              unit.context,
              extendsClause.extendsClause_superclass,
            );
          }

          var withClause = node.classDeclaration_withClause;
          if (withClause != null) {
            for (var typeName in withClause.withClause_mixinTypes) {
              _resolveTypeName(unit.context, typeName);
            }
          }

          var implementsClause = node.classOrMixinDeclaration_implementsClause;
          if (implementsClause != null) {
            for (var typeName in implementsClause.implementsClause_interfaces) {
              _resolveTypeName(unit.context, typeName);
            }
          }

          // TODO(scheglov) type parameters
          assert(node.classOrMixinDeclaration_typeParameters == null);
        } else {
          // TODO(scheglov) implement
          throw UnimplementedError();
        }
      }
    }
  }

  int _referenceIndex(Reference reference) {
    if (reference.index == null) {
      reference.index = linker.references.length;
      linker.references.add(reference);
    }
    return reference.index;
  }

  void _resolveTypeName(LinkedUnitContext context, LinkedNodeBuilder typeName) {
    var identifier = typeName.typeName_name;
    if (identifier.kind == LinkedNodeKind.simpleIdentifier) {
      var name = context.getSimpleName(identifier);
      var reference = exportScope.lookup(name).reference;
      var referenceIndex = _referenceIndex(reference);
      identifier.simpleIdentifier_element = referenceIndex;
      if (reference.isClass) {
        typeName.typeName_type = LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.interface,
          interfaceClass: referenceIndex,
        );
        // TODO(scheglov) type arguments
      } else {
        // TODO(scheglov) set Object? keep unresolved?
        throw UnimplementedError();
      }
    } else {
      // TODO(scheglov) implement
      throw UnimplementedError();
    }
  }
}
