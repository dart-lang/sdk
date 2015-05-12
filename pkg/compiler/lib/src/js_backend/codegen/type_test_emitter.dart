// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of code_generator;

abstract class TypeTestEmitter {
  giveup(node, reason);
  Glue get glue;

  js.Expression emitSubtypeTest(tree_ir.Node node,
                                js.Expression value,
                                DartType type) {
    return glue.isNativePrimitiveType(type)
        ? emitNativeSubtypeTest(node, value, type.element)
        : emitGeneralSubtypeTest(node, value, type);
  }

  js.Expression emitNativeSubtypeTest(tree_ir.Node node,
                                      js.Expression value,
                                      ClassElement cls) {
    if (glue.isIntClass(cls)) {
      return _emitIntCheck(value);
    } else if (glue.isStringClass(cls)) {
      return _emitTypeofCheck(value, 'string');
    } else if (glue.isBoolClass(cls)) {
      return _emitTypeofCheck(value, 'boolean');
    } else if (glue.isNumClass(cls) || glue.isDoubleClass(cls)) {
      return _emitNumCheck(value);
    } else {
      return giveup(value, 'type check unimplemented for ${cls.name}.');
    }
  }

  js.Expression emitGeneralSubtypeTest(tree_ir.Node node,
                                       js.Expression value,
                                       InterfaceType type) {
    return new js.Binary('&&',
        new js.Prefix('!!', value),
        new js.Prefix('!!',
            new js.PropertyAccess.field(value, glue.getTypeTestTag(type))));
  }

  js.Expression _emitNumCheck(js.Expression value) {
    return _emitTypeofCheck(value, 'number');
  }

  js.Expression _emitBigIntCheck(js.Expression value) {
    return js.js('Math.floor(#) === #', [value, value]);
  }

  js.Expression _emitIntCheck(js.Expression value) {
    return new js.Binary('&&',
        _emitNumCheck(value),
        _emitBigIntCheck(value));
  }

  js.Expression _emitTypeofCheck(js.Expression value, String type) {
    return new js.Binary('===',
        new js.Prefix("typeof", value),
        js.string(type));
  }
}