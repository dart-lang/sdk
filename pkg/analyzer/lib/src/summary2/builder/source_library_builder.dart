// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/builder/prefix_builder.dart';
import 'package:analyzer/src/summary2/declaration.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';
import 'package:analyzer/src/summary2/scope.dart';
import 'package:analyzer/src/summary2/top_level_inference.dart';

class SourceLibraryBuilder {
  final Linker linker;
  final Uri uri;
  final Reference reference;
  final LinkedNodeLibraryBuilder node;
  final List<UnitBuilder> units = [];

  /// The import scope of the library.
  final Scope importScope;

  /// Local declarations, enclosed by [importScope].
  final Scope scope;

  /// The export scope of the library.
  final Scope exportScope = Scope.top();

  SourceLibraryBuilder(Linker linker, Uri uri, Reference reference,
      LinkedNodeLibraryBuilder node)
      : this._(linker, uri, reference, node, Scope.top());

  SourceLibraryBuilder._(
      this.linker, this.uri, this.reference, this.node, this.importScope)
      : scope = Scope(importScope, <String, Declaration>{});

  void addImportsToScope() {
    // TODO
    var hasDartCore = false;
    for (var directive in units[0].node.compilationUnit_directives) {
      if (directive.kind == LinkedNodeKind.importDirective) {
        var uriStr = directive.uriBasedDirective_uriContent;
        var importedLibrary = reference.parent.getChild(uriStr);
        // TODO(scheglov) resolve URI as relative
        // TODO(scheglov) prefix
        // TODO(scheglov) combinators
      }
    }
    if (!hasDartCore) {
      var references = linker.elementFactory.exportsOfLibrary('dart:core');
      for (var reference in references) {
        var name = reference.name;
        importScope.declare(name, Declaration(name, reference));
      }
    }
  }

  /// Add top-level declaration of the library units to the local scope.
  void addLocalDeclarations() {
    for (var unit in units) {
      var unitRef = reference.getChild('@unit').getChild('${unit.uri}');
      var classRef = unitRef.getChild('@class');
      var functionRef = unitRef.getChild('@function');
      var typeAliasRef = unitRef.getChild('@typeAlias');
      var getterRef = unitRef.getChild('@getter');
      var setterRef = unitRef.getChild('@setter');
      var variableRef = unitRef.getChild('@variable');
      for (var node in unit.node.compilationUnit_declarations) {
        if (node.kind == LinkedNodeKind.classDeclaration ||
            node.kind == LinkedNodeKind.classTypeAlias) {
          var name = unit.context.getUnitMemberName(node);
          var reference = classRef.getChild(name);
          reference.node = node;
          var declaration = Declaration(name, reference);
          scope.declare(name, declaration);
        } else if (node.kind == LinkedNodeKind.functionDeclaration) {
          var name = unit.context.getUnitMemberName(node);

          Reference containerRef;
          if (unit.context.isGetterFunction(node)) {
            containerRef = getterRef;
          } else if (unit.context.isSetterFunction(node)) {
            containerRef = setterRef;
          } else {
            containerRef = functionRef;
          }

          var reference = containerRef.getChild(name);
          reference.node = node;

          var declaration = Declaration(name, reference);
          scope.declare(name, declaration);
        } else if (node.kind == LinkedNodeKind.functionTypeAlias) {
          var name = unit.context.getUnitMemberName(node);
          var reference = typeAliasRef.getChild(name);
          reference.node = node;

          var declaration = Declaration(name, reference);
          scope.declare(name, declaration);
        } else if (node.kind == LinkedNodeKind.genericTypeAlias) {
          var name = unit.context.getUnitMemberName(node);
          var reference = typeAliasRef.getChild(name);
          reference.node = node;

          var declaration = Declaration(name, reference);
          scope.declare(name, declaration);
        } else if (node.kind == LinkedNodeKind.topLevelVariableDeclaration) {
          var variableList = node.topLevelVariableDeclaration_variableList;
          for (var variable in variableList.variableDeclarationList_variables) {
            var name = unit.context.getVariableName(variable);

            var reference = variableRef.getChild(name);
            reference.node = node;

            var getter = getterRef.getChild(name);
            scope.declare(name, Declaration(name, getter));

            if (!unit.context.isFinal(variable)) {
              var setter = setterRef.getChild(name);
              scope.declare('$name=', Declaration(name, setter));
            }
          }
        } else {
          // TODO(scheglov) implement
          throw UnimplementedError('${node.kind}');
        }
      }
    }
  }

  void addSyntheticConstructors() {
    for (var declaration in scope.map.values) {
      var reference = declaration.reference;
      var node = reference.node;
      if (node == null) continue;
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
          constructorDeclaration_body: LinkedNodeBuilder.emptyFunctionBody(),
        )..isSynthetic = true,
      );
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

  void buildInitialExportScope() {
    scope.forEach((name, declaration) {
      addToExportScope(name, declaration);
    });
  }

  void performTopLevelInference() {
    for (var unit in units) {
      TopLevelInference(linker, reference, unit).infer();
    }
  }

  void resolveTypes() {
    for (var unit in units) {
      var unitReference = reference.getChild('@unit').getChild('${unit.uri}');
      ReferenceResolver(linker, unit, scope, unitReference).resolve();
    }
  }

  void storeExportScope() {
    for (var declaration in exportScope.map.values) {
      var index = linker.indexOfReference(declaration.reference);
      node.exports.add(index);
    }
  }

  static void build(Linker linker, Source librarySource,
      Map<Source, ast.CompilationUnit> libraryUnits) {
    var libraryUriStr = librarySource.uri.toString();
    var libraryReference = linker.rootReference.getChild(libraryUriStr);

    var unitNodeList = <LinkedNodeUnitBuilder>[];
    var libraryNode = LinkedNodeLibraryBuilder(
      units: unitNodeList,
      uriStr: libraryUriStr,
    );

    var builder = SourceLibraryBuilder(
      linker,
      librarySource.uri,
      libraryReference,
      libraryNode,
    );

    ast.CompilationUnit definingUnit;
    for (var unitSource in libraryUnits.keys) {
      var unit = libraryUnits[unitSource];
      definingUnit ??= unit;

      var writer = AstBinaryWriter();
      var unitNode = writer.writeNode(unit);

      var unitContext = LinkedUnitContext(linker.bundleContext, writer.tokens);
      builder.units.add(
        UnitBuilder(unitSource.uri, unitContext, unitNode),
      );

      libraryNode.units.add(
        LinkedNodeUnitBuilder(
          uriStr: '${unitSource.uri}',
          tokens: writer.tokens,
          node: unitNode,
        ),
      );

      if (libraryUriStr == 'dart:core') {
        for (var declaration in unitNode.compilationUnit_declarations) {
          if (declaration.kind == LinkedNodeKind.classDeclaration) {
            var nameNode = declaration.namedCompilationUnitMember_name;
            if (unitContext.getSimpleName(nameNode) == 'Object') {
              declaration.classDeclaration_isDartObject = true;
            }
          }
        }
      }
    }

    for (var directive in definingUnit.directives) {
      if (directive is ast.LibraryDirective) {
        var name = directive.name;
        libraryNode.name = name.components.map((id) => id.name).join('.');
        libraryNode.nameOffset = name.offset;
        libraryNode.nameLength = name.length;
        break;
      }
    }

    linker.linkingLibraries.add(libraryNode);
    linker.builders.add(builder);
  }
}

class UnitBuilder {
  final Uri uri;
  final LinkedUnitContext context;
  final LinkedNode node;

  UnitBuilder(this.uri, this.context, this.node);
}
