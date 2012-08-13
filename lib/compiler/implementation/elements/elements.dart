// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('elements');

#import('dart:uri');

#import('../tree/tree.dart');
#import('../scanner/scannerlib.dart');
#import('../leg.dart');  // TODO(karlklose): we only need type.
#import('../util/util.dart');

class ElementCategory {
  /**
   * Represents things that we don't expect to find when looking in a
   * scope.
   */
  static final int NONE = 0;

  /** Field, parameter, or variable. */
  static final int VARIABLE = 1;

  /** Function, method, or foreign function. */
  static final int FUNCTION = 2;

  static final int CLASS = 4;

  static final int PREFIX = 8;

  /** Constructor or factory. */
  static final int FACTORY = 16;

  static final int ALIAS = 32;

  static final int SUPER = 64;

  /** Type variable */
  static final int TYPE_VARIABLE = 128;

  static final int IMPLIES_TYPE = CLASS | ALIAS | TYPE_VARIABLE;

  static final int IS_EXTENDABLE = CLASS | ALIAS;
}

class ElementKind {
  final String id;
  final int category;

  const ElementKind(String this.id, this.category);

  static final ElementKind VARIABLE =
    const ElementKind('variable', ElementCategory.VARIABLE);
  static final ElementKind PARAMETER =
    const ElementKind('parameter', ElementCategory.VARIABLE);
  // Parameters in constructors that directly initialize fields. For example:
  // [:A(this.field):].
  static final ElementKind FIELD_PARAMETER =
    const ElementKind('field_parameter', ElementCategory.VARIABLE);
  static final ElementKind FUNCTION =
    const ElementKind('function', ElementCategory.FUNCTION);
  static final ElementKind CLASS =
    const ElementKind('class', ElementCategory.CLASS);
  static final ElementKind FOREIGN =
    const ElementKind('foreign', ElementCategory.FUNCTION);
  static final ElementKind GENERATIVE_CONSTRUCTOR =
      const ElementKind('generative_constructor', ElementCategory.FACTORY);
  static final ElementKind FIELD =
    const ElementKind('field', ElementCategory.VARIABLE);
  static final ElementKind VARIABLE_LIST =
    const ElementKind('variable_list', ElementCategory.NONE);
  static final ElementKind FIELD_LIST =
    const ElementKind('field_list', ElementCategory.NONE);
  static final ElementKind GENERATIVE_CONSTRUCTOR_BODY =
      const ElementKind('generative_constructor_body', ElementCategory.NONE);
  static final ElementKind COMPILATION_UNIT =
      const ElementKind('compilation_unit', ElementCategory.NONE);
  static final ElementKind GETTER =
    const ElementKind('getter', ElementCategory.NONE);
  static final ElementKind SETTER =
    const ElementKind('setter', ElementCategory.NONE);
  static final ElementKind TYPE_VARIABLE =
    const ElementKind('type_variable', ElementCategory.TYPE_VARIABLE);
  static final ElementKind ABSTRACT_FIELD =
    const ElementKind('abstract_field', ElementCategory.VARIABLE);
  static final ElementKind LIBRARY =
    const ElementKind('library', ElementCategory.NONE);
  static final ElementKind PREFIX =
    const ElementKind('prefix', ElementCategory.PREFIX);
  static final ElementKind TYPEDEF =
    const ElementKind('typedef', ElementCategory.ALIAS);

  static final ElementKind STATEMENT =
    const ElementKind('statement', ElementCategory.NONE);
  static final ElementKind LABEL =
    const ElementKind('label', ElementCategory.NONE);
  static final ElementKind VOID =
    const ElementKind('void', ElementCategory.NONE);

  toString() => id;
}

class Element implements Hashable {
  final SourceString name;
  final ElementKind kind;
  final Element enclosingElement;
  Link<Node> metadata = const EmptyLink<Node>();
  Modifiers get modifiers() => null;

  Node parseNode(DiagnosticListener listener) {
    listener.cancel("Internal Error: $this.parseNode", token: position());
  }

  Type computeType(Compiler compiler) {
    compiler.internalError("$this.computeType.", token: position());
  }

  void addMetadata(Node node) {
    metadata = metadata.prepend(node);
  }

  bool isFunction() => kind === ElementKind.FUNCTION;
  bool isConstructor() => isFactoryConstructor() || isGenerativeConstructor();
  bool isClosure() => false;
  bool isMember() {
    // Check that this element is defined in the scope of a Class.
    Element enclosing = enclosingElement;
    // TODO(lrn): Skip any synthetic elements inserted, e.g.,
    // a compilation unit override.
    return enclosing !== null && enclosing.isClass();
  }
  bool isInstanceMember() => false;
  bool isFactoryConstructor() => modifiers !== null && modifiers.isFactory();
  bool isGenerativeConstructor() => kind === ElementKind.GENERATIVE_CONSTRUCTOR;
  bool isGenerativeConstructorBody() =>
      kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY;
  bool isCompilationUnit() {
    return kind === ElementKind.COMPILATION_UNIT ||
           kind === ElementKind.LIBRARY;
  }
  bool isClass() => kind === ElementKind.CLASS;
  bool isPrefix() => kind === ElementKind.PREFIX;
  bool isVariable() => kind === ElementKind.VARIABLE;
  bool isParameter() => kind === ElementKind.PARAMETER;
  bool isStatement() => kind === ElementKind.STATEMENT;
  bool isTypedef() => kind === ElementKind.TYPEDEF;
  bool isTypeVariable() => kind === ElementKind.TYPE_VARIABLE;
  bool isField() => kind === ElementKind.FIELD;
  bool isGetter() => kind === ElementKind.GETTER;
  bool isSetter() => kind === ElementKind.SETTER;
  bool isAccessor() => isGetter() || isSetter();
  bool isForeign() => kind === ElementKind.FOREIGN;
  bool isLibrary() => kind === ElementKind.LIBRARY;
  bool impliesType() => (kind.category & ElementCategory.IMPLIES_TYPE) != 0;
  bool isExtendable() => (kind.category & ElementCategory.IS_EXTENDABLE) != 0;

