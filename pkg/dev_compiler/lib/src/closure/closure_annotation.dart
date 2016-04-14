// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../js_ast/js_ast.dart' as JS show TypeRef, ClosureTypePrinter;

/// Set of closure annotations that can be [toString]ed to a single JsDoc comment.
/// See https://developers.google.com/closure/compiler/docs/js-for-compiler
///
/// TODO(ochafik): Support inclusion of 'normal' comments (including @param comments).
class ClosureAnnotation {
  final String comment;
  final bool isConst;
  final bool isConstructor;
  final bool isFinal;
  final bool isNoCollapse;
  final bool isNoSideEffects;
  final bool isOverride;
  final bool isPrivate;
  final bool isProtected;
  final bool isStruct;
  final bool isTypedef;
  final JS.TypeRef lendsToType;
  final JS.TypeRef returnType;
  final JS.TypeRef superType;
  final JS.TypeRef thisType;
  final JS.TypeRef throwsType;
  final JS.TypeRef type;
  final List<JS.TypeRef> interfaces;
  final List<String> templates;
  final Map<String, JS.TypeRef> paramTypes;

  ClosureAnnotation(
      {this.comment,
      this.interfaces: const [],
      this.isConst: false,
      this.isConstructor: false,
      this.isFinal: false,
      this.isNoCollapse: false,
      this.isNoSideEffects: false,
      this.isOverride: false,
      this.isPrivate: false,
      this.isProtected: false,
      this.isStruct: false,
      this.isTypedef: false,
      this.lendsToType,
      this.paramTypes: const {},
      this.returnType,
      this.superType,
      this.templates: const [],
      this.thisType,
      this.throwsType,
      this.type});

  @override
  int get hashCode => _cachedString.hashCode;

  @override
  bool operator ==(other) =>
      other is ClosureAnnotation && _cachedString == other._cachedString;

  @override
  String toString([String indent = '']) =>
      _cachedString.replaceAll('\n', '\n$indent');

  String _print(JS.TypeRef t) =>
      (new JS.ClosureTypePrinter()..visit(t)).toString();

  String __cachedString;
  String get _cachedString {
    if (__cachedString == null) {
      bool isNonWildcard(JS.TypeRef t) => t != null && !t.isAny && !t.isUnknown;

      var lines = <String>[];
      if (comment != null) lines.addAll(comment.split('\n'));
      if (templates != null && templates.isNotEmpty) {
        lines.add('@template ${templates.join(', ')}');
      }
      if (thisType != null) lines.add('@this {${_print(thisType)}}');
      if (isOverride) lines.add('@override');
      if (isNoSideEffects) lines.add('@nosideeffects');
      if (isNoCollapse) lines.add('@nocollapse');
      if (lendsToType != null) lines.add('@lends {${_print(lendsToType)}}');

      {
        var typeHolders = <String>[];
        if (isPrivate) typeHolders.add('@private');
        if (isProtected) typeHolders.add('@protected');
        if (isFinal) typeHolders.add('@final');
        if (isConst) typeHolders.add('@const');
        if (isTypedef) typeHolders.add('@typedef');
        if (isNonWildcard(type)) {
          if (typeHolders.isEmpty) typeHolders.add('@type');
          typeHolders.add('{${_print(type)}}');
        }
        if (!typeHolders.isEmpty) lines.add(typeHolders.join(' '));
      }

      {
        List constructorLine = [];
        if (isConstructor) constructorLine.add('@constructor');
        if (isStruct) constructorLine.add('@struct');
        if (isNonWildcard(superType)) {
          constructorLine.add('@extends {${_print(superType)}}');
        }

        if (constructorLine.isNotEmpty) lines.add(constructorLine.join(' '));
      }

      if (interfaces != null) {
        for (var interface in interfaces) {
          if (isNonWildcard(interface))
            lines.add('@implements {${_print(interface)}}');
        }
      }

      if (paramTypes != null) {
        paramTypes.forEach((String paramName, JS.TypeRef paramType) {
          // Must output params even with wildcard type.
          lines.add('@param {${_print(paramType)}} $paramName');
        });
      }
      if (isNonWildcard(returnType))
        lines.add('@return {${_print(returnType)}}');
      if (isNonWildcard(throwsType))
        lines.add('@throws {${_print(throwsType)}}');

      if (lines.length == 0) return '';
      if (lines.length == 1) return '/** ${lines.single} */';
      __cachedString = '/**\n' + lines.map((l) => ' * $l').join('\n') + '\n */';
    }
    return __cachedString;
  }
}
