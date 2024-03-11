// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show relativizeUri;
import 'package:collection/collection.dart';
import 'package:front_end/src/fasta/kernel/resource_identifier.dart'
    as ResourceIdentifiers;
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:vm/metadata/loading_units.dart';

/// Collect calls to methods annotated with `@ResourceIdentifier`.
///
/// Identify and collect all calls to static methods annotated in the given
/// [component]. This requires the deferred loading to be handled already to
/// also save which loading unit the call is made in. Write the result into a
/// JSON at [resourcesFile].
///
/// The purpose of this feature is to be able to pass the recorded information
/// to packages in a post-compilation step, allowing them to remove or modify
/// assets based on the actual usage in the code prior to bundling in the final
/// application.
Component transformComponent(Component component, Uri resourcesFile) {
  final tag = LoadingUnitsMetadataRepository.repositoryTag;
  final loadingMetadata =
      component.metadata[tag] as LoadingUnitsMetadataRepository;
  final loadingUnits = loadingMetadata.mapping[component]?.loadingUnits ?? [];

  final visitor = _ResourceIdentifierVisitor(loadingUnits);
  for (final library in component.libraries) {
    library.visitChildren(visitor);
  }

  File.fromUri(resourcesFile).writeAsStringSync(_toJson(visitor.identifiers));

  return component;
}

String _toJson(List<Identifier> identifiers) {
  return JsonEncoder.withIndent('  ').convert({
    '_comment': 'Resources referenced by annotated resource identifiers',
    'AppTag': 'TBD',
    'environment': {
      'dart.tool.dart2js': false,
    },
    'identifiers': identifiers,
  });
}

class _ResourceIdentifierVisitor extends RecursiveVisitor {
  final List<Identifier> identifiers = [];
  final List<LoadingUnit> _loadingUnits;

  _ResourceIdentifierVisitor(this._loadingUnits);

  @override
  void visitStaticInvocation(StaticInvocation node) {
    final annotations =
        ResourceIdentifiers.findResourceAnnotations(node.target);
    if (annotations.isNotEmpty) {
      _collectCallInformation(node, _firstResourceId(annotations.first));
      annotations.forEach(node.target.annotations.remove);
    }
    node.visitChildren(this);
  }

  /// In case a method has multiple `ResourceIdentifier` annotations, we just
  /// take the first.
  String _firstResourceId(InstanceConstant instance) {
    final fields = instance.fieldValues;
    final firstField = fields.entries.first;
    final fieldValue = firstField.value;
    return _evaluateConstant(fieldValue);
  }

  String _evaluateConstant(Constant fieldValue) {
    if (fieldValue case NullConstant()) {
      return '';
    } else if (fieldValue case PrimitiveConstant()) {
      return fieldValue.value.toString();
    } else {
      return throw UnsupportedError(
          'The type ${fieldValue.runtimeType} is not a '
          'supported metadata type for `@ResourceIdentifier` annotations');
    }
  }

  /// Collects all the information needed to transform [node].
  void _collectCallInformation(StaticInvocation node, String resourceId) {
    // Collect the name and definition location of the invocation. This is
    // shared across multiple calls to the same method.
    final identifier = _identifierOf(node, resourceId);
    identifiers.add(identifier);

    // Collect the call location and loading unit of the call.
    final resourceFile = _resourceFile(node, identifier);
    identifier.files.add(resourceFile);

    // Collect the (int, bool, double, or String) arguments passed in the call.
    final reference = _reference(node);
    resourceFile.references.add(reference);
  }

  Identifier _identifierOf(StaticInvocation node, String resourceId) {
    final identifierUri = relativizeUri(
        Uri.base, node.target.enclosingLibrary.fileUri, Platform.isWindows);

    return identifiers
            .where((id) => id.name == node.name.text && id.uri == identifierUri)
            .firstOrNull ??
        Identifier(
          name: node.name.text,
          id: resourceId,
          uri: identifierUri,
          nonConstant: !node.isConst,
          files: [],
        );
  }

  ResourceFile _resourceFile(StaticInvocation node, Identifier identifier) {
    final importUri = node.target.enclosingLibrary.importUri.toString();
    final id = _loadingUnits
            .firstWhereOrNull(
                (element) => element.libraryUris.contains(importUri))
            ?.id ??
        -1;
    final resourceFile =
        identifier.files.firstWhereOrNull((element) => element.part == id);
    return resourceFile ?? ResourceFile(part: id, references: []);
  }

  ResourceReference _reference(StaticInvocation node) {
    // Get rid of the artificial `this` argument for extension methods.
    final int argumentStart;
    if (node.target.isExtensionMember || node.target.isExtensionTypeMember) {
      argumentStart = 1;
    } else {
      argumentStart = 0;
    }
    final arguments = {
      // TODO(mosuem): Support more than just literals here,
      // by adding visitors for enum indices and other const expressions.
      for (var i = argumentStart; i < node.arguments.positional.length; i++)
        if (_evaluateLiteral(node.arguments.positional[i]) case var value?)
          '${i + 1 - argumentStart}': value,
      for (var argument in node.arguments.named)
        if (_evaluateLiteral(argument.value) case var value?)
          argument.name: value,
    };

    final location = node.location!;
    return ResourceReference(
      uri: relativizeUri(Uri.base, location.file, Platform.isWindows),
      line: location.line,
      column: location.column,
      arguments: arguments,
    );
  }

  static Object? _evaluateLiteral(Expression expression) =>
      expression is BasicLiteral ? expression.value : null;
}

//TODO(mosum): Expose these classes externally, as they will have to be used
//when parsing the generated JSON file.
class Identifier {
  final String name;
  final String id;
  final String uri;
  final bool nonConstant;
  final List<ResourceFile> files;

  Identifier({
    required this.name,
    required this.id,
    required this.uri,
    required this.nonConstant,
    required this.files,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'uri': uri,
      'nonConstant': nonConstant,
      'files': files,
    };
  }

  @override
  String toString() {
    return 'Identifier(name: $name, id: $id, uri: $uri, nonConstant: $nonConstant, files: $files)';
  }
}

class ResourceFile {
  final int part;
  final List<ResourceReference> references;

  ResourceFile({required this.part, required this.references});

  Map<String, dynamic> toJson() {
    return {
      'part': part,
      'references': references,
    };
  }

  @override
  String toString() => 'ResourceFile(part: $part, references: $references)';
}

class ResourceReference {
  final String uri;
  final int line;
  final int column;
  final Map<String, Object?> arguments;

  ResourceReference({
    required this.uri,
    required this.line,
    required this.column,
    required this.arguments,
  });

  Map<String, dynamic> toJson() {
    return {
      '@': {
        'uri': uri,
        'line': line,
        'column': column,
      },
      ...arguments,
    };
  }

  @override
  String toString() {
    return 'ResourceReference(uri: $uri, line: $line, column: $column, arguments: $arguments)';
  }
}
