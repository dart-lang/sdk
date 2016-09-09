// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types;

import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/elements.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../tree/tree.dart';
import '../resolution/tree_elements.dart';
import '../universe/selector.dart' show Selector;

import 'masks.dart';
export 'masks.dart';

/// API to interact with the global type-inference engine.
abstract class TypesInferrer {
  void analyzeMain(Element element);
  TypeMask getReturnTypeOfElement(Element element);
  TypeMask getTypeOfElement(Element element);
  TypeMask getTypeForNewList(Element owner, Node node);
  TypeMask getTypeOfSelector(Selector selector, TypeMask mask);
  void clear();
  bool isCalledOnce(Element element);
  bool isFixedArrayCheckedForGrowable(Node node);
}

/// Results produced by the global type-inference algorithm.
///
/// All queries in this class may contain results that assume whole-program
/// closed-world semantics. Any [TypeMask] for an element or node that we return
/// was inferred to be a "guaranteed type", that means, it is a type that we
/// can prove to be correct for all executions of the program.
class GlobalTypeInferenceResults {
  // TODO(sigmund): store relevant data & drop reference to inference engine.
  final TypesInferrer _inferrer;
  final Compiler compiler;
  final TypeMask dynamicType;

  GlobalTypeInferenceResults(this._inferrer, this.compiler, CommonMasks masks)
      : dynamicType = masks.dynamicType;

  /// Returns the type of a parameter or field [element], if any.
  TypeMask typeOf(Element element) {
    // TODO(24489): trust some JsInterop types.
    if (compiler.backend.isJsInterop(element)) return dynamicType;
    return _inferrer.getTypeOfElement(element);
  }

  /// Returns the return type of a method or function [element].
  TypeMask returnTypeOf(Element element) {
    // TODO(24489): trust some JsInterop types.
    if (compiler.backend.isJsInterop(element)) return dynamicType;
    return _inferrer.getReturnTypeOfElement(element);
  }

  /// Returns the type of a [selector] when applied to a receiver with the given
  /// type [mask].
  TypeMask typeOfSelector(Selector selector, TypeMask mask) =>
      _inferrer.getTypeOfSelector(selector, mask);

  /// Returns whether the method [element] always throws.
  bool throwsAlways(Element element) {
    // We know the element always throws if the return type was inferred to be
    // non-null empty.
    TypeMask returnType = returnTypeOf(element);
    return returnType != null && returnType.isEmpty;
  }

  /// Returns whether [element] is only called once in the entire program.
  bool isCalledOnce(Element element) => _inferrer.isCalledOnce(element);

  // TODO(sigmund): introduce a new class [ElementInferenceResult] that can be
  // used to collect any information that is specific about the body within a
  // single element (basically everything below this line). We could consider
  // moving some of the functions above too, for example:
  //    results.throwsAlways(element)
  // could become:
  //    results[element].alwaysThrows;
  //

  /// Returns the type of a list allocation [node] occuring within [owner].
  ///
  /// [node] can be a list literal or a list new expression.
  TypeMask typeOfNewList(Element owner, Node node) =>
      _inferrer.getTypeForNewList(owner, node);

  /// Returns whether a fixed-length constructor call goes through a growable
  /// check.
  bool isFixedArrayCheckedForGrowable(Node ctorCall) =>
      _inferrer.isFixedArrayCheckedForGrowable(ctorCall);

  /// Returns the type of a send [node].
  TypeMask typeOfSend(
          Node node,
          // TODO(sigmund): move inference data out of TreeElements
          TreeElements elements) =>
      elements.getTypeMask(node);

  /// Returns the type of the operator of a complex send-set [node], for
  /// example, the type of `+` in `a += b`.
  TypeMask typeOfOperator(Send node, TreeElements elements) =>
      elements.getOperatorTypeMaskInComplexSendSet(node);

  /// Returns the type of the getter in a complex send-set [node], for example,
  /// the type of the `a.f` getter in `a.f += b`.
  TypeMask typeOfGetter(node, elements) =>
      elements.getGetterTypeMaskInComplexSendSet(node);

  /// Returns the type of the iterator in a [loop].
  TypeMask typeOfIterator(ForIn loop, elements) =>
      elements.getIteratorTypeMask(loop);

  /// Returns the type of the `moveNext` call of an iterator in a [loop].
  TypeMask typeOfIteratorMoveNext(ForIn loop, elements) =>
      elements.getMoveNextTypeMask(loop);

  /// Returns the type of the `current` getter of an iterator in a [loop].
  TypeMask typeOfIteratorCurrent(ForIn node, elements) =>
      elements.getCurrentTypeMask(node);
}

/// Global analysis that infers concrete types.
class GlobalTypeInferenceTask extends CompilerTask {
  // TODO(sigmund): rename at the same time as our benchmarking tools.
  final String name = 'Type inference';

  final Compiler compiler;
  TypesInferrer typesInferrer;
  CommonMasks masks;
  GlobalTypeInferenceResults results;

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
      results = new GlobalTypeInferenceResults(typesInferrer, compiler, masks);
    });
  }
}