  // TODO(johnniwinther): This breaks for libraries (for which enclosing
  // elements are null) and is invalid for top level variable declarations for
  // which the enclosing element is a VariableDeclarations and not a compilation
  // unit.
  bool isTopLevel() => enclosingElement.isCompilationUnit();

  bool isAssignable() {
    if (modifiers != null && modifiers.isFinal()) return false;
    if (isFunction() || isGenerativeConstructor()) return false;
    return true;
  }

  Token position() => null;

  Token findMyName(Token token) {
    for (Token t = token; t.kind !== EOF_TOKEN; t = t.next) {
      if (t.value == name) return t;
    }
    return token;
  }

  Element(this.name, this.kind, this.enclosingElement) {
    assert(getLibrary() !== null);
  }

  // TODO(kasperl): This is a very bad hash code for the element and
  // there's no reason why two elements with the same name should have
  // the same hash code. Replace this with a simple id in the element?
  int hashCode() => name === null ? 0 : name.hashCode();

  CompilationUnitElement getCompilationUnit() {
    Element element = this;
    while (element !== null && !element.isCompilationUnit()) {
      element = element.enclosingElement;
    }
    return element;
  }

  LibraryElement getLibrary() {
    Element element = this;
    while (element.kind !== ElementKind.LIBRARY) {
      element = element.enclosingElement;
    }
    return element;
  }

  ClassElement getEnclosingClass() {
    for (Element e = this; e !== null; e = e.enclosingElement) {
      if (e.isClass()) return e;
    }
    return null;
  }

  Element getEnclosingMember() {
    for (Element e = this; e !== null; e = e.enclosingElement) {
      if (e.isMember()) return e;
    }
    return null;
  }

  Element getOutermostEnclosingMemberOrTopLevel() {
    // TODO(lrn): Why is this called "Outermost"?
    for (Element e = this; e !== null; e = e.enclosingElement) {
      if (e.isMember() || e.isTopLevel()) {
        return e;
      }
    }
    return null;
  }

  /**
   * Creates the scope for this element. The scope of the
   * enclosing element will be the parent scope.
   */
  Scope buildScope() => buildEnclosingScope();

  /**
   * Creates the scope for the enclosing element.
   */
  Scope buildEnclosingScope() => enclosingElement.buildScope();

  String toString() {
    // TODO(johnniwinther): Test for nullness of name, or make non-nullness an
    // invariant for all element types?
    var nameText = name !== null ? name.slowToString() : '?';
    if (enclosingElement !== null && !isTopLevel()) {
      String holderName = enclosingElement.name !== null
          ? enclosingElement.name.slowToString()
          : '${enclosingElement.kind}?';
      return '$kind($holderName#${nameText})';
    } else {
      return '$kind(${nameText})';
    }
  }

  bool _isNative = false;
  void setNative() { _isNative = true; }
  bool isNative() => _isNative;

  FunctionElement asFunctionElement() => null;
}

class ContainerElement extends Element {
  Link<Element> localMembers = const EmptyLink<Element>();

  ContainerElement(name, kind, enclosingElement)
    : super(name, kind, enclosingElement);

  void addMember(Element element, DiagnosticListener listener) {
    localMembers = localMembers.prepend(element);
  }
}

class ScopeContainerElement extends ContainerElement {
  final Map<SourceString, Element> localScope;

  ScopeContainerElement(name, kind, enclosingElement)
    : super(name, kind, enclosingElement),
      localScope = new Map<SourceString, Element>();

  void addMember(Element element, DiagnosticListener listener) {
    super.addMember(element, listener);
    addToScope(element, listener);
  }

  void addToScope(Element element, DiagnosticListener listener) {
    if (element.isAccessor()) {
      addGetterOrSetter(element, localScope[element.name], listener);
    } else {
      Element existing = localScope.putIfAbsent(element.name, () => element);
      if (existing !== element) {
        listener.cancel('duplicate definition', token: element.position());
        listener.cancel('existing definition', token: existing.position());
      }
    }
  }

  Element localLookup(SourceString elementName) {
    return localScope[elementName];
  }

