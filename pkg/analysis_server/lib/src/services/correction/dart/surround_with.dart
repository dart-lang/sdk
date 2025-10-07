// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class SurroundWith extends MultiCorrectionProducer {
  SurroundWith({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    // If the node is the CompilationUnit, the selected statements must span multiple
    // top level items and cannot be surrounded with anything.
    if (node is CompilationUnit) {
      return const [];
    }

    // prepare selected statements
    var selectionAnalyzer = StatementAnalyzer(
      unitResult,
      SourceRange(selectionOffset, selectionLength),
    );
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
        return const [];
      }
    }
    // we want only statements
    if (selectedStatements.isEmpty ||
        selectedStatements.length != selectedNodes.length) {
      return const [];
    }
    // prepare statement information
    var firstStatement = selectedStatements[0];
    var statementsRange = utils.getLinesRangeStatements(selectedStatements);
    // prepare environment
    var indentOld = utils.getNodePrefix(firstStatement);
    var indentNew = '$indentOld${utils.oneIndent}';
    var indentedCode = utils.replaceSourceRangeIndent(
      statementsRange,
      indentOld,
      indentNew,
      includeLeading: true,
      ensureTrailingNewline: true,
    );

    context;
    return [
      _SurroundWithBlock(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
      _SurroundWithDoWhile(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
      _SurroundWithFor(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
      _SurroundWithForIn(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
      _SurroundWithIf(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
      _SurroundWithSetState(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
      _SurroundWithTryCatch(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
      _SurroundWithTryFinally(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
      _SurroundWithWhile(
        statementsRange,
        indentOld,
        indentNew,
        indentedCode,
        context: context,
      ),
    ];
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
abstract class _SurroundWith extends ResolvedCorrectionProducer {
  final SourceRange statementsRange;

  final String indentOld;

  final String indentNew;

  final String indentedCode;

  _SurroundWith(
    this.statementsRange,
    this.indentOld,
    this.indentNew,
    this.indentedCode, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithBlock extends _SurroundWith {
  _SurroundWithBlock(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithBlock;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      builder.addSimpleInsertion(statementsRange.offset, '$indentOld{$eol');
      builder.addSimpleReplacement(
        statementsRange,
        utils.replaceSourceRangeIndent(
          statementsRange,
          indentOld,
          indentNew,
          includeLeading: true,
          ensureTrailingNewline: true,
        ),
      );
      builder.addSimpleInsertion(statementsRange.end, '$indentOld}$eol');
    });
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithDoWhile extends _SurroundWith {
  _SurroundWithDoWhile(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithDoWhile;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('do {');
        builder.writeln();
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('} while (');
        builder.addSimpleLinkedEdit('CONDITION', 'condition');
        builder.write(');');
        builder.selectHere();
        builder.writeln();
      });
    });
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithFor extends _SurroundWith {
  _SurroundWithFor(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithFor;

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
        builder.writeln();
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('}');
        builder.selectHere();
        builder.writeln();
      });
    });
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithForIn extends _SurroundWith {
  _SurroundWithForIn(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithForIn;

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
        builder.writeln();
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('}');
        builder.selectHere();
        builder.writeln();
      });
    });
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithIf extends _SurroundWith {
  _SurroundWithIf(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithIf;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('if (');
        builder.addSimpleLinkedEdit('CONDITION', 'condition');
        builder.write(') {');
        builder.writeln();
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('}');
        builder.selectHere();
        builder.writeln();
      });
    });
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithSetState extends _SurroundWith {
  _SurroundWithSetState(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithSetState;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var classElement = node.parent
        ?.thisOrAncestorOfType<ClassDeclaration>()
        ?.declaredFragment
        ?.element;
    if (classElement != null && classElement.isState) {
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

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithTryCatch extends _SurroundWith {
  _SurroundWithTryCatch(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithTryCatch;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('try {');
        builder.writeln();
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('} on ');
        builder.addSimpleLinkedEdit('EXCEPTION_TYPE', 'Exception');
        builder.write(' catch (');
        builder.addSimpleLinkedEdit('EXCEPTION_VAR', 'e');
        builder.write(') {');
        builder.writeln();
        //
        builder.write(indentNew);
        builder.addSimpleLinkedEdit('CATCH', '// TODO');
        builder.selectHere();
        builder.writeln();
        //
        builder.write(indentOld);
        builder.write('}');
        builder.writeln();
      });
    });
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithTryFinally extends _SurroundWith {
  _SurroundWithTryFinally(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithTryFinally;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('try {');
        builder.writeln();
        //
        builder.write(indentedCode);
        //
        builder.write(indentOld);
        builder.write('} finally {');
        builder.writeln();
        //
        builder.write(indentNew);
        builder.addSimpleLinkedEdit('FINALLY', '// TODO');
        builder.selectHere();
        builder.writeln();
        //
        builder.write(indentOld);
        builder.write('}');
        builder.writeln();
      });
    });
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [SurroundWith] producer.
class _SurroundWithWhile extends _SurroundWith {
  _SurroundWithWhile(
    super.statementsRange,
    super.indentOld,
    super.indentNew,
    super.indentedCode, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.surroundWithWhile;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(statementsRange, (builder) {
        builder.write(indentOld);
        builder.write('while (');
        builder.addSimpleLinkedEdit('CONDITION', 'condition');
        builder.write(') {');
        builder.writeln();
        builder.write(indentedCode);
        builder.write(indentOld);
        builder.write('}');
        builder.selectHere();
        builder.writeln();
      });
    });
  }
}
