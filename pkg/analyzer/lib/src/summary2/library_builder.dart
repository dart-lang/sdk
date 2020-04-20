// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/ast/mixin_super_invoked_names.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart' show LibraryScope;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/constructor_initializer_resolver.dart';
import 'package:analyzer/src/summary2/default_value_resolver.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
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
  final LinkedNodeLibraryBuilder node;

  LinkedLibraryContext context;

  LibraryElementImpl element;
  LibraryScope scope;

  /// Local declarations.
  final Scope localScope = Scope.top();

  /// The export scope of the library.
  final Scope exportScope = Scope.top();

  final List<Export> exporters = [];

  LibraryBuilder(this.linker, this.uri, this.reference, this.node);

  void addExporters() {
    var unitContext = context.units[0];
    for (var directive in unitContext.unit_withDirectives.directives) {
      if (directive is ast.ExportDirective) {
        Uri uri;
        try {
          uri = _selectAbsoluteUri(directive);
          if (uri == null) continue;
        } on FormatException {
          continue;
        }

        var combinators = directive.combinators.map((node) {
          if (node is ast.ShowCombinator) {
            var nameList = node.shownNames.map((i) => i.name).toList();
            return Combinator.show(nameList);
          } else if (node is ast.HideCombinator) {
            var nameList = node.hiddenNames.map((i) => i.name).toList();
            return Combinator.hide(nameList);
          }
          return null;
        }).toList();

        var exported = linker.builders[uri];
        var export = Export(this, exported, combinators);
        if (exported != null) {
          exported.exporters.add(export);
        } else {
          var references = linker.elementFactory.exportsOfLibrary('$uri');
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
  }

  /// Add top-level declaration of the library units to the local scope.
  void addLocalDeclarations() {
    for (var unitContext in context.units) {
      var unitRef = reference.getChild('@unit').getChild(unitContext.uriStr);
      var classRef = unitRef.getChild('@class');
      var enumRef = unitRef.getChild('@enum');
      var extensionRef = unitRef.getChild('@extension');
      var functionRef = unitRef.getChild('@function');
      var mixinRef = unitRef.getChild('@mixin');
      var typeAliasRef = unitRef.getChild('@typeAlias');
      var getterRef = unitRef.getChild('@getter');
      var setterRef = unitRef.getChild('@setter');
      var variableRef = unitRef.getChild('@variable');
      var nextUnnamedExtensionId = 0;
      for (var node in unitContext.unit.declarations) {
        if (node is ast.ClassDeclaration) {
          var name = node.name.name;
          var reference = classRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);
        } else if (node is ast.ClassTypeAlias) {
          var name = node.name.name;
          var reference = classRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);
        } else if (node is ast.EnumDeclaration) {
          var name = node.name.name;
          var reference = enumRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);
        } else if (node is ast.ExtensionDeclaration) {
          var name = node.name?.name;
          var refName = name ?? 'extension-${nextUnnamedExtensionId++}';
          LazyExtensionDeclaration.get(node).setRefName(refName);

          var reference = extensionRef.getChild(refName);
          reference.node ??= node;

          if (name != null) {
            localScope.declare(name, reference);
          }
        } else if (node is ast.FunctionDeclaration) {
          var name = node.name.name;

          Reference containerRef;
          if (node.isGetter) {
            containerRef = getterRef;
          } else if (node.isSetter) {
            containerRef = setterRef;
          } else {
            containerRef = functionRef;
          }

          var reference = containerRef.getChild(name);
          reference.node ??= node;

          if (node.isSetter) {
            localScope.declare('$name=', reference);
          } else {
            localScope.declare(name, reference);
          }
        } else if (node is ast.FunctionTypeAlias) {
          var name = node.name.name;
          var reference = typeAliasRef.getChild(name);
          reference.node ??= node;

          localScope.declare(name, reference);
        } else if (node is ast.GenericTypeAlias) {
          var name = node.name.name;
          var reference = typeAliasRef.getChild(name);
          reference.node = node;

          localScope.declare(name, reference);
        } else if (node is ast.MixinDeclaration) {
          var name = node.name.name;
          var reference = mixinRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);
        } else if (node is ast.TopLevelVariableDeclaration) {
          for (var variable in node.variables.variables) {
            var name = variable.name.name;

            var reference = variableRef.getChild(name);
            reference.node ??= node;

            var getter = getterRef.getChild(name);
            localScope.declare(name, getter);

            if (!variable.isConst && !variable.isFinal) {
              var setter = setterRef.getChild(name);
              localScope.declare('$name=', setter);
            }
          }
        } else {
          // TODO(scheglov) implement
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
    element = linker.elementFactory.libraryOfUri('$uri');
    scope = LibraryScope(element);
  }

  void buildInitialExportScope() {
    localScope.forEach((name, reference) {
      addToExportScope(name, reference);
    });
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
          var lazy = LazyMixinDeclaration.get(declaration);
          lazy.setSuperInvokedNames(names.toList());
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
    for (CompilationUnitElementImpl unit in element.units) {
      var resolver = MetadataResolver(linker, scope, unit);
      unit.linkedNode.accept(resolver);
    }
  }

  void resolveTypes(NodesToBuildType nodesToBuildType) {
    for (var unitContext in context.units) {
      var unitRef = reference.getChild('@unit');
      var unitReference = unitRef.getChild(unitContext.uriStr);
      var resolver = ReferenceResolver(
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

  void resolveUriDirectives() {
    var unitContext = context.units[0];
    for (var directive in unitContext.unit.directives) {
      if (directive is ast.NamespaceDirective) {
        try {
          var uri = _selectAbsoluteUri(directive);
          if (uri != null) {
            LazyDirective.setSelectedUri(directive, '$uri');
          }
        } on FormatException {
          // ignored
        }
      }
    }
  }

  void storeExportScope() {
    var linkingBundleContext = linker.linkingBundleContext;
    for (var reference in exportScope.map.values) {
      var index = linkingBundleContext.indexOfReference(reference);
      node.exports.add(index);
    }
  }

  Uri _selectAbsoluteUri(ast.NamespaceDirective directive) {
    var relativeUriStr = _selectRelativeUri(
      directive.configurations,
      directive.uri.stringValue,
    );
    if (relativeUriStr == null) {
      return null;
    }
    var relativeUri = Uri.parse(relativeUriStr);
    return resolveRelativeUri(this.uri, relativeUri);
  }

  String _selectRelativeUri(
    List<ast.Configuration> configurations,
    String defaultUri,
  ) {
    for (var configuration in configurations) {
      var name = configuration.name.components.join('.');
      var value = configuration.value?.stringValue ?? 'true';
      if (linker.declaredVariables.get(name) == value) {
        return configuration.uri.stringValue;
      }
    }
    return defaultUri;
  }

  static void build(Linker linker, LinkInputLibrary inputLibrary) {
    var libraryUri = inputLibrary.source.uri;
    var libraryUriStr = '$libraryUri';
    var libraryReference = linker.rootReference.getChild(libraryUriStr);

    var libraryNode = LinkedNodeLibraryBuilder(
      uriStr: libraryUriStr,
    );

    var definingUnit = inputLibrary.units[0].unit;
    for (var directive in definingUnit.directives) {
      if (directive is ast.LibraryDirective) {
        var name = directive.name;
        libraryNode.name = name.components.map((id) => id.name).join('.');
        libraryNode.nameOffset = name.offset;
        libraryNode.nameLength = name.length;
        break;
      }
    }

    var builder = LibraryBuilder(
      linker,
      libraryUri,
      libraryReference,
      libraryNode,
    );
    linker.builders[builder.uri] = builder;

    builder.context = linker.bundleContext.addLinkingLibrary(
      libraryUriStr,
      libraryNode,
      inputLibrary,
    );
  }
}

class UnitBuilder {
  final Uri uri;
  final LinkedUnitContext context;
  final LinkedNode node;

  UnitBuilder(this.uri, this.context, this.node);
}