  void addGetterOrSetter(Element element,
                         Element existing,
                         DiagnosticListener listener) {
    void reportError(Element other) {
      listener.cancel('duplicate definition of ${element.name.slowToString()}',
                      element: element);
      listener.cancel('existing definition', element: other);
    }

    if (existing != null) {
      if (existing.kind !== ElementKind.ABSTRACT_FIELD) {
        reportError(existing);
      } else {
        AbstractFieldElement field = existing;
        if (element.kind == ElementKind.GETTER) {
          if (field.getter != null && field.getter != element) {
            reportError(field.getter);
          }
          field.getter = element;
        } else {
          if (field.setter != null && field.setter != element) {
            reportError(field.setter);
          }
          field.setter = element;
        }
      }
    } else {
      AbstractFieldElement field = new AbstractFieldElement(element.name, this);
      if (element.kind == ElementKind.GETTER) {
        field.getter = element;
      } else {
        field.setter = element;
      }
      addMember(field, listener);
    }
  }
}



class CompilationUnitElement extends ContainerElement {
  final Script script;

  CompilationUnitElement(Script script, Element enclosing)
    : this.script = script,
      super(new SourceString(script.name),
            ElementKind.COMPILATION_UNIT,
            enclosing);

  void addMember(Element element, DiagnosticListener listener) {
    // Keep a list of top level members.
    super.addMember(element, listener);
    // Provide the member to the library to build scope.
    getLibrary().addMember(element, listener);
  }
}

class LibraryElement extends ScopeContainerElement {
  CompilationUnitElement entryCompilationUnit;
  Link<CompilationUnitElement> compilationUnits =
      const EmptyLink<CompilationUnitElement>();

  Link<ScriptTag> tags = const EmptyLink<ScriptTag>();
  ScriptTag libraryTag;
  bool canUseNative = false;
  LibraryElement patch = null;

  LibraryElement(Script script)
    : super(new SourceString(script.name), ElementKind.LIBRARY, null) {
    entryCompilationUnit = new CompilationUnitElement(script, this);
  }

  Uri get uri() => entryCompilationUnit.script.uri;

  bool get isPatched() => patch !== null;

  void addCompilationUnit(CompilationUnitElement element) {
    compilationUnits = compilationUnits.prepend(element);
  }

  void addTag(ScriptTag tag, DiagnosticListener listener) {
    tags = tags.prepend(tag);
  }

  /** Look up a top-level element in this library. The element could
    * potentially have been imported from another library. Returns
    * null if no such element exist. */
  Element find(SourceString elementName) {
    return localScope[elementName];
  }

  /** Look up a top-level element in this library, but only look for
    * non-imported elements. Returns null if no such element exist. */
  Element findLocal(SourceString elementName) {
    Element result = localScope[elementName];
    if (result === null || result.getLibrary() != this) return null;
    return result;
  }

  void forEachExport(f(Element element)) {
    localMembers.forEach((Element e) {
      if (e.kind !== ElementKind.PREFIX
          && e.kind !== ElementKind.FOREIGN
          && !e.name.isPrivate()) {
        f(e);
      }
    });
  }

  bool hasLibraryName() => libraryTag !== null;

  /**
   * Returns the library name (as defined by the #library tag) or for script
   * (which have no #library tag) the script file name. The latter case is used
   * to private 'library name' for scripts to use for instance in dartdoc.
   */
  String getLibraryOrScriptName() {
    if (libraryTag !== null) {
      return libraryTag.argument.dartString.slowToString();
    } else {
      // Use the file name as script name.
      String path = uri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }

  CompilationUnitElement getCompilationUnit() => entryCompilationUnit;

  Scope buildEnclosingScope() => new TopScope(this);
}

class PrefixElement extends Element {
  Map<SourceString, Element> imported;
  Token firstPosition;
  final CompilationUnitElement patchCompilationUnit;

  PrefixElement(SourceString prefix, Element enclosing, this.firstPosition,
                [this.patchCompilationUnit])
    : imported = new Map<SourceString, Element>(),
      super(prefix, ElementKind.PREFIX, enclosing);

  CompilationUnitElement getCompilationUnit() {
    if (patchCompilationUnit !== null) return patchCompilationUnit;
    return super.getCompilationUnit();
  }

  lookupLocalMember(SourceString memberName) => imported[memberName];

  Type computeType(Compiler compiler) => compiler.types.dynamicType;

  Token position() => firstPosition;
}

class TypedefElement extends Element implements TypeDeclarationElement {
  Type cachedType;
  Typedef cachedNode;

  TypedefElement(SourceString name, Element enclosing)
      : super(name, ElementKind.TYPEDEF, enclosing);

  Type computeType(Compiler compiler) {
    if (cachedType !== null) return cachedType;
    cachedType = compiler.computeFunctionType(
        this, compiler.resolveTypedef(this));
    return cachedType;
  }

  Link<Type> get typeVariables() => const EmptyLink<Type>();

  Scope buildScope() =>
      new TypeDeclarationScope(enclosingElement.buildScope(), this);
}

class VariableElement extends Element {
  final VariableListElement variables;
  Expression cachedNode; // The send or the identifier in the variables list.

  Modifiers get modifiers() => variables.modifiers;

  VariableElement(SourceString name,
                  VariableListElement this.variables,
                  ElementKind kind,
                  Element enclosing,
                  [Node node])
    : super(name, kind, enclosing), cachedNode = node;

