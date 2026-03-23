// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart'
    hide Element;
import 'package:language_server_protocol/protocol_generated.dart' show Position;

class FlutterWidgetPreviewDetector {
  final _namespaceAllocator = NamespaceAllocator();

  Map<String, String> get namespaces => _namespaceAllocator.namespaces;

  /// Search for functions annotated with `@Preview` in the current project.
  void findPreviews(
    ResolvedUnitResult resolvedUnit, {
    Map<Uri, LibraryPreviewNode>? graph,
  }) {
    var lib = resolvedUnit.libraryElement;

    var previewsForLibrary = graph != null
        ? graph.putIfAbsent(
            lib.uri,
            () => LibraryPreviewNode(
              library: lib,
              namespaceAllocator: _namespaceAllocator,
            ),
          )
        : LibraryPreviewNode(
            library: lib,
            namespaceAllocator: _namespaceAllocator,
          );

    // Track errors in the current file.
    previewsForLibrary.populateErrorsForFile(
      uri: resolvedUnit.uri,
      diagnostics: resolvedUnit.diagnostics,
    );

    // If we have a graph, update dependencies for propagation.
    if (graph != null) {
      previewsForLibrary.updateDependencyGraph(
        graph: graph,
        unit: resolvedUnit,
      );
    }

    // Iterate over the library's AST to find previews.
    previewsForLibrary.addPreviews(unit: resolvedUnit);
  }

  /// Propagates errors through the dependency graph.
  void propagateErrors(Map<Uri, LibraryPreviewNode> graph) {
    // Reset the error state for all dependencies.
    for (var libraryDetails in graph.values) {
      libraryDetails.dependencyHasErrors = false;
    }

    void propagateErrorsHelper(LibraryPreviewNode errorContainingNode) {
      for (var importer in errorContainingNode.dependedOnBy) {
        if (importer.dependencyHasErrors) {
          // This dependency path has already been processed.
          continue;
        }
        importer.dependencyHasErrors = true;
        propagateErrorsHelper(importer);
      }
    }

    // Find the libraries that have errors and mark each of their downstream
    // dependencies as having a dependency containing errors.
    for (var nodeDetails in graph.values) {
      if (nodeDetails.hasErrors) {
        propagateErrorsHelper(nodeDetails);
      }
    }

    // Update the error flags on all previews based on the propagated state.
    for (var node in graph.values) {
      var hasError = node.hasErrors;
      var dependencyHasErrors = node.dependencyHasErrors;
      for (var i = 0; i < node.previews.length; i++) {
        var preview = node.previews[i];
        if (preview.hasError != hasError ||
            preview.dependencyHasErrors != dependencyHasErrors) {
          node.previews[i] = FlutterWidgetPreviewDetails(
            scriptUri: preview.scriptUri,
            position: preview.position,
            packageName: preview.packageName,
            functionName: preview.functionName,
            isBuilder: preview.isBuilder,
            previewAnnotation: preview.previewAnnotation,
            isMultiPreview: preview.isMultiPreview,
            hasError: hasError,
            dependencyHasErrors: dependencyHasErrors,
          );
        }
      }
    }
  }
}

/// Contains information related to a library being scanned for previews.
final class LibraryPreviewNode {
  final NamespaceAllocator namespaceAllocator;

  /// The URI pointing to the library.
  final Uri uri;

  /// The absolute path to the library's defining unit.
  final String path;

  /// The list of previews contained within the file.
  final previews = <FlutterWidgetPreviewDetails>[];

  /// Files that import this file.
  final dependedOnBy = <LibraryPreviewNode>{};

  /// Files this file imports.
  final dependsOn = <LibraryPreviewNode>{};

  /// `true` if a transitive dependency has compile time errors.
  bool dependencyHasErrors = false;

  /// The set of errors found in this library.
  final errors = <Diagnostic>[];

  LibraryPreviewNode({
    required LibraryElement library,
    required this.namespaceAllocator,
  }) : uri = library.uri,
       path = library.firstFragment.source.fullName;

