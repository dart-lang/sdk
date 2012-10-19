// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library elements;

import 'dart:uri';

// TODO(ahe): Rename prefix to 'api' when VM bug is fixed.
import '../../compiler.dart' as api_e;
import '../tree/tree.dart';
import '../dart2jslib.dart' show invariant,
                                 InterfaceType,
                                 DartType,
                                 TypeVariableType,
                                 TypedefType,
                                 MessageKind,
                                 DiagnosticListener,
                                 Script,
                                 FunctionType,
                                 SourceString,
                                 Selector,
                                 Constant,
                                 Compiler;
import '../scanner/scannerlib.dart' show Token, EOF_TOKEN;
import '../util/util.dart';
import '../resolution/resolution.dart';

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

  static const ElementKind ERROR =
      const ElementKind('error', ElementCategory.NONE);

  toString() => id;
}

class Element implements Spannable {
  final SourceString name;
  final ElementKind kind;
  final Element enclosingElement;
  Link<MetadataAnnotation> metadata = const Link<MetadataAnnotation>();

  Element(this.name, this.kind, this.enclosingElement) {
    assert(isErroneous() || getImplementationLibrary() != null);
  }

  Modifiers get modifiers => Modifiers.EMPTY;

  Node parseNode(DiagnosticListener listener) {
    listener.internalErrorOnElement(this, 'not implemented');
  }

  DartType computeType(Compiler compiler) {
    compiler.internalError("$this.computeType.", token: position());
  }

  void addMetadata(MetadataAnnotation annotation) {
    assert(annotation.annotatedElement == null);
    annotation.annotatedElement = this;
    metadata = metadata.prepend(annotation);
  }

  bool isFunction() => identical(kind, ElementKind.FUNCTION);
  bool isConstructor() => isFactoryConstructor() || isGenerativeConstructor();
  bool isClosure() => false;
  bool isMember() {
    // Check that this element is defined in the scope of a Class.
    return enclosingElement != null && enclosingElement.isClass();
  }
  bool isInstanceMember() => false;
  bool isFactoryConstructor() => modifiers.isFactory();
  bool isGenerativeConstructor() =>
      identical(kind, ElementKind.GENERATIVE_CONSTRUCTOR);
  bool isGenerativeConstructorBody() =>
      identical(kind, ElementKind.GENERATIVE_CONSTRUCTOR_BODY);
  bool isCompilationUnit() => identical(kind, ElementKind.COMPILATION_UNIT);
  bool isClass() => identical(kind, ElementKind.CLASS);
  bool isPrefix() => identical(kind, ElementKind.PREFIX);
  bool isVariable() => identical(kind, ElementKind.VARIABLE);
  bool isParameter() => identical(kind, ElementKind.PARAMETER);
  bool isStatement() => identical(kind, ElementKind.STATEMENT);
  bool isTypedef() => identical(kind, ElementKind.TYPEDEF);
  bool isTypeVariable() => identical(kind, ElementKind.TYPE_VARIABLE);
  bool isField() => identical(kind, ElementKind.FIELD);
  bool isAbstractField() => identical(kind, ElementKind.ABSTRACT_FIELD);
  bool isGetter() => identical(kind, ElementKind.GETTER);
  bool isSetter() => identical(kind, ElementKind.SETTER);
  bool isAccessor() => isGetter() || isSetter();
  bool isForeign() => identical(kind, ElementKind.FOREIGN);
  bool isLibrary() => identical(kind, ElementKind.LIBRARY);
  bool impliesType() => (kind.category & ElementCategory.IMPLIES_TYPE) != 0;
  bool isExtendable() => (kind.category & ElementCategory.IS_EXTENDABLE) != 0;

  /** See [ErroneousElement] for documentation. */
  bool isErroneous() => false;

