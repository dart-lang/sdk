// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/util.dart';
import 'package:dart2js_info/src/io.dart';

import 'inject_text.dart';
import 'usage_exception.dart';

/// Shows the contents of an info file as text.
class ShowCommand extends Command<void> with PrintUsageException {
  final String name = "show";
  final String description = "Show a text representation of the info file.";

  ShowCommand() {
    argParser.addOption('out',
        abbr: 'o', help: 'Output file (defauts to stdout)');

    argParser.addFlag('inject-text',
        negatable: false,
        help: 'Whether to inject output code snippets.\n\n'
            'By default dart2js produces code spans, but excludes the text. This\n'
            'option can be used to embed the text directly in the output.');
  }

  void run() async {
    if (argResults.rest.length < 1) {
      usageException('Missing argument: <input-info>');
    }

    String filename = argResults.rest[0];
    AllInfo info = await infoFromFile(filename);
    if (argResults['inject-text']) injectText(info);

    var buffer = new StringBuffer();
    info.accept(new TextPrinter(buffer, argResults['inject-text']));
    var outputPath = argResults['out'];
    if (outputPath == null) {
      print(buffer);
    } else {
      new File(outputPath).writeAsStringSync('$buffer');
    }
  }
}

class TextPrinter implements InfoVisitor<void> {
  final StringBuffer buffer;
  final bool injectText;

  TextPrinter(this.buffer, this.injectText);

  int _indent = 0;
  String get _textIndent => "  " * _indent;
  void _writeIndentation() {
    buffer.write(_textIndent);
  }

  void _writeIndented(String s) {
    _writeIndentation();
    buffer.writeln(s.replaceAll('\n', '\n$_textIndent'));
  }

  void _writeBlock(String s, void f()) {
    _writeIndented("$s");
    _indent++;
    f();
    _indent--;
  }

  void visitAll(AllInfo info) {
    _writeBlock("Summary data", () => visitProgram(info.program));
    buffer.writeln();
    _writeBlock("Libraries", () => info.libraries.forEach(visitLibrary));
    // Note: classes, functions, typedefs, and fields are group;ed by library.

    if (injectText) {
      _writeBlock("Constants", () => info.constants.forEach(visitConstant));
    } else {
      int size = info.constants.fold(0, (n, c) => n + c.size);
      _writeIndented("All constants: ${_size(size)}");
    }
    _writeBlock("Output units", () => info.outputUnits.forEach(visitOutput));
  }

  void visitProgram(ProgramInfo info) {
    _writeIndented('main: ${longName(info.entrypoint, useLibraryUri: true)}');
    _writeIndented('size: ${info.size}');
    _writeIndented('dart2js-version: ${info.dart2jsVersion}');
    var features = [];
    if (info.noSuchMethodEnabled) features.add('no-such-method');
    if (info.isRuntimeTypeUsed) features.add('runtime-type');
    if (info.isFunctionApplyUsed) features.add('function-apply');
    if (info.minified) features.add('minified');
    if (features.isNotEmpty) {
      _writeIndented('features: ${features.join(' ')}');
    }
  }

  String _size(int size) {
    if (size < 1024) return "$size b";
    if (size < (1024 * 1024)) {
      return "${(size / 1024).toStringAsFixed(2)} Kb ($size b)";
    }
    return "${(size / (1024 * 1024)).toStringAsFixed(2)} Mb ($size b)";
  }

  void visitLibrary(LibraryInfo info) {
    _writeBlock('${info.uri}: ${_size(info.size)}', () {
      if (info.topLevelFunctions.isNotEmpty) {
        _writeBlock('Top-level functions',
            () => info.topLevelFunctions.forEach(visitFunction));
        buffer.writeln();
      }
      if (info.topLevelVariables.isNotEmpty) {
        _writeBlock('Top-level variables',
            () => info.topLevelVariables.forEach(visitField));
        buffer.writeln();
      }
      if (info.classes.isNotEmpty) {
        _writeBlock('Classes', () => info.classes.forEach(visitClass));
      }
      if (info.typedefs.isNotEmpty) {
        _writeBlock("Typedefs", () => info.typedefs.forEach(visitTypedef));
        buffer.writeln();
      }
      buffer.writeln();
    });
  }

  void visitClass(ClassInfo info) {
    _writeBlock(
        '${info.name}: ${_size(info.size)} [${info.outputUnit.filename}]', () {
      if (info.functions.isNotEmpty) {
        _writeBlock('Methods:', () => info.functions.forEach(visitFunction));
      }
      if (info.fields.isNotEmpty) {
        _writeBlock('Fields:', () => info.fields.forEach(visitField));
      }
      if (info.functions.isNotEmpty || info.fields.isNotEmpty) buffer.writeln();
    });
  }

  void visitField(FieldInfo info) {
    _writeBlock('${info.type} ${info.name}: ${_size(info.size)}', () {
      _writeIndented('inferred type: ${info.inferredType}');
      if (injectText) _writeBlock("code:", () => _writeCode(info.code));
      if (info.closures.isNotEmpty) {
        _writeBlock('Closures:', () => info.closures.forEach(visitClosure));
      }
      if (info.uses.isNotEmpty) {
        _writeBlock('Dependencies:', () => info.uses.forEach(showDependency));
      }
    });
  }

  void visitFunction(FunctionInfo info) {
    var outputUnitFile = '';
    if (info.functionKind == FunctionInfo.TOP_LEVEL_FUNCTION_KIND) {
      outputUnitFile = ' [${info.outputUnit.filename}]';
    }
    String params =
        info.parameters.map((p) => "${p.declaredType} ${p.name}").join(', ');
    _writeBlock(
        '${info.returnType} ${info.name}($params): ${_size(info.size)}$outputUnitFile',
        () {
      String params = info.parameters.map((p) => "${p.type}").join(', ');
      _writeIndented('declared type: ${info.type}');
      _writeIndented(
          'inferred type: ${info.inferredReturnType} Function($params)');
      _writeIndented('side effects: ${info.sideEffects}');
      if (injectText) _writeBlock("code:", () => _writeCode(info.code));
      if (info.closures.isNotEmpty) {
        _writeBlock('Closures:', () => info.closures.forEach(visitClosure));
      }
      if (info.uses.isNotEmpty) {
        _writeBlock('Dependencies:', () => info.uses.forEach(showDependency));
      }
    });
  }

  void showDependency(DependencyInfo info) {
    var mask = info.mask ?? '';
    _writeIndented('- ${longName(info.target, useLibraryUri: true)} $mask');
  }

  void visitTypedef(TypedefInfo info) {
    _writeIndented('${info.name}: ${info.type}');
  }

  void visitClosure(ClosureInfo info) {
    _writeBlock('${info.name}', () => visitFunction(info.function));
  }

  void visitConstant(ConstantInfo info) {
    _writeBlock('${_size(info.size)}:', () => _writeCode(info.code));
  }

  void _writeCode(List<CodeSpan> code) {
    _writeIndented(code.map((c) => c.text).join('\n'));
  }

  void visitOutput(OutputUnitInfo info) {
    _writeIndented('${info.filename}: ${_size(info.size)}');
  }
}
