// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library closureToClassMapper;

import 'common/names.dart' show Identifiers;
import 'common/resolution.dart' show ParsingContext, Resolution;
import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'compiler.dart' show Compiler;
import 'constants/expressions.dart';
import 'elements/elements.dart';
import 'elements/entities.dart';
import 'elements/entity_utils.dart' as utils;
import 'elements/modelx.dart'
    show BaseFunctionElementX, ClassElementX, ElementX;
import 'elements/resolution_types.dart';
import 'elements/types.dart';
import 'elements/visitor.dart' show ElementVisitor;
import 'js_backend/js_backend.dart' show JavaScriptBackend;
import 'resolution/tree_elements.dart' show TreeElements;
import 'package:front_end/src/fasta/scanner.dart' show Token;
import 'tree/tree.dart';
import 'util/util.dart';
import 'world.dart' show ClosedWorldRefiner;

abstract class ClosureClassMaps {
  ClosureClassMap getMemberMap(MemberEntity member);
  ClosureClassMap getLocalFunctionMap(Local localFunction);
}

class ClosureTask extends CompilerTask implements ClosureClassMaps {
  Map<Element, ClosureClassMap> _closureMappingCache =
      <Element, ClosureClassMap>{};
  Compiler compiler;
  ClosureTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer);

  String get name => "Closure Simplifier";

  DiagnosticReporter get reporter => compiler.reporter;

  ClosureClassMap getMemberMap(MemberElement member) {
    return getClosureToClassMapping(member);
  }

  ClosureClassMap getLocalFunctionMap(LocalFunctionElement localFunction) {
    return getClosureToClassMapping(localFunction);
  }

  /// Returns the [ClosureClassMap] computed for [resolvedAst].
  ClosureClassMap getClosureToClassMapping(Element element) {
    return measure(() {
      if (element.isGenerativeConstructorBody) {
        ConstructorBodyElement constructorBody = element;
        element = constructorBody.constructor;
      }
      ClosureClassMap closureClassMap = _closureMappingCache[element];
      assert(closureClassMap != null,
          failedAt(element, "No ClosureClassMap computed for ${element}."));
      return closureClassMap;
    });
  }

  /// Create [ClosureClassMap]s for all live members.
  void createClosureClasses(ClosedWorldRefiner closedWorldRefiner) {
    compiler.enqueuer.resolution.processedEntities
        .forEach((MemberElement element) {
      ResolvedAst resolvedAst = element.resolvedAst;
      if (element.isAbstract) return;
      if (element.isField &&
          !element.isInstanceMember &&
          resolvedAst.body == null) {
        // Skip top-level/static fields without an initializer.
        return;
      }
      computeClosureToClassMapping(element, closedWorldRefiner);
    });
  }

  ClosureClassMap computeClosureToClassMapping(
      AstElement element, ClosedWorldRefiner closedWorldRefiner) {
    return measure(() {
      ClosureClassMap cached = _closureMappingCache[element];
      if (cached != null) return cached;
      if (element.resolvedAst.kind != ResolvedAstKind.PARSED) {
        return _closureMappingCache[element] =
            new ClosureClassMap(null, null, null, new ThisLocal(element));
      }
      return reporter.withCurrentElement(element.implementation, () {
        Node node = element.resolvedAst.node;
        TreeElements elements = element.resolvedAst.elements;

        ClosureTranslator translator = new ClosureTranslator(
            compiler, closedWorldRefiner, elements, _closureMappingCache);

        // The translator will store the computed closure-mappings inside the
        // cache. One for given node and one for each nested closure.
        if (node is FunctionExpression) {
          translator.translateFunction(element, node);
        } else if (element.isSynthesized) {
          reporter.internalError(
              element, "Unexpected synthesized element: $element");
          _closureMappingCache[element] =
              new ClosureClassMap(null, null, null, new ThisLocal(element));
        } else {
          assert(element.isField,
              failedAt(element, "Expected $element to be a field."));
          Node initializer = element.resolvedAst.body;
          if (initializer != null) {
            // The lazy initializer of a static.
            translator.translateLazyInitializer(element, node, initializer);
          } else {
            assert(
                element.isInstanceMember,
                failedAt(
                    element,
                    "Expected $element (${element.runtimeType}) "
                    "to be an instance field."));
            _closureMappingCache[element] =
                new ClosureClassMap(null, null, null, new ThisLocal(element));
          }
        }
        assert(_closureMappingCache[element] != null,
            failedAt(element, "No ClosureClassMap computed for ${element}."));
        return _closureMappingCache[element];
      });
    });
  }
}

