// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class TypeMaskFactory {
  static TypeMask fromInferredType(TypeMask mask, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    if (mask == null) return backend.dynamicType;
    return mask;
  }

  static TypeMask inferredReturnTypeForElement(
      Element element, Compiler compiler) {
    return fromInferredType(
        compiler.typesTask.getGuaranteedReturnTypeOfElement(element),
        compiler);
  }

  static TypeMask inferredTypeForElement(Element element, Compiler compiler) {
    return fromInferredType(
        compiler.typesTask.getGuaranteedTypeOfElement(element),
        compiler);
  }

  static TypeMask inferredTypeForSelector(Selector selector, Compiler compiler) {
    return fromInferredType(
        compiler.typesTask.getGuaranteedTypeOfSelector(selector),
        compiler);
  }

  static TypeMask inferredForNode(Element owner, ast.Node node,
                                  Compiler compiler) {
    return fromInferredType(
        compiler.typesTask.getGuaranteedTypeOfNode(owner, node),
        compiler);
  }

  static TypeMask fromNativeBehavior(native.NativeBehavior nativeBehavior,
                                     Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    if (nativeBehavior.typesReturned.isEmpty) return backend.dynamicType;

    TypeMask result = nativeBehavior.typesReturned
        .map((type) => fromNativeType(type, compiler))
        .reduce((t1, t2) => t1.union(t2, compiler));
    assert(!(result.isEmpty && !result.isNullable));
    return result;
  }

  // [type] is either an instance of [DartType] or special objects
  // like [native.SpecialType.JsObject].
  static TypeMask fromNativeType(type, Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    if (type == native.SpecialType.JsObject) {
      return new TypeMask.nonNullExact(compiler.objectClass);
    } else if (type.isVoid) {
      return backend.nullType;
    } else if (type.element == compiler.nullClass) {
      return backend.nullType;
    } else if (type.treatAsDynamic) {
      return backend.dynamicType;
    } else if (compiler.world.hasAnySubtype(type.element)) {
      return new TypeMask.nonNullSubtype(type.element);
    } else if (compiler.world.hasAnySubclass(type.element)) {
      return new TypeMask.nonNullSubclass(type.element);
    } else {
      return new TypeMask.nonNullExact(type.element);
    }
  }
}
