// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library simple_types_inferrer;

import '../native_handler.dart' as native;
import '../elements/elements.dart';
import '../dart2jslib.dart';
import '../tree/tree.dart';
import '../util/util.dart' show Link;
import 'types.dart' show TypesInferrer, ConcreteType, ClassBaseType;

/**
 * A work queue that ensures there are no duplicates, and adds and
 * removes in LIFO.
 */
class WorkSet<E extends Element> {
  final List<E> queue = new List<E>();
  final Set<E> elementsInQueue = new Set<E>();
  
  void add(E element) {
    element = element.implementation;
    if (elementsInQueue.contains(element)) return;
    queue.addLast(element);
    elementsInQueue.add(element);
  }

  E remove() {
    E element = queue.removeLast();
    elementsInQueue.remove(element);
    return element;
  }

  bool get isEmpty => queue.isEmpty;
}

class SimpleTypesInferrer extends TypesInferrer {
  /**
   * Maps an element to its callers.
   */
  final Map<Element, Set<Element>> callersOf =
      new Map<Element, Set<Element>>();

  /**
   * Maps an element to its return type.
   */
  final Map<Element, Element> returnTypeOf =
      new Map<Element, Element>();

  /**
   * Maps a name to elements in the universe that have that name.
   */
  final Map<SourceString, Set<Element>> methodCache =
      new Map<SourceString, Set<Element>>();

  /**
   * Maps an element to the number of times this type inferrer
   * analyzed it.
   */
  final Map<Element, int> analyzeCount = new Map<Element, int>();

  /**
   * The work list of the inferrer.
   */
  final WorkSet<Element> workSet = new WorkSet<Element>();

  /**
   * Heuristic for avoiding too many re-analysis of an element.
   */
  final int MAX_ANALYSIS_COUNT_PER_ELEMENT = 5;

  /**
   * Sentinal used by the inferrer to notify that it gave up finding a type
   * on a specific element.
   */
  Element giveUpType;

  final Compiler compiler;

  // Times the computation of the call graph.
  final Stopwatch memberWatch = new Stopwatch();
  // Times the computation of re-analysis of methods.
  final Stopwatch recomputeWatch = new Stopwatch();
  // Number of re-analysis.
  int recompiles = 0;

  SimpleTypesInferrer(this.compiler);

  /**
   * Main entry point of the inferrer. Analyzes all elements that the
   * resolver found as reachable. Returns whether it succeeded.
   */
  bool analyzeMain(Element element) {
    // We use the given element as the sentinel. This is a temporary
    // situation as long as this inferrer is using [ClassElement] for
    // expressing types.
    giveUpType = element;
    buildWorkQueue();
    int analyzed = 0;
    compiler.progress.reset();
    do {
      if (compiler.progress.elapsedMilliseconds > 500) {
        compiler.log('Inferred $analyzed methods.');
        compiler.progress.reset();
      }
      element = workSet.remove();
      if (element.isErroneous()) continue;

      bool wasAnalyzed = analyzeCount.containsKey(element);
      if (wasAnalyzed) {
        recompiles++;
        recomputeWatch.start();
      }
      bool changed = analyze(element);
      analyzed++;
      if (wasAnalyzed) {
        recomputeWatch.stop();
      }
      if (!changed) continue;
      // If something changed during the analysis of [element],
      // put back callers of it in the work list.
      Set<Element> methodCallers = callersOf[element];
      if (methodCallers != null) {
        methodCallers.forEach(enqueueAgain);
      }
    } while (!workSet.isEmpty);
    dump();
    clear();
    return true;
  }

  /**
   * Query method after the analysis to know the type of [element].
   */
  getConcreteTypeOfElement(element) {
    return getTypeIfValuable(returnTypeOf[element]);
  }

  getTypeIfValuable(returnType) {
    if (returnType == null
        || returnType == compiler.dynamicClass
        || returnType == giveUpType) {
      return null;
    }
    return new ConcreteType.singleton(
        compiler.maxConcreteTypeSize, new ClassBaseType(returnType));
  }