// TODO(ahe): These classes continuously cause problems.  We need to
// find a more general solution.
class ClosureFieldElement extends ElementX
    implements FieldElement, PrivatelyNamedJSEntity {
  /// The [BoxLocal] or [LocalElement] being accessed through the field.
  final Local local;

  ClosureFieldElement(String name, this.local, ClosureClassElement enclosing)
      : super(name, ElementKind.FIELD, enclosing);

  /// Use [closureClass] instead.
  @deprecated
  get enclosingElement => super.enclosingElement;

  ClosureClassElement get closureClass => super.enclosingElement;

  MemberElement get memberContext => closureClass.methodElement.memberContext;

  @override
  Entity get declaredEntity => local;
  @override
  Entity get rootOfScope => closureClass;

  bool get hasNode => false;

  Node get node {
    throw new SpannableAssertionFailure(
        local, 'Should not access node of ClosureFieldElement.');
  }

  bool get hasResolvedAst => hasTreeElements;

  ResolvedAst get resolvedAst {
    return new ParsedResolvedAst(this, null, null, treeElements,
        memberContext.compilationUnit.script.resourceUri);
  }

  Expression get initializer {
    throw new SpannableAssertionFailure(
        local, 'Should not access initializer of ClosureFieldElement.');
  }

  bool get isInstanceMember => true;
  bool get isAssignable => false;

  ResolutionDartType computeType(Resolution resolution) => type;

  ResolutionDartType get type {
    if (local is LocalElement) {
      LocalElement element = local;
      return element.type;
    }
    return const ResolutionDynamicType();
  }

  String toString() => "ClosureFieldElement($name)";

  accept(ElementVisitor visitor, arg) {
    return visitor.visitClosureFieldElement(this, arg);
  }

  Element get analyzableElement => closureClass.methodElement.analyzableElement;

  @override
  List<FunctionElement> get nestedClosures => const <FunctionElement>[];

  @override
  bool get hasConstant => false;

  @override
  ConstantExpression get constant => null;
}

// TODO(ahe): These classes continuously cause problems.  We need to find
// a more general solution.
class ClosureClassElement extends ClassElementX {
  ResolutionInterfaceType rawType;
  ResolutionInterfaceType thisType;
  ResolutionFunctionType callType;

  /// Node that corresponds to this closure, used for source position.
  final FunctionExpression node;

  /**
   * The element for the declaration of the function expression.
   */
  final LocalFunctionElement methodElement;

  final List<ClosureFieldElement> _closureFields = <ClosureFieldElement>[];

  ClosureClassElement(
      this.node, String name, Compiler compiler, LocalFunctionElement closure)
      : this.methodElement = closure,
        super(
            name,
            closure.compilationUnit,
            // By assigning a fresh class-id we make sure that the hashcode
            // is unique, but also emit closure classes after all other
            // classes (since the emitter sorts classes by their id).
            compiler.idGenerator.getNextFreeId(),
            STATE_DONE) {
    ClassElement superclass = methodElement.isInstanceMember
        ? compiler.commonElements.boundClosureClass
        : compiler.commonElements.closureClass;
    superclass.ensureResolved(compiler.resolution);
    supertype = superclass.thisType;
    interfaces = const Link<ResolutionDartType>();
    thisType = rawType = new ResolutionInterfaceType(this);
    allSupertypesAndSelf =
        superclass.allSupertypesAndSelf.extendClass(thisType);
    callType = methodElement.type;
  }

