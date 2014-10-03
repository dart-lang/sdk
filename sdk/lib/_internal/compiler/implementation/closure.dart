// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library closureToClassMapper;

import "elements/elements.dart";
import "dart2jslib.dart";
import "dart_types.dart";
import "js_backend/js_backend.dart" show JavaScriptBackend;
import "scanner/scannerlib.dart" show Token;
import "tree/tree.dart";
import "util/util.dart";
import "elements/modelx.dart"
    show BaseFunctionElementX,
         ClassElementX,
         ElementX,
         LocalFunctionElementX;
import "elements/visitor.dart" show ElementVisitor;

import 'universe/universe.dart' show
    Universe;

class ClosureNamer {
  String getClosureVariableName(String name, int id) {
    return "${name}_$id";
  }

  void forgetElement(Element element) {}
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
        return new ClosureClassMap(null, null, null, new ThisLocal(element));
      } else {
        assert(element.isField);
        VariableElement field = element;
        if (field.initializer != null) {
          // The lazy initializer of a static.
          translator.translateLazyInitializer(element, node, field.initializer);
        } else {
          assert(element.isInstanceMember);
          closureMappingCache[node] =
              new ClosureClassMap(null, null, null, new ThisLocal(element));
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

  void forgetElement(var closure) {
    ClosureClassElement cls;
    if (closure is ClosureFieldElement) {
      cls = closure.closureClass;
    } else if (closure is SynthesizedCallMethodElementX) {
      cls = closure.closureClass;
    } else {
      throw new SpannableAssertionFailure(
          closure, 'Not a closure: $closure (${closure.runtimeType}).');
    }
    namer.forgetElement(cls);
    Universe universe = compiler.enqueuer.codegen.universe;
    universe.instantiatedTypes
        ..remove(cls.rawType)
        ..remove(cls.thisType);
    universe.instantiatedClasses.remove(cls);
    cls.forEachLocalMember((Element e) {
      universe.closurizedMembers.remove(e);
      universe.fieldSetters.remove(e);
      universe.fieldGetters.remove(e);
    });
    compiler.enqueuer.codegen.seenClasses.remove(cls);
  }
}

/// Common interface for [BoxFieldElement] and [ClosureFieldElement] as
/// non-elements.
abstract class CapturedVariable {}

// TODO(ahe): These classes continuously cause problems.  We need to
// find a more general solution.
class ClosureFieldElement extends ElementX
    implements VariableElement, CapturedVariable {
  /// The source variable this element refers to.
  final Local local;

  ClosureFieldElement(String name,
                      this.local,
                      ClosureClassElement enclosing)
      : super(name, ElementKind.FIELD, enclosing);

  /// Use [closureClass] instead.
  @deprecated
  get enclosingElement => super.enclosingElement;

  ClosureClassElement get closureClass => super.enclosingElement;

  MemberElement get memberContext => closureClass.methodElement.memberContext;

  bool get hasNode => false;

  Node get node {
    throw new SpannableAssertionFailure(local,
        'Should not access node of ClosureFieldElement.');
  }

  bool get hasResolvedAst => hasTreeElements;

  ResolvedAst get resolvedAst {
    return new ResolvedAst(this, null, treeElements);
  }

  Expression get initializer {
    throw new SpannableAssertionFailure(local,
        'Should not access initializer of ClosureFieldElement.');
  }

  bool get isInstanceMember => true;
  bool get isAssignable => false;

  DartType computeType(Compiler compiler) => type;

  DartType get type {
    if (local is LocalElement) {
      LocalElement element = local;
      return element.type;
    }
    return const DynamicType();
  }

  String toString() => "ClosureFieldElement($name)";

  accept(ElementVisitor visitor) => visitor.visitClosureFieldElement(this);

  Element get analyzableElement => closureClass.methodElement.analyzableElement;
}

// TODO(ahe): These classes continuously cause problems.  We need to find
// a more general solution.
class ClosureClassElement extends ClassElementX {
  DartType rawType;
  DartType thisType;
  FunctionType callType;
  /// Node that corresponds to this closure, used for source position.
  final FunctionExpression node;

  /**
   * The element for the declaration of the function expression.
   */
  final LocalFunctionElement methodElement;

  final List<ClosureFieldElement> _closureFields = <ClosureFieldElement>[];

  ClosureClassElement(this.node,
                      String name,
                      Compiler compiler,
                      LocalFunctionElement closure)
      : this.methodElement = closure,
        super(name,
              closure.compilationUnit,
              // By assigning a fresh class-id we make sure that the hashcode
              // is unique, but also emit closure classes after all other
              // classes (since the emitter sorts classes by their id).
              compiler.getNextFreeClassId(),
              STATE_DONE) {
    JavaScriptBackend backend = compiler.backend;
    ClassElement superclass = methodElement.isInstanceMember
        ? backend.boundClosureClass
        : backend.closureClass;
    superclass.ensureResolved(compiler);
    supertype = superclass.thisType;
    interfaces = const Link<DartType>();
    thisType = rawType = new InterfaceType(this);
    allSupertypesAndSelf =
        superclass.allSupertypesAndSelf.extendClass(thisType);
    callType = methodElement.type;
  }

  Iterable<ClosureFieldElement> get closureFields => _closureFields;

  void addField(ClosureFieldElement field, DiagnosticListener listener) {
    _closureFields.add(field);
    addMember(field, listener);
  }

  bool get hasNode => true;

  bool get isClosure => true;

  Token get position => node.getBeginToken();

  Node parseNode(DiagnosticListener listener) => node;

  // A [ClosureClassElement] is nested inside a function or initializer in terms
  // of [enclosingElement], but still has to be treated as a top-level
  // element.
  bool get isTopLevel => true;

  get enclosingElement => methodElement;

  accept(ElementVisitor visitor) => visitor.visitClosureClassElement(this);
}

/// A local variable that contains the box object holding the [BoxFieldElement]
/// fields.
class BoxLocal extends Local {
  final String name;
  final ExecutableElement executableContext;

  BoxLocal(this.name, this.executableContext);
}

// TODO(ngeoffray, ahe): These classes continuously cause problems.  We need to
// find a more general solution.
class BoxFieldElement extends ElementX
    implements TypedElement, CapturedVariable {
  final BoxLocal box;

  BoxFieldElement(String name, this.variableElement, BoxLocal box)
      : this.box = box,
        super(name, ElementKind.FIELD, box.executableContext);

  DartType computeType(Compiler compiler) => type;

  DartType get type => variableElement.type;

  final VariableElement variableElement;

  accept(ElementVisitor visitor) => visitor.visitBoxFieldElement(this);
}

/// A local variable used encode the direct (uncaptured) references to [this].
class ThisLocal extends Local {
  final ExecutableElement executableContext;

  ThisLocal(this.executableContext);

  String get name => 'this';

  ClassElement get enclosingClass => executableContext.enclosingClass;
}

/// Call method of a closure class.
class SynthesizedCallMethodElementX extends BaseFunctionElementX {
  final LocalFunctionElement expression;

  SynthesizedCallMethodElementX(String name,
                                LocalFunctionElementX other,
                                ClosureClassElement enclosing)
      : expression = other,
        super(name, other.kind, other.modifiers, enclosing, false) {
    functionSignatureCache = other.functionSignature;
  }

  /// Use [closureClass] instead.
  @deprecated
  get enclosingElement => super.enclosingElement;

  ClosureClassElement get closureClass => super.enclosingElement;

  MemberElement get memberContext {
    return closureClass.methodElement.memberContext;
  }

  bool get hasNode => expression.hasNode;

  FunctionExpression get node => expression.node;

  FunctionExpression parseNode(DiagnosticListener listener) => node;

  ResolvedAst get resolvedAst {
    return new ResolvedAst(this, node, treeElements);
  }

  Element get analyzableElement => closureClass.methodElement.analyzableElement;
}

// The box-element for a scope, and the captured variables that need to be
// stored in the box.
class ClosureScope {
  BoxLocal boxElement;
  Map<VariableElement, BoxFieldElement> _capturedVariableMapping;

  // If the scope is attached to a [For] contains the variables that are
  // declared in the initializer of the [For] and that need to be boxed.
  // Otherwise contains the empty List.
  List<VariableElement> boxedLoopVariables = const <VariableElement>[];

  ClosureScope(this.boxElement, this._capturedVariableMapping);

  bool hasBoxedLoopVariables() => !boxedLoopVariables.isEmpty;

  bool isCapturedVariable(VariableElement variable) {
    return _capturedVariableMapping.containsKey(variable);
  }

  void forEachCapturedVariable(f(LocalVariableElement variable,
                                 BoxFieldElement boxField)) {
    _capturedVariableMapping.forEach(f);
  }
}

class ClosureClassMap {
  // The closure's element before any translation. Will be null for methods.
  final LocalFunctionElement closureElement;
  // The closureClassElement will be null for methods that are not local
  // closures.
  final ClosureClassElement closureClassElement;
  // The callElement will be null for methods that are not local closures.
  final FunctionElement callElement;
  // The [thisElement] makes handling 'this' easier by treating it like any
  // other argument. It is only set for instance-members.
  final ThisLocal thisLocal;

  // Maps free locals, arguments and function elements to their captured
  // copies.
  final Map<Local, CapturedVariable> _freeVariableMapping =
      new Map<Local, CapturedVariable>();

  // Maps closure-fields to their captured elements. This is somehow the inverse
  // mapping of [freeVariableMapping], but whereas [freeVariableMapping] does
  // not deal with boxes, here we map instance-fields (which might represent
  // boxes) to their boxElement.
  final Map<ClosureFieldElement, Local> _closureFieldMapping =
      new Map<ClosureFieldElement, Local>();

  // Maps scopes ([Loop] and [FunctionExpression] nodes) to their
  // [ClosureScope] which contains their box and the
  // captured variables that are stored in the box.
  // This map will be empty if the method/closure of this [ClosureData] does not
  // contain any nested closure.
  final Map<Node, ClosureScope> capturingScopes = new Map<Node, ClosureScope>();

  final Set<Local> usedVariablesInTry = new Set<Local>();

  ClosureClassMap(this.closureElement,
                  this.closureClassElement,
                  this.callElement,
                  this.thisLocal);

  void addFreeVariable(Local element) {
    assert(_freeVariableMapping[element] == null);
    _freeVariableMapping[element] = null;
  }

  Iterable<Local> get freeVariables => _freeVariableMapping.keys;

  bool isFreeVariable(Local element) {
    return _freeVariableMapping.containsKey(element);
  }

  CapturedVariable getFreeVariableElement(Local element) {
    return _freeVariableMapping[element];
  }

  /// Sets the free [variable] to be captured by the [boxField].
  void setFreeVariableBoxField(Local variable,
                               BoxFieldElement boxField) {
    _freeVariableMapping[variable] = boxField;
  }

  /// Sets the free [variable] to be captured by the [closureField].
  void setFreeVariableClosureField(Local variable,
                                   ClosureFieldElement closureField) {
    _freeVariableMapping[variable] = closureField;
  }


  void forEachFreeVariable(f(Local variable,
                             CapturedVariable field)) {
    _freeVariableMapping.forEach(f);
  }

  Local getLocalVariableForClosureField(ClosureFieldElement field) {
    return _closureFieldMapping[field];
  }

  void setLocalVariableForClosureField(ClosureFieldElement field,
      Local variable) {
    _closureFieldMapping[field] = variable;
  }

  bool get isClosure => closureElement != null;

  bool capturingScopesBox(Local variable) {
    return capturingScopes.values.any((scope) {
      return scope.boxedLoopVariables.contains(variable);
    });
  }

  bool isVariableBoxed(Local variable) {
    CapturedVariable copy = _freeVariableMapping[variable];
    if (copy is BoxFieldElement) {
      return true;
    }
    return capturingScopesBox(variable);
  }

  void forEachCapturedVariable(void f(Local variable,
                                      CapturedVariable field)) {
    _freeVariableMapping.forEach((variable, copy) {
      if (variable is BoxLocal) return;
      f(variable, copy);
    });
    capturingScopes.values.forEach((ClosureScope scope) {
      scope.forEachCapturedVariable(f);
    });
  }

  void forEachBoxedVariable(void f(LocalVariableElement local,
                                   BoxFieldElement field)) {
    _freeVariableMapping.forEach((variable, copy) {
      if (!isVariableBoxed(variable)) return;
      f(variable, copy);
    });
    capturingScopes.values.forEach((ClosureScope scope) {
      scope.forEachCapturedVariable(f);
    });
  }

  void removeMyselfFrom(Universe universe) {
    _freeVariableMapping.values.forEach((e) {
      universe.closurizedMembers.remove(e);
      universe.fieldSetters.remove(e);
      universe.fieldGetters.remove(e);
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

  // Map of captured variables. Initially they will map to `null`. If
  // a variable needs to be boxed then the scope declaring the variable
  // will update this to mapping to the capturing [BoxFieldElement].
  Map<Local, BoxFieldElement> _capturedVariableMapping =
      new Map<Local, BoxFieldElement>();

  // List of encountered closures.
  List<Expression> closures = <Expression>[];

  // The local variables that have been declared in the current scope.
  List<LocalVariableElement> scopeVariables;

  // Keep track of the mutated local variables so that we don't need to box
  // non-mutated variables.
  Set<LocalVariableElement> mutatedVariables = new Set<LocalVariableElement>();

  MemberElement outermostElement;
  ExecutableElement executableContext;

  // The closureData of the currentFunctionElement.
  ClosureClassMap closureData;

  ClosureNamer namer;

  bool insideClosure = false;

  ClosureTranslator(this.compiler,
                    this.elements,
                    this.closureMappingCache,
                    this.namer);

  bool isCapturedVariable(Local element) {
    return _capturedVariableMapping.containsKey(element);
  }

  void addCapturedVariable(Node node, Local variable) {
    if (_capturedVariableMapping[variable] != null) {
      compiler.internalError(node, 'In closure analyzer.');
    }
    _capturedVariableMapping[variable] = null;
  }

  void setCapturedVariableBoxField(Local variable,
      BoxFieldElement boxField) {
    assert(isCapturedVariable(variable));
    _capturedVariableMapping[variable] = boxField;
  }

  BoxFieldElement getCapturedVariableBoxField(Local variable) {
    return _capturedVariableMapping[variable];
  }

  void translateFunction(Element element, FunctionExpression node) {
    // For constructors the [element] and the [:elements[node]:] may differ.
    // The [:elements[node]:] always points to the generative-constructor
    // element, whereas the [element] might be the constructor-body element.
    visit(node); // [visitFunctionExpression] will call [visitInvokable].
    // When variables need to be boxed their [_capturedVariableMapping] is
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
  // class representing the closure.
  void updateClosures() {
    for (Expression closure in closures) {
      // The captured variables that need to be stored in a field of the closure
      // class.
      Set<Local> fieldCaptures = new Set<Local>();
      Set<BoxLocal> boxes = new Set<BoxLocal>();
      ClosureClassMap data = closureMappingCache[closure];
      // We get a copy of the keys and iterate over it, to avoid modifications
      // to the map while iterating over it.
      Iterable<Local> freeVariables = data.freeVariables.toList();
      freeVariables.forEach((Local fromElement) {
        assert(data.isFreeVariable(fromElement));
        assert(data.getFreeVariableElement(fromElement) == null);
        assert(isCapturedVariable(fromElement));
        BoxFieldElement boxFieldElement =
            getCapturedVariableBoxField(fromElement);
        if (boxFieldElement == null) {
          assert(fromElement is! BoxLocal);
          // The variable has not been boxed.
          fieldCaptures.add(fromElement);
        } else {
          // A boxed element.
          data.setFreeVariableBoxField(fromElement, boxFieldElement);
          boxes.add(boxFieldElement.box);
        }
      });
      ClosureClassElement closureClass = data.closureClassElement;
      assert(closureClass != null ||
             (fieldCaptures.isEmpty && boxes.isEmpty));

      void addClosureField(Local local, String name) {
        ClosureFieldElement closureField =
            new ClosureFieldElement(name, local, closureClass);
        closureClass.addField(closureField, compiler);
        data.setLocalVariableForClosureField(closureField, local);
        data.setFreeVariableClosureField(local, closureField);
      }

      // Add the box elements first so we get the same ordering.
      // TODO(sra): What is the canonical order of multiple boxes?
      for (BoxLocal capturedElement in boxes) {
        addClosureField(capturedElement, capturedElement.name);
      }

      /// Comparator for locals. Position boxes before elements.
      int compareLocals(a, b) {
        if (a is Element && b is Element) {
          return Elements.compareByPosition(a, b);
        } else if (a is Element) {
          return 1;
        } else if (b is Element) {
          return -1;
        } else {
          return a.name.compareTo(b.name);
        }
      }

      for (Local capturedLocal in fieldCaptures.toList()..sort(compareLocals)) {
        int id = closureFieldCounter++;
        String name = namer.getClosureVariableName(capturedLocal.name, id);
        addClosureField(capturedLocal, name);
      }
      closureClass.reverseBackendMembers();
    }
  }

  void useLocal(Local variable) {
    // If the element is not declared in the current function and the element
    // is not the closure itself we need to mark the element as free variable.
    // Note that the check on [insideClosure] is not just an
    // optimization: factories have type parameters as function
    // parameters, and type parameters are declared in the class, not
    // the factory.
    bool inCurrentContext(Local variable) {
      return variable == executableContext ||
             variable.executableContext == executableContext;
    }

    if (insideClosure && !inCurrentContext(variable)) {
      closureData.addFreeVariable(variable);
    } else if (inTryStatement) {
      // Don't mark the this-element or a self-reference. This would complicate
      // things in the builder.
      // Note that nested (named) functions are immutable.
      if (variable != closureData.thisLocal &&
          variable != closureData.closureElement) {
        // TODO(ngeoffray): only do this if the variable is mutated.
        closureData.usedVariablesInTry.add(variable);
      }
    }
  }

  void useTypeVariableAsLocal(TypeVariableType typeVariable) {
    useLocal(new TypeVariableLocal(typeVariable, outermostElement));
  }

  void declareLocal(LocalVariableElement element) {
    scopeVariables.add(element);
  }

  void registerNeedsThis() {
    if (closureData.thisLocal != null) {
      useLocal(closureData.thisLocal);
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
      LocalElement element = elements[definition];
      assert(element != null);
      if (!element.isInitializingFormal) {
        declareLocal(element);
      }
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
    MemberElement member = executableContext.memberContext;
    DartType type = elements.getType(node);
    // TODO(karlklose,johnniwinther): if the type is null, the annotation is
    // from a parameter which has been analyzed before the method has been
    // resolved and the result has been thrown away.
    if (compiler.enableTypeAssertions && type != null &&
        type.containsTypeVariables) {
      if (insideClosure && member.isFactoryConstructor) {
        // This is a closure in a factory constructor.  Since there is no
        // [:this:], we have to mark the type arguments as free variables to
        // capture them in the closure.
        type.forEachTypeVariable((TypeVariableType variable) {
          useTypeVariableAsLocal(variable);
        });
      }
      if (member.isInstanceMember && !member.isField) {
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
      if (element != null && element.isTypeVariable) {
        if (outermostElement.isConstructor) {
          TypeVariableElement typeVariable = element;
          useTypeVariableAsLocal(typeVariable.type);
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
      LocalElement localElement = element;
      useLocal(localElement);
    } else if (element != null && element.isTypeVariable) {
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
    } else if (elements.isAssert(node) && !compiler.enableUserAssertions) {
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
      if (!outermostElement.isField &&
          !outermostElement.isConstructor) {
        registerNeedsThis();
      } else {
        useTypeVariableAsLocal(typeVariable);
      }
    });
  }

  void analyzeType(DartType type) {
    // TODO(johnniwinther): Find out why this can be null.
    if (type == null) return;
    if (outermostElement.isClassMember &&
        compiler.backend.classNeedsRti(outermostElement.enclosingClass)) {
      if (outermostElement.isConstructor ||
          outermostElement.isField) {
        analyzeTypeVariables(type);
      } else if (outermostElement.isInstanceMember) {
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
    BoxLocal box = null;
    Map<LocalVariableElement, BoxFieldElement> scopeMapping =
        new Map<LocalVariableElement, BoxFieldElement>();

    void boxCapturedVariable(LocalVariableElement variable) {
      if (isCapturedVariable(variable)) {
        if (box == null) {
          // TODO(floitsch): construct better box names.
          String boxName =
              namer.getClosureVariableName('box', closureFieldCounter++);
          box = new BoxLocal(boxName, executableContext);
        }
        String elementName = variable.name;
        String boxedName =
            namer.getClosureVariableName(elementName, boxedFieldCounter++);
        // TODO(kasperl): Should this be a FieldElement instead?
        BoxFieldElement boxed = new BoxFieldElement(boxedName, variable, box);
        // No need to rename the fields of a box, so we give them a native name
        // right now.
        boxed.setFixedBackendName(boxedName);
        scopeMapping[variable] = boxed;
        setCapturedVariableBoxField(variable, boxed);
      }
    }

    for (LocalVariableElement variable in scopeVariables) {
      // No need to box non-assignable elements.
      if (!variable.isAssignable) continue;
      if (!mutatedVariables.contains(variable)) continue;
      boxCapturedVariable(variable);
    }
    if (!scopeMapping.isEmpty) {
      ClosureScope scope = new ClosureScope(box, scopeMapping);
      closureData.capturingScopes[node] = scope;
    }
  }

  void inNewScope(Node node, Function action) {
    List<LocalVariableElement> oldScopeVariables = scopeVariables;
    scopeVariables = <LocalVariableElement>[];
    action();
    attachCapturedScopeVariables(node);
    mutatedVariables.removeAll(scopeVariables);
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
    List<LocalVariableElement> result = <LocalVariableElement>[];
    for (Link<Node> link = definitions.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      LocalVariableElement element = elements[definition];
      if (isCapturedVariable(element)) {
        result.add(element);
      }
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
      if (enclosingElement.isGenerativeConstructor ||
          enclosingElement.isGenerativeConstructorBody ||
          enclosingElement.isFactoryConstructor) {
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

  JavaScriptBackend get backend => compiler.backend;

  ClosureClassMap globalizeClosure(FunctionExpression node,
                                   LocalFunctionElement element) {
    String closureName = computeClosureName(element);
    ClosureClassElement globalizedElement = new ClosureClassElement(
        node, closureName, compiler, element);
    FunctionElement callElement =
        new SynthesizedCallMethodElementX(Compiler.CALL_OPERATOR_NAME,
                                          element,
                                          globalizedElement);
    backend.maybeMarkClosureAsNeededForReflection(globalizedElement, callElement, element);
    MemberElement enclosing = element.memberContext;
    enclosing.nestedClosures.add(callElement);
    globalizedElement.addMember(callElement, compiler);
    globalizedElement.computeAllClassMembers(compiler);
    // The nested function's 'this' is the same as the one for the outer
    // function. It could be [null] if we are inside a static method.
    ThisLocal thisElement = closureData.thisLocal;

    return new ClosureClassMap(element, globalizedElement,
                               callElement, thisElement);
  }

  void visitInvokable(ExecutableElement element,
                      Node node,
                      void visitChildren()) {
    bool oldInsideClosure = insideClosure;
    Element oldFunctionElement = executableContext;
    ClosureClassMap oldClosureData = closureData;

    insideClosure = outermostElement != null;
    LocalFunctionElement closure;
    executableContext = element;
    if (insideClosure) {
      closure = element;
      closures.add(node);
      closureData = globalizeClosure(node, closure);
    } else {
      outermostElement = element;
      ThisLocal thisElement = null;
      if (element.isInstanceMember || element.isGenerativeConstructor) {
        thisElement = new ThisLocal(element);
      }
      closureData = new ClosureClassMap(null, null, null, thisElement);
    }
    closureMappingCache[node] = closureData;

    inNewScope(node, () {
      DartType type = element.type;
      // If the method needs RTI, or checked mode is set, we need to
      // escape the potential type variables used in that closure.
      if (element is FunctionElement &&
          (compiler.backend.methodNeedsRti(element) ||
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
    executableContext = oldFunctionElement;

    // Mark all free variables as captured and use them in the outer function.
    Iterable<Local> freeVariables = savedClosureData.freeVariables;
    assert(freeVariables.isEmpty || savedInsideClosure);
    for (Local freeVariable in freeVariables) {
      addCapturedVariable(node, freeVariable);
      useLocal(freeVariable);
    }
  }

  visitFunctionExpression(FunctionExpression node) {
    Element element = elements[node];

    if (element.isParameter) {
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

  visitTryStatement(TryStatement node) {
    // TODO(ngeoffray): implement finer grain state.
    bool oldInTryStatement = inTryStatement;
    inTryStatement = true;
    node.visitChildren(this);
    inTryStatement = oldInTryStatement;
  }
}

/// A type variable as a local variable.
class TypeVariableLocal implements Local {
  final TypeVariableType typeVariable;
  final ExecutableElement executableContext;

  TypeVariableLocal(this.typeVariable, this.executableContext);

  String get name => typeVariable.name;

  int get hashCode => typeVariable.hashCode;

  bool operator ==(other) {
    if (other is! TypeVariableLocal) return false;
    return typeVariable == other.typeVariable;
  }
}