  /**
   * Query method after the analysis to know the type of [node],
   * defined in the context of [owner].
   */
  getConcreteTypeOfNode(Element owner, Node node) {
    var elements = compiler.enqueuer.resolution.resolvedElements[owner];
    Selector selector = elements.getSelector(node);
    // TODO(ngeoffray): Should the builder call this method with a
    // SendSet?
    if (selector == null || selector.isSetter() || selector.isIndexSet()) {
      return null;
    }
    return getTypeIfValuable(returnTypeOfSelector(selector));
  }

  /**
   * Enqueues [e] in the work queue if it is valuable.
   */
  void enqueueAgain(Element e) {
    Element returnType = returnTypeOf[e];
    // If we have found a type for [e], no need to re-analyze it.
    if (returnType != compiler.dynamicClass) return;
    if (analyzeCount[e] > MAX_ANALYSIS_COUNT_PER_ELEMENT) return;
    workSet.add(e);
  }

  /**
   * Builds the initial work queue by adding all resolved elements in
   * the work queue, ordered by the number of selectors they use. This
   * order is benficial for the analysis of return types, but we may
   * have to refine it once we analyze parameter types too.
   */
  void buildWorkQueue() {
    int max = 0;
    Map<int, Set<Element>> methodSizes = new Map<int, Set<Element>>();
    compiler.enqueuer.resolution.resolvedElements.forEach(
      (Element element, TreeElementMapping mapping) {
        // TODO(ngeoffray): Not sure why the resolver would put a null
        // mapping.
        if (mapping == null) return;
        if (element.isAbstract(compiler)) return;
        int length = mapping.selectors.length;
        max = length > max ? length : max;
        Set<Element> set = methodSizes.putIfAbsent(
            length, () => new Set<Element>());
        set.add(element);
    });
    
    // This iteration assumes the [WorkSet] is LIFO.
    for (int i = max; i >= 0; i--) {
      Set<Element> set = methodSizes[i];
      if (set != null) {
        set.forEach((e) { workSet.add(e); });
      }
    }
  }

  dump() {
    int interestingTypes = 0;
    int giveUpTypes = 0;
    returnTypeOf.forEach((Element method, Element type) {
      if (type == giveUpType) {
        giveUpTypes++;
      } else if (type != compiler.nullClass && type != compiler.dynamicClass) {
        interestingTypes++;
      }
    });
    compiler.log('Type inferrer spent ${memberWatch.elapsedMilliseconds} ms '
                 'computing a call graph.');
    compiler.log('Type inferrer re-analyzed methods $recompiles times '
                 'in ${recomputeWatch.elapsedMilliseconds} ms.');
    compiler.log('Type inferrer found $interestingTypes interesting '
                 'return types and gave up on $giveUpTypes methods.');
  }

  /**
   * Clear data structures that are not used after the analysis.
   */
  void clear() {
    callersOf.clear();
    analyzeCount.clear();
  }

  bool analyze(Element element) {
    if (element.isField()) {
      // TODO(ngeoffray): Analyze its initializer.
      return false;
    } else {
      SimpleTypeInferrerVisitor visitor =
          new SimpleTypeInferrerVisitor(element, compiler, this);
      return visitor.run();
    }
  }

  /**
   * Records [returnType] as the return type of [analyzedElement].
   * Returns whether the new type is worth recompiling the callers of
   * [analyzedElement].
   */
  bool recordReturnType(analyzedElement, returnType) {
    assert(returnType != null);
    Element existing = returnTypeOf[analyzedElement];
    if (existing == null) {
      // First time we analyzed [analyzedElement]. Initialize the
      // return type.
      assert(!analyzeCount.containsKey(analyzedElement));
      returnTypeOf[analyzedElement] = returnType;
      // If the return type is useful, say it has changed.
      return returnType != compiler.dynamicClass
          && returnType != compiler.nullClass;
    } else if (existing == compiler.dynamicClass) {
      // Previous analysis did not find any type.
      returnTypeOf[analyzedElement] = returnType;
      // If the return type is useful, say it has changed.
      return returnType != compiler.dynamicClass
          && returnType != compiler.nullClass;
    } else if (existing == giveUpType) {
      // If we already gave up on the return type, we don't change it.
      return false;
    } else if (existing != returnType) {
      // The method is returning two different types. Give up for now.
      // TODO(ngeoffray): Compute LUB.
      returnTypeOf[analyzedElement] = giveUpType;
      return true;
    }
    return false;
  }

