// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library closureToClassMapper;

import "elements/elements.dart";
import "dart2jslib.dart";
import "dart_types.dart";
import "scanner/scannerlib.dart" show Token;
import "tree/tree.dart";
import "util/util.dart";
import "elements/modelx.dart" show ElementX, SynthesizedCallMethodElementX,
    ClassElementX;
import "elements/visitor.dart" show ElementVisitor;

class ClosureNamer {
  String getClosureVariableName(String name, int id) {
    return "${name}_$id";
  }
}

class ClosureTask extends CompilerTask {
  Map<Node, ClosureClassMap> closureMappingCache;
  ClosureNamer namer;
  ClosureTask(Compiler compiler, this.namer)
      : closureMappingCache = new Map<Node, ClosureClassMap>(),
        super(compiler);

  String get name => "Closure Simplifier";

  ClosureClassMap computeClosureToClassMapping(Element element,
                                               Node node,
                                               TreeElements elements) {
    return measure(() {
      ClosureClassMap cached = closureMappingCache[node];
      if (cached != null) return cached;

      ClosureTranslator translator =
          new ClosureTranslator(compiler, elements, closureMappingCache, namer);

      // The translator will store the computed closure-mappings inside the
      // cache. One for given node and one for each nested closure.
      if (node is FunctionExpression) {
        translator.translateFunction(element, node);
      } else if (element.isSynthesized) {
        return new ClosureClassMap(null, null, null,
            new ThisElement(element, compiler.types.dynamicType));
      } else {
        assert(element.isField());
        VariableElement field = element;
        if (field.initializer != null) {
          // The lazy initializer of a static.
          translator.translateLazyInitializer(element, node, field.initializer);
        } else {
          assert(element.isInstanceMember());
          closureMappingCache[node] =
              new ClosureClassMap(null, null, null,
                  new ThisElement(element, compiler.types.dynamicType));
        }
      }
      assert(closureMappingCache[node] != null);
      return closureMappingCache[node];
    });
  }

  ClosureClassMap getMappingForNestedFunction(FunctionExpression node) {
    return measure(() {
      ClosureClassMap nestedClosureData = closureMappingCache[node];
      if (nestedClosureData == null) {
        compiler.internalError(node, "No closure cache.");
      }
      return nestedClosureData;
    });
  }
}

// TODO(ahe): These classes continuously cause problems.  We need to
// move these classes to elements/modelx.dart or see if we can find a
// more general solution.
class ClosureFieldElement extends ElementX implements VariableElement {
  /// The source variable this element refers to.
  final TypedElement variableElement;

  ClosureFieldElement(String name,
                      this.variableElement,
                      ClassElement enclosing)
      : super(name, ElementKind.FIELD, enclosing);

  Expression get initializer {
    throw new SpannableAssertionFailure(
        variableElement,
        'Should not access initializer of ClosureFieldElement.');
  }

  bool isInstanceMember() => true;
  bool isAssignable() => false;

  DartType computeType(Compiler compiler) {
    return variableElement.type;
  }

  DartType get type => variableElement.type;

  String toString() => "ClosureFieldElement($name)";

  accept(ElementVisitor visitor) => visitor.visitClosureFieldElement(this);
}

// TODO(ahe): These classes continuously cause problems.  We need to
// move these classes to elements/modelx.dart or see if we can find a
// more general solution.
class ClosureClassElement extends ClassElementX {
  DartType rawType;
  DartType thisType;
  FunctionType callType;
  /// Node that corresponds to this closure, used for source position.
  final FunctionExpression node;

  ClosureClassElement(this.node,
                      String name,
                      Compiler compiler,
                      this.methodElement,
                      Element enclosingElement)
      : super(name,
              enclosingElement,
              // By assigning a fresh class-id we make sure that the hashcode
              // is unique, but also emit closure classes after all other
              // classes (since the emitter sorts classes by their id).
              compiler.getNextFreeClassId(),
              STATE_DONE) {
    ClassElement superclass = methodElement.isInstanceMember()
        ? compiler.boundClosureClass
        : compiler.closureClass;
    superclass.ensureResolved(compiler);
    supertype = superclass.thisType;
    interfaces = const Link<DartType>();
    thisType = rawType = new InterfaceType(this);
    allSupertypesAndSelf =
        superclass.allSupertypesAndSelf.extendClass(thisType);
    callType = methodElement.type;
  }

