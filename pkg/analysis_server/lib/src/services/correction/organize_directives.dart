// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.organize_directives;

import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide AnalysisError, Element;
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';

/**
 * Organizer of directives in the [unit].
 */
class DirectiveOrganizer {
  final String initialCode;
  final CompilationUnit unit;
  final List<AnalysisError> errors;
  final bool removeUnresolved;
  final bool removeUnused;
  String code;
  String endOfLine;

  DirectiveOrganizer(this.initialCode, this.unit, this.errors,
      {this.removeUnresolved: true, this.removeUnused: true}) {
    this.code = initialCode;
    this.endOfLine = getEOL(code);
  }

  /**
   * Return the [SourceEdit]s that organize directives in the [unit].
   */
  List<SourceEdit> organize() {
    _organizeDirectives();
    // prepare edits
    List<SourceEdit> edits = <SourceEdit>[];
    if (code != initialCode) {
      int suffixLength = findCommonSuffix(initialCode, code);
      SourceEdit edit = new SourceEdit(0, initialCode.length - suffixLength,
          code.substring(0, code.length - suffixLength));
      edits.add(edit);
    }
    return edits;
  }

  bool _isUnresolvedUri(UriBasedDirective directive) {
    for (AnalysisError error in errors) {
      ErrorCode errorCode = error.errorCode;
      if ((errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST ||
              errorCode == CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED) &&
          directive.uri.offset == error.offset) {
        return true;
      }
    }
    return false;
  }

  bool _isUnusedImport(UriBasedDirective directive) {
    for (AnalysisError error in errors) {
      if ((error.errorCode == HintCode.DUPLICATE_IMPORT ||
              error.errorCode == HintCode.UNUSED_IMPORT) &&
          directive.uri.offset == error.offset) {
        return true;
      }
    }
    return false;
  }

  /**
   * Oraganize all [Directive]s.
   */
  void _organizeDirectives() {
    List<_DirectiveInfo> directives = [];
    for (Directive directive in unit.directives) {
      if (directive is UriBasedDirective) {
        _DirectivePriority priority = getDirectivePriority(directive);
        if (priority != null) {
          int offset = directive.offset;
          int length = directive.length;
          String text = code.substring(offset, offset + length);
          String uriContent = directive.uri.stringValue;
          directives
              .add(new _DirectiveInfo(directive, priority, uriContent, text));
        }
      }
    }
    // nothing to do
    if (directives.isEmpty) {
      return;
    }
    int firstDirectiveOffset = directives.first.directive.offset;
    int lastDirectiveEnd = directives.last.directive.end;
    // sort
    directives.sort();
    // append directives with grouping
    String directivesCode;
    {
      StringBuffer sb = new StringBuffer();
      _DirectivePriority currentPriority = null;
      for (_DirectiveInfo directiveInfo in directives) {
        if (removeUnresolved && _isUnresolvedUri(directiveInfo.directive)) {
          continue;
        }
        if (removeUnused && _isUnusedImport(directiveInfo.directive)) {
          continue;
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
    // append comment tokens which otherwise would be removed completely
    {
      bool firstCommentToken = true;
      Token token = unit.beginToken;
      while (token != null &&
          token.type != TokenType.EOF &&
          token.end < lastDirectiveEnd) {
        Token commentToken = token.precedingComments;
        while (commentToken != null) {
          int offset = commentToken.offset;
          int end = commentToken.end;
          if (offset > firstDirectiveOffset && offset < lastDirectiveEnd) {
            if (firstCommentToken) {
              directivesCode += endOfLine;
              firstCommentToken = false;
            }
            directivesCode += code.substring(offset, end) + endOfLine;
          }
          commentToken = commentToken.next;
        }
        token = token.next;
      }
    }
    // prepare code
    String beforeDirectives = code.substring(0, firstDirectiveOffset);
    String afterDirectives = code.substring(lastDirectiveEnd);
    code = beforeDirectives + directivesCode + afterDirectives;
  }

  static _DirectivePriority getDirectivePriority(UriBasedDirective directive) {
    String uriContent = directive.uri.stringValue;
    if (directive is ImportDirective) {
      if (uriContent.startsWith("dart:")) {
        return _DirectivePriority.IMPORT_SDK;
      } else if (uriContent.startsWith("package:")) {
        return _DirectivePriority.IMPORT_PKG;
      } else if (uriContent.contains('://')) {
        return _DirectivePriority.IMPORT_OTHER;
      } else {
        return _DirectivePriority.IMPORT_REL;
      }
    }
    if (directive is ExportDirective) {
      if (uriContent.startsWith("dart:")) {
        return _DirectivePriority.EXPORT_SDK;
      } else if (uriContent.startsWith("package:")) {
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

  /**
   * Return the EOL to use for [code].
   */
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
  final String text;

  _DirectiveInfo(this.directive, this.priority, this.uri, this.text);

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
    List<String> aList = _splitUri(a);
    List<String> bList = _splitUri(b);
    int result;
    if ((result = aList[0].compareTo(bList[0])) != 0) return result;
    if ((result = aList[1].compareTo(bList[1])) != 0) return result;
    return 0;
  }

  /**
   * Split the given [uri] like `package:some.name/and/path.dart` into a list
   * like `[package:some.name, and/path.dart]`.
   */
  static List<String> _splitUri(String uri) {
    int index = uri.indexOf('/');
    if (index == -1) {
      return <String>[uri, ''];
    }
    return <String>[uri.substring(0, index), uri.substring(index + 1)];
  }
}

class _DirectivePriority {
  static const IMPORT_SDK = const _DirectivePriority('IMPORT_SDK', 0);
  static const IMPORT_PKG = const _DirectivePriority('IMPORT_PKG', 1);
  static const IMPORT_OTHER = const _DirectivePriority('IMPORT_OTHER', 2);
  static const IMPORT_REL = const _DirectivePriority('IMPORT_REL', 3);
  static const EXPORT_SDK = const _DirectivePriority('EXPORT_SDK', 4);
  static const EXPORT_PKG = const _DirectivePriority('EXPORT_PKG', 5);
  static const EXPORT_OTHER = const _DirectivePriority('EXPORT_OTHER', 6);
  static const EXPORT_REL = const _DirectivePriority('EXPORT_REL', 7);
  static const PART = const _DirectivePriority('PART', 8);

  final String name;
  final int ordinal;

  const _DirectivePriority(this.name, this.ordinal);

  @override
  String toString() => name;
}
