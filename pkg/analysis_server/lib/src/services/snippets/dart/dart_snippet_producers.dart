// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/lint/linter.dart' show LinterContextImpl;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// Produces a [Snippet] that creates a Class definition.
class DartClassSnippetProducer extends DartSnippetProducer {
  static const prefix = 'class';
  static const label = 'class';

  DartClassSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write('class ');
        builder.addEmptyLinkedEdit('className');
        builder.writeln(' {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a class definition.',
      builder.sourceChange,
    );
  }

  static DartClassSnippetProducer newInstance(DartSnippetRequest request) =>
      DartClassSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a `do while` loop.
class DartDoWhileLoopSnippetProducer extends DartSnippetProducer {
  static const prefix = 'do';
  static const label = 'do while';

  DartDoWhileLoopSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.writeln('do {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('} while (');
        builder.addEmptyLinkedEdit('expression');
        builder.write(');');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a do-while loop.',
      builder.sourceChange,
    );
  }

  static DartDoWhileLoopSnippetProducer newInstance(
          DartSnippetRequest request) =>
      DartDoWhileLoopSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a `for in` loop.
class DartForInLoopSnippetProducer extends DartSnippetProducer {
  static const prefix = 'forin';
  static const label = 'for in';

  DartForInLoopSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);
    final varOrFinal =
        isLintEnabled(LintNames.prefer_final_locals) ? 'final' : 'var';

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write('for ($varOrFinal ');
        builder.addEmptyLinkedEdit('variableName');
        builder.write(' in ');
        builder.addEmptyLinkedEdit('collectionName');
        builder.writeln(') {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a for-in loop.',
      builder.sourceChange,
    );
  }

  static DartForInLoopSnippetProducer newInstance(DartSnippetRequest request) =>
      DartForInLoopSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a `for` loop.
class DartForLoopSnippetProducer extends DartSnippetProducer {
  static const prefix = 'for';
  static const label = 'for';

  DartForLoopSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write('for (var i = 0; i < ');
        builder.addEmptyLinkedEdit('count');
        builder.writeln('; i++) {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a for loop.',
      builder.sourceChange,
    );
  }

  static DartForLoopSnippetProducer newInstance(DartSnippetRequest request) =>
      DartForLoopSnippetProducer._(request);
}

/// Produces a [Snippet] that creates an if/else statement.
class DartIfElseSnippetProducer extends DartSnippetProducer {
  static const prefix = 'ife';
  static const label = 'ife';

  DartIfElseSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        void writeIndentedln(String string) =>
            builder.writeln('$indent$string');
        builder.write('if (');
        builder.addEmptyLinkedEdit('condition');
        builder.writeln(') {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndentedln('} else {');
        writeIndentedln('  ');
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert an if/else statement.',
      builder.sourceChange,
    );
  }

  static DartIfElseSnippetProducer newInstance(DartSnippetRequest request) =>
      DartIfElseSnippetProducer._(request);
}

/// Produces a [Snippet] that creates an if statement.
class DartIfSnippetProducer extends DartSnippetProducer {
  static const prefix = 'if';
  static const label = 'if';

  DartIfSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write('if (');
        builder.addEmptyLinkedEdit('condition');
        builder.writeln(') {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert an if statement.',
      builder.sourceChange,
    );
  }

  static DartIfSnippetProducer newInstance(DartSnippetRequest request) =>
      DartIfSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a top-level `main` function.
///
/// A `List<String> args` parameter will be included when generating inside a
/// file in `bin` or `tool` folders.
class DartMainFunctionSnippetProducer extends DartSnippetProducer {
  static const prefix = 'main';
  static const label = 'main()';

  DartMainFunctionSnippetProducer._(DartSnippetRequest request)
      : super(request);

  /// Whether to insert a `List<String> args` parameter in the generated
  /// function.
  ///
  /// The parameter is suppressed for any known test directories.
  bool get _insertArgsParameter => !isInTestDirectory;

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);

    final typeProvider = request.unit.typeProvider;
    final listString = typeProvider.listType(typeProvider.stringType);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        builder.writeFunctionDeclaration(
          'main',
          returnType: VoidTypeImpl.instance,
          parameterWriter: _insertArgsParameter
              ? () => builder.writeParameter('args', type: listString)
              : null,
          bodyWriter: () {
            builder.writeln('{');
            builder.write('  ');
            builder.selectHere();
            builder.writeln();
            builder.write('}');
          },
        );
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a main function, used as an entry point.',
      builder.sourceChange,
    );
  }

  static DartMainFunctionSnippetProducer newInstance(
          DartSnippetRequest request) =>
      DartMainFunctionSnippetProducer._(request);
}

