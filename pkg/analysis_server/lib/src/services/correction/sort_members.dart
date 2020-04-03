// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;

/// Sorter for unit/class members.
class MemberSorter {
  static final List<_PriorityItem> _PRIORITY_ITEMS = [
    _PriorityItem(false, _MemberKind.UNIT_FUNCTION_MAIN, false),
    _PriorityItem(false, _MemberKind.UNIT_VARIABLE_CONST, false),
    _PriorityItem(false, _MemberKind.UNIT_VARIABLE_CONST, true),
    _PriorityItem(false, _MemberKind.UNIT_VARIABLE, false),
    _PriorityItem(false, _MemberKind.UNIT_VARIABLE, true),
    _PriorityItem(false, _MemberKind.UNIT_ACCESSOR, false),
    _PriorityItem(false, _MemberKind.UNIT_ACCESSOR, true),
    _PriorityItem(false, _MemberKind.UNIT_FUNCTION, false),
    _PriorityItem(false, _MemberKind.UNIT_FUNCTION, true),
    _PriorityItem(false, _MemberKind.UNIT_GENERIC_TYPE_ALIAS, false),
    _PriorityItem(false, _MemberKind.UNIT_GENERIC_TYPE_ALIAS, true),
    _PriorityItem(false, _MemberKind.UNIT_FUNCTION_TYPE, false),
    _PriorityItem(false, _MemberKind.UNIT_FUNCTION_TYPE, true),
    _PriorityItem(false, _MemberKind.UNIT_CLASS, false),
    _PriorityItem(false, _MemberKind.UNIT_CLASS, true),
    _PriorityItem(false, _MemberKind.UNIT_EXTENSION, false),
    _PriorityItem(false, _MemberKind.UNIT_EXTENSION, true),
    _PriorityItem(true, _MemberKind.CLASS_FIELD, false),
    _PriorityItem(true, _MemberKind.CLASS_ACCESSOR, false),
    _PriorityItem(true, _MemberKind.CLASS_ACCESSOR, true),
    _PriorityItem(false, _MemberKind.CLASS_FIELD, false),
    _PriorityItem(false, _MemberKind.CLASS_CONSTRUCTOR, false),
    _PriorityItem(false, _MemberKind.CLASS_CONSTRUCTOR, true),
    _PriorityItem(false, _MemberKind.CLASS_ACCESSOR, false),
    _PriorityItem(false, _MemberKind.CLASS_ACCESSOR, true),
    _PriorityItem(false, _MemberKind.CLASS_METHOD, false),
    _PriorityItem(false, _MemberKind.CLASS_METHOD, true),
    _PriorityItem(true, _MemberKind.CLASS_METHOD, false),
    _PriorityItem(true, _MemberKind.CLASS_METHOD, true)
  ];

  final String initialCode;
  final CompilationUnit unit;
  String code;
  String endOfLine;

  MemberSorter(this.initialCode, this.unit) {
    code = initialCode;
    endOfLine = getEOL(code);
  }

  /// Return the [SourceEdit]s that sort [unit].
  List<SourceEdit> sort() {
    _sortClassesMembers();
    _sortUnitMembers();
    // Must sort unit directives last because it may insert newlines, which
    // would confuse the offsets used by the other sort functions.
    _sortUnitDirectives();
    // prepare edits
    var edits = <SourceEdit>[];
    if (code != initialCode) {
      var diff = computeSimpleDiff(initialCode, code);
      var edit = SourceEdit(diff.offset, diff.length, diff.replacement);
      edits.add(edit);
    }
    return edits;
  }

  void _sortAndReorderMembers(List<_MemberInfo> members) {
    var membersSorted = _getSortedMembers(members);
    var size = membersSorted.length;
    for (var i = 0; i < size; i++) {
      var newInfo = membersSorted[size - 1 - i];
      var oldInfo = members[size - 1 - i];
      if (newInfo != oldInfo) {
        var beforeCode = code.substring(0, oldInfo.offset);
        var afterCode = code.substring(oldInfo.end);
        code = beforeCode + newInfo.text + afterCode;
      }
    }
  }

  /// Sorts all members of all [ClassOrMixinDeclaration]s.
  void _sortClassesMembers() {
    for (var unitMember in unit.declarations) {
      if (unitMember is ClassOrMixinDeclaration) {
        _sortClassMembers(unitMember);
      }
    }
  }

