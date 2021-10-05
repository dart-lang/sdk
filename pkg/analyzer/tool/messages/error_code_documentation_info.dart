// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';

/// Extracts comments from the declaration of [field] and interprets them as a
/// list of [ErrorCodeDocumentationPart] objects.  These objects represent
/// user-publishable documentation about the error code, along with code blocks
/// illustrating when the error occurs and how to fix it.
List<ErrorCodeDocumentationPart>? parseErrorCodeDocumentation(
    FieldDeclaration field) {
  var comments = field.firstTokenAfterCommentAndMetadata.precedingComments;
  if (comments == null) {
    return null;
  }
  var className = (field.parent as ClassDeclaration).name.name;
  var errorName = field.fields.variables.single.name.name;
  var commentLines = <String>[];
  while (comments != null) {
    String lexeme = comments.lexeme;
    if (lexeme.startsWith('// ')) {
      commentLines.add(lexeme.substring(3));
    } else if (lexeme == '//') {
      commentLines.add('');
    }
    comments = comments.next as CommentToken?;
  }
  if (commentLines.isEmpty) {
    return null;
  }
  var parser =
      _ErrorCodeDocumentationParser('$className.$errorName', commentLines);
  parser.parse();
  return parser.result;
}

/// Enum representing the different documentation sections in which an
/// [ErrorCodeDocumentationBlock] might appear.
enum BlockSection {
  // The "Examples" section, where we give examples of code that generates the
  // error.
  examples,

  // The "Common fixes" section, where we give examples of code that doesn't
  // generate the error.
  commonFixes,
}

/// An [ErrorCodeDocumentationPart] containing a block of code.
class ErrorCodeDocumentationBlock extends ErrorCodeDocumentationPart {
  /// The code itself.
  final String text;

  /// The section this block is contained in.
  final BlockSection containingSection;

  /// A list of the experiments that need to be enabled for this code to behave
  /// as expected (if any).
  final List<String> experiments;

  /// The file type of this code block (e.g. `dart` or `yaml`).
  final String fileType;

  /// The language version that must be active for this code to behave as
  /// expected (if any).
  final String? languageVersion;

  /// If this code is an auxiliary file that supports other blocks, the URI of
  /// the file.
  final String? uri;

  ErrorCodeDocumentationBlock(this.text,
      {required this.containingSection,
      this.experiments = const [],
      required this.fileType,
      this.languageVersion,
      this.uri});

  @override
  String formatForDocumentation() => fileType == 'dart'
      ? ['{% prettify dart tag=pre+code %}', text, '{% endprettify %}']
          .join('\n')
      : ['```$fileType', text, '```'].join('\n');
}

/// A portion of an error code's documentation.  This could be free form
/// markdown text ([ErrorCodeDocumentationText]) or a code block
/// ([ErrorCodeDocumentationBlock]).
abstract class ErrorCodeDocumentationPart {
  /// Formats this documentation part as text suitable for inclusion in the
  /// analyzer's `diagnostics.md` file.
  String formatForDocumentation();
}

/// An [ErrorCodeDocumentationPart] containing free form markdown text.
class ErrorCodeDocumentationText extends ErrorCodeDocumentationPart {
  /// The text, in markdown format.
  final String text;

  ErrorCodeDocumentationText(this.text);

  @override
  String formatForDocumentation() => text;
}

class _ErrorCodeDocumentationParser {
  /// The prefix used on directive lines to specify the experiments that should
  /// be enabled for a snippet.
  static const String experimentsPrefix = '%experiments=';

  /// The prefix used on directive lines to specify the language version for
  /// the snippet.
  static const String languagePrefix = '%language=';

  /// The prefix used on directive lines to indicate the uri of an auxiliary
  /// file that is needed for testing purposes.
  static const String uriDirectivePrefix = '%uri="';

  final String errorCode;

  final List<String> commentLines;

  final List<ErrorCodeDocumentationPart> result = [];

  int currentLineNumber = 0;

  String? currentSection;

  _ErrorCodeDocumentationParser(this.errorCode, this.commentLines);

  bool get done => currentLineNumber >= commentLines.length;

  String get line => commentLines[currentLineNumber];

  BlockSection computeCurrentBlockSection() {
    switch (currentSection) {
      case '#### Example':
      case '#### Examples':
        return BlockSection.examples;
      case '#### Common fixes':
        return BlockSection.commonFixes;
      case null:
        problem('Code block before section header');
      default:
        problem('Code block in invalid section ${json.encode(currentSection)}');
    }
  }

  void parse() {
    var textLines = <String>[];

    void flushText() {
      if (textLines.isNotEmpty) {
        result.add(ErrorCodeDocumentationText(textLines.join('\n')));
        textLines = [];
      }
    }

    while (!done) {
      if (line.startsWith('TODO')) {
        // Everything after the "TODO" is ignored.
        break;
      } else if (line.startsWith('%')) {
        problem('% directive outside code block');
      } else if (line.startsWith('```')) {
        flushText();
        processCodeBlock();
      } else {
        if (line.startsWith('#') && !line.startsWith('#####')) {
          currentSection = line;
        }
        textLines.add(line);
        currentLineNumber++;
      }
    }
    flushText();
  }

  Never problem(String explanation) {
    throw 'In documentation for $errorCode, at line ${currentLineNumber + 1}, '
        '$explanation';
  }

  void processCodeBlock() {
    var containingSection = computeCurrentBlockSection();
    var codeLines = <String>[];
    String? languageVersion;
    String? uri;
    List<String>? experiments;
    assert(line.startsWith('```'));
    var fileType = line.substring(3);
    if (fileType.isEmpty) {
      problem('Code blocks should have a file type, e.g. "```dart"');
    }
    ++currentLineNumber;
    while (true) {
      if (done) {
        problem('Unterminated code block');
      } else if (line.startsWith('```')) {
        if (line != '```') {
          problem('Code blocks should end with "```"');
        }
        ++currentLineNumber;
        result.add(ErrorCodeDocumentationBlock(codeLines.join('\n'),
            containingSection: containingSection,
            experiments: experiments ?? const [],
            fileType: fileType,
            languageVersion: languageVersion,
            uri: uri));
        return;
      } else if (line.startsWith('%')) {
        if (line.startsWith(languagePrefix)) {
          if (languageVersion != null) {
            problem('Multiple language version directives');
          }
          languageVersion = line.substring(languagePrefix.length);
        } else if (line.startsWith(uriDirectivePrefix)) {
          if (uri != null) {
            problem('Multiple URI directives');
          }
          if (!line.endsWith('"')) {
            problem('URI directive should be surrounded by double quotes');
          }
          uri = line.substring(uriDirectivePrefix.length, line.length - 1);
        } else if (line.startsWith(experimentsPrefix)) {
          if (experiments != null) {
            problem('Multiple experiments directives');
          }
          experiments = line
              .substring(experimentsPrefix.length)
              .split(',')
              .map((e) => e.trim())
              .toList();
        } else {
          problem('Unrecognized directive ${json.encode(line)}');
        }
      } else {
        codeLines.add(line);
      }
      ++currentLineNumber;
    }
  }
}
