// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import 'dart:collection' show Queue, IterableBase;

import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../tree/tree.dart';
import '../elements/elements.dart';
import '../native_handler.dart' as native;
import '../util/util.dart';
import '../universe/universe.dart';
import 'simple_types_inferrer.dart' show SimpleTypesInferrer;
import '../dart_types.dart';

part 'concrete_types_inferrer.dart';
part 'container_type_mask.dart';
part 'flat_type_mask.dart';
part 'type_mask.dart';
part 'union_type_mask.dart';

/**
 * Common super class for our type inferrers.
 */
abstract class TypesInferrer {
  analyzeMain(Element element);
  TypeMask getReturnTypeOfElement(Element element);
  TypeMask getTypeOfElement(Element element);
  TypeMask getTypeOfNode(Element owner, Node node);
  TypeMask getTypeOfSelector(Selector selector);
}

/**
 * The types task infers guaranteed types globally.
 */
class TypesTask extends CompilerTask {
  static final bool DUMP_SURPRISING_RESULTS = false;

  final String name = 'Type inference';
  SimpleTypesInferrer typesInferrer;
  ConcreteTypesInferrer concreteTypesInferrer;

  TypesTask(Compiler compiler) : super(compiler) {
    typesInferrer = new SimpleTypesInferrer(compiler);
    if (compiler.enableConcreteTypeInference) {
      concreteTypesInferrer = new ConcreteTypesInferrer(compiler);
    }
  }

  TypeMask dynamicType;
  TypeMask nullType;
  TypeMask intType;
  TypeMask doubleType;
  TypeMask numType;
  TypeMask boolType;
  TypeMask functionType;
  TypeMask listType;
  TypeMask constListType;
  TypeMask fixedListType;
  TypeMask growableListType;
  TypeMask mapType;
  TypeMask constMapType;
  TypeMask stringType;
  TypeMask typeType;

  /// Replaces native types by their backend implementation.
  Element normalize(Element cls) {
    if (cls == compiler.boolClass) {
      return compiler.backend.boolImplementation;
    }
    if (cls == compiler.intClass) {
      return compiler.backend.intImplementation;
    }
    if (cls == compiler.doubleClass) {
      return compiler.backend.doubleImplementation;
    }
    if (cls == compiler.numClass) {
      return compiler.backend.numImplementation;
    }
    if (cls == compiler.stringClass) {
      return compiler.backend.stringImplementation;
    }
    if (cls == compiler.listClass) {
      return compiler.backend.listImplementation;
    }
    return cls;
  }

  /// Checks that two [DartType]s are the same modulo normalization.
  bool same(DartType type1, DartType type2) {
    return (type1 == type2)
        || normalize(type1.element) == normalize(type2.element);
  }

  /**
   * Checks that one of [type1] and [type2] is a subtype of the other.
   */
  bool related(DartType type1, DartType type2) {
    return compiler.types.isSubtype(type1, type2)
        || compiler.types.isSubtype(type2, type1);
  }

  /**
   * Return the more precise of both types, giving precedence in that order to
   * exactness, subclassing, subtyping and nullability. The [element] parameter
   * is for debugging purposes only and can be omitted.
   */
  TypeMask best(var type1, var type2, [element]) {
    // TODO(polux): Handle [UnionTypeMask].
    if (type1 != null) type1 = type1.simplify(compiler);
    if (type2 != null) type2 = type2.simplify(compiler);
    final result = _best(type1, type2);
    // Tests type1 and type2 for equality modulo normalization of native types.
    // Only called when DUMP_SURPRISING_RESULTS is true.
    bool similar() {
      if (type1 == null || type2 == null || type1.isEmpty || type2.isEmpty) {
        return type1 == type2;
      }
      return same(type1.base, type2.base);
    }
    if (DUMP_SURPRISING_RESULTS && result == type1 && !similar()) {
      print("$type1 better than $type2 for $element");
    }
    return result;
  }

  /// Helper method for [best].
  TypeMask _best(var type1, var type2) {
    if (type1 == null) return type2;
    if (type2 == null) return type1;
    if (type1.isContainer) type1 = type1.asFlat;
    if (type2.isContainer) type2 = type2.asFlat;
    if (type1.isExact) {
      if (type2.isExact) {
        // TODO(polux): Update the code to not have this situation.
        if (type1.base != type2.base) return type1;
        assert(same(type1.base, type2.base));
        return type1.isNullable ? type2 : type1;
      } else {
        return type1;
      }
    } else if (type2.isExact) {
      return type2;
    } else if (type1.isSubclass) {
      if (type2.isSubclass) {
        assert(related(type1.base, type2.base));
        if (same(type1.base, type2.base)) {
          return type1.isNullable ? type2 : type1;
        } else if (compiler.types.isSubtype(type1.base, type2.base)) {
          return type1;
        } else {
          return type2;
        }
      } else {
        return type1;
      }
    } else if (type2.isSubclass) {
      return type2;
    } else if (type1.isSubtype) {
      if (type2.isSubtype) {
        assert(related(type1.base, type2.base));
        if (same(type1.base, type2.base)) {
          return type1.isNullable ? type2 : type1;
        } else if (compiler.types.isSubtype(type1.base, type2.base)) {
          return type1;
        } else {
          return type2;
        }
      } else {
        return type1;
      }
    } else if (type2.isSubtype) {
      return type2;
    } else {
      return type1.isNullable ? type2 : type1;
    }
  }

