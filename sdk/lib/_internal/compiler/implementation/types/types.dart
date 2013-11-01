// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../tree/tree.dart';
import '../util/util.dart';
import '../universe/universe.dart';
import 'concrete_types_inferrer.dart' show ConcreteTypesInferrer;

part 'container_type_mask.dart';
part 'flat_type_mask.dart';
part 'forwarding_type_mask.dart';
part 'type_mask.dart';
part 'union_type_mask.dart';

/**
 * Common super class for our type inferrers.
 */
abstract class TypesInferrer {
  void analyzeMain(Element element);
  TypeMask getReturnTypeOfElement(Element element);
  TypeMask getTypeOfElement(Element element);
  TypeMask getTypeOfNode(Element owner, Node node);
  TypeMask getTypeOfSelector(Selector selector);
  Iterable<TypeMask> get containerTypes;
  void clear();
  Iterable<Element> getCallersOf(Element element);
}

/**
 * The types task infers guaranteed types globally.
 */
class TypesTask extends CompilerTask {
  static final bool DUMP_SURPRISING_RESULTS = false;

  final String name = 'Type inference';
  TypesInferrer typesInferrer;
  ConcreteTypesInferrer concreteTypesInferrer;

  TypesTask(Compiler compiler) : super(compiler) {
    typesInferrer = new TypeGraphInferrer(compiler);
    if (compiler.enableConcreteTypeInference) {
      concreteTypesInferrer = new ConcreteTypesInferrer(compiler);
    }
  }

  TypeMask dynamicTypeCache;
  TypeMask nullTypeCache;
  TypeMask intTypeCache;
  TypeMask doubleTypeCache;
  TypeMask numTypeCache;
  TypeMask boolTypeCache;
  TypeMask functionTypeCache;
  TypeMask listTypeCache;
  TypeMask constListTypeCache;
  TypeMask fixedListTypeCache;
  TypeMask growableListTypeCache;
  TypeMask mapTypeCache;
  TypeMask constMapTypeCache;
  TypeMask stringTypeCache;
  TypeMask typeTypeCache;

  TypeMask get dynamicType {
    if (dynamicTypeCache == null) {
      dynamicTypeCache = new TypeMask.subclass(compiler.objectClass);
    }
    return dynamicTypeCache;
  }

  TypeMask get intType {
    if (intTypeCache == null) {
      intTypeCache = new TypeMask.nonNullExact(
          compiler.backend.intImplementation);
    }
    return intTypeCache;
  }

  TypeMask get doubleType {
    if (doubleTypeCache == null) {
      doubleTypeCache = new TypeMask.nonNullExact(
          compiler.backend.doubleImplementation);
    }
    return doubleTypeCache;
  }

  TypeMask get numType {
    if (numTypeCache == null) {
      numTypeCache = new TypeMask.nonNullSubclass(
          compiler.backend.numImplementation);
    }
    return numTypeCache;
  }

  TypeMask get boolType {
    if (boolTypeCache == null) {
      boolTypeCache = new TypeMask.nonNullExact(
          compiler.backend.boolImplementation);
    }
    return boolTypeCache;
  }

  TypeMask get functionType {
    if (functionTypeCache == null) {
      functionTypeCache = new TypeMask.nonNullSubtype(
          compiler.backend.functionImplementation);
    }
    return functionTypeCache;
  }

  TypeMask get listType {
    if (listTypeCache == null) {
      listTypeCache = new TypeMask.nonNullExact(
          compiler.backend.listImplementation);
    }
    return listTypeCache;
  }

  TypeMask get constListType {
    if (constListTypeCache == null) {
      constListTypeCache = new TypeMask.nonNullExact(
          compiler.backend.constListImplementation);
    }
    return constListTypeCache;
  }

  TypeMask get fixedListType {
    if (fixedListTypeCache == null) {
      fixedListTypeCache = new TypeMask.nonNullExact(
          compiler.backend.fixedListImplementation);
    }
    return fixedListTypeCache;
  }

  TypeMask get growableListType {
    if (growableListTypeCache == null) {
      growableListTypeCache = new TypeMask.nonNullExact(
          compiler.backend.growableListImplementation);
    }
    return growableListTypeCache;
  }

  TypeMask get mapType {
    if (mapTypeCache == null) {
      mapTypeCache = new TypeMask.nonNullSubtype(
          compiler.backend.mapImplementation);
    }
    return mapTypeCache;
  }