  /// `true` if this library contains compile time errors.
  bool get hasErrors => errors.isNotEmpty;

  /// Finds all previews defined in the [unit] and adds them to [previews].
  void addPreviews({required ResolvedUnitResult unit}) {
    // Iterate over the compilation unit's AST to find previews.
    var visitor = _PreviewVisitor(
      lib: unit.libraryElement,
      previewNode: this,
      namespaceAllocator: namespaceAllocator,
    );
    visitor.findPreviewsInResolvedUnitResult(unit);

    // Remove existing previews for this unit before adding new ones.
    previews.removeWhere((p) => p.scriptUri == unit.uri);
    previews.addAll(visitor.previewEntries);
  }

  /// Determines the set of errors found in this file.
  void populateErrorsForFile({
    required Uri uri,
    required List<Diagnostic> diagnostics,
  }) {
    errors
      ..removeWhere((e) => e.source.uri == uri)
      ..addAll(diagnostics.where((e) => e.severity == Severity.error));
  }

  /// Updates the dependency graph based on changes to a compilation [unit].
  void updateDependencyGraph({
    required Map<Uri, LibraryPreviewNode> graph,
    required ResolvedUnitResult unit,
  }) {
    var updatedDependencies = <LibraryPreviewNode>{};

    for (var fragment in unit.libraryElement.fragments) {
      for (var importedLib in fragment.libraryImports) {
        if (importedLib.importedLibrary == null) {
          continue;
        }
        var importedLibrary = importedLib.importedLibrary!;
        var result = graph.putIfAbsent(
          importedLibrary.uri,
          () => LibraryPreviewNode(
            library: importedLibrary,
            namespaceAllocator: namespaceAllocator,
          ),
        );
        updatedDependencies.add(result);
      }
    }

    // Only update dependsOn for the library unit itself to avoid confusion
    // with parts, or just use a cumulative set.
    dependsOn.addAll(updatedDependencies);

    for (var dependency in updatedDependencies) {
      dependency.dependedOnBy.add(this);
    }
  }
}

/// Tracks imports and assigns namespaces to each unique library URL.
class NamespaceAllocator {
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};
  var _keys = 1;

  /// Returns import source code for each library seen.
  Map<String, String> get namespaces =>
      _imports.map((uri, id) => MapEntry(uri, '_i$id'));

  /// Returns the name of [symbol] with a namespace prefix assigned based on
  /// [url].
  String applyNamespaceToSymbol({
    required String symbol,
    required String? url,
  }) {
    if (url == null || _doNotPrefix.contains(url)) {
      return symbol;
    }
    return '_i${_imports.putIfAbsent(url, _nextKey)}.$symbol';
  }

  int _nextKey() => _keys++;
}

/// Visitor which detects previews and extracts [PreviewDetails] for later code
/// generation.
class _PreviewVisitor extends RecursiveAstVisitor<void> {
  final LibraryPreviewNode previewNode;

  final NamespaceAllocator namespaceAllocator;
  late final String? packageName;
  final previewEntries = <FlutterWidgetPreviewDetails>[];

  FunctionDeclaration? _currentFunction;

  ConstructorDeclaration? _currentConstructor;
  MethodDeclaration? _currentMethod;
  late Uri _currentScriptUri;

  late CompilationUnit _currentUnit;
  _PreviewVisitor({
    required LibraryElement lib,
    required this.previewNode,
    required this.namespaceAllocator,
  }) : packageName = lib.uri.scheme == 'package'
           ? lib.uri.pathSegments.first
           : null;

  void findPreviewsInResolvedUnitResult(ResolvedUnitResult unit) {
    _currentScriptUri = unit.uri;
    _currentUnit = unit.unit;
    _currentUnit.visitChildren(this);
  }

  bool hasRequiredParams(FormalParameterList? params) {
    return params?.parameters.any((p) => p.isRequired) ?? false;
  }

