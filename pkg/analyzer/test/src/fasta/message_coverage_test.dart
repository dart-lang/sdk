// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/parser_fasta_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractRecoveryTest);
  });
}

@reflectiveTest
class AbstractRecoveryTest extends FastaParserTestCase {
  List<String> getReferencedCodes(String messagesPath) {
    String content = new io.File(messagesPath).readAsStringSync();
    YamlDocument document = loadYamlDocument(content);
    expect(document, isNotNull);
    Set<String> codes = new Set<String>();
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

  List<String> getTranslatedCodes(String astBuilderPath) {
    String content = new io.File(astBuilderPath).readAsStringSync();
    CompilationUnit unit = parseCompilationUnit(content);
    ClassDeclaration astBuilder = unit.declarations[0];
    expect(astBuilder, isNotNull);
    MethodDeclaration method = astBuilder.members.firstWhere(
        (x) =>
            x is MethodDeclaration &&
            x.name.name == 'addCompileTimeErrorWithLength',
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

  test_messageCoverage() {
    String analyzerPath = new io.File.fromUri(io.Platform.script).path;
    while (path.basename(analyzerPath) != 'analyzer') {
      String previousPath = analyzerPath;
      analyzerPath = path.dirname(analyzerPath);
      if (analyzerPath == previousPath) {
        fail('Could not find the path to the analyzer package.');
      }
    }

    String astBuilderPath =
        path.join(analyzerPath, 'lib', 'src', 'fasta', 'ast_builder.dart');
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
    expect(untranslated, isEmpty, reason: 'Referenced but not translated');

    List<String> unreferenced = <String>[];
    for (String translatedCode in translatedCodes) {
      if (!referencedCodes.contains(translatedCode)) {
        unreferenced.add(translatedCode);
      }
    }
    expect(unreferenced, isEmpty, reason: 'Translated but not referenced');
  }
}