  Node parseNode(DiagnosticListener listener) {
    if (cachedNode !== null) return cachedNode;
    VariableDefinitions definitions = variables.parseNode(listener);
    for (Link<Node> link = definitions.definitions.nodes;
         !link.isEmpty(); link = link.tail) {
      Expression initializedIdentifier = link.head;
      Identifier identifier = initializedIdentifier.asIdentifier();
      if (identifier === null) {
        identifier = initializedIdentifier.asSendSet().selector.asIdentifier();
      }
      if (name === identifier.source) {
        cachedNode = initializedIdentifier;
        return cachedNode;
      }
    }
    listener.cancel('internal error: could not find $name', node: variables);
  }

  Type computeType(Compiler compiler) {
    return variables.computeType(compiler);
  }

  Type get type() => variables.type;

  bool isInstanceMember() {
    return isMember() && !modifiers.isStatic();
  }

  // Note: cachedNode.getBeginToken() will not be correct in all
  // cases, for example, for function typed parameters.
  Token position() => findMyName(variables.position());
}

/**
 * Parameters in constructors that directly initialize fields. For example:
 * [:A(this.field):].
 */
class FieldParameterElement extends VariableElement {
  VariableElement fieldElement;

  FieldParameterElement(SourceString name,
                        this.fieldElement,
                        VariableListElement variables,
                        Element enclosing,
                        Node node)
      : super(name, variables, ElementKind.FIELD_PARAMETER, enclosing, node);
}

// This element represents a list of variable or field declaration.
// It contains the node, and the type. A [VariableElement] always
// references its [VariableListElement]. It forwards its
// [computeType] and [parseNode] methods to this element.
class VariableListElement extends Element {
  VariableDefinitions cachedNode;
  Type type;
  final Modifiers modifiers;

  /**
   * Function signature for a variable with a function type. The signature is
   * kept to provide full information about parameter names through the mirror
   * system.
   */
  FunctionSignature functionSignature;

  VariableListElement(ElementKind kind,
                      Modifiers this.modifiers,
                      Element enclosing)
    : super(null, kind, enclosing);

  VariableListElement.node(VariableDefinitions node,
                           ElementKind kind,
                           Element enclosing)
    : super(null, kind, enclosing),
      this.cachedNode = node,
      this.modifiers = node.modifiers;

  VariableDefinitions parseNode(DiagnosticListener listener) {
    return cachedNode;
  }

  Type computeType(Compiler compiler) {
    if (type != null) return type;
    VariableDefinitions node = parseNode(compiler);
    if (node.type !== null) {
      type = compiler.resolveTypeAnnotation(this, node.type);
    } else {
      // Is node.definitions exactly one FunctionExpression?
      Link<Node> link = node.definitions.nodes;
      if (!link.isEmpty() &&
          link.head.asFunctionExpression() !== null &&
          link.tail.isEmpty()) {
        FunctionExpression functionExpression = link.head;
        // We found exactly one FunctionExpression
        compiler.withCurrentElement(this, () {
          functionSignature =
              compiler.resolveFunctionExpression(this, functionExpression);
        });
        type = compiler.computeFunctionType(compiler.functionClass,
                                            functionSignature);
      } else {
        type = compiler.types.dynamicType;
      }
    }
    assert(type != null);
    return type;
  }

  Token position() => cachedNode.getBeginToken();
}

class ForeignElement extends Element {
  ForeignElement(SourceString name, ContainerElement enclosingElement)
    : super(name, ElementKind.FOREIGN, enclosingElement);

  Type computeType(Compiler compiler) {
    return compiler.types.dynamicType;
  }

  parseNode(DiagnosticListener listener) {
    throw "internal error: ForeignElement has no node";
  }
}

class AbstractFieldElement extends Element {
  FunctionElement getter;
  FunctionElement setter;

  AbstractFieldElement(SourceString name, Element enclosing)
      : super(name, ElementKind.ABSTRACT_FIELD, enclosing);

  Type computeType(Compiler compiler) {
    throw "internal error: AbstractFieldElement has no type";
  }

  Node parseNode(DiagnosticListener listener) {
    throw "internal error: AbstractFieldElement has no node";
  }

  position() {
    // The getter and setter may be defined in two different
    // compilation units.  However, we know that one of them is
    // non-null and defined in the same compilation unit as the
    // abstract element.
    //
    // We need to make sure that the position returned is relative to
    // the compilation unit of the abstract element.
    if (getter !== null && getter.enclosingElement === enclosingElement) {
      return getter.position();
    } else {
      return setter.position();
    }
  }

  Modifiers get modifiers() {
    // The resolver ensures that the flags match (ignoring abstract).
    if (getter !== null) {
      return new Modifiers.withFlags(
          getter.modifiers.nodes,
          getter.modifiers.flags | Modifiers.FLAG_ABSTRACT);
    } else {
      return new Modifiers.withFlags(
          setter.modifiers.nodes,
          setter.modifiers.flags | Modifiers.FLAG_ABSTRACT);
    }
  }
}

// TODO(johnniwinther): [FunctionSignature] should be merged with
// [FunctionType].
class FunctionSignature {
  Link<Element> requiredParameters;
  Link<Element> optionalParameters;
  Type returnType;
  int requiredParameterCount;
  int optionalParameterCount;
  FunctionSignature(this.requiredParameters,
                    this.optionalParameters,
                    this.requiredParameterCount,
                    this.optionalParameterCount,
                    this.returnType);

