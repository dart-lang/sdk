#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_checker.dart' as type_checker;
import 'package:kernel/type_algebra.dart';

import 'package:kernel/text/ast_to_text.dart';

void main(List<String> args) {
  final binary = loadProgramFromBinary(args[0]);

  final checker = new TypeChecker(binary)..checkProgram(binary);
  if (checker.fails > 0) {
    print('------- Reported ${checker.fails} errors -------');
    exit(-1);
  }
}

class TypeChecker extends type_checker.TypeChecker {
  /// Number of fails found.
  int fails = 0;

  TypeChecker(Program program)
      : this._(new CoreTypes(program), new ClosedWorldClassHierarchy(program));

  TypeChecker._(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : super(coreTypes, hierarchy, strongMode: true, ignoreSdk: false);

  // TODO(vegorov) this only gets called for immediate overrides which leads
  // to less strict checking that Dart 2.0 specification demands for covariant
  // parameters.
  @override
  void checkOverride(
      Class host, Member ownMember, Member superMember, bool isSetter) {
    final ownMemberIsFieldOrAccessor =
        ownMember is Field || (ownMember as Procedure).isAccessor;
    final superMemberIsFieldOrAccessor =
        superMember is Field || (superMember as Procedure).isAccessor;

    // First check if we are overriding field/accessor with a normal method
    // or other way around.
    if (ownMemberIsFieldOrAccessor != superMemberIsFieldOrAccessor) {
      return _reportInvalidOverride(ownMember, superMember, '''
${ownMember} is a ${_memberKind(ownMember)}
${superMember} is a ${_memberKind(superMember)}
''');
    }

    if (ownMemberIsFieldOrAccessor) {
      if (isSetter) {
        final DartType ownType = setterType(host, ownMember);
        final DartType superType = setterType(host, superMember);
        final isCovariant = ownMember is Field
            ? ownMember.isCovariant
            : ownMember.function.positionalParameters[0].isCovariant;
        if (!_isValidParameterOverride(isCovariant, ownType, superType)) {
          if (isCovariant) {
            return _reportInvalidOverride(ownMember, superMember, '''
${ownType} is neither a subtype nor supertype of ${superType}
''');
          } else {
            return _reportInvalidOverride(ownMember, superMember, '''
${ownType} is not a subtype of ${superType}
''');
          }
        }
      } else {
        final DartType ownType = getterType(host, ownMember);
        final DartType superType = getterType(host, superMember);
        if (!environment.isSubtypeOf(ownType, superType)) {
          return _reportInvalidOverride(ownMember, superMember, '''
${ownType} is not a subtype of ${superType}
''');
        }
      }
    } else {
      final msg = _checkFunctionOverride(host, ownMember, superMember);
      if (msg != null) {
        return _reportInvalidOverride(ownMember, superMember, msg);
      }
    }
  }

  void _reportInvalidOverride(
      Member ownMember, Member superMember, String message) {
    fail(ownMember, '''
Incompatible override of ${superMember} with ${ownMember}:

    ${_realign(message, '    ')}''');
  }

  String _memberKind(Member m) {
    if (m is Field) {
      return 'field';
    } else {
      final p = m as Procedure;
      if (p.isGetter) {
        return 'getter';
      } else if (p.isSetter) {
        return 'setter';
      } else {
        return 'method';
      }
    }
  }

  /// Check if [subtype] is subtype of [supertype] after applying
  /// type parameter [substitution].
  bool _isSubtypeOf(DartType subtype, DartType supertype) =>
      environment.isSubtypeOf(subtype, supertype);

  Substitution _makeSubstitutionForMember(Class host, Member member) {
    final hostType =
        hierarchy.getClassAsInstanceOf(host, member.enclosingClass);
    return Substitution.fromSupertype(hostType);
  }

  /// Check if function node [ownMember] is a valid override for [superMember].
  /// Returns [null] if override is valid or an error message.
  ///
  /// Note: this function is a copy of [SubtypeTester._isFunctionSubtypeOf]
  /// but it additionally accounts for parameter covariance.
  String _checkFunctionOverride(
      Class host, Member ownMember, Member superMember) {
    final FunctionNode ownFunction = ownMember.function;
    final FunctionNode superFunction = superMember.function;
    Substitution ownSubstitution = _makeSubstitutionForMember(host, ownMember);
    final Substitution superSubstitution =
        _makeSubstitutionForMember(host, superMember);

    if (ownFunction.requiredParameterCount >
        superFunction.requiredParameterCount) {
      return 'override has more required parameters';
    }
    if (ownFunction.positionalParameters.length <
        superFunction.positionalParameters.length) {
      return 'super method has more positional parameters';
    }
    if (ownFunction.typeParameters.length !=
        superFunction.typeParameters.length) {
      return 'methods have different type parameters counts';
    }

    if (ownFunction.typeParameters.isNotEmpty) {
      final typeParameterMap = <TypeParameter, DartType>{};
      for (int i = 0; i < ownFunction.typeParameters.length; ++i) {
        var subParameter = ownFunction.typeParameters[i];
        var superParameter = superFunction.typeParameters[i];
        typeParameterMap[subParameter] = new TypeParameterType(superParameter);
      }

      ownSubstitution = Substitution.combine(
          ownSubstitution, Substitution.fromMap(typeParameterMap));
      for (int i = 0; i < ownFunction.typeParameters.length; ++i) {
        var subParameter = ownFunction.typeParameters[i];
        var superParameter = superFunction.typeParameters[i];
        var subBound = ownSubstitution.substituteType(subParameter.bound);
        if (!_isSubtypeOf(
            superSubstitution.substituteType(superParameter.bound), subBound)) {
          return 'type parameters have incompatible bounds';
        }
      }
    }

    if (!_isSubtypeOf(ownSubstitution.substituteType(ownFunction.returnType),
        superSubstitution.substituteType(superFunction.returnType))) {
      return 'return type of override ${ownFunction.returnType} is not a subtype'
          ' of ${superFunction.returnType}';
    }

    for (int i = 0; i < superFunction.positionalParameters.length; ++i) {
      final ownParameter = ownFunction.positionalParameters[i];
      final superParameter = superFunction.positionalParameters[i];
      if (!_isValidParameterOverride(
          ownParameter.isCovariant,
          ownSubstitution.substituteType(ownParameter.type),
          superSubstitution.substituteType(superParameter.type))) {
        return '''
type of parameter ${ownParameter.name} is incompatible
override declares ${ownParameter.type}
super method declares ${superParameter.type}
''';
      }
    }

    if (superFunction.namedParameters.isEmpty) {
      return null;
    }

    // Note: FunctionNode.namedParameters are not sorted so we convert them
    // to map to make lookup faster.
    final ownParameters = new Map<String, VariableDeclaration>.fromIterable(
        ownFunction.namedParameters,
        key: (v) => v.name);
    for (VariableDeclaration superParameter in superFunction.namedParameters) {
      final ownParameter = ownParameters[superParameter.name];
      if (ownParameter == null) {
        return 'override is missing ${superParameter.name} parameter';
      }

      if (!_isValidParameterOverride(
          ownParameter.isCovariant,
          ownSubstitution.substituteType(ownParameter.type),
          superSubstitution.substituteType(superParameter.type))) {
        return '''
type of parameter ${ownParameter.name} is incompatible
override declares ${ownParameter.type}
super method declares ${superParameter.type}
''';
      }
    }

    return null;
  }

  /// Checks whether parameter with [ownParameterType] type is a valid override
  /// for parameter with [superParameterType] type taking into account its
  /// covariance and applying type parameter [substitution] if necessary.
  bool _isValidParameterOverride(bool isCovariant, DartType ownParameterType,
      DartType superParameterType) {
    if (_isSubtypeOf(superParameterType, ownParameterType)) {
      return true;
    } else if (isCovariant &&
        _isSubtypeOf(ownParameterType, superParameterType)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void checkAssignable(TreeNode where, DartType from, DartType to) {
    // Note: we permit implicit downcasts.
    if (from != to &&
        !environment.isSubtypeOf(from, to) &&
        !environment.isSubtypeOf(to, from)) {
      fail(
          where,
          '${ansiBlue}${from}${ansiReset} ${ansiYellow}is not assignable to'
          '${ansiReset} ${ansiBlue}${to}${ansiReset}');
    }
  }

  @override
  void checkUnresolvedInvocation(DartType receiver, TreeNode where) {
    if (receiver is DynamicType) {
      return;
    }

    fail(where, 'Unresolved method invocation');
  }

  @override
  void fail(TreeNode where, String message) {
    fails++;

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

    print('''
-----------------------------------------------------------------------
In ${name} at ${sourceLocation}:

    ${message.replaceAll('\n', '\n    ')}

Kernel:
|
|   ${_realign(HighlightingPrinter.stringifyContainingLines(body, where))}
|
''');

    if (sourceLine != null) {
      print('''
Source:
|
|   ${_realign(sourceLine)}
|
''');
    }
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
