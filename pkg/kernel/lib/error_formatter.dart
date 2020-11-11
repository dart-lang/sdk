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
    final dynamic context = where is Class || where is Library
        ? where
        : _findEnclosingMember(where);
    String sourceLocation = '<unknown source>';
    String sourceLine = null;

    // Try finding original source line.
    final int fileOffset = _findFileOffset(where);
    if (fileOffset != TreeNode.noOffset) {
      final Uri fileUri = _fileUriOf(context);

      final Component component = context.enclosingComponent;
      final Source source = component.uriToSource[fileUri];
      final Location location = component.getLocation(fileUri, fileOffset);
      final int lineStart = source.lineStarts[location.line - 1];
      final int lineEnd = (location.line < source.lineStarts.length)
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
    String name = "";
    dynamic body = context;
    if (context is Class || context is Library) {
      name = context.name;
    } else if (context is Procedure || context is Constructor) {
      final dynamic parent = context.parent;
      final String parentName =
          parent is Class ? parent.name : (parent as Library).name;
      name = "${parentName}::${context.name.text}";
    } else {
      final Field field = context as Field;
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

  static Uri _fileUriOf(FileUriNode node) {
    return node.fileUri;
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
    TreeNode context = n;
    while (context is! Member) {
      context = context.parent;
    }
    return context;
  }
}

/// Extension of a [Printer] that highlights the given node using ANSI
/// escape sequences.
class HighlightingPrinter extends Printer {
  final Node highlight;

  HighlightingPrinter(this.highlight)
      : super(new StringBuffer(), syntheticNames: globalDebuggingNames);

  @override
  bool shouldHighlight(Node node) => highlight == node;

  static const String kHighlightStart = ansiRed;
  static const String kHighlightEnd = ansiReset;

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
      final String firstLine = debugNodeToString(node).split('\n').first;
      return "${kHighlightStart}${firstLine}${kHighlightEnd}";
    }

    final HighlightingPrinter p = new HighlightingPrinter(highlight);
    p.writeNode(node);
    final String text = p.sink.toString();
    return _onlyHighlightedLines(text).join('\n');
  }

  static Iterable<String> _onlyHighlightedLines(String text) sync* {
    for (String line
        in text.split('\n').skipWhile((l) => !l.contains(kHighlightStart))) {
      yield line;
      if (line.contains(kHighlightEnd)) {
        break;
      }
    }
  }
}

const String ansiBlue = "\u001b[1;34m";
const String ansiYellow = "\u001b[1;33m";
const String ansiRed = "\u001b[1;31m";
const String ansiReset = "\u001b[0;0m";