  /**
   * Returns the return type of [element]. Returns [:Dynamic:] if
   * [element] has not been analyzed yet.
   */
  ClassElement returnTypeOfElement(Element element) {
    element = element.implementation;
    if (element.isGenerativeConstructor()) return element.getEnclosingClass();
    Element returnType = returnTypeOf[element];
    if (returnType == null || returnType == giveUpType) {
      return compiler.dynamicClass;
    }
    return returnType;
  }

  /**
   * Returns the union of the return types of all elements that match
   * the called [selector].
   */
  ClassElement returnTypeOfSelector(Selector selector) {
    ClassElement result;
    iterateOverElements(selector, (Element element) {
      assert(element.isImplementation);
      Element cls;
      if (element.isFunction() && selector.isGetter()) {
        cls = compiler.functionClass;
      } else {
        cls = returnTypeOf[element];
      }
      if (cls == null
          || cls == compiler.dynamicClass
          || cls == giveUpType
          || (cls != result && result != null)) {
        result = compiler.dynamicClass;
        return false;
      } else {
        result = cls;
        return true;
      }
    });
    return result;
  }

  /**
   * Registers that [caller] calls [callee] with the given
   * [arguments].
   */
  void registerCalledElement(Element caller,
                             Element callee,
                             ArgumentsTypes arguments) {
    if (analyzeCount.containsKey(caller)) return;
    callee = callee.implementation;
    Set<FunctionElement> callers = callersOf.putIfAbsent(
        callee, () => new Set<FunctionElement>());
    callers.add(caller);
  }

  /**
   * Registers that [caller] accesses [callee] through a property
   * access.
   */
  void registerGetterOnElement(Element caller,
                               Element callee) {
    if (analyzeCount.containsKey(caller)) return;
    callee = callee.implementation;
    Set<FunctionElement> callers = callersOf.putIfAbsent(
        callee, () => new Set<FunctionElement>());
    callers.add(caller);
  }

  /**
   * Registers that [caller] calls an element matching [selector]
   * with the given [arguments].
   */
  void registerCalledSelector(Element caller,
                              Selector selector,
                              ArgumentsTypes arguments) {
    if (analyzeCount.containsKey(caller)) return;
    iterateOverElements(selector, (Element element) {
      assert(element.isImplementation);
      Set<FunctionElement> callers = callersOf.putIfAbsent(
          element, () => new Set<FunctionElement>());
      callers.add(caller);
      return true;
    });
  }

  /**
   * Registers that [caller] accesses an element matching [selector]
   * through a property access.
   */
  void registerGetterOnSelector(Element caller, Selector selector) {
    if (analyzeCount.containsKey(caller)) return;
    iterateOverElements(selector, (Element element) {
      assert(element.isImplementation);
      Set<FunctionElement> callers = callersOf.putIfAbsent(
          element, () => new Set<FunctionElement>());
      callers.add(caller);
      return true;
    });
  }

  /**
   * Registers that [caller] closurizes [function].
   */
  void registerGetFunction(Element caller, Element function) {
    assert(caller.isImplementation);
    if (analyzeCount.containsKey(caller)) return;
    // We don't register that [caller] calls [function] because we
    // don't know if the code is going to call it, and if it is, then
    // the inferrer has lost track of its identity anyway.
  }

