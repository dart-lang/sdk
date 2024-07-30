// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

class TextExpectationsCollector {
  /// If this flag is `true`, we accumulate updates to expectations.
  /// This should only happen locally, to update tests or implementation.
  ///
  /// This flag should be `false` during code review.
  static const updatingIsEnabled = false;

  static final assertMethods = [
    _AssertMethod(
      className: 'AbstractCompletionDriverTest',
      methodName: 'assertResponse',
      argument: _ArgumentIndex(0),
    ),
    _AssertMethod(
      className: '_AnalysisDomainTest',
      methodName: 'assertNotificationsText',
      argument: _ArgumentIndex(0),
    ),
    _AssertMethod(
      className: 'SelectionTest',
      methodName: '_assertSelection',
      argument: _ArgumentIndex(1),
    ),
  ];

  static final Map<String, _File> _files = {};

  static void add(String actual) {
    if (!updatingIsEnabled) {
      return;
    }

    var traceLines = '${StackTrace.current}'.split('\n');
    for (var assertMethod in assertMethods) {
      for (var traceIndex = 0; traceIndex < traceLines.length; traceIndex++) {
        var traceLine = traceLines[traceIndex];
        if (!traceLine.contains(' ${assertMethod.stackTracePattern} ')) {
          continue;
        }

        // Find the invocation of the assert method in the stack trace.
        var invocationTraceIndex = traceIndex + 1;
        if (traceLines[invocationTraceIndex] == '<asynchronous suspension>') {
          invocationTraceIndex++;
        }
        var invocationTraceLine = traceLines[invocationTraceIndex];

        // Parse the invocation stack trace line.
        var locationMatch = RegExp(
          r'(file://.+_test.dart):(\d+):',
        ).firstMatch(invocationTraceLine);
        if (locationMatch == null) {
          fail('Cannot parse: $invocationTraceLine');
        }

        var path = Uri.parse(locationMatch.group(1)!).toFilePath();
        var line = int.parse(locationMatch.group(2)!);
        var file = _getFile(path);

        var invocation = file.findInvocation(
          invocationLine: line,
        );
        if (invocation == null) {
          fail('Cannot find MethodInvocation.');
        }

        if (invocation.methodName.name != assertMethod.methodName) {
          fail(
            'Expected: ${assertMethod.methodName}\n'
            'Actual: ${invocation.methodName.name}\n',
          );
        }

        if (invocation.isInFailingTest) {
          return;
        }

        var argumentList = invocation.argumentList;
        var argument = assertMethod.argument.get(argumentList);
        if (argument is! SimpleStringLiteral) {
          fail('Not a literal: ${argument.runtimeType}');
        }

        file.addReplacement(
          _Replacement(
            argument.contentsOffset,
            argument.contentsEnd,
            actual,
          ),
        );

        // Stop after the first (most specific) assert method.
        return;
      }
    }
  }

  static void apply() {
    for (var file in _files.values) {
      file.applyReplacements();
    }
    _files.clear();
  }

  static _File _getFile(String path) {
    return _files[path] ??= _File(path);
  }
}

@reflectiveTest
class UpdateTextExpectations {
  test_applyReplacements() {
    TextExpectationsCollector.apply();
  }
}

sealed class _Argument {
  Expression get(ArgumentList argumentList);
}

final class _ArgumentIndex extends _Argument {
  final int index;

  _ArgumentIndex(this.index);

  @override
  Expression get(ArgumentList argumentList) {
    return argumentList.arguments
        .whereNotType<NamedExpression>()
        .elementAt(index);
  }
}

class _AssertMethod {
  final String methodName;
  final String stackTracePattern;
  final _Argument argument;

  const _AssertMethod({
    required String className,
    required this.methodName,
    required this.argument,
  }) : stackTracePattern = '$className.$methodName';
}

class _File {
  final String path;
  final String content;
  final LineInfo lineInfo;
  final CompilationUnit unit;
  final List<_Replacement> replacements = [];

  factory _File(String path) {
    var content = io.File(path).readAsStringSync();

    var collection = AnalysisContextCollection(
      resourceProvider: PhysicalResourceProvider.INSTANCE,
      includedPaths: [path],
    );
    var analysisContext = collection.contextFor(path);
    var analysisSession = analysisContext.currentSession;
    var parseResult = analysisSession.getParsedUnit(path);
    parseResult as ParsedUnitResult;

    return _File._(
      path: path,
      content: content,
      lineInfo: LineInfo.fromContent(content),
      unit: parseResult.unit,
    );
  }

  _File._({
    required this.path,
    required this.content,
    required this.lineInfo,
    required this.unit,
  });

  void addReplacement(_Replacement replacement) {
    // Check if there is the same replacement.
    for (var existing in replacements) {
      if (existing.offset == replacement.offset) {
        // Sanity check.
        if (existing.end != replacement.end) {
          fail(
            'At offset: ${existing.offset}\n'
            'Existing end: ${existing.end}\n'
            'New end: ${replacement.end}\n',
          );
        }
        if (existing.text != replacement.text) {
          fail(
            'At offset: ${existing.offset}\n'
            'Existing text:\n${existing.text}\n'
            'New text:\n${replacement.end}\n',
          );
        }
        // We already have the same replacement, exit.
        return;
      }
    }

    // This is a new replacement, add it.
    replacements.add(replacement);
  }

  void applyReplacements() {
    replacements.sort((a, b) => b.offset - a.offset);
    var newCode = content;
    for (var replacement in replacements) {
      newCode = newCode.substring(0, replacement.offset) +
          replacement.text +
          newCode.substring(replacement.end);
    }
    io.File(path).writeAsStringSync(newCode);
  }

  MethodInvocation? findInvocation({
    required int invocationLine,
  }) {
    var visitor = _InvocationVisitor(
      lineInfo: lineInfo,
      requestedLine: invocationLine,
    );
    unit.accept(visitor);
    return visitor.result;
  }
}

class _InvocationVisitor extends RecursiveAstVisitor<void> {
  final LineInfo lineInfo;
  final int requestedLine;
  MethodInvocation? result;

  _InvocationVisitor({
    required this.lineInfo,
    required this.requestedLine,
  });

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (result != null) {
      return;
    }

    var nodeLine = lineInfo.getLocation(node.offset).lineNumber;
    if (nodeLine == requestedLine) {
      result = node;
    }

    super.visitMethodInvocation(node);
  }
}

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement(this.offset, this.end, this.text);
}

extension on AstNode {
  bool get isInFailingTest {
    var testMethod = thisOrAncestorOfType<MethodDeclaration>();
    if (testMethod != null && testMethod.name.lexeme.startsWith('test_')) {
      for (var annotation in testMethod.metadata) {
        var name = annotation.name.name;
        if (const {'FailingTest', 'failingTest'}.contains(name)) {
          return true;
        }
      }
    }
    return false;
  }
}
