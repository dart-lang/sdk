// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_testing/package_root.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:path/path.dart';

const packages = {
  '_fe_analyzer_shared',
  '_js_interop_checks',
  'compiler',
  'dart2wasm',
  'front_end',
  'vm',
};

void main() async {
  var provider = PhysicalResourceProvider.INSTANCE;
  var collection = AnalysisContextCollection(
    includedPaths: [for (var package in packages) join(packageRoot, package)],
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
      var relativePath = relative(libraryFile, from: packageRoot);
      var package = split(relativePath).first;
      if (!packages.contains(package)) {
        throw StateError('Unexpected package $package');
      }
      for (var unit in resolvedLibraryResult.units) {
        var visitor = _Visitor(package: package);
        unit.unit.accept(visitor);
        var changes = visitor.changes;
        if (changes.isNotEmpty) {
          var s = changes.length == 1 ? '' : 's';
          print('Found ${changes.length} change$s in ${unit.path}');
          await changeBuilder.addDartFileEdit(unit.path, (builder) {
            for (var change in changes) {
              change(builder);
            }
            // Attempting to format the whole file can result in conflicts
            // because any added imports will be applied after formatting. So
            // just format the portion of the file starting at the first
            // declaration.
            if (unit.unit.declarations case [var first, ...]) {
              var offset = first.offset;
              builder.format(SourceRange(offset, unit.content.length - offset));
            }
          });
        }
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

class _Visitor extends RecursiveAstVisitor<void> {
  final String package;
  final List<void Function(DartFileEditBuilder)> changes = [];

  /// While visiting a show/hide combinator, this set gathers all the simple
  /// identifiers that can be safely removed from the combinator.
  Set<SimpleIdentifier>? _namesToRemoveFromCombinator;

  _Visitor({required this.package});

  @override
  void visitShowCombinator(ShowCombinator node) {
    var namesToRemoveFromCombinator = _namesToRemoveFromCombinator = {};
    super.visitShowCombinator(node);
    _namesToRemoveFromCombinator = null;
    if (namesToRemoveFromCombinator.isEmpty) return;
    var shownNames = node.shownNames;
    if (namesToRemoveFromCombinator.length == shownNames.length) {
      // The whole import can be removed.
      changes.add((builder) {
        var importDirective = node.parent as ImportDirective;
        builder.addDeletion(
          SourceRange(importDirective.offset, importDirective.length),
        );
      });
    } else {
      // Each name has to be removed along with an adjacent `,`. For names
      // at the end of the list, remove the preceding `,`. For all other names,
      // remove the following `,`.
      var removePrecedingComma = true;
      for (var i = shownNames.length; i-- > 0;) {
        if (namesToRemoveFromCombinator.contains(shownNames[i])) {
          int offset;
          int end;
          if (removePrecedingComma) {
            offset = shownNames[i - 1].end;
            end = shownNames[i].end;
          } else {
            offset = shownNames[i].offset;
            end = shownNames[i + 1].offset;
          }
          changes.add((builder) {
            builder.addDeletion(SourceRange(offset, end - offset));
          });
        } else {
          removePrecedingComma = false;
        }
      }
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.name.startsWith('code')) return;
    var pascalCaseName = node.name.substring('code'.length);
    var element = node.element;
    if (element is GetterElement) element = element.variable;
    if (element is! TopLevelVariableElement) return;
    var message =
        diagnosticTables.frontEndDiagnosticsByPascalCaseName[pascalCaseName];
    if (message == null) return;
    var replacementText = 'diag.${message.frontEndCode.camelCaseName}';
    Identifier nodeToReplace;
    if (node.parent case PrefixedIdentifier parent
        when parent.prefix.element is PrefixElement) {
      nodeToReplace = parent;
    } else {
      nodeToReplace = node;
    }
    if (node.parent is Combinator) {
      _namesToRemoveFromCombinator!.add(node);
    } else {
      changes.add((builder) {
        var offset = nodeToReplace.offset;
        builder.addSimpleReplacement(
          SourceRange(offset, nodeToReplace.end - offset),
          replacementText,
        );
        builder.importLibrary(
          Uri.parse(
            package == '_fe_analyzer_shared'
                ? 'package:_fe_analyzer_shared/src/messages/diagnostic.dart'
                : 'package:front_end/src/codes/diagnostic.dart',
          ),
          prefix: 'diag',
        );
      });
    }
  }
}
