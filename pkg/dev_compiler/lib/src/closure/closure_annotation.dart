// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.closure.closure_annotation;

import 'closure_type.dart';

/// Set of closure annotations that can be [toString]ed to a single JsDoc comment.
/// See https://developers.google.com/closure/compiler/docs/js-for-compiler
///
/// TODO(ochafik): Support inclusion of 'normal' comments (including @param comments).
class ClosureAnnotation {
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
  final ClosureType lendsToType;
  final ClosureType returnType;
  final ClosureType superType;
  final ClosureType thisType;
  final ClosureType throwsType;
  final ClosureType type;
  final List<ClosureType> interfaces;
  final List<String> templates;
  final Map<String, ClosureType> paramTypes;

  ClosureAnnotation({this.interfaces: const [], this.isConst: false,
      this.isConstructor: false, this.isFinal: false, this.isNoCollapse: false,
      this.isNoSideEffects: false, this.isOverride: false,
      this.isPrivate: false, this.isProtected: false, this.isStruct: false,
      this.isTypedef: false, this.lendsToType, this.paramTypes: const {},
      this.returnType, this.superType, this.templates: const [], this.thisType,
      this.throwsType, this.type});

  @override
  int get hashCode => _cachedString.hashCode;

  @override
  bool operator ==(other) =>
      other is ClosureAnnotation && _cachedString == other._cachedString;

  @override
  String toString([String indent = '']) =>
      _cachedString.replaceAll('\n', '\n$indent');

  String __cachedString;
  String get _cachedString {
    if (__cachedString == null) {
      bool isNonWildcard(ClosureType t) =>
          t != null && !t.isAll && !t.isUnknown;

      var lines = <String>[];
      if (templates != null && templates.isNotEmpty) {
        lines.add('@template ${templates.join(', ')}');
      }
      if (thisType != null) lines.add('@this {$thisType}');
      if (isOverride) lines.add('@override');
      if (isNoSideEffects) lines.add('@nosideeffects');
      if (isNoCollapse) lines.add('@nocollapse');
      if (lendsToType != null) lines.add('@lends {$lendsToType}');

      {
        var typeHolders = <String>[];
        if (isPrivate) typeHolders.add('@private');
        if (isProtected) typeHolders.add('@protected');
        if (isFinal) typeHolders.add('@final');
        if (isConst) typeHolders.add('@const');
        if (isTypedef) typeHolders.add('@typedef');
        if (isNonWildcard(type)) {
          if (typeHolders.isEmpty) typeHolders.add('@type');
          typeHolders.add('{$type}');
        }
        if (!typeHolders.isEmpty) lines.add(typeHolders.join(' '));
      }

      {
        List constructorLine = [];
        if (isConstructor) constructorLine.add('@constructor');
        if (isStruct) constructorLine.add('@struct');
        if (isNonWildcard(superType)) {
          constructorLine.add('@extends {$superType}');
        }

        if (constructorLine.isNotEmpty) lines.add(constructorLine.join(' '));
      }

      for (var interface in interfaces) {
        if (isNonWildcard(interface)) lines.add('@implements {$interface}');
      }

      paramTypes.forEach((String paramName, ClosureType paramType) {
        // Must output params even with wildcard type.
        lines.add('@param {$paramType} $paramName');
      });
      if (isNonWildcard(returnType)) lines.add('@return {$returnType}');
      if (isNonWildcard(throwsType)) lines.add('@throws {$throwsType}');

      if (lines.length == 0) return '';
      if (lines.length == 1) return '/** ${lines.single} */';
      __cachedString = '/**\n' + lines.map((l) => ' * $l').join('\n') + '\n */';
    }
    return __cachedString;
  }
}
