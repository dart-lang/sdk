// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('elements');

#import('dart:uri');

#import('../tree/tree.dart');
#import('../scanner/scannerlib.dart');
#import('../leg.dart');  // TODO(karlklose): we only need type.
#import('../util/util.dart');

const int STATE_NOT_STARTED = 0;
const int STATE_STARTED = 1;
const int STATE_DONE = 2;

class ElementCategory {
  /**
   * Represents things that we don't expect to find when looking in a
   * scope.
   */
  static const int NONE = 0;

  /** Field, parameter, or variable. */
  static const int VARIABLE = 1;

  /** Function, method, or foreign function. */
  static const int FUNCTION = 2;

  static const int CLASS = 4;

  static const int PREFIX = 8;

  /** Constructor or factory. */
  static const int FACTORY = 16;

  static const int ALIAS = 32;

  static const int SUPER = 64;

  /** Type variable */
  static const int TYPE_VARIABLE = 128;

  static const int IMPLIES_TYPE = CLASS | ALIAS | TYPE_VARIABLE;

  static const int IS_EXTENDABLE = CLASS | ALIAS;
}

class ElementKind {
  final String id;
  final int category;

  const ElementKind(String this.id, this.category);

  static const ElementKind VARIABLE =
    const ElementKind('variable', ElementCategory.VARIABLE);
  static const ElementKind PARAMETER =
    const ElementKind('parameter', ElementCategory.VARIABLE);
  // Parameters in constructors that directly initialize fields. For example:
  // [:A(this.field):].
  static const ElementKind FIELD_PARAMETER =
    const ElementKind('field_parameter', ElementCategory.VARIABLE);
  static const ElementKind FUNCTION =
    const ElementKind('function', ElementCategory.FUNCTION);
  static const ElementKind CLASS =
    const ElementKind('class', ElementCategory.CLASS);
  static const ElementKind FOREIGN =
    const ElementKind('foreign', ElementCategory.FUNCTION);
  static const ElementKind GENERATIVE_CONSTRUCTOR =
      const ElementKind('generative_constructor', ElementCategory.FACTORY);
  static const ElementKind FIELD =
    const ElementKind('field', ElementCategory.VARIABLE);
  static const ElementKind VARIABLE_LIST =
    const ElementKind('variable_list', ElementCategory.NONE);
  static const ElementKind FIELD_LIST =
    const ElementKind('field_list', ElementCategory.NONE);
  static const ElementKind GENERATIVE_CONSTRUCTOR_BODY =
      const ElementKind('generative_constructor_body', ElementCategory.NONE);
  static const ElementKind COMPILATION_UNIT =
      const ElementKind('compilation_unit', ElementCategory.NONE);
  static const ElementKind GETTER =
    const ElementKind('getter', ElementCategory.NONE);
  static const ElementKind SETTER =
    const ElementKind('setter', ElementCategory.NONE);
  static const ElementKind TYPE_VARIABLE =
    const ElementKind('type_variable', ElementCategory.TYPE_VARIABLE);
  static const ElementKind ABSTRACT_FIELD =
    const ElementKind('abstract_field', ElementCategory.VARIABLE);
  static const ElementKind LIBRARY =
    const ElementKind('library', ElementCategory.NONE);
  static const ElementKind COMPILATION_UNIT_OVERRIDE =
    const ElementKind('compilation_unit_override', ElementCategory.NONE);
  static const ElementKind PREFIX =
    const ElementKind('prefix', ElementCategory.PREFIX);
  static const ElementKind TYPEDEF =
    const ElementKind('typedef', ElementCategory.ALIAS);

  static const ElementKind STATEMENT =
    const ElementKind('statement', ElementCategory.NONE);
  static const ElementKind LABEL =
    const ElementKind('label', ElementCategory.NONE);
  static const ElementKind VOID =
    const ElementKind('void', ElementCategory.NONE);

  toString() => id;
}