  // TODO(ngeoffray): Get rid of this method. Unit tests don't always
  // ensure these classes are resolved.
  rawTypeOf(ClassElement cls) {
    cls.ensureResolved(compiler);
    assert(cls.rawType != null);
    return cls.rawType;
  }

  void initializeTypes() {
    nullType = new TypeMask.empty();

    Backend backend = compiler.backend;
    intType = new TypeMask.nonNullExact(
        rawTypeOf(backend.intImplementation));
    doubleType = new TypeMask.nonNullExact(
        rawTypeOf(backend.doubleImplementation));
    numType = new TypeMask.nonNullSubclass(
        rawTypeOf(backend.numImplementation));
    stringType = new TypeMask.nonNullExact(
        rawTypeOf(backend.stringImplementation));
    boolType = new TypeMask.nonNullExact(
        rawTypeOf(backend.boolImplementation));

    listType = new TypeMask.nonNullExact(
        rawTypeOf(backend.listImplementation));
    constListType = new TypeMask.nonNullExact(
        rawTypeOf(backend.constListImplementation));
    fixedListType = new TypeMask.nonNullExact(
        rawTypeOf(backend.fixedListImplementation));
    growableListType = new TypeMask.nonNullExact(
        rawTypeOf(backend.growableListImplementation));

    mapType = new TypeMask.nonNullSubtype(
        rawTypeOf(backend.mapImplementation));
    constMapType = new TypeMask.nonNullSubtype(
        rawTypeOf(backend.constMapImplementation));
    functionType = new TypeMask.nonNullSubtype(
        rawTypeOf(backend.functionImplementation));
    typeType = new TypeMask.nonNullExact(
        rawTypeOf(backend.typeImplementation));

    dynamicType = new TypeMask.subclass(rawTypeOf(compiler.objectClass));
  }

  /**
   * Called when resolution is complete.
   */
  void onResolutionComplete(Element mainElement) {
    measure(() {
      initializeTypes();
      typesInferrer.analyzeMain(mainElement);
      if (concreteTypesInferrer != null) {
        bool success = concreteTypesInferrer.analyzeMain(mainElement);
        if (!success) {
          // If the concrete type inference bailed out, we pretend it didn't
          // happen. In the future we might want to record that it failed but
          // use the partial results as hints.
          concreteTypesInferrer = null;
        }
      }
    });
    compiler.containerTracer.analyze();
    typesInferrer.clear();
  }

  /**
   * Return the (inferred) guaranteed type of [element] or null.
   */
  TypeMask getGuaranteedTypeOfElement(Element element) {
    return measure(() {
      TypeMask guaranteedType = typesInferrer.getTypeOfElement(element);
      return (concreteTypesInferrer == null)
          ? guaranteedType
          : best(guaranteedType,
                 concreteTypesInferrer.getTypeOfElement(element),
                 element);
    });
  }

  TypeMask getGuaranteedReturnTypeOfElement(Element element) {
    return measure(() {
      TypeMask guaranteedType =
          typesInferrer.getReturnTypeOfElement(element);
      return (concreteTypesInferrer == null)
          ? guaranteedType
          : best(guaranteedType,
                 concreteTypesInferrer.getReturnTypeOfElement(element),
                 element);
    });
  }

  /**
   * Return the (inferred) guaranteed type of [node] or null.
   * [node] must be an AST node of [owner].
   */
  TypeMask getGuaranteedTypeOfNode(owner, node) {
    return measure(() {
      TypeMask guaranteedType = typesInferrer.getTypeOfNode(owner, node);
      return (concreteTypesInferrer == null)
          ? guaranteedType
          : best(guaranteedType,
                 concreteTypesInferrer.getTypeOfNode(owner, node),
                 node);
    });
  }

  /**
   * Return the (inferred) guaranteed type of [selector] or null.
   * [node] must be an AST node of [owner].
   */
  TypeMask getGuaranteedTypeOfSelector(Selector selector) {
    return measure(() {
      TypeMask guaranteedType =
          typesInferrer.getTypeOfSelector(selector);
      return (concreteTypesInferrer == null)
          ? guaranteedType
          : best(guaranteedType,
                 concreteTypesInferrer.getTypeOfSelector(selector),
                 selector);
    });
  }
}
