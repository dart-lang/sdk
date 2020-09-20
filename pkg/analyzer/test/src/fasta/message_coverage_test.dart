// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/parser_fasta_test.dart';
import '../../utils/package_root.dart' as package_root;

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractRecoveryTest);
  });
}

@reflectiveTest
class AbstractRecoveryTest extends FastaParserTestCase {
  /// Given the path to the file containing the declaration of the fasta Parser,
  /// return a set containing the names of all the messages and templates that
  /// are referenced (presumably because they are being generated) within that
  /// file.
  Set<String> getGeneratedNames(String parserPath) {
    String content = io.File(parserPath).readAsStringSync();
    CompilationUnit unit = parseCompilationUnit(content);
    expect(unit, isNotNull);
    GeneratedCodesVisitor visitor = GeneratedCodesVisitor();
    unit.accept(visitor);
    return visitor.generatedNames;
  }

  /// Given the path to the file 'messages.yaml', return a list of the top-level
  /// keys defined in that file that define an 'analyzerCode'.
  List<String> getMappedCodes(String messagesPath) {
    String content = io.File(messagesPath).readAsStringSync();
    YamlDocument document = loadYamlDocument(content);
    expect(document, isNotNull);
    Set<String> codes = <String>{};
    YamlNode contents = document.contents;
    if (contents is YamlMap) {
      for (String name in contents.keys) {
        Object value = contents[name];
        if (value is YamlMap) {
          if (value['analyzerCode'] != null) {
            codes.add(name);
          }
        }
      }
    }
    return codes.toList();
  }

  /// Given the path to the file 'messages.yaml', return a list of the analyzer
  /// codes defined in that file.
  List<String> getReferencedCodes(String messagesPath) {
    String content = io.File(messagesPath).readAsStringSync();
    YamlDocument document = loadYamlDocument(content);
    expect(document, isNotNull);
    Set<String> codes = <String>{};
    YamlNode contents = document.contents;
    if (contents is YamlMap) {
      for (String name in contents.keys) {
        Object value = contents[name];
        if (value is YamlMap) {
          String code = value['analyzerCode']?.toString();
          if (code != null) {
            codes.add(code);
          }
        }
      }
    }
    return codes.toList();
  }

  /// Given the path to the file containing the declaration of the AstBuilder,
  /// return a list of the analyzer codes that are translated by the builder.
  List<String> getTranslatedCodes(String astBuilderPath) {
    String content = io.File(astBuilderPath).readAsStringSync();
    CompilationUnit unit = parseCompilationUnit(content);
    ClassDeclaration astBuilder = unit.declarations[0];
    expect(astBuilder, isNotNull);
    MethodDeclaration method = astBuilder.members.firstWhere(
        (x) => x is MethodDeclaration && x.name.name == 'reportMessage',
        orElse: () => null);
    expect(method, isNotNull);
    SwitchStatement statement = (method.body as BlockFunctionBody)
        .block
        .statements
        .firstWhere((x) => x is SwitchStatement, orElse: () => null);
    expect(statement, isNotNull);
    List<String> codes = <String>[];
    for (SwitchMember member in statement.members) {
      if (member is SwitchCase) {
        codes.add((member.expression as StringLiteral).stringValue);
      }
    }
    return codes;
  }

  @failingTest
  test_mappedMessageCoverage() {
    String frontEndPath = path.join(package_root.packageRoot, 'front_end');
    String parserPath =
        path.join(frontEndPath, 'lib', 'src', 'fasta', 'parser', 'parser.dart');
    Set<String> generatedNames = getGeneratedNames(parserPath);

    String messagesPath = path.join(frontEndPath, 'messages.yaml');
    List<String> mappedCodes = getMappedCodes(messagesPath);

    generatedNames.removeAll(mappedCodes);
    if (generatedNames.isEmpty) {
      return;
    }
    List<String> sortedNames = generatedNames.toList()..sort();
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Generated parser errors without analyzer codes:');
    for (String name in sortedNames) {
      buffer.write('  ');
      buffer.writeln(name);
    }
    fail(buffer.toString());
  }

  @failingTest
  test_translatedMessageCoverage() {
    String analyzerPath = path.join(package_root.packageRoot, 'analyzer');
    String astBuilderPath =
        path.join(analyzerPath, 'lib', 'src', 'fasta', 'error_converter.dart');
    List<String> translatedCodes = getTranslatedCodes(astBuilderPath);

    String messagesPath =
        path.join(path.dirname(analyzerPath), 'front_end', 'messages.yaml');
    List<String> referencedCodes = getReferencedCodes(messagesPath);

    List<String> untranslated = <String>[];
    for (String referencedCode in referencedCodes) {
      if (!translatedCodes.contains(referencedCode)) {
        untranslated.add(referencedCode);
      }
    }
    StringBuffer buffer = StringBuffer();
    if (untranslated.isNotEmpty) {
      buffer
          .writeln('Analyzer codes used in messages.yaml but not translated:');
      for (String code in untranslated) {
        buffer.write('  ');
        buffer.writeln(code);
      }
      buffer.write(
          'Add a case for these codes to FastaErrorReporter.reportError.');
    }

    List<String> unreferenced = <String>[];
    for (String translatedCode in translatedCodes) {
      if (!referencedCodes.contains(translatedCode)) {
        unreferenced.add(translatedCode);
      }
    }
    if (untranslated.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.writeln(
          'Analyzer codes that are translated but not used in messages.yaml:');
      for (String code in unreferenced) {
        buffer.write('  ');
        buffer.writeln(code);
      }
      buffer.write('Remove the cases for these codes from '
          'FastaErrorReporter.reportMessage.');
    }
    if (buffer.isNotEmpty) {
      fail(buffer.toString());
    }
  }
}

/// A visitor that gathers the names of all the message codes that are generated
/// in the visited AST. This assumes that the codes are accessed via the prefix
/// 'fasta'.
class GeneratedCodesVisitor extends RecursiveAstVisitor {
  /// The names of the message codes that are generated in the visited AST.
  Set<String> generatedNames = <String>{};

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'fasta') {
      String name = node.identifier.name;
      if (name.startsWith('message')) {
        name = name.substring(7);
      } else if (name.startsWith('template')) {
        name = name.substring(8);
      } else {
        return;
      }
      generatedNames.add(name);
    }
  }
}