class Element implements Hashable {
  final SourceString name;
  final ElementKind kind;
  final Element enclosingElement;
  Link<MetadataAnnotation> metadata = const EmptyLink<MetadataAnnotation>();

  Element(this.name, this.kind, this.enclosingElement) {
    assert(getLibrary() !== null);
  }

  Modifiers get modifiers => null;

  Node parseNode(DiagnosticListener listener) {
    listener.cancel("Internal Error: $this.parseNode", token: position());
  }

  Type computeType(Compiler compiler) {
    compiler.internalError("$this.computeType.", token: position());
  }

  void addMetadata(MetadataAnnotation annotation) {
    assert(annotation.annotatedElement === null);
    annotation.annotatedElement = this;
    metadata = metadata.prepend(annotation);
  }

  bool isFunction() => kind === ElementKind.FUNCTION;
  bool isConstructor() => isFactoryConstructor() || isGenerativeConstructor();
  bool isClosure() => false;
  bool isMember() {
    // Check that this element is defined in the scope of a Class.
    Element enclosing = enclosingElement;
    if (enclosing !== null &&
        enclosing.kind === ElementKind.COMPILATION_UNIT_OVERRIDE) {
      enclosing = enclosing.enclosingElement;
    }
    return enclosing !== null && enclosing.isClass();
  }
  bool isInstanceMember() => false;
  bool isFactoryConstructor() => modifiers !== null && modifiers.isFactory();
  bool isGenerativeConstructor() => kind === ElementKind.GENERATIVE_CONSTRUCTOR;
  bool isGenerativeConstructorBody() =>
      kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY;
  bool isCompilationUnit() => kind === ElementKind.COMPILATION_UNIT;
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

  /** See [ErroneousElement] for documentation. */
  bool isErroneous() => false;

  // TODO(johnniwinther): This breaks for libraries (for which enclosing
  // elements are null) and is invalid for top level variable declarations for
  // which the enclosing element is a VariableDeclarations and not a compilation
  // unit.
  bool isTopLevel() {
    return enclosingElement !== null && enclosingElement.isCompilationUnit();
  }