  /**
   * Is [:true:] if this element has a corresponding patch.
   *
   * If [:true:] this element has a non-null [patch] field.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  bool get isPatched => false;

  /**
   * Is [:true:] if this element is a patch.
   *
   * If [:true:] this element has a non-null [origin] field.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  bool get isPatch => false;

  /**
   * Is [:true:] if this element defines the implementation for the entity of
   * this element.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  bool get isImplementation => !isPatched;

  /**
   * Is [:true:] if this element introduces the entity of this element.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  bool get isDeclaration => !isPatch;

  /**
   * Returns the element which defines the implementation for the entity of this
   * element.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  Element get implementation => isPatched ? patch : this;

  /**
   * Returns the element which introduces the entity of this element.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  Element get declaration => isPatch ? origin : this;

  Element get patch {
    throw new UnsupportedOperationException('patch is not supported on $this');
  }

  Element get origin {
    throw new UnsupportedOperationException('origin is not supported on $this');
  }

  // TODO(johnniwinther): This breaks for libraries (for which enclosing
  // elements are null) and is invalid for top level variable declarations for
  // which the enclosing element is a VariableDeclarations and not a compilation
  // unit.
  bool isTopLevel() {
    return enclosingElement != null && enclosingElement.isCompilationUnit();
  }

  bool isAssignable() {
    if (modifiers.isFinalOrConst()) return false;
    if (isFunction() || isGenerativeConstructor()) return false;
    return true;
  }

  Token position() => null;

  Token findMyName(Token token) {
    for (Token t = token; !identical(t.kind, EOF_TOKEN); t = t.next) {
      if (t.value == name) return t;
    }
    return token;
  }

  // TODO(kasperl): This is a very bad hash code for the element and
  // there's no reason why two elements with the same name should have
  // the same hash code. Replace this with a simple id in the element?
  int hashCode() => name == null ? 0 : name.hashCode();

  CompilationUnitElement getCompilationUnit() {
    Element element = this;
    while (!element.isCompilationUnit()) {
      element = element.enclosingElement;
    }
    return element;
  }

  LibraryElement getLibrary() => enclosingElement.getLibrary();

  LibraryElement getImplementationLibrary() {
    Element element = this;
    while (!identical(element.kind, ElementKind.LIBRARY)) {
      element = element.enclosingElement;
    }
    return element;
  }

  ClassElement getEnclosingClass() {
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClass()) return e;
    }
    return null;
  }

  Element getEnclosingClassOrCompilationUnit() {
   for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClass() || e.isCompilationUnit()) return e;
    }
    return null;
  }

  Element getEnclosingMember() {
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isMember()) return e;
    }
    return null;
  }

  Element getOutermostEnclosingMemberOrTopLevel() {
    // TODO(lrn): Why is this called "Outermost"?
    for (Element e = this; e != null; e = e.enclosingElement) {
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
  // TODO(johnniwinther): Clean up scope generation. Possibly generation scopes
  // externally.
  Scope buildScope({bool patchScope: false}) =>
      buildEnclosingScope(patchScope: patchScope);

  /**
   * Creates the scope for the enclosing element.
   */
  // TODO(johnniwinther): Remove buildEnclosingScope as part of scope clean-up.
  Scope buildEnclosingScope({bool patchScope: false}) =>
      enclosingElement.buildScope(patchScope: patchScope);

  String toString() {
    // TODO(johnniwinther): Test for nullness of name, or make non-nullness an
    // invariant for all element types?
    var nameText = name != null ? name.slowToString() : '?';
    if (enclosingElement != null && !isTopLevel()) {
      String holderName = enclosingElement.name != null
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
  final MessageKind messageKind;
  final List messageArguments;
  final SourceString targetName;

  ErroneousElement(this.messageKind, this.messageArguments,
                   this.targetName, Element enclosing)
      : super(const SourceString('erroneous element'),
              ElementKind.ERROR, enclosing);

  isErroneous() => true;

  unsupported() {
    throw 'unsupported operation on erroneous element';
  }

  SourceString get name => unsupported();
  Link<MetadataAnnotation> get metadata => unsupported();

  getLibrary() => enclosingElement.getLibrary();
}

class ErroneousFunctionElement extends ErroneousElement
                               implements FunctionElement {
  ErroneousFunctionElement(MessageKind messageKind, List messageArguments,
                           SourceString targetName, Element enclosing)
      : super(messageKind, messageArguments, targetName, enclosing);

  get type => unsupported();
  get cachedNode => unsupported();
  get functionSignature => unsupported();
  get patch => unsupported();
  get origin => unsupported();
  get defaultImplementation => unsupported();
  bool get isPatched => unsupported();
  bool get isPatch => unsupported();
  setPatch(patch) => unsupported();
  computeSignature(compiler) => unsupported();
  requiredParameterCount(compiler) => unsupported();
  optionalParameterCount(compiler) => unsupported();
  parameterCount(copmiler) => unsupported();
}

class ContainerElement extends Element {
  Link<Element> localMembers = const Link<Element>();

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
      if (!identical(existing, element)) {
        // TODO(ahe): Do something similar to Resolver.reportErrorWithContext.
        listener.cancel('duplicate definition', token: element.position());
        listener.cancel('existing definition', token: existing.position());
      }
    }
  }