  /**
   * Applies [f] to all elements in the universe that match
   * [selector]. If [f] returns false, aborts the iteration.
   */
  void iterateOverElements(Selector selector, bool f(Element element)) {
    SourceString name = selector.name;

    // The following is already computed by the resolver, but it does
    // not save it yet.
    Set<Element> methods = methodCache[name];
    if (methods == null) {
      memberWatch.start();
      methods = new Set<Element>();
      void add(element) {
        if (!element.isInstanceMember()) return;
        if (element.isAbstract(compiler)) return;
        if (!compiler.enqueuer.resolution.isProcessed(element)) return;
        methods.add(element.implementation);
      }
      for (ClassElement cls in compiler.enqueuer.resolution.seenClasses) {
        var element = cls.lookupLocalMember(name);
        if (element != null) {
          if (element.isAbstractField()) {
            if (element.getter != null) add(element.getter);
            if (element.setter != null) add(element.setter);
          } else {
            add(element);
          }
        }
      }
      methodCache[name] = methods;
      memberWatch.stop();
    }

    for (Element element in methods) {
      if (selector.appliesUnnamed(element, compiler)) {
        if (!f(element)) return;
      }
    }
  }
}

/**
 * Placeholder for inferred arguments types on sends.
 */
class ArgumentsTypes {
  final List<Element> positional;
  final Map<Identifier, Element> named;
  ArgumentsTypes(this.positional, this.named);
  int get length => positional.length + named.length;
  toString() => "{ positional = $positional, named = $named }";
}

class SimpleTypeInferrerVisitor extends ResolvedVisitor {
  final FunctionElement analyzedElement;
  final SimpleTypesInferrer inferrer;
  final Compiler compiler;
  Element returnType;

  SimpleTypeInferrerVisitor(FunctionElement element,
                            Compiler compiler,
                            this.inferrer)
    : super(compiler.enqueuer.resolution.resolvedElements[element.declaration]),
      analyzedElement = element,
      compiler = compiler {
    assert(elements != null);
  }

  bool run() {
    FunctionExpression node =
        analyzedElement.implementation.parseNode(compiler);
    bool changed;
    if (analyzedElement.isGenerativeConstructor()) {
      FunctionSignature signature = analyzedElement.computeSignature(compiler);
      // TODO(ngeoffray): handle initializing formals.
      // TODO(ngeoffray): handle initializers.
      node.body.accept(this);
      // We always know the return type of a generative constructor.
      changed = false;
    } else if (analyzedElement.isNative()) {
      // Native methods do not have a body, and we currently just say
      // they return dynamic.
      inferrer.recordReturnType(analyzedElement, compiler.dynamicClass);
      changed = false;
    } else {
      node.body.accept(this);
      if (returnType == null) {
        // No return in the body.
        returnType = compiler.nullClass;
      }
      changed = inferrer.recordReturnType(analyzedElement, returnType);
    }
    if (inferrer.analyzeCount.containsKey(analyzedElement)) {
      inferrer.analyzeCount[analyzedElement]++;
    } else {
      inferrer.analyzeCount[analyzedElement] = 1;
    }
    return changed;
  }

  recordReturnType(ClassElement cls) {
    if (returnType == null) {
      returnType = cls;
    } else if (returnType != inferrer.giveUpType
               && cls == compiler.dynamicClass) {
      returnType = cls;
    } else if (returnType == compiler.dynamicClass) {
      // Nothing to do. Stay dynamic.
    } else if (leastUpperBound(cls, returnType) == compiler.dynamicClass) {
      returnType = inferrer.giveUpType;
    }
  }

  visitNode(Node node) {
    node.visitChildren(this);
    return compiler.dynamicClass;
  }

  visitNewExpression(NewExpression node) {
    return node.send.accept(this);
  }

  visitFunctionExpression(FunctionExpression node) {
    // We don't put the closure in the work queue of the
    // inferrer, because it will share information with its enclosing
    // method, like for example the types of local variables.
    SimpleTypeInferrerVisitor visitor =
        new SimpleTypeInferrerVisitor(elements[node], compiler, inferrer);
    visitor.run();
    return compiler.functionClass;
  }

