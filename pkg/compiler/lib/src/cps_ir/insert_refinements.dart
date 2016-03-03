// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cps_ir.optimization.insert_refinements;

import 'dart:math' show min;
import 'optimizers.dart' show Pass;
import 'cps_ir_nodes.dart';
import '../elements/elements.dart';
import '../common/names.dart';
import '../types/types.dart' show TypeMask;
import '../universe/selector.dart';
import 'type_mask_system.dart';

/// Inserts [Refinement] nodes in the IR to allow for sparse path-sensitive
/// type analysis in the [TypePropagator] pass.
///
/// Refinement nodes are inserted at the arms of a [Branch] node with a
/// condition of form `x is T` or `x == null`.
///
/// Refinement nodes are inserted after a method invocation to refine the
/// receiver to the types that can respond to the given selector.
class InsertRefinements extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Insert refinement nodes';

  final TypeMaskSystem types;

  /// Maps unrefined primitives to its refinement currently in scope (if any).
  final Map<Primitive, Refinement> refinementFor = <Primitive, Refinement>{};

  InsertRefinements(this.types);

  void rewrite(FunctionDefinition node) {
    visit(node.body);
  }

  /// Updates references to refer to the refinement currently in scope.
  void processReference(Reference node) {
    Definition definition = node.definition;
    if (definition is Primitive) {
      Primitive prim = definition.effectiveDefinition;
      Refinement refined = refinementFor[prim];
      if (refined != null && refined != definition) {
        node.changeTo(refined);
      }
    }
  }

  /// Sinks the binding of [cont] to immediately above [use].
  ///
  /// This is used to ensure that everything in scope at [use] is also in scope
  /// inside [cont], so refinements can be inserted inside [cont] without
  /// accidentally referencing a primitive out of scope.
  ///
  /// It is always safe to do this for single-use continuations, because
  /// strictly more things are in scope at the use site, and there can't be any
  /// other use of [cont] that might fall out of scope since there is only
  /// that single use.
  void sinkContinuationToUse(Continuation cont, Expression use) {
    assert(cont.hasExactlyOneUse && cont.firstRef.parent == use);
    assert(!cont.isRecursive);
    LetCont let = cont.parent;
    InteriorNode useParent = use.parent;
    if (useParent == let) return;
    if (let.continuations.length > 1) {
      // Create a new LetCont binding only this continuation.
      let.continuations.remove(cont);
      let = new LetCont(cont, null);
    } else {
      let.remove(); // Reuse the existing LetCont.
    }
    let.insertAbove(use);
  }

  /// Sets [refined] to be the current refinement for its value, and pushes an
  /// action that will restore the original scope again.
  ///
  /// The refinement is inserted as the child of [insertionParent] if it has
  /// at least one use after its scope has been processed.
  void applyRefinement(InteriorNode insertionParent, Refinement refined) {
    Primitive value = refined.effectiveDefinition;
    Primitive currentRefinement = refinementFor[value];
    refinementFor[value] = refined;
    pushAction(() {
      refinementFor[value] = currentRefinement;
      if (refined.hasNoUses) {
        // Clean up refinements that are not used.
        refined.destroy();
      } else {
        LetPrim let = new LetPrim(refined);
        let.insertBelow(insertionParent);
      }
    });
  }

  /// Enqueues [cont] for processing in a context where [refined] is the
  /// current refinement for its value.
  void pushRefinement(Continuation cont, Refinement refined) {
    pushAction(() {
      applyRefinement(cont, refined);
      push(cont);
    });
  }

  /// Refine the type of each argument on [node] according to the provided
  /// type masks.
  void _refineArguments(
      InvocationPrimitive node, List<TypeMask> argumentSuccessTypes) {
    if (argumentSuccessTypes == null) return;

    // Note: node.dartArgumentsLength is shorter when the call doesn't include
    // some optional arguments.
    int length = min(argumentSuccessTypes.length, node.dartArgumentsLength);
    for (int i = 0; i < length; i++) {
      TypeMask argSuccessType = argumentSuccessTypes[i];

      // Skip arguments that provide no refinement.
      if (argSuccessType == types.dynamicType) continue;

      applyRefinement(node.parent,
          new Refinement(node.dartArgument(i), argSuccessType));
    }
  }

  void visitInvokeStatic(InvokeStatic node) {
    node.argumentRefs.forEach(processReference);
    _refineArguments(node,
        _getSuccessTypesForStaticMethod(types, node.target));
  }

  void visitInvokeMethod(InvokeMethod node) {
    // Update references to their current refined values.
    processReference(node.receiverRef);
    node.argumentRefs.forEach(processReference);

    // If the call is intercepted, we want to refine the actual receiver,
    // not the interceptor.
    Primitive receiver = node.dartReceiver;

    // Do not try to refine the receiver of closure calls; the class world
    // does not know about closure classes.
    Selector selector = node.selector;
    if (!selector.isClosureCall) {
      // Filter away receivers that throw on this selector.
      TypeMask type = types.receiverTypeFor(selector, node.mask);
      Refinement refinement = new Refinement(receiver, type);
      LetPrim letPrim = node.parent;
      applyRefinement(letPrim, refinement);

      // Refine arguments of methods on numbers which we know will throw on
      // invalid argument values.
      _refineArguments(node,
          _getSuccessTypesForInstanceMethod(types, type, selector));
    }
  }

  void visitTypeCast(TypeCast node) {
    Primitive value = node.value;

    processReference(node.valueRef);
    node.typeArgumentRefs.forEach(processReference);

    // Refine the type of the input.
    TypeMask type = types.subtypesOf(node.dartType).nullable();
    Refinement refinement = new Refinement(value, type);
    LetPrim letPrim = node.parent;
    applyRefinement(letPrim, refinement);
  }

  void visitRefinement(Refinement node) {
    // We found a pre-existing refinement node. These are generated by the
    // IR builder to hold information from --trust-type-annotations.
    // Update its input to use our own current refinement, then update the
    // environment to use this refinement.
    processReference(node.value);
    Primitive value = node.value.definition.effectiveDefinition;
    Primitive oldRefinement = refinementFor[value];
    refinementFor[value] = node;
    pushAction(() {
      refinementFor[value] = oldRefinement;
    });
  }

  bool isTrue(Primitive prim) {
    return prim is Constant && prim.value.isTrue;
  }

  void visitBranch(Branch node) {
    processReference(node.conditionRef);
    Primitive condition = node.condition;

    Continuation trueCont = node.trueContinuation;
    Continuation falseCont = node.falseContinuation;

    // Sink both continuations to the Branch to ensure everything in scope
    // here is also in scope inside the continuations.
    sinkContinuationToUse(trueCont, node);
    sinkContinuationToUse(falseCont, node);

    // If the condition is an 'is' check, promote the checked value.
    if (condition is TypeTest) {
      Primitive value = condition.value;
      TypeMask type = types.subtypesOf(condition.dartType);
      Primitive refinedValue = new Refinement(value, type);
      pushRefinement(trueCont, refinedValue);
      push(falseCont);
      return;
    }

    // If the condition is comparison with a constant, promote the other value.
    // This can happen either for calls to `==` or `identical` calls, such
    // as the ones inserted by the unsugaring pass.

    void refineEquality(Primitive first,
                        Primitive second,
                        Continuation trueCont,
                        Continuation falseCont) {
      if (second is Constant && second.value.isNull) {
        Refinement refinedTrue = new Refinement(first, types.nullType);
        Refinement refinedFalse = new Refinement(first, types.nonNullType);
        pushRefinement(trueCont, refinedTrue);
        pushRefinement(falseCont, refinedFalse);
      } else if (first is Constant && first.value.isNull) {
        Refinement refinedTrue = new Refinement(second, types.nullType);
        Refinement refinedFalse = new Refinement(second, types.nonNullType);
        pushRefinement(trueCont, refinedTrue);
        pushRefinement(falseCont, refinedFalse);
      } else {
        push(trueCont);
        push(falseCont);
      }
    }

    if (condition is InvokeMethod && condition.selector == Selectors.equals) {
      refineEquality(condition.dartReceiver,
                     condition.dartArgument(0),
                     trueCont,
                     falseCont);
      return;
    }

    if (condition is ApplyBuiltinOperator &&
        condition.operator == BuiltinOperator.Identical) {
      refineEquality(condition.argument(0),
                     condition.argument(1),
                     trueCont,
                     falseCont);
      return;
    }

    push(trueCont);
    push(falseCont);
  }

  @override
  Expression traverseLetCont(LetCont node) {
    for (Continuation cont in node.continuations) {
      // Do not push the branch continuations here. visitBranch will do that.
      if (!(cont.hasExactlyOneUse && cont.firstRef.parent is Branch)) {
        push(cont);
      }
    }
    return node.body;
  }
}