  void forEachParameter(void function(Element parameter)) {
    for (Link<Element> link = requiredParameters;
         !link.isEmpty();
         link = link.tail) {
      function(link.head);
    }
    for (Link<Element> link = optionalParameters;
         !link.isEmpty();
         link = link.tail) {
      function(link.head);
    }
  }

  int get parameterCount() => requiredParameterCount + optionalParameterCount;
}

class FunctionElement extends Element {
  FunctionExpression cachedNode;
  Type type;
  final Modifiers modifiers;

  FunctionSignature functionSignature;

  /**
   * A function declaration that should be parsed instead of the current one.
   * The patch should be parsed as if it was in the current scope. Its
   * signature must match this function's signature.
   */
  // TODO(lrn): Consider using [defaultImplementation] to store the patch.
  FunctionElement patch = null;

  /**
   * If this is an interface constructor, [defaultImplementation] will
   * changed by the resolver to point to the default
   * implementation. Otherwise, [:defaultImplementation === this:].
   */
  FunctionElement defaultImplementation;

  FunctionElement(SourceString name,
                  ElementKind kind,
                  Modifiers modifiers,
                  Element enclosing)
      : this.tooMuchOverloading(name, null, kind, modifiers, enclosing, null);

  FunctionElement.node(SourceString name,
                       FunctionExpression node,
                       ElementKind kind,
                       Modifiers modifiers,
                       Element enclosing)
      : this.tooMuchOverloading(name, node, kind, modifiers, enclosing, null);

  FunctionElement.from(SourceString name,
                       FunctionElement other,
                       Element enclosing)
      : this.tooMuchOverloading(name, other.cachedNode, other.kind,
                                other.modifiers, enclosing,
                                other.functionSignature);

  FunctionElement.tooMuchOverloading(SourceString name,
                                     FunctionExpression this.cachedNode,
                                     ElementKind kind,
                                     Modifiers this.modifiers,
                                     Element enclosing,
                                     FunctionSignature this.functionSignature)
      : super(name, kind, enclosing) {
    defaultImplementation = this;
  }

  CompilationUnitElement getCompilationUnit() {
    if (patch !== null) return patch.getCompilationUnit();
    return super.getCompilationUnit();
  }

  bool get isPatched() => patch !== null;

  /**
   * Applies a patch function to this function. The patch function's body
   * is used as replacement when parsing this function's body.
   * This method must not be called after the function has been parsed,
   * and it must be called at most once.
   */
  void setPatch(FunctionElement patchElement) {
    // Sanity checks. The caller must check these things before calling.
    assert(patch === null);
    assert(cachedNode === null);
    this.patch = patchElement;
    cachedNode = patchElement.cachedNode;
  }

  bool isInstanceMember() {
    return isMember()
           && kind != ElementKind.GENERATIVE_CONSTRUCTOR
           && !modifiers.isFactory()
           && !modifiers.isStatic();
  }

  FunctionSignature computeSignature(Compiler compiler) {
    if (functionSignature !== null) return functionSignature;
    compiler.withCurrentElement(this, () {
      functionSignature = compiler.resolveSignature(this);
    });
    return functionSignature;
  }

  int requiredParameterCount(Compiler compiler) {
    return computeSignature(compiler).requiredParameterCount;
  }

  int optionalParameterCount(Compiler compiler) {
    return computeSignature(compiler).optionalParameterCount;
  }

  int parameterCount(Compiler compiler) {
    return computeSignature(compiler).parameterCount;
  }

  FunctionType computeType(Compiler compiler) {
    if (type != null) return type;
    type = compiler.computeFunctionType(this, computeSignature(compiler));
    return type;
  }

  Node parseNode(DiagnosticListener listener) {
    if (cachedNode !== null) return cachedNode;
    if (patch === null) {
      if (modifiers.isExternal()) {
        listener.cancel("Compiling external function with no implementation.",
                        element: this);
      }
      return null;
    }
    cachedNode = patch.parseNode(listener);
    return cachedNode;
  }

  Token position() => cachedNode.getBeginToken();

  FunctionElement asFunctionElement() => this;
}

class ConstructorBodyElement extends FunctionElement {
  FunctionElement constructor;

  ConstructorBodyElement(FunctionElement constructor)
      : this.constructor = constructor,
        super(constructor.name,
              ElementKind.GENERATIVE_CONSTRUCTOR_BODY,
              null,
              constructor.enclosingElement) {
    functionSignature = constructor.functionSignature;
  }

  bool isInstanceMember() => true;

  FunctionType computeType(Compiler compiler) {
    compiler.reportFatalError('Internal error: $this.computeType', this);
  }

  Node parseNode(DiagnosticListener listener) {
    if (cachedNode !== null) return cachedNode;
    cachedNode = constructor.parseNode(listener);
    assert(cachedNode !== null);
    return cachedNode;
  }

  Token position() => constructor.position();
}

class SynthesizedConstructorElement extends FunctionElement {
  SynthesizedConstructorElement(Element enclosing)
    : super(enclosing.name, ElementKind.GENERATIVE_CONSTRUCTOR,
            null, enclosing);

