// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/builder/prefix_builder.dart';
import 'package:analyzer/src/summary2/declaration.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/scope.dart';

class LibraryBuilder {
  final Uri uri;
  final Reference reference;
  final List<UnitBuilder> units = [];

  /// The import scope of the library.
  final Scope importScope;

  /// Local declarations, enclosed by [importScope].
  final Scope scope;

  /// The export scope of the library.
  final Scope exportScope = Scope.top();

  LibraryBuilder(Uri uri, Reference reference)
      : this._(uri, reference, Scope.top());

  LibraryBuilder._(this.uri, this.reference, this.importScope)
      : scope = Scope(importScope, <String, Declaration>{});

  /// Add top-level declaration of the library units to the local scope.
  void addLocalDeclarations() {
    for (var unit in units) {
      for (var node in unit.node.compilationUnit_declarations) {
        if (node.kind == LinkedNodeKind.classDeclaration) {
          var name = unit.context.getUnitMemberName(node);
          var reference = this.reference.getChild('@class').getChild(name);
          reference.node = node;
          var declaration = Declaration(name, reference);
          scope.declare(name, declaration);
        } else {
          // TODO(scheglov) implement
          throw UnimplementedError();
        }
      }
    }
  }

  /// Return `true` if the export scope was modified.
  bool addToExportScope(String name, Declaration declaration) {
    if (name.startsWith('_')) return false;
    if (declaration is PrefixBuilder) return false;

    var existing = exportScope.map[name];
    if (existing == declaration) return false;

    // Ambiguous declaration detected.
    if (existing != null) return false;

    exportScope.map[name] = declaration;
    return true;
  }

  void addUnit(LinkedUnitContext context, LinkedNode node) {
    units.add(UnitBuilder(context, node));
  }

  void buildInitialExportScope() {
    // TODO(scheglov) Maybe store export scopes in summaries?
    scope.forEach((name, declaration) {
      addToExportScope(name, declaration);
    });
  }
}

class UnitBuilder {
  final LinkedUnitContext context;
  final LinkedNode node;

  UnitBuilder(this.context, this.node);
}
