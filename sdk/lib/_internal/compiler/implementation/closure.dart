// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library closureToClassMapper;

import "elements/elements.dart";
import "dart2jslib.dart";
import "tree/tree.dart";
import "util/util.dart";

class ClosureTask extends CompilerTask {
  Map<Node, ClosureClassMap> closureMappingCache;
  ClosureTask(Compiler compiler)
      : closureMappingCache = new Map<Node, ClosureClassMap>(),
        super(compiler);

  String get name => "Closure Simplifier";

  ClosureClassMap computeClosureToClassMapping(Element element,
                                               Expression node,
                                               TreeElements elements) {
    return measure(() {
      ClosureClassMap cached = closureMappingCache[node];
      if (cached != null) return cached;

      ClosureTranslator translator =
          new ClosureTranslator(compiler, elements, closureMappingCache);

      // The translator will store the computed closure-mappings inside the
      // cache. One for given node and one for each nested closure.
      if (node is FunctionExpression) {
        translator.translateFunction(element, node);
      } else {
        // Must be the lazy initializer of a static.
        assert(node is SendSet);
        translator.translateLazyInitializer(element, node);
      }
      assert(closureMappingCache[node] != null);
      return closureMappingCache[node];
    });
  }

  ClosureClassMap getMappingForNestedFunction(FunctionExpression node) {
    return measure(() {
      ClosureClassMap nestedClosureData = closureMappingCache[node];
      if (nestedClosureData == null) {
        compiler.internalError("No closure cache", node: node);
      }
      return nestedClosureData;
    });
  }
}

class ClosureFieldElement extends Element {
  ClosureFieldElement(SourceString name, ClassElement enclosing)
      : super(name, ElementKind.FIELD, enclosing);

  bool isInstanceMember() => true;
  bool isAssignable() => false;

  String toString() => "ClosureFieldElement($name)";
}

class ClosureClassElement extends ClassElement {
  ClosureClassElement(SourceString name,
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
    compiler.closureClass.ensureResolved(compiler);
    supertype = compiler.closureClass.computeType(compiler);
    interfaces = const Link<DartType>();
    allSupertypes = const Link<DartType>().prepend(supertype);
  }

  bool isClosure() => true;

  /**
   * The most outer method this closure is declared into.
   */
  Element methodElement;
}

class BoxElement extends Element {
  BoxElement(SourceString name, Element enclosingElement)
      : super(name, ElementKind.VARIABLE, enclosingElement);
}

class ThisElement extends Element {
  ThisElement(Element enclosing)
      : super(const SourceString('this'), ElementKind.PARAMETER, enclosing);

  bool isAssignable() => false;
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

  // A map from the parameter element to the variable element that
  // holds the sentinel check.
  final Map<Element, Element> parametersWithSentinel;

  ClosureClassMap(this.closureElement,
              this.closureClassElement,
              this.callElement,
              this.thisElement)
      : this.freeVariableMapping = new Map<Element, Element>(),
        this.capturedFieldMapping = new Map<Element, Element>(),
        this.capturingScopes = new Map<Node, ClosureScope>(),
        this.usedVariablesInTry = new Set<Element>(),
        this.parametersWithSentinel = new Map<Element, Element>();

  bool isClosure() => closureElement != null;
}

class ClosureTranslator extends Visitor {
  final Compiler compiler;
  final TreeElements elements;
  int closureFieldCounter = 0;
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

  bool insideClosure = false;

  ClosureTranslator(this.compiler, this.elements, this.closureMappingCache)
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

  void translateLazyInitializer(Element element, SendSet node) {
    assert(node.assignmentOperator.source == const SourceString("="));
    Expression initialValue = node.argumentsNode.nodes.head;
    visitInvokable(element, node, () { visit(initialValue); });
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
      ClosureClassMap data = closureMappingCache[closure];
      Map<Element, Element> freeVariableMapping = data.freeVariableMapping;
      // We get a copy of the keys and iterate over it, to avoid modifications
      // to the map while iterating over it.
      freeVariableMapping.keys.forEach((Element fromElement) {
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
          assert(boxElement.kind == ElementKind.VARIABLE);
          fieldCaptures.add(boxElement);
        }
      });
      ClassElement closureElement = data.closureClassElement;
      assert(closureElement != null || fieldCaptures.isEmpty);
      for (Element capturedElement in fieldCaptures) {
        SourceString name;
        if (capturedElement is BoxElement) {
          // The name is already mangled.
          name = capturedElement.name;
        } else {
          int id = closureFieldCounter++;
          name = new SourceString("${capturedElement.name.slowToString()}_$id");
        }
        Element fieldElement = new ClosureFieldElement(name, closureElement);
        closureElement.backendMembers =
            closureElement.backendMembers.prepend(fieldElement);
        data.capturedFieldMapping[fieldElement] = capturedElement;
        freeVariableMapping[capturedElement] = fieldElement;
      }
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

  visit(Node node) => node.accept(this);

  visitNode(Node node) => node.visitChildren(this);