  Iterable<ClosureFieldElement> get closureFields => _closureFields;

  void addField(ClosureFieldElement field, DiagnosticReporter listener) {
    _closureFields.add(field);
    addMember(field, listener);
  }

  bool get hasNode => true;

  bool get isClosure => true;

  Token get position => node.getBeginToken();

  Node parseNode(ParsingContext parsing) => node;

  // A [ClosureClassElement] is nested inside a function or initializer in terms
  // of [enclosingElement], but still has to be treated as a top-level
  // element.
  bool get isTopLevel => true;

  get enclosingElement => methodElement;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitClosureClassElement(this, arg);
  }
}

/// A local variable that contains the box object holding the [BoxFieldElement]
/// fields.
class BoxLocal extends Local {
  final String name;
  final ExecutableElement executableContext;

  final int hashCode = _nextHashCode = (_nextHashCode + 10007).toUnsigned(30);
  static int _nextHashCode = 0;

  BoxLocal(this.name, this.executableContext);

  @override
  MemberElement get memberContext => executableContext.memberContext;

  String toString() => 'BoxLocal($name)';
}

// TODO(ngeoffray, ahe): These classes continuously cause problems.  We need to
// find a more general solution.
class BoxFieldElement extends ElementX
    implements TypedElement, FieldElement, PrivatelyNamedJSEntity {
  final BoxLocal box;

  BoxFieldElement(String name, this.variableElement, BoxLocal box)
      : this.box = box,
        super(name, ElementKind.FIELD, box.executableContext);

  ResolutionDartType computeType(Resolution resolution) => type;

  ResolutionDartType get type => variableElement.type;

  @override
  Entity get declaredEntity => variableElement;
  @override
  Entity get rootOfScope => box;

  final VariableElement variableElement;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitBoxFieldElement(this, arg);
  }

  @override
  bool get hasNode => false;

  @override
  bool get hasResolvedAst => false;

  @override
  Expression get initializer {
    throw new UnsupportedError("BoxFieldElement.initializer");
  }

  @override
  MemberElement get memberContext => box.executableContext.memberContext;

  @override
  List<FunctionElement> get nestedClosures => const <FunctionElement>[];

  @override
  Node get node {
    throw new UnsupportedError("BoxFieldElement.node");
  }

  @override
  ResolvedAst get resolvedAst {
    throw new UnsupportedError("BoxFieldElement.resolvedAst");
  }

  @override
  bool get hasConstant => false;

  @override
  ConstantExpression get constant => null;
}

/// A local variable used encode the direct (uncaptured) references to [this].
class ThisLocal extends Local {
  final ExecutableElement executableContext;
  final hashCode = ElementX.newHashCode();

  ThisLocal(this.executableContext);

  @override
  MemberElement get memberContext => executableContext.memberContext;

  String get name => 'this';

  ClassElement get enclosingClass => executableContext.enclosingClass;
}

/// Call method of a closure class.
class SynthesizedCallMethodElementX extends BaseFunctionElementX
    implements MethodElement {
  final LocalFunctionElement expression;
  final FunctionExpression node;
  final TreeElements treeElements;

  SynthesizedCallMethodElementX(String name, LocalFunctionElement other,
      ClosureClassElement enclosing, this.node, this.treeElements)
      : expression = other,
        super(name, other.kind, Modifiers.EMPTY, enclosing) {
    asyncMarker = other.asyncMarker;
    functionSignature = other.functionSignature;
  }

  /// Use [closureClass] instead.
  @deprecated
  get enclosingElement => super.enclosingElement;

  ClosureClassElement get closureClass => super.enclosingElement;

  MemberElement get memberContext {
    return closureClass.methodElement.memberContext;
  }

  bool get hasNode => node != null;

  FunctionExpression parseNode(ParsingContext parsing) => node;

  Element get analyzableElement => closureClass.methodElement.analyzableElement;

  bool get hasResolvedAst => true;

  ResolvedAst get resolvedAst {
    return new ParsedResolvedAst(this, node, node.body, treeElements,
        expression.compilationUnit.script.resourceUri);
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitMethodElement(this, arg);
  }
}