  visitLiteralString(LiteralString node) {
    return compiler.stringClass;
  }

  visitStringInterpolation(StringInterpolation node) {
    return compiler.stringClass;
  }

  visitStringJuxtaposition(StringJuxtaposition node) {
    return compiler.stringClass;
  }

  visitLiteralBool(LiteralBool node) {
    return compiler.boolClass;
  }

  visitLiteralDouble(LiteralDouble node) {
    return compiler.doubleClass;
  }

  visitLiteralInt(LiteralInt node) {
    return compiler.intClass;
  }

  visitLiteralList(LiteralList node) {
    return compiler.listClass;
  }

  visitLiteralMap(LiteralMap node) {
    return compiler.mapClass;
  }

  visitLiteralNull(LiteralNull node) {
    return compiler.nullClass;
  }

  visitTypeReferenceSend(Send node) {
    return compiler.typeClass;
  }

  visitSendSet(SendSet node) {
    // TODO(ngeoffray): return the right hand side's type.
    node.visitChildren(this);
    return compiler.dynamicClass;
  }

  visitIdentifier(Identifier node) {
    if (node.isThis() || node.isSuper()) {
      // TODO(ngeoffray): Represent subclasses.
      return compiler.dynamicClass;
    }
    return compiler.dynamicClass;
  }

  visitSuperSend(Send node) {
    Element element = elements[node];
    if (Elements.isUnresolved(element)) {
      return compiler.dynamicClass;
    }
    Selector selector = elements.getSelector(node);
    if (node.isPropertyAccess) {
      inferrer.registerGetterOnElement(analyzedElement, element);
      return inferrer.returnTypeOfElement(element);
    } else if (element.isFunction()) {
      ArgumentsTypes arguments = analyzeArguments(node.arguments);
      inferrer.registerCalledElement(analyzedElement, element, arguments);
      return inferrer.returnTypeOfElement(element);
    } else {
      // Closure call on a getter. We don't have function types yet,
      // so we just return [:Dynamic:].
      return compiler.dynamicClass;
    }
  }

  visitStaticSend(Send node) {
    Element element = elements[node];
    if (Elements.isUnresolved(element)) {
      return compiler.dynamicClass;
    }
    if (element.isForeign(compiler)) {
      return handleForeignSend(node);
    }
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    inferrer.registerCalledElement(analyzedElement, element, arguments);
    return inferrer.returnTypeOfElement(element);
  }

