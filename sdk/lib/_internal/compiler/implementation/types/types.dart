// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import 'dart:collection' show Queue, IterableBase;

import '../dart2jslib.dart' hide Selector;
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../tree/tree.dart';
import '../elements/elements.dart';
import '../native_handler.dart' as native;
import '../util/util.dart';
import '../universe/universe.dart';
import 'simple_types_inferrer.dart' show SimpleTypesInferrer;
import '../dart_types.dart';

part 'concrete_types_inferrer.dart';
part 'type_mask.dart';

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
  final String name = 'Type inference';
  TypesInferrer typesInferrer;

  TypesTask(Compiler compiler)
    : typesInferrer = compiler.enableConcreteTypeInference
          ? new ConcreteTypesInferrer(compiler)
          : new SimpleTypesInferrer(compiler),
      super(compiler);

  /**
   * Called when resolution is complete.
   */
  void onResolutionComplete(Element mainElement) {
    measure(() {
      if (typesInferrer != null) {
        bool success = typesInferrer.analyzeMain(mainElement);
        if (!success) {
          // If the concrete type inference bailed out, we pretend it didn't
          // happen. In the future we might want to record that it failed but
          // use the partial results as hints.
          typesInferrer = null;
        }
      }
    });
  }

  /**
   * Return the (inferred) guaranteed type of [element] or null.
   */
  TypeMask getGuaranteedTypeOfElement(Element element) {
    return measure(() {
      if (typesInferrer != null) {
        TypeMask guaranteedType =
            typesInferrer .getTypeOfElement(element);
        if (guaranteedType != null) return guaranteedType;
      }
      return null;
    });
  }

  TypeMask getGuaranteedReturnTypeOfElement(Element element) {
    return measure(() {
      if (typesInferrer != null) {
        TypeMask guaranteedType =
            typesInferrer.getReturnTypeOfElement(element);
        if (guaranteedType != null) return guaranteedType;
      }
      return null;
    });
  }

  /**
   * Return the (inferred) guaranteed type of [node] or null.
   * [node] must be an AST node of [owner].
   */
  TypeMask getGuaranteedTypeOfNode(owner, node) {
    return measure(() {
      if (typesInferrer != null) {
        return typesInferrer.getTypeOfNode(owner, node);
      }
      return null;
    });
  }

  /**
   * Return the (inferred) guaranteed type of [selector] or null.
   * [node] must be an AST node of [owner].
   */
  TypeMask getGuaranteedTypeOfSelector(Selector selector) {
    return measure(() {
      if (typesInferrer != null) {
        return typesInferrer.getTypeOfSelector(selector);
      }
      return null;
    });
  }
}