abstract class DartSnippetProducer extends SnippetProducer {
  final AnalysisSessionHelper sessionHelper;
  final CorrectionUtils utils;

  DartSnippetProducer(DartSnippetRequest request)
      : sessionHelper = AnalysisSessionHelper(request.analysisSession),
        utils = CorrectionUtils(request.unit),
        super(request);

  bool get isInTestDirectory {
    final path = request.unit.path;
    return LinterContextImpl.testDirectories
        .any((testDir) => path.contains(testDir));
  }

  bool isLintEnabled(String name) {
    var analysisOptions = sessionHelper.session.analysisContext.analysisOptions;
    return analysisOptions.isLintEnabled(name);
  }
}

/// Produces a [Snippet] that creates an if statement.
class DartSwitchSnippetProducer extends DartSnippetProducer {
  static const prefix = 'switch';
  static const label = 'switch case';

  DartSwitchSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        void writeIndentedln(String string) =>
            builder.writeln('$indent$string');
        builder.write('switch (');
        builder.addEmptyLinkedEdit('expression');
        builder.writeln(') {');
        writeIndented('  case ');
        builder.addEmptyLinkedEdit('value');
        builder.writeln(':');
        writeIndented('    ');
        builder.selectHere();
        builder.writeln();
        writeIndentedln('    break;');
        writeIndentedln('  default:');
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a switch statement.',
      builder.sourceChange,
    );
  }

  static DartSwitchSnippetProducer newInstance(DartSnippetRequest request) =>
      DartSwitchSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a `test()` block.
class DartTestBlockSnippetProducer extends DartSnippetProducer {
  static const prefix = 'test';
  static const label = 'test';

  DartTestBlockSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write("test('");
        builder.addEmptyLinkedEdit('testName');
        builder.writeln("', () {");
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('});');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a test block.',
      builder.sourceChange,
    );
  }

  @override
  Future<bool> isValid() async {
    if (!await super.isValid()) {
      return false;
    }

    return isInTestDirectory;
  }

  static DartTestBlockSnippetProducer newInstance(DartSnippetRequest request) =>
      DartTestBlockSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a `test()` block.
class DartTestGroupBlockSnippetProducer extends DartSnippetProducer {
  static const prefix = 'group';
  static const label = 'group';

  DartTestGroupBlockSnippetProducer._(DartSnippetRequest request)
      : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write("group('");
        builder.addEmptyLinkedEdit('groupName');
        builder.writeln("', () {");
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('});');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a test group block.',
      builder.sourceChange,
    );
  }

  @override
  Future<bool> isValid() async {
    if (!await super.isValid()) {
      return false;
    }

    return isInTestDirectory;
  }

  static DartTestGroupBlockSnippetProducer newInstance(
          DartSnippetRequest request) =>
      DartTestGroupBlockSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a try/catch statement.
class DartTryCatchSnippetProducer extends DartSnippetProducer {
  static const prefix = 'try';
  static const label = 'try';

  DartTryCatchSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        void writeIndentedln(String string) =>
            builder.writeln('$indent$string');
        builder.writeln('try {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('} catch (');
        builder.addLinkedEdit('exceptionName', (builder) {
          builder.write('e');
        });
        builder.writeln(') {');
        writeIndentedln('  ');
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a try/catch statement.',
      builder.sourceChange,
    );
  }

  static DartTryCatchSnippetProducer newInstance(DartSnippetRequest request) =>
      DartTryCatchSnippetProducer._(request);
}

/// Produces a [Snippet] that creates a `while` loop.
class DartWhileLoopSnippetProducer extends DartSnippetProducer {
  static const prefix = 'while';
  static const label = 'while';

  DartWhileLoopSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    final builder = ChangeBuilder(session: request.analysisSession);
    final indent = utils.getLinePrefix(request.offset);

    await builder.addDartFileEdit(request.filePath, (builder) {
      builder.addReplacement(request.replacementRange, (builder) {
        void writeIndented(String string) => builder.write('$indent$string');
        builder.write('while (');
        builder.addEmptyLinkedEdit('expression');
        builder.writeln(') {');
        writeIndented('  ');
        builder.selectHere();
        builder.writeln();
        writeIndented('}');
      });
    });

    return Snippet(
      prefix,
      label,
      'Insert a while loop.',
      builder.sourceChange,
    );
  }

  static DartWhileLoopSnippetProducer newInstance(DartSnippetRequest request) =>
      DartWhileLoopSnippetProducer._(request);
}
