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
import 'package:path/src/context.dart';

import '../../test/utils/package_root.dart' as package_root;

/// Generate the file `diagnostics.md` based on the documentation associated
/// with the declarations of the error codes.
void main() async {
  IOSink sink = File(computeOutputPath()).openWrite();
  DocumentationGenerator generator = DocumentationGenerator(computeCodePaths());
  generator.writeDocumentation(sink);
  await sink.flush();
  await sink.close();
}

/// Compute a list of the code paths for the files containing diagnostics that
/// have been documented.
List<CodePath> computeCodePaths() {
  Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  String packageRoot = pathContext.normalize(package_root.packageRoot);
  String analyzerPath = pathContext.join(packageRoot, 'analyzer');
  return CodePath.from([
    [analyzerPath, 'lib', 'src', 'dart', 'error', 'hint_codes.dart'],
    [analyzerPath, 'lib', 'src', 'dart', 'error', 'syntactic_errors.dart'],
    [analyzerPath, 'lib', 'src', 'error', 'codes.dart'],
  ], [
    null,
    [analyzerPath, 'lib', 'src', 'dart', 'error', 'syntactic_errors.g.dart'],
    null,
  ]);
}

/// Compute the path to the file into which documentation is being generated.
String computeOutputPath() {
  Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  String packageRoot = pathContext.normalize(package_root.packageRoot);
  String analyzerPath = pathContext.join(packageRoot, 'analyzer');
  return pathContext.join(
      analyzerPath, 'tool', 'diagnostics', 'diagnostics.md');
}

/// A representation of the paths to the documentation and declaration of a set
/// of diagnostic codes.
class CodePath {
  /// The path to the file containing the declarations of the diagnostic codes
  /// that might have documentation associated with them.
  final String documentationPath;

  /// The path to the file containing the generated definition of the diagnostic
  /// codes that include the message, or `null` if the
  final String declarationPath;

  /// Initialize a newly created code path from the [documentationPath] and
  /// [declarationPath].
  CodePath(this.documentationPath, this.declarationPath);

  /// Return a list of code paths computed by joining the path segments in the
  /// corresponding lists from [documentationPaths] and [declarationPaths].
  static List<CodePath> from(List<List<String>> documentationPaths,
      List<List<String>> declarationPaths) {
    Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    List<CodePath> paths = [];
    for (int i = 0; i < documentationPaths.length; i++) {
      String docPath = pathContext.joinAll(documentationPaths[i]);
      String declPath;
      if (declarationPaths[i] != null) {
        declPath = pathContext.joinAll(declarationPaths[i]);
      }
      paths.add(CodePath(docPath, declPath));
    }
    return paths;
  }
}

/// A class used to generate diagnostic documentation.
class DocumentationGenerator {
  /// The absolute paths of the files containing the declarations of the error
  /// codes.
  final List<CodePath> codePaths;

  /// A map from the name of a diagnostic code to the lines of the documentation
  /// for that code.
  Map<String, List<String>> docsByCode = {};

  /// Initialize a newly created documentation generator.
  DocumentationGenerator(this.codePaths) {
    _extractAllDocs();
  }

  /// Write the documentation to the file at the given [outputPath].
  void writeDocumentation(StringSink sink) {
    _writeHeader(sink);
    _writeGlossary(sink);
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
    List<String> includedPaths = [];
    for (CodePath codePath in codePaths) {
      includedPaths.add(codePath.documentationPath);
      if (codePath.declarationPath != null) {
        includedPaths.add(codePath.declarationPath);
      }
    }
    AnalysisContextCollection collection = new AnalysisContextCollection(
        includedPaths: includedPaths,
        resourceProvider: PhysicalResourceProvider.INSTANCE);
    for (CodePath codePath in codePaths) {
      String docPath = codePath.documentationPath;
      String declPath = codePath.declarationPath;
      if (declPath == null) {
        _extractDocs(_parse(collection, docPath), null);
      } else {
        File file = File(declPath);
        if (file.existsSync()) {
          _extractDocs(
              _parse(collection, docPath), _parse(collection, declPath));
        } else {
          _extractDocs(_parse(collection, docPath), null);
        }
      }
    }
  }

  /// Extract documentation from the given [field] declaration.
  List<String> _extractDoc(FieldDeclaration field) {
    Token comments = field.firstTokenAfterCommentAndMetadata.precedingComments;
    if (comments == null) {
      return null;
    }
    List<String> docs = [];
    bool inDartCodeBlock = false;
    while (comments != null) {
      String lexeme = comments.lexeme;
      if (lexeme.startsWith('// TODO')) {
        break;
      } else if (lexeme.startsWith('// %')) {
        // Ignore lines containing directives for testing support.
      } else if (lexeme.startsWith('// ')) {
        String trimmedLine = lexeme.substring(3);
        if (trimmedLine == '```dart') {
          inDartCodeBlock = true;
          docs.add('{% prettify dart %}');
        } else if (trimmedLine == '```') {
          if (inDartCodeBlock) {
            docs.add('{% endprettify %}');
            inDartCodeBlock = false;
          } else {
            docs.add(trimmedLine);
          }
        } else {
          docs.add(trimmedLine);
        }
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
  /// [result]. If a [generatedResult] is provided, then the messages might be
  /// in the file parsed to produce the result.
  void _extractDocs(ParsedUnitResult result, ParsedUnitResult generatedResult) {
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
                  _extractMessage(variable.initializer, generatedResult);
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

  /// Extract the message from the [expression]. If the expression is the name
  /// of a generated code, then the [generatedResult] should have the unit in
  /// which the message can be found.
  String _extractMessage(
      Expression expression, ParsedUnitResult generatedResult) {
    if (expression is InstanceCreationExpression) {
      return (expression.argumentList.arguments[1] as StringLiteral)
          .stringValue;
    } else if (expression is SimpleIdentifier && generatedResult != null) {
      VariableDeclaration variable =
          _findVariable(expression.name, generatedResult.unit);
      if (variable != null) {
        return _extractMessage(variable.initializer, null);
      }
    }
    throw StateError(
        'Cannot extract a message from a ${expression.runtimeType}');
  }

  /// Return the declaration of the top-level variable with the [name] in the
  /// compilation unit, or `null` if there is no such variable.
  VariableDeclaration _findVariable(String name, CompilationUnit unit) {
    for (CompilationUnitMember member in unit.declarations) {
      if (member is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in member.variables.variables) {
          if (variable.name.name == name) {
            return variable;
          }
        }
      }
    }
    return null;
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

  /// Write the glossary.
  void _writeGlossary(StringSink sink) {
    sink.write('''

## Glossary

This page uses the following terms.

### Constant context

A _constant context_ is a region of code in which it isn't necessary to include
the `const` keyword because it's implied by the fact that everything in that
region is required to be a constant. The following locations are constant
contexts:

* Everything inside a list, map or set literal that's prefixed by the
  `const` keyword. Example:

  ```dart
  var l = const [/*constant context*/];
  ```

* The arguments inside an invocation of a constant constructor. Example:

  ```dart
  var p = const Point(/*constant context*/);
  ```

* The initializer for a variable that's prefixed by the `const` keyword.
  Example:

  ```dart
  const v = /*constant context*/;
  ```

* Annotations

* The expression in a case clause. Example:

  ```dart
  void f(int e) {
    switch (e) {
      case /*constant context*/:
        break;
    }
  }
  ```
''');

//### Potentially non-nullable
//
//A type is _potentially non-nullable_ if it's either explicitly non-nullable or
//if it's a type parameter. The latter case is included because the actual runtime
//type might be non-nullable.
  }

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