  bool isClosure() => true;

  Token position() => node.getBeginToken();

  Node parseNode(DiagnosticListener listener) => node;

  /**
   * The element for the declaration of the function expression.
   */
  final TypedElement methodElement;

  // A [ClosureClassElement] is nested inside a function or initializer in terms
  // of [enclosingElement], but still has to be treated as a top-level
  // element.
  bool isTopLevel() => true;

  get enclosingElement => methodElement;

  accept(ElementVisitor visitor) => visitor.visitClosureClassElement(this);
}

// TODO(ahe): These classes continuously cause problems.  We need to
// move these classes to elements/modelx.dart or see if we can find a
// more general solution.
class BoxElement extends ElementX implements TypedElement {
  final DartType type;

  BoxElement(String name, Element enclosingElement, this.type)
      : super(name, ElementKind.VARIABLE_LIST, enclosingElement);

  DartType computeType(Compiler compiler) => type;

  accept(ElementVisitor visitor) => visitor.visitBoxElement(this);
}

// TODO(ngeoffray, ahe): These classes continuously cause problems.  We need to
// move these classes to elements/modelx.dart or see if we can find a
// more general solution.
class BoxFieldElement extends ElementX implements TypedElement {
  BoxFieldElement(String name,
                  this.variableElement,
                  BoxElement enclosingBox)
      : super(name, ElementKind.FIELD, enclosingBox);

  DartType computeType(Compiler compiler) => type;

  DartType get type => variableElement.type;

  final VariableElement variableElement;

  accept(ElementVisitor visitor) => visitor.visitBoxFieldElement(this);
}

// TODO(ahe): These classes continuously cause problems.  We need to
// move these classes to elements/modelx.dart or see if we can find a
// more general solution.
class ThisElement extends ElementX implements TypedElement {
  final DartType type;

  ThisElement(Element enclosing, this.type)
      : super('this', ElementKind.PARAMETER, enclosing);

  bool isAssignable() => false;

  DartType computeType(Compiler compiler) => compiler.types.dynamicType;

  // Since there is no declaration corresponding to 'this', use the position of
  // the enclosing method.
  Token position() => enclosingElement.position();

  accept(ElementVisitor visitor) => visitor.visitThisElement(this);
}

// The box-element for a scope, and the captured variables that need to be
// stored in the box.
class ClosureScope {
  Element boxElement;
  Map<Element, Element> capturedVariableMapping;
  // If the scope is attached to a [For] contains the variables that are
  // declared in the initializer of the [For] and that need to be boxed.
  // Otherwise contains the empty List.
  List<Element> boxedLoopVariables;

  ClosureScope(this.boxElement, this.capturedVariableMapping)
      : boxedLoopVariables = const <Element>[];

  bool hasBoxedLoopVariables() => !boxedLoopVariables.isEmpty;
}

class ClosureClassMap {
  // The closure's element before any translation. Will be null for methods.
  final Element closureElement;
  // The closureClassElement will be null for methods that are not local
  // closures.
  final ClassElement closureClassElement;
  // The callElement will be null for methods that are not local closures.
  final FunctionElement callElement;
  // The [thisElement] makes handling 'this' easier by treating it like any
  // other argument. It is only set for instance-members.
  final ThisElement thisElement;

  // Maps free locals, arguments and function elements to their captured
  // copies.
  final Map<Element, Element> freeVariableMapping;
  // Maps closure-fields to their captured elements. This is somehow the inverse
  // mapping of [freeVariableMapping], but whereas [freeVariableMapping] does
  // not deal with boxes, here we map instance-fields (which might represent
  // boxes) to their boxElement.
  final Map<Element, Element> capturedFieldMapping;

