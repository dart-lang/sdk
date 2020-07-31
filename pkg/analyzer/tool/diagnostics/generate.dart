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

/// An information holder containing information about a diagnostic that was
/// extracted from the instance creation expression.
class DiagnosticInformation {
  /// The name of the diagnostic.
  final String name;

  /// The messages associated with the diagnostic.
  List<String> messages;

  /// The lines of documentation associated with the diagnostic.
  List<String> documentation;

  /// Initialize a newly created information holder with the given [name] and
  /// [message].
  DiagnosticInformation(this.name, String message) : messages = [message];

  /// Return `true` if this diagnostic has documentation.
  bool get hasDocumentation => documentation != null;

  /// Return the full documentation for this diagnostic.
  void writeOn(StringSink sink) {
    messages.sort();
    sink.writeln('### ${name.toLowerCase()}');
    for (String message in messages) {
      sink.writeln();
      for (String line in _split('_${_escape(message)}_')) {
        sink.writeln(line);
      }
    }
    sink.writeln();
    for (String line in documentation) {
      sink.writeln(line);
    }
  }

  /// Return a version of the [text] in which characters that have special
  /// meaning in markdown have been escaped.
  String _escape(String text) {
    return text.replaceAll('_', '\\_');
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
}

/// A class used to generate diagnostic documentation.
class DocumentationGenerator {
  /// The absolute paths of the files containing the declarations of the error
  /// codes.
  final List<CodePath> codePaths;

  /// A map from the name of a diagnostic to the information about that
  /// diagnostic.
  Map<String, DiagnosticInformation> infoByName = {};

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
    AnalysisContextCollection collection = AnalysisContextCollection(
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

  /// Extract information about a diagnostic from the [expression], or `null` if
  /// the expression does not appear to be creating an error code. If the
  /// expression is the name of a generated code, then the [generatedResult]
  /// should have the unit in which the information can be found.
  DiagnosticInformation _extractDiagnosticInformation(
      Expression expression, ParsedUnitResult generatedResult) {
    List<Expression> arguments;
    if (expression is InstanceCreationExpression) {
      arguments = expression.argumentList.arguments;
    } else if (expression is MethodInvocation) {
      var name = expression.methodName.name;
      if (name.endsWith('Code') || name.endsWith('CodeWithUniqueName')) {
        arguments = expression.argumentList.arguments;
      }
    }
    if (arguments != null) {
      String name = _extractName(arguments);
      String message = _extractMessage(arguments);
      DiagnosticInformation info = infoByName[name];
      if (info == null) {
        info = DiagnosticInformation(name, message);
        infoByName[name] = info;
      } else {
        info.messages.add(message);
      }
      return info;
    }

    if (expression is SimpleIdentifier && generatedResult != null) {
      VariableDeclaration variable =
          _findVariable(expression.name, generatedResult.unit);
      if (variable != null) {
        return _extractDiagnosticInformation(variable.initializer, null);
      }
    }

    return null;
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
          docs.add('{% prettify dart tag=pre+code %}');
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
      if (declaration is ClassDeclaration &&
          declaration.name.name != 'StrongModeCode') {
        for (ClassMember member in declaration.members) {
          if (member is FieldDeclaration &&
              member.isStatic &&
              !_isDeprecated(member)) {
            VariableDeclaration variable = member.fields.variables[0];
            DiagnosticInformation info = _extractDiagnosticInformation(
                variable.initializer, generatedResult);
            if (info != null) {
              List<String> docs = _extractDoc(member);
              if (docs != null) {
                if (info.documentation != null) {
                  throw StateError(
                      'Documentation defined multiple times for ${info.name}');
                }
                info.documentation = docs;
              }
            }
          }
        }
      }
    }
  }

  /// Return the message extracted from the list of [arguments].
  String _extractMessage(NodeList<Expression> arguments) {
    int positionalCount =
        arguments.where((expression) => expression is! NamedExpression).length;
    if (positionalCount == 2) {
      return _extractString(arguments[1]);
    } else if (positionalCount == 3) {
      return _extractString(arguments[2]);
    } else {
      throw StateError(
          'Invalid number of positional arguments: $positionalCount');
    }
  }

  /// Return the name extracted from the list of [arguments].
  String _extractName(NodeList<Expression> arguments) =>
      _extractString(arguments[0]);

  String _extractString(Expression expression) {
    if (expression is StringLiteral) {
      return expression.stringValue;
    }
    throw StateError('Cannot extract string from $expression');
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

  /// Return `true` if the [field] is marked as being deprecated.
  bool _isDeprecated(FieldDeclaration field) =>
      field.metadata.any((annotation) => annotation.name.name == 'Deprecated');

  /// Use the analysis context [collection] to parse the file at the given
  /// [path] and return the result.
  ParsedUnitResult _parse(AnalysisContextCollection collection, String path) {
    AnalysisSession session = collection.contextFor(path).currentSession;
    if (session == null) {
      throw StateError('No session for "$path"');
    }
    ParsedUnitResult result = session.getParsedUnit(path);
    if (result.state != ResultState.VALID) {
      throw StateError('Unable to parse "$path"');
    }
    return result;
  }

  /// Write the documentation for all of the diagnostics.
  void _writeDiagnostics(StringSink sink) {
    sink.write('''

## Diagnostics

The analyzer produces the following diagnostics for code that
doesn't conform to the language specification or
that might work in unexpected ways.
''');
    List<String> errorCodes = infoByName.keys.toList();
    errorCodes.sort();
    for (String errorCode in errorCodes) {
      DiagnosticInformation info = infoByName[errorCode];
      if (info.hasDocumentation) {
        sink.writeln();
        info.writeOn(sink);
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

* The expression in a `case` clause. Example:

  ```dart
  void f(int e) {
    switch (e) {
      case /*constant context*/:
        break;
    }
  }
  ```

### Potentially non-nullable

A type is _potentially non-nullable_ if it's either explicitly non-nullable or
if it's a type parameter.

A type is explicitly non-nullable if it is a type name that isn't followed by a
question mark. Note that there are a few types that are always nullable, such as
`Null` and `dynamic`, and that `FutureOr` is only non-nullable if it isn't
followed by a question mark _and_ the type argument is non-nullable (such as
`FutureOr<String>`).

Type parameters are potentially non-nullable because the actual runtime type
(the type specified as a type argument) might be non-nullable. For example,
given a declaration of `class C<T> {}`, the type `C` could be used with a
non-nullable type argument as in `C<int>`.
''');
  }

  /// Write the header of the file.
  void _writeHeader(StringSink sink) {
    sink.write('''
---
title: Diagnostic messages
description: Details for diagnostics produced by the Dart analyzer.
---
{%- comment %}
WARNING: Do NOT EDIT this file directly. It is autogenerated by the script in
`pkg/analyzer/tool/diagnostics/generate.dart` in the sdk repository.
Update instructions: https://github.com/dart-lang/site-www/issues/1949
{% endcomment -%}

This page lists diagnostic messages produced by the Dart analyzer,
with details about what those messages mean and how you can fix your code.
For more information about the analyzer, see
[Customizing static analysis](/guides/language/analysis-options).
''');
  }
}
