// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library elements.modelx;

import 'dart:uri';

import 'elements.dart';
import '../../compiler.dart' as api;
import '../tree/tree.dart';
import '../util/util.dart';
import '../resolution/resolution.dart';

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


class ElementX implements Element {
  static int elementHashCode = 0;

  final SourceString name;
  final ElementKind kind;
  final Element enclosingElement;
  final int hashCode = ++elementHashCode;
  Link<MetadataAnnotation> metadata = const Link<MetadataAnnotation>();

  ElementX(this.name, this.kind, this.enclosingElement) {
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

  /**
   * Returns [:true:] if this element is enclosed in a static member or is
   * itself a static member.
   */
  bool isInStaticMember() {
    Element member = getEnclosingMember();
    return member != null && member.modifiers.isStatic();
  }

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
  bool isLibrary() => identical(kind, ElementKind.LIBRARY);
  bool impliesType() => (kind.category & ElementCategory.IMPLIES_TYPE) != 0;

  /** See [ErroneousElement] for documentation. */
  bool isErroneous() => false;

  /** See [AmbiguousElement] for documentation. */
  bool isAmbiguous() => false;

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

  bool get isSynthesized => false;

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
    throw new UnsupportedError('patch is not supported on $this');
  }

  Element get origin {
    throw new UnsupportedError('origin is not supported on $this');
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

  /**
   * Returns the member enclosing this element or the element itself if it is a
   * member. If no enclosing element is found, [:null:] is returned.
   */
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
   * Creates the scope for this element.
   */
  Scope buildScope() => enclosingElement.buildScope();

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

  String _fixedBackendName = null;
  bool _isNative = false;
  bool isNative() => _isNative;
  bool hasFixedBackendName() => _fixedBackendName != null;
  String fixedBackendName() => _fixedBackendName;
  // Marks this element as a native element.
  void setNative(String name) {
    _isNative = true;
    _fixedBackendName = name;
  }
  void setFixedBackendName(String name) {
    _fixedBackendName = name;
  }

  FunctionElement asFunctionElement() => null;

  static bool isInvalid(Element e) => e == null || e.isErroneous();

  bool isAbstract(Compiler compiler) => modifiers.isAbstract();
  bool isForeign(Compiler compiler) => getLibrary() == compiler.foreignLibrary;
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
class ErroneousElementX extends ElementX implements ErroneousElement {
  final MessageKind messageKind;
  final List messageArguments;

  ErroneousElementX(this.messageKind, this.messageArguments,
                    SourceString name, Element enclosing)
      : super(name, ElementKind.ERROR, enclosing);

  isErroneous() => true;

  unsupported() {
    throw 'unsupported operation on erroneous element';
  }

  Link<MetadataAnnotation> get metadata => unsupported();
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

  // TODO(kasperl): These seem unnecessary.
  set patch(value) => unsupported();
  set origin(value) => unsupported();
  set defaultImplementation(value) => unsupported();

  get redirectionTarget => this;

  getLibrary() => enclosingElement.getLibrary();

  String toString() {
    String n = name.slowToString();
    return '<$n: ${messageKind.message(messageArguments)}>';
  }
}

/**
 * An ambiguous element represents multiple elements accessible by the same name.
 *
 * Ambiguous elements are created during handling of import/export scopes. If an
 * ambiguous element is encountered during resolution a warning/error should be
 * reported.
 */
class AmbiguousElementX extends ElementX implements AmbiguousElement {
  /**
   * The message to report on resolving this element.
   */
  final MessageKind messageKind;

  /**
   * The message arguments to report on resolving this element.
   */
  final List messageArguments;

  /**
   * The first element that this ambiguous element might refer to.
   */
  final Element existingElement;

  /**
   * The second element that this ambiguous element might refer to.
   */
  final Element newElement;

  AmbiguousElementX(this.messageKind, this.messageArguments,
      Element enclosingElement, Element existingElement, Element newElement)
      : this.existingElement = existingElement,
        this.newElement = newElement,
        super(existingElement.name, ElementKind.AMBIGUOUS, enclosingElement);

  bool isAmbiguous() => true;
}

class ScopeX {
  final Map<SourceString, Element> contents = new Map<SourceString, Element>();

  bool get isEmpty => contents.isEmpty;
  Iterable<Element> get values => contents.values;

  Element lookup(SourceString name) {
    return contents[name];
  }

  void add(Element element, DiagnosticListener listener) {
    if (element.isAccessor()) {
      addAccessor(element, contents[element.name], listener);
    } else {
      Element existing = contents.putIfAbsent(element.name, () => element);
      if (!identical(existing, element)) {
        // TODO(ahe): Do something similar to Resolver.reportErrorWithContext.
        listener.cancel('duplicate definition', token: element.position());
        listener.cancel('existing definition', token: existing.position());
      }
    }
  }

  /**
   * Adds a definition for an [accessor] (getter or setter) to a scope.
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
  void addAccessor(Element accessor,
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
        AbstractFieldElementX field = existing;
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
      AbstractFieldElementX field =
          new AbstractFieldElementX(accessor.name, container);
      if (accessor.isGetter()) {
        field.getter = accessor;
      } else {
        field.setter = accessor;
      }
      add(field, listener);
    }
  }
}

class CompilationUnitElementX extends ElementX
    implements CompilationUnitElement {
  final Script script;
  PartOf partTag;
  Link<Element> localMembers = const Link<Element>();

  CompilationUnitElementX(Script script, LibraryElement library)
    : this.script = script,
      super(new SourceString(script.name),
            ElementKind.COMPILATION_UNIT,
            library) {
    library.addCompilationUnit(this);
  }

  void addMember(Element element, DiagnosticListener listener) {
    // Keep a list of top level members.
    localMembers = localMembers.prepend(element);
    // Provide the member to the library to build scope.
    if (enclosingElement.isPatch) {
      getImplementationLibrary().addMember(element, listener);
    } else {
      getLibrary().addMember(element, listener);
    }
  }

  void setPartOf(PartOf tag, DiagnosticListener listener) {
    LibraryElementX library = enclosingElement;
    if (library.entryCompilationUnit == this) {
      listener.reportMessage(
          listener.spanFromSpannable(tag),
          MessageKind.ILLEGAL_DIRECTIVE.error(),
          api.Diagnostic.WARNING);
      return;
    }
    if (!localMembers.isEmpty) {
      listener.reportMessage(
          listener.spanFromSpannable(tag),
          MessageKind.BEFORE_TOP_LEVEL.error(),
          api.Diagnostic.ERROR);
      return;
    }
    if (partTag != null) {
      listener.reportMessage(
          listener.spanFromSpannable(tag),
          MessageKind.DUPLICATED_PART_OF.error(),
          api.Diagnostic.WARNING);
      return;
    }
    partTag = tag;
    LibraryName libraryTag = getLibrary().libraryTag;
    if (libraryTag != null) {
      String actualName = tag.name.toString();
      String expectedName = libraryTag.name.toString();
      if (expectedName != actualName) {
        listener.reportMessage(
            listener.spanFromSpannable(tag.name),
            MessageKind.LIBRARY_NAME_MISMATCH.error([expectedName]),
            api.Diagnostic.WARNING);
      }
    }
  }

  bool get hasMembers => !localMembers.isEmpty;
}

class LibraryElementX extends ElementX implements LibraryElement {
  final Uri canonicalUri;
  CompilationUnitElement entryCompilationUnit;
  Link<CompilationUnitElement> compilationUnits =
      const Link<CompilationUnitElement>();
  Link<LibraryTag> tags = const Link<LibraryTag>();
  LibraryName libraryTag;
  bool canUseNative = false;
  Link<Element> localMembers = const Link<Element>();
  final ScopeX localScope = new ScopeX();

  /**
   * If this library is patched, [patch] points to the patch library.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  LibraryElementX patch = null;

  /**
   * If this is a patch library, [origin] points to the origin library.
   *
   * See [:patch_parser.dart:] for a description of the terminology.
   */
  final LibraryElementX origin;

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

  LibraryElementX(Script script, [Uri canonicalUri, LibraryElement this.origin])
    : this.canonicalUri = ((canonicalUri == null) ? script.uri : canonicalUri),
      importScope = new Map<SourceString, Element>(),
      super(new SourceString(script.name), ElementKind.LIBRARY, null) {
    entryCompilationUnit = new CompilationUnitElementX(script, this);
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
      // TODO(johnniwinther): Provide access to the import tags from which
      // the elements came.
      importScope[element.name] = new AmbiguousElementX(
          MessageKind.DUPLICATE_IMPORT, [element.name],
          this, existing, element);
    } else {
      importScope[element.name] = element;
    }
  }

  void addMember(Element element, DiagnosticListener listener) {
    localMembers = localMembers.prepend(element);
    addToScope(element, listener);
  }

  void addToScope(Element element, DiagnosticListener listener) {
    localScope.add(element, listener);
  }

  Element localLookup(SourceString elementName) {
    Element result = localScope.lookup(elementName);
    if (result == null && isPatch) {
      result = origin.localLookup(elementName);
    }
    return result;
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
    Element result = localScope.lookup(elementName);
    if (result != null) return result;
    if (origin != null) {
      result = origin.localScope.lookup(elementName);
      if (result != null) return result;
    }
    result = importScope[elementName];
    if (result != null) return result;
    if (origin != null) {
      result = origin.importScope[elementName];
      if (result != null) return result;
    }
    return null;
  }

  /** Look up a top-level element in this library, but only look for
    * non-imported elements. Returns null if no such element exist. */
  Element findLocal(SourceString elementName) {
    // TODO(johnniwinther): How to handle injected elements in the patch
    // library?
    Element result = localScope.lookup(elementName);
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

  Iterable<Element> getNonPrivateElementsInScope() {
    return localScope.values.where((Element element) {
      // At this point [localScope] only contains members so we don't need
      // to check for foreign or prefix elements.
      return !element.name.isPrivate();
    });
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
      String path = canonicalUri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }

  Scope buildScope() => new LibraryScope(this);

  bool get isPlatformLibrary => canonicalUri.scheme == "dart";

  bool get isInternalLibrary =>
      isPlatformLibrary && canonicalUri.path.startsWith('_');

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

class PrefixElementX extends ElementX implements PrefixElement {
  Map<SourceString, Element> imported;
  Token firstPosition;

  PrefixElementX(SourceString prefix, Element enclosing, this.firstPosition)
      : imported = new Map<SourceString, Element>(),
        super(prefix, ElementKind.PREFIX, enclosing);

  Element lookupLocalMember(SourceString memberName) => imported[memberName];

  DartType computeType(Compiler compiler) => compiler.types.dynamicType;

  Token position() => firstPosition;
}

class TypedefElementX extends ElementX implements TypedefElement {
  Typedef cachedNode;
  TypedefType cachedType;

  /**
   * Canonicalize raw version of [cachedType].
   *
   * See [ClassElement.rawType] for motivation.
   *
   * The [rawType] is computed together with [cachedType] in [computeType].
   */
  TypedefType rawType;

  /**
   * The type annotation which defines this typedef.
   */
  DartType alias;

  bool isResolved = false;
  bool isBeingResolved = false;

  TypedefElementX(SourceString name, Element enclosing)
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
        TypeDeclarationElementX.createTypeVariables(this, node.typeParameters);
    cachedType = new TypedefType(this, parameters);
    if (parameters.isEmpty) {
      rawType = cachedType;
    } else {
      var dynamicParameters = const Link<DartType>();
      parameters.forEach((_) {
        dynamicParameters =
            dynamicParameters.prepend(compiler.types.dynamicType);
      });
      rawType = new TypedefType(this, dynamicParameters);
    }
    compiler.resolveTypedef(this);
    return cachedType;
  }

  Link<DartType> get typeVariables => cachedType.typeArguments;

  Scope buildScope() {
    return new TypeDeclarationScope(enclosingElement.buildScope(), this);
  }
}

class VariableElementX extends ElementX implements VariableElement {
  final VariableListElement variables;
  Expression cachedNode; // The send or the identifier in the variables list.

  Modifiers get modifiers => variables.modifiers;

  VariableElementX(SourceString name,
                   VariableListElement variables,
                   ElementKind kind,
                   this.cachedNode)
    : this.variables = variables,
      super(name, kind, variables.enclosingElement);

  Node parseNode(DiagnosticListener listener) {
    if (cachedNode != null) return cachedNode;
    VariableDefinitions definitions = variables.parseNode(listener);
    for (Link<Node> link = definitions.definitions.nodes;
         !link.isEmpty; link = link.tail) {
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
class FieldParameterElementX extends VariableElementX
    implements FieldParameterElement {
  VariableElement fieldElement;

  FieldParameterElementX(SourceString name,
                         this.fieldElement,
                         VariableListElement variables,
                         Node node)
      : super(name, variables, ElementKind.FIELD_PARAMETER, node);
}

// This element represents a list of variable or field declaration.
// It contains the node, and the type. A [VariableElement] always
// references its [VariableListElement]. It forwards its
// [computeType] and [parseNode] methods to this element.
class VariableListElementX extends ElementX implements VariableListElement {
  VariableDefinitions cachedNode;
  DartType type;
  final Modifiers modifiers;

  /**
   * Function signature for a variable with a function type. The signature is
   * kept to provide full information about parameter names through the mirror
   * system.
   */
  FunctionSignature functionSignature;

  VariableListElementX(ElementKind kind,
                       Modifiers this.modifiers,
                       Element enclosing)
    : super(null, kind, enclosing);

  VariableListElementX.node(VariableDefinitions node,
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
        if (!link.isEmpty &&
            link.head.asFunctionExpression() != null &&
            link.tail.isEmpty) {
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

class AbstractFieldElementX extends ElementX implements AbstractFieldElement {
  FunctionElement getter;
  FunctionElement setter;

  AbstractFieldElementX(SourceString name, Element enclosing)
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
class FunctionSignatureX implements FunctionSignature {
  final Link<Element> requiredParameters;
  final Link<Element> optionalParameters;
  final DartType returnType;
  final int requiredParameterCount;
  final int optionalParameterCount;
  final bool optionalParametersAreNamed;

  List<Element> _orderedOptionalParameters;

  FunctionSignatureX(this.requiredParameters,
                     this.optionalParameters,
                     this.requiredParameterCount,
                     this.optionalParameterCount,
                     this.optionalParametersAreNamed,
                     this.returnType);

  void forEachRequiredParameter(void function(Element parameter)) {
    for (Link<Element> link = requiredParameters;
         !link.isEmpty;
         link = link.tail) {
      function(link.head);
    }
  }

  void forEachOptionalParameter(void function(Element parameter)) {
    for (Link<Element> link = optionalParameters;
         !link.isEmpty;
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

class FunctionElementX extends ElementX implements FunctionElement {
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
   * If this is a redirecting factory, [defaultImplementation] will be
   * changed by the resolver to point to the redirection target.  If
   * this is an interface constructor, [defaultImplementation] will be
   * changed by the resolver to point to the default implementation.
   * Otherwise, [:identical(defaultImplementation, this):].
   */
  // TODO(ahe): Rename this field to redirectionTarget and remove
  // mention of interface constructors above.
  FunctionElement defaultImplementation;

  FunctionElementX(SourceString name,
                   ElementKind kind,
                   Modifiers modifiers,
                   Element enclosing)
      : this.tooMuchOverloading(name, null, kind, modifiers, enclosing, null);

  FunctionElementX.node(SourceString name,
                        FunctionExpression node,
                        ElementKind kind,
                        Modifiers modifiers,
                        Element enclosing)
      : this.tooMuchOverloading(name, node, kind, modifiers, enclosing, null);

  FunctionElementX.from(SourceString name,
                        FunctionElement other,
                        Element enclosing)
      : this.tooMuchOverloading(name, other.cachedNode, other.kind,
                                other.modifiers, enclosing,
                                other.functionSignature);

  FunctionElementX.tooMuchOverloading(SourceString name,
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

  FunctionElement get redirectionTarget {
    if (this == defaultImplementation) return this;
    var target = defaultImplementation;
    Set<Element> seen = new Set<Element>();
    seen.add(target);
    while (!target.isErroneous() && target != target.defaultImplementation) {
      target = target.defaultImplementation;
      if (seen.contains(target)) {
        // TODO(ahe): This is expedient for now, but it should be
        // checked by the resolver.  Keeping http://dartbug.com/3970
        // open to track this.
        throw new SpannableAssertionFailure(
            target, 'redirecting factory leads to cycle');
      }
    }
    return target;
  }

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

  FunctionExpression parseNode(DiagnosticListener listener) {
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

  bool isAbstract(Compiler compiler) {
    if (super.isAbstract(compiler)) return true;
    if (modifiers.isExternal()) return false;
    if (isFunction() || isAccessor()) {
      return !parseNode(compiler).hasBody();
    }
    return false;
  }
}

class ConstructorBodyElementX extends FunctionElementX
    implements ConstructorBodyElement {
  FunctionElement constructor;

  ConstructorBodyElementX(FunctionElement constructor)
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

class SynthesizedConstructorElementX extends FunctionElementX {
  SynthesizedConstructorElementX(Element enclosing)
    : super(enclosing.name, ElementKind.GENERATIVE_CONSTRUCTOR,
            Modifiers.EMPTY, enclosing);

  SynthesizedConstructorElementX.forDefault(Element enclosing,
                                            Compiler compiler)
    : super(enclosing.name, ElementKind.GENERATIVE_CONSTRUCTOR,
            Modifiers.EMPTY, enclosing) {
    type = new FunctionType(
        compiler.types.voidType,
        const Link<DartType>(),
        this);
    cachedNode = new FunctionExpression(
        new Identifier(enclosing.position()),
        new NodeList.empty(),
        new Block(new NodeList.empty()),
        null, Modifiers.EMPTY, null, null);
  }

  bool get isSynthesized => true;

  Token position() => enclosingElement.position();
}

class VoidElementX extends ElementX {
  VoidElementX(Element enclosing)
      : super(const SourceString('void'), ElementKind.VOID, enclosing);
  DartType computeType(compiler) => compiler.types.voidType;
  Node parseNode(_) {
    throw 'internal error: parseNode on void';
  }
  bool impliesType() => true;
}

class TypeDeclarationElementX {
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
    for (Link link = parameters.nodes; !link.isEmpty; link = link.tail) {
      TypeVariable node = link.head;
      SourceString variableName = node.name.source;
      TypeVariableElement variableElement =
          new TypeVariableElementX(variableName, element, node);
      TypeVariableType variableType = new TypeVariableType(variableElement);
      variableElement.type = variableType;
      arguments.addLast(variableType);
    }
    return arguments.toLink();
  }
}

abstract class BaseClassElementX extends ElementX implements ClassElement {
  final int id;

  /**
   * The type of [:this:] for this class declaration.
   *
   * The type of [:this:] is the interface type based on this element in which
   * the type arguments are the declared type variables. For instance,
   * [:List<E>:] for [:List:] and [:Map<K,V>:] for [:Map:].
   *
   * This type is computed in [computeType].
   */
  InterfaceType thisType;

  /**
   * The raw type for this class declaration.
   *
   * The raw type is the interface type base on this element in which the type
   * arguments are all [dynamic]. For instance [:List<dynamic>:] for [:List:]
   * and [:Map<dynamic,dynamic>:] for [:Map:]. For non-generic classes [rawType]
   * is the same as [thisType].
   *
   * The [rawType] field is a canonicalization of the raw type and should be
   * used to distinguish explicit and implicit uses of the [dynamic]
   * type arguments. For instance should [:List:] be the [rawType] of the
   * [:List:] class element whereas [:List<dynamic>:] should be its own
   * instantiation of [InterfaceType] with [:dynamic:] as type argument. Using
   * this distinction, we can print the raw type with type arguments only when
   * the input source has used explicit type arguments.
   *
   * This type is computed together with [thisType] in [computeType].
   */
  InterfaceType rawType;
  DartType supertype;
  DartType defaultClass;
  Link<DartType> interfaces;
  SourceString nativeTagInfo;
  int supertypeLoadState;
  int resolutionState;

  // backendMembers are members that have been added by the backend to simplify
  // compilation. They don't have any user-side counter-part.
  Link<Element> backendMembers = const Link<Element>();

  Link<DartType> allSupertypes;

  BaseClassElementX(SourceString name,
                    Element enclosing,
                    this.id,
                    int initialState)
      : supertypeLoadState = initialState,
        resolutionState = initialState,
        super(name, ElementKind.CLASS, enclosing);

  int get hashCode => id;
  ClassElement get patch => super.patch;
  ClassElement get origin => super.origin;
  ClassElement get declaration => super.declaration;
  ClassElement get implementation => super.implementation;

  bool get hasBackendMembers => !backendMembers.isEmpty;

  InterfaceType computeType(Compiler compiler) {
    if (thisType == null) {
      if (origin == null) {
        Link<DartType> parameters = computeTypeParameters(compiler);
        thisType = new InterfaceType(this, parameters);
        if (parameters.isEmpty) {
          rawType = thisType;
        } else {
          var dynamicParameters = const Link<DartType>();
          parameters.forEach((_) {
            dynamicParameters =
                dynamicParameters.prepend(compiler.types.dynamicType);
          });
          rawType = new InterfaceType(this, dynamicParameters);
        }
      } else {
        thisType = origin.computeType(compiler);
        rawType = origin.rawType;
      }
    }
    return thisType;
  }

  Link<DartType> computeTypeParameters(Compiler compiler);

  /**
   * Return [:true:] if this element is the [:Object:] class for the [compiler].
   */
  bool isObject(Compiler compiler) =>
      identical(declaration, compiler.objectClass);

  Link<DartType> get typeVariables => thisType.typeArguments;

  ClassElement ensureResolved(Compiler compiler) {
    if (resolutionState == STATE_NOT_STARTED) {
      compiler.resolver.resolveClass(this);
    }
    return this;
  }

  void addDefaultConstructorIfNeeded(Compiler compiler) {
    if (hasConstructor) return;
    FunctionElement constructor =
        new SynthesizedConstructorElementX.forDefault(this, compiler);
    setDefaultConstructor(constructor, compiler);
  }

  void setDefaultConstructor(FunctionElement constructor, Compiler compiler);

  void addBackendMember(Element member) {
    backendMembers = backendMembers.prepend(member);
  }

  void reverseBackendMembers() {
    backendMembers = backendMembers.reverse();
  }

  /**
   * Lookup local members in the class. This will ignore constructors.
   */
  Element lookupLocalMember(SourceString memberName) {
    var result = localLookup(memberName);
    if (result != null && result.isConstructor()) return null;
    return result;
  }

  /// Lookup a synthetic element created by the backend.
  Element lookupBackendMember(SourceString memberName) {
    for (Element element in backendMembers) {
      if (element.name == memberName) {
        return element;
      }
    }
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
    if (constructorName != const SourceString('')) {
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
      classElement.forEachLocalMember((e) => f(classElement, e));
      if (includeBackendMembers) {
        classElement.forEachBackendMember((e) => f(classElement, e));
      }
      if (includeInjectedMembers) {
        if (classElement.patch != null) {
          classElement.patch.forEachLocalMember((e) {
            if (!e.isPatch) f(classElement, e);
          });
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

  void forEachBackendMember(void f(Element member)) {
    backendMembers.forEach(f);
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
  bool isNative() => nativeTagInfo != null;
  void setNative(String name) {
    nativeTagInfo = new SourceString(name);
  }
}

abstract class ClassElementX extends BaseClassElementX {
  // Lazily applied patch of class members.
  ClassElement patch = null;
  ClassElement origin = null;

  Link<Element> localMembers = const Link<Element>();
  final ScopeX localScope = new ScopeX();

  ClassElementX(SourceString name, Element enclosing, int id, int initialState)
      : super(name, enclosing, id, initialState);

  ClassNode parseNode(Compiler compiler);

  bool get isMixinApplication => false;
  bool get isPatched => patch != null;
  bool get isPatch => origin != null;
  bool get hasLocalScopeMembers => !localScope.isEmpty;

  void addMember(Element element, DiagnosticListener listener) {
    localMembers = localMembers.prepend(element);
    addToScope(element, listener);
  }

  void addToScope(Element element, DiagnosticListener listener) {
    localScope.add(element, listener);
  }

  Element localLookup(SourceString elementName) {
    Element result = localScope.lookup(elementName);
    if (result == null && isPatch) {
      result = origin.localLookup(elementName);
    }
    return result;
  }

  void forEachLocalMember(void f(Element member)) {
    localMembers.reverse().forEach(f);
  }

  bool get hasConstructor {
    // Search in scope to be sure we search patched constructors.
    for (var element in localScope.values) {
      if (element.isConstructor()) return true;
    }
    return false;
  }

  void setDefaultConstructor(FunctionElement constructor, Compiler compiler) {
    addToScope(constructor, compiler);
  }

  Link<DartType> computeTypeParameters(Compiler compiler) {
    ClassNode node = parseNode(compiler);
    return TypeDeclarationElementX.createTypeVariables(
        this, node.typeParameters);
  }

  Scope buildScope() => new ClassScope(enclosingElement.buildScope(), this);

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

class MixinApplicationElementX extends BaseClassElementX
    implements MixinApplicationElement {
  final Node node;
  final Modifiers modifiers;

  FunctionElement constructor;
  ClassElement mixin;

  // TODO(kasperl): The analyzer complains when I don't have these two
  // fields. This is pretty weird. I cannot replace them with getters.
  final ClassElement patch = null;
  final ClassElement origin = null;

  MixinApplicationElementX(SourceString name, Element enclosing, int id,
                           this.node, this.modifiers)
      : super(name, enclosing, id, STATE_NOT_STARTED);

  bool get isMixinApplication => true;
  bool get hasConstructor => constructor != null;
  bool get hasLocalScopeMembers => false;

  Token position() => node.getBeginToken();

  Node parseNode(DiagnosticListener listener) => node;

  Element localLookup(SourceString name) {
    if (this.name == name) return constructor;
    if (mixin == null) return null;
    Element mixedInElement = mixin.localLookup(name);
    if (mixedInElement == null) return null;
    return mixedInElement.isInstanceMember() ? mixedInElement : null;
  }

  void forEachLocalMember(void f(Element member)) {
    if (mixin != null) mixin.forEachLocalMember((Element mixedInElement) {
      if (mixedInElement.isInstanceMember()) f(mixedInElement);
    });
  }

  void addMember(Element element, DiagnosticListener listener) {
    throw new UnsupportedError("cannot add member to $this");
  }

  void addToScope(Element element, DiagnosticListener listener) {
    throw new UnsupportedError("cannot add to scope of $this");
  }

  void setDefaultConstructor(FunctionElement constructor, Compiler compiler) {
    assert(!hasConstructor);
    this.constructor = constructor;
  }

  Link<DartType> computeTypeParameters(Compiler compiler) {
    NamedMixinApplication named = node.asNamedMixinApplication();
    if (named == null) return const Link<DartType>();
    return TypeDeclarationElementX.createTypeVariables(
        this, named.typeParameters);
  }
}

class LabelElementX extends ElementX implements LabelElement {

  // We store the original label here so it can be returned by [parseNode].
  final Label label;
  final String labelName;
  final TargetElement target;
  bool isBreakTarget = false;
  bool isContinueTarget = false;
  LabelElementX(Label label, String labelName, this.target,
                Element enclosingElement)
      : this.label = label,
        this.labelName = labelName,
        // In case of a synthetic label, just use [labelName] for
        // identifying the element.
        super(label == null
                  ? new SourceString(labelName)
                  : label.identifier.source,
              ElementKind.LABEL,
              enclosingElement);

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
class TargetElementX extends ElementX implements TargetElement {
  final Node statement;
  final int nestingLevel;
  Link<LabelElement> labels = const Link<LabelElement>();
  bool isBreakTarget = false;
  bool isContinueTarget = false;

  TargetElementX(this.statement, this.nestingLevel, Element enclosingElement)
      : super(const SourceString(""), ElementKind.STATEMENT, enclosingElement);
  bool get isTarget => isBreakTarget || isContinueTarget;

  LabelElement addLabel(Label label, String labelName) {
    LabelElement result = new LabelElementX(label, labelName, this,
                                            enclosingElement);
    labels = labels.prepend(result);
    return result;
  }

  Node parseNode(DiagnosticListener l) => statement;

  bool get isSwitch => statement is SwitchStatement;

  Token position() => statement.getBeginToken();
  String toString() => statement.toString();
}

class TypeVariableElementX extends ElementX implements TypeVariableElement {
  final Node cachedNode;
  TypeVariableType type;
  DartType bound;

  TypeVariableElementX(name, Element enclosing, this.cachedNode,
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
abstract class MetadataAnnotationX implements MetadataAnnotation {
  /**
   * The compile-time constant which this annotation resolves to.
   * In the mirror system, this would be an object mirror.
   */
  Constant get value;
  Element annotatedElement;
  int resolutionState;

  /**
   * The beginning token of this annotation, or [:null:] if it is synthetic.
   */
  Token get beginToken;

  MetadataAnnotationX([this.resolutionState = STATE_NOT_STARTED]);

  MetadataAnnotation ensureResolved(Compiler compiler) {
    if (resolutionState == STATE_NOT_STARTED) {
      compiler.resolver.resolveMetadataAnnotation(this);
    }
    return this;
  }

  String toString() => 'MetadataAnnotation($value, $resolutionState)';
}