  // Maps scopes ([Loop] and [FunctionExpression] nodes) to their
  // [ClosureScope] which contains their box and the
  // captured variables that are stored in the box.
  // This map will be empty if the method/closure of this [ClosureData] does not
  // contain any nested closure.
  final Map<Node, ClosureScope> capturingScopes;

  final Set<Element> usedVariablesInTry;

  ClosureClassMap(this.closureElement,
                  this.closureClassElement,
                  this.callElement,
                  this.thisElement)
      : this.freeVariableMapping = new Map<Element, Element>(),
        this.capturedFieldMapping = new Map<Element, Element>(),
        this.capturingScopes = new Map<Node, ClosureScope>(),
        this.usedVariablesInTry = new Set<Element>();

  bool isClosure() => closureElement != null;

  bool capturingScopesBox(Element element) {
    return capturingScopes.values.any((scope) {
      return scope.boxedLoopVariables.contains(element);
    });
  }

  bool isVariableBoxed(Element element) {
    Element copy = freeVariableMapping[element];
    if (copy != null && !copy.isMember()) return true;
    return capturingScopesBox(element);
  }

  void forEachCapturedVariable(void f(Element local, Element field)) {
    freeVariableMapping.forEach((variable, copy) {
      if (variable is BoxElement) return;
      f(variable, copy);
    });
    capturingScopes.values.forEach((scope) {
      scope.capturedVariableMapping.forEach(f);
    });
  }

  void forEachBoxedVariable(void f(Element local, Element field)) {
    freeVariableMapping.forEach((variable, copy) {
      if (!isVariableBoxed(variable)) return;
      f(variable, copy);
    });
    capturingScopes.values.forEach((scope) {
      scope.capturedVariableMapping.forEach(f);
    });
  }
}

class ClosureTranslator extends Visitor {
  final Compiler compiler;
  final TreeElements elements;
  int closureFieldCounter = 0;
  int boxedFieldCounter = 0;
  bool inTryStatement = false;
  final Map<Node, ClosureClassMap> closureMappingCache;

  // Map of captured variables. Initially they will map to themselves. If
  // a variable needs to be boxed then the scope declaring the variable
  // will update this mapping.
  Map<Element, Element> capturedVariableMapping;
  // List of encountered closures.
  List<Expression> closures;

  // The variables that have been declared in the current scope.
  List<Element> scopeVariables;

  // Keep track of the mutated variables so that we don't need to box
  // non-mutated variables.
  Set<Element> mutatedVariables;

  Element outermostElement;
  Element currentElement;

  // The closureData of the currentFunctionElement.
  ClosureClassMap closureData;

  ClosureNamer namer;

  bool insideClosure = false;

  ClosureTranslator(this.compiler, this.elements, this.closureMappingCache,
                    this.namer)
      : capturedVariableMapping = new Map<Element, Element>(),
        closures = <Expression>[],
        mutatedVariables = new Set<Element>();

  void translateFunction(Element element, FunctionExpression node) {
    // For constructors the [element] and the [:elements[node]:] may differ.
    // The [:elements[node]:] always points to the generative-constructor
    // element, whereas the [element] might be the constructor-body element.
    visit(node);  // [visitFunctionExpression] will call [visitInvokable].
    // When variables need to be boxed their [capturedVariableMapping] is
    // updated, but we delay updating the similar freeVariableMapping in the
    // closure datas that capture these variables.
    // The closures don't have their fields (in the closure class) set, either.
    updateClosures();
  }

  void translateLazyInitializer(VariableElement element,
                                VariableDefinitions node,
                                Expression initializer) {
    visitInvokable(element, node, () { visit(initializer); });
    updateClosures();
  }

