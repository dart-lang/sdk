// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
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
              linkingUnit.reference.element as CompilationUnitElementImpl,
              reference,
              node);
        } else if (node is ast.ClassTypeAlias) {
          var name = node.name.name;
          var reference = classRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);

          ClassElementImpl.forLinkedNode(
              linkingUnit.reference.element as CompilationUnitElementImpl,
              reference,
              node);
        } else if (node is ast.EnumDeclarationImpl) {
          var name = node.name.name;
          var reference = enumRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);

          EnumElementImpl.forLinkedNode(
              linkingUnit.reference.element as CompilationUnitElementImpl,
              reference,
              node);
        } else if (node is ast.ExtensionDeclarationImpl) {
          var name = node.name?.name;
          var refName = name ?? 'extension-${nextUnnamedExtensionId++}';

          var reference = extensionRef.getChild(refName);
          reference.node ??= node;

          if (name != null) {
            localScope.declare(name, reference);
          }

          ExtensionElementImpl.forLinkedNode(
              linkingUnit.reference.element as CompilationUnitElementImpl,
              reference,
              node);
        } else if (node is ast.FunctionDeclarationImpl) {
          var name = node.name.name;

          Reference reference;
          if (node.isGetter) {
            reference = getterRef.getChild(name);
            PropertyAccessorElementImpl.forLinkedNode(
                linkingUnit.reference.element as ElementImpl, reference, node);
          } else if (node.isSetter) {
            reference = setterRef.getChild(name);
            PropertyAccessorElementImpl.forLinkedNode(
                linkingUnit.reference.element as ElementImpl, reference, node);
          } else {
            reference = functionRef.getChild(name);
            FunctionElementImpl.forLinkedNode(
                linkingUnit.reference.element as ElementImpl, reference, node);
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
          var name = node.name.name;
          var reference = mixinRef.getChild(name);
          reference.node ??= node;
          localScope.declare(name, reference);

          MixinElementImpl.forLinkedNode(
              linkingUnit.reference.element as CompilationUnitElementImpl,
              reference,
              node);
        } else if (node is ast.TopLevelVariableDeclaration) {
          for (var variable in node.variables.variables) {
            var name = variable.name.name;

            var reference = variableRef.getChild(name);
            reference.node ??= node;

            if (variable.isConst) {
              var element = ConstTopLevelVariableElementImpl.forLinkedNode(
                  linkingUnit.reference.element as CompilationUnitElementImpl,
                  reference,
                  variable);
              element.constantInitializer = variable.initializer;
            } else {
              TopLevelVariableElementImpl.forLinkedNode(
                  linkingUnit.reference.element as CompilationUnitElementImpl,
                  reference,
                  variable);
            }

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
    var definingUnit = context.definingUnit;
    var elementBuilder = _ElementBuilder(
      libraryBuilder: this,
      unitElement: definingUnit.element,
    );
    definingUnit.unit.directives.accept(elementBuilder);
    elementBuilder.setExportsImports();
  }

  void buildElement() {
    element = linker.elementFactory.createLibraryElementForLinking(context)
        as LibraryElementImpl;
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

class _ElementBuilder extends ThrowingAstVisitor<void> {
  final LibraryBuilder _libraryBuilder;
  final CompilationUnitElementImpl _unitElement;

  final _exports = <ExportElement>[];
  final _imports = <ImportElement>[];
  var _hasCoreImport = false;

  _ElementBuilder({
    required LibraryBuilder libraryBuilder,
    required CompilationUnitElementImpl unitElement,
  })  : _libraryBuilder = libraryBuilder,
        _unitElement = unitElement;

  LibraryElementImpl get _libraryElement => _libraryBuilder.element;

  Linker get _linker => _libraryBuilder.linker;

  /// This method should be invoked after visiting directive nodes, it
  /// will set created exports and imports into [_libraryElement].
  void setExportsImports() {
    _libraryElement.exports = _exports;

    if (!_hasCoreImport) {
      var dartCore = _linker.elementFactory.libraryOfUri2('dart:core');
      _imports.add(
        ImportElementImpl(-1)
          ..importedLibrary = dartCore
          ..isSynthetic = true
          ..uri = 'dart:core',
      );
    }
    _libraryElement.imports = _imports;
  }

  @override
  void visitExportDirective(covariant ast.ExportDirectiveImpl node) {
    var element = ExportElementImpl(node.keyword.offset);
    element.combinators = _buildCombinators(node.combinators);
    element.exportedLibrary = _selectLibrary(node);
    element.metadata = _buildAnnotations(node.metadata);
    element.uri = node.uri.stringValue;

    node.element = element;
    _exports.add(element);
  }

  @override
  void visitImportDirective(covariant ast.ImportDirectiveImpl node) {
    var element = ImportElementImpl(node.keyword.offset);
    element.combinators = _buildCombinators(node.combinators);
    element.importedLibrary = _selectLibrary(node);
    element.isDeferred = node.deferredKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    element.uri = node.uri.stringValue;

    var prefixNode = node.prefix;
    if (prefixNode != null) {
      element.prefix = PrefixElementImpl(
        prefixNode.name,
        prefixNode.offset,
        reference: _libraryBuilder.reference
            .getChild('@prefix')
            .getChild(prefixNode.name),
      );
    }

    node.element = element;

    _imports.add(element);
    if (!_hasCoreImport) {
      if (node.uri.stringValue == 'dart:core') {
        _hasCoreImport = true;
      }
    }
  }

  @override
  void visitLibraryDirective(ast.LibraryDirective node) {}

  @override
  void visitPartDirective(ast.PartDirective node) {}

  @override
  void visitPartOfDirective(ast.PartOfDirective node) {
    _libraryElement.hasPartOfDirective = true;
  }

  List<ElementAnnotation> _buildAnnotations(
    List<ast.Annotation> nodeList,
  ) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotation>[];
    }

    var annotations = <ElementAnnotation>[];
    for (int i = 0; i < length; i++) {
      var ast = nodeList[i];
      annotations.add(ElementAnnotationImpl(_unitElement)
        ..annotationAst = ast
        ..element = ast.element);
    }
    return annotations;
  }

  Uri? _selectAbsoluteUri(ast.NamespaceDirective directive) {
    var relativeUriStr = _selectRelativeUri(
      directive.configurations,
      directive.uri.stringValue,
    );
    if (relativeUriStr == null) {
      return null;
    }
    var relativeUri = Uri.parse(relativeUriStr);
    return resolveRelativeUri(_libraryBuilder.uri, relativeUri);
  }

  LibraryElement? _selectLibrary(ast.NamespaceDirective node) {
    try {
      var uri = _selectAbsoluteUri(node);
      return _linker.elementFactory.libraryOfUri('$uri');
    } on FormatException {
      return null;
    }
  }

  String? _selectRelativeUri(
    List<ast.Configuration> configurations,
    String? defaultUri,
  ) {
    for (var configuration in configurations) {
      var name = configuration.name.components.join('.');
      var value = configuration.value?.stringValue ?? 'true';
      if (_linker.declaredVariables.get(name) == value) {
        return configuration.uri.stringValue;
      }
    }
    return defaultUri;
  }

  static List<NamespaceCombinator> _buildCombinators(
    List<ast.Combinator> combinators,
  ) {
    return combinators.map((node) {
      if (node is ast.HideCombinator) {
        return HideElementCombinatorImpl()
          ..hiddenNames = node.hiddenNames.nameList;
      }
      if (node is ast.ShowCombinator) {
        return ShowElementCombinatorImpl()
          ..shownNames = node.shownNames.nameList;
      }
      throw UnimplementedError('${node.runtimeType}');
    }).toList();
  }
}

extension on Iterable<ast.SimpleIdentifier> {
  List<String> get nameList {
    return map((e) => e.name).toList();
  }
}