  @override
  void visitAnnotation(Annotation node) {
    bool isMultiPreview = node.isMultiPreview;
    bool isPreview = node.isPreview;
    // Skip non-preview annotations.
    if (!isPreview && !isMultiPreview) {
      return;
    }
    // The preview annotations must only have constant arguments.
    DartObject? preview = node.elementAnnotation!.computeConstantValue();
    if (preview == null) {
      return;
    }
    LineInfo lineInfo = _currentUnit.lineInfo;
    CharacterLocation location = lineInfo.getLocation(node.offset);
    int line = location.lineNumber;
    int column = location.columnNumber;
    var hasError = previewNode.hasErrors;
    var dependencyHasErrors = previewNode.dependencyHasErrors;

    FlutterWidgetPreviewDetails buildPreviewDetails({
      required String functionName,
      required bool isWidgetBuilder,
    }) {
      return FlutterWidgetPreviewDetails(
        scriptUri: _currentScriptUri,
        position: Position(character: column, line: line),
        packageName: packageName,
        functionName: functionName,
        isBuilder: isWidgetBuilder,
        previewAnnotation: preview.toSource(namespaceAllocator),
        isMultiPreview: isMultiPreview,
        hasError: hasError,
        dependencyHasErrors: dependencyHasErrors,
      );
    }

    if (_currentFunction != null &&
        !hasRequiredParams(_currentFunction!.functionExpression.parameters)) {
      TypeAnnotation? returnTypeAnnotation = _currentFunction!.returnType;
      if (returnTypeAnnotation is NamedType) {
        Token returnType = returnTypeAnnotation.name;
        if (returnType.isWidget || returnType.isWidgetBuilder) {
          previewEntries.add(
            buildPreviewDetails(
              functionName: _currentFunction!.name.toString(),
              isWidgetBuilder: returnType.isWidgetBuilder,
            ),
          );
        }
      }
    } else if (_currentConstructor != null &&
        !hasRequiredParams(_currentConstructor!.parameters)) {
      var returnType = _currentConstructor!.typeName!;
      Token? name = _currentConstructor!.name;
      previewEntries.add(
        buildPreviewDetails(
          functionName: '$returnType${name == null ? '' : '.$name'}',
          isWidgetBuilder: false,
        ),
      );
    } else if (_currentMethod != null &&
        !hasRequiredParams(_currentMethod!.parameters)) {
      TypeAnnotation? returnTypeAnnotation = _currentMethod!.returnType;
      if (returnTypeAnnotation is NamedType) {
        Token returnType = returnTypeAnnotation.name;
        if (returnType.isWidget || returnType.isWidgetBuilder) {
          var parentClass = _currentMethod!.parent!.parent! as ClassDeclaration;
          previewEntries.add(
            buildPreviewDetails(
              functionName:
                  '${parentClass.namePart.typeName}.${_currentMethod!.name}',
              isWidgetBuilder: returnType.isWidgetBuilder,
            ),
          );
        }
      }
    }
  }

  /// Handles previews defined on constructors.
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _scopedVisitChildren(
      node,
      (ConstructorDeclaration? node) => _currentConstructor = node,
    );
  }

  /// Handles previews defined on top-level functions.
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    assert(_currentFunction == null);
    if (node.name.isPrivate) {
      return;
    }

    TypeAnnotation? returnType = node.returnType;
    if (returnType == null || returnType.question != null) {
      return;
    }
    _scopedVisitChildren(
      node,
      (FunctionDeclaration? node) => _currentFunction = node,
    );
  }

  /// Handles previews defined on static methods within classes.
  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isStatic) {
      return;
    }
    _scopedVisitChildren(
      node,
      (MethodDeclaration? node) => _currentMethod = node,
    );
  }

  void _scopedVisitChildren<T extends AstNode>(
    T node,
    void Function(T?) setter,
  ) {
    setter(node);
    node.visitChildren(this);
    setter(null);
  }
}

extension on Annotation {
  static final widgetPreviewsLibraryUri = Uri.parse(
    'package:flutter/src/widget_previews/widget_previews.dart',
  );

  /// Convenience getter to identify `@MultiPreview` annotations
  bool get isMultiPreview => _isPreviewType('MultiPreview');

