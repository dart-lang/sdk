// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;

/**
 * Sorter for unit/class members.
 */
class MemberSorter {
  static List<_PriorityItem> _PRIORITY_ITEMS = [
    new _PriorityItem(false, _MemberKind.UNIT_FUNCTION_MAIN, false),
    new _PriorityItem(false, _MemberKind.UNIT_VARIABLE_CONST, false),
    new _PriorityItem(false, _MemberKind.UNIT_VARIABLE_CONST, true),
    new _PriorityItem(false, _MemberKind.UNIT_VARIABLE, false),
    new _PriorityItem(false, _MemberKind.UNIT_VARIABLE, true),
    new _PriorityItem(false, _MemberKind.UNIT_ACCESSOR, false),
    new _PriorityItem(false, _MemberKind.UNIT_ACCESSOR, true),
    new _PriorityItem(false, _MemberKind.UNIT_FUNCTION, false),
    new _PriorityItem(false, _MemberKind.UNIT_FUNCTION, true),
    new _PriorityItem(false, _MemberKind.UNIT_FUNCTION_TYPE, false),
    new _PriorityItem(false, _MemberKind.UNIT_FUNCTION_TYPE, true),
    new _PriorityItem(false, _MemberKind.UNIT_CLASS, false),
    new _PriorityItem(false, _MemberKind.UNIT_CLASS, true),
    new _PriorityItem(true, _MemberKind.CLASS_FIELD, false),
    new _PriorityItem(true, _MemberKind.CLASS_ACCESSOR, false),
    new _PriorityItem(true, _MemberKind.CLASS_ACCESSOR, true),
    new _PriorityItem(false, _MemberKind.CLASS_FIELD, false),
    new _PriorityItem(false, _MemberKind.CLASS_CONSTRUCTOR, false),
    new _PriorityItem(false, _MemberKind.CLASS_CONSTRUCTOR, true),
    new _PriorityItem(false, _MemberKind.CLASS_ACCESSOR, false),
    new _PriorityItem(false, _MemberKind.CLASS_ACCESSOR, true),
    new _PriorityItem(false, _MemberKind.CLASS_METHOD, false),
    new _PriorityItem(false, _MemberKind.CLASS_METHOD, true),
    new _PriorityItem(true, _MemberKind.CLASS_METHOD, false),
    new _PriorityItem(true, _MemberKind.CLASS_METHOD, true)
  ];

  final String initialCode;
  final CompilationUnit unit;
  String code;
  String endOfLine;

  MemberSorter(this.initialCode, this.unit) {
    this.code = initialCode;
    this.endOfLine = getEOL(code);
  }

  /**
   * Return the [SourceEdit]s that sort [unit].
   */
  List<SourceEdit> sort() {
    _sortClassesMembers();
    _sortUnitMembers();
    // Must sort unit directives last because it may insert newlines, which
    // would confuse the offsets used by the other sort functions.
    _sortUnitDirectives();
    // prepare edits
    List<SourceEdit> edits = <SourceEdit>[];
    if (code != initialCode) {
      SimpleDiff diff = computeSimpleDiff(initialCode, code);
      SourceEdit edit =
          new SourceEdit(diff.offset, diff.length, diff.replacement);
      edits.add(edit);
    }
    return edits;
  }

  void _sortAndReorderMembers(List<_MemberInfo> members) {
    List<_MemberInfo> membersSorted = _getSortedMembers(members);
    int size = membersSorted.length;
    for (int i = 0; i < size; i++) {
      _MemberInfo newInfo = membersSorted[size - 1 - i];
      _MemberInfo oldInfo = members[size - 1 - i];
      if (newInfo != oldInfo) {
        String beforeCode = code.substring(0, oldInfo.offset);
        String afterCode = code.substring(oldInfo.end);
        code = beforeCode + newInfo.text + afterCode;
      }
    }
  }