  // This function runs through all of the existing closures and updates their
  // free variables to the boxed value. It also adds the field-elements to the
  // class representing the closure. At the same time it fills the
  // [capturedFieldMapping].
  void updateClosures() {
    for (Expression closure in closures) {
      // The captured variables that need to be stored in a field of the closure
      // class.
      Set<Element> fieldCaptures = new Set<Element>();
      Set<Element> boxes = new Set<Element>();
      ClosureClassMap data = closureMappingCache[closure];
      Map<Element, Element> freeVariableMapping = data.freeVariableMapping;
      // We get a copy of the keys and iterate over it, to avoid modifications
      // to the map while iterating over it.
      freeVariableMapping.keys.toList().forEach((Element fromElement) {
        assert(fromElement == freeVariableMapping[fromElement]);
        Element updatedElement = capturedVariableMapping[fromElement];
        assert(updatedElement != null);
        if (fromElement == updatedElement) {
          assert(freeVariableMapping[fromElement] == updatedElement);
          assert(Elements.isLocal(updatedElement)
                 || updatedElement.isTypeVariable());
          // The variable has not been boxed.
          fieldCaptures.add(updatedElement);
        } else {
          // A boxed element.
          freeVariableMapping[fromElement] = updatedElement;
          Element boxElement = updatedElement.enclosingElement;
          assert(boxElement is BoxElement);
          boxes.add(boxElement);
        }
      });
      ClassElement closureElement = data.closureClassElement;
      assert(closureElement != null ||
             (fieldCaptures.isEmpty && boxes.isEmpty));
      void addElement(Element element, String name) {
        Element fieldElement = new ClosureFieldElement(
            name, element, closureElement);
        closureElement.addMember(fieldElement, compiler);
        data.capturedFieldMapping[fieldElement] = element;
        freeVariableMapping[element] = fieldElement;
      }
      // Add the box elements first so we get the same ordering.
      // TODO(sra): What is the canonical order of multiple boxes?
      for (Element capturedElement in boxes) {
        addElement(capturedElement, capturedElement.name);
      }
      for (Element capturedElement in
               Elements.sortedByPosition(fieldCaptures)) {
        int id = closureFieldCounter++;
        String name = namer.getClosureVariableName(capturedElement.name, id);
        addElement(capturedElement, name);
      }
      closureElement.reverseBackendMembers();
    }
  }

  void useLocal(Element element) {
    // If the element is not declared in the current function and the element
    // is not the closure itself we need to mark the element as free variable.
    // Note that the check on [insideClosure] is not just an
    // optimization: factories have type parameters as function
    // parameters, and type parameters are declared in the class, not
    // the factory.
    if (insideClosure &&
        element.enclosingElement != currentElement &&
        element != currentElement) {
      assert(closureData.freeVariableMapping[element] == null ||
             closureData.freeVariableMapping[element] == element);
      closureData.freeVariableMapping[element] = element;
    } else if (inTryStatement) {
      // Don't mark the this-element. This would complicate things in the
      // builder.
      if (element != closureData.thisElement) {
        // TODO(ngeoffray): only do this if the variable is mutated.
        closureData.usedVariablesInTry.add(element);
      }
    }
  }

  void declareLocal(Element element) {
    scopeVariables.add(element);
  }

  void registerNeedsThis() {
    if (closureData.thisElement != null) {
      useLocal(closureData.thisElement);
    }
  }

  visit(Node node) => node.accept(this);

  visitNode(Node node) => node.visitChildren(this);

  visitVariableDefinitions(VariableDefinitions node) {
    if (node.type != null) {
      visit(node.type);
    }
    for (Link<Node> link = node.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      VariableElement element = elements[definition];
      assert(element != null);
      declareLocal(element);
      // We still need to visit the right-hand sides of the init-assignments.
      // For SendSets don't visit the left again. Otherwise it would be marked
      // as mutated.
      if (definition is Send) {
        Send assignment = definition;
        Node arguments = assignment.argumentsNode;
        if (arguments != null) {
          visit(arguments);
        }
      } else {
        visit(definition);
      }
    }
  }

