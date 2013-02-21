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

/**
 * Placeholder for type information of final fields of classes.
 */
class ClassInfoForFinalFields {
  /**
   * Maps a final field to a map from generative constructor to the
   * inferred type of the field in that generative constructor.
   */
  final Map<Element, Map<Element, Element>> typesOfFinalFields =
      new Map<Element, Map<Element, Element>>();

  /**
   * The number of generative constructors that need to be visited
   * before we can take any decision on the type of the fields.
   * Given that all generative constructors must be analyzed before
   * re-analyzing one, we know that once [constructorsToVisitCount]
   * reaches to 0, all generative constructors have been analyzed.
   */
  int constructorsToVisitCount;

  ClassInfoForFinalFields(this.constructorsToVisitCount);

  /**
   * Records that the generative [constructor] has inferred [type]
   * for the final [field].
   */
  void recordFinalFieldType(Element constructor, Element field, Element type) {
    Map<Element, Element> typesFor = typesOfFinalFields.putIfAbsent(
        field, () => new Map<Element, Element>());
    typesFor[constructor] = type;
  }

  /**
   * Records that [constructor] has been analyzed. If not at 0,
   * decrement [constructorsToVisitCount].
   */ 
  void doneAnalyzingGenerativeConstructor(Element constructor) {
    if (constructorsToVisitCount != 0) constructorsToVisitCount--;
  }

  /**
   * Returns whether all generative constructors of the class have
   * been analyzed.
   */
  bool get isDone => constructorsToVisitCount == 0;
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
   * Maps an element to the number of times this type inferrer
   * analyzed it.
   */
  final Map<Element, int> analyzeCount = new Map<Element, int>();

  /**
   * Maps a class to a [ClassInfoForFinalFields] to help collect type
   * information of final fields.
   */
  final Map<ClassElement, ClassInfoForFinalFields> classInfoForFinalFields =
      new Map<ClassElement, ClassInfoForFinalFields>();

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
    // TODO(ngeoffray): Not sure why the resolver would put a null
    // mapping.
    if (elements == null) return null;
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

