// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library container_tracer;

import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../universe/universe.dart';
import '../util/util.dart' show Link;
import 'simple_types_inferrer.dart'
    show InferrerEngine, InferrerVisitor, LocalsHandler, TypeMaskSystem;
import '../types/types.dart';
import 'inferrer_visitor.dart';

/**
 * A set of selector names that [List] implements, that we know do not
 * change the element type of the list, or let the list escape to code
 * that might change the element type.
 */
Set<String> okSelectorsSet = new Set<String>.from(
  const <String>[
    // From Object.
    '==',
    'hashCode',
    'toString',
    'noSuchMethod',
    'runtimeType',

    // From Iterable.
    'iterator',
    'map',
    'where',
    'expand',
    'contains',
    'forEach',
    'reduce',
    'fold',
    'every',
    'join',
    'any',
    'toList',
    'toSet',
    'length',
    'isEmpty',
    'isNotEmpty',
    'take',
    'takeWhile',
    'skip',
    'skipWhile',
    'first',
    'last',
    'single',
    'firstWhere',
    'lastWhere',
    'singleWhere',
    'elementAt',

    // From List.
    '[]',
    'length',
    'reversed',
    'sort',
    'indexOf',
    'lastIndexOf',
    'clear',
    'remove',
    'removeAt',
    'removeLast',
    'removeWhere',
    'retainWhere',
    'sublist',
    'getRange',
    'removeRange',
    'asMap',

    // From JSArray.
    'checkMutable',
    'checkGrowable',
  ]);

Set<String> doNotChangeLengthSelectorsSet = new Set<String>.from(
  const <String>[
    // From Object.
    '==',
    'hashCode',
    'toString',
    'noSuchMethod',
    'runtimeType',

    // From Iterable.
    'iterator',
    'map',
    'where',
    'expand',
    'contains',
    'forEach',
    'reduce',
    'fold',
    'every',
    'join',
    'any',
    'toList',
    'toSet',
    'length',
    'isEmpty',
    'isNotEmpty',
    'take',
    'takeWhile',
    'skip',
    'skipWhile',
    'first',
    'last',
    'single',
    'firstWhere',
    'lastWhere',
    'singleWhere',
    'elementAt',

    // From List.
    '[]',
    'length',
    'reversed',
    'sort',
    'indexOf',
    'lastIndexOf',
    'sublist',
    'getRange',
    'asMap',

    // From JSArray.
    'checkMutable',
    'checkGrowable',
  ]);

bool _VERBOSE = false;

class InferrerEngineForContainerTracer
    implements MinimalInferrerEngine<TypeMask> {
  final Compiler compiler;

  InferrerEngineForContainerTracer(this.compiler);

  TypeMask typeOfElement(Element element) {
    return compiler.typesTask.getGuaranteedTypeOfElement(element);
  }

  TypeMask returnTypeOfElement(Element element) {
    return compiler.typesTask.getGuaranteedReturnTypeOfElement(element);
  }

  TypeMask returnTypeOfSelector(Selector selector) {
    return compiler.typesTask.getGuaranteedTypeOfSelector(selector);
  }

  TypeMask typeOfNode(Node node) {
    return compiler.typesTask.getGuaranteedTypeOfNode(null, node);
  }

  Iterable<Element> getCallersOf(Element element) {
    return compiler.typesTask.typesInferrer.getCallersOf(element);
  }

  void recordTypeOfNonFinalField(Node node,
                                 Element field,
                                 TypeMask type) {}
}

/**
 * Global analysis phase that traces container instantiations in order to
 * find their element type.
 */
class ContainerTracer extends CompilerTask {
  ContainerTracer(Compiler compiler) : super(compiler);

  String get name => 'List tracer';

  bool analyze() {
    measure(() {
      if (compiler.disableTypeInference) return;
      TypesInferrer inferrer = compiler.typesTask.typesInferrer;
      InferrerEngineForContainerTracer engine =
          new InferrerEngineForContainerTracer(compiler);

      // Walk over all created [ContainerTypeMask].
      inferrer.containerTypes.forEach((ContainerTypeMask mask) {
        // The element type has already been set for const containers.
        if (mask.elementType != null) return;
        new TracerForConcreteContainer(mask, this, compiler, engine).run();
      });
    });
  }
}

/**
 * A tracer for a specific container.
 */
class TracerForConcreteContainer {
  final Compiler compiler;
  final ContainerTracer tracer;
  final InferrerEngineForContainerTracer inferrer;
  final ContainerTypeMask mask;

