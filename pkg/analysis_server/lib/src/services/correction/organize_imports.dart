// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError, Element;

/// Organizer of imports (and other directives) in the [unit].
class ImportOrganizer {
  final String initialCode;
  final CompilationUnit unit;
  final List<AnalysisError> errors;
  final bool removeUnused;

  String code;
  String endOfLine;
  bool hasUnresolvedIdentifierError;

  ImportOrganizer(this.initialCode, this.unit, this.errors,
      {this.removeUnused = true}) {
    code = initialCode;
    endOfLine = getEOL(code);
    hasUnresolvedIdentifierError = errors.any((error) {
      return error.errorCode.isUnresolvedIdentifier;
    });
  }

  /// Return the [SourceEdit]s that organize imports in the [unit].
  List<SourceEdit> organize() {
    _organizeDirectives();
    // prepare edits
    var edits = <SourceEdit>[];
    if (code != initialCode) {
      var suffixLength = findCommonSuffix(initialCode, code);
      var edit = SourceEdit(0, initialCode.length - suffixLength,
          code.substring(0, code.length - suffixLength));
      edits.add(edit);
    }
    return edits;
  }

  bool _isUnusedImport(UriBasedDirective directive) {
    for (var error in errors) {
      if ((error.errorCode == HintCode.DUPLICATE_IMPORT ||
              error.errorCode == HintCode.UNUSED_IMPORT) &&
          directive.uri.offset == error.offset) {
        return true;
      }
    }
    return false;
  }

  /// Organize all [Directive]s.
  void _organizeDirectives() {
    var lineInfo = unit.lineInfo;
    var directives = <_DirectiveInfo>[];
    for (var directive in unit.directives) {
      if (directive is UriBasedDirective) {
        var priority = getDirectivePriority(directive);
        if (priority != null) {
          var offset = directive.offset;

          var end = directive.end;
          var line = lineInfo.getLocation(end).lineNumber;
          Token comment = directive.endToken.next.precedingComments;
          while (comment != null) {
            if (lineInfo.getLocation(comment.offset).lineNumber == line) {
              end = comment.end;
            }
            comment = comment.next;
          }

          var text = code.substring(offset, end);
          var uriContent = directive.uri.stringValue;
          directives.add(
            _DirectiveInfo(
              directive,
              priority,
              uriContent,
              offset,
              end,
              text,
            ),
          );
        }
      }
    }
    // nothing to do
    if (directives.isEmpty) {
      return;
    }
    var firstDirectiveOffset = directives.first.offset;
    var lastDirectiveEnd = directives.last.end;
    // sort
    directives.sort();
    // append directives with grouping
    String directivesCode;
    {
      var sb = StringBuffer();
      _DirectivePriority currentPriority;
      for (var directiveInfo in directives) {
        if (!hasUnresolvedIdentifierError) {
          var directive = directiveInfo.directive;
          if (removeUnused && _isUnusedImport(directive)) {
            continue;
          }
        }
        if (currentPriority != directiveInfo.priority) {
          if (sb.length != 0) {
            sb.write(endOfLine);
          }
          currentPriority = directiveInfo.priority;
        }
        sb.write(directiveInfo.text);
        sb.write(endOfLine);
      }
      directivesCode = sb.toString();
      directivesCode = directivesCode.trimRight();
    }
    // prepare code
    var beforeDirectives = code.substring(0, firstDirectiveOffset);
    var afterDirectives = code.substring(lastDirectiveEnd);
    code = beforeDirectives + directivesCode + afterDirectives;
  }

  static _DirectivePriority getDirectivePriority(UriBasedDirective directive) {
    var uriContent = directive.uri.stringValue;
    if (directive is ImportDirective) {
      if (uriContent.startsWith('dart:')) {
        return _DirectivePriority.IMPORT_SDK;
      } else if (uriContent.startsWith('package:')) {
        return _DirectivePriority.IMPORT_PKG;
      } else if (uriContent.contains('://')) {
        return _DirectivePriority.IMPORT_OTHER;
      } else {
        return _DirectivePriority.IMPORT_REL;
      }
    }
    if (directive is ExportDirective) {
      if (uriContent.startsWith('dart:')) {
        return _DirectivePriority.EXPORT_SDK;
      } else if (uriContent.startsWith('package:')) {
        return _DirectivePriority.EXPORT_PKG;
      } else if (uriContent.contains('://')) {
        return _DirectivePriority.EXPORT_OTHER;
      } else {
        return _DirectivePriority.EXPORT_REL;
      }
    }
    if (directive is PartDirective) {
      return _DirectivePriority.PART;
    }
    return null;
  }

  /// Return the EOL to use for [code].
  static String getEOL(String code) {
    if (code.contains('\r\n')) {
      return '\r\n';
    } else {
      return '\n';
    }
  }
}

class _DirectiveInfo implements Comparable<_DirectiveInfo> {
  final UriBasedDirective directive;
  final _DirectivePriority priority;
  final String uri;

  /// The offset of the first token, usually the keyword.
  final int offset;

  /// The offset after the least token, including the end-of-line comment.
  final int end;

  /// The text between [offset] and [end].
  final String text;

  _DirectiveInfo(
    this.directive,
    this.priority,
    this.uri,
    this.offset,
    this.end,
    this.text,
  );

  @override
  int compareTo(_DirectiveInfo other) {
    if (priority == other.priority) {
      return _compareUri(uri, other.uri);
    }
    return priority.ordinal - other.priority.ordinal;
  }

  @override
  String toString() => '(priority=$priority; text=$text)';

  static int _compareUri(String a, String b) {
    var aList = _splitUri(a);
    var bList = _splitUri(b);
    int result;
    if ((result = aList[0].compareTo(bList[0])) != 0) return result;
    if ((result = aList[1].compareTo(bList[1])) != 0) return result;
    return 0;
  }

  /// Split the given [uri] like `package:some.name/and/path.dart` into a list
  /// like `[package:some.name, and/path.dart]`.
  static List<String> _splitUri(String uri) {
    var index = uri.indexOf('/');
    if (index == -1) {
      return <String>[uri, ''];
    }
    return <String>[uri.substring(0, index), uri.substring(index + 1)];
  }
}

class _DirectivePriority {
  static const IMPORT_SDK = _DirectivePriority('IMPORT_SDK', 0);
  static const IMPORT_PKG = _DirectivePriority('IMPORT_PKG', 1);
  static const IMPORT_OTHER = _DirectivePriority('IMPORT_OTHER', 2);
  static const IMPORT_REL = _DirectivePriority('IMPORT_REL', 3);
  static const EXPORT_SDK = _DirectivePriority('EXPORT_SDK', 4);
  static const EXPORT_PKG = _DirectivePriority('EXPORT_PKG', 5);
  static const EXPORT_OTHER = _DirectivePriority('EXPORT_OTHER', 6);
  static const EXPORT_REL = _DirectivePriority('EXPORT_REL', 7);
  static const PART = _DirectivePriority('PART', 8);

  final String name;
  final int ordinal;

  const _DirectivePriority(this.name, this.ordinal);

  @override
  String toString() => name;
}