  /**
   * Sorts all members of all [ClassDeclaration]s.
   */
  void _sortClassesMembers() {
    for (CompilationUnitMember unitMember in unit.declarations) {
      if (unitMember is ClassDeclaration) {
        ClassDeclaration classDeclaration = unitMember;
        _sortClassMembers(classDeclaration);
      }
    }
  }

  /**
   * Sorts all members of the given [ClassDeclaration].
   */
  void _sortClassMembers(ClassDeclaration classDeclaration) {
    List<_MemberInfo> members = <_MemberInfo>[];
    for (ClassMember member in classDeclaration.members) {
      _MemberKind kind = null;
      bool isStatic = false;
      String name = null;
      if (member is ConstructorDeclaration) {
        kind = _MemberKind.CLASS_CONSTRUCTOR;
        SimpleIdentifier nameNode = member.name;
        if (nameNode == null) {
          name = "";
        } else {
          name = nameNode.name;
        }
      }
      if (member is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = member;
        List<VariableDeclaration> fields = fieldDeclaration.fields.variables;
        if (!fields.isEmpty) {
          kind = _MemberKind.CLASS_FIELD;
          isStatic = fieldDeclaration.isStatic;
          name = fields[0].name.name;
        }
      }
      if (member is MethodDeclaration) {
        MethodDeclaration method = member;
        isStatic = method.isStatic;
        name = method.name.name;
        if (method.isGetter) {
          kind = _MemberKind.CLASS_ACCESSOR;
          name += " getter";
        } else if (method.isSetter) {
          kind = _MemberKind.CLASS_ACCESSOR;
          name += " setter";
        } else {
          kind = _MemberKind.CLASS_METHOD;
        }
      }
      if (name != null) {
        _PriorityItem item = new _PriorityItem.forName(isStatic, name, kind);
        int offset = member.offset;
        int length = member.length;
        String text = code.substring(offset, offset + length);
        members.add(new _MemberInfo(item, name, offset, length, text));
      }
    }
    // do sort
    _sortAndReorderMembers(members);
  }