  Element localLookup(SourceString elementName) {
    Element result = localScope[elementName];
    if (result == null && isPatch) {
      ScopeContainerElement element = origin;
      result = element.localScope[elementName];
    }
    return result;
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
      if (!identical(existing.kind, ElementKind.ABSTRACT_FIELD)) {
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
  PartOf partTag;

  CompilationUnitElement(Script script, LibraryElement library)
    : this.script = script,
      super(new SourceString(script.name),
            ElementKind.COMPILATION_UNIT,
            library) {
    library.addCompilationUnit(this);
  }

  void addMember(Element element, DiagnosticListener listener) {
    // Keep a list of top level members.
    super.addMember(element, listener);
    // Provide the member to the library to build scope.
    if (enclosingElement.isPatch) {
      getImplementationLibrary().addMember(element, listener);
    } else {
      getLibrary().addMember(element, listener);
    }
  }

  void setPartOf(PartOf tag, DiagnosticListener listener) {
    LibraryElement library = enclosingElement;
    if (library.entryCompilationUnit == this) {
      listener.reportMessage(
          listener.spanFromNode(tag),
          MessageKind.ILLEGAL_DIRECTIVE.error(),
          api_e.Diagnostic.WARNING);
      return;
    }
    if (!localMembers.isEmpty()) {
      listener.reportMessage(
          listener.spanFromNode(tag),
          MessageKind.BEFORE_TOP_LEVEL.error(),
          api_e.Diagnostic.ERROR);
      return;
    }
    if (partTag != null) {
      listener.reportMessage(
          listener.spanFromNode(tag),
          MessageKind.DUPLICATED_PART_OF.error(),
          api_e.Diagnostic.WARNING);
      return;
    }
    partTag = tag;
    LibraryName libraryTag = getLibrary().libraryTag;
    if (libraryTag != null) {
      String expectedName = tag.name.toString();
      String actualName = libraryTag.name.toString();
      if (expectedName != actualName) {
        listener.reportMessage(
            listener.spanFromNode(tag.name),
            MessageKind.LIBRARY_NAME_MISMATCH.error([expectedName]),
            api_e.Diagnostic.WARNING);
      }
    }
  }
}

class LibraryElement extends ScopeContainerElement {
  final Uri uri;
  CompilationUnitElement entryCompilationUnit;
  Link<CompilationUnitElement> compilationUnits =
      const Link<CompilationUnitElement>();
  Link<LibraryTag> tags = const Link<LibraryTag>();
  LibraryName libraryTag;
  bool canUseNative = false;

  /**
   * If this library is patched, [patch] points to the patch library.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  LibraryElement patch = null;

  /**
   * If this is a patch library, [origin] points to the origin library.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  final LibraryElement origin;

  /**
   * Map for elements imported through import declarations.
   *
   * Addition to the map is performed by [addImport]. Lookup is done trough
   * [find].
   */
  final Map<SourceString, Element> importScope;

  /**
   * Link for elements exported either through export declarations or through
   * declaration. This field should not be accessed directly but instead through
   * the [exports] getter.
   *
   * [LibraryDependencyHandler] sets this field through [setExports] when the
   * library is loaded.
   */
  Link<Element> slotForExports;

  LibraryElement(Script script, [Uri uri, LibraryElement this.origin])
    : this.uri = ((uri == null) ? script.uri : uri),
      importScope = new Map<SourceString, Element>(),
      super(new SourceString(script.name), ElementKind.LIBRARY, null) {
    entryCompilationUnit = new CompilationUnitElement(script, this);
    if (isPatch) {
      origin.patch = this;
    }
  }

  bool get isPatched => patch != null;
  bool get isPatch => origin != null;

  LibraryElement get declaration => super.declaration;
  LibraryElement get implementation => super.implementation;

  CompilationUnitElement getCompilationUnit() => entryCompilationUnit;

  void addCompilationUnit(CompilationUnitElement element) {
    compilationUnits = compilationUnits.prepend(element);
  }

  void addTag(LibraryTag tag, DiagnosticListener listener) {
    tags = tags.prepend(tag);
  }

  /**
   * Adds [element] to the import scope of this library.
   *
   * If an element by the same name is already in the imported scope, an
   * [ErroneousElement] will be put in the imported scope, allowing for the
   * detection of ambiguous uses of imported names.
   */
  void addImport(Element element, DiagnosticListener listener) {
    Element existing = importScope[element.name];
    if (existing != null) {
      if (!existing.isErroneous()) {
        // TODO(johnniwinther): Provide access to both the new and existing
        // elements.
        importScope[element.name] = new ErroneousElement(
            MessageKind.DUPLICATE_IMPORT,
            [element.name], element.name, this);
      }
    } else {
      importScope[element.name] = element;
    }
  }

  /**
   * Returns [:true:] if the export scope has already been computed for this
   * library.
   */
  bool get exportsHandled => slotForExports != null;

  Link<Element> get exports {
    assert(invariant(this, exportsHandled,
                     message: 'Exports not handled on $this'));
    return slotForExports;
  }

  /**
   * Sets the export scope of this library. This method can only be called once.
   */
  void setExports(Iterable<Element> exportedElements) {
    assert(invariant(this, !exportsHandled,
        message: 'Exports already set to $slotForExports on $this'));
    assert(invariant(this, exportedElements != null));
    var builder = new LinkBuilder<Element>();
    for (Element export in exportedElements) {
      builder.addLast(export);
    }
    slotForExports = builder.toLink();
  }

  LibraryElement getLibrary() => isPatch ? origin : this;

  /**
   * Look up a top-level element in this library. The element could
   * potentially have been imported from another library. Returns
   * null if no such element exist and an [ErroneousElement] if multiple
   * elements have been imported.
   */
  Element find(SourceString elementName) {
    Element result = localScope[elementName];
    if (result == null) {
      result = importScope[elementName];
    }
    return result;
  }

  /** Look up a top-level element in this library, but only look for
    * non-imported elements. Returns null if no such element exist. */
  Element findLocal(SourceString elementName) {
    // TODO(johnniwinther): How to handle injected elements in the patch
    // library?
    Element result = localScope[elementName];
    if (result == null || result.getLibrary() != this) return null;
    return result;
  }

  void forEachExport(f(Element element)) {
    exports.forEach((Element e) => f(e));
  }

  void forEachLocalMember(f(Element element)) {
    if (isPatch) {
      // Patch libraries traverse both origin and injected members.
      origin.localMembers.forEach(f);

      void filterPatch(Element element) {
        if (!element.isPatch) {
          // Do not traverse the patch members.
          f(element);
        }
      }
      localMembers.forEach(filterPatch);
    } else {
      localMembers.forEach(f);
    }
  }

  bool hasLibraryName() => libraryTag != null;

  /**
   * Returns the library name (as defined by the #library tag) or for script
   * (which have no #library tag) the script file name. The latter case is used
   * to private 'library name' for scripts to use for instance in dartdoc.
   */
  String getLibraryOrScriptName() {
    if (libraryTag != null) {
      return libraryTag.name.toString();
    } else {
      // Use the file name as script name.
      String path = uri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }

  // TODO(johnniwinther): Rewrite to avoid the optional argument.
  Scope buildEnclosingScope({bool patchScope: false}) {
    if (origin != null) {
      return new PatchLibraryScope(origin, this);
    } if (patchScope && patch != null) {
      return new PatchLibraryScope(this, patch);
    } else {
      return new TopScope(this);
    }
  }

  bool get isPlatformLibrary => uri.scheme == "dart";

  String toString() {
    if (origin != null) {
      return 'patch library(${getLibraryOrScriptName()})';
    } else if (patch != null) {
      return 'origin library(${getLibraryOrScriptName()})';
    } else {
      return 'library(${getLibraryOrScriptName()})';
    }
  }
}

class PrefixElement extends Element {
  Map<SourceString, Element> imported;
  Token firstPosition;

  PrefixElement(SourceString prefix, Element enclosing, this.firstPosition)
      : imported = new Map<SourceString, Element>(),
        super(prefix, ElementKind.PREFIX, enclosing);

  lookupLocalMember(SourceString memberName) => imported[memberName];

  DartType computeType(Compiler compiler) => compiler.types.dynamicType;

  Token position() => firstPosition;
}

class TypedefElement extends Element implements TypeDeclarationElement {
  Typedef cachedNode;
  TypedefType cachedType;
  DartType alias;

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
    if (cachedType != null) return cachedType;
    Typedef node = parseNode(compiler);
    Link<DartType> parameters =
        TypeDeclarationElement.createTypeVariables(this, node.typeParameters);
    cachedType = new TypedefType(this, parameters);
    compiler.resolveTypedef(this);
    return cachedType;
  }

  Link<DartType> get typeVariables => cachedType.typeArguments;

  // TODO(johnniwinther): Rewrite to avoid the optional argument.
  Scope buildScope({bool patchScope: false}) {
    return new TypeDeclarationScope(
      enclosingElement.buildScope(patchScope: patchScope), this);
  }
}

class VariableElement extends Element {
  final VariableListElement variables;
  Expression cachedNode; // The send or the identifier in the variables list.

  Modifiers get modifiers => variables.modifiers;

  VariableElement(SourceString name,
                  VariableListElement variables,
                  ElementKind kind,
                  this.cachedNode)
    : this.variables = variables,
      super(name, kind, variables.enclosingElement);

  Node parseNode(DiagnosticListener listener) {
    if (cachedNode != null) return cachedNode;
    VariableDefinitions definitions = variables.parseNode(listener);
    for (Link<Node> link = definitions.definitions.nodes;
         !link.isEmpty(); link = link.tail) {
      Expression initializedIdentifier = link.head;
      Identifier identifier = initializedIdentifier.asIdentifier();
      if (identifier == null) {
        identifier = initializedIdentifier.asSendSet().selector.asIdentifier();
      }
      if (identical(name, identifier.source)) {
        cachedNode = initializedIdentifier;
        return cachedNode;
      }
    }
    listener.cancel('internal error: could not find $name', node: variables);
  }

  DartType computeType(Compiler compiler) {
    return variables.computeType(compiler);
  }

  DartType get type => variables.type;

  bool isInstanceMember() => variables.isInstanceMember();

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
                        Node node)
      : super(name, variables, ElementKind.FIELD_PARAMETER, node);
}

// This element represents a list of variable or field declaration.
// It contains the node, and the type. A [VariableElement] always
// references its [VariableListElement]. It forwards its
// [computeType] and [parseNode] methods to this element.
class VariableListElement extends Element {
  VariableDefinitions cachedNode;
  DartType type;
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
        this.modifiers = node.modifiers {
    assert(modifiers != null);
  }