  /// Convenience getter to identify `@Preview` annotations
  bool get isPreview => _isPreviewType('Preview');

  bool _isPreviewType(String typeName) {
    Element? element = elementAnnotation!.element;
    if (element is ConstructorElement) {
      InterfaceType type = element.enclosingElement.thisType;
      return type.isType(typeName: typeName, uri: widgetPreviewsLibraryUri);
    }
    return false;
  }
}

extension on DartObject {
  /// Generates an equivalent source code representation of this constant
  /// object using [prefixAllocator] to apply namespaces to types.
  String toSource(NamespaceAllocator prefixAllocator) {
    DartType type = this.type!;
    return switch (type) {
      DartType(isDartCoreBool: true) => toBoolValue()!.toString(),
      DartType(isDartCoreDouble: true) => toDoubleValue()!.toString(),
      DartType(isDartCoreInt: true) => toIntValue()!.toString(),
      DartType(isDartCoreString: true) => "'${toStringValue()!}'",
      DartType(isDartCoreNull: true) => 'null',
      DartType(isDartCoreList: true) => _buildListSource(prefixAllocator),
      DartType(isDartCoreMap: true) => _buildMapSource(prefixAllocator),
      DartType(isDartCoreSet: true) => _buildSetSource(prefixAllocator),
      RecordType() => _buildRecordSource(prefixAllocator),
      InterfaceType(element: EnumElement()) => _buildEnumInstanceSource(
        prefixAllocator,
      ),
      InterfaceType() => _buildInstanceSource(prefixAllocator),
      FunctionType() => _createTearoffSource(prefixAllocator),
      _ => throw UnsupportedError('Unexpected DartObject type: $runtimeType'),
    };
  }

  String _buildEnumInstanceSource(NamespaceAllocator prefixAllocator) {
    VariableElement variable = this.variable!;
    var url = variable.library!.uri.toString();
    return switch (variable) {
      FieldElement(
        isEnumConstant: true,
        displayName: var enumValue,
        enclosingElement: EnumElement(displayName: var enumName),
      ) =>
        prefixAllocator.applyNamespaceToSymbol(
          symbol: '$enumName.$enumValue',
          url: url,
        ),

      PropertyInducingElement(:var displayName) =>
        prefixAllocator.applyNamespaceToSymbol(symbol: displayName, url: url),
      _ => throw UnsupportedError(
        'Unexpected enum variable type: ${variable.runtimeType}',
      ),
    };
  }

  String _buildInstanceSource(NamespaceAllocator prefixAllocator) {
    var dartType = type! as InterfaceType;
    var invocation = constructorInvocation;
    if (invocation == null) {
      return prefixAllocator.applyNamespaceToSymbol(
        symbol: dartType.element.name!,
        url: dartType.element.library.uri.toString(),
      );
    }

    ConstructorElement? constructor = invocation.constructor;
    String? constructorName = constructor.name == 'new'
        ? null
        : constructor.name;

    List<String> positionalArguments = invocation.positionalArguments
        .map((e) => e.toSource(prefixAllocator))
        .toList();
    var namedArguments = <String, String>{
      for (final MapEntry(key: name, :value)
          in invocation.namedArguments.entries)
        name: value.toSource(prefixAllocator),
    };
    var typeArguments = <String>[
      for (var typeArgument in dartType.typeArguments)
        typeArgument.toSource(prefixAllocator),
    ];

    var buffer = StringBuffer();
    buffer.write(
      prefixAllocator.applyNamespaceToSymbol(
        symbol: dartType.element.name!,
        url: dartType.element.library.uri.toString(),
      ),
    );
    if (typeArguments.isNotEmpty) {
      buffer
        ..write('<')
        ..writeAll(typeArguments, ', ')
        ..write('>');
    }
    if (constructorName != null) {
      buffer.write('.$constructorName');
    }
    buffer
      ..write('(')
      ..writeAll([
        ...positionalArguments,
        ...namedArguments.entries.map<String>((e) => '${e.key}: ${e.value}'),
      ], ', ')
      ..write(')');
    return buffer.toString();
  }