  final Node analyzedNode;
  final Element startElement;

  final List<Element> workList = <Element>[];

  /**
   * A set of elements where this list might escape.
   */
  final Set<Element> escapingElements = new Set<Element>();

  /**
   * A set of selectors that both use and update the list, for example
   * [: list[0]++; :] or [: list[0] |= 42; :].
   */
  final Set<Selector> constraints = new Set<Selector>();

  /**
   * A cache of setters that were already seen. Caching these
   * selectors avoid the filtering done in [addSettersToAnalysis].
   */
  final Set<Selector> seenSetterSelectors = new Set<Selector>();

  static const int MAX_ANALYSIS_COUNT = 11;

  TypeMask potentialType;
  int potentialLength;
  bool isLengthTrackingDisabled = false;
  bool continueAnalyzing = true;

  TracerForConcreteContainer(ContainerTypeMask mask,
                             this.tracer,
                             this.compiler,
                             this.inferrer)
      : analyzedNode = mask.allocationNode,
        startElement = mask.allocationElement,
        this.mask = mask;

  void run() {
    int analysisCount = 0;
    workList.add(startElement);
    while (!workList.isEmpty) {
      if (workList.length + analysisCount > MAX_ANALYSIS_COUNT) {
        bailout('Too many users');
        break;
      }
      Element currentElement = workList.removeLast().implementation;
      new ContainerTracerVisitor(currentElement, this).run();
      if (!continueAnalyzing) break;
      analysisCount++;
    }

    if (!continueAnalyzing) {
      if (mask.forwardTo == compiler.typesTask.fixedListType) {
        mask.length = potentialLength;
      }
      mask.elementType = compiler.typesTask.dynamicType;
      return;
    }

    // [potentialType] can be null if we did not find any instruction
    // that adds elements to the list.
    if (potentialType == null) {
      if (_VERBOSE) {
        print('Found empty type for $analyzedNode $startElement');
      }
      mask.elementType = new TypeMask.nonNullEmpty();
      return;
    }

    // Walk over the found constraints and update the type according
    // to the selectors of these constraints.
    for (Selector constraint in constraints) {
      assert(constraint.isOperator());
      constraint = new TypedSelector(potentialType, constraint);
      potentialType = potentialType.union(
          inferrer.returnTypeOfSelector(constraint), compiler);
    }
    if (_VERBOSE) {
      print('$potentialType and $potentialLength '
            'for $analyzedNode $startElement');
    }
    mask.elementType = potentialType;
    mask.length = potentialLength;
  }

  void disableLengthTracking() {
    if (mask.forwardTo == compiler.typesTask.fixedListType) {
      // Bogus update to a fixed list.
      return;
    }
    isLengthTrackingDisabled = true;
    potentialLength = null;
  }

  void setPotentialLength(int value) {
    if (isLengthTrackingDisabled) return;
    potentialLength = value;
  }

  void unionPotentialTypeWith(TypeMask newType) {
    assert(newType != null);
    potentialType = potentialType == null
        ? newType
        : newType.union(potentialType, compiler);
    if (potentialType == compiler.typesTask.dynamicType) {
      bailout('Moved to dynamic');
    }
  }

  void addEscapingElement(element) {
    element = element.implementation;
    if (escapingElements.contains(element)) return;
    escapingElements.add(element);
    if (element.isField() || element.isGetter() || element.isFunction()) {
      for (Element e in inferrer.getCallersOf(element)) {
        addElementToAnalysis(e);
      }
    } else if (element.isParameter()) {
      addElementToAnalysis(element.enclosingElement);
    } else if (element.isFieldParameter()) {
      addEscapingElement(element.fieldElement);
    }
  }

  void addSettersToAnalysis(Selector selector) {
    assert(selector.isSetter());
    if (seenSetterSelectors.contains(selector)) return;
    seenSetterSelectors.add(selector);
    for (var e in compiler.world.allFunctions.filter(selector)) {
      e = e.implementation;
      if (e.isField()) {
        addEscapingElement(e);
      } else {
        FunctionSignature signature = e.computeSignature(compiler);
        signature.forEachRequiredParameter((Element e) {
          addEscapingElement(e);
        });
      }
    }
  }

  void addElementToAnalysis(Element element) {
    workList.add(element);
  }

  TypeMask bailout(String reason) {
    if (_VERBOSE) {
      print('Bailout on $analyzedNode $startElement because of $reason');
    }
    continueAnalyzing = false;
    return compiler.typesTask.dynamicType;
  }