  /**
   * Sorts all [Directive]s.
   */
  void _sortUnitDirectives() {
    bool hasLibraryDirective = false;
    List<_DirectiveInfo> directives = [];
    for (Directive directive in unit.directives) {
      if (directive is LibraryDirective) {
        hasLibraryDirective = true;
      }
      if (directive is! UriBasedDirective) {
        continue;
      }
      UriBasedDirective uriDirective = directive as UriBasedDirective;
      String uriContent = uriDirective.uri.stringValue;
      _DirectivePriority kind = null;
      if (directive is ImportDirective) {
        if (uriContent.startsWith("dart:")) {
          kind = _DirectivePriority.IMPORT_SDK;
        } else if (uriContent.startsWith("package:")) {
          kind = _DirectivePriority.IMPORT_PKG;
        } else if (uriContent.contains('://')) {
          kind = _DirectivePriority.IMPORT_OTHER;
        } else {
          kind = _DirectivePriority.IMPORT_REL;
        }
      }
      if (directive is ExportDirective) {
        if (uriContent.startsWith("dart:")) {
          kind = _DirectivePriority.EXPORT_SDK;
        } else if (uriContent.startsWith("package:")) {
          kind = _DirectivePriority.EXPORT_PKG;
        } else if (uriContent.contains('://')) {
          kind = _DirectivePriority.EXPORT_OTHER;
        } else {
          kind = _DirectivePriority.EXPORT_REL;
        }
      }
      if (directive is PartDirective) {
        kind = _DirectivePriority.PART;
      }
      if (kind != null) {
        String documentationText;
        if (directive.documentationComment != null) {
          documentationText = code.substring(
              directive.documentationComment.offset,
              directive.documentationComment.end);
        }
        String annotationText;
        if (directive.metadata.beginToken != null) {
          annotationText = code.substring(directive.metadata.beginToken.offset,
              directive.metadata.endToken.end);
        }
        int offset = directive.firstTokenAfterCommentAndMetadata.offset;
        int length = directive.end - offset;
        String text = code.substring(offset, offset + length);
        directives.add(new _DirectiveInfo(directive, kind, uriContent,
            documentationText, annotationText, text));
      }
    }
    // nothing to do
    if (directives.isEmpty) {
      return;
    }
    int firstDirectiveOffset = directives[0].directive.offset;
    int lastDirectiveEnd = directives[directives.length - 1].directive.end;
    // Without a library directive, the library comment is the comment of the
    // first directive.
    _DirectiveInfo libraryDocumentationDirective;
    if (!hasLibraryDirective && directives.isNotEmpty) {
      libraryDocumentationDirective = directives.first;
    }
    // do sort
    directives.sort();
    // append directives with grouping
    String directivesCode;
    {
      StringBuffer sb = new StringBuffer();
      String endOfLine = this.endOfLine;
      _DirectivePriority currentPriority = null;
      bool firstOutputDirective = true;
      for (_DirectiveInfo directive in directives) {
        if (currentPriority != directive.priority) {
          if (sb.length != 0) {
            sb.write(endOfLine);
          }
          currentPriority = directive.priority;
        }
        if (directive != libraryDocumentationDirective &&
            directive.documentationText != null) {
          sb.write(directive.documentationText);
          sb.write(endOfLine);
        }
        if (firstOutputDirective) {
          firstOutputDirective = false;
          if (libraryDocumentationDirective != null &&
              libraryDocumentationDirective.documentationText != null) {
            sb.write(libraryDocumentationDirective.documentationText);
            sb.write(endOfLine);
          }
        }
        if (directive.annotationText != null) {
          sb.write(directive.annotationText);
          sb.write(endOfLine);
        }
        sb.write(directive.text);
        sb.write(endOfLine);
      }
      directivesCode = sb.toString();
      directivesCode = directivesCode.trimRight();
    }
    // prepare code
    String beforeDirectives = code.substring(0, firstDirectiveOffset);
    String afterDirectives = code.substring(lastDirectiveEnd);
    code = beforeDirectives + directivesCode + afterDirectives;
  }

  /**
   * Sorts all [CompilationUnitMember]s.
   */
  void _sortUnitMembers() {
    List<_MemberInfo> members = [];
    for (CompilationUnitMember member in unit.declarations) {
      _MemberKind kind = null;
      String name = null;
      if (member is ClassDeclaration) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.name;
      }
      if (member is ClassTypeAlias) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.name;
      }
      if (member is EnumDeclaration) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.name;
      }
      if (member is FunctionDeclaration) {
        FunctionDeclaration function = member;
        name = function.name.name;
        if (function.isGetter) {
          kind = _MemberKind.UNIT_ACCESSOR;
          name += " getter";
        } else if (function.isSetter) {
          kind = _MemberKind.UNIT_ACCESSOR;
          name += " setter";
        } else {
          if (name == 'main') {
            kind = _MemberKind.UNIT_FUNCTION_MAIN;
          } else {
            kind = _MemberKind.UNIT_FUNCTION;
          }
        }
      }
      if (member is FunctionTypeAlias) {
        kind = _MemberKind.UNIT_FUNCTION_TYPE;
        name = member.name.name;
      }
      if (member is TopLevelVariableDeclaration) {
        TopLevelVariableDeclaration variableDeclaration = member;
        List<VariableDeclaration> variables =
            variableDeclaration.variables.variables;
        if (!variables.isEmpty) {
          if (variableDeclaration.variables.isConst) {
            kind = _MemberKind.UNIT_VARIABLE_CONST;
          } else {
            kind = _MemberKind.UNIT_VARIABLE;
          }
          name = variables[0].name.name;
        }
      }
      if (name != null) {
        _PriorityItem item = new _PriorityItem.forName(false, name, kind);
        int offset = member.offset;
        int length = member.length;
        String text = code.substring(offset, offset + length);
        members.add(new _MemberInfo(item, name, offset, length, text));
      }
    }
    // do sort
    _sortAndReorderMembers(members);
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

  static int _getPriority(_PriorityItem item) {
    for (int i = 0; i < _PRIORITY_ITEMS.length; i++) {
      if (_PRIORITY_ITEMS[i] == item) {
        return i;
      }
    }
    return 0;
  }

  static List<_MemberInfo> _getSortedMembers(List<_MemberInfo> members) {
    List<_MemberInfo> membersSorted = new List<_MemberInfo>.from(members);
    membersSorted.sort((_MemberInfo o1, _MemberInfo o2) {
      int priority1 = _getPriority(o1.item);
      int priority2 = _getPriority(o2.item);
      if (priority1 == priority2) {
        // don't reorder class fields
        if (o1.item.kind == _MemberKind.CLASS_FIELD) {
          return o1.offset - o2.offset;
        }
        // sort all other members by name
        String name1 = o1.name.toLowerCase();
        String name2 = o2.name.toLowerCase();
        return name1.compareTo(name2);
      }
      return priority1 - priority2;
    });
    return membersSorted;
  }
}