  TypeMask get constMapType {
    if (constMapTypeCache == null) {
      constMapTypeCache = new TypeMask.nonNullSubtype(
          compiler.backend.constMapImplementation);
    }
    return constMapTypeCache;
  }

  TypeMask get stringType {
    if (stringTypeCache == null) {
      stringTypeCache = new TypeMask.nonNullExact(
          compiler.backend.stringImplementation);
    }
    return stringTypeCache;
  }

  TypeMask get typeType {
    if (typeTypeCache == null) {
      typeTypeCache = new TypeMask.nonNullExact(
          compiler.backend.typeImplementation);
    }
    return typeTypeCache;
  }

  TypeMask get nullType {
    if (nullTypeCache == null) {
      // TODO(johnniwinther): Assert that the null type has been resolved.
      nullTypeCache = const TypeMask.empty();
    }
    return nullTypeCache;
  }


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

  /// Checks that two types are the same modulo normalization.
  bool same(ClassElement type1, ClassElement type2) {
    return (type1 == type2) || normalize(type1) == normalize(type2);
  }

  /**
   * Checks that one of [type1] and [type2] is a subtype of the other.
   */
  bool related(ClassElement type1, ClassElement type2) {
    return compiler.types.isSubtype(type1.rawType, type2.rawType)
        || compiler.types.isSubtype(type2.rawType, type1.rawType);
  }

  /**
   * Return the more precise of both types, giving precedence in that order to
   * exactness, subclassing, subtyping and nullability. The [element] parameter
   * is for debugging purposes only and can be omitted.
   */
  FlatTypeMask best(TypeMask type1, TypeMask type2, [element]) {
    // TODO(polux): Handle [UnionTypeMask].
    if (type1 != null) type1 = type1.simplify(compiler);
    if (type2 != null) type2 = type2.simplify(compiler);
    FlatTypeMask result = _best(type1, type2);
    // Tests type1 and type2 for equality modulo normalization of native types.
    // Only called when DUMP_SURPRISING_RESULTS is true.
    bool similar() {
      if (type1 == null || type2 == null || type1.isEmpty || type2.isEmpty) {
        return type1 == type2;
      }
      FlatTypeMask flat1 = type1;
      FlatTypeMask flat2 = type2;
      return same(flat1.base, flat2.base);
    }
    if (DUMP_SURPRISING_RESULTS && result == type1 && !similar()) {
      print("$type1 better than $type2 for $element");
    }
    return result;
  }

  /// Helper method for [best].
  FlatTypeMask _best(var type1, var type2) {
    if (type1 == null) return type2;
    if (type2 == null) return type1;
    FlatTypeMask flat1 = type1.isContainer ? type1.asFlat : type1;
    FlatTypeMask flat2 = type2.isContainer ? type2.asFlat : type2;
    if (flat1.isExact) {
      if (flat2.isExact) {
        // TODO(polux): Update the code to not have this situation.
        if (flat1.base != flat2.base) return flat1;
        assert(same(flat1.base, flat2.base));
        return flat1.isNullable ? flat2 : flat1;
      } else {
        return flat1;
      }
    } else if (flat2.isExact) {
      return flat2;
    } else if (flat1.isSubclass) {
      if (flat2.isSubclass) {
        assert(related(flat1.base, flat2.base));
        if (same(flat1.base, flat2.base)) {
          return flat1.isNullable ? flat2 : flat1;
        } else if (compiler.types.isSubtype(flat1.base.rawType,
                                            flat2.base.rawType)) {
          return flat1;
        } else {
          return flat2;
        }
      } else {
        return flat1;
      }
    } else if (flat2.isSubclass) {
      return flat2;
    } else if (flat1.isSubtype) {
      if (flat2.isSubtype) {
        assert(related(flat1.base, flat2.base));
        if (same(flat1.base, flat2.base)) {
          return flat1.isNullable ? flat2 : flat1;
        } else if (compiler.types.isSubtype(flat1.base.rawType,
                                            flat2.base.rawType)) {
          return flat1;
        } else {
          return flat2;
        }
      } else {
        return flat1;
      }
    } else if (flat2.isSubtype) {
      return flat2;
    } else {
      return flat1.isNullable ? flat2 : flat1;
    }
  }

  /**
   * Called when resolution is complete.
   */
  void onResolutionComplete(Element mainElement) {
    measure(() {
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