  VariableDefinitions parseNode(DiagnosticListener listener) {
    return cachedNode;
  }

  DartType computeType(Compiler compiler) {
    if (type != null) return type;
    compiler.withCurrentElement(this, () {
      VariableDefinitions node = parseNode(compiler);
      if (node.type != null) {
        type = compiler.resolveTypeAnnotation(this, node.type);
      } else {
        // Is node.definitions exactly one FunctionExpression?
        Link<Node> link = node.definitions.nodes;
        if (!link.isEmpty() &&
            link.head.asFunctionExpression() != null &&
            link.tail.isEmpty()) {
          FunctionExpression functionExpression = link.head;
          // We found exactly one FunctionExpression
          functionSignature =
              compiler.resolveFunctionExpression(this, functionExpression);
          type = compiler.computeFunctionType(compiler.functionClass,
                                              functionSignature);
        } else {
          type = compiler.types.dynamicType;
        }
      }
    });
    assert(type != null);
    return type;
  }

  Token position() => cachedNode.getBeginToken();

  bool isInstanceMember() {
    return isMember() && !modifiers.isStatic();
  }
}

class ForeignElement extends Element {
  ForeignElement(SourceString name, ContainerElement enclosingElement)
    : super(name, ElementKind.FOREIGN, enclosingElement);

