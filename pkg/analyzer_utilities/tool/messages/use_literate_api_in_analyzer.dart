// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
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
import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';

void main() async {
  var provider = PhysicalResourceProvider.INSTANCE;
  var collection = AnalysisContextCollection(
    includedPaths: [join(packageRoot, 'analyzer')],
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

class _RejectStats {
  List<String> dueToMissingDiagnosticCode = [];
  List<String> dueToInvalidLocationArgs = [];
  List<String> dueToUnrecognizedArgument = [];
  List<String> dueToComplexDiagnostic = [];
  Map<String, List<String>> dueToPlaceholderParameterNames = {};
  List<String> dueToComplexArguments = [];
  List<String> dueToComments = [];

  void dump() {
    print(
      'Rejects due to missing diagnostic code: ${dueToMissingDiagnosticCode.length}',
    );
    print(
      'Rejects due to invalid location args: ${dueToInvalidLocationArgs.length}',
    );
    print(
      'Rejects due to unrecognized argument: '
      '${dueToUnrecognizedArgument.length}',
    );
    print(
      'Rejects due to complex diagnostic: ${dueToComplexDiagnostic.length}',
    );
    print('Rejects due to complex arguments: ${dueToComplexArguments.length}');
    print('Rejects due to comments: ${dueToComments.length}');
    print(
      'Rejects due to placeholder parameter names: '
      '${dueToPlaceholderParameterNames.values.map((v) => v.length).sum}',
    );
    for (var entry in dueToPlaceholderParameterNames.entries.sortedBy(
      (entry) => -entry.value.length,
    )) {
      print('  ${entry.key}: ${entry.value.length}');
    }
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  static final _placeholderParameterNameRegExp = RegExp(r'^p[0-9]+$');
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
  void visitMethodInvocation(MethodInvocation node) {
    if (_tryFixingMethodInvocation(node) case var change?) {
      changes.add(change);
    } else {
      super.visitMethodInvocation(node);
    }
  }

  bool _containsComments(AstNode node) {
    var token = node.beginToken;
    var endToken = node.endToken;
    while (token != endToken) {
      token = token.next!;
      if (token.precedingComments != null) return true;
    }
    return false;
  }

  MessageWithAnalyzerCode? _decodeDiagnostic(Expression expr) {
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
        var uniqueName = value
            .superAwareGetField('_uniqueName')
            ?.toStringValue();
        return diagnosticTables.diagnosticsByAnalyzerUniqueName[uniqueName] ??
            (throw 'Diagnostic not found: $uniqueName');
      }
    }
    return null;
  }

  String _text(SyntacticEntity entity) {
    return fileContents.substring(entity.offset, entity.end);
  }

  bool _translateArguments(
    MessageWithAnalyzerCode diagnostic,
    Expression? arguments,
    StringBuffer replacementText,
  ) {
    List<String> argumentList = [];
    if (arguments != null) {
      if (arguments is! ListLiteral) return false;
      for (var element in arguments.elements) {
        if (element is! Expression) return false;
        argumentList.add(_text(element));
      }
    }
    if (diagnostic.parameters.length != argumentList.length) {
      return false;
    }
    if (argumentList.isNotEmpty) {
      replacementText.write('.withArguments(');
      for (var (i, key) in diagnostic.parameters.keys.indexed) {
        replacementText.write(key);
        replacementText.write(': ');
        replacementText.write(argumentList[i]);
        replacementText.write(', ');
      }
      replacementText.write(')');
    }
    return true;
  }

  void Function(DartFileEditBuilder)? _tryFixingMethodInvocation(
    MethodInvocation node,
  ) {
    late var characterLocation = lineInfo.getLocation(node.offset);
    late var location =
        '$path:${characterLocation.lineNumber}:'
        '${characterLocation.columnNumber}';
    if (node.methodName.element case MethodElement(
      enclosingElement: ClassElement(name: 'DiagnosticReporter'),
      :var name,
    )) {
      String? Function(List<Expression>, Map<String, Expression>)
      translateLocationArgs;
      bool diagnosticCodeArgumentIsNamed;
      switch (name) {
        case 'atEntity':
        case 'atNode':
        case 'atToken':
          translateLocationArgs = (positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty) {
              return '.at(${_text(positionalArgs.removeAt(0))})';
            } else {
              return null;
            }
          };
          diagnosticCodeArgumentIsNamed = false;
        case 'atOffset':
          translateLocationArgs = (positionalArgs, namedArgs) {
            var offset = namedArgs.remove('offset');
            var length = namedArgs.remove('length');
            if (offset != null && length != null) {
              return '.atOffset(offset: ${_text(offset)}, length: ${_text(length)})';
            } else {
              return null;
            }
          };
          diagnosticCodeArgumentIsNamed = true;
        case 'atSourceSpan':
          translateLocationArgs = (positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty) {
              return '.atSourceSpan(${_text(positionalArgs.removeAt(0))})';
            } else {
              return null;
            }
          };
          diagnosticCodeArgumentIsNamed = false;
        case 'atSourceRange':
          translateLocationArgs = (positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty) {
              return '.atSourceRange(${_text(positionalArgs.removeAt(0))})';
            } else {
              return null;
            }
          };
          diagnosticCodeArgumentIsNamed = false;
        default:
          return null;
      }
      var positionalArgs = <Expression>[];
      var namedArgs = <String, Expression>{};
      for (var arg in node.argumentList.arguments) {
        if (arg case NamedExpression(:var name, :var expression)) {
          namedArgs[name.label.name] = expression;
        } else {
          positionalArgs.add(arg);
        }
      }
      var locationText = translateLocationArgs(positionalArgs, namedArgs);
      if (locationText == null) {
        rejectStats.dueToInvalidLocationArgs.add(location);
        return null;
      }
      Expression diagnosticCodeArg;
      if (diagnosticCodeArgumentIsNamed) {
        if (namedArgs.remove('diagnosticCode') case var expr?) {
          diagnosticCodeArg = expr;
        } else {
          rejectStats.dueToMissingDiagnosticCode.add(location);
          return null;
        }
      } else {
        if (positionalArgs.isEmpty) {
          rejectStats.dueToMissingDiagnosticCode.add(location);
          return null;
        }
        diagnosticCodeArg = positionalArgs.removeLast();
      }
      var diagnostic = _decodeDiagnostic(diagnosticCodeArg);
      if (diagnostic == null) {
        rejectStats.dueToComplexDiagnostic.add(location);
        return null;
      }
      if (diagnostic.parameters.keys.any(
        (k) => _placeholderParameterNameRegExp.matchAsPrefix(k) != null,
      )) {
        (rejectStats.dueToPlaceholderParameterNames[diagnostic.constantName] ??=
                [])
            .add(location);
        return null;
      }
      if (positionalArgs.isNotEmpty ||
          namedArgs.keys.any(
            (k) => !const {'arguments', 'contextMessages'}.contains(k),
          )) {
        rejectStats.dueToUnrecognizedArgument.add(location);
        return null;
      }
      var replacementText = StringBuffer('report(');
      replacementText.write(_text(diagnosticCodeArg));
      if (!_translateArguments(
        diagnostic,
        namedArgs['arguments'],
        replacementText,
      )) {
        rejectStats.dueToComplexArguments.add(location);
        return null;
      }
      if (namedArgs['contextMessages'] case var expr?) {
        replacementText.write('.withContextMessages(${_text(expr)})');
      }
      replacementText.write(locationText);
      replacementText.write(')');
      if (_containsComments(node)) {
        rejectStats.dueToComments.add(location);
        return null;
      }
      return (builder) {
        var offset = node.methodName.offset;
        builder.addSimpleReplacement(
          SourceRange(offset, node.end - offset),
          replacementText.toString(),
        );
        builder.importLibrary(
          Uri.parse('package:analyzer/src/error/listener.dart'),
        );
      };
    } else {
      return null;
    }
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