  visitTypeAnnotation(TypeAnnotation node) {
    Element member = currentElement.getEnclosingMember();
    DartType type = elements.getType(node);
    // TODO(karlklose,johnniwinther): if the type is null, the annotation is
    // from a parameter which has been analyzed before the method has been
    // resolved and the result has been thrown away.
    if (compiler.enableTypeAssertions && type != null &&
        type.containsTypeVariables) {
      if (insideClosure && member.isFactoryConstructor()) {
        // This is a closure in a factory constructor.  Since there is no
        // [:this:], we have to mark the type arguments as free variables to
        // capture them in the closure.
        type.forEachTypeVariable((variable) => useLocal(variable.element));
      }
      if (member.isInstanceMember() && !member.isField()) {
        // In checked mode, using a type variable in a type annotation may lead
        // to a runtime type check that needs to access the type argument and
        // therefore the closure needs a this-element, if it is not in a field
        // initializer; field initatializers are evaluated in a context where
        // the type arguments are available in locals.
        registerNeedsThis();
      }
    }
  }

  visitIdentifier(Identifier node) {
    if (node.isThis()) {
      registerNeedsThis();
    } else {
      Element element = elements[node];
      if (element != null && element.kind == ElementKind.TYPE_VARIABLE) {
        if (outermostElement.isConstructor()) {
          useLocal(element);
        } else {
          registerNeedsThis();
        }
      }
    }
    node.visitChildren(this);
  }

  visitSend(Send node) {
    Element element = elements[node];
    if (Elements.isLocal(element)) {
      useLocal(element);
    } else if (element != null && element.isTypeVariable()) {
      TypeVariableElement variable = element;
      analyzeType(variable.type);
    } else if (node.receiver == null &&
               Elements.isInstanceSend(node, elements)) {
      registerNeedsThis();
    } else if (node.isSuperCall) {
      registerNeedsThis();
    } else if (node.isTypeTest || node.isTypeCast) {
      TypeAnnotation annotation = node.typeAnnotationFromIsCheckOrCast;
      DartType type = elements.getType(annotation);
      analyzeType(type);
    } else if (node.isTypeTest) {
      DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
      analyzeType(type);
    } else if (node.isTypeCast) {
      DartType type = elements.getType(node.arguments.head);
      analyzeType(type);
    } else if (element == compiler.assertMethod
               && !compiler.enableUserAssertions) {
      return;
    }
    node.visitChildren(this);
  }

  visitSendSet(SendSet node) {
    Element element = elements[node];
    if (Elements.isLocal(element)) {
      mutatedVariables.add(element);
      if (compiler.enableTypeAssertions) {
        TypedElement typedElement = element;
        analyzeTypeVariables(typedElement.type);
      }
    }
    super.visitSendSet(node);
  }

  visitNewExpression(NewExpression node) {
    DartType type = elements.getType(node);
    analyzeType(type);
    node.visitChildren(this);
  }

  void analyzeTypeVariables(DartType type) {
    type.forEachTypeVariable((TypeVariableType typeVariable) {
      // Field initializers are inlined and access the type variable as
      // normal parameters.
      if (!outermostElement.isField() &&
          !outermostElement.isConstructor()) {
        registerNeedsThis();
      } else {
        useLocal(typeVariable.element);
      }
    });
  }

  void analyzeType(DartType type) {
    // TODO(johnniwinther): Find out why this can be null.
    if (type == null) return;
    if (outermostElement.isMember() &&
        compiler.backend.classNeedsRti(outermostElement.getEnclosingClass())) {
      if (outermostElement.isConstructor() ||
          outermostElement.isField()) {
        analyzeTypeVariables(type);
      } else if (outermostElement.isInstanceMember()) {
        if (type.containsTypeVariables) {
          registerNeedsThis();
        }
      }
    }
  }

