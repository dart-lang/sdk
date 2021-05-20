// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/ast/mixin_super_invoked_names.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/constructor_initializer_resolver.dart';
import 'package:analyzer/src/summary2/default_value_resolver.dart';
import 'package:analyzer/src/summary2/element_builder.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_library_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/metadata_resolver.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';
import 'package:analyzer/src/summary2/scope.dart';
import 'package:analyzer/src/summary2/types_builder.dart';

class LibraryBuilder {
  final Linker linker;
  final Uri uri;
  final Reference reference;
  late final List<Reference> exports;

  late final LinkedLibraryContext context;

  late final LibraryElementImpl element;
  late final LibraryScope scope;

  /// Local declarations.
  final Scope localScope = Scope.top();

  /// The export scope of the library.
  final Scope exportScope = Scope.top();

  final List<Export> exporters = [];

  LibraryBuilder._(this.linker, this.uri, this.reference);

  void addExporters() {
    for (var element in element.exports) {
      var exportedLibrary = element.exportedLibrary;
      if (exportedLibrary == null) {
        continue;
      }

      var combinators = element.combinators.map((combinator) {
        if (combinator is ShowElementCombinator) {
          return Combinator.show(combinator.shownNames);
        } else if (combinator is HideElementCombinator) {
          return Combinator.hide(combinator.hiddenNames);
        } else {
          throw UnimplementedError();
        }
      }).toList();

      var exportedUri = exportedLibrary.source.uri;
      var exportedBuilder = linker.builders[exportedUri];

      var export = Export(this, exportedBuilder, combinators);
      if (exportedBuilder != null) {
        exportedBuilder.exporters.add(export);
      } else {
        var references = linker.elementFactory.exportsOfLibrary('$exportedUri');
        for (var reference in references) {
          var name = reference.name;
          if (reference.isSetter) {
            export.addToExportScope('$name=', reference);
          } else {
            export.addToExportScope(name, reference);
          }
        }
      }
    }
  }