  DartType computeType(Compiler compiler) {
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

  DartType computeType(Compiler compiler) {
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
    if (getter != null
        && identical(getter.getCompilationUnit(), getCompilationUnit())) {
      return getter.position();
    } else {
      return setter.position();
    }
  }

  Modifiers get modifiers {
    // The resolver ensures that the flags match (ignoring abstract).
    if (getter != null) {
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
  final Link<Element> requiredParameters;
  final Link<Element> optionalParameters;
  final DartType returnType;
  final int requiredParameterCount;
  final int optionalParameterCount;
  final bool optionalParametersAreNamed;

  List<Element> _orderedOptionalParameters;

  FunctionSignature(this.requiredParameters,
                    this.optionalParameters,
                    this.requiredParameterCount,
                    this.optionalParameterCount,
                    this.optionalParametersAreNamed,
                    this.returnType);

  void forEachRequiredParameter(void function(Element parameter)) {
    for (Link<Element> link = requiredParameters;
         !link.isEmpty();
         link = link.tail) {
      function(link.head);
    }
  }

  void forEachOptionalParameter(void function(Element parameter)) {
    for (Link<Element> link = optionalParameters;
         !link.isEmpty();
         link = link.tail) {
      function(link.head);
    }
  }

  List<Element> get orderedOptionalParameters {
    if (_orderedOptionalParameters != null) return _orderedOptionalParameters;
    List<Element> list = new List<Element>.from(optionalParameters);
    if (optionalParametersAreNamed) {
      list.sort((Element a, Element b) {
        return a.name.slowToString().compareTo(b.name.slowToString());
      });
    }
    _orderedOptionalParameters = list;
    return list;
  }

  void forEachParameter(void function(Element parameter)) {
    forEachRequiredParameter(function);
    forEachOptionalParameter(function);
  }

  void orderedForEachParameter(void function(Element parameter)) {
    forEachRequiredParameter(function);
    orderedOptionalParameters.forEach(function);
  }

  int get parameterCount => requiredParameterCount + optionalParameterCount;
}

class FunctionElement extends Element {
  FunctionExpression cachedNode;
  DartType type;
  final Modifiers modifiers;

  FunctionSignature functionSignature;

  /**
   * A function declaration that should be parsed instead of the current one.
   * The patch should be parsed as if it was in the current scope. Its
   * signature must match this function's signature.
   */
  // TODO(lrn): Consider using [defaultImplementation] to store the patch.
  FunctionElement patch = null;
  FunctionElement origin = null;

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
    assert(modifiers != null);
    defaultImplementation = this;
  }

  bool get isPatched => patch != null;
  bool get isPatch => origin != null;

  /**
   * Applies a patch function to this function. The patch function's body
   * is used as replacement when parsing this function's body.
   * This method must not be called after the function has been parsed,
   * and it must be called at most once.
   */
  void setPatch(FunctionElement patchElement) {
    // Sanity checks. The caller must check these things before calling.
    assert(patch == null);
    this.patch = patchElement;
  }

  bool isInstanceMember() {
    return isMember()
           && !isConstructor()
           && !modifiers.isStatic();
  }

  FunctionSignature computeSignature(Compiler compiler) {
    if (functionSignature != null) return functionSignature;
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
    type = compiler.computeFunctionType(declaration,
                                        computeSignature(compiler));
    return type;
  }

  Node parseNode(DiagnosticListener listener) {
    if (patch == null) {
      if (modifiers.isExternal()) {
        listener.cancel("Compiling external function with no implementation.",
                        element: this);
      }
    }
    return cachedNode;
  }

  Token position() => cachedNode.getBeginToken();

  FunctionElement asFunctionElement() => this;

  String toString() {
    if (isPatch) {
      return 'patch ${super.toString()}';
    } else if (isPatched) {
      return 'origin ${super.toString()}';
    } else {
      return super.toString();
    }
  }
}

class ConstructorBodyElement extends FunctionElement {
  FunctionElement constructor;

  ConstructorBodyElement(FunctionElement constructor)
      : this.constructor = constructor,
        super(constructor.name,
              ElementKind.GENERATIVE_CONSTRUCTOR_BODY,
              Modifiers.EMPTY,
              constructor.enclosingElement) {
    functionSignature = constructor.functionSignature;
  }

  bool isInstanceMember() => true;

  FunctionType computeType(Compiler compiler) {
    compiler.reportFatalError('Internal error: $this.computeType', this);
  }

  Node parseNode(DiagnosticListener listener) {
    if (cachedNode != null) return cachedNode;
    cachedNode = constructor.parseNode(listener);
    assert(cachedNode != null);
    return cachedNode;
  }

  Token position() => constructor.position();
}

class SynthesizedConstructorElement extends FunctionElement {
  SynthesizedConstructorElement(Element enclosing)
    : super(enclosing.name, ElementKind.GENERATIVE_CONSTRUCTOR,
            Modifiers.EMPTY, enclosing);

  Token position() => enclosingElement.position();
}

class VoidElement extends Element {
  VoidElement(Element enclosing)
      : super(const SourceString('void'), ElementKind.VOID, enclosing);
  DartType computeType(compiler) => compiler.types.voidType;
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
  abstract Link<DartType> get typeVariables;

  /**
   * Creates the type variables, their type and corresponding element, for the
   * type variables declared in [parameter] on [element]. The bounds of the type
   * variables are not set until [element] has been resolved.
   */
  static Link<DartType> createTypeVariables(TypeDeclarationElement element,
                                        NodeList parameters) {
    if (parameters == null) return const Link<DartType>();

    // Create types and elements for type variable.
    var arguments = new LinkBuilder<DartType>();
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

abstract class ClassElement extends ScopeContainerElement
    implements TypeDeclarationElement {
  final int id;
  InterfaceType type;
  DartType supertype;
  DartType defaultClass;
  Link<DartType> interfaces;
  SourceString nativeName;
  int supertypeLoadState;
  int resolutionState;

  // backendMembers are members that have been added by the backend to simplify
  // compilation. They don't have any user-side counter-part.
  Link<Element> backendMembers = const Link<Element>();

  Link<DartType> allSupertypes;

  // Lazily applied patch of class members.
  ClassElement patch = null;
  ClassElement origin = null;

  ClassElement(SourceString name, Element enclosing, this.id, int initialState)
    : supertypeLoadState = initialState,
      resolutionState = initialState,
      super(name, ElementKind.CLASS, enclosing);

  abstract ClassNode parseNode(Compiler compiler);

  InterfaceType computeType(compiler) {
    if (type == null) {
      if (origin == null) {
        ClassNode node = parseNode(compiler);
        Link<DartType> parameters =
            TypeDeclarationElement.createTypeVariables(this,
                                                       node.typeParameters);
        type = new InterfaceType(this, parameters);
      } else {
        type = origin.computeType(compiler);
      }
    }
    return type;
  }

  bool get isPatched => patch != null;
  bool get isPatch => origin != null;

  ClassElement get declaration => super.declaration;
  ClassElement get implementation => super.implementation;

  /**
   * Return [:true:] if this element is the [:Object:] class for the [compiler].
   */
  bool isObject(Compiler compiler) =>
      identical(declaration, compiler.objectClass);

  Link<DartType> get typeVariables => type.arguments;

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
    if (result != null && result.isConstructor()) return null;
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
    bool includeInjectedMembers = isPatch;
    bool isPrivate = memberName.isPrivate();
    for (ClassElement s = superclass; s != null; s = s.superclass) {
      // Private members from a different library are not visible.
      if (isPrivate && !identical(library, s.getLibrary())) continue;
      s = includeInjectedMembers ? s.implementation : s;
      Element e = s.lookupLocalMember(memberName);
      if (e == null) continue;
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
    bool includeInjectedMembers = isPatch;
    bool isPrivate = memberName.isPrivate();
    for (InterfaceType t in interfaces) {
      ClassElement cls = t.element;
      cls = includeInjectedMembers ? cls.implementation : cls;
      Element e = cls.lookupLocalMember(memberName);
      if (e == null) continue;
      // Private members from a different library are not visible.
      if (isPrivate && !identical(fromLibrary, e.getLibrary())) continue;
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
   *
   * When called on the implementation element both members declared in the
   * origin and the patch class are returned.
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
    return localMember == null ? lookupSuperMember(memberName) : localMember;
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

  Element validateConstructorLookupResults(Selector selector,
                                           Element result,
                                           Element noMatch(Element)) {
    if (result == null
        || !result.isConstructor()
        || (selector.name.isPrivate()
            && result.getLibrary() != selector.library)) {
      result = noMatch != null ? noMatch(result) : null;
    }
    return result;
  }

  // TODO(aprelev@gmail.com): Peter believes that it would be great to
  // make noMatch a required argument. Peter's suspicion is that most
  // callers of this method would benefit from using the noMatch method.
  Element lookupConstructor(Selector selector, [Element noMatch(Element)]) {
    SourceString normalizedName;
    SourceString className = this.name;
    SourceString constructorName = selector.name;
    if (!identical(constructorName, const SourceString('')) &&
        ((className == null) ||
         (constructorName.slowToString() != className.slowToString()))) {
      normalizedName = Elements.constructConstructorName(className,
                                                         constructorName);
    } else {
      normalizedName = className;
    }
    Element result = localLookup(normalizedName);
    return validateConstructorLookupResults(selector, result, noMatch);
  }

  Element lookupFactoryConstructor(Selector selector,
                                   [Element noMatch(Element)]) {
    SourceString constructorName = selector.name;
    Element result = localLookup(constructorName);
    return validateConstructorLookupResults(selector, result, noMatch);
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
    Link<Element> result = const Link<Element>();
    // TODO(johnniwinther): Should we include injected constructors?
    forEachMember((_, Element member) {
      if (member.isConstructor()) result = result.prepend(member);
    });
    return result;
  }

  /**
   * Returns the super class, if any.
   *
   * The returned element may not be resolved yet.
   */
  ClassElement get superclass {
    assert(supertypeLoadState == STATE_DONE);
    return supertype == null ? null : supertype.element;
  }

  /**
   * Runs through all members of this class.
   *
   * The enclosing class is passed to the callback. This is useful when
   * [includeSuperMembers] is [:true:].
   *
   * When called on an implementation element both the members in the origin
   * and patch class are included.
   */
  // TODO(johnniwinther): Clean up lookup to get rid of the include predicates.
  void forEachMember(void f(ClassElement enclosingClass, Element member),
                     {includeBackendMembers: false,
                      includeSuperMembers: false}) {
    bool includeInjectedMembers = isPatch;
    Set<ClassElement> seen = new Set<ClassElement>();
    ClassElement classElement = declaration;
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
      if (includeInjectedMembers) {
        if (classElement.patch != null) {
          for (Element element in classElement.patch.localMembers.reverse()) {
            if (!element.isPatch) {
              f(classElement, element);
            }
          }
        }
      }
      classElement = includeSuperMembers ? classElement.superclass : null;
    } while(classElement != null);
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
   *
   * When called on the implementation element both the fields declared in the
   * origin and in the patch are included.
   */
  void forEachInstanceField(void f(ClassElement enclosingClass, Element field),
                            {includeBackendMembers: false,
                             includeSuperMembers: false}) {
    // Filters so that [f] is only invoked with instance fields.
    void fieldFilter(ClassElement enclosingClass, Element member) {
      if (member.isInstanceMember() && member.kind == ElementKind.FIELD) {
        f(enclosingClass, member);
      }
    }

    forEachMember(fieldFilter,
                  includeBackendMembers: includeBackendMembers,
                  includeSuperMembers: includeSuperMembers);
  }

  bool implementsInterface(ClassElement intrface) {
    for (DartType implementedInterfaceType in allSupertypes) {
      ClassElement implementedInterface = implementedInterfaceType.element;
      if (identical(implementedInterface, intrface)) {
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
      if (identical(s, cls)) return true;
    }
    return false;
  }

  bool isInterface() => false;
  bool isNative() => nativeName != null;
  int hashCode() => id;

  // TODO(johnniwinther): Rewrite to avoid the optional argument.
  Scope buildScope({bool patchScope: false}) {
    if (origin != null) {
      return new PatchClassScope(
          enclosingElement.buildScope(patchScope: patchScope), origin, this);
    } else if (patchScope && patch != null) {
      return new PatchClassScope(
          enclosingElement.buildScope(patchScope: patchScope), this, patch);
    } else {
      return new ClassScope(
          enclosingElement.buildScope(patchScope: patchScope), this);
    }
  }

  Scope buildLocalScope() {
    if (origin != null) {
      return new LocalPatchClassScope(origin, this);
    } else {
      return new LocalClassScope(this);
    }
  }

  Link<DartType> get allSupertypesAndSelf {
    return allSupertypes.prepend(new InterfaceType(this));
  }

  String toString() {
    if (origin != null) {
      return 'patch ${super.toString()}';
    } else if (patch != null) {
      return 'origin ${super.toString()}';
    } else {
      return super.toString();
    }
  }
}

class Elements {
  static bool isUnresolved(Element e) => e == null || e.isErroneous();
  static bool isErroneousElement(Element e) => e != null && e.isErroneous();

  static bool isLocal(Element element) {
    return !Elements.isUnresolved(element)
            && !element.isInstanceMember()
            && !isStaticOrTopLevelField(element)
            && !isStaticOrTopLevelFunction(element)
            && (identical(element.kind, ElementKind.VARIABLE) ||
                identical(element.kind, ElementKind.PARAMETER) ||
                identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isInstanceField(Element element) {
    return !Elements.isUnresolved(element)
           && element.isInstanceMember()
           && (identical(element.kind, ElementKind.FIELD)
               || identical(element.kind, ElementKind.GETTER)
               || identical(element.kind, ElementKind.SETTER));
  }

  static bool isStaticOrTopLevel(Element element) {
    // TODO(ager): This should not be necessary when patch support has
    // been reworked.
    if (!Elements.isUnresolved(element)
        && element.modifiers.isStatic()) {
      return true;
    }
    return !Elements.isUnresolved(element)
           && !element.isInstanceMember()
           && !element.isPrefix()
           && element.enclosingElement != null
           && (element.enclosingElement.kind == ElementKind.CLASS ||
               element.enclosingElement.kind == ElementKind.COMPILATION_UNIT ||
               element.enclosingElement.kind == ElementKind.LIBRARY);
  }

  static bool isStaticOrTopLevelField(Element element) {
    return isStaticOrTopLevel(element)
           && (identical(element.kind, ElementKind.FIELD)
               || identical(element.kind, ElementKind.GETTER)
               || identical(element.kind, ElementKind.SETTER));
  }

  static bool isStaticOrTopLevelFunction(Element element) {
    return isStaticOrTopLevel(element)
           && (identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isInstanceMethod(Element element) {
    return !Elements.isUnresolved(element)
           && element.isInstanceMember()
           && (identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isInstanceSend(Send send, TreeElements elements) {
    Element element = elements[send];
    if (element == null) return !isClosureSend(send, element);
    return isInstanceMethod(element) || isInstanceField(element);
  }

  static bool isClosureSend(Send send, Element element) {
    if (send.isPropertyAccess) return false;
    if (send.receiver != null) return false;
    // (o)() or foo()().
    if (element == null && send.selector.asIdentifier() == null) return true;
    if (element == null) return false;
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
      const SourceString(r'operator$eq');

  static SourceString constructOperatorName(SourceString selector,
                                            bool isUnary) {
    String str = selector.stringValue;
    if (identical(str, '==') || identical(str, '!=')) return OPERATOR_EQUALS;

    if (identical(str, '~')) {
      str = 'not';
    } else if (identical(str, '-') && isUnary) {
      // TODO(ahe): Return something like 'unary -'.
      return const SourceString('negate');
    } else if (identical(str, '[]')) {
      str = 'index';
    } else if (identical(str, '[]=')) {
      str = 'indexSet';
    } else if (identical(str, '*') || identical(str, '*=')) {
      str = 'mul';
    } else if (identical(str, '/') || identical(str, '/=')) {
      str = 'div';
    } else if (identical(str, '%') || identical(str, '%=')) {
      str = 'mod';
    } else if (identical(str, '~/') || identical(str, '~/=')) {
      str = 'tdiv';
    } else if (identical(str, '+') || identical(str, '+=')) {
      str = 'add';
    } else if (identical(str, '-') || identical(str, '-=')) {
      str = 'sub';
    } else if (identical(str, '<<') || identical(str, '<<=')) {
      str = 'shl';
    } else if (identical(str, '>>') || identical(str, '>>=')) {
      str = 'shr';
    } else if (identical(str, '>=')) {
      str = 'ge';
    } else if (identical(str, '>')) {
      str = 'gt';
    } else if (identical(str, '<=')) {
      str = 'le';
    } else if (identical(str, '<')) {
      str = 'lt';
    } else if (identical(str, '&') || identical(str, '&=')) {
      str = 'and';
    } else if (identical(str, '^') || identical(str, '^=')) {
      str = 'xor';
    } else if (identical(str, '|') || identical(str, '|=')) {
      str = 'or';
    } else if (selector == const SourceString('negate')) {
      // TODO(ahe): Remove this case: Legacy support for pre-0.11 spec.
      return selector;
    } else if (identical(str, '?')) {
      return selector;
    } else {
      throw new Exception('Unhandled selector: ${selector.slowToString()}');
    }
    return new SourceString('operator\$$str');
  }

  static SourceString mapToUserOperator(SourceString op) {
    String value = op.stringValue;

    if (identical(value, '!=')) return const SourceString('==');
    if (identical(value, '*=')) return const SourceString('*');
    if (identical(value, '/=')) return const SourceString('/');
    if (identical(value, '%=')) return const SourceString('%');
    if (identical(value, '~/=')) return const SourceString('~/');
    if (identical(value, '+=')) return const SourceString('+');
    if (identical(value, '-=')) return const SourceString('-');
    if (identical(value, '<<=')) return const SourceString('<<');
    if (identical(value, '>>=')) return const SourceString('>>');
    if (identical(value, '&=')) return const SourceString('&');
    if (identical(value, '^=')) return const SourceString('^');
    if (identical(value, '|=')) return const SourceString('|');

    throw 'Unhandled operator: ${op.slowToString()}';
  }

  static bool isNumberOrStringSupertype(Element element, Compiler compiler) {
    LibraryElement coreLibrary = compiler.coreLibrary;
    return (element == coreLibrary.find(const SourceString('Comparable')));
  }

  static bool isStringOnlySupertype(Element element, Compiler compiler) {
    LibraryElement coreLibrary = compiler.coreLibrary;
    return element == coreLibrary.find(const SourceString('Pattern'));
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
  Link<LabelElement> labels = const Link<LabelElement>();
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
  DartType bound;

  TypeVariableElement(name, Element enclosing, this.cachedNode,
                      [this.type, this.bound])
    : super(name, ElementKind.TYPE_VARIABLE, enclosing);

  TypeVariableType computeType(compiler) => type;

  Node parseNode(compiler) => cachedNode;

  String toString() => "${enclosingElement.toString()}.${name.slowToString()}";

  Token position() => cachedNode.getBeginToken();
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
abstract class MetadataAnnotation {
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