  /// Sorts all members of the given [classDeclaration].
  void _sortClassMembers(ClassOrMixinDeclaration classDeclaration) {
    var members = <_MemberInfo>[];
    for (var member in classDeclaration.members) {
      _MemberKind kind;
      var isStatic = false;
      String name;
      if (member is ConstructorDeclaration) {
        kind = _MemberKind.CLASS_CONSTRUCTOR;
        var nameNode = member.name;
        if (nameNode == null) {
          name = '';
        } else {
          name = nameNode.name;
        }
      }
      if (member is FieldDeclaration) {
        var fieldDeclaration = member;
        List<VariableDeclaration> fields = fieldDeclaration.fields.variables;
        if (fields.isNotEmpty) {
          kind = _MemberKind.CLASS_FIELD;
          isStatic = fieldDeclaration.isStatic;
          name = fields[0].name.name;
        }
      }
      if (member is MethodDeclaration) {
        var method = member;
        isStatic = method.isStatic;
        name = method.name.name;
        if (method.isGetter) {
          kind = _MemberKind.CLASS_ACCESSOR;
          name += ' getter';
        } else if (method.isSetter) {
          kind = _MemberKind.CLASS_ACCESSOR;
          name += ' setter';
        } else {
          kind = _MemberKind.CLASS_METHOD;
        }
      }
      if (name != null) {
        var item = _PriorityItem.forName(isStatic, name, kind);
        var offset = member.offset;
        var length = member.length;
        var text = code.substring(offset, offset + length);
        members.add(_MemberInfo(item, name, offset, length, text));
      }
    }
    // do sort
    _sortAndReorderMembers(members);
  }

  /// Sorts all [Directive]s.
  void _sortUnitDirectives() {
    var hasLibraryDirective = false;
    var directives = <_DirectiveInfo>[];
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        hasLibraryDirective = true;
      }
      if (directive is! UriBasedDirective) {
        continue;
      }
      var uriDirective = directive as UriBasedDirective;
      var uriContent = uriDirective.uri.stringValue;
      _DirectivePriority kind;
      if (directive is ImportDirective) {
        if (uriContent.startsWith('dart:')) {
          kind = _DirectivePriority.IMPORT_SDK;
        } else if (uriContent.startsWith('package:')) {
          kind = _DirectivePriority.IMPORT_PKG;
        } else if (uriContent.contains('://')) {
          kind = _DirectivePriority.IMPORT_OTHER;
        } else {
          kind = _DirectivePriority.IMPORT_REL;
        }
      }
      if (directive is ExportDirective) {
        if (uriContent.startsWith('dart:')) {
          kind = _DirectivePriority.EXPORT_SDK;
        } else if (uriContent.startsWith('package:')) {
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
        var offset = directive.firstTokenAfterCommentAndMetadata.offset;
        var length = directive.end - offset;
        var text = code.substring(offset, offset + length);
        directives.add(_DirectiveInfo(directive, kind, uriContent,
            documentationText, annotationText, text));
      }
    }
    // nothing to do
    if (directives.isEmpty) {
      return;
    }
    var firstDirectiveOffset = directives[0].directive.offset;
    var lastDirectiveEnd = directives[directives.length - 1].directive.end;
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
      var sb = StringBuffer();
      var endOfLine = this.endOfLine;
      _DirectivePriority currentPriority;
      var firstOutputDirective = true;
      for (var directive in directives) {
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
    var beforeDirectives = code.substring(0, firstDirectiveOffset);
    var afterDirectives = code.substring(lastDirectiveEnd);
    code = beforeDirectives + directivesCode + afterDirectives;
  }