  /// Add top-level declaration of the library units to the local scope.
  void addLocalDeclarations() {
    for (var linkingUnit in context.units) {
      var unitRef = reference.getChild('@unit').getChild(linkingUnit.uriStr);
      var typeAliasRef = unitRef.getChild('@typeAlias');
      for (var node in linkingUnit.unit.declarations) {
        if (node is ast.ClassDeclaration) {
          // Handled in ElementBuilder.
        } else if (node is ast.ClassTypeAlias) {
          // Handled in ElementBuilder.
        } else if (node is ast.EnumDeclarationImpl) {
          // Handled in ElementBuilder.
        } else if (node is ast.ExtensionDeclarationImpl) {
          // Handled in ElementBuilder.
        } else if (node is ast.FunctionDeclarationImpl) {
          // Handled in ElementBuilder.
        } else if (node is ast.FunctionTypeAlias) {
          var name = node.name.name;
          var reference = typeAliasRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);

          var element = TypeAliasElementImpl.forLinkedNodeFactory(
              linkingUnit.reference.element as CompilationUnitElementImpl,
              reference,
              node);
          element.isFunctionTypeAliasBased = true;
        } else if (node is ast.GenericTypeAlias) {
          var name = node.name.name;
          var reference = typeAliasRef.getChild(name);
          reference.node ??= node;

          localScope.declare(name, reference);

          TypeAliasElementImpl.forLinkedNodeFactory(
              linkingUnit.reference.element as CompilationUnitElementImpl,
              reference,
              node);
        } else if (node is ast.MixinDeclarationImpl) {
          // Handled in ElementBuilder.
        } else if (node is ast.TopLevelVariableDeclaration) {
          // Handled in ElementBuilder.
        } else {
          throw UnimplementedError('${node.runtimeType}');
        }
      }
    }
    if ('$uri' == 'dart:core') {
      localScope.declare('dynamic', reference.getChild('dynamic'));
      localScope.declare('Never', reference.getChild('Never'));
    }
  }

  /// Return `true` if the export scope was modified.
  bool addToExportScope(String name, Reference reference) {
    if (name.startsWith('_')) return false;
    if (reference.isPrefix) return false;

    var existing = exportScope.map[name];
    if (existing == reference) return false;

    // Ambiguous declaration detected.
    if (existing != null) return false;

    exportScope.map[name] = reference;
    return true;
  }

  void buildElement() {
    element = linker.elementFactory.createLibraryElementForLinking(context)
        as LibraryElementImpl;
  }

  void buildElements() {
    for (var unitContext in context.units) {
      var elementBuilder = ElementBuilder(
        libraryBuilder: this,
        unitReference: unitContext.reference,
        unitElement: unitContext.element,
      );
      if (unitContext.indexInLibrary == 0) {
        unitContext.unit.directives.accept(elementBuilder);
        elementBuilder.setExportsImports();
      }
      elementBuilder.buildDeclarationElements(unitContext.unit);
    }
  }

  void buildEnumChildren() {
    ElementBuilder.buildEnumChildren(linker, element);
  }

  void buildInitialExportScope() {
    localScope.forEach((name, reference) {
      addToExportScope(name, reference);
    });
  }

  void buildScope() {
    scope = element.scope as LibraryScope;
  }

  void collectMixinSuperInvokedNames() {
    for (var unitContext in context.units) {
      for (var declaration in unitContext.unit.declarations) {
        if (declaration is ast.MixinDeclaration) {
          var names = <String>{};
          var collector = MixinSuperInvokedNamesCollector(names);
          for (var executable in declaration.members) {
            if (executable is ast.MethodDeclaration) {
              executable.body.accept(collector);
            }
          }
          var element = declaration.declaredElement as MixinElementImpl;
          element.superInvokedNames = names.toList();
        }
      }
    }
  }

  void resolveConstructors() {
    ConstructorInitializerResolver(linker, element).resolve();
  }

  void resolveDefaultValues() {
    DefaultValueResolver(linker, element).resolve();
  }

  void resolveMetadata() {
    for (var unit in element.units) {
      var unitImpl = unit as CompilationUnitElementImpl;
      var resolver = MetadataResolver(linker, scope, unit);
      unitImpl.linkedNode!.accept(resolver);
    }
  }

  void resolveTypes(NodesToBuildType nodesToBuildType) {
    for (var unitContext in context.units) {
      var unitRef = reference.getChild('@unit');
      var unitReference = unitRef.getChild(unitContext.uriStr);
      var resolver = ReferenceResolver(
        linker,
        nodesToBuildType,
        linker.elementFactory,
        element,
        unitReference,
        unitContext.unit.featureSet.isEnabled(Feature.non_nullable),
        scope,
      );
      unitContext.unit.accept(resolver);
    }
  }

  void storeExportScope() {
    exports = exportScope.map.values.toList();
    linker.elementFactory.linkingExports['$uri'] = exports;

    // TODO(scheglov) store for serialization
    // for (var reference in exportScope.map.values) {
    //   var index = linkingBundleContext.indexOfReference(reference);
    //   context.exports.add(index);
    // }
  }

  static void build(Linker linker, LinkInputLibrary inputLibrary) {
    var uriStr = inputLibrary.uriStr;
    var reference = linker.rootReference.getChild(uriStr);

    var elementFactory = linker.elementFactory;
    var context = LinkedLibraryContext(elementFactory, uriStr, reference);

    var unitRef = reference.getChild('@unit');
    var unitIndex = 0;
    for (var inputUnit in inputLibrary.units) {
      var uriStr = inputUnit.uriStr;
      var reference = unitRef.getChild(uriStr);
      context.units.add(
        LinkedUnitContext(
          context,
          unitIndex++,
          inputUnit.partUriStr,
          uriStr,
          reference,
          inputUnit.isSynthetic,
          unit: inputUnit.unit,
        ),
      );
    }

    var builder = LibraryBuilder._(linker, inputLibrary.uri, reference);
    linker.builders[builder.uri] = builder;
    builder.context = context;
  }
}