  // If variables that are declared in the [node] scope are captured and need
  // to be boxed create a box-element and update the [capturingScopes] in the
  // current [closureData].
  // The boxed variables are updated in the [capturedVariableMapping].
  void attachCapturedScopeVariables(Node node) {
    Element box = null;
    Map<Element, Element> scopeMapping = new Map<Element, Element>();
    for (Element element in scopeVariables) {
      // No need to box non-assignable elements.
      if (!element.isAssignable()) continue;
      if (!mutatedVariables.contains(element)) continue;
      if (capturedVariableMapping.containsKey(element)) {
        if (box == null) {
          // TODO(floitsch): construct better box names.
          String boxName =
              namer.getClosureVariableName('box', closureFieldCounter++);
          box = new BoxElement(
              boxName, currentElement, compiler.types.dynamicType);
        }
        String elementName = element.name;
        String boxedName =
            namer.getClosureVariableName(elementName, boxedFieldCounter++);
        // TODO(kasperl): Should this be a FieldElement instead?
        Element boxed = new BoxFieldElement(boxedName, element, box);
        // No need to rename the fields of a box, so we give them a native name
        // right now.
        boxed.setFixedBackendName(boxedName);
        scopeMapping[element] = boxed;
        capturedVariableMapping[element] = boxed;
      }
    }
    if (!scopeMapping.isEmpty) {
      ClosureScope scope = new ClosureScope(box, scopeMapping);
      closureData.capturingScopes[node] = scope;
    }
  }

  void inNewScope(Node node, Function action) {
    List<Element> oldScopeVariables = scopeVariables;
    scopeVariables = new List<Element>();
    action();
    attachCapturedScopeVariables(node);
    for (Element element in scopeVariables) {
      mutatedVariables.remove(element);
    }
    scopeVariables = oldScopeVariables;
  }

  visitLoop(Loop node) {
    inNewScope(node, () {
      node.visitChildren(this);
    });
  }

  visitFor(For node) {
    visitLoop(node);
    // See if we have declared loop variables that need to be boxed.
    if (node.initializer == null) return;
    VariableDefinitions definitions = node.initializer.asVariableDefinitions();
    if (definitions == null) return;
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    List<Element> result = <Element>[];
    for (Link<Node> link = definitions.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      Element element = elements[definition];
      if (capturedVariableMapping.containsKey(element)) {
        result.add(element);
      };
    }
    scopeData.boxedLoopVariables = result;
  }

  /** Returns a non-unique name for the given closure element. */
  String computeClosureName(Element element) {
    Link<String> parts = const Link<String>();
    String ownName = element.name;
    if (ownName == null || ownName == "") {
      parts = parts.prepend("closure");
    } else {
      parts = parts.prepend(ownName);
    }
    for (Element enclosingElement = element.enclosingElement;
         enclosingElement != null &&
             (enclosingElement.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY
              || enclosingElement.kind == ElementKind.GENERATIVE_CONSTRUCTOR
              || enclosingElement.kind == ElementKind.CLASS
              || enclosingElement.kind == ElementKind.FUNCTION
              || enclosingElement.kind == ElementKind.GETTER
              || enclosingElement.kind == ElementKind.SETTER);
         enclosingElement = enclosingElement.enclosingElement) {
      // TODO(johnniwinther): Simplify computed names.
      if (enclosingElement.isGenerativeConstructor() ||
          enclosingElement.isGenerativeConstructorBody() ||
          enclosingElement.isFactoryConstructor()) {
        parts = parts.prepend(
            Elements.reconstructConstructorName(enclosingElement));
      } else {
        String surroundingName =
            Elements.operatorNameToIdentifier(enclosingElement.name);
        parts = parts.prepend(surroundingName);
      }
      // A generative constructors's parent is the class; the class name is
      // already part of the generative constructor's name.
      if (enclosingElement.kind == ElementKind.GENERATIVE_CONSTRUCTOR) break;
    }
    StringBuffer sb = new StringBuffer();
    parts.printOn(sb, '_');
    return sb.toString();
  }