// The box-element for a scope, and the captured variables that need to be
// stored in the box.
class ClosureScope {
  final BoxLocal boxElement;
  final Map<Local, BoxFieldElement> capturedVariables;

  // If the scope is attached to a [For] contains the variables that are
  // declared in the initializer of the [For] and that need to be boxed.
  // Otherwise contains the empty List.
  List<Local> boxedLoopVariables = const <Local>[];

  ClosureScope(this.boxElement, this.capturedVariables);

  bool hasBoxedLoopVariables() => !boxedLoopVariables.isEmpty;

  bool isCapturedVariable(Local variable) {
    return capturedVariables.containsKey(variable);
  }

  void forEachCapturedVariable(
      f(LocalVariableElement variable, BoxFieldElement boxField)) {
    capturedVariables.forEach(f);
  }

  String toString() {
    String separator = '';
    StringBuffer sb = new StringBuffer();
    sb.write('ClosureScope(');
    if (boxElement != null) {
      sb.write('box=$boxElement');
      separator = ',';
    }
    if (boxedLoopVariables.isNotEmpty) {
      sb.write(separator);
      sb.write('boxedLoopVariables=${boxedLoopVariables}');
      separator = ',';
    }
    if (capturedVariables.isNotEmpty) {
      sb.write(separator);
      sb.write('capturedVariables=$capturedVariables');
    }
    sb.write(')');
    return sb.toString();
  }
}

class ClosureClassMap {
  /// The local function element before any translation.
  ///
  /// Will be null for methods.
  final LocalFunctionElement closureElement;

  /// The synthesized closure class for [closureElement].
  ///
  /// The closureClassElement will be null for methods that are not local
  /// closures.
  final ClosureClassElement closureClassElement;

  /// The synthesized `call` method of the [ closureClassElement].
  ///
  /// The callElement will be null for methods that are not local closures.
  final MethodElement callElement;

  /// The [thisElement] makes handling 'this' easier by treating it like any
  /// other argument. It is only set for instance-members.
  final ThisLocal thisLocal;

  /// Maps free locals, arguments, function elements, and box locals to
  /// their locations.
  final Map<Local, FieldEntity> freeVariableMap = new Map<Local, FieldEntity>();

  /// Maps [Loop] and [FunctionExpression] nodes to their [ClosureScope] which
  /// contains their box and the captured variables that are stored in the box.
  /// This map will be empty if the method/closure of this [ClosureData] does
  /// not contain any nested closure.
  final Map<Node, ClosureScope> capturingScopes = new Map<Node, ClosureScope>();

  /// Variables that are used in a try must be treated as boxed because the
  /// control flow can be non-linear.
  ///
  /// Also parameters to a `sync*` generator must be boxed, because of the way
  /// we rewrite sync* functions. See also comments in [useLocal].
  // TODO(johnniwinther): Add variables to this only if the variable is mutated.
  final Set<Local> variablesUsedInTryOrGenerator = new Set<Local>();

  ClosureClassMap(this.closureElement, this.closureClassElement,
      this.callElement, this.thisLocal);

  void addFreeVariable(Local element) {
    assert(freeVariableMap[element] == null);
    freeVariableMap[element] = null;
  }

  Iterable<Local> get freeVariables => freeVariableMap.keys;

  bool isFreeVariable(Local element) {
    return freeVariableMap.containsKey(element);
  }

  void forEachFreeVariable(f(Local variable, FieldEntity field)) {
    freeVariableMap.forEach(f);
  }

  Local getLocalVariableForClosureField(ClosureFieldElement field) {
    return field.local;
  }