  handleForeignSend(Send node) {
    node.visitChildren(this);
    Selector selector = elements.getSelector(node);
    SourceString name = selector.name;
    if (name == const SourceString('JS')) {
      native.NativeBehavior nativeBehavior =
          compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);
      if (nativeBehavior.typesInstantiated.isEmpty) {
        return compiler.dynamicClass;
      }
      ClassElement returnType;
      for (var type in nativeBehavior.typesReturned) {
        ClassElement mappedType;
        if (type == native.SpecialType.JsObject) {
          mappedType = compiler.objectClass;
        } else if (type == native.SpecialType.JsArray) {
          mappedType = compiler.listClass;
        } else {
          mappedType = type.element;
          // For primitive types, we know how to handle them here and
          // in the backend.
          if (mappedType != compiler.stringClass
              && mappedType != compiler.intClass
              && mappedType != compiler.doubleClass
              && mappedType != compiler.boolClass
              && mappedType != compiler.numClass) {
            Set<ClassElement> subtypes = compiler.world.subtypes[mappedType];
            // TODO(ngeoffray): Handle subtypes and subclasses.
            if (subtypes != null && !subtypes.isEmpty) {
              return compiler.dynamicClass;
            }
          }
        }
        if (returnType == null) {
          returnType = mappedType;
        } else {
          return compiler.dynamicClass;
        }
      }
      return returnType;
    } else if (name == const SourceString('JS_OPERATOR_IS_PREFIX')) {
      return compiler.stringClass;
    } else {
      return compiler.dynamicClass;
    }
  }

  analyzeArguments(Link<Node> arguments) {
    List<ClassElement> positional = [];
    Map<Identifier, ClassElement> named = new Map<Identifier, ClassElement>();
    for (Node argument in arguments) {
      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        named[namedArgument.name] = namedArgument.expression.accept(this);
      } else {
        positional.add(argument.accept(this));
      }
    }
    return new ArgumentsTypes(positional, named);
  }

  visitOperatorSend(Send node) {
    Operator op = node.selector;
    if (const SourceString("[]") == op.source) {
      return visitDynamicSend(node);
    } else if (const SourceString("&&") == op.source ||
               const SourceString("||") == op.source) {
      node.visitChildren(this);
      return compiler.boolClass;
    } else if (const SourceString("!") == op.source) {
      node.visitChildren(this);
      return compiler.boolClass;
    } else if (const SourceString("is") == op.source) {
      node.visitChildren(this);
      return compiler.boolClass;
    } else if (const SourceString("as") == op.source) {
      node.visitChildren(this);
      return compiler.dynamicClass;
    } else if (node.isParameterCheck) {
      node.visitChildren(this);
      return compiler.boolClass;
    } else if (node.argumentsNode is Prefix) {
      // Unary operator.
      return visitDynamicSend(node);
    } else if (const SourceString('===') == op.source
               || const SourceString('!==') == op.source) {
      node.visitChildren(this);
      return compiler.boolClass;
    } else {
      // Binary operator.
      return visitDynamicSend(node);
    }
  }

  // Because some nodes just visit their children, we may end up
  // visiting a type annotation, that may contain a send in case of a
  // prefixed type. Therefore we explicitly visit the type annotation
  // to avoid confusing the [ResolvedVisitor].
  visitTypeAnnotation(TypeAnnotation node) {}

  visitGetterSend(Send node) {
    Element element = elements[node];
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.isGetter()) {
        inferrer.registerGetterOnElement(analyzedElement, element);
        return inferrer.returnTypeOfElement(element);
      } else {
        // Nothing yet.
        // TODO: Analyze initializer of element.
        return compiler.dynamicClass;
      }
    } else if (Elements.isInstanceSend(node, elements)) {
      ClassElement receiverType;
      if (node.receiver == null) {
        receiverType = analyzedElement.getEnclosingClass();
      } else {
        receiverType = node.receiver.accept(this);
      }
      Selector selector = elements.getSelector(node);
      inferrer.registerGetterOnSelector(analyzedElement, selector);
      return inferrer.returnTypeOfSelector(selector);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      inferrer.registerGetFunction(analyzedElement, element);
      return compiler.functionClass;
    } else {
      // TODO: Analyze variable.
      return compiler.dynamicClass;
    }
  }

  visitClosureSend(Send node) {
    node.visitChildren(this);
    return compiler.dynamicClass;
  }

  visitDynamicSend(Send node) {
    ClassElement receiverType;
    if (node.receiver == null) {
      receiverType = analyzedElement.getEnclosingClass();
    } else {
      receiverType = node.receiver.accept(this);
    }
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    inferrer.registerCalledSelector(analyzedElement, selector, arguments);
    return inferrer.returnTypeOfSelector(selector);
  }

  visitReturn(Return node) {
    Node expression = node.expression;
    recordReturnType(expression == null
        ? compiler.nullClass
        : expression.accept(this));
  }

  visitConditional(Conditional node) {
    node.condition.accept(this);
    Element firstType = node.thenExpression.accept(this);
    Element secondType = node.elseExpression.accept(this);
    return leastUpperBound(firstType, secondType);
  }

  leastUpperBound(Element firstType, Element secondType) {
    if (firstType == secondType) return firstType;
    return compiler.dynamicClass;
  }

  internalError(String reason, {Node node}) {
    compiler.internalError(reason, node: node);
  }
}