  ClosureClassMap globalizeClosure(FunctionExpression node,
                                   TypedElement element) {
    String closureName = computeClosureName(element);
    ClassElement globalizedElement = new ClosureClassElement(
        node, closureName, compiler, element, element.getCompilationUnit());
    FunctionElement callElement =
        new SynthesizedCallMethodElementX(Compiler.CALL_OPERATOR_NAME,
                                          element,
                                          globalizedElement);
    ClosureContainer enclosing = element.enclosingElement;
    enclosing.nestedClosures.add(callElement);
    globalizedElement.addMember(callElement, compiler);
    // The nested function's 'this' is the same as the one for the outer
    // function. It could be [null] if we are inside a static method.
    Element thisElement = closureData.thisElement;
    return new ClosureClassMap(element, globalizedElement,
                               callElement, thisElement);
  }

  void visitInvokable(TypedElement element, Node node, void visitChildren()) {
    bool oldInsideClosure = insideClosure;
    Element oldFunctionElement = currentElement;
    ClosureClassMap oldClosureData = closureData;

    insideClosure = outermostElement != null;
    currentElement = element;
    if (insideClosure) {
      closures.add(node);
      closureData = globalizeClosure(node, element);
    } else {
      outermostElement = element;
      Element thisElement = null;
      if (element.isInstanceMember() || element.isGenerativeConstructor()) {
        thisElement = new ThisElement(element, compiler.types.dynamicType);
      }
      closureData = new ClosureClassMap(null, null, null, thisElement);
    }
    closureMappingCache[node] = closureData;

    inNewScope(node, () {
      // We have to declare the implicit 'this' parameter.
      if (!insideClosure && closureData.thisElement != null) {
        declareLocal(closureData.thisElement);
      }
      // If we are inside a named closure we have to declare ourselve. For
      // simplicity we declare the local even if the closure does not have a
      // name.
      // It will simply not be used.
      if (insideClosure) {
        declareLocal(element);
      }

      if (currentElement.isFactoryConstructor() &&
          compiler.backend.classNeedsRti(currentElement.enclosingElement)) {
        // Declare the type parameters in the scope. Generative
        // constructors just use 'this'.
        ClassElement cls = currentElement.enclosingElement;
        cls.typeVariables.forEach((TypeVariableType typeVariable) {
          declareLocal(typeVariable.element);
        });
      }

      DartType type = element.computeType(compiler);
      // If the method needs RTI, or checked mode is set, we need to
      // escape the potential type variables used in that closure.
      if (element is FunctionElement
          && (compiler.backend.methodNeedsRti(element) ||
              compiler.enableTypeAssertions)) {
        analyzeTypeVariables(type);
      }

      visitChildren();
    });


    ClosureClassMap savedClosureData = closureData;
    bool savedInsideClosure = insideClosure;

    // Restore old values.
    insideClosure = oldInsideClosure;
    closureData = oldClosureData;
    currentElement = oldFunctionElement;

    // Mark all free variables as captured and use them in the outer function.
    Iterable<Element> freeVariables = savedClosureData.freeVariableMapping.keys;
    assert(freeVariables.isEmpty || savedInsideClosure);
    for (Element freeElement in freeVariables) {
      if (capturedVariableMapping[freeElement] != null &&
          capturedVariableMapping[freeElement] != freeElement) {
        compiler.internalError(node, 'In closure analyzer.');
      }
      capturedVariableMapping[freeElement] = freeElement;
      useLocal(freeElement);
    }
  }

  visitFunctionExpression(FunctionExpression node) {
    Element element = elements[node];

    if (element.isParameter()) {
      // TODO(ahe): This is a hack. This method should *not* call
      // visitChildren.
      return node.name.accept(this);
    }

    visitInvokable(element, node, () {
      // TODO(ahe): This is problematic. The backend should not repeat
      // the work of the resolver. It is the resolver's job to create
      // parameters, etc. Other phases should only visit statements.
      if (node.parameters != null) node.parameters.accept(this);
      if (node.initializers != null) node.initializers.accept(this);
      if (node.body != null) node.body.accept(this);
    });
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    declareLocal(elements[node]);
  }

  visitTryStatement(TryStatement node) {
    // TODO(ngeoffray): implement finer grain state.
    bool oldInTryStatement = inTryStatement;
    inTryStatement = true;
    node.visitChildren(this);
    inTryStatement = oldInTryStatement;
  }
}