  bool get isClosure => closureElement != null;

  bool capturingScopesBox(Local variable) {
    return capturingScopes.values.any((scope) {
      return scope.boxedLoopVariables.contains(variable);
    });
  }

  bool isVariableBoxed(Local variable) {
    FieldEntity copy = freeVariableMap[variable];
    if (copy is BoxFieldElement) {
      return true;
    }
    return capturingScopesBox(variable);
  }

  void forEachCapturedVariable(void f(Local variable, FieldEntity field)) {
    freeVariableMap.forEach((variable, copy) {
      if (variable is BoxLocal) return;
      f(variable, copy);
    });
    capturingScopes.values.forEach((ClosureScope scope) {
      scope.forEachCapturedVariable(f);
    });
  }

  void forEachBoxedVariable(
      void f(LocalVariableElement local, BoxFieldElement field)) {
    freeVariableMap.forEach((variable, copy) {
      if (!isVariableBoxed(variable)) return;
      f(variable, copy);
    });
    capturingScopes.values.forEach((ClosureScope scope) {
      scope.forEachCapturedVariable(f);
    });
  }
}

class ClosureTranslator extends Visitor {
  final Compiler compiler;
  final ClosedWorldRefiner closedWorldRefiner;
  final TreeElements elements;
  int closureFieldCounter = 0;
  int boxedFieldCounter = 0;
  bool inTryStatement = false;

  final Map<Element, ClosureClassMap> closureMappingCache;

  // Map of captured variables. Initially they will map to `null`. If
  // a variable needs to be boxed then the scope declaring the variable
  // will update this to mapping to the capturing [BoxFieldElement].
  Map<Local, BoxFieldElement> _capturedVariableMapping =
      new Map<Local, BoxFieldElement>();

  // List of encountered closures.
  List<LocalFunctionElement> closures = <LocalFunctionElement>[];

  // The local variables that have been declared in the current scope.
  List<LocalVariableElement> scopeVariables;

  // Keep track of the mutated local variables so that we don't need to box
  // non-mutated variables.
  Set<LocalVariableElement> mutatedVariables = new Set<LocalVariableElement>();

  MemberElement outermostElement;
  ExecutableElement executableContext;

  // The closureData of the currentFunctionElement.
  ClosureClassMap closureData;

  bool insideClosure = false;

  ClosureTranslator(this.compiler, this.closedWorldRefiner, this.elements,
      this.closureMappingCache);

  DiagnosticReporter get reporter => compiler.reporter;

  /// Generate a unique name for the [id]th closure field, with proposed name
  /// [name].
  ///
  /// The result is used as the name of [ClosureFieldElement]s, and must
  /// therefore be unique to avoid breaking an invariant in the element model
  /// (classes cannot declare multiple fields with the same name).
  ///
  /// Also, the names should be distinct from real field names to prevent
  /// clashes with selectors for those fields.
  ///
  /// These names are not used in generated code, just as element name.
  String getClosureVariableName(String name, int id) {
    return "_captured_${name}_$id";
  }

  /// Generate a unique name for the [id]th box field, with proposed name
  /// [name].
  ///
  /// The result is used as the name of [BoxFieldElement]s, and must
  /// therefore be unique to avoid breaking an invariant in the element model
  /// (classes cannot declare multiple fields with the same name).
  ///
  /// Also, the names should be distinct from real field names to prevent
  /// clashes with selectors for those fields.
  ///
  /// These names are not used in generated code, just as element name.
  String getBoxFieldName(int id) {
    return "_box_$id";
  }

  bool isCapturedVariable(Local element) {
    return _capturedVariableMapping.containsKey(element);
  }

  void addCapturedVariable(Node node, Local variable) {
    if (_capturedVariableMapping[variable] != null) {
      reporter.internalError(node, 'In closure analyzer.');
    }
    _capturedVariableMapping[variable] = null;
  }