  visitVariableDefinitions(VariableDefinitions node) {
    for (Link<Node> link = node.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      Element element = elements[definition];
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

  visitIdentifier(Identifier node) {
    if (node.isThis()) {
      useLocal(closureData.thisElement);
    }
    node.visitChildren(this);
  }

  visitSend(Send node) {
    Element element = elements[node];
    if (Elements.isLocal(element)) {
      useLocal(element);
    } else if (node.receiver == null &&
               Elements.isInstanceSend(node, elements)) {
      useLocal(closureData.thisElement);
    } else if (node.isSuperCall) {
      useLocal(closureData.thisElement);
    } else if (node.isParameterCheck) {
      Element parameter = elements[node.receiver];
      FunctionElement enclosing = parameter.enclosingElement;
      FunctionExpression function = enclosing.parseNode(compiler);
      ClosureClassMap cached = closureMappingCache[function];
      if (!cached.parametersWithSentinel.containsKey(parameter)) {
        SourceString parameterName = parameter.name;
        String name = '${parameterName.slowToString()}_check';
        Element newElement = new Element(new SourceString(name),
                                         ElementKind.VARIABLE,
                                         enclosing);
        useLocal(newElement);
        cached.parametersWithSentinel[parameter] = newElement;
      }
    }
    node.visitChildren(this);
  }

  visitSendSet(SendSet node) {
    Element element = elements[node];
    if (Elements.isLocal(element)) {
      mutatedVariables.add(element);
    }
    super.visitSendSet(node);
  }

  visitNewExpression(NewExpression node) {
    DartType type = elements.getType(node);

    bool hasTypeVariable(DartType type) {
      if (type is TypeVariableType) {
        return true;
      } else if (type is InterfaceType) {
        InterfaceType ifcType = type;
        for (DartType argument in ifcType.typeArguments) {
          if (hasTypeVariable(argument)) {
            return true;
          }
        }
      }
      return false;
    }

    void analyzeTypeVariables(DartType type) {
      if (type is TypeVariableType) {
        useLocal(type.element);
      } else if (type is InterfaceType) {
        InterfaceType ifcType = type;
        for (DartType argument in ifcType.typeArguments) {
          analyzeTypeVariables(argument);
        }
      }
    }
    if (outermostElement.isMember() &&
        compiler.world.needsRti(outermostElement.getEnclosingClass())) {
      if (outermostElement.isInstanceMember()
          || outermostElement.isGenerativeConstructor()) {
        if (hasTypeVariable(type)) useLocal(closureData.thisElement);
      } else if (outermostElement.isFactoryConstructor()) {
        analyzeTypeVariables(type);
      }
    }

    node.visitChildren(this);
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
          SourceString boxName =
              new SourceString("box_${closureFieldCounter++}");
          box = new BoxElement(boxName, currentElement);
        }
        // TODO(floitsch): construct better boxed names.
        String elementName = element.name.slowToString();
        // We are currently using the name in an HForeign which could replace
        // "$X" with something else.
        String escaped = elementName.replaceAll("\$", "_");
        SourceString boxedName =
            new SourceString("${escaped}_${closureFieldCounter++}");
        Element boxed = new Element(boxedName, ElementKind.FIELD, box);
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
  String closureName(Element element) {
    Link<String> parts = const Link<String>();
    SourceString ownName = element.name;
    if (ownName == null || ownName.stringValue == "") {
      parts = parts.prepend("anon");
    } else {
      parts = parts.prepend(ownName.slowToString());
    }
    for (Element enclosingElement = element.enclosingElement;
         enclosingElement != null &&
             (identical(enclosingElement.kind,
                        ElementKind.GENERATIVE_CONSTRUCTOR_BODY)
              || identical(enclosingElement.kind, ElementKind.CLASS)
              || identical(enclosingElement.kind, ElementKind.FUNCTION)
              || identical(enclosingElement.kind, ElementKind.GETTER)
              || identical(enclosingElement.kind, ElementKind.SETTER));
         enclosingElement = enclosingElement.enclosingElement) {
      SourceString surroundingName =
          Elements.operatorNameToIdentifier(enclosingElement.name);
      parts = parts.prepend(surroundingName.slowToString());
    }
    StringBuffer sb = new StringBuffer();
    parts.printOn(sb, '_');
    return sb.toString();
  }

  ClosureClassMap globalizeClosure(FunctionExpression node, Element element) {
    SourceString closureName = new SourceString(closureName(element));
    ClassElement globalizedElement = new ClosureClassElement(
        closureName, compiler, element, element.getCompilationUnit());
    FunctionElement callElement =
        new FunctionElement.from(Compiler.CALL_OPERATOR_NAME,
                                 element,
                                 globalizedElement);
    globalizedElement.backendMembers =
        const Link<Element>().prepend(callElement);
    // The nested function's 'this' is the same as the one for the outer
    // function. It could be [null] if we are inside a static method.
    Element thisElement = closureData.thisElement;
    return new ClosureClassMap(element, globalizedElement,
                               callElement, thisElement);
  }

  void visitInvokable(Element element, Expression node, void visitChildren()) {
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
        thisElement = new ThisElement(element);
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

      if (currentElement.isFactoryConstructor()
          && compiler.world.needsRti(currentElement.enclosingElement)) {
        // Declare the type parameters in the scope. Generative
        // constructors just use 'this'.
        ClassElement cls = currentElement.enclosingElement;
        cls.typeVariables.forEach((TypeVariableType typeVariable) {
          declareLocal(typeVariable.element);
        });
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
    List<Element> freeVariables =
        savedClosureData.freeVariableMapping.keys;
    assert(freeVariables.isEmpty || savedInsideClosure);
    for (Element freeElement in freeVariables) {
      if (capturedVariableMapping[freeElement] != null &&
          capturedVariableMapping[freeElement] != freeElement) {
        compiler.internalError('In closure analyzer', node: node);
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
