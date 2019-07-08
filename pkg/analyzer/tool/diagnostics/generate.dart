// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:front_end/src/testing/package_root.dart' as package_root;
import 'package:path/src/context.dart';

/// Generate the file `diagnostics.md` based on the documentation associated
/// with the declarations of the error codes.
void main() async {
  Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  String packageRoot = pathContext.normalize(package_root.packageRoot);
  String analyzerPath = pathContext.join(packageRoot, 'analyzer');
  List<String> docPaths = [
    pathContext.join(
        analyzerPath, 'lib', 'src', 'dart', 'error', 'hint_codes.dart'),
    pathContext.join(analyzerPath, 'lib', 'src', 'error', 'codes.dart'),
  ];
  String outputPath =
      pathContext.join(analyzerPath, 'tool', 'diagnostics', 'diagnostics.md');

  IOSink sink = File(outputPath).openWrite();
  DocumentationGenerator generator = DocumentationGenerator(docPaths);
  generator.writeDocumentation(sink);
  await sink.flush();
  await sink.close();
}

/// A class used to generate diagnostic documentation.
class DocumentationGenerator {
  /// The absolute paths of the files containing the declarations of the error
  /// codes.
  final List<String> docPaths;

  /// A map from the name of a diagnostic code to the lines of the documentation
  /// for that code.
  Map<String, List<String>> docsByCode = {};

  /// Initialize a newly created documentation generator.
  DocumentationGenerator(this.docPaths) {
    _extractAllDocs();
  }

  /// Write the documentation to the file at the given [outputPath].
  void writeDocumentation(StringSink sink) {
    _writeHeader(sink);
//    _writeGlossary(sink);
    _writeDiagnostics(sink);
  }

  /// Return a version of the [text] in which characters that have special
  /// meaning in markdown have been escaped.
  String _escape(String text) {
    return text.replaceAll('_', '\\_');
  }

  /// Extract documentation from all of the files containing the definitions of
  /// diagnostics.
  void _extractAllDocs() {
    AnalysisContextCollection collection = new AnalysisContextCollection(
        includedPaths: docPaths,
        resourceProvider: PhysicalResourceProvider.INSTANCE);
    for (String docPath in docPaths) {
      _extractDocs(_parse(collection, docPath));
    }
  }

  /// Extract documentation from the given [field] declaration.
  List<String> _extractDoc(FieldDeclaration field) {
    Token comments = field.firstTokenAfterCommentAndMetadata.precedingComments;
    if (comments == null) {
      return null;
    }
    List<String> docs = [];
    while (comments != null) {
      String lexeme = comments.lexeme;
      if (lexeme.startsWith('// TODO')) {
        break;
      } else if (lexeme.startsWith('// ')) {
        docs.add(lexeme.substring(3));
      } else if (lexeme == '//') {
        docs.add('');
      }
      comments = comments.next;
    }
    if (docs.isEmpty) {
      return null;
    }
    return docs;
  }

  /// Extract documentation from the file that was parsed to produce the given
  /// [result].
  void _extractDocs(ParsedUnitResult result) {
    CompilationUnit unit = result.unit;
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        for (ClassMember member in declaration.members) {
          if (member is FieldDeclaration) {
            List<String> docs = _extractDoc(member);
            if (docs != null) {
              VariableDeclaration variable = member.fields.variables[0];
              String variableName = variable.name.name;
              if (docsByCode.containsKey(variableName)) {
                throw StateError('Duplicate diagnostic code');
              }
              String message =
                  ((variable.initializer as InstanceCreationExpression)
                          .argumentList
                          .arguments[1] as StringLiteral)
                      .stringValue;
              docs = [
                '### ${variableName.toLowerCase()}',
                '',
                ..._split('_${_escape(message)}_'),
                '',
                ...docs,
              ];
              docsByCode[variableName] = docs;
            }
          }
        }
      }
    }
  }

  /// Use the analysis context [collection] to parse the file at the given
  /// [path] and return the result.
  ParsedUnitResult _parse(AnalysisContextCollection collection, String path) {
    AnalysisSession session = collection.contextFor(path).currentSession;
    if (session == null) {
      throw new StateError('No session for "$path"');
    }
    ParsedUnitResult result = session.getParsedUnit(path);
    if (result.state != ResultState.VALID) {
      throw new StateError('Unable to parse "$path"');
    }
    return result;
  }

  /// Split the [message] into multiple lines, each of which is less than 80
  /// characters long.
  List<String> _split(String message) {
    // This uses a brute force approach because we don't expect to have messages
    // that need to be split more than once.
    int length = message.length;
    if (length <= 80) {
      return [message];
    }
    int endIndex = message.lastIndexOf(' ', 80);
    if (endIndex < 0) {
      return [message];
    }
    return [message.substring(0, endIndex), message.substring(endIndex + 1)];
  }

  /// Write the documentation for all of the diagnostics.
  void _writeDiagnostics(StringSink sink) {
    sink.write('''

## Diagnostics

The analyzer produces the following diagnostics for code that
doesn't conform to the language specification or
that might work in unexpected ways.
''');
    List<String> errorCodes = docsByCode.keys.toList();
    errorCodes.sort();
    for (String errorCode in errorCodes) {
      List<String> docs = docsByCode[errorCode];
      sink.writeln();
      for (String line in docs) {
        sink.writeln(line);
      }
    }
  }

//  /// Write the glossary.
//  void _writeGlossary(StringSink sink) {
//    sink.write('''
//
//## Glossary
//
//This page uses the following terms.
//
//### Potentially non-nullable
//
//A type is _potentially non-nullable_ if it's either explicitly non-nullable or
//if it's a type parameter. The latter case is included because the actual runtime
//type might be non-nullable.
//''');
//  }

  /// Write the header of the file.
  void _writeHeader(StringSink sink) {
    sink.write('''
---
title: Diagnostics
description: Details for diagnostics produced by the Dart analyzer.
---
{%- comment %}
WARNING: Do NOT EDIT this file directly. It is autogenerated by the script in
`pkg/analyzer/tool/diagnostics/generate.dart` in the sdk repository.
{% endcomment -%}

This page lists diagnostic messages produced by the Dart analyzer,
with details about what those messages mean and how you can fix your code.
For more information about the analyzer, see
[Customizing static analysis](/guides/language/analysis-options).
''');
  }
}