    // Build the [classInfoForFinalFields] map by iterating over all
    // seen classes and counting the number of their generative
    // constructors.
    // We iterate over the seen classes and not the instantiated ones,
    // because we also need to analyze the final fields of super
    // classes that are not instantiated.
    compiler.enqueuer.resolution.seenClasses.forEach((ClassElement cls) {
      int constructorCount = 0;
      cls.forEachMember((_, member) {
        if (member.isGenerativeConstructor()) constructorCount++;
      });
      classInfoForFinalFields[cls.implementation] =
          new ClassInfoForFinalFields(constructorCount);
    });
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
    classInfoForFinalFields.clear();
  }

  bool analyze(Element element) {
    SimpleTypeInferrerVisitor visitor =
        new SimpleTypeInferrerVisitor(element, compiler, this);
    Element returnType = visitor.run();
    if (analyzeCount.containsKey(element)) {
      analyzeCount[element]++;
    } else {
      analyzeCount[element] = 1;
    }
    if (element.isGenerativeConstructor()) {
      // We always know the return type of a generative constructor.
      return false;
    } else if (element.isField()) {
      if (element.modifiers.isFinal() || element.modifiers.isConst()) {
        if (element.parseNode(compiler).asSendSet() != null) {
          // If [element] is final and has an initializer, we record
          // the inferred type.
          return recordReturnType(element, returnType);
        }
      }
      // We don't record anything for non-final fields.
      return false;
    } else {
      return recordReturnType(element, returnType);
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
    Element newType = existing == compiler.dynamicClass
        ? returnType // Previous analysis did not find any type.
        : computeLUB(existing, returnType);
    returnTypeOf[analyzedElement] = newType;
    // If the return type is useful, say it has changed.
    return existing != newType
        && newType != compiler.dynamicClass
        && newType != compiler.nullClass;
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
    assert(returnType != null);
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
    if (result == null) {
      result = compiler.dynamicClass;
    }
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
    Set<Element> callers = callersOf.putIfAbsent(
        callee, () => new Set<Element>());
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
    Set<Element> callers = callersOf.putIfAbsent(
        callee, () => new Set<Element>());
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
      Set<Element> callers = callersOf.putIfAbsent(
          element, () => new Set<Element>());
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
      Set<Element> callers = callersOf.putIfAbsent(
          element, () => new Set<Element>());
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
    Iterable<Element> elements = compiler.world.allFunctions.filter(selector);
    for (Element e in elements) {
      if (!f(e.implementation)) return;
    }
  }

  /**
   * Records in [classInfoForFinalFields] that [constructor] has
   * inferred [type] for the final [field].
   */
  void recordFinalFieldType(Element constructor, Element field, Element type) {
    // If the field is being set at its declaration site, it is not
    // being tracked in the [classInfoForFinalFields] map.
    if (constructor == field) return;
    assert(field.modifiers.isFinal() || field.modifiers.isConst());
    ClassElement cls = constructor.getEnclosingClass();
    ClassInfoForFinalFields info = classInfoForFinalFields[cls.implementation];
    info.recordFinalFieldType(constructor, field, type);
  }

  /**
   * Records that we are done analyzing [constructor]. If all
   * generative constructors of its enclosing class have already been
   * analyzed, this method updates the types of final fields.
   */
  void doneAnalyzingGenerativeConstructor(Element constructor) {
    ClassElement cls = constructor.getEnclosingClass();
    ClassInfoForFinalFields info = classInfoForFinalFields[cls.implementation];
    info.doneAnalyzingGenerativeConstructor(constructor);
    if (info.isDone) {
      updateFieldTypes(info);
    }
  }

  /**
   * Updates types of final fields listed in [info].
   */
  void updateFieldTypes(ClassInfoForFinalFields info) {
    assert(info.isDone);
    info.typesOfFinalFields.forEach((Element field,
                                     Map<Element, Element> types) {
      assert(field.modifiers.isFinal());
      Element fieldType;
      types.forEach((_, type) {
        fieldType = computeLUB(fieldType, type);
      });
      returnTypeOf[field] = fieldType;
    });
  }

  /**
   * Returns the least upper bound between [firstType] and
   * [secondType].
   */
  Element computeLUB(Element firstType, Element secondType) {
    assert(secondType != null);
    if (firstType == null) {
      return secondType;
    } else if (firstType == giveUpType) {
      return firstType;
    } else if (secondType == compiler.dynamicClass) {
      return secondType;
    } else if (firstType == compiler.dynamicClass) {
      return firstType;
    } else if (firstType != secondType) {
      // TODO(ngeoffray): Actually compute the least upper bound.
      return giveUpType;
    } else {
      assert(firstType == secondType);
      return firstType;
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
  final Element analyzedElement;
  final SimpleTypesInferrer inferrer;
  final Compiler compiler;
  Element returnType;

  SimpleTypeInferrerVisitor(Element element,
                            Compiler compiler,
                            this.inferrer)
    : super(compiler.enqueuer.resolution.resolvedElements[element.declaration]),
      analyzedElement = element,
      compiler = compiler {
    assert(elements != null);
  }

  Element run() {
    var node = analyzedElement.implementation.parseNode(compiler);
    if (analyzedElement.isField()) {
      returnType = visit(node);
    } else if (analyzedElement.isGenerativeConstructor()) {
      FunctionElement function = analyzedElement;
      FunctionSignature signature = function.computeSignature(compiler);
      signature.forEachParameter((element) {
        if (element.kind == ElementKind.FIELD_PARAMETER
            && element.modifiers.isFinal()) {
          // We don't track argument types yet, so just set the field
          // as dynamic.
          inferrer.recordFinalFieldType(
              analyzedElement, element.fieldElement, compiler.dynamicClass);
        }
      });
      visit(node.initializers);
      visit(node.body);
      inferrer.doneAnalyzingGenerativeConstructor(analyzedElement);
      returnType = analyzedElement.getEnclosingClass();
    } else if (analyzedElement.isNative()) {
      // Native methods do not have a body, and we currently just say
      // they return dynamic.
      returnType = compiler.dynamicClass;
    } else {
      visit(node.body);
      if (returnType == null) {
        // No return in the body.
        returnType = compiler.nullClass;
      }
    }
    return returnType;
  }

  recordReturnType(ClassElement cls) {
    returnType = inferrer.computeLUB(returnType, cls);
  }

  visitNode(Node node) {
    node.visitChildren(this);
    return compiler.dynamicClass;
  }

  visitNewExpression(NewExpression node) {
    return node.send.accept(this);
  }

  visit(Node node) {
    return node == null ? compiler.dynamicClass : node.accept(this);
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
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType()) {
      node.visitChildren(this);
      return compiler.dynamicClass;
    }

    Operator op = node.assignmentOperator;
    if (node.isSuperCall) {
      // [: super.foo = 42 :] or [: super.foo++ :] or [: super.foo += 1 :].
      node.visitChildren(this);
      return compiler.dynamicClass;
    } else if (node.isIndex) {
      if (const SourceString("=") == op.source) {
        // [: foo[0] = 42 :]
        visit(node.receiver);
        Element returnType;
        for (Node argument in node.arguments) {
          returnType = argument.accept(this);
        }
        return returnType;
      } else {
        // [: foo[0] += 42 :] or [: foo[0]++ :].
        node.visitChildren(this);
        return compiler.dynamicClass;
      }
    } else if (const SourceString("=") == op.source) {
      // [: foo = 42 :]
      visit(node.receiver);
      Link<Node> link = node.arguments;
      assert(!link.isEmpty && link.tail.isEmpty);
      Element type = link.head.accept(this);

      if (!Elements.isUnresolved(element)
          && element.isField()
          && element.modifiers.isFinal()) {
        inferrer.recordFinalFieldType(analyzedElement, element, type);
      }
      return type;
    } else {
      // [: foo++ :] or [: foo += 1 :].
      assert(const SourceString("++") == op.source ||
             const SourceString("--") == op.source ||
             node.assignmentOperator.source.stringValue.endsWith("="));
      node.visitChildren(this);
      return compiler.dynamicClass;
    }
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
      if (nativeBehavior == null) return compiler.dynamicClass;
      List typesReturned = nativeBehavior.typesReturned;
      if (typesReturned.isEmpty) return compiler.dynamicClass;
      ClassElement returnType;
      for (var type in typesReturned) {
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
      inferrer.registerGetterOnElement(analyzedElement, element);
      return inferrer.returnTypeOfElement(element);
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
    Element type = inferrer.computeLUB(firstType, secondType);
    if (type == inferrer.giveUpType) type = compiler.dynamicClass;
    return type;
  }

  internalError(String reason, {Node node}) {
    compiler.internalError(reason, node: node);
  }
}
