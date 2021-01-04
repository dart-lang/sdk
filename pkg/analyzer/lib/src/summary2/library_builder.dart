// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/mixin_super_invoked_names.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/constructor_initializer_resolver.dart';
import 'package:analyzer/src/summary2/default_value_resolver.dart';
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
  List<Reference> exports;

  LinkedLibraryContext context;

  LibraryElementImpl element;
  LibraryScope scope;

  /// Local declarations.
  final Scope localScope = Scope.top();

  /// The export scope of the library.
  final Scope exportScope = Scope.top();

  final List<Export> exporters = [];

  LibraryBuilder._(this.linker, this.uri, this.reference);

  void addExporters() {
    var unitContext = context.definingUnit;
    for (var directive in unitContext.unit.directives) {
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
    for (var linkingUnit in context.units) {
      var unitRef = reference.getChild('@unit').getChild(linkingUnit.uriStr);
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
      for (var node in linkingUnit.unit.declarations) {
        if (node is ast.ClassDeclaration) {
          var name = node.name.name;
          var reference = classRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);

          ClassElementImpl.forLinkedNode(
              linkingUnit.reference.element, reference, node);
        } else if (node is ast.ClassTypeAlias) {
          var name = node.name.name;
          var reference = classRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);

          ClassElementImpl.forLinkedNode(
              linkingUnit.reference.element, reference, node);
        } else if (node is ast.EnumDeclaration) {
          var name = node.name.name;
          var reference = enumRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);

          EnumElementImpl.forLinkedNode(
              linkingUnit.reference.element, reference, node);
        } else if (node is ast.ExtensionDeclaration) {
          var name = node.name?.name;
          var refName = name ?? 'extension-${nextUnnamedExtensionId++}';

          var reference = extensionRef.getChild(refName);
          reference.node ??= node;

          if (name != null) {
            localScope.declare(name, reference);
          }

          ExtensionElementImpl.forLinkedNode(
              linkingUnit.reference.element, reference, node);
        } else if (node is ast.FunctionDeclaration) {
          var name = node.name.name;

          Reference reference;
          if (node.isGetter) {
            reference = getterRef.getChild(name);
            PropertyAccessorElementImpl.forLinkedNode(
                linkingUnit.reference.element, reference, node);
          } else if (node.isSetter) {
            reference = setterRef.getChild(name);
            PropertyAccessorElementImpl.forLinkedNode(
                linkingUnit.reference.element, reference, node);
          } else {
            reference = functionRef.getChild(name);
            FunctionElementImpl.forLinkedNode(
                linkingUnit.reference.element, reference, node);
          }

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

          TypeAliasElementImpl.forLinkedNodeFactory(
              linkingUnit.reference.element, reference, node);
        } else if (node is ast.GenericTypeAlias) {
          var name = node.name.name;
          var reference = typeAliasRef.getChild(name);
          reference.node ??= node;

          localScope.declare(name, reference);

          TypeAliasElementImpl.forLinkedNodeFactory(
              linkingUnit.reference.element, reference, node);
        } else if (node is ast.MixinDeclaration) {
          var name = node.name.name;
          var reference = mixinRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);

          MixinElementImpl.forLinkedNode(
              linkingUnit.reference.element, reference, node);
        } else if (node is ast.TopLevelVariableDeclaration) {
          for (var variable in node.variables.variables) {
            var name = variable.name.name;

            var reference = variableRef.getChild(name);
            reference.node ??= node;

            TopLevelVariableElementImpl.forLinkedNode(
                linkingUnit.reference.element, reference, variable);

            var getter = getterRef.getChild(name);
            localScope.declare(name, getter);

            if (!variable.isConst && !variable.isFinal) {
              var setter = setterRef.getChild(name);
              localScope.declare('$name=', setter);
            }
          }
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

  void buildDirectives() {
    var exports = <ExportElement>[];
    var imports = <ImportElement>[];
    var hasCoreImport = false;

    // Build elements directives in all units.
    // Store elements only for the defining unit of the library.
    var isDefiningUnit = true;
    for (var unitContext in context.units) {
      for (var node in unitContext.unit.directives) {
        if (node is ast.ExportDirective) {
          var exportElement = ExportElementImpl.forLinkedNode(element, node);
          if (isDefiningUnit) {
            exports.add(exportElement);
          }
        } else if (node is ast.ImportDirective) {
          var importElement = ImportElementImpl.forLinkedNode(element, node);
          if (isDefiningUnit) {
            imports.add(importElement);
            hasCoreImport |= importElement.importedLibrary?.isDartCore ?? false;
          }
        }
      }
      isDefiningUnit = false;
    }

    element.exports = exports;

    if (!hasCoreImport) {
      var dartCore = linker.elementFactory.libraryOfUri('dart:core');
      imports.add(
        ImportElementImpl(-1)
          ..importedLibrary = dartCore
          ..isSynthetic = true
          ..uri = 'dart:core',
      );
    }
    element.imports = imports;
  }

  void buildElement() {
    linker.elementFactory.createLibraryElementForLinking(context);
    element = reference.element;
    assert(element != null);
  }

  void buildInitialExportScope() {
    localScope.forEach((name, reference) {
      addToExportScope(name, reference);
    });
  }

  void buildScope() {
    scope = element.scope;
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
            var library = linker.elementFactory.libraryOfUri('$uri');
            if (directive is ast.ExportDirective) {
              var exportElement = directive.element as ExportElementImpl;
              exportElement.exportedLibrary = library;
            } else if (directive is ast.ImportDirective) {
              var importElement = directive.element as ImportElementImpl;
              importElement.importedLibrary = library;
            }
          }
        } on FormatException {
          // ignored
        }
      }
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

  Uri _selectAbsoluteUri(ast.NamespaceDirective directive) {
    var relativeUriStr = _selectRelativeUri(
      directive.configurations,
      directive.uri.stringValue,
    );
    if (relativeUriStr == null) {
      return null;
    }
    var relativeUri = Uri.parse(relativeUriStr);
    return resolveRelativeUri(uri, relativeUri);
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
    var uriStr = inputLibrary.uriStr;
    var reference = linker.rootReference.getChild(uriStr);

    var elementFactory = linker.elementFactory;
    var context = LinkedLibraryContext(elementFactory, uriStr, reference);

    var unitRef = reference.getChild('@unit');
    var unitIndex = 0;
    for (var inputUnit in inputLibrary.units) {
      var source = inputUnit.source;
      var uriStr = source != null ? '${source.uri}' : '';
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
          unitReader: null,
        ),
      );
    }

    var builder = LibraryBuilder._(linker, inputLibrary.uri, reference);
    linker.builders[builder.uri] = builder;
    builder.context = context;
  }
}