  Token position() => enclosingElement.position();
}

class VoidElement extends Element {
  VoidElement(Element enclosing)
      : super(const SourceString('void'), ElementKind.VOID, enclosing);
  Type computeType(compiler) => compiler.types.voidType;
  Node parseNode(_) {
    throw 'internal error: parseNode on void';
  }
  bool impliesType() => true;
}

/**
 * [TypeDeclarationElement] defines the common interface for class/interface
 * declarations and typedefs.
 */
abstract class TypeDeclarationElement implements Element {
  // TODO(johnniwinther): This class should eventually be a mixin.

  /**
   * The type variables declared on this declaration. The type variables are not
   * available until the type of the element has been computed through
   * [computeType].
   */
  // TODO(johnniwinther): Find a (better) way to decouple [typeVariables] from
  // [Compiler].
  abstract Link<Type> get typeVariables();

  /**
   * Creates the type variables, their type and corresponding element, for the
   * type variables declared in [parameter] on [element]. The bounds of the type
   * variables are not set until [element] has been resolved.
   */
  static Link<Type> createTypeVariables(TypeDeclarationElement element,
                                        NodeList parameters) {
    if (parameters === null) return const EmptyLink<Type>();

    // Create types and elements for type variable.
    var arguments = new LinkBuilder<Type>();
    for (Link<Node> link = parameters.nodes; !link.isEmpty(); link = link.tail) {
      TypeVariable node = link.head;
      SourceString variableName = node.name.source;
      TypeVariableElement variableElement =
          new TypeVariableElement(variableName, element, node);
      TypeVariableType variableType = new TypeVariableType(variableElement);
      variableElement.type = variableType;
      arguments.addLast(variableType);
    }
    return arguments.toLink();
  }
}

class ClassElement extends ScopeContainerElement
    implements TypeDeclarationElement {
  final int id;
  InterfaceType type;
  Type supertype;
  Type defaultClass;
  Link<Type> interfaces = const EmptyLink<Type>();
  bool isResolved = false;
  bool isBeingResolved = false;
  // backendMembers are members that have been added by the backend to simplify
  // compilation. They don't have any user-side counter-part.
  Link<Element> backendMembers = const EmptyLink<Element>();

  Link<Type> allSupertypes;
  ClassElement patch = null;

  ClassElement(SourceString name, CompilationUnitElement enclosing, this.id)
    : super(name, ElementKind.CLASS, enclosing);

  InterfaceType computeType(compiler) {
    if (type == null) {
      ClassNode node = parseNode(compiler);
      Link<Type> parameters =
          TypeDeclarationElement.createTypeVariables(this, node.typeParameters);
      type = new InterfaceType(this, parameters);
    }
    return type;
  }

  Link<Type> get typeVariables() => type.arguments;

  ClassElement ensureResolved(Compiler compiler) {
    compiler.resolveClass(this);
    return this;
  }

  /**
   * Lookup local members in the class. This will ignore constructors.
   */
  Element lookupLocalMember(SourceString memberName) {
    var result = localLookup(memberName);
    if (result !== null && result.isConstructor()) return null;
    return result;
  }

  /**
  * Lookup super members for the class. This will ignore constructors.
   */
  Element lookupSuperMember(SourceString memberName) {
    bool isPrivate = memberName.isPrivate();
    for (ClassElement s = superclass; s != null; s = s.superclass) {
      // Private members from a different library are not visible.
      if (isPrivate && getLibrary() !== s.getLibrary()) continue;
      Element e = s.lookupLocalMember(memberName);
      if (e === null) continue;
      // Static members are not inherited.
      if (e.modifiers.isStatic()) continue;
      return e;
    }
    return null;
  }

  /**
   * Find the first member in the class chain with the given
   * [memberName]. This method is NOT to be used for resolving
   * unqualified sends because it does not implement the scoping
   * rules, where library scope comes before superclass scope.
   */
  Element lookupMember(SourceString memberName) {
    Element localMember = lookupLocalMember(memberName);
    return localMember === null ? lookupSuperMember(memberName) : localMember;
  }

  /**
   * Returns true if the [fieldMember] is shadowed by another field. The given
   * [fieldMember] must be a member of this class.
   *
   * This method also works if the [fieldMember] is private.
   */
  bool isShadowedByField(Element fieldMember) {
    assert(fieldMember.isField());
    // Note that we cannot use [lookupMember] or [lookupSuperMember] since it
    // will not do the right thing for private elements.
    ClassElement lookupClass = this;
    LibraryElement memberLibrary = fieldMember.getLibrary();
    if (fieldMember.name.isPrivate()) {
      // We find a super class in the same library as the field. This way the
      // lookupMember will work.
      while (lookupClass.getLibrary() != memberLibrary) {
        lookupClass = lookupClass.superclass;
      }
    }
    SourceString fieldName = fieldMember.name;
    while (true) {
      Element foundMember = lookupClass.lookupMember(fieldName);
      if (foundMember == fieldMember) return false;
      if (foundMember.isField()) return true;
      lookupClass = (foundMember.enclosingElement as ClassElement).superclass;
    }
  }

  Element lookupConstructor(SourceString className,
                            [SourceString constructorName =
                                 const SourceString(''),
                            Element noMatch(Element)]) {
    // TODO(karlklose): have a map from class names to a map of constructors
    //                  instead of creating the name here?
    SourceString normalizedName;
    if (constructorName !== const SourceString('')) {
      normalizedName = Elements.constructConstructorName(className,
                                                         constructorName);
    } else {
      normalizedName = className;
    }
    Element result = localLookup(normalizedName);
    if (result === null || !result.isConstructor()) {
      result = noMatch !== null ? noMatch(result) : null;
    }
    return result;
  }

  bool get hasConstructor() {
    // Search in scope to be sure we search patched constructors.
    for (var element in localScope.getValues()) {
      if (element.isConstructor()) return true;
    }
    return false;
  }

  Collection<Element> get constructors() {
    // TODO(ajohnsen): See if we can avoid this method at some point.
    List<Element> result = <Element>[];
    // Search in scope to be sure we search patched constructors.
    localScope.forEach((_, Element value) {
      if (value.isConstructor()) result.add(value);
    });
    return result;
  }

  /**
   * Returns the super class, if any.
   *
   * The returned element may not be resolved yet.
   */
  ClassElement get superclass() {
    assert(isResolved);
    return supertype === null ? null : supertype.element;
  }

  /**
   * Runs through all members of this class.
   *
   * The enclosing class is passed to the callback. This is useful when
   * [includeSuperMembers] is [:true:].
   */
  void forEachMember([void f(ClassElement enclosingClass, Element member),
                      includeBackendMembers = false,
                      includeSuperMembers = false]) {
    Set<ClassElement> seen = new Set<ClassElement>();
    ClassElement classElement = this;
    do {
      if (seen.contains(classElement)) return;
      seen.add(classElement);
      for (Element element in classElement.localMembers) {
        f(classElement, element);
      }
      if (includeBackendMembers) {
        for (Element element in classElement.backendMembers) {
          f(classElement, element);
        }
      }
      classElement = includeSuperMembers ? classElement.superclass : null;
    } while(classElement !== null);
  }

  /**
   * Runs through all instance-field members of this class.
   *
   * The enclosing class is passed to the callback. This is useful when
   * [includeSuperMembers] is [:true:].
   *
   * When [includeBackendMembers] and [includeSuperMembers] are both [:true:]
   * then the fields are visited in the same order as they need to be given
   * to the JavaScript constructor.
   */
  void forEachInstanceField([void f(ClassElement enclosingClass, Element field),
                             includeBackendMembers = false,
                             includeSuperMembers = false]) {
    // Filters so that [f] is only invoked with instance fields.
    void fieldFilter(ClassElement enclosingClass, Element member) {
      if (member.isInstanceMember() && member.kind == ElementKind.FIELD) {
        f(enclosingClass, member);
      }
    }

    forEachMember(fieldFilter, includeBackendMembers, includeSuperMembers);
  }

  bool implementsInterface(ClassElement intrface) {
    for (Type implementedInterfaceType in allSupertypes) {
      ClassElement implementedInterface = implementedInterfaceType.element;
      if (implementedInterface === intrface) {
        return true;
      }
    }
    return false;
  }

  /**
   * Returns true if [this] is a subclass of [cls].
   *
   * This method is not to be used for checking type hierarchy and
   * assignments, because it does not take parameterized types into
   * account.
   */
  bool isSubclassOf(ClassElement cls) {
    for (ClassElement s = this; s != null; s = s.superclass) {
      if (s === cls) return true;
    }
    return false;
  }

  bool isInterface() => false;
  bool isNative() => nativeName != null;
  SourceString nativeName;
  int hashCode() => id;

  Scope buildScope() =>
      new ClassScope(enclosingElement.buildScope(), this);
}

class Elements {
  static bool isLocal(Element element) {
    return ((element !== null)
            && !element.isInstanceMember()
            && !isStaticOrTopLevelField(element)
            && !isStaticOrTopLevelFunction(element)
            && (element.kind === ElementKind.VARIABLE ||
                element.kind === ElementKind.PARAMETER ||
                element.kind === ElementKind.FUNCTION));
  }

