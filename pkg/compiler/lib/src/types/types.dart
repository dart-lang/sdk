// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/elements.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../tree/tree.dart';
import '../universe/selector.dart' show Selector;

import 'masks.dart';
export 'masks.dart';

/// API to interact with the global type-inference engine.
abstract class TypesInferrer {
  void analyzeMain(Element element);
  TypeMask getReturnTypeOfElement(Element element);
  TypeMask getTypeOfElement(Element element);
  TypeMask getTypeOfNode(Element owner, Node node);
  TypeMask getTypeOfSelector(Selector selector, TypeMask mask);
  void clear();
  bool isCalledOnce(Element element);
  bool isFixedArrayCheckedForGrowable(Node node);
}

/// Global analysis that infers concrete types.
class GlobalTypeInferenceTask extends CompilerTask {
  // TODO(sigmund): rename at the same time as our benchmarking tools.
  final String name = 'Type inference';

  final Compiler compiler;
  TypesInferrer typesInferrer;
  CommonMasks masks;

  GlobalTypeInferenceTask(Compiler compiler)
      : masks = new CommonMasks(compiler),
        compiler = compiler,
        super(compiler.measurer) {
    typesInferrer = new TypeGraphInferrer(compiler, masks);
  }

  /// Runs the global type-inference algorithm once.
  void runGlobalTypeInference(Element mainElement) {
    measure(() {
      typesInferrer.analyzeMain(mainElement);
      typesInferrer.clear();
    });
  }

  /**
   * Return the (inferred) guaranteed type of [element] or null.
   */
  TypeMask getGuaranteedTypeOfElement(Element element) {
    // TODO(24489): trust some JsInterop types.
    if (compiler.backend.isJsInterop(element)) {
      return masks.dynamicType;
    }
    TypeMask guaranteedType = typesInferrer.getTypeOfElement(element);
    return guaranteedType;
  }

  TypeMask getGuaranteedReturnTypeOfElement(Element element) {
    // TODO(24489): trust some JsInterop types.
    if (compiler.backend.isJsInterop(element)) {
      return masks.dynamicType;
    }

    TypeMask guaranteedType = typesInferrer.getReturnTypeOfElement(element);
    return guaranteedType;
  }

  /// Return whether the global inference algorithm determined that [element]
  /// always throws.
  bool throwsAlways(Element element) {
    // We know the element always throws if the return type was inferred to be
    // non-null empty.
    TypeMask returnType = getGuaranteedReturnTypeOfElement(element);
    return returnType != null && returnType.isEmpty;
  }

  bool isFixedArrayCheckedForGrowable(Node send) =>
      typesInferrer.isFixedArrayCheckedForGrowable(send);

  bool isCalledOnce(Element element) => typesInferrer.isCalledOnce(element);

  /**
   * Return the (inferred) guaranteed type of [node] or null.
   * [node] must be an AST node of [owner].
   */
  TypeMask getGuaranteedTypeOfNode(owner, node) {
    TypeMask guaranteedType = typesInferrer.getTypeOfNode(owner, node);
    return guaranteedType;
  }

  /**
   * Return the (inferred) guaranteed type of [selector] or null.
   */
  TypeMask getGuaranteedTypeOfSelector(Selector selector, TypeMask mask) {
    TypeMask guaranteedType = typesInferrer.getTypeOfSelector(selector, mask);
    return guaranteedType;
  }
}