  void setCapturedVariableBoxField(Local variable, BoxFieldElement boxField) {
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
      VariableDefinitions node, Expression initializer) {
    visitInvokable(element, node, () {
      visit(initializer);
    });
    updateClosures();
  }

  // This function runs through all of the existing closures and updates their
  // free variables to the boxed value. It also adds the field-elements to the
  // class representing the closure.
  void updateClosures() {
    for (LocalFunctionElement closure in closures) {
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
        assert(data.freeVariableMap[fromElement] == null);
        assert(isCapturedVariable(fromElement));
        BoxFieldElement boxFieldElement =
            getCapturedVariableBoxField(fromElement);
        if (boxFieldElement == null) {
          assert(fromElement is! BoxLocal);
          // The variable has not been boxed.
          fieldCaptures.add(fromElement);
        } else {
          // A boxed element.
          data.freeVariableMap[fromElement] = boxFieldElement;
          boxes.add(boxFieldElement.box);
        }
      });
      ClosureClassElement closureClass = data.closureClassElement;
      assert(closureClass != null || (fieldCaptures.isEmpty && boxes.isEmpty));

      void addClosureField(Local local, String name) {
        ClosureFieldElement closureField =
            new ClosureFieldElement(name, local, closureClass);
        closureClass.addField(closureField, reporter);
        data.freeVariableMap[local] = closureField;
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
        String name = getClosureVariableName(capturedLocal.name, id);
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
          variable != closureData.closureElement &&
          variable is! TypeVariableLocal) {
        closureData.variablesUsedInTryOrGenerator.add(variable);
      }
    } else if (variable is LocalParameterElement &&
        variable.functionDeclaration.asyncMarker == AsyncMarker.SYNC_STAR) {
      // Parameters in a sync* function are shared between each Iterator created
      // by the Iterable returned by the function, therefore they must be boxed.
      closureData.variablesUsedInTryOrGenerator.add(variable);
    }
  }

  void useTypeVariableAsLocal(ResolutionTypeVariableType typeVariable) {
    useLocal(new TypeVariableLocal(
        typeVariable, outermostElement, outermostElement.memberContext));
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
    ResolutionDartType type = elements.getType(node);
    // TODO(karlklose,johnniwinther): if the type is null, the annotation is
    // from a parameter which has been analyzed before the method has been
    // resolved and the result has been thrown away.
    if (compiler.options.enableTypeAssertions &&
        type != null &&
        type.containsTypeVariables) {
      if (insideClosure && member.isFactoryConstructor) {
        // This is a closure in a factory constructor.  Since there is no
        // [:this:], we have to mark the type arguments as free variables to
        // capture them in the closure.
        type.forEachTypeVariable((ResolutionTypeVariableType variable) {
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
        if (outermostElement.isConstructor || outermostElement.isField) {
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
      ResolutionDartType type = elements.getType(annotation);
      analyzeType(type);
    } else if (node.isTypeTest) {
      ResolutionDartType type =
          elements.getType(node.typeAnnotationFromIsCheckOrCast);
      analyzeType(type);
    } else if (node.isTypeCast) {
      ResolutionDartType type = elements.getType(node.arguments.head);
      analyzeType(type);
    }
    node.visitChildren(this);
  }

  visitSendSet(SendSet node) {
    Element element = elements[node];
    if (Elements.isLocal(element)) {
      mutatedVariables.add(element);
      if (compiler.options.enableTypeAssertions) {
        TypedElement typedElement = element;
        analyzeTypeVariables(typedElement.type);
      }
    }
    super.visitSendSet(node);
  }

  visitNewExpression(NewExpression node) {
    ResolutionDartType type = elements.getType(node);
    analyzeType(type);
    node.visitChildren(this);
  }

  visitLiteralList(LiteralList node) {
    ResolutionDartType type = elements.getType(node);
    analyzeType(type);
    node.visitChildren(this);
  }

  visitLiteralMap(LiteralMap node) {
    ResolutionDartType type = elements.getType(node);
    analyzeType(type);
    node.visitChildren(this);
  }

  void analyzeTypeVariables(ResolutionDartType type) {
    type.forEachTypeVariable((ResolutionTypeVariableType typeVariable) {
      // Field initializers are inlined and access the type variable as
      // normal parameters.
      if (!outermostElement.isField && !outermostElement.isConstructor) {
        registerNeedsThis();
      } else {
        useTypeVariableAsLocal(typeVariable);
      }
    });
  }

  void analyzeType(ResolutionDartType type) {
    // TODO(johnniwinther): Find out why this can be null.
    if (type == null) return;
    if (outermostElement.isClassMember &&
        compiler.backend.rtiNeed
            .classNeedsRti(outermostElement.enclosingClass)) {
      if (outermostElement.isConstructor || outermostElement.isField) {
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
          String boxName = getBoxFieldName(closureFieldCounter++);
          box = new BoxLocal(boxName, executableContext);
        }
        String elementName = variable.name;
        String boxedName =
            getClosureVariableName(elementName, boxedFieldCounter++);
        // TODO(kasperl): Should this be a FieldElement instead?
        BoxFieldElement boxed = new BoxFieldElement(boxedName, variable, box);
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
    List<LocalVariableElement> boxedLoopVariables = <LocalVariableElement>[];
    inNewScope(node, () {
      // First visit initializer and update so we can easily check if a loop
      // variable was captured in one of these subexpressions.
      if (node.initializer != null) visit(node.initializer);
      if (node.update != null) visit(node.update);

      // Loop variables that have not been captured yet can safely be flagged as
      // non-mutated, because no nested function can observe the mutation.
      if (node.initializer is VariableDefinitions) {
        VariableDefinitions definitions = node.initializer;
        definitions.definitions.nodes.forEach((Node node) {
          LocalVariableElement local = elements[node];
          if (!isCapturedVariable(local)) {
            mutatedVariables.remove(local);
          }
        });
      }

      // Visit condition and body.
      // This must happen after the above, so any loop variables mutated in the
      // condition or body are indeed flagged as mutated.
      if (node.conditionStatement != null) visit(node.conditionStatement);
      if (node.body != null) visit(node.body);

      // See if we have declared loop variables that need to be boxed.
      if (node.initializer == null) return;
      VariableDefinitions definitions =
          node.initializer.asVariableDefinitions();
      if (definitions == null) return;
      for (Link<Node> link = definitions.definitions.nodes;
          !link.isEmpty;
          link = link.tail) {
        Node definition = link.head;
        LocalVariableElement element = elements[definition];
        // Non-mutated variables should not be boxed.  The mutatedVariables set
        // gets cleared when 'inNewScope' returns, so check it here.
        if (isCapturedVariable(element) && mutatedVariables.contains(element)) {
          boxedLoopVariables.add(element);
        }
      }
    });
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    scopeData.boxedLoopVariables = boxedLoopVariables;
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
            (enclosingElement.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY ||
                enclosingElement.kind == ElementKind.GENERATIVE_CONSTRUCTOR ||
                enclosingElement.kind == ElementKind.CLASS ||
                enclosingElement.kind == ElementKind.FUNCTION ||
                enclosingElement.kind == ElementKind.GETTER ||
                enclosingElement.kind == ElementKind.SETTER);
        enclosingElement = enclosingElement.enclosingElement) {
      // TODO(johnniwinther): Simplify computed names.
      if (enclosingElement.isGenerativeConstructor ||
          enclosingElement.isGenerativeConstructorBody ||
          enclosingElement.isFactoryConstructor) {
        ConstructorElement constructor = enclosingElement;
        parts = parts.prepend(utils.reconstructConstructorName(constructor));
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

  ClosureClassMap globalizeClosure(
      FunctionExpression node, LocalFunctionElement element) {
    String closureName = computeClosureName(element);
    ClosureClassElement globalizedElement =
        new ClosureClassElement(node, closureName, compiler, element);
    // Extend [globalizedElement] as an instantiated class in the closed world.
    closedWorldRefiner.registerClosureClass(globalizedElement);
    MethodElement callElement = new SynthesizedCallMethodElementX(
        Identifiers.call, element, globalizedElement, node, elements);
    backend.mirrorsDataBuilder.maybeMarkClosureAsNeededForReflection(
        globalizedElement, callElement, element);
    MemberElement enclosing = element.memberContext;
    enclosing.nestedClosures.add(callElement);
    globalizedElement.addMember(callElement, reporter);
    globalizedElement.computeAllClassMembers(compiler.resolution);
    // The nested function's 'this' is the same as the one for the outer
    // function. It could be [null] if we are inside a static method.
    ThisLocal thisElement = closureData.thisLocal;

    return new ClosureClassMap(
        element, globalizedElement, callElement, thisElement);
  }

  void visitInvokable(
      ExecutableElement element, Node node, void visitChildren()) {
    bool oldInsideClosure = insideClosure;
    Element oldFunctionElement = executableContext;
    ClosureClassMap oldClosureData = closureData;

    insideClosure = outermostElement != null;
    LocalFunctionElement closure;
    executableContext = element;
    bool needsRti = false;
    if (insideClosure) {
      closure = element;
      closures.add(closure);
      closureData = globalizeClosure(node, closure);
      needsRti = compiler.options.enableTypeAssertions ||
          compiler.backend.rtiNeed.localFunctionNeedsRti(closure);
    } else {
      outermostElement = element;
      ThisLocal thisElement = null;
      if (element.isInstanceMember || element.isGenerativeConstructor) {
        thisElement = new ThisLocal(element);
      }
      closureData = new ClosureClassMap(null, null, null, thisElement);
      if (element is MethodElement) {
        needsRti = compiler.options.enableTypeAssertions ||
            compiler.backend.rtiNeed.methodNeedsRti(element);
      }
    }
    closureMappingCache[element] = closureData;
    closureMappingCache[element.declaration] = closureData;
    if (closureData.callElement != null) {
      closureMappingCache[closureData.callElement] = closureData;
    }

    inNewScope(node, () {
      // If the method needs RTI, or checked mode is set, we need to
      // escape the potential type variables used in that closure.
      if (needsRti) {
        analyzeTypeVariables(element.type);
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

    if (element.isRegularParameter) {
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

  visitCatchBlock(CatchBlock node) {
    if (node.type != null) {
      // The "on T" clause may contain type variables.
      analyzeType(elements.getType(node.type));
    }
    if (node.formals != null) {
      node.formals.visitChildren(this);
    }
    node.block.accept(this);
  }

  visitAsyncForIn(AsyncForIn node) {
    // An `await for` loop is enclosed in an implicit try-finally.
    bool oldInTryStatement = inTryStatement;
    inTryStatement = true;
    visitLoop(node);
    inTryStatement = oldInTryStatement;
  }
}

/// A type variable as a local variable.
class TypeVariableLocal implements Local {
  final TypeVariableType typeVariable;
  final Entity executableContext;
  final MemberEntity memberContext;

  TypeVariableLocal(
      this.typeVariable, this.executableContext, this.memberContext);

  String get name => typeVariable.element.name;

  int get hashCode => typeVariable.hashCode;

  bool operator ==(other) {
    if (other is! TypeVariableLocal) return false;
    return typeVariable == other.typeVariable;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('type_variable_local(');
    if (memberContext.enclosingClass != null) {
      sb.write(memberContext.enclosingClass.name);
      sb.write('.');
    }
    sb.write(memberContext.name);
    sb.write('#');
    sb.write(name);
    sb.write(')');
    return sb.toString();
  }
}

///
/// Move the below classes to a JS model eventually.
///
abstract class JSEntity implements Entity {
  Entity get declaredEntity;
}

abstract class PrivatelyNamedJSEntity implements JSEntity {
  Entity get rootOfScope;
}