  static bool isInstanceField(Element element) {
    return (element !== null)
           && element.isInstanceMember()
           && (element.kind === ElementKind.FIELD
               || element.kind === ElementKind.GETTER
               || element.kind === ElementKind.SETTER);
  }

  static bool isStaticOrTopLevel(Element element) {
    return (element != null)
           && !element.isInstanceMember()
           && element.enclosingElement !== null
           && (element.enclosingElement.kind == ElementKind.CLASS ||
               element.enclosingElement.kind == ElementKind.COMPILATION_UNIT ||
               element.enclosingElement.kind == ElementKind.LIBRARY);
  }

  static bool isStaticOrTopLevelField(Element element) {
    return isStaticOrTopLevel(element)
           && (element.kind === ElementKind.FIELD
               || element.kind === ElementKind.GETTER
               || element.kind === ElementKind.SETTER);
  }

  static bool isStaticOrTopLevelFunction(Element element) {
    return isStaticOrTopLevel(element)
           && (element.kind === ElementKind.FUNCTION);
  }

  static bool isInstanceMethod(Element element) {
    return (element != null)
           && element.isInstanceMember()
           && (element.kind === ElementKind.FUNCTION);
  }

  static bool isInstanceSend(Send send, TreeElements elements) {
    Element element = elements[send];
    if (element === null) return !isClosureSend(send, element);
    return isInstanceMethod(element) || isInstanceField(element);
  }