  bool couldBeTheList(resolved) {
    if (resolved is Selector) {
      return escapingElements.any((e) {
        return e.isInstanceMember() && resolved.applies(e, compiler);
      });
    } else if (resolved is Node) {
      return analyzedNode == resolved;
    } else {
      assert(resolved is Element);
      return escapingElements.contains(resolved);
    }
  }

  void recordConstraint(Selector selector) {
    constraints.add(selector);
  }
}

class ContainerTracerVisitor
    extends InferrerVisitor<TypeMask, InferrerEngineForContainerTracer> {
  final Element analyzedElement;
  final TracerForConcreteContainer tracer;
  final bool visitingClosure;

  ContainerTracerVisitor(element, tracer, [LocalsHandler<TypeMask> locals])
      : super(element, tracer.inferrer, new TypeMaskSystem(tracer.compiler),
              tracer.compiler, locals),
        this.analyzedElement = element,
        this.tracer = tracer,
        visitingClosure = locals != null;

  bool escaping = false;
  bool visitingInitializers = false;

  void run() {
    compiler.withCurrentElement(analyzedElement, () {
      visit(analyzedElement.parseNode(compiler));
    });
  }

  /**
   * Executes [f] and returns whether it triggered the list to escape.
   */
  bool visitAndCatchEscaping(Function f) {
    bool oldEscaping = escaping;
    escaping = false;
    f();
    bool foundEscaping = escaping;
    escaping = oldEscaping;
    return foundEscaping;
  }

  /**
   * Visits the [arguments] of [callee], and records the parameters
   * that could hold the container as escaping.
   *
   * Returns whether the container escaped.
   */
  bool visitArguments(Link<Node> arguments, /* Element or Selector */ callee) {
    List<int> indices = [];
    int index = 0;
    for (Node node in arguments) {
      if (visitAndCatchEscaping(() { visit(node); })) {
        indices.add(index);
      }
      index++;
    }
    if (!indices.isEmpty) {
      Iterable<Element> callees;
      if (callee is Element) {
        // No need to go further, we know the call will throw.
        if (callee.isErroneous()) return false;
        callees = [callee];
      } else {
        assert(callee is Selector);
        callees = compiler.world.allFunctions.filter(callee);
      }
      for (var e in callees) {
        e = e.implementation;
        if (e.isField()) {
          tracer.bailout('Passed to a closure');
          break;
        }
        FunctionSignature signature = e.computeSignature(compiler);
        index = 0;
        int parameterIndex = 0;
        signature.forEachRequiredParameter((Element parameter) {
          if (index < indices.length && indices[index] == parameterIndex) {
            tracer.addEscapingElement(parameter);
            index++;
          }
          parameterIndex++;
        });
        if (index != indices.length) {
          tracer.bailout('Used in a named parameter or closure');
        }
      }
      return true;
    } else {
      return false;
    }
  }

  TypeMask visitFunctionExpression(FunctionExpression node) {
    FunctionElement function = elements[node];
    if (function != analyzedElement) {
      // Visiting a closure.
      LocalsHandler closureLocals = new LocalsHandler<TypeMask>.from(
          locals, node, useOtherTryBlock: false);
      new ContainerTracerVisitor(function, tracer, closureLocals).run();
      return types.functionType;
    } else {
      // Visiting [analyzedElement].
      FunctionSignature signature = function.computeSignature(compiler);
      signature.forEachParameter((element) {
        locals.update(element, inferrer.typeOfElement(element), node);
      });
      visitingInitializers = true;
      visit(node.initializers);
      visitingInitializers = false;
      visit(node.body);
      return null;
    }
  }

  TypeMask visitLiteralList(LiteralList node) {
    if (node.isConst()) {
      return inferrer.typeOfNode(node);
    }
    if (tracer.couldBeTheList(node)) {
      escaping = true;
      int length = 0;
      for (Node element in node.elements.nodes) {
        tracer.unionPotentialTypeWith(visit(element));
        length++;
      }
      tracer.setPotentialLength(length);
    } else {
      node.visitChildren(this);
    }
    return types.growableListType;
  }

  TypeMask visitSendSet(SendSet node) {
    bool isReceiver = visitAndCatchEscaping(() {
      visit(node.receiver);
    });
    return handleSendSet(node, isReceiver);
  }

  TypeMask handleSendSet(SendSet node, bool isReceiver) {
    TypeMask rhsType;
    TypeMask indexType;

    Selector getterSelector =
        elements.getGetterSelectorInComplexSendSet(node);
    Selector operatorSelector =
        elements.getOperatorSelectorInComplexSendSet(node);
    Selector setterSelector = elements.getSelector(node);

    String op = node.assignmentOperator.source.stringValue;
    bool isIncrementOrDecrement = op == '++' || op == '--';
    bool isIndexEscaping = false;
    bool isValueEscaping = false;
    if (isIncrementOrDecrement) {
      rhsType = types.intType;
      if (node.isIndex) {
        isIndexEscaping = visitAndCatchEscaping(() {
          indexType = visit(node.arguments.head);
        });
      }
    } else if (node.isIndex) {
      isIndexEscaping = visitAndCatchEscaping(() {
        indexType = visit(node.arguments.head);
      });
      isValueEscaping = visitAndCatchEscaping(() {
        rhsType = visit(node.arguments.tail.head);
      });
    } else {
      isValueEscaping = visitAndCatchEscaping(() {
        rhsType = visit(node.arguments.head);
      });
    }

    Element element = elements[node];

    if (node.isIndex) {
      if (isReceiver) {
        if (op == '=') {
          tracer.unionPotentialTypeWith(rhsType);
        } else {
          tracer.recordConstraint(operatorSelector);
        }
      } else if (isIndexEscaping || isValueEscaping) {
        // If the index or value is escaping, iterate over all
        // potential targets, and mark their parameter as escaping.
        for (var e in compiler.world.allFunctions.filter(setterSelector)) {
          e = e.implementation;
          FunctionSignature signature = e.computeSignature(compiler);
          int index = 0;
          signature.forEachRequiredParameter((Element parameter) {
            if (index == 0 && isIndexEscaping) {
              tracer.addEscapingElement(parameter);
            }
            if (index == 1 && isValueEscaping) {
              tracer.addEscapingElement(parameter);
            }
            index++;
          });
        }
      }
    } else if (isReceiver) {
      if (setterSelector.name == const SourceString('length')) {
        tracer.disableLengthTracking();
        tracer.unionPotentialTypeWith(compiler.typesTask.nullType);
      }
    } else if (isValueEscaping) {
      if (element != null
          && element.isField()
          && setterSelector == null
          && !visitingInitializers) {
        // Initializer at declaration of a field.
        assert(analyzedElement.isField());
        tracer.addEscapingElement(analyzedElement);
      } else if (element != null
                  && (!element.isInstanceMember() || visitingInitializers)) {
        // A local, a static element, or a field in an initializer.
        tracer.addEscapingElement(element);
      } else {
        tracer.addSettersToAnalysis(setterSelector);
      }
    }

    if (Elements.isLocal(element)) {
      locals.update(element, rhsType, node);
    }

    if (node.isPostfix) {
      // We don't check if [getterSelector] could be the container because
      // a list++ will always throw.
      return inferrer.returnTypeOfSelector(getterSelector);
    } else if (op != '=') {
      // We don't check if [getterSelector] could be the container because
      // a list += 42 will always throw.
      return inferrer.returnTypeOfSelector(operatorSelector);
    } else {
      if (isValueEscaping) {
        escaping = true;
      }
      return rhsType;
    }
  }

  TypeMask visitSuperSend(Send node) {
    Element element = elements[node];
    if (!node.isPropertyAccess) {
      visitArguments(node.arguments, element);
    }

    if (tracer.couldBeTheList(element)) {
      escaping = true;
    }

    if (element.isField()) {
      return inferrer.typeOfElement(element);
    } else if (element.isFunction()) {
      return inferrer.returnTypeOfElement(element);
    } else {
      return types.dynamicType;
    }
  }

  TypeMask visitStaticSend(Send node) {
    Element element = elements[node];

    if (Elements.isGrowableListConstructorCall(element, node, compiler)) {
      visitArguments(node.arguments, element);
      if (tracer.couldBeTheList(node)) {
        escaping = true;
      }
      return inferrer.typeOfNode(node);
    } else if (Elements.isFixedListConstructorCall(element, node, compiler)) {
      visitArguments(node.arguments, element);
      if (tracer.couldBeTheList(node)) {
        tracer.unionPotentialTypeWith(types.nullType);
        escaping = true;
        LiteralInt length = node.arguments.head.asLiteralInt();
        if (length != null) {
          tracer.setPotentialLength(length.value);
        }
      }
      return inferrer.typeOfNode(node);
    } else if (Elements.isFilledListConstructorCall(element, node, compiler)) {
      if (tracer.couldBeTheList(node)) {
        escaping = true;
        visit(node.arguments.head);
        TypeMask fillWithType = visit(node.arguments.tail.head);
        tracer.unionPotentialTypeWith(fillWithType);
        LiteralInt length = node.arguments.head.asLiteralInt();
        if (length != null) {
          tracer.setPotentialLength(length.value);
        }
      } else {
        visitArguments(node.arguments, element);
      }
      return inferrer.typeOfNode(node);
    }

    bool isEscaping = visitArguments(node.arguments, element);

    if (element.isForeign(compiler)) {
      if (isEscaping) return tracer.bailout('Used in a JS');
    }

    if (tracer.couldBeTheList(element)) {
      escaping = true;
    }

    if (element.isFunction() || element.isConstructor()) {
      return inferrer.returnTypeOfElement(element);
    } else {
      // Closure call or unresolved.
      return types.dynamicType;
    }
  }

  TypeMask visitGetterSend(Send node) {
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    if (Elements.isStaticOrTopLevelField(element)) {
      if (tracer.couldBeTheList(element)) {
        escaping = true;
      }
      return inferrer.typeOfElement(element);
    } else if (Elements.isInstanceSend(node, elements)) {
      return visitDynamicSend(node);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      return types.functionType;
    } else if (Elements.isErroneousElement(element)) {
      return types.dynamicType;
    } else if (Elements.isLocal(element)) {
      if (tracer.couldBeTheList(element)) {
        escaping = true;
      }
      return locals.use(element);
    } else {
      node.visitChildren(this);
      return types.dynamicType;
    }
  }

  TypeMask visitClosureSend(Send node) {
    assert(node.receiver == null);
    visit(node.selector);
    bool isEscaping =
        visitArguments(node.arguments, elements.getSelector(node));

    if (isEscaping) return tracer.bailout('Passed to a closure');
    return types.dynamicType;
  }

  TypeMask visitDynamicSend(Send node) {
    bool isReceiver = visitAndCatchEscaping(() {
      visit(node.receiver);
    });
    return handleDynamicSend(node, isReceiver);
  }

  TypeMask handleDynamicSend(Send node, bool isReceiver) {
    Selector selector = elements.getSelector(node);
    String selectorName = selector.name.slowToString();
    if (isReceiver && !okSelectorsSet.contains(selectorName)) {
      if (selector.isCall()
          && (selectorName == 'add' || selectorName == 'insert')) {
        TypeMask argumentType;
        if (node.arguments.isEmpty
            || (selectorName == 'insert' && node.arguments.tail.isEmpty)) {
          return tracer.bailout('Invalid "add" or "insert" call on a list');
        }
        bool isEscaping = visitAndCatchEscaping(() {
          argumentType = visit(node.arguments.head);
          if (selectorName == 'insert') {
            argumentType = visit(node.arguments.tail.head);
          }
        });
        if (isEscaping) {
          return tracer.bailout('List containing itself');
        }
        tracer.unionPotentialTypeWith(argumentType);
      } else {
        return tracer.bailout('Send with the node as receiver $node');
      }
    } else if (!node.isPropertyAccess) {
      visitArguments(node.arguments, selector);
    }
    if (isReceiver && !doNotChangeLengthSelectorsSet.contains(selectorName)) {
      tracer.disableLengthTracking();
    }
    if (tracer.couldBeTheList(selector)) {
      escaping = true;
    }
    return inferrer.returnTypeOfSelector(selector);
  }

  TypeMask visitReturn(Return node) {
    if (node.expression == null) {
      return types.nullType;
    }

    TypeMask type;
    bool isEscaping = visitAndCatchEscaping(() {
      type = visit(node.expression);
    });

    if (isEscaping) {
      if (visitingClosure) {
        tracer.bailout('Return from closure');
      } else {
        tracer.addEscapingElement(analyzedElement);
      }
    }
    return type;
  }

  TypeMask visitForIn(ForIn node) {
    visit(node.expression);
    Selector iteratorSelector = elements.getIteratorSelector(node);
    Selector currentSelector = elements.getCurrentSelector(node);

    TypeMask iteratorType = inferrer.returnTypeOfSelector(iteratorSelector);
    TypeMask currentType = inferrer.returnTypeOfSelector(currentSelector);

    // We nullify the type in case there is no element in the
    // iterable.
    currentType = currentType.nullable();

    Node identifier = node.declaredIdentifier;
    Element element = elements[identifier];
    if (Elements.isLocal(element)) {
      locals.update(element, currentType, node);
    }

    return handleLoop(node, () {
      visit(node.body);
    });
  }
}
