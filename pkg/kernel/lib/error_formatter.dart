#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/naive_type_checker.dart';
import 'package:kernel/text/ast_to_text.dart';

class ErrorFormatter implements FailureListener {
  List<String> failures = <String>[];
  int get numberOfFailures => failures.length;

  @override
  void reportNotAssignable(TreeNode where, DartType from, DartType to) {
    reportFailure(
        where,
        '${ansiBlue}${from}${ansiReset} ${ansiYellow}is not assignable to'
        '${ansiReset} ${ansiBlue}${to}${ansiReset}');
  }

  @override
  void reportInvalidOverride(
      Member ownMember, Member superMember, String message) {
    reportFailure(ownMember, '''
Incompatible override of ${superMember} with ${ownMember}:

    ${_realign(message, '    ')}''');
  }

  @override
  void reportFailure(TreeNode where, String message) {
    final context = _findEnclosingMember(where);
    String sourceLocation = '<unknown source>';
    String sourceLine = null;

    // Try finding original source line.
    final fileOffset = _findFileOffset(where);
    if (fileOffset != TreeNode.noOffset) {
      final fileUri = _fileUriOf(context);

      final program = context.enclosingProgram;
      final source = program.uriToSource[fileUri];
      final location = program.getLocation(fileUri, fileOffset);
      final lineStart = source.lineStarts[location.line - 1];
      final lineEnd = (location.line < source.lineStarts.length)
          ? source.lineStarts[location.line]
          : (source.source.length - 1);
      if (lineStart < source.source.length &&
          lineEnd < source.source.length &&
          lineStart < lineEnd) {
        sourceLocation = '${fileUri}:${location.line}';
        sourceLine = new String.fromCharCodes(
            source.source.getRange(lineStart, lineEnd));
      }
    }

    // Find the name of the enclosing member.
    var name = "", body = context;
    if (context is Procedure || context is Constructor) {
      final parent = context.parent;
      final parentName =
          parent is Class ? parent.name : (parent as Library).name;
      name = "${parentName}::${context.name.name}";
      body = context;
    } else {
      final field = context as Field;
      if (where is Field) {
        name = "${field.parent}.${field.name}";
      } else {
        name = "field initializer for ${field.parent}.${field.name}";
      }
    }

    String failure = '''
-----------------------------------------------------------------------
In ${name} at ${sourceLocation}:

    ${message.replaceAll('\n', '\n    ')}

Kernel:
|
|   ${_realign(HighlightingPrinter.stringifyContainingLines(body, where))}
|
''';

    if (sourceLine != null) {
      failure = '''$failure
Source:
|
|   ${_realign(sourceLine)}
|
''';
    }
    failures.add(failure);
  }

  static String _fileUriOf(Member context) {
    if (context is Procedure) {
      return context.fileUri;
    } else if (context is Field) {
      return context.fileUri;
    } else {
      final klass = context.enclosingClass;
      if (klass != null) {
        return klass.fileUri;
      }
      return context.enclosingLibrary.fileUri;
    }
  }

  static String _realign(String str, [String prefix = '|   ']) =>
      str.trimRight().replaceAll('\n', '\n${prefix}');

  static int _findFileOffset(TreeNode context) {
    while (context != null && context.fileOffset == TreeNode.noOffset) {
      context = context.parent;
    }

    return context?.fileOffset ?? TreeNode.noOffset;
  }

  static Member _findEnclosingMember(TreeNode n) {
    var context = n;
    while (context is! Member) {
      context = context.parent;
    }
    return context;
  }
}

/// Extension of a [Printer] that highlights the given node using ANSI
/// escape sequences.
class HighlightingPrinter extends Printer {
  final highlight;

  HighlightingPrinter(this.highlight)
      : super(new StringBuffer(), syntheticNames: globalDebuggingNames);

  @override
  bool shouldHighlight(Node node) => highlight == node;

  static const kHighlightStart = ansiRed;
  static const kHighlightEnd = ansiReset;

  @override
  void startHighlight(Node node) {
    sink.write(kHighlightStart);
  }

  @override
  void endHighlight(Node node) {
    sink.write(kHighlightEnd);
  }

  /// Stringify the given [node] but only return lines that contain string
  /// representation of the [highlight] node.
  static String stringifyContainingLines(Node node, Node highlight) {
    if (node == highlight) {
      assert(node is Member);
      final firstLine = debugNodeToString(node).split('\n').first;
      return "${kHighlightStart}${firstLine}${kHighlightEnd}";
    }

    final HighlightingPrinter p = new HighlightingPrinter(highlight);
    p.writeNode(node);
    final String text = p.sink.toString();
    return _onlyHighlightedLines(text).join('\n');
  }

  static Iterable<String> _onlyHighlightedLines(String text) sync* {
    for (var line
        in text.split('\n').skipWhile((l) => !l.contains(kHighlightStart))) {
      yield line;
      if (line.contains(kHighlightEnd)) {
        break;
      }
    }
  }
}

const ansiBlue = "\u001b[1;34m";
const ansiYellow = "\u001b[1;33m";
const ansiRed = "\u001b[1;31m";
const ansiReset = "\u001b[0;0m";