  static bool isClosureSend(Send send, Element element) {
    if (send.isPropertyAccess) return false;
    if (send.receiver !== null) return false;
    // (o)() or foo()().
    if (element === null && send.selector.asIdentifier() === null) return true;
    if (element === null) return false;
    // foo() with foo a local or a parameter.
    return isLocal(element);
  }

  static SourceString constructConstructorName(SourceString receiver,
                                               SourceString selector) {
    String r = receiver.slowToString();
    String s = selector.slowToString();
    return new SourceString('$r\$$s');
  }

  static final SourceString OPERATOR_EQUALS =
      const SourceString(@'operator$eq');

  static SourceString constructOperatorName(SourceString receiver,
                                            SourceString selector,
                                            [bool isPrefix = false]) {
    String str = selector.stringValue;
    if (str === '==' || str === '!=') return OPERATOR_EQUALS;

    if (str === '~') str = 'not';
    else if (str === 'negate' || (str === '-' && isPrefix)) str = 'negate';
    else if (str === '[]') str = 'index';
    else if (str === '[]=') str = 'indexSet';
    else if (str === '*' || str === '*=') str = 'mul';
    else if (str === '/' || str === '/=') str = 'div';
    else if (str === '%' || str === '%=') str = 'mod';
    else if (str === '~/' || str === '~/=') str = 'tdiv';
    else if (str === '+' || str === '+=') str = 'add';
    else if (str === '-' || str === '-=') str = 'sub';
    else if (str === '<<' || str === '<<=') str = 'shl';
    else if (str === '>>' || str === '>>=') str = 'shr';
    else if (str === '>=') str = 'ge';
    else if (str === '>') str = 'gt';
    else if (str === '<=') str = 'le';
    else if (str === '<') str = 'lt';
    else if (str === '&' || str === '&=') str = 'and';
    else if (str === '^' || str === '^=') str = 'xor';
    else if (str === '|' || str === '|=') str = 'or';
    else {
      throw new Exception('Unhandled selector: ${selector.slowToString()}');
    }
    return new SourceString('$receiver\$$str');
  }

  static bool isStringSupertype(Element element, Compiler compiler) {
    LibraryElement coreLibrary = compiler.coreLibrary;
    return (element == coreLibrary.find(const SourceString('Comparable')))
        || (element == coreLibrary.find(const SourceString('Hashable')))
        || (element == coreLibrary.find(const SourceString('Pattern')));
  }

  static bool isListSupertype(Element element, Compiler compiler) {
    LibraryElement coreLibrary = compiler.coreLibrary;
    return (element == coreLibrary.find(const SourceString('Collection')))
        || (element == coreLibrary.find(const SourceString('Iterable')));
  }
}


class LabelElement extends Element {
  // We store the original label here so it can be returned by [parseNode].
  final Label label;
  final String labelName;
  final TargetElement target;
  bool isBreakTarget = false;
  bool isContinueTarget = false;
  LabelElement(Label label, this.labelName, this.target,
               Element enclosingElement)
      : this.label = label,
        super(label.identifier.source, ElementKind.LABEL, enclosingElement);

  void setBreakTarget() {
    isBreakTarget = true;
    target.isBreakTarget = true;
  }
  void setContinueTarget() {
    isContinueTarget = true;
    target.isContinueTarget = true;
  }

  bool get isTarget() => isBreakTarget || isContinueTarget;
  Node parseNode(DiagnosticListener l) => label;

  Token position() => label.getBeginToken();
  String toString() => "${labelName}:";
}

// Represents a reference to a statement or switch-case, either by label or the
// default target of a break or continue.
class TargetElement extends Element {
  final Node statement;
  final int nestingLevel;
  Link<LabelElement> labels = const EmptyLink<LabelElement>();
  bool isBreakTarget = false;
  bool isContinueTarget = false;

  TargetElement(this.statement, this.nestingLevel, Element enclosingElement)
      : super(const SourceString(""), ElementKind.STATEMENT, enclosingElement);
  bool get isTarget() => isBreakTarget || isContinueTarget;

  LabelElement addLabel(Label label, String labelName) {
    LabelElement result = new LabelElement(label, labelName, this,
                                           enclosingElement);
    labels = labels.prepend(result);
    return result;
  }

  Node parseNode(DiagnosticListener l) => statement;

  bool get isSwitch() => statement is SwitchStatement;

  Token position() => statement.getBeginToken();
  String toString() => statement.toString();
}

class TypeVariableElement extends Element {
  final Node cachedNode;
  TypeVariableType type;
  Type bound;

  TypeVariableElement(name, Element enclosing, this.cachedNode,
                      [this.type, this.bound])
    : super(name, ElementKind.TYPE_VARIABLE, enclosing);

  TypeVariableType computeType(compiler) => type;

  Node parseNode(compiler) => cachedNode;

  String toString() => "${enclosingElement.toString()}.${name.slowToString()}";
}