class _DirectiveInfo implements Comparable<_DirectiveInfo> {
  final Directive directive;
  final _DirectivePriority priority;
  final String uri;
  final String documentationText;
  final String annotationText;
  final String text;

  _DirectiveInfo(this.directive, this.priority, this.uri,
      this.documentationText, this.annotationText, this.text);

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

class _MemberInfo {
  final _PriorityItem item;
  final String name;
  final int offset;
  final int length;
  final int end;
  final String text;

  _MemberInfo(this.item, this.name, int offset, int length, this.text)
      : offset = offset,
        length = length,
        end = offset + length;

  @override
  String toString() {
    return '(priority=$item; name=$name; offset=$offset; length=$length)';
  }
}

class _MemberKind {
  static const UNIT_FUNCTION_MAIN = const _MemberKind('UNIT_FUNCTION_MAIN', 0);
  static const UNIT_ACCESSOR = const _MemberKind('UNIT_ACCESSOR', 1);
  static const UNIT_FUNCTION = const _MemberKind('UNIT_FUNCTION', 2);
  static const UNIT_FUNCTION_TYPE = const _MemberKind('UNIT_FUNCTION_TYPE', 3);
  static const UNIT_CLASS = const _MemberKind('UNIT_CLASS', 4);
  static const UNIT_VARIABLE_CONST = const _MemberKind('UNIT_VARIABLE', 5);
  static const UNIT_VARIABLE = const _MemberKind('UNIT_VARIABLE', 6);
  static const CLASS_ACCESSOR = const _MemberKind('CLASS_ACCESSOR', 7);
  static const CLASS_CONSTRUCTOR = const _MemberKind('CLASS_CONSTRUCTOR', 8);
  static const CLASS_FIELD = const _MemberKind('CLASS_FIELD', 9);
  static const CLASS_METHOD = const _MemberKind('CLASS_METHOD', 10);

  final String name;
  final int ordinal;

  const _MemberKind(this.name, this.ordinal);

  @override
  String toString() => name;
}

class _PriorityItem {
  final _MemberKind kind;
  final bool isPrivate;
  final bool isStatic;

  _PriorityItem(this.isStatic, this.kind, this.isPrivate);

  factory _PriorityItem.forName(bool isStatic, String name, _MemberKind kind) {
    bool isPrivate = Identifier.isPrivateName(name);
    return new _PriorityItem(isStatic, kind, isPrivate);
  }

  @override
  bool operator ==(Object obj) {
    _PriorityItem other = obj as _PriorityItem;
    if (kind == _MemberKind.CLASS_FIELD) {
      return other.kind == kind && other.isStatic == isStatic;
    }
    return other.kind == kind &&
        other.isPrivate == isPrivate &&
        other.isStatic == isStatic;
  }

  @override
  String toString() => kind.toString();
}