// TODO(sigmund): ideally this whitelist information should be stored as
// metadata annotations on the runtime libraries so we can keep it in sync with
// the implementation more easily.
// TODO(sigmund): add support for constructors.
// TODO(sigmund): add checks for RegExp and DateTime (currently not exposed as
// easily in TypeMaskSystem).
// TODO(sigmund): after the above TODOs are fixed, add:
//   ctor JSArray.fixed: [types.uint32Type],
//   ctor JSArray.growable: [types.uintType],
//   ctor DateTime': [int, int, int, int, int, int, int],
//   ctor DateTime.utc': [int, int, int, int, int, int, int],
//   ctor DateTime._internal': [int, int, int, int, int, int, int, bool],
//   ctor RegExp': [string, dynamic, dynamic],
//   method RegExp.allMatches: [string, int],
//   method RegExp.firstMatch: [string],
//   method RegExp.hasMatch: [string],
List<TypeMask> _getSuccessTypesForInstanceMethod(
    TypeMaskSystem types, TypeMask receiver, Selector selector) {
  if (types.isDefinitelyInt(receiver)) {
    switch (selector.name) {
      case 'toSigned':
      case 'toUnsigned':
      case 'modInverse':
      case 'gcd':
        return [types.intType];

      case 'modPow':
       return [types.intType, types.intType];
    }
    // Note: num methods on int values are handled below.
  }

  if (types.isDefinitelyNum(receiver)) {
    switch (selector.name) {
      case 'clamp':
          return [types.numType, types.numType];
      case 'toStringAsFixed':
      case 'toStringAsPrecision':
      case 'toRadixString':
          return [types.intType];
      case 'toStringAsExponential':
          return [types.intType.nullable()];
      case 'compareTo':
      case 'remainder':
      case '+':
      case '-':
      case '/':
      case '*':
      case '%':
      case '~/':
      case '<<':
      case '>>':
      case '&':
      case '|':
      case '^':
      case '<':
      case '>':
      case '<=':
      case '>=':
          return [types.numType];
      default:
        return null;
    }
  }

  if (types.isDefinitelyString(receiver)) {
    switch (selector.name) {
      case 'allMatches':
        return [types.stringType, types.intType];
      case 'endsWith':
        return [types.stringType];
      case 'replaceAll':
        return [types.dynamicType, types.stringType];
      case 'replaceFirst':
        return [types.dynamicType, types.stringType, types.intType];
      case 'replaceFirstMapped':
        return [
          types.dynamicType,
          types.dynamicType.nonNullable(),
          types.intType
        ];
      case 'split':
        return [types.dynamicType.nonNullable()];
      case 'replaceRange':
        return [types.intType, types.intType, types.stringType];
      case 'startsWith':
        return [types.dynamicType, types.intType];
      case 'substring':
        return [types.intType, types.uintType.nullable()];
      case 'indexOf':
        return [types.dynamicType.nonNullable(), types.uintType];
      case 'lastIndexOf':
        return [types.dynamicType.nonNullable(), types.uintType.nullable()];
      case 'contains':
        return [
          types.dynamicType.nonNullable(),
          // TODO(sigmund): update runtime to add check for int?
          types.dynamicType
        ];
      case 'codeUnitAt':
        return [types.uintType];
      case '+':
        return [types.stringType];
      case '*':
        return [types.uint32Type];
      case '[]':
        return [types.uintType];
      default:
        return null;
    }
  }

  if (types.isDefinitelyArray(receiver)) {
    switch (selector.name) {
      case 'removeAt':
      case 'insert':
        return [types.uintType];
      case 'sublist':
        return [types.uintType, types.uintType.nullable()];
      case 'length':
         return selector.isSetter ? [types.uintType] : null;
      case '[]':
      case '[]=':
        return [types.uintType];
      default:
        return null;
    }
  }
  return null;
}

List<TypeMask> _getSuccessTypesForStaticMethod(
    TypeMaskSystem types, FunctionElement target) {
  var lib = target.library;
  if (lib.isDartCore) {
    var cls = target.enclosingClass?.name;
    if (cls == 'int' && target.name == 'parse') {
      // source, onError, radix
      return [types.stringType, types.dynamicType, types.uint31Type.nullable()];
    } else if (cls == 'double' && target.name == 'parse') {
      return [types.stringType, types.dynamicType];
    }
  }

  if (lib.isPlatformLibrary && '${lib.canonicalUri}' == 'dart:math') {
    switch(target.name) {
      case 'sqrt':
      case 'sin':
      case 'cos':
      case 'tan':
      case 'acos':
      case 'asin':
      case 'atan':
      case 'atan2':
      case 'exp':
      case 'log':
        return [types.numType];
      case 'pow':
        return [types.numType, types.numType];
    }
  }

  return null;
}