  bool isAssignable() {
    if (modifiers != null && modifiers.isFinalOrConst()) return false;
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

  // TODO(kasperl): This is a very bad hash code for the element and
  // there's no reason why two elements with the same name should have
  // the same hash code. Replace this with a simple id in the element?
  int hashCode() => name === null ? 0 : name.hashCode();

  CompilationUnitElement getCompilationUnit() {
    Element element = this;
    while (element !== null && !element.isCompilationUnit()) {
      if (element is CompilationUnitOverrideElement) {
        CompilationUnitOverrideElement override = element;
        return override.compilationUnit;
      }
      if (element.isLibrary()) {
        LibraryElement library = element;
        return library.entryCompilationUnit;
      }
      element = element.enclosingElement;
      if (element is FunctionElement) {
        FunctionElement function = element;
        if (function.isPatched) {
          element = function.patch;
        }
      }
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

  Element getEnclosingClassOrCompilationUnit() {
   for (Element e = this; e !== null; e = e.enclosingElement) {
      if (e.isClass() || e.isCompilationUnit()) return e;
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

  Element cloneTo(Element enclosing, DiagnosticListener listener) {
    listener.cancel("Unimplemented cloneTo", element: this);
  }


  static bool isInvalid(Element e) => e == null || e.isErroneous();
}

/**
 * Represents an unresolvable or duplicated element.
 *
 * An [ErroneousElement] is used instead of [null] to provide additional
 * information about the error that caused the element to be unresolvable
 * or otherwise invalid.
 *
 * Accessing any field or calling any method defined on [ErroneousElement]
 * except [isErroneous] will currently throw an exception. (This might
 * change when we actually want more information on the erroneous element,
 * e.g., the name of the element we were trying to resolve.)
 *
 * Code that cannot not handle an [ErroneousElement] should use
 *   [: Element.isInvalid(element) :]
 * to check for unresolvable elements instead of
 *   [: element == null :].
 */
class ErroneousElement extends Element {
  final Message errorMessage;

  ErroneousElement(this.errorMessage, Element enclosing)
      : super(const SourceString('erroneous element'), null, enclosing);

  isErroneous() => true;

  unsupported() {
    throw 'unsupported operation on erroneous element';
  }

  SourceString get name => unsupported();
  ElementKind get kind => unsupported();
  Link<MetadataAnnotation> get metadata => unsupported();
}

class ErroneousFunctionElement extends ErroneousElement
                               implements FunctionElement {
  ErroneousFunctionElement(errorMessage, Element enclosing)
      : super(errorMessage, enclosing);

  get type => unsupported();
  get cachedNode => unsupported();
  get functionSignature => unsupported();
  get patch => unsupported();
  get defaultImplementation => unsupported();
  bool get isPatched => unsupported();
  setPatch(patch) => unsupported();
  computeSignature(compiler) => unsupported();
  requiredParameterCount(compiler) => unsupported();
  optionalParameterCount(compiler) => unsupported();
  parameterCount(copmiler) => unsupported();

  getLibrary() => enclosingElement.getLibrary();
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
      addAccessorToScope(element, localScope[element.name], listener);
    } else {
      Element existing = localScope.putIfAbsent(element.name, () => element);
      if (existing !== element) {
        // TODO(ahe): Do something similar to Resolver.reportErrorWithContext.
        listener.cancel('duplicate definition', token: element.position());
        listener.cancel('existing definition', token: existing.position());
      }
    }
  }

  Element localLookup(SourceString elementName) {
    return localScope[elementName];
  }

  /**
   * Adds a definition for an [accessor] (getter or setter) to a container.
   * The definition binds to an abstract field that can hold both a getter
   * and a setter.
   *
   * The abstract field is added once, for the first getter or setter, and
   * reused if the other one is also added.
   * The abstract field should not be treated as a proper member of the
   * container, it's simply a way to return two results for one lookup.
   * That is, the getter or setter does not have the abstract field as enclosing
   * element, they are enclosed by the class or compilation unit, as is the
   * abstract field.
   */
  void addAccessorToScope(Element accessor,
                          Element existing,
                          DiagnosticListener listener) {
    void reportError(Element other) {
      // TODO(ahe): Do something similar to Resolver.reportErrorWithContext.
      listener.cancel('duplicate definition of ${accessor.name.slowToString()}',
                      element: accessor);
      listener.cancel('existing definition', element: other);
    }

    if (existing != null) {
      if (existing.kind !== ElementKind.ABSTRACT_FIELD) {
        reportError(existing);
      } else {
        AbstractFieldElement field = existing;
        if (accessor.isGetter()) {
          if (field.getter != null && field.getter != accessor) {
            reportError(field.getter);
          }
          field.getter = accessor;
        } else {
          assert(accessor.isSetter());
          if (field.setter != null && field.setter != accessor) {
            reportError(field.setter);
          }
          field.setter = accessor;
        }
      }
    } else {
      Element container = accessor.getEnclosingClassOrCompilationUnit();
      AbstractFieldElement field =
          new AbstractFieldElement(accessor.name, container);
      if (accessor.isGetter()) {
        field.getter = accessor;
      } else {
        field.setter = accessor;
      }
      addToScope(field, listener);
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

class CompilationUnitOverrideElement extends Element {
  final CompilationUnitElement compilationUnit;

  CompilationUnitOverrideElement(CompilationUnitElement compilationUnit,
                                 Element enclosing)
      : this.compilationUnit = compilationUnit,
        super(compilationUnit.name,
              ElementKind.COMPILATION_UNIT_OVERRIDE,
              enclosing);
}

class LibraryElement extends ScopeContainerElement {
  final Uri uri;
  CompilationUnitElement entryCompilationUnit;
  Link<CompilationUnitElement> compilationUnits =
      const EmptyLink<CompilationUnitElement>();
  Link<ScriptTag> tags = const EmptyLink<ScriptTag>();
  ScriptTag libraryTag;
  bool canUseNative = false;
  LibraryElement patch = null;

  LibraryElement(Script script, [Uri uri])
    : this.uri = ((uri === null) ? script.uri : uri),
      super(new SourceString(script.name), ElementKind.LIBRARY, null) {
    entryCompilationUnit = new CompilationUnitElement(script, this);
  }


  bool get isPatched => patch !== null;

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
    localScope.forEach((_, Element e) {
      if (this === e.getLibrary()
          && e.kind !== ElementKind.PREFIX
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

  Scope buildEnclosingScope() => new TopScope(this);

  bool get isPlatformLibrary => uri.scheme == "dart";
}

class PrefixElement extends Element {
  Map<SourceString, Element> imported;
  Token firstPosition;

  PrefixElement(SourceString prefix, Element enclosing, this.firstPosition)
      : imported = new Map<SourceString, Element>(),
        super(prefix, ElementKind.PREFIX, enclosing);

  lookupLocalMember(SourceString memberName) => imported[memberName];

  Type computeType(Compiler compiler) => compiler.types.dynamicType;

  Token position() => firstPosition;

  PrefixElement cloneTo(Element enclosing, DiagnosticListener listener) {
    return new PrefixElement(name, enclosing, firstPosition);
  }
}

class TypedefElement extends Element implements TypeDeclarationElement {
  Typedef cachedNode;
  TypedefType cachedType;
  Type alias;

  bool isResolved = false;
  bool isBeingResolved = false;

  TypedefElement(SourceString name, Element enclosing)
      : super(name, ElementKind.TYPEDEF, enclosing);

  /**
   * Function signature for a typedef of a function type. The signature is
   * kept to provide full information about parameter names through the mirror
   * system.
   *
   * The [functionSignature] is not available until the typedef element has been
   * resolved.
   */
  FunctionSignature functionSignature;

  TypedefType computeType(Compiler compiler) {
    if (cachedType !== null) return cachedType;
    Typedef node = parseNode(compiler);
    Link<Type> parameters =
        TypeDeclarationElement.createTypeVariables(this, node.typeParameters);
    cachedType = new TypedefType(this, parameters);
    compiler.resolveTypedef(this);
    return cachedType;
  }

  Link<Type> get typeVariables => cachedType.typeArguments;

  Scope buildScope() =>
      new TypeDeclarationScope(enclosingElement.buildScope(), this);

  TypedefElement cloneTo(Element enclosing, DiagnosticListener listener) {
    TypedefElement result = new TypedefElement(name, enclosing);
    return result;
  }
}

class VariableElement extends Element {
  final VariableListElement variables;
  Expression cachedNode; // The send or the identifier in the variables list.

  Modifiers get modifiers => variables.modifiers;

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

  Type get type => variables.type;

  bool isInstanceMember() {
    return isMember() && !modifiers.isStatic();
  }

  // Note: cachedNode.getBeginToken() will not be correct in all
  // cases, for example, for function typed parameters.
  Token position() => findMyName(variables.position());

  VariableElement cloneTo(Element enclosing, DiagnosticListener listener) {
    VariableListElement clonedVariables =
        variables.cloneTo(enclosing, listener);
    VariableElement result = new VariableElement(
        name, clonedVariables, kind, enclosing, cachedNode);
    return result;
  }
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

  FieldParameterElement cloneTo(Element enclosing,
                                DiagnosticListener listener) {
    FieldParameterElement result =
      new FieldParameterElement(name, fieldElement,
                                variables.cloneTo(enclosing, listener),
                                enclosing, cachedNode);
    return result;
  }
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

  VariableListElement cloneTo(Element enclosing, DiagnosticListener listener) {
    VariableListElement result;
    if (cachedNode !== null) {
      result = new VariableListElement.node(cachedNode, kind, enclosing);
    } else {
      result = new VariableListElement(kind, modifiers, enclosing);
    }
    return result;
  }
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

  ForeignElement cloneTo(Element enclosing, DiagnosticListener listener) {
    ForeignElement result = new ForeignElement(name, enclosing);
    return result;
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
    // TODO(lrn): No we don't know that if the element from the same
    // compilation unit is patched.
    //
    // We need to make sure that the position returned is relative to
    // the compilation unit of the abstract element.
    if (getter !== null
        && getter.getCompilationUnit() === getCompilationUnit()) {
      return getter.position();
    } else {
      return setter.position();
    }
  }

  Modifiers get modifiers {
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

  AbstractFieldElement cloneTo(Element enclosing, DiagnosticListener listener) {
    listener.cancel("Cannot clone synthetic AbstractFieldElement",
                    element: this);
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

  int get parameterCount => requiredParameterCount + optionalParameterCount;
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

  bool get isPatched => patch !== null;

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
           && !isConstructor()
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

  FunctionElement cloneTo(Element enclosing, DiagnosticListener listener) {
    FunctionElement result = new FunctionElement.tooMuchOverloading(
        name, cachedNode, kind, modifiers, enclosing, functionSignature);
    result.defaultImplementation = defaultImplementation;
    result.type = type;
    return result;
  }
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

  ConstructorBodyElement cloneTo(Element enclosing,
                                 DiagnosticListener listener) {
    ConstructorBodyElement result =
      new ConstructorBodyElement(constructor.cloneTo(enclosing, listener));
    return result;
  }
}

class SynthesizedConstructorElement extends FunctionElement {
  SynthesizedConstructorElement(Element enclosing)
    : super(enclosing.name, ElementKind.GENERATIVE_CONSTRUCTOR,
            null, enclosing);

  Token position() => enclosingElement.position();

  SynthesizedConstructorElement cloneTo(Element enclosing,
                                        DiagnosticListener listener) {
    return new SynthesizedConstructorElement(enclosing);
  }
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
  abstract Link<Type> get typeVariables;

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
    for (Link link = parameters.nodes; !link.isEmpty(); link = link.tail) {
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
  Link<Type> interfaces;
  SourceString nativeName;
  int supertypeLoadState;
  int resolutionState;

  // backendMembers are members that have been added by the backend to simplify
  // compilation. They don't have any user-side counter-part.
  Link<Element> backendMembers = const EmptyLink<Element>();

  Link<Type> allSupertypes;

  // Lazily applied patch of class members.
  ClassElement patch = null;

  ClassElement(SourceString name, Element enclosing, this.id, int initialState)
    : supertypeLoadState = initialState,
      resolutionState = initialState,
      super(name, ElementKind.CLASS, enclosing);

  InterfaceType computeType(compiler) {
    if (type == null) {
      ClassNode node = parseNode(compiler);
      Link<Type> parameters =
          TypeDeclarationElement.createTypeVariables(this, node.typeParameters);
      type = new InterfaceType(this, parameters);
    }
    return type;
  }

  bool get isPatched => patch != null;

  Link<Type> get typeVariables => type.arguments;

  ClassElement ensureResolved(Compiler compiler) {
    if (resolutionState == STATE_NOT_STARTED) {
      compiler.resolver.resolveClass(this);
    }
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
    return lookupSuperMemberInLibrary(memberName, getLibrary());
  }

  /**
   * Lookup super members for the class that is accessible in [library].
   * This will ignore constructors.
   */
  Element lookupSuperMemberInLibrary(SourceString memberName,
                                     LibraryElement library) {
    bool isPrivate = memberName.isPrivate();
    for (ClassElement s = superclass; s != null; s = s.superclass) {
      // Private members from a different library are not visible.
      if (isPrivate && library !== s.getLibrary()) continue;
      Element e = s.lookupLocalMember(memberName);
      if (e === null) continue;
      // Static members are not inherited.
      if (e.modifiers.isStatic()) continue;
      return e;
    }
    if (isInterface()) {
      return lookupSuperInterfaceMember(memberName, getLibrary());
    }
    return null;
  }

  Element lookupSuperInterfaceMember(SourceString memberName,
                                     LibraryElement fromLibrary) {
    bool isPrivate = memberName.isPrivate();
    for (InterfaceType t in interfaces) {
      ClassElement cls = t.element;
      Element e = cls.lookupLocalMember(memberName);
      if (e === null) continue;
      // Private members from a different library are not visible.
      if (isPrivate && fromLibrary !== e.getLibrary()) continue;
      // Static members are not inherited.
      if (e.modifiers.isStatic()) continue;
      return e;
    }
    return null;
  }

  /**
   * Find the first member in the class chain with the given [selector].
   *
   * This method is NOT to be used for resolving
   * unqualified sends because it does not implement the scoping
   * rules, where library scope comes before superclass scope.
   */
  Element lookupSelector(Selector selector) {
    SourceString memberName = selector.name;
    LibraryElement library = selector.library;
    Element localMember = lookupLocalMember(memberName);
    if (localMember != null &&
        (!memberName.isPrivate() || getLibrary() == library)) {
      return localMember;
    }
    return lookupSuperMemberInLibrary(memberName, library);
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
      lookupClass = foundMember.getEnclosingClass().superclass;
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

  bool get hasConstructor {
    // Search in scope to be sure we search patched constructors.
    for (var element in localScope.getValues()) {
      if (element.isConstructor()) return true;
    }
    return false;
  }

  Link<Element> get constructors {
    // TODO(ajohnsen): See if we can avoid this method at some point.
    Link<Element> result = const EmptyLink<Element>();
    for (Element member in localMembers) {
      if (member.isConstructor()) result = result.prepend(member);
    }
    return result;
  }

  /**
   * Returns the super class, if any.
   *
   * The returned element may not be resolved yet.
   */
  ClassElement get superclass {
    assert(supertypeLoadState == STATE_DONE);
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

      // Iterate through the members in textual order, which requires
      // to reverse the data structure [localMembers] we created.
      // Textual order may be important for certain operations, for
      // example when emitting the initializers of fields.
      for (Element element in classElement.localMembers.reverse()) {
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
  int hashCode() => id;

  Scope buildScope() =>
      new ClassScope(enclosingElement.buildScope(), this);

  ClassElement cloneTo(Element enclosing, DiagnosticListener listener) {
    listener.internalErrorOnElement(this, 'unsupported operation');
  }

  Link<Type> get allSupertypesAndSelf {
    return allSupertypes.prepend(new InterfaceType(this));
  }
}

class Elements {
  static bool isLocal(Element element) {
    return !Element.isInvalid(element)
            && !element.isInstanceMember()
            && !isStaticOrTopLevelField(element)
            && !isStaticOrTopLevelFunction(element)
            && (element.kind === ElementKind.VARIABLE ||
                element.kind === ElementKind.PARAMETER ||
                element.kind === ElementKind.FUNCTION);
  }

  static bool isInstanceField(Element element) {
    return !Element.isInvalid(element)
           && element.isInstanceMember()
           && (element.kind === ElementKind.FIELD
               || element.kind === ElementKind.GETTER
               || element.kind === ElementKind.SETTER);
  }

  static bool isStaticOrTopLevel(Element element) {
    // TODO(ager): This should not be necessary when patch support has
    // been reworked.
    if (!Element.isInvalid(element)
        && element.modifiers != null
        && element.modifiers.isStatic()) {
      return true;
    }
    return !Element.isInvalid(element)
           && !element.isInstanceMember()
           && !element.isPrefix()
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
    return !Element.isInvalid(element)
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

  static const SourceString OPERATOR_EQUALS =
      const SourceString(@'operator$eq');

  static SourceString constructOperatorName(SourceString selector,
                                            bool isUnary) {
    String str = selector.stringValue;
    if (str === '==' || str === '!=') return OPERATOR_EQUALS;

    if (str === '~') {
      str = 'not';
    } else if (str === '-' && isUnary) {
      // TODO(ahe): Return something like 'unary -'.
      return const SourceString('negate');
    } else if (str === '[]') {
      str = 'index';
    } else if (str === '[]=') {
      str = 'indexSet';
    } else if (str === '*' || str === '*=') {
      str = 'mul';
    } else if (str === '/' || str === '/=') {
      str = 'div';
    } else if (str === '%' || str === '%=') {
      str = 'mod';
    } else if (str === '~/' || str === '~/=') {
      str = 'tdiv';
    } else if (str === '+' || str === '+=') {
      str = 'add';
    } else if (str === '-' || str === '-=') {
      str = 'sub';
    } else if (str === '<<' || str === '<<=') {
      str = 'shl';
    } else if (str === '>>' || str === '>>=') {
      str = 'shr';
    } else if (str === '>=') {
      str = 'ge';
    } else if (str === '>') {
      str = 'gt';
    } else if (str === '<=') {
      str = 'le';
    } else if (str === '<') {
      str = 'lt';
    } else if (str === '&' || str === '&=') {
      str = 'and';
    } else if (str === '^' || str === '^=') {
      str = 'xor';
    } else if (str === '|' || str === '|=') {
      str = 'or';
    } else if (selector == const SourceString('negate')) {
      // TODO(ahe): Remove this case: Legacy support for pre-0.11 spec.
      return selector;
    } else {
      throw new Exception('Unhandled selector: ${selector.slowToString()}');
    }
    return new SourceString('operator\$$str');
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

  bool get isTarget => isBreakTarget || isContinueTarget;
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
  bool get isTarget => isBreakTarget || isContinueTarget;

  LabelElement addLabel(Label label, String labelName) {
    LabelElement result = new LabelElement(label, labelName, this,
                                           enclosingElement);
    labels = labels.prepend(result);
    return result;
  }

  Node parseNode(DiagnosticListener l) => statement;

  bool get isSwitch => statement is SwitchStatement;

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

  Token position() => cachedNode.getBeginToken();

  TypeVariableElement cloneTo(Element enclosing, DiagnosticListener listener) {
    TypeVariableElement result =
        new TypeVariableElement(name, enclosing, cachedNode, type, bound);
    return result;
  }
}

/**
 * A single metadata annotation.
 *
 * For example, consider:
 *
 * [:
 * class Data {
 *   const Data();
 * }
 *
 * const data = const Data();
 *
 * @data
 * class Foo {}
 *
 * @data @data
 * class Bar {}
 * :]
 *
 * In this example, there are three instances of [MetadataAnnotation]
 * and they correspond each to a location in the source code where
 * there is an at-sign, '@'. The [value] of each of these instances
 * are the same compile-time constant, [: const Data() :].
 *
 * The mirror system does not have a concept matching this class.
 */
class MetadataAnnotation {
  /**
   * The compile-time constant which this annotation resolves to.
   * In the mirror system, this would be an object mirror.
   */
  abstract Constant get value;
  Element annotatedElement;
  int resolutionState;

  MetadataAnnotation([this.resolutionState = STATE_NOT_STARTED]);

  MetadataAnnotation ensureResolved(Compiler compiler) {
    if (resolutionState == STATE_NOT_STARTED) {
      compiler.resolver.resolveMetadataAnnotation(this);
    }
    return this;
  }

  String toString() => 'MetadataAnnotation($value, $resolutionState)';
}
