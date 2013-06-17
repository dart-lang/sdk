// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library container_tracer;

import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../universe/universe.dart';
import '../util/util.dart' show Link;
import 'simple_types_inferrer.dart' show SimpleTypesInferrer, InferrerVisitor;
import 'types.dart';

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

bool _VERBOSE = false;

/**
 * Global analysis phase that traces container instantiations in order to
 * find their element type.
 */
class ContainerTracer extends CompilerTask {
  ContainerTracer(Compiler compiler) : super(compiler);

  String get name => 'List tracer';

  bool analyze() {
    measure(() {
      SimpleTypesInferrer inferrer = compiler.typesTask.typesInferrer;
      var internal = inferrer.internal;
      // Walk over all created [ContainerTypeMask].
      internal.concreteTypes.values.forEach((ContainerTypeMask mask) {
        mask.elementType = new TracerForConcreteContainer(
            mask, this, compiler, inferrer).run();
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
  final SimpleTypesInferrer inferrer;

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
  bool continueAnalyzing = true;

  TracerForConcreteContainer(ContainerTypeMask mask,
                             this.tracer,
                             this.compiler,
                             this.inferrer)
      : analyzedNode = mask.allocationNode,
        startElement = mask.allocationElement;

  TypeMask run() {
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

    if (!continueAnalyzing) return inferrer.dynamicType;

    // [potentialType] can be null if we did not find any instruction
    // that adds elements to the list.
    if (potentialType == null) return new TypeMask.empty();

    potentialType = potentialType.nullable();
    // Walk over the found constraints and update the type according
    // to the selectors of these constraints.
    for (Selector constraint in constraints) {
      assert(constraint.isOperator());
      constraint = new TypedSelector(potentialType, constraint);
      potentialType = potentialType.union(
          inferrer.getTypeOfSelector(constraint), compiler);
    }
    if (_VERBOSE) {
      print('$potentialType for $analyzedNode');
    }
    return potentialType;
  }


  void unionPotentialTypeWith(TypeMask newType) {
    assert(newType != null);
    potentialType = potentialType == null
        ? newType
        : newType.union(potentialType, compiler);
    if (potentialType == inferrer.dynamicType) {
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
    return inferrer.dynamicType;
  }

  bool couldBeTheList(resolved) {
    if (resolved is Selector) {
      return escapingElements.any((e) {
        return e.isInstanceMember()
            && (e.isField() || e.isFunction())
            && resolved.applies(e, compiler);
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

class ContainerTracerVisitor extends InferrerVisitor {
  final Element analyzedElement;
  final TracerForConcreteContainer tracer;
  ContainerTracerVisitor(element, tracer)
      : super(element, tracer.inferrer, tracer.compiler),
        this.analyzedElement = element,
        this.tracer = tracer;

  bool escaping = false;
  bool visitingClosure = false;
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
    bool oldVisitingClosure = visitingClosure;
    FunctionElement function = elements[node];
    FunctionSignature signature = function.computeSignature(compiler);
    signature.forEachParameter((element) {
      locals.update(element, inferrer.getTypeOfElement(element));
    });
    visitingClosure = function != analyzedElement;
    bool oldVisitingInitializers = visitingInitializers;
    visitingInitializers = true;
    visit(node.initializers);
    visitingInitializers = oldVisitingInitializers;
    visit(node.body);
    visitingClosure = oldVisitingClosure;

    return inferrer.functionType;
  }

  TypeMask visitLiteralList(LiteralList node) {
    if (node.isConst()) return inferrer.constListType;
    if (tracer.couldBeTheList(node)) {
      escaping = true;
      for (Node element in node.elements.nodes) {
        tracer.unionPotentialTypeWith(visit(element));
      }
    } else {
      node.visitChildren(this);
    }
    return inferrer.growableListType;
  }

  // TODO(ngeoffray): Try to move the following two methods in
  // [InferrerVisitor].
  TypeMask visitCascadeReceiver(CascadeReceiver node) {
    return visit(node.expression);
  }

  TypeMask visitCascade(Cascade node) {
    Send send = node.expression;
    TypeMask result;
    bool isReceiver = visitAndCatchEscaping(() {
      result = visit(send.receiver);
    });
    if (send.asSendSet() != null) {
      handleSendSet(send, isReceiver);
    } else {
      handleDynamicSend(send, isReceiver);
    }
    if (isReceiver) {
      escaping = true;
    }
    return result;
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
      rhsType = inferrer.intType;
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
        // Changing the length.
        tracer.unionPotentialTypeWith(inferrer.nullType);
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
      locals.update(element, rhsType);
    }

    if (node.isPostfix) {
      // We don't check if [getterSelector] could be the container because
      // a list++ will always throw.
      return inferrer.getTypeOfSelector(getterSelector);
    } else if (op != '=') {
      // We don't check if [getterSelector] could be the container because
      // a list += 42 will always throw.
      return inferrer.getTypeOfSelector(operatorSelector);
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
      return inferrer.getTypeOfElement(element);
    } else if (element.isFunction()) {
      return inferrer.getReturnTypeOfElement(element);
    } else {
      return inferrer.dynamicType;
    }
  }

  TypeMask visitStaticSend(Send node) {
    Element element = elements[node];
    bool isEscaping = visitArguments(node.arguments, element);

    if (element.isForeign(compiler)) {
      if (isEscaping) return tracer.bailout('Used in a JS');
    }

    if (tracer.couldBeTheList(element)) {
      escaping = true;
    }

    if (Elements.isGrowableListConstructorCall(element, node, compiler)) {
      if (tracer.couldBeTheList(node)) {
        escaping = true;
      }
      return inferrer.growableListType;
    } else if (Elements.isFixedListConstructorCall(element, node, compiler)) {
      if (tracer.couldBeTheList(node)) {
        escaping = true;
      }
      return inferrer.fixedListType;
    } else if (element.isFunction() || element.isConstructor()) {
      return inferrer.getReturnTypeOfElement(element);
    } else {
      // Closure call or unresolved.
      return inferrer.dynamicType;
    }
  }

  TypeMask visitGetterSend(Send node) {
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    if (Elements.isStaticOrTopLevelField(element)) {
      if (tracer.couldBeTheList(element)) {
        escaping = true;
      }
      return inferrer.getTypeOfElement(element);
    } else if (Elements.isInstanceSend(node, elements)) {
      return visitDynamicSend(node);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      return inferrer.functionType;
    } else if (Elements.isErroneousElement(element)) {
      return inferrer.dynamicType;
    } else if (Elements.isLocal(element)) {
      if (tracer.couldBeTheList(element)) {
        escaping = true;
      }
      return locals.use(element);
    } else {
      node.visitChildren(this);
      return inferrer.dynamicType;
    }
  }

  TypeMask visitClosureSend(Send node) {
    assert(node.receiver == null);
    visit(node.selector);
    bool isEscaping =
        visitArguments(node.arguments, elements.getSelector(node));

    if (isEscaping) return tracer.bailout('Passed to a closure');
    return inferrer.dynamicType;
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
    if (tracer.couldBeTheList(selector)) {
      escaping = true;
    }
    return inferrer.getTypeOfSelector(selector);
  }

  TypeMask visitReturn(Return node) {
    if (node.expression == null) {
      return inferrer.nullType;
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

    TypeMask iteratorType = inferrer.getTypeOfSelector(iteratorSelector);
    TypeMask currentType = inferrer.getTypeOfSelector(currentSelector);

    // We nullify the type in case there is no element in the
    // iterable.
    currentType = currentType.nullable();

    Node identifier = node.declaredIdentifier;
    Element element = elements[identifier];
    if (Elements.isLocal(element)) {
      locals.update(element, currentType);
    }

    return handleLoop(node, () {
      visit(node.body);
    });
  }
}