  String _buildListSource(NamespaceAllocator prefixAllocator) {
    var list = toListValue()!;
    var buffer = StringBuffer();
    buffer.write('[');
    buffer.writeAll(list.map((e) => e.toSource(prefixAllocator)), ', ');
    buffer.write(']');
    return buffer.toString();
  }

  String _buildMapSource(NamespaceAllocator prefixAllocator) {
    var map = toMapValue()!;
    var buffer = StringBuffer();
    buffer.write('{');
    buffer.writeAll(
      map.entries.map(
        (e) =>
            '${e.key!.toSource(prefixAllocator)}: ${e.value!.toSource(prefixAllocator)}',
      ),
      ', ',
    );
    buffer.write('}');
    return buffer.toString();
  }

  String _buildRecordSource(NamespaceAllocator prefixAllocator) {
    var record = toRecordValue()!;
    var buffer = StringBuffer()
      ..write('(')
      ..writeAll([
        ...record.positional.map((e) => e.toSource(prefixAllocator)),
        ...record.named.entries.map(
          (e) => '${e.key}: ${e.value.toSource(prefixAllocator)}',
        ),
      ], ', ')
      ..write(')');
    return buffer.toString();
  }

  String _buildSetSource(NamespaceAllocator prefixAllocator) {
    var set = toSetValue()!;
    var buffer = StringBuffer();
    buffer.write('{');
    buffer.writeAll(set.map((e) => e.toSource(prefixAllocator)), ', ');
    buffer.write('}');
    return buffer.toString();
  }

  String _createTearoffSource(NamespaceAllocator prefixAllocator) {
    var function = toFunctionValue()!;
    return prefixAllocator.applyNamespaceToSymbol(
      symbol: function.displayName,
      url: function.library.uri.toString(),
    );
  }
}

extension on DartType {
  /// Generates an equivalent source code representation of this type using
  /// [prefixAllocator] to apply namespaces to all referenced types.
  String toSource(NamespaceAllocator prefixAllocator) {
    if (this is RecordType) {
      return _recordToSource(this as RecordType, prefixAllocator);
    }
    var typeArguments = switch (this) {
      InterfaceType(:var typeArguments) => [
        for (var typeArgument in typeArguments)
          typeArgument.toSource(prefixAllocator),
      ],
      _ => <String>[],
    };
    var element = this.element!;
    var buffer = StringBuffer();
    buffer.write(
      prefixAllocator.applyNamespaceToSymbol(
        symbol: element.name!,
        url: element.library!.uri.toString(),
      ),
    );
    if (typeArguments.isNotEmpty) {
      buffer
        ..write('<')
        ..writeAll(typeArguments, ', ')
        ..write('>');
    }
    return buffer.toString();
  }

  String _recordToSource(RecordType type, NamespaceAllocator prefixAllocator) {
    var positionalFields = type.positionalFields
        .map((e) => e.type.toSource(prefixAllocator))
        .join(', ');

    var namedFields = type.namedFields
        .map((e) => '${e.type.toSource(prefixAllocator)} ${e.name}')
        .join(', ');

    var buffer = StringBuffer();
    buffer
      ..write('(')
      ..writeAll([
        if (positionalFields.isNotEmpty) positionalFields,
        if (namedFields.isNotEmpty) '{$namedFields}',
      ], ', ')
      ..write(')');
    return buffer.toString();
  }
}

extension on InterfaceType {
  bool isType({required String typeName, required Uri uri}) {
    if (getDisplayString() == typeName && element.library.uri == uri) {
      return true;
    }
    return allSupertypes.firstWhereOrNull((e) {
          return e.getDisplayString() == typeName &&
              e.element.library.uri == uri;
        }) !=
        null;
  }
}

extension on Token {
  /// Convenience getter to identify tokens for private fields and functions.
  bool get isPrivate => toString().startsWith('_');

  /// Convenience getter to identify Widget types.
  bool get isWidget => toString() == 'Widget';

  /// Convenience getter to identify WidgetBuilder types.
  bool get isWidgetBuilder => toString() == 'WidgetBuilder';
}
