// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a temporary utility that modifies references to diagnostic constants
/// in the analyzer and related packages so that instead of referring to
/// constants in classes like `CompileTimeErrorCode`, etc., they refer to
/// top level constants in `diagnostic.dart` files using the import prefix
/// `diag`.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_testing/package_root.dart';
import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:linter/src/rules.dart' as linter;
import 'package:path/path.dart';

void main() async {
  linter.registerLintRules();
  var provider = PhysicalResourceProvider.INSTANCE;
  var collection = AnalysisContextCollection(
    includedPaths: [
      for (var package in const [
        'analyzer',
        'analysis_server',
        'linter',
        'analysis_server_plugin',
        'analyzer_plugin',
        'analyzer_testing',
        'front_end',
        'analyzer_cli',
      ])
        join(packageRoot, package),
    ],
    resourceProvider: provider,
  );
  // Use `.single` to make sure that `collection` just contains a single
  // context. This ensures that the code below will see all the files in the
  // packages.
  var context = collection.contexts.single;
  var changeBuilder = ChangeBuilder(session: context.currentSession);
  for (var libraryFile in context.contextRoot.analyzedFiles()) {
    if (!libraryFile.endsWith('.dart')) continue;
    var fileResult = context.currentSession.getFile(libraryFile) as FileResult;
    if (fileResult.isLibrary) {
      var resolvedLibraryResult =
          (await context.currentSession.getResolvedLibrary(libraryFile))
              as ResolvedLibraryResult;
      for (var unit in resolvedLibraryResult.units) {
        var visitor = _Visitor(
          libraryUri: resolvedLibraryResult.element.uri,
          path: unit.path,
        );
        unit.unit.accept(visitor);
        var changes = visitor.changes;
        if (changes.isNotEmpty) {
          var s = changes.length == 1 ? '' : 's';
          print('Found ${changes.length} change$s in ${unit.path}');
        }
        await changeBuilder.addDartFileEdit(unit.path, (builder) {
          for (var change in changes) {
            change(builder);
          }
        });
      }
    }
  }
  for (var edit in changeBuilder.sourceChange.edits) {
    var filePath = edit.file;
    var content = File(filePath).readAsStringSync();
    var newContent = SourceEdit.applySequence(content, edit.edits);
    File(filePath).writeAsStringSync(newContent);
  }
}

final activeMessagesByCamelCaseName = {
  for (var messages in diagnosticTables.activeMessagesByPackage.values)
    for (var message in messages) message.analyzerCode.camelCaseName: message,
};

final diagnosticClassesByName = {
  for (var diagnosticClass in diagnosticClasses)
    diagnosticClass.name: diagnosticClass,
};

class _Visitor extends RecursiveAstVisitor<void> {
  final Uri libraryUri;
  final String path;
  final List<void Function(DartFileEditBuilder)> changes = [];

  _Visitor({required this.libraryUri, required this.path});

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _fixIfNeeded(element: node.identifier.element, prefix: node.prefix);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.operator.type == TokenType.PERIOD) {
      if (node.target case PrefixedIdentifier prefix) {
        _fixIfNeeded(element: node.propertyName.element, prefix: prefix);
      }
    }
    super.visitPropertyAccess(node);
  }

  /// Consider replacing [prefix] with import prefix `diag`.
  ///
  /// [element] is the element referred to by the identifier to the right of
  /// [prefix].
  void _fixIfNeeded({required Element? element, required Identifier prefix}) {
    if (element case GetterElement(
      isStatic: true,
      name: var messageName?,
      enclosingElement: ClassElement(name: var className?),
    )) {
      if (diagnosticClassesByName[className] case var diagnosticClass?) {
        if (activeMessagesByCamelCaseName[messageName]
            case MessageWithAnalyzerCode(:var analyzerCode)
            when analyzerCode.diagnosticClass == diagnosticClass) {
          changes.add((builder) {
            builder.addSimpleReplacement(
              SourceRange(prefix.offset, prefix.length),
              'diag',
            );
            var package = diagnosticClass.file.package;
            builder.importLibrary(
              Uri.parse(
                'package:${package.dirName}/${package.diagnosticPathPart}.dart',
              ),
              prefix: 'diag',
            );
          });
        }
      }
    }
  }
}
