// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_testing/package_root.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:path/path.dart';

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
  var rejectStats = _RejectStats();
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
          rejectStats: rejectStats,
          fileContents: unit.content,
          path: unit.path,
          lineInfo: unit.lineInfo,
        );
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
            var offset = unit.unit.declarations.first.offset;
            builder.format(SourceRange(offset, unit.content.length - offset));
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
  rejectStats.dump();
}

const packages = {
  '_fe_analyzer_shared',
  '_js_interop_checks',
  'dart2wasm',
  'front_end',
  'vm',
};

class _RejectStats {
  List<String> dueToComplexDiagnostic = [];
  List<String> dueToTearOff = [];
  List<String> dueToArgumentLengthMismatch = [];
  List<String> dueToNamedArgument = [];
  List<String> dueToPlaceholderParameterComment = [];

  void dump() {
    print(
      'Rejects due to complex diagnostic: ${dueToComplexDiagnostic.length}',
    );
    print('Rejects due to tearoff: ${dueToTearOff.length}');
    print(
      'Rejects due to argument length mismatch: ${dueToArgumentLengthMismatch.length}',
    );
    print('Rejects due to named argument: ${dueToNamedArgument.length}');
    print(
      'Rejects due to placeholder parameter comment: ${dueToPlaceholderParameterComment.length}',
    );
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  final _RejectStats rejectStats;
  final String fileContents;
  final String path;
  final LineInfo lineInfo;

  final List<void Function(DartFileEditBuilder)> changes = [];

  _Visitor({
    required this.rejectStats,
    required this.fileContents,
    required this.path,
    required this.lineInfo,
  });

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_tryFixingPropertyAccess(
          node: node,
          target: node.prefix,
          propertyName: node.identifier,
        )
        case var change?) {
      changes.add(change);
    } else {
      super.visitPrefixedIdentifier(node);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_tryFixingPropertyAccess(
          node: node,
          target: node.target,
          propertyName: node.propertyName,
        )
        case var change?) {
      changes.add(change);
    } else {
      super.visitPropertyAccess(node);
    }
  }

  CfeStyleMessage? _decodeDiagnostic(Expression expr) {
    if (expr is! PrefixedIdentifier) return null;
    if (expr.element case GetterElement(:var variable)) {
      if (variable.isConst) {
        var value = variable.computeConstantValue();
        if (value == null) return null;
        // Note that accessing the private name `_uniqueName` is brittle, since
        // it will not be obvious that this code needs to be changed if the
        // private name changes. It would be better if we could call
        // `DiagnosticCode.lowerCaseUniqueName` on the constant, but the
        // analyzer's constant evaluation engine isn't sophisticated enough to
        // provide that capability. In practice the brittleness is of little
        // consequence because this script is exclusively for the use of the
        // analyzer developers during the transition period to the literate
        // diagnostic reporting API.
        var name = value.superAwareGetField('name')?.toStringValue();
        return diagnosticTables.frontEndDiagnosticsByPascalCaseName[name] ??
            (throw 'Diagnostic not found: $name');
      }
    }
    return null;
  }

  void Function(DartFileEditBuilder)? _tryFixingPropertyAccess({
    required Expression node,
    required Expression? target,
    required SimpleIdentifier propertyName,
  }) {
    if (target == null) return null;
    late var characterLocation = lineInfo.getLocation(node.offset);
    late var location =
        '$path:${characterLocation.lineNumber}:'
        '${characterLocation.columnNumber}';
    if (propertyName.name == 'withArgumentsOld') {
      var parent = node.parent;
      if (parent is! FunctionExpressionInvocation) {
        rejectStats.dueToTearOff.add(location);
        return null;
      }
      var diagnostic = _decodeDiagnostic(target);
      if (diagnostic == null) {
        rejectStats.dueToComplexDiagnostic.add(location);
        return null;
      }
      var arguments = parent.argumentList.arguments;
      var parameterNames = diagnostic.parameters.keys.toList();
      if (arguments.length != parameterNames.length) {
        rejectStats.dueToArgumentLengthMismatch.add(location);
        return null;
      }
      for (var argument in arguments) {
        if (argument is NamedExpression) {
          rejectStats.dueToNamedArgument.add(location);
          return null;
        }
      }
      for (var parameter in diagnostic.parameters.values) {
        if (parameter.comment == 'undocumented') {
          rejectStats.dueToPlaceholderParameterComment.add(location);
          return null;
        }
      }
      return (builder) {
        builder.addSimpleReplacement(
          SourceRange(propertyName.offset, propertyName.length),
          'withArguments',
        );
        for (var i = 0; i < arguments.length; i++) {
          builder.addSimpleInsertion(
            arguments[i].offset,
            '${parameterNames[i]}: ',
          );
        }
      };
    }
    return null;
  }
}

extension on DartObject {
  DartObject? superAwareGetField(String field) {
    if (getField(field) case var value?) {
      return value;
    } else if (getField('(super)') case var value?) {
      return value.superAwareGetField(field);
    } else {
      return null;
    }
  }
}
