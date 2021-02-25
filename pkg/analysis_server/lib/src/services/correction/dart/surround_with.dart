// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class SurroundWith extends MultiCorrectionProducer {
  @override
  Iterable<CorrectionProducer> get producers sync* {
    // If the node is the CompilationUnit, the selected statements must span multiple
    // top level items and cannot be surrounded with anything.
    if (node is CompilationUnit) {
      return;
    }

    // prepare selected statements
    var selectionAnalyzer = StatementAnalyzer(
        resolvedResult, SourceRange(selectionOffset, selectionLength));
    selectionAnalyzer.analyze();
    var selectedNodes = selectionAnalyzer.selectedNodes;
    // convert nodes to statements
    var selectedStatements = <Statement>[];
    for (var selectedNode in selectedNodes) {
      if (selectedNode is Statement) {
        selectedStatements.add(selectedNode);
      }
    }
    // we want only statements in blocks
    for (var statement in selectedStatements) {
      if (statement.parent is! Block) {
        return;
      }
    }
    // we want only statements
    if (selectedStatements.isEmpty ||
        selectedStatements.length != selectedNodes.length) {
      return;
    }
    // prepare statement information
    var firstStatement = selectedStatements[0];
    var statementsRange = utils.getLinesRangeStatements(selectedStatements);
    // prepare environment
    var indentOld = utils.getNodePrefix(firstStatement);
    var indentNew = '$indentOld${utils.getIndent(1)}';
    var indentedCode =
        utils.replaceSourceRangeIndent(statementsRange, indentOld, indentNew);

    yield _SurroundWithBlock(
        statementsRange, indentOld, indentNew, indentedCode);
    yield _SurroundWithDoWhile(
        statementsRange, indentOld, indentNew, indentedCode);
    yield _SurroundWithFor(statementsRange, indentOld, indentNew, indentedCode);
    yield _SurroundWithForIn(
        statementsRange, indentOld, indentNew, indentedCode);
    yield _SurroundWithIf(statementsRange, indentOld, indentNew, indentedCode);
    yield _SurroundWithSetState(
        statementsRange, indentOld, indentNew, indentedCode);
    yield _SurroundWithTryCatch(
        statementsRange, indentOld, indentNew, indentedCode);
    yield _SurroundWithTryFinally(
        statementsRange, indentOld, indentNew, indentedCode);
    yield _SurroundWithWhile(
        statementsRange, indentOld, indentNew, indentedCode);
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static SurroundWith newInstance() => SurroundWith();
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
abstract class _SurroundWith extends CorrectionProducer {
  final SourceRange statementsRange;

  final String indentOld;

  final String indentNew;

  final String indentedCode;

  _SurroundWith(
      this.statementsRange, this.indentOld, this.indentNew, this.indentedCode);
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithBlock extends _SurroundWith {
  _SurroundWithBlock(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_BLOCK;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(statementsRange.offset, '$indentOld{$eol');
      builder.addSimpleReplacement(
          statementsRange,
          utils.replaceSourceRangeIndent(
              statementsRange, indentOld, indentNew));
      builder.addSimpleInsertion(statementsRange.end, '$indentOld}$eol');
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithDoWhile extends _SurroundWith {
  _SurroundWithDoWhile(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_DO_WHILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('do {');
        builder.write(eol);
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('} while (');
        builder.addSimpleLinkedEdit('CONDITION', 'condition');
        builder.write(');');
        builder.selectHere();
        builder.write(eol);
      });
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithFor extends _SurroundWith {
  _SurroundWithFor(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_FOR;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('for (var ');
        builder.addSimpleLinkedEdit('VAR', 'v');
        builder.write(' = ');
        builder.addSimpleLinkedEdit('INIT', 'init');
        builder.write('; ');
        builder.addSimpleLinkedEdit('CONDITION', 'condition');
        builder.write('; ');
        builder.addSimpleLinkedEdit('INCREMENT', 'increment');
        builder.write(') {');
        builder.write(eol);
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('}');
        builder.selectHere();
        builder.write(eol);
      });
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithForIn extends _SurroundWith {
  _SurroundWithForIn(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_FOR_IN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('for (var ');
        builder.addSimpleLinkedEdit('NAME', 'item');
        builder.write(' in ');
        builder.addSimpleLinkedEdit('ITERABLE', 'iterable');
        builder.write(') {');
        builder.write(eol);
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('}');
        builder.selectHere();
        builder.write(eol);
      });
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithIf extends _SurroundWith {
  _SurroundWithIf(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_IF;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('if (');
        builder.addSimpleLinkedEdit('CONDITION', 'condition');
        builder.write(') {');
        builder.write(eol);
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('}');
        builder.selectHere();
        builder.write(eol);
      });
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithSetState extends _SurroundWith {
  _SurroundWithSetState(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_SET_STATE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var classDeclaration = node.parent.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration != null &&
        flutter.isState(classDeclaration.declaredElement)) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(statementsRange, (builder) {
          builder.write(indentOld);
          builder.writeln('setState(() {');
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.selectHere();
          builder.writeln('});');
        });
      });
    }
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithTryCatch extends _SurroundWith {
  _SurroundWithTryCatch(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_TRY_CATCH;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('try {');
        builder.write(eol);
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('} on ');
        builder.addSimpleLinkedEdit('EXCEPTION_TYPE', 'Exception');
        builder.write(' catch (');
        builder.addSimpleLinkedEdit('EXCEPTION_VAR', 'e');
        builder.write(') {');
        builder.write(eol);
        //
        builder.write(indentNew);
        builder.addSimpleLinkedEdit('CATCH', '// TODO');
        builder.selectHere();
        builder.write(eol);
        //
        builder.write(indentOld);
        builder.write('}');
        builder.write(eol);
      });
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithTryFinally extends _SurroundWith {
  _SurroundWithTryFinally(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_TRY_FINALLY;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('try {');
        builder.write(eol);
        //
        builder.write(indentedCode);
        //
        builder.write(indentOld);
        builder.write('} finally {');
        builder.write(eol);
        //
        builder.write(indentNew);
        builder.addSimpleLinkedEdit('FINALLY', '// TODO');
        builder.selectHere();
        builder.write(eol);
        //
        builder.write(indentOld);
        builder.write('}');
        builder.write(eol);
      });
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [SurroundWith] producer.
class _SurroundWithWhile extends _SurroundWith {
  _SurroundWithWhile(SourceRange statementsRange, String indentOld,
      String indentNew, String indentedCode)
      : super(statementsRange, indentOld, indentNew, indentedCode);

  @override
  AssistKind get assistKind => DartAssistKind.SURROUND_WITH_WHILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('while (');
        builder.addSimpleLinkedEdit('CONDITION', 'condition');
        builder.write(') {');
        builder.write(eol);
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('}');
        builder.selectHere();
        builder.write(eol);
      });
    });
  }
}