  /// Sorts all [CompilationUnitMember]s.
  void _sortUnitMembers() {
    var members = <_MemberInfo>[];
    for (var member in unit.declarations) {
      _MemberKind kind;
      String name;
      if (member is ClassOrMixinDeclaration) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.name;
      } else if (member is ClassTypeAlias) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.name;
      } else if (member is EnumDeclaration) {
        kind = _MemberKind.UNIT_CLASS;
        name = member.name.name;
      } else if (member is ExtensionDeclaration) {
        kind = _MemberKind.UNIT_EXTENSION;
        name = member.name?.name ?? '';
      } else if (member is FunctionDeclaration) {
        var function = member;
        name = function.name.name;
        if (function.isGetter) {
          kind = _MemberKind.UNIT_ACCESSOR;
          name += ' getter';
        } else if (function.isSetter) {
          kind = _MemberKind.UNIT_ACCESSOR;
          name += ' setter';
        } else {
          if (name == 'main') {
            kind = _MemberKind.UNIT_FUNCTION_MAIN;
          } else {
            kind = _MemberKind.UNIT_FUNCTION;
          }
        }
      } else if (member is FunctionTypeAlias) {
        kind = _MemberKind.UNIT_FUNCTION_TYPE;
        name = member.name.name;
      } else if (member is GenericTypeAlias) {
        kind = _MemberKind.UNIT_GENERIC_TYPE_ALIAS;
        name = member.name.name;
      } else if (member is TopLevelVariableDeclaration) {
        var variableDeclaration = member;
        List<VariableDeclaration> variables =
            variableDeclaration.variables.variables;
        if (variables.isNotEmpty) {
          if (variableDeclaration.variables.isConst) {
            kind = _MemberKind.UNIT_VARIABLE_CONST;
          } else {
            kind = _MemberKind.UNIT_VARIABLE;
          }
          name = variables[0].name.name;
        }
      }
      if (name != null) {
        var item = _PriorityItem.forName(false, name, kind);
        var offset = member.offset;
        var length = member.length;
        var text = code.substring(offset, offset + length);
        members.add(_MemberInfo(item, name, offset, length, text));
      }
    }
    // do sort
    _sortAndReorderMembers(members);
  }

  /// Return the EOL to use for [code].
  static String getEOL(String code) {
    if (code.contains('\r\n')) {
      return '\r\n';
    } else {
      return '\n';
    }
  }

  static int _getPriority(_PriorityItem item) {
    for (var i = 0; i < _PRIORITY_ITEMS.length; i++) {
      if (_PRIORITY_ITEMS[i] == item) {
        return i;
      }
    }
    return 0;
  }

  static List<_MemberInfo> _getSortedMembers(List<_MemberInfo> members) {
    var membersSorted = List<_MemberInfo>.from(members);
    membersSorted.sort((_MemberInfo o1, _MemberInfo o2) {
      var priority1 = _getPriority(o1.item);
      var priority2 = _getPriority(o2.item);
      if (priority1 == priority2) {
        // don't reorder class fields
        if (o1.item.kind == _MemberKind.CLASS_FIELD) {
          return o1.offset - o2.offset;
        }
        // sort all other members by name
        var name1 = o1.name.toLowerCase();
        var name2 = o2.name.toLowerCase();
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
  static const CLASS_ACCESSOR = _MemberKind('CLASS_ACCESSOR');
  static const CLASS_CONSTRUCTOR = _MemberKind('CLASS_CONSTRUCTOR');
  static const CLASS_FIELD = _MemberKind('CLASS_FIELD');
  static const CLASS_METHOD = _MemberKind('CLASS_METHOD');
  static const UNIT_ACCESSOR = _MemberKind('UNIT_ACCESSOR');
  static const UNIT_CLASS = _MemberKind('UNIT_CLASS');
  static const UNIT_EXTENSION = _MemberKind('UNIT_EXTENSION');
  static const UNIT_FUNCTION = _MemberKind('UNIT_FUNCTION');
  static const UNIT_FUNCTION_MAIN = _MemberKind('UNIT_FUNCTION_MAIN');
  static const UNIT_FUNCTION_TYPE = _MemberKind('UNIT_FUNCTION_TYPE');
  static const UNIT_GENERIC_TYPE_ALIAS = _MemberKind('UNIT_GENERIC_TYPE_ALIAS');
  static const UNIT_VARIABLE = _MemberKind('UNIT_VARIABLE');
  static const UNIT_VARIABLE_CONST = _MemberKind('UNIT_VARIABLE_CONST');

  final String name;

  const _MemberKind(this.name);

  @override
  String toString() => name;
}

class _PriorityItem {
  final _MemberKind kind;
  final bool isPrivate;
  final bool isStatic;

  _PriorityItem(this.isStatic, this.kind, this.isPrivate);

  factory _PriorityItem.forName(bool isStatic, String name, _MemberKind kind) {
    var isPrivate = Identifier.isPrivateName(name);
    return _PriorityItem(isStatic, kind, isPrivate);
  }

  @override
  bool operator ==(Object obj) {
    var other = obj as _PriorityItem;
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
