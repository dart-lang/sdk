// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../elements/elements.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../tree/tree.dart';
import '../util/util.dart';
import '../universe/universe.dart';
import '../inferrer/concrete_types_inferrer.dart' show ConcreteTypesInferrer;

part 'container_type_mask.dart';
part 'dictionary_type_mask.dart';
part 'flat_type_mask.dart';
part 'forwarding_type_mask.dart';
part 'map_type_mask.dart';
part 'type_mask.dart';
part 'union_type_mask.dart';
part 'value_type_mask.dart';

/**
 * Common super class for our type inferrers.
 */
abstract class TypesInferrer {
  void analyzeMain(Element element);
  TypeMask getReturnTypeOfElement(Element element);
  TypeMask getTypeOfElement(Element element);
  TypeMask getTypeOfNode(Element owner, Node node);
  TypeMask getTypeOfSelector(Selector selector);
  void clear();
  bool isCalledOnce(Element element);
  bool isFixedArrayCheckedForGrowable(Node node);
}

/**
 * The types task infers guaranteed types globally.
 */
class TypesTask extends CompilerTask {
  static final bool DUMP_BAD_CPA_RESULTS = false;
  static final bool DUMP_GOOD_CPA_RESULTS = false;

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
  TypeMask nonNullTypeCache;
  TypeMask nullTypeCache;
  TypeMask intTypeCache;
  TypeMask uint32TypeCache;
  TypeMask uint31TypeCache;
  TypeMask positiveIntTypeCache;
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

  TypeMask get nonNullType {
    if (nonNullTypeCache == null) {
      nonNullTypeCache = new TypeMask.nonNullSubclass(compiler.objectClass);
    }
    return nonNullTypeCache;
  }

  TypeMask get intType {
    if (intTypeCache == null) {
      intTypeCache = new TypeMask.nonNullSubclass(
          compiler.backend.intImplementation);
    }
    return intTypeCache;
  }

  TypeMask get uint32Type {
    if (uint32TypeCache == null) {
      uint32TypeCache = new TypeMask.nonNullSubclass(
          compiler.backend.uint32Implementation);
    }
    return uint32TypeCache;
  }

  TypeMask get uint31Type {
    if (uint31TypeCache == null) {
      uint31TypeCache = new TypeMask.nonNullExact(
          compiler.backend.uint31Implementation);
    }
    return uint31TypeCache;
  }

  TypeMask get positiveIntType {
    if (positiveIntTypeCache == null) {
      positiveIntTypeCache = new TypeMask.nonNullSubclass(
          compiler.backend.positiveIntImplementation);
    }
    return positiveIntTypeCache;
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

  /** Helper method for [intersection]. */
  TypeMask _intersection(TypeMask type1, TypeMask type2) {
    if (type1 == null) return type2;
    if (type2 == null) return type1;
    return type1.intersection(type2, compiler);
  }

  /** Computes the intersection of [type1] and [type2] */
  TypeMask intersection(TypeMask type1, TypeMask type2, element) {
    TypeMask result = _intersection(type1, type2);
    if (DUMP_BAD_CPA_RESULTS && better(type1, type2)) {
      print("CPA is worse for $element: $type1 /\\ $type2 = $result");
    }
    if (DUMP_GOOD_CPA_RESULTS && better(type2, type1)) {
      print("CPA is better for $element: $type1 /\\ $type2 = $result");
    }
    return result;
  }

  /** Returns true if [type1] is strictly bettern than [type2]. */
  bool better(TypeMask type1, TypeMask type2) {
    if (type1 == null) return false;
    if (type2 == null) {
      return (type1 != null) &&
             (type1 != new TypeMask.subclass(compiler.objectClass));
    }
    return (type1 != type2) &&
           type2.containsMask(type1, compiler) &&
           !type1.containsMask(type2, compiler);
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
          : intersection(guaranteedType,
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
          : intersection(guaranteedType,
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
          : intersection(guaranteedType,
                         concreteTypesInferrer.getTypeOfNode(owner, node),
                         node);
    });
  }

  /**
   * Return the (inferred) guaranteed type of [selector] or null.
   */
  TypeMask getGuaranteedTypeOfSelector(Selector selector) {
    return measure(() {
      TypeMask guaranteedType =
          typesInferrer.getTypeOfSelector(selector);
      return (concreteTypesInferrer == null)
          ? guaranteedType
          : intersection(guaranteedType,
                         concreteTypesInferrer.getTypeOfSelector(selector),
                         selector);
    });
  }
}
