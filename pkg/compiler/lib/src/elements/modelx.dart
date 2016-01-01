// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library elements.modelx;

import '../common.dart';
import '../common/resolution.dart' show
    Resolution,
    Parsing;
import '../compiler.dart' show
    Compiler;
import '../constants/constant_constructors.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../diagnostics/messages.dart' show
    MessageTemplate;
import '../ordered_typeset.dart' show
    OrderedTypeSet;
import '../resolution/class_members.dart' show
    ClassMemberMixin;
import '../resolution/scope.dart' show
    ClassScope,
    LibraryScope,
    Scope,
    TypeDeclarationScope;
import '../resolution/resolution.dart' show
    AnalyzableElementX;
import '../resolution/tree_elements.dart' show
    TreeElements;
import '../resolution/typedefs.dart' show
    TypedefCyclicVisitor;
import '../script.dart';
import '../tokens/token.dart' show
    ErrorToken,
    Token;
import '../tokens/token_constants.dart' as Tokens show
    EOF_TOKEN;
import '../tree/tree.dart';
import '../util/util.dart';

import 'common.dart';
import 'elements.dart';
import 'visitor.dart' show
    ElementVisitor;

abstract class DeclarationSite {
}

abstract class ElementX extends Element with ElementCommon {
  static int elementHashCode = 0;

  final String name;
  final ElementKind kind;
  final Element enclosingElement;
  final int hashCode = ++elementHashCode;
  List<MetadataAnnotation> metadataInternal;

  ElementX(this.name, this.kind, this.enclosingElement) {
    assert(isError || implementationLibrary != null);
  }

  Modifiers get modifiers => Modifiers.EMPTY;

  Node parseNode(Parsing parsing) {
    parsing.reporter.internalError(this,
        'parseNode not implemented on $this.');
    return null;
  }

  void set metadata(List<MetadataAnnotation> metadata) {
    assert(metadataInternal == null);
    for (MetadataAnnotationX annotation in metadata) {
      assert(annotation.annotatedElement == null);
      annotation.annotatedElement = this;
    }
    metadataInternal = metadata;
  }

  Iterable<MetadataAnnotation> get metadata {
    if (isPatch && metadataInternal != null) {
      if (origin.metadata.isEmpty) {
        return metadataInternal;
      } else {
        return <MetadataAnnotation>[]
            ..addAll(origin.metadata)
            ..addAll(metadataInternal);
      }
    }
    return metadataInternal != null
        ? metadataInternal : const <MetadataAnnotation>[];
  }

  bool get isClosure => false;
  bool get isClassMember {
    // Check that this element is defined in the scope of a Class.
    return enclosingElement != null && enclosingElement.isClass;
  }
  bool get isInstanceMember => false;
  bool get isDeferredLoaderGetter => false;

  bool get isConst => modifiers.isConst;
  bool get isFinal => modifiers.isFinal;
  bool get isStatic => modifiers.isStatic;
  bool get isOperator => Elements.isOperatorName(name);

  bool get isSynthesized => false;

  bool get isMixinApplication => false;

  bool get isLocal => false;

  // TODO(johnniwinther): This breaks for libraries (for which enclosing
  // elements are null) and is invalid for top level variable declarations for
  // which the enclosing element is a VariableDeclarations and not a compilation
  // unit.
  bool get isTopLevel {
    return enclosingElement != null && enclosingElement.isCompilationUnit;
  }

  bool get isAssignable {
    if (isFinal || isConst) return false;
    if (isFunction || isConstructor) return false;
    return true;
  }

  Token get position => null;

  SourceSpan get sourcePosition {
    if (position == null) return null;
    Uri uri = compilationUnit.script.resourceUri;
    return new SourceSpan(
        uri, position.charOffset, position.charOffset + position.charCount);
  }

  Token findMyName(Token token) {
    return findNameToken(token, isConstructor, name, enclosingElement.name);
  }

  static Token findNameToken(Token token, bool isConstructor, String name,
                             String enclosingClassName) {
    // We search for the token that has the name of this element.
    // For constructors, that doesn't work because they may have
    // named formed out of multiple tokens (named constructors) so
    // for those we search for the class name instead.
    String needle = isConstructor ? enclosingClassName : name;
    // The unary '-' operator has a special element name (specified).
    if (needle == 'unary-') needle = '-';
    for (Token t = token; Tokens.EOF_TOKEN != t.kind; t = t.next) {
      if (t is !ErrorToken && needle == t.value) return t;
    }
    return token;
  }

  CompilationUnitElement get compilationUnit {
    Element element = this;
    while (!element.isCompilationUnit) {
      element = element.enclosingElement;
    }
    return element;
  }

  LibraryElement get library => enclosingElement.library;

  Name get memberName => new Name(name, library);

  LibraryElementX get implementationLibrary {
    Element element = this;
    while (!identical(element.kind, ElementKind.LIBRARY)) {
      element = element.enclosingElement;
    }
    return element;
  }

  ClassElement get enclosingClass {
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClass) return e;
    }
    return null;
  }

  Element get enclosingClassOrCompilationUnit {
   for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClass || e.isCompilationUnit) return e;
    }
    return null;
  }

  Element get outermostEnclosingMemberOrTopLevel {
    // TODO(lrn): Why is this called "Outermost"?
    // TODO(johnniwinther): Clean up this method: This method does not return
    // the outermost for elements in closure classses, but some call-sites rely
    // on that behavior.
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClassMember || e.isTopLevel) {
        return e;
      }
    }
    return null;
  }

  ClassElement get contextClass {
    ClassElement cls;
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClass) {
        // Record [e] instead of returning it directly. We need the last class
        // in the chain since the first classes might be closure classes.
        cls = e.declaration;
      }
    }
    return cls;
  }

  /**
   * Creates the scope for this element.
   */
  Scope buildScope() => enclosingElement.buildScope();

  String toString() {
    // TODO(johnniwinther): Test for nullness of name, or make non-nullness an
    // invariant for all element types?
    var nameText = name != null ? name : '?';
    if (enclosingElement != null && !isTopLevel) {
      String holderName = enclosingElement.name != null
          ? enclosingElement.name
          : '${enclosingElement.kind}?';
      return '$kind($holderName#${nameText})';
    } else {
      return '$kind(${nameText})';
    }
  }

  FunctionElement asFunctionElement() => null;

  bool get isAbstract => modifiers.isAbstract;

  bool get hasTreeElements => analyzableElement.hasTreeElements;

  TreeElements get treeElements => analyzableElement.treeElements;

  AnalyzableElement get analyzableElement {
    Element element = outermostEnclosingMemberOrTopLevel;
    if (element.isAbstractField || element.isPrefix) return element.library;
    return element;
  }

  DeclarationSite get declarationSite => null;

  void reuseElement() {
    throw "reuseElement isn't implemented on ${runtimeType}.";
  }
}

class ErroneousElementX extends ElementX implements ErroneousElement {
  final MessageKind messageKind;
  final Map messageArguments;

  ErroneousElementX(this.messageKind, this.messageArguments,
                    String name, Element enclosing)
      : super(name, ElementKind.ERROR, enclosing);

  bool get isTopLevel => false;

  bool get isSynthesized => true;

  bool get isCyclicRedirection => false;

  bool get isMalformed => true;

  PrefixElement get redirectionDeferredPrefix => null;

  AbstractFieldElement abstractField;

  unsupported() {
    throw 'unsupported operation on erroneous element';
  }

  get asyncMarker => AsyncMarker.SYNC;
  Iterable<MetadataAnnotation> get metadata => unsupported();
  bool get hasNode => false;
  get node => unsupported();
  get hasResolvedAst => false;
  get resolvedAst => unsupported();
  get type => unsupported();
  get cachedNode => unsupported();
  get functionSignature => unsupported();
  get parameters => unsupported();
  get patch => null;
  get origin => this;
  get immediateRedirectionTarget => unsupported();
  get nestedClosures => unsupported();
  get memberContext => unsupported();
  get executableContext => unsupported();
  get isExternal => unsupported();
  get constantConstructor => null;

  bool get isRedirectingGenerative => unsupported();
  bool get isRedirectingFactory => unsupported();

  computeType(Resolution resolution) => unsupported();

  bool get hasFunctionSignature => false;

  get effectiveTarget => this;

  computeEffectiveTargetType(InterfaceType newType) => unsupported();

  get definingConstructor => null;

  FunctionElement asFunctionElement() => this;

  String get message {
    return MessageTemplate.TEMPLATES[messageKind]
        .message(messageArguments).toString();
  }

  String toString() => '<$name: $message>';

  accept(ElementVisitor visitor, arg) {
    return visitor.visitErroneousElement(this, arg);
  }

  @override
  get isEffectiveTargetMalformed {
    throw new UnsupportedError("isEffectiveTargetMalformed");
  }

  @override
  bool get isFromEnvironmentConstructor => false;
}

/// A constructor that was synthesized to recover from a compile-time error.
class ErroneousConstructorElementX extends ErroneousElementX
    with PatchMixin<FunctionElement>,
         AnalyzableElementX,
         ConstantConstructorMixin
    implements ConstructorElementX {
  // TODO(ahe): Instead of subclassing [ErroneousElementX], this class should
  // be more like [ErroneousFieldElementX]. In particular, its kind should be
  // [ElementKind.GENERATIVE_CONSTRUCTOR], and it shouldn't throw as much.

  ErroneousConstructorElementX(
      MessageKind messageKind,
      Map messageArguments,
      String name,
      Element enclosing)
      : super(messageKind, messageArguments, name, enclosing);

  @override
  bool get isRedirectingGenerative => false;

  @override
  void set isRedirectingGenerative(_) {
    throw new UnsupportedError("isRedirectingGenerative");
  }

  @override
  bool get isRedirectingFactory => false;

  @override
  get definingElement {
    throw new UnsupportedError("definingElement");
  }

  @override
  get asyncMarker {
    throw new UnsupportedError("asyncMarker");
  }

  @override
  set asyncMarker(_) {
    throw new UnsupportedError("asyncMarker=");
  }

  @override
  get effectiveTargetInternal {
    throw new UnsupportedError("effectiveTargetInternal");
  }

  @override
  set effectiveTargetInternal(_) {
    throw new UnsupportedError("effectiveTargetInternal=");
  }

  @override
  get _effectiveTargetType {
    throw new UnsupportedError("_effectiveTargetType");
  }

  @override
  set _effectiveTargetType(_) {
    throw new UnsupportedError("_effectiveTargetType=");
  }

  @override
  get effectiveTargetType {
    throw new UnsupportedError("effectiveTargetType");
  }

  @override
  get _isEffectiveTargetMalformed {
    throw new UnsupportedError("_isEffectiveTargetMalformed");
  }

  @override
  set _isEffectiveTargetMalformed(_) {
    throw new UnsupportedError("_isEffectiveTargetMalformed=");
  }

  @override
  get isEffectiveTargetMalformed {
    throw new UnsupportedError("isEffectiveTargetMalformed");
  }

  @override
  void setEffectiveTarget(ConstructorElement target,
                            InterfaceType type,
                            {bool isMalformed: false}) {
    throw new UnsupportedError("setEffectiveTarget");
  }

  @override
  void _computeSignature(Resolution resolution) {
    throw new UnsupportedError("_computeSignature");
  }

  @override
  get typeCache {
    throw new UnsupportedError("typeCache");
  }

  @override
  set typeCache(_) {
    throw new UnsupportedError("typeCache=");
  }

  @override
  get immediateRedirectionTarget {
    throw new UnsupportedError("immediateRedirectionTarget");
  }

  @override
  set immediateRedirectionTarget(_) {
    throw new UnsupportedError("immediateRedirectionTarget=");
  }

  @override
  get _functionSignatureCache {
    throw new UnsupportedError("functionSignatureCache");
  }

  @override
  set _functionSignatureCache(_) {
    throw new UnsupportedError("functionSignatureCache=");
  }

  @override
  set functionSignature(_) {
    throw new UnsupportedError("functionSignature=");
  }

  @override
  get nestedClosures {
    throw new UnsupportedError("nestedClosures");
  }

  @override
  set nestedClosures(_) {
    throw new UnsupportedError("nestedClosures=");
  }

  @override
  set redirectionDeferredPrefix(_) {
    throw new UnsupportedError("redirectionDeferredPrefix=");
  }
}

/// A message attached to a [WarnOnUseElementX].
class WrappedMessage {
  /// The message position. If [:null:] the position of the reference to the
  /// [WarnOnUseElementX] is used.
  final Spannable spannable;

  /**
   * The message to report on resolving a wrapped element.
   */
  final MessageKind messageKind;

  /**
   * The message arguments to report on resolving a wrapped element.
   */
  final Map messageArguments;

  WrappedMessage(this.spannable, this.messageKind, this.messageArguments);
}

class WarnOnUseElementX extends ElementX implements WarnOnUseElement {
  /// Warning to report on resolving this element.
  final WrappedMessage warning;

  /// Info to report on resolving this element.
  final WrappedMessage info;

  /// The element whose usage cause a warning.
  final Element wrappedElement;

  WarnOnUseElementX(WrappedMessage this.warning, WrappedMessage this.info,
                    Element enclosingElement, Element wrappedElement)
      : this.wrappedElement = wrappedElement,
        super(wrappedElement.name, ElementKind.WARN_ON_USE, enclosingElement);

  Element unwrap(DiagnosticReporter reporter, Spannable usageSpannable) {
    var unwrapped = wrappedElement;
    if (warning != null) {
      Spannable spannable = warning.spannable;
      if (spannable == null) spannable = usageSpannable;
      DiagnosticMessage warningMessage = reporter.createMessage(
          spannable, warning.messageKind, warning.messageArguments);
      List<DiagnosticMessage> infos = <DiagnosticMessage>[];
      if (info != null) {
        Spannable spannable = info.spannable;
        if (spannable == null) spannable = usageSpannable;
        infos.add(reporter.createMessage(
            spannable, info.messageKind, info.messageArguments));
      }
      reporter.reportWarning(warningMessage, infos);
    }
    if (unwrapped.isWarnOnUse) {
      unwrapped = unwrapped.unwrap(reporter, usageSpannable);
    }
    return unwrapped;
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitWarnOnUseElement(this, arg);
  }
}

abstract class AmbiguousElementX extends ElementX implements AmbiguousElement {
  /**
   * The message to report on resolving this element.
   */
  final MessageKind messageKind;

  /**
   * The message arguments to report on resolving this element.
   */
  final Map messageArguments;

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

  Setlet flatten() {
    Element element = this;
    var set = new Setlet();
    while (element.isAmbiguous) {
      AmbiguousElement ambiguous = element;
      set.add(ambiguous.newElement);
      element = ambiguous.existingElement;
    }
    set.add(element);
    return set;
  }

  List<DiagnosticMessage> computeInfos(Element context,
                                       DiagnosticReporter reporter) {
    return const <DiagnosticMessage>[];
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitAmbiguousElement(this, arg);
  }

  bool get isTopLevel => false;

  DynamicType get type => const DynamicType();
}

/// Element synthesized to diagnose an ambiguous import.
class AmbiguousImportX extends AmbiguousElementX {
  AmbiguousImportX(
      MessageKind messageKind,
      Map messageArguments,
      Element enclosingElement, Element existingElement, Element newElement)
      : super(messageKind, messageArguments, enclosingElement, existingElement,
              newElement);

  List<DiagnosticMessage> computeInfos(
      Element context,
      DiagnosticReporter reporter) {
    List<DiagnosticMessage> infos = <DiagnosticMessage>[];
    Setlet ambiguousElements = flatten();
    MessageKind code = (ambiguousElements.length == 1)
        ? MessageKind.AMBIGUOUS_REEXPORT : MessageKind.AMBIGUOUS_LOCATION;
    LibraryElementX importer = context.library;
    for (Element element in ambiguousElements) {
      Map arguments = {'name': element.name};
      infos.add(reporter.createMessage(element, code, arguments));
      reporter.withCurrentElement(importer, () {
        for (ImportElement import in importer.importers.getImports(element)) {
          infos.add(reporter.createMessage(
              import, MessageKind.IMPORTED_HERE, arguments));
        }
      });
    }
    return infos;
  }
}

/// Element synthesized to recover from a duplicated member of an element.
class DuplicatedElementX extends AmbiguousElementX {
  DuplicatedElementX(
      MessageKind messageKind,
      Map messageArguments,
      Element enclosingElement, Element existingElement, Element newElement)
      : super(messageKind, messageArguments, enclosingElement, existingElement,
              newElement);

  bool get isMalformed => true;
}

class ScopeX {
  final Map<String, Element> contents = new Map<String, Element>();

  bool get isEmpty => contents.isEmpty;
  Iterable<Element> get values => contents.values;

  Element lookup(String name) {
    return contents[name];
  }

  void add(Element element, DiagnosticReporter reporter) {
    String name = element.name;
    if (element.isAccessor) {
      addAccessor(element, contents[name], reporter);
    } else {
      Element existing = contents.putIfAbsent(name, () => element);
      if (!identical(existing, element)) {
        reporter.reportError(
            reporter.createMessage(
                element,
                MessageKind.DUPLICATE_DEFINITION,
                {'name': name}),
            <DiagnosticMessage>[
                reporter.createMessage(
                    existing,
                    MessageKind.EXISTING_DEFINITION,
                    {'name': name}),
            ]);
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
  void addAccessor(AccessorElementX accessor,
                   Element existing,
                   DiagnosticReporter reporter) {
    void reportError(Element other) {
      reporter.reportError(
          reporter.createMessage(
              accessor,
              MessageKind.DUPLICATE_DEFINITION,
              {'name': accessor.name}),
          <DiagnosticMessage>[
              reporter.createMessage(
                  other,
                  MessageKind.EXISTING_DEFINITION,
                  {'name': accessor.name}),
          ]);

      contents[accessor.name] = new DuplicatedElementX(
          MessageKind.DUPLICATE_DEFINITION, {'name': accessor.name},
          accessor.memberContext.enclosingElement, other, accessor);
    }

    if (existing != null) {
      if (!identical(existing.kind, ElementKind.ABSTRACT_FIELD)) {
        reportError(existing);
        return;
      } else {
        AbstractFieldElementX field = existing;
        accessor.abstractField = field;
        if (accessor.isGetter) {
          if (field.getter != null && field.getter != accessor) {
            reportError(field.getter);
            return;
          }
          field.getter = accessor;
        } else {
          assert(accessor.isSetter);
          if (field.setter != null && field.setter != accessor) {
            reportError(field.setter);
            return;
          }
          field.setter = accessor;
        }
      }
    } else {
      Element container = accessor.enclosingClassOrCompilationUnit;
      AbstractFieldElementX field =
          new AbstractFieldElementX(accessor.name, container);
      accessor.abstractField = field;
      if (accessor.isGetter) {
        field.getter = accessor;
      } else {
        field.setter = accessor;
      }
      add(field, reporter);
    }
  }
}

class CompilationUnitElementX extends ElementX
    with CompilationUnitElementCommon
    implements CompilationUnitElement {
  final Script script;
  PartOf partTag;
  Link<Element> localMembers = const Link<Element>();

  CompilationUnitElementX(Script script, LibraryElementX library)
    : this.script = script,
      super(script.name,
            ElementKind.COMPILATION_UNIT,
            library) {
    library.addCompilationUnit(this);
  }

  @override
  LibraryElementX get library => enclosingElement.declaration;

  void set metadata(List<MetadataAnnotation> metadata) {
    for (MetadataAnnotationX annotation in metadata) {
      assert(annotation.annotatedElement == null);
      annotation.annotatedElement = this;
    }
    // TODO(johnniwinther): Remove this work-around when import, export,
    // part, and part-of declarations are elements.
    if (metadataInternal == null) {
      metadataInternal = <MetadataAnnotation>[];
    }
    metadataInternal.addAll(metadata);
  }

  void forEachLocalMember(f(Element element)) {
    localMembers.forEach(f);
  }

  void addMember(Element element, DiagnosticReporter reporter) {
    // Keep a list of top level members.
    localMembers = localMembers.prepend(element);
    // Provide the member to the library to build scope.
    if (enclosingElement.isPatch) {
      implementationLibrary.addMember(element, reporter);
    } else {
      library.addMember(element, reporter);
    }
  }

  void setPartOf(PartOf tag, DiagnosticReporter reporter) {
    LibraryElementX library = enclosingElement;
    if (library.entryCompilationUnit == this) {
      // This compilation unit is loaded as a library. The error is reported by
      // the library loader.
      partTag = tag;
      return;
    }
    if (!localMembers.isEmpty) {
      reporter.reportErrorMessage(
          tag, MessageKind.BEFORE_TOP_LEVEL);
      return;
    }
    if (partTag != null) {
      reporter.reportWarningMessage(tag, MessageKind.DUPLICATED_PART_OF);
      return;
    }
    partTag = tag;
    LibraryName libraryTag = library.libraryTag;
    String actualName = tag.name.toString();
    if (libraryTag != null) {
      String expectedName = libraryTag.name.toString();
      if (expectedName != actualName) {
        reporter.reportWarningMessage(
            tag.name,
            MessageKind.LIBRARY_NAME_MISMATCH,
            {'libraryName': expectedName});
      }
    } else {
      reporter.reportWarning(
          reporter.createMessage(
              library,
              MessageKind.MISSING_LIBRARY_NAME,
              {'libraryName': actualName}),
          <DiagnosticMessage>[
              reporter.createMessage(
                  tag.name,
                  MessageKind.THIS_IS_THE_PART_OF_TAG),
          ]);
    }
  }

  bool get hasMembers => !localMembers.isEmpty;

  Element get analyzableElement => library;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitCompilationUnitElement(this, arg);
  }
}

/// Map from [Element] to the [ImportElement]s throught which it was imported.
///
/// This is used for error reporting and deferred loading.
class Importers {
  Map<Element, List<ImportElement>> importers =
      new Map<Element, List<ImportElement>>();

  /// Returns the the list of [ImportElement]s through which [element] was
  /// imported.
  List<ImportElement> getImports(Element element) {
    List<ImportElement> imports = importers[element];
    return imports != null ? imports : const <ImportElement>[];
  }

  /// Returns the first [ImportElement] through which [element] was imported.
  ImportElement getImport(Element element) => getImports(element).first;

  /// Register [element] as imported through [import];
  void registerImport(Element element, ImportElement import) {
    importers.putIfAbsent(element, () => <ImportElement>[]).add(import);
  }
}

class ImportScope {
  /**
   * Map for elements imported through import declarations.
   *
   * Addition to the map is performed by [addImport]. Lookup is done trough
   * [find].
   */
  final Map<String, Element> importScope =
      new Map<String, Element>();

  /**
   * Adds [element] to the import scope of this library.
   *
   * If an element by the same name is already in the imported scope, an
   * [ErroneousElement] will be put in the imported scope, allowing for
   * detection of ambiguous uses of imported names.
   */
  void addImport(Element enclosingElement,
                 Element element,
                 ImportElement import,
                 DiagnosticReporter reporter) {
    LibraryElementX library = enclosingElement.library;
    Importers importers = library.importers;

    String name = element.name;

    // The loadLibrary function always shadows existing bindings to that name.
    if (element.isDeferredLoaderGetter) {
      importScope.remove(name);
      // TODO(sigurdm): Print a hint.
    }
    Element existing = importScope.putIfAbsent(name, () => element);
    importers.registerImport(element, import);

    void registerWarnOnUseElement(ImportElement import,
                                  MessageKind messageKind,
                                  Element hidingElement,
                                  Element hiddenElement) {
      Uri hiddenUri = hiddenElement.library.canonicalUri;
      Uri hidingUri = hidingElement.library.canonicalUri;
      Element element = new WarnOnUseElementX(
          new WrappedMessage(
              null, // Report on reference to [hidingElement].
              messageKind,
              {'name': name, 'hiddenUri': hiddenUri, 'hidingUri': hidingUri}),
          new WrappedMessage(
              reporter.spanFromSpannable(import),
              MessageKind.IMPORTED_HERE,
              {'name': name}),
          enclosingElement, hidingElement);
      importScope[name] = element;
      importers.registerImport(element, import);
    }

    if (existing != element) {
      ImportElement existingImport = importers.getImport(existing);
      if (existing.library.isPlatformLibrary &&
          !element.library.isPlatformLibrary) {
        // [existing] is implicitly hidden.
        registerWarnOnUseElement(
            import, MessageKind.HIDDEN_IMPORT, element, existing);
      } else if (!existing.library.isPlatformLibrary &&
                 element.library.isPlatformLibrary) {
        // [element] is implicitly hidden.
        if (import.isSynthesized) {
          // [element] is imported implicitly (probably through dart:core).
          registerWarnOnUseElement(
              existingImport, MessageKind.HIDDEN_IMPLICIT_IMPORT,
              existing, element);
        } else {
          registerWarnOnUseElement(
              import, MessageKind.HIDDEN_IMPORT, existing, element);
        }
      } else {
        Element ambiguousElement = new AmbiguousImportX(
            MessageKind.DUPLICATE_IMPORT, {'name': name},
            enclosingElement, existing, element);
        importScope[name] = ambiguousElement;
        importers.registerImport(ambiguousElement, import);
        importers.registerImport(ambiguousElement, existingImport);
      }
    }
  }

  Element operator [](String name) => importScope[name];

  void forEach(f(Element element)) => importScope.values.forEach(f);
}

abstract class LibraryDependencyElementX extends ElementX {
  final LibraryDependency node;
  final Uri uri;
  LibraryElement libraryDependency;

  LibraryDependencyElementX(CompilationUnitElement enclosingElement,
                            ElementKind kind,
                            this.node,
                            this.uri)
      : super('', kind, enclosingElement);

  @override
  List<MetadataAnnotation> get metadata => node.metadata;

  void set metadata(value) {
    // The metadata is stored on [libraryDependency].
    throw new SpannableAssertionFailure(
        this, 'Cannot set metadata on a import/export.');
  }

  @override
  Token get position => node.getBeginToken();

  SourceSpan get sourcePosition {
    return new SourceSpan.fromNode(compilationUnit.script.resourceUri, node);
  }

  String toString() => '$kind($uri)';
}

class ImportElementX extends LibraryDependencyElementX
    implements ImportElement {
  PrefixElementX prefix;

  ImportElementX(CompilationUnitElement enclosingElement, Import node, Uri uri)
      : super(enclosingElement, ElementKind.IMPORT, node, uri);

  @override
  Import get node => super.node;

  @override
  LibraryElement get importedLibrary => libraryDependency;

  @override
  accept(ElementVisitor visitor, arg) => visitor.visitImportElement(this, arg);

  @override
  bool get isDeferred => node.isDeferred;
}

class SyntheticImportElement extends ImportElementX {
  SyntheticImportElement(CompilationUnitElement enclosingElement, Uri uri)
      : super(enclosingElement, null, uri);

  @override
  Token get position => library.position;

  @override
  bool get isSynthesized => true;

  @override
  bool get isDeferred => false;

  @override
  List<MetadataAnnotation> get metadata => const <MetadataAnnotation>[];

  @override
  SourceSpan get sourcePosition => library.sourcePosition;
}


class ExportElementX extends LibraryDependencyElementX
    implements ExportElement {

  ExportElementX(CompilationUnitElement enclosingElement, Export node, Uri uri)
      : super(enclosingElement, ElementKind.EXPORT, node, uri);

  Export get node => super.node;

  @override
  LibraryElement get exportedLibrary => libraryDependency;

  @override
  accept(ElementVisitor visitor, arg) => visitor.visitExportElement(this, arg);
}

class LibraryElementX
    extends ElementX
    with LibraryElementCommon,
         AnalyzableElementX,
         PatchMixin<LibraryElementX>
    implements LibraryElement {
  final Uri canonicalUri;

  /// True if the constructing script was synthesized.
  final bool isSynthesized;

  CompilationUnitElement entryCompilationUnit;
  Link<CompilationUnitElement> compilationUnits =
      const Link<CompilationUnitElement>();
  LinkBuilder<LibraryTag> tagsBuilder = new LinkBuilder<LibraryTag>();
  List<LibraryTag> tagsCache;
  LibraryName libraryTag;
  Link<Element> localMembers = const Link<Element>();
  final ScopeX localScope = new ScopeX();
  final ImportScope importScope = new ImportScope();

  /// A mapping from an imported element to the "import" tag.
  final Importers importers = new Importers();

  /**
   * Link for elements exported either through export declarations or through
   * declaration. This field should not be accessed directly but instead through
   * the [exports] getter.
   *
   * [LibraryDependencyHandler] sets this field through [setExports] when the
   * library is loaded.
   */
  Link<Element> slotForExports;

  List<ImportElement> _imports = <ImportElement>[];
  List<ExportElement> _exports = <ExportElement>[];

  final Map<LibraryDependency, LibraryElement> tagMapping =
      new Map<LibraryDependency, LibraryElement>();

  LibraryElementX(Script script,
                  [Uri canonicalUri, LibraryElementX origin])
    : this.canonicalUri =
          ((canonicalUri == null) ? script.readableUri : canonicalUri),
      this.isSynthesized = script.isSynthesized,
      super(script.name, ElementKind.LIBRARY, null) {
    entryCompilationUnit = new CompilationUnitElementX(script, this);
    if (origin != null) {
      origin.applyPatch(this);
    }
  }

  Iterable<MetadataAnnotation> get metadata {
    if (libraryTag != null) {
      return libraryTag.metadata;
    }
    return const <MetadataAnnotation>[];
  }

  void set metadata(value) {
    // The metadata is stored on [libraryTag].
    throw new SpannableAssertionFailure(this, 'Cannot set metadata on Library');
  }

  CompilationUnitElement get compilationUnit => entryCompilationUnit;

  Element get analyzableElement => this;

  void addCompilationUnit(CompilationUnitElement element) {
    compilationUnits = compilationUnits.prepend(element);
  }

  void addTag(LibraryTag tag, DiagnosticReporter reporter) {
    if (tagsCache != null) {
      reporter.internalError(tag,
          "Library tags for $this have already been computed.");
    }
    tagsBuilder.addLast(tag);
  }

  Iterable<LibraryTag> get tags {
    if (tagsCache == null) {
      tagsCache = tagsBuilder.toList();
      tagsBuilder = null;
    }
    return tagsCache;
  }

  void addImportDeclaration(ImportElement import) {
    _imports.add(import);
  }

  Iterable<ImportElement> get imports => _imports;

  void addExportDeclaration(ExportElement export) {
    _exports.add(export);
  }

  Iterable<ExportElement> get exports => _exports;

  /**
   * Adds [element] to the import scope of this library.
   *
   * If an element by the same name is already in the imported scope, an
   * [ErroneousElement] will be put in the imported scope, allowing for
   * detection of ambiguous uses of imported names.
   */
  void addImport(Element element,
                 ImportElement import,
                 DiagnosticReporter reporter) {
    importScope.addImport(this, element, import, reporter);
  }

  void addMember(Element element, DiagnosticReporter reporter) {
    localMembers = localMembers.prepend(element);
    addToScope(element, reporter);
  }

  void addToScope(Element element, DiagnosticReporter reporter) {
    localScope.add(element, reporter);
  }

  Element localLookup(String elementName) {
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

  LibraryElement get library => isPatch ? origin : this;

  /**
   * Look up a top-level element in this library. The element could
   * potentially have been imported from another library. Returns
   * null if no such element exist and an [ErroneousElement] if multiple
   * elements have been imported.
   */
  Element find(String elementName) {
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
  Element findLocal(String elementName) {
    // TODO((johnniwinther): How to handle injected elements in the patch
    // library?
    Element result = localScope.lookup(elementName);
    if (result == null && isPatch) {
      return origin.findLocal(elementName);
    }
    return result;
  }

  Element findExported(String elementName) {
    assert(invariant(this, exportsHandled,
                     message: 'Exports not handled on $this'));
    for (Link link = slotForExports; !link.isEmpty; link = link.tail) {
      Element element = link.head;
      if (element.name == elementName) return element;
    }
    return null;
  }

  void forEachExport(f(Element element)) {
    assert(invariant(this, exportsHandled,
                     message: 'Exports not handled on $this'));
    slotForExports.forEach((Element e) => f(e));
  }

  Iterable<ImportElement> getImportsFor(Element element) {
    return importers.getImports(element);
  }

  void forEachImport(f(Element element)) => importScope.forEach(f);

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
      return !Name.isPrivateName(element.name);
    });
  }

  bool get hasLibraryName => libraryTag != null;

  String get libraryName {
    if (libraryTag == null) return '';
    return libraryTag.name.toString();
  }

  String get libraryOrScriptName {
    if (libraryTag != null) {
      return libraryTag.name.toString();
    } else {
      // Use the file name as script name.
      String path = canonicalUri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }

  Scope buildScope() => new LibraryScope(this);

  String toString() {
    if (origin != null) {
      return 'patch library(${canonicalUri})';
    } else if (patch != null) {
      return 'origin library(${canonicalUri})';
    } else {
      return 'library(${canonicalUri})';
    }
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitLibraryElement(this, arg);
  }

  // TODO(johnniwinther): Remove these when issue 18630 is fixed.
  LibraryElementX get patch => super.patch;
  LibraryElementX get origin => super.origin;
}

class PrefixElementX extends ElementX implements PrefixElement {
  Token firstPosition;

  final ImportScope importScope = new ImportScope();

  bool get isDeferred => deferredImport != null;

  // Only needed for deferred imports.
  final ImportElement deferredImport;

  PrefixElementX(String prefix,
                 Element enclosing,
                 this.firstPosition,
                 this.deferredImport)
      : super(prefix, ElementKind.PREFIX, enclosing);

  bool get isTopLevel => false;

  Element lookupLocalMember(String memberName) => importScope[memberName];

  DartType computeType(Resolution resolution) => const DynamicType();

  Token get position => firstPosition;

  void addImport(Element element,
                 ImportElement import,
                 DiagnosticReporter reporter) {
    importScope.addImport(this, element, import, reporter);
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitPrefixElement(this, arg);
  }

  String toString() => '$kind($name)';
}

class TypedefElementX extends ElementX
    with AstElementMixin,
         AnalyzableElementX,
         TypeDeclarationElementX<TypedefType>
    implements TypedefElement {
  Typedef cachedNode;

  /**
   * The type annotation which defines this typedef.
   */
  DartType aliasCache;

  DartType get alias {
    assert(invariant(this, hasBeenCheckedForCycles,
        message: "$this has not been checked for cycles."));
    return aliasCache;
  }

  /// [:true:] if the typedef has been checked for cyclic reference.
  bool hasBeenCheckedForCycles = false;

  int resolutionState = STATE_NOT_STARTED;

  TypedefElementX(String name, Element enclosing)
      : super(name, ElementKind.TYPEDEF, enclosing);

  bool get hasNode => cachedNode != null;

  Typedef get node {
    assert(invariant(this, cachedNode != null,
        message: "Node has not been computed for $this."));
    return cachedNode;
  }

  /**
   * Function signature for a typedef of a function type. The signature is
   * kept to provide full information about parameter names through the mirror
   * system.
   *
   * The [functionSignature] is not available until the typedef element has been
   * resolved.
   */
  FunctionSignature functionSignature;

  TypedefType computeType(Resolution resolution) {
    if (thisTypeCache != null) return thisTypeCache;
    Typedef node = parseNode(resolution.parsing);
    setThisAndRawTypes(createTypeVariables(node.typeParameters));
    ensureResolved(resolution);
    return thisTypeCache;
  }

  void ensureResolved(Resolution resolution) {
    if (resolutionState == STATE_NOT_STARTED) {
      resolution.resolveTypedef(this);
    }
  }

  TypedefType createType(List<DartType> typeArguments) {
    return new TypedefType(this, typeArguments);
  }

  Scope buildScope() {
    return new TypeDeclarationScope(enclosingElement.buildScope(), this);
  }

  void checkCyclicReference(Resolution resolution) {
    if (hasBeenCheckedForCycles) return;
    TypedefCyclicVisitor visitor =
        new TypedefCyclicVisitor(resolution.reporter, this);
    computeType(resolution).accept(visitor, null);
    hasBeenCheckedForCycles = true;
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitTypedefElement(this, arg);
  }

  // A typedef cannot be patched therefore defines itself.
  AstElement get definingElement => this;
}

// This class holds common information for a list of variable or field
// declarations. It contains the node, and the type. A [VariableElementX]
// forwards its [computeType] and [parseNode] methods to this class.
class VariableList implements DeclarationSite {
  VariableDefinitions definitions;
  DartType type;
  final Modifiers modifiers;
  List<MetadataAnnotation> metadataInternal;

  VariableList(Modifiers this.modifiers);

  VariableList.node(VariableDefinitions node, this.type)
      : this.definitions = node,
        this.modifiers = node.modifiers {
    assert(modifiers != null);
  }

  Iterable<MetadataAnnotation> get metadata {
    return metadataInternal != null
        ? metadataInternal : const <MetadataAnnotation>[];
  }

  void set metadata(List<MetadataAnnotation> metadata) {
    if (metadata.isEmpty) {
      // For a multi declaration like:
      //
      //    @foo @bar var a, b, c
      //
      // the metadata list is reported through the declaration of `a`, and `b`
      // and `c` report an empty list of metadata.
      return;
    }
    assert(metadataInternal == null);
    metadataInternal = metadata;
  }

  VariableDefinitions parseNode(Element element, Parsing parsing) {
    return definitions;
  }

  DartType computeType(Element element, Resolution resolution) => type;
}

abstract class ConstantVariableMixin implements VariableElement {
  ConstantExpression constantCache;

  ConstantExpression get constant {
    if (isPatch) {
      ConstantVariableMixin originVariable = origin;
      return originVariable.constant;
    }
    assert(invariant(this, constantCache != null,
        message: "Constant has not been computed for $this."));
    return constantCache;
  }

  void set constant(ConstantExpression value) {
    if (isPatch) {
      ConstantVariableMixin originVariable = origin;
      originVariable.constant = value;
      return;
    }
    assert(invariant(
        this, constantCache == null || constantCache == value,
        message: "Constant has already been computed for $this. "
                 "Existing constant: "
                 "${constantCache != null ? constantCache.getText() : ''}, "
                 "New constant: ${value != null ? value.getText() : ''}."));
    constantCache = value;
  }
}

abstract class VariableElementX extends ElementX
    with AstElementMixin, ConstantVariableMixin
    implements VariableElement {
  final Token token;
  final VariableList variables;
  VariableDefinitions definitionsCache;
  Expression initializerCache;

  Modifiers get modifiers => variables.modifiers;

  VariableElementX(String name,
                   ElementKind kind,
                   Element enclosingElement,
                   VariableList variables,
                   this.token)
    : this.variables = variables,
      super(name, kind, enclosingElement);

  // TODO(johnniwinther): Ensure that the [TreeElements] for this variable hold
  // the mappings for all its metadata.
  Iterable<MetadataAnnotation> get metadata => variables.metadata;

  void set metadata(List<MetadataAnnotation> metadata) {
    for (MetadataAnnotationX annotation in metadata) {
      assert(annotation.annotatedElement == null);
      annotation.annotatedElement = this;
    }
    variables.metadata = metadata;
  }

  // A variable cannot be patched therefore defines itself.
  AstElement get definingElement => this;

  bool get hasNode => definitionsCache != null;

  VariableDefinitions get node {
    assert(invariant(this, definitionsCache != null,
        message: "Node has not been computed for $this."));
    return definitionsCache;
  }

  Expression get initializer {
    assert(invariant(this, definitionsCache != null,
        message: "Initializer has not been computed for $this."));
    return initializerCache;
  }

  Node parseNode(Parsing parsing) {
    if (definitionsCache != null) return definitionsCache;

    VariableDefinitions definitions = variables.parseNode(this, parsing);
    createDefinitions(definitions);
    return definitionsCache;
  }

  void createDefinitions(VariableDefinitions definitions) {
    assert(invariant(this, definitionsCache == null,
        message: "VariableDefinitions has already been computed for $this."));
    Expression node;
    int count = 0;
    for (Link<Node> link = definitions.definitions.nodes;
         !link.isEmpty; link = link.tail) {
      Expression initializedIdentifier = link.head;
      Identifier identifier = initializedIdentifier.asIdentifier();
      if (identifier == null) {
        SendSet sendSet = initializedIdentifier.asSendSet();
        identifier = sendSet.selector.asIdentifier();
        if (identical(name, identifier.source)) {
          node = initializedIdentifier;
          initializerCache = sendSet.arguments.first;
        }
      } else if (identical(name, identifier.source)) {
        node = initializedIdentifier;
      }
      count++;
    }
    invariant(definitions, node != null, message: "Could not find '$name'.");
    if (count == 1) {
      definitionsCache = definitions;
    } else {
      // Create a [VariableDefinitions] node for the single definition of
      // [node].
      definitionsCache = new VariableDefinitions(definitions.type,
          definitions.modifiers, new NodeList(
              definitions.definitions.beginToken,
              const Link<Node>().prepend(node),
              definitions.definitions.endToken));
    }
  }

  DartType computeType(Resolution resolution) {
    if (variables.type != null) return variables.type;
    // Call [parseNode] to ensure that [definitionsCache] and [initializerCache]
    // are set as a consequence of calling [computeType].
    parseNode(resolution.parsing);
    return variables.computeType(this, resolution);
  }

  DartType get type {
    assert(invariant(this, variables.type != null,
        message: "Type has not been computed for $this."));
    return variables.type;
  }

  bool get isInstanceMember => isClassMember && !isStatic;

  // Note: cachedNode.beginToken will not be correct in all
  // cases, for example, for function typed parameters.
  Token get position => token;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitVariableElement(this, arg);
  }

  DeclarationSite get declarationSite => variables;
}

class LocalVariableElementX extends VariableElementX
    implements LocalVariableElement {
  LocalVariableElementX(String name,
                        ExecutableElement enclosingElement,
                        VariableList variables,
                        Token token)
      : super(name, ElementKind.VARIABLE, enclosingElement, variables, token) {
    createDefinitions(variables.definitions);
  }

  ExecutableElement get executableContext => enclosingElement;

  MemberElement get memberContext => executableContext.memberContext;

  bool get isLocal => true;
}

class FieldElementX extends VariableElementX
    with AnalyzableElementX implements FieldElement {
  List<FunctionElement> nestedClosures = new List<FunctionElement>();

  FieldElementX(Identifier name,
                Element enclosingElement,
                VariableList variables)
    : super(name.source, ElementKind.FIELD, enclosingElement,
            variables, name.token);

  accept(ElementVisitor visitor, arg) {
    return visitor.visitFieldElement(this, arg);
  }

  MemberElement get memberContext => this;

  void reuseElement() {
    super.reuseElement();
    nestedClosures.clear();
  }

  FieldElementX copyWithEnclosing(Element enclosingElement) {
    return new FieldElementX(
        new Identifier(token), enclosingElement, variables);
  }
}

/// A field that was synthesized to recover from a compile-time error.
class ErroneousFieldElementX extends ElementX
    with ConstantVariableMixin implements FieldElementX {
  final VariableList variables;

  ErroneousFieldElementX(Identifier name, Element enclosingElement)
      : variables = new VariableList(Modifiers.EMPTY)
            ..definitions = new VariableDefinitions(
                null, Modifiers.EMPTY, new NodeList.singleton(name))
            ..type = const DynamicType(),
        super(name.source, ElementKind.FIELD, enclosingElement);

  VariableDefinitions get definitionsCache => variables.definitions;

  set definitionsCache(VariableDefinitions _) {
    throw new UnsupportedError("definitionsCache=");
  }

  bool get hasNode => true;

  VariableDefinitions get node => definitionsCache;

  bool get hasResolvedAst => false;

  ResolvedAst get resolvedAst {
    throw new UnsupportedError("resolvedAst");
  }

  DynamicType get type => const DynamicType();

  Token get token => node.getBeginToken();

  get initializerCache {
    throw new UnsupportedError("initializerCache");
  }

  set initializerCache(_) {
    throw new UnsupportedError("initializerCache=");
  }

  void createDefinitions(VariableDefinitions definitions) {
    throw new UnsupportedError("createDefinitions");
  }

  get initializer => null;

  bool get isMalformed => true;

  get nestedClosures {
    throw new UnsupportedError("nestedClosures");
  }

  set nestedClosures(_) {
    throw new UnsupportedError("nestedClosures=");
  }

  // TODO(ahe): Should this throw or do nothing?
  accept(ElementVisitor visitor, arg) {
    return visitor.visitFieldElement(this, arg);
  }

  // TODO(ahe): Should return the context of the error site?
  MemberElement get memberContext => this;

  // TODO(ahe): Should return the definingElement of the error site?
  AstElement get definingElement => this;

  void reuseElement() {
    throw new UnsupportedError("reuseElement");
  }

  FieldElementX copyWithEnclosing(Element enclosingElement) {
    throw new UnsupportedError("copyWithEnclosing");
  }

  DartType computeType(Resolution resolution) => type;
}

/// [Element] for a parameter-like element.
class FormalElementX extends ElementX
    with AstElementMixin
    implements FormalElement {
  final VariableDefinitions definitions;
  final Identifier identifier;
  DartType typeCache;

  /**
   * Function signature for a variable with a function type. The signature is
   * kept to provide full information about parameter names through the mirror
   * system.
   */
  FunctionSignature _functionSignatureCache;

  FormalElementX(ElementKind elementKind,
                 FunctionTypedElement enclosingElement,
                 this.definitions,
                 Identifier identifier)
      : this.identifier = identifier,
        super(identifier.source, elementKind, enclosingElement);

  FunctionTypedElement get functionDeclaration => enclosingElement;

  Modifiers get modifiers => definitions.modifiers;

  Token get position => identifier.getBeginToken();

  Node parseNode(Parsing parsing) => definitions;

  DartType computeType(Resolution resolution) {
    assert(invariant(this, type != null,
        message: "Parameter type has not been set for $this."));
    return type;
  }

  DartType get type {
    assert(invariant(this, typeCache != null,
            message: "Parameter type has not been set for $this."));
        return typeCache;
  }

  FunctionSignature get functionSignature {
    assert(invariant(this, _functionSignatureCache != null,
        message: "Parameter signature has not been computed for $this."));
    return _functionSignatureCache;
  }

  void set functionSignature(FunctionSignature value) {
    assert(invariant(this, _functionSignatureCache == null,
        message: "Parameter signature has already been computed for $this."));
    _functionSignatureCache = value;
    typeCache = _functionSignatureCache.type;
  }

  bool get hasNode => true;

  VariableDefinitions get node => definitions;

  FunctionType get functionType => type;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitFormalElement(this, arg);
  }

  // A parameter is defined by the declaration element.
  AstElement get definingElement => declaration;
}

/// [Element] for a formal parameter.
///
/// A [ParameterElementX] can be patched. A parameter of an external method is
/// patched with the corresponding parameter of the patch method. This is done
/// to ensure that default values on parameters are computed once (on the
/// origin parameter) but can be found through both the origin and the patch.
abstract class ParameterElementX extends FormalElementX
    with PatchMixin<ParameterElement>,
         ConstantVariableMixin
    implements ParameterElement {
  final Expression initializer;
  final bool isOptional;
  final bool isNamed;

  ParameterElementX(ElementKind elementKind,
                    FunctionElement functionDeclaration,
                    VariableDefinitions definitions,
                    Identifier identifier,
                    this.initializer,
                    {this.isOptional: false,
                     this.isNamed: false})
      : super(elementKind, functionDeclaration, definitions, identifier);

  FunctionElement get functionDeclaration => enclosingElement;

  ExecutableElement get executableContext => enclosingElement;

  MemberElement get memberContext => executableContext.memberContext;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitParameterElement(this, arg);
  }

  bool get isLocal => true;

  String toString() {
    if (isPatched) {
      return 'origin ${super.toString()}';
    } else if (isPatch) {
      return 'patch ${super.toString()}';
    }
    return super.toString();
  }
}

class LocalParameterElementX extends ParameterElementX
    implements LocalParameterElement {


  LocalParameterElementX(FunctionElement functionDeclaration,
                         VariableDefinitions definitions,
                         Identifier identifier,
                         Expression initializer,
                         {bool isOptional: false,
                          bool isNamed: false})
      : super(ElementKind.PARAMETER, functionDeclaration,
              definitions, identifier, initializer,
              isOptional: isOptional, isNamed: isNamed);
}

/// Parameters in constructors that directly initialize fields. For example:
/// `A(this.field)`.
class InitializingFormalElementX extends ParameterElementX
    implements InitializingFormalElement {
  final FieldElement fieldElement;

  InitializingFormalElementX(ConstructorElement constructorDeclaration,
                             VariableDefinitions variables,
                             Identifier identifier,
                             Expression initializer,
                             this.fieldElement,
                             {bool isOptional: false,
                              bool isNamed: false})
      : super(ElementKind.INITIALIZING_FORMAL, constructorDeclaration,
              variables, identifier, initializer,
              isOptional: isOptional, isNamed: isNamed);

  accept(ElementVisitor visitor, arg) {
    return visitor.visitFieldParameterElement(this, arg);
  }

  MemberElement get memberContext => enclosingElement;

  bool get isLocal => false;
}

class ErroneousInitializingFormalElementX extends ParameterElementX
    implements InitializingFormalElementX {
  final ErroneousFieldElementX fieldElement;

  ErroneousInitializingFormalElementX(
      Identifier identifier,
      Element enclosingElement)
      : this.fieldElement =
            new ErroneousFieldElementX(identifier, enclosingElement),
        super(
            ElementKind.INITIALIZING_FORMAL,
            enclosingElement, null, identifier, null);

  VariableDefinitions get definitions => fieldElement.node;

  MemberElement get memberContext => enclosingElement;

  bool get isLocal => false;

  bool get isMalformed => true;

  DynamicType get type => const DynamicType();
}

class AbstractFieldElementX extends ElementX implements AbstractFieldElement {
  GetterElementX getter;
  SetterElementX setter;

  AbstractFieldElementX(String name, Element enclosing)
      : super(name, ElementKind.ABSTRACT_FIELD, enclosing);

  DartType computeType(Compiler compiler) {
    throw "internal error: AbstractFieldElement has no type";
  }

  Node parseNode(Parsing parsing) {
    throw "internal error: AbstractFieldElement has no node";
  }

  Token get position {
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
        && identical(getter.compilationUnit, compilationUnit)) {
      return getter.position;
    } else {
      return setter.position;
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

  bool get isInstanceMember {
    return isClassMember && !isStatic;
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitAbstractFieldElement(this, arg);
  }

  bool get isAbstract {
    return getter != null && getter.isAbstract
        || setter != null && setter.isAbstract;
  }
}

// TODO(johnniwinther): [FunctionSignature] should be merged with
// [FunctionType].
// TODO(karlklose): all these lists should have element type [FormalElement].
class FunctionSignatureX extends FunctionSignatureCommon
    implements FunctionSignature {
  final List<Element> requiredParameters;
  final List<Element> optionalParameters;
  final int requiredParameterCount;
  final int optionalParameterCount;
  final bool optionalParametersAreNamed;
  final List<Element> orderedOptionalParameters;
  final FunctionType type;
  final bool hasOptionalParameters;

  FunctionSignatureX({this.requiredParameters: const <Element>[],
                      this.requiredParameterCount: 0,
                      List<Element> optionalParameters: const <Element>[],
                      this.optionalParameterCount: 0,
                      this.optionalParametersAreNamed: false,
                      this.orderedOptionalParameters: const <Element>[],
                      this.type})
      : optionalParameters = optionalParameters,
        hasOptionalParameters = !optionalParameters.isEmpty;
}

abstract class BaseFunctionElementX
    extends ElementX with PatchMixin<FunctionElement>, AstElementMixin
    implements FunctionElement {
  DartType typeCache;
  final Modifiers modifiers;

  List<FunctionElement> nestedClosures = new List<FunctionElement>();

  FunctionSignature _functionSignatureCache;

  AsyncMarker asyncMarker = AsyncMarker.SYNC;

  BaseFunctionElementX(String name,
                       ElementKind kind,
                       Modifiers this.modifiers,
                       Element enclosing)
      : super(name, kind, enclosing) {
    assert(modifiers != null);
  }

  bool get isExternal => modifiers.isExternal;

  bool get isInstanceMember {
    return isClassMember
           && !isConstructor
           && !isStatic;
  }

  bool get hasFunctionSignature => _functionSignatureCache != null;

  void _computeSignature(Resolution resolution) {
    if (hasFunctionSignature) return;
    functionSignature = resolution.resolveSignature(this);
  }

  FunctionSignature get functionSignature {
    assert(invariant(this, hasFunctionSignature,
        message: "Function signature has not been computed for $this."));
    return _functionSignatureCache;
  }

  void set functionSignature(FunctionSignature value) {
    // TODO(johnniwinther): Strengthen the invariant to `!hasFunctionSignature`
    // when checked mode checks are not enqueued eagerly.
    assert(invariant(this, !hasFunctionSignature || type == value.type,
        message: "Function signature has already been computed for $this."));
    _functionSignatureCache = value;
    typeCache = _functionSignatureCache.type;
  }

  List<ParameterElement> get parameters {
    // TODO(johnniwinther): Store the list directly, possibly by using List
    // instead of Link in FunctionSignature.
    List<ParameterElement> list = <ParameterElement>[];
    functionSignature.forEachParameter((e) => list.add(e));
    return list;
  }

  FunctionType computeType(Resolution resolution) {
    if (typeCache != null) return typeCache;
    _computeSignature(resolution);
    assert(invariant(this, typeCache != null,
        message: "Type cache expected to be set on $this."));
    return typeCache;
  }

  FunctionType get type {
    assert(invariant(this, typeCache != null,
        message: "Type has not been computed for $this."));
    return typeCache;
  }

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

  bool get isAbstract => false;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitFunctionElement(this, arg);
  }

  // A function is defined by the implementation element.
  AstElement get definingElement => implementation;
}

abstract class FunctionElementX extends BaseFunctionElementX
    with AnalyzableElementX implements MethodElement {

  FunctionElementX(String name,
                   ElementKind kind,
                   Modifiers modifiers,
                   Element enclosing)
      : super(name, kind, modifiers, enclosing);

  MemberElement get memberContext => this;

  @override
  SourceSpan get sourcePosition {
    SourceSpan span = super.sourcePosition;
    if (span != null && hasNode) {
      FunctionExpression functionExpression = node.asFunctionExpression();
      if (functionExpression != null) {
        Token begin = functionExpression.getBeginToken();
        Token end;
        if (functionExpression.parameters != null) {
          end = functionExpression.parameters.getEndToken();
        } else {
          end = functionExpression.name.getEndToken();
        }
        span = new SourceSpan.fromTokens(span.uri, begin, end);
      }
    }
    return span;
  }

  void reuseElement() {
    super.reuseElement();
    nestedClosures.clear();
    _functionSignatureCache = null;
    typeCache = null;
  }
}

abstract class MethodElementX extends FunctionElementX {
  final bool hasBody;

  MethodElementX(String name,
                 ElementKind kind,
                 Modifiers modifiers,
                 Element enclosing,
                 // TODO(15101): Make this a named parameter.
                 this.hasBody)
      : super(name, kind, modifiers, enclosing);

  @override
  bool get isAbstract {
    return !modifiers.isExternal && !hasBody;
  }
}

abstract class AccessorElementX extends MethodElementX
    implements AccessorElement {
  AbstractFieldElement abstractField;

  AccessorElementX(String name,
                   ElementKind kind,
                   Modifiers modifiers,
                   Element enclosing,
                   bool hasBody)
      : super(name, kind, modifiers, enclosing, hasBody);
}

abstract class GetterElementX extends AccessorElementX
    implements GetterElement {

  GetterElementX(String name,
                 Modifiers modifiers,
                 Element enclosing,
                 bool hasBody)
      : super(name, ElementKind.GETTER, modifiers, enclosing, hasBody);
}

abstract class SetterElementX extends AccessorElementX
    implements SetterElement {

  SetterElementX(String name,
                 Modifiers modifiers,
                 Element enclosing,
                 bool hasBody)
      : super(name, ElementKind.SETTER, modifiers, enclosing, hasBody);
}

class LocalFunctionElementX extends BaseFunctionElementX
    implements LocalFunctionElement {
  final FunctionExpression node;

  LocalFunctionElementX(String name,
                        FunctionExpression this.node,
                        ElementKind kind,
                        Modifiers modifiers,
                        ExecutableElement enclosing)
      : super(name, kind, modifiers, enclosing);

  ExecutableElement get executableContext => enclosingElement;

  MemberElement get memberContext => executableContext.memberContext;

  bool get hasNode => true;

  FunctionExpression parseNode(Parsing parsing) => node;

  Token get position {
    // Use the name as position if this is not an unnamed closure.
    if (node.name != null) {
      return node.name.getBeginToken();
    } else {
      return node.getBeginToken();
    }
  }

  bool get isLocal => true;
}

abstract class ConstantConstructorMixin implements ConstructorElement {
  ConstantConstructor _constantConstructor;

  ConstantConstructor get constantConstructor {
    if (isPatch) {
      ConstructorElement originConstructor = origin;
      return originConstructor.constantConstructor;
    }
    if (!isConst || isFromEnvironmentConstructor) return null;
    if (_constantConstructor == null) {
      _constantConstructor = computeConstantConstructor(resolvedAst);
    }
    return _constantConstructor;
  }

  void set constantConstructor(ConstantConstructor value) {
    if (isPatch) {
      ConstantConstructorMixin originConstructor = origin;
      originConstructor.constantConstructor = value;
    } else {
      assert(invariant(this, isConst,
          message: "Constant constructor set on non-constant "
                   "constructor $this."));
      assert(invariant(this, !isFromEnvironmentConstructor,
          message: "Constant constructor set on fromEnvironment "
                   "constructor: $this."));
      assert(invariant(this,
          _constantConstructor == null || _constantConstructor == value,
          message: "Constant constructor already computed for $this:"
                   "Existing: $_constantConstructor, new: $value"));
      _constantConstructor = value;
    }
  }

  bool get isFromEnvironmentConstructor {
    return name == 'fromEnvironment' &&
           library.isDartCore &&
           (enclosingClass.name == 'bool' ||
            enclosingClass.name == 'int' ||
            enclosingClass.name == 'String');
  }
}

abstract class ConstructorElementX extends FunctionElementX
    with ConstantConstructorMixin implements ConstructorElement {
  bool isRedirectingGenerative = false;

  ConstructorElementX(String name,
                      ElementKind kind,
                      Modifiers modifiers,
                      Element enclosing)
        : super(name, kind, modifiers, enclosing);

  FunctionElement immediateRedirectionTarget;
  PrefixElement redirectionDeferredPrefix;

  bool get isRedirectingFactory => immediateRedirectionTarget != null;

  // TODO(johnniwinther): This should also return true for cyclic redirecting
  // generative constructors.
  bool get isCyclicRedirection => effectiveTarget.isRedirectingFactory;

  /// These fields are set by the post process queue when checking for cycles.
  ConstructorElement effectiveTargetInternal;
  DartType _effectiveTargetType;
  bool _isEffectiveTargetMalformed;

  void setEffectiveTarget(ConstructorElement target,
                          DartType type,
                          {bool isMalformed: false}) {
    assert(invariant(this, target != null,
        message: 'No effective target provided for $this.'));
    assert(invariant(this, effectiveTargetInternal == null,
        message: 'Effective target has already been computed for $this.'));
    effectiveTargetInternal = target;
    _effectiveTargetType = type;
    _isEffectiveTargetMalformed = isMalformed;
  }

  ConstructorElement get effectiveTarget {
    if (Elements.isMalformed(immediateRedirectionTarget)) {
      return immediateRedirectionTarget;
    }
    assert(!isRedirectingFactory || effectiveTargetInternal != null);
    if (isRedirectingFactory) {
      return effectiveTargetInternal;
    }
    if (isPatched) {
      return effectiveTargetInternal ?? this;
    }
    return this;
  }

  InterfaceType get effectiveTargetType {
    assert(invariant(this, _effectiveTargetType != null,
        message: 'Effective target type has not yet been computed for $this.'));
    return _effectiveTargetType;
  }

  InterfaceType computeEffectiveTargetType(InterfaceType newType) {
    if (!isRedirectingFactory) return newType;
    return effectiveTargetType.substByContext(newType);
  }

  bool get isEffectiveTargetMalformed {
    if (!isRedirectingFactory) return false;
    assert(invariant(this, _isEffectiveTargetMalformed != null,
            message: 'Malformedness has not yet been computed for $this.'));
    return _isEffectiveTargetMalformed == true;
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitConstructorElement(this, arg);
  }

  ConstructorElement get definingConstructor => null;

  ClassElement get enclosingClass => enclosingElement;
}

class DeferredLoaderGetterElementX extends GetterElementX
    implements GetterElement {
  final PrefixElement prefix;

  DeferredLoaderGetterElementX(PrefixElement prefix)
      : this.prefix = prefix,
        super("loadLibrary",
              Modifiers.EMPTY,
              prefix,
              false) {
    functionSignature = new FunctionSignatureX(type: new FunctionType(this));
  }

  bool get isClassMember => false;

  bool get isSynthesized => true;

  bool get isDeferredLoaderGetter => true;

  bool get isTopLevel => true;
  // By having position null, the enclosing elements location is printed in
  // error messages.
  Token get position => null;

  FunctionExpression parseNode(Parsing parsing) => null;

  bool get hasNode => false;

  FunctionExpression get node => null;

  @override
  SetterElement get setter => null;
}

class ConstructorBodyElementX extends BaseFunctionElementX
    implements ConstructorBodyElement {
  ConstructorElementX constructor;

  ConstructorBodyElementX(ConstructorElementX constructor)
      : this.constructor = constructor,
        super(constructor.name,
              ElementKind.GENERATIVE_CONSTRUCTOR_BODY,
              Modifiers.EMPTY,
              constructor.enclosingElement) {
    functionSignature = constructor.functionSignature;
  }

  bool get hasNode => constructor.hasNode;

  FunctionExpression get node => constructor.node;

  List<MetadataAnnotation> get metadata => constructor.metadata;

  bool get isInstanceMember => true;

  FunctionType computeType(Resolution resolution) {
    DiagnosticReporter reporter = resolution.reporter;
    reporter.internalError(this, '$this.computeType.');
    return null;
  }

  Token get position => constructor.position;

  Element get outermostEnclosingMemberOrTopLevel => constructor;

  Element get analyzableElement => constructor.analyzableElement;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitConstructorBodyElement(this, arg);
  }

  MemberElement get memberContext => constructor;
}

/**
 * A constructor that is not defined in the source code but rather implied by
 * the language semantics.
 *
 * This class is used to represent default constructors and forwarding
 * constructors for mixin applications.
 */
class SynthesizedConstructorElementX extends ConstructorElementX {
  final ConstructorElement definingConstructor;
  final bool isDefaultConstructor;

  SynthesizedConstructorElementX.notForDefault(String name,
                                               this.definingConstructor,
                                               Element enclosing)
      : isDefaultConstructor = false,
        super(name,
              ElementKind.GENERATIVE_CONSTRUCTOR,
              Modifiers.EMPTY,
              enclosing) ;

  SynthesizedConstructorElementX.forDefault(this.definingConstructor,
                                            Element enclosing)
      : isDefaultConstructor = true,
        super('',
              ElementKind.GENERATIVE_CONSTRUCTOR,
              Modifiers.EMPTY,
              enclosing) {
    functionSignature = new FunctionSignatureX(
        type: new FunctionType.synthesized(enclosingClass.thisType));
  }

  FunctionExpression parseNode(Parsing parsing) => null;

  bool get hasNode => false;

  FunctionExpression get node => null;

  Token get position => enclosingElement.position;

  bool get isSynthesized => true;

  DartType get type {
    if (isDefaultConstructor) {
      return super.type;
    } else {
      // TODO(johnniwinther): Ensure that the function type substitutes type
      // variables correctly.
      return definingConstructor.type;
    }
  }

  void _computeSignature(Resolution resolution) {
    if (hasFunctionSignature) return;
    if (definingConstructor.isMalformed) {
      functionSignature = new FunctionSignatureX(
          type: new FunctionType.synthesized(enclosingClass.thisType));
    }
    // TODO(johnniwinther): Ensure that the function signature (and with it the
    // function type) substitutes type variables correctly.
    definingConstructor.computeType(resolution);
    functionSignature = definingConstructor.functionSignature;
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitConstructorElement(this, arg);
  }
}

abstract class TypeDeclarationElementX<T extends GenericType>
    implements TypeDeclarationElement {
  /**
   * The `this type` for this type declaration.
   *
   * The type of [:this:] is the generic type based on this element in which
   * the type arguments are the declared type variables. For instance,
   * [:List<E>:] for [:List:] and [:Map<K,V>:] for [:Map:].
   *
   * For a class declaration this is the type of [:this:].
   *
   * This type is computed in [computeType].
   */
  T thisTypeCache;

  /**
   * The raw type for this type declaration.
   *
   * The raw type is the generic type base on this element in which the type
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
  T rawTypeCache;

  T get thisType {
    assert(invariant(this, thisTypeCache != null,
                     message: 'This type has not been computed for $this'));
    return thisTypeCache;
  }

  T get rawType {
    assert(invariant(this, rawTypeCache != null,
                     message: 'Raw type has not been computed for $this'));
    return rawTypeCache;
  }

  T createType(List<DartType> typeArguments);

  void setThisAndRawTypes(List<DartType> typeParameters) {
    assert(invariant(this, thisTypeCache == null,
        message: "This type has already been set on $this."));
    assert(invariant(this, rawTypeCache == null,
        message: "Raw type has already been set on $this."));
    thisTypeCache = createType(typeParameters);
    if (typeParameters.isEmpty) {
      rawTypeCache = thisTypeCache;
    } else {
      List<DartType> dynamicParameters =
          new List.filled(typeParameters.length, const DynamicType());
      rawTypeCache = createType(dynamicParameters);
    }
  }

  List<DartType> get typeVariables => thisType.typeArguments;

  /**
   * Creates the type variables, their type and corresponding element, for the
   * type variables declared in [parameter] on [element]. The bounds of the type
   * variables are not set until [element] has been resolved.
   */
  List<DartType> createTypeVariables(NodeList parameters) {
    if (parameters == null) return const <DartType>[];

    // Create types and elements for type variable.
    Link<Node> nodes = parameters.nodes;
    List<DartType> arguments =
        new List.generate(nodes.slowLength(), (int index) {
      TypeVariable node = nodes.head;
      String variableName = node.name.source;
      nodes = nodes.tail;
      TypeVariableElementX variableElement =
          new TypeVariableElementX(variableName, this, index, node);
      TypeVariableType variableType = new TypeVariableType(variableElement);
      variableElement.typeCache = variableType;
      return variableType;
    }, growable: false);
    return arguments;
  }

  bool get isResolved => resolutionState == STATE_DONE;

  int get resolutionState;
}

abstract class BaseClassElementX extends ElementX
    with AstElementMixin,
         AnalyzableElementX,
         ClassElementCommon,
         TypeDeclarationElementX<InterfaceType>,
         PatchMixin<ClassElement>,
         ClassMemberMixin
    implements ClassElement {
  final int id;

  DartType supertype;
  Link<DartType> interfaces;
  int supertypeLoadState;
  int resolutionState;
  bool isProxy = false;
  bool hasIncompleteHierarchy = false;

  // backendMembers are members that have been added by the backend to simplify
  // compilation. They don't have any user-side counter-part.
  Link<Element> backendMembers = const Link<Element>();

  OrderedTypeSet allSupertypesAndSelf;

  BaseClassElementX(String name,
                    Element enclosing,
                    this.id,
                    int initialState)
      : supertypeLoadState = initialState,
        resolutionState = initialState,
        super(name, ElementKind.CLASS, enclosing);

  int get hashCode => id;

  bool get hasBackendMembers => !backendMembers.isEmpty;

  bool get isUnnamedMixinApplication => false;

  @override
  bool get isEnumClass => false;

  InterfaceType computeType(Resolution resolution) {
    if (isPatch) {
      origin.computeType(resolution);
      thisTypeCache = origin.thisType;
      rawTypeCache = origin.rawType;
    } else if (thisTypeCache == null) {
      computeThisAndRawType(
          resolution, computeTypeParameters(resolution.parsing));
    }
    return thisTypeCache;
  }

  void computeThisAndRawType(Resolution resolution,
                             List<DartType> typeVariables) {
    if (thisTypeCache == null) {
      if (origin == null) {
        setThisAndRawTypes(typeVariables);
      } else {
        thisTypeCache = origin.computeType(resolution);
        rawTypeCache = origin.rawType;
      }
    }
  }

  @override
  InterfaceType createType(List<DartType> typeArguments) {
    return new InterfaceType(this, typeArguments);
  }

  List<DartType> computeTypeParameters(Parsing parsing);

  bool get isObject {
    assert(invariant(this, isResolved,
        message: "isObject has not been computed for $this."));
    return supertype == null;
  }

  void ensureResolved(Resolution resolution) {
    if (resolutionState == STATE_NOT_STARTED) {
      resolution.resolveClass(this);
      resolution.registerClass(this);
    }
  }

  void setDefaultConstructor(FunctionElement constructor,
                             DiagnosticReporter reporter);

  void addBackendMember(Element member) {
    // TODO(ngeoffray): Deprecate this method.
    assert(member.isGenerativeConstructorBody);
    backendMembers = backendMembers.prepend(member);
  }

  void reverseBackendMembers() {
    backendMembers = backendMembers.reverse();
  }

  /// Lookup a synthetic element created by the backend.
  Element lookupBackendMember(String memberName) {
    for (Element element in backendMembers) {
      if (element.name == memberName) {
        return element;
      }
    }
    return null;
  }

  ConstructorElement lookupDefaultConstructor() {
    ConstructorElement constructor = lookupConstructor("");
    // This method might be called on constructors that have not been
    // resolved. As we query the live world, we return `null` in such cases
    // as no default constructor exists in the live world.
    if (constructor != null &&
        constructor.hasFunctionSignature &&
        constructor.functionSignature.requiredParameterCount == 0) {
      return constructor;
    }
    return null;
  }

  /**
   * Returns the super class, if any.
   *
   * The returned element may not be resolved yet.
   */
  ClassElement get superclass {
    assert(invariant(this, supertypeLoadState == STATE_DONE,
        message: "Superclass has not been computed for $this."));
    return supertype == null ? null : supertype.element;
  }

  void forEachBackendMember(void f(Element member)) {
    backendMembers.forEach(f);
  }

  bool implementsFunction(Compiler compiler) {
    return asInstanceOf(compiler.coreClasses.functionClass) != null ||
        callType != null;
  }

  // TODO(johnniwinther): Remove these when issue 18630 is fixed.
  ClassElement get patch => super.patch;
  ClassElement get origin => super.origin;

  // A class declaration is defined by the declaration element.
  AstElement get definingElement => declaration;
}

abstract class ClassElementX extends BaseClassElementX {
  Link<Element> localMembersReversed = const Link<Element>();
  final ScopeX localScope = new ScopeX();

  Link<Element> localMembersCache;

  Link<Element> get localMembers {
    if (localMembersCache == null) {
      localMembersCache = localMembersReversed.reverse();
    }
    return localMembersCache;
  }

  ClassElementX(String name, Element enclosing, int id, int initialState)
      : super(name, enclosing, id, initialState);

  bool get isMixinApplication => false;
  bool get hasLocalScopeMembers => !localScope.isEmpty;

  void addMember(Element element, DiagnosticReporter reporter) {
    localMembersCache = null;
    localMembersReversed = localMembersReversed.prepend(element);
    addToScope(element, reporter);
  }

  void addToScope(Element element, DiagnosticReporter reporter) {
    if (element.isField && element.name == name) {
      reporter.reportErrorMessage(
          element, MessageKind.MEMBER_USES_CLASS_NAME);
    }
    localScope.add(element, reporter);
  }

  Element localLookup(String elementName) {
    Element result = localScope.lookup(elementName);
    if (result == null && isPatch) {
      result = origin.localLookup(elementName);
    }
    return result;
  }

  void forEachLocalMember(void f(Element member)) {
    localMembers.forEach(f);
  }

  bool get hasConstructor {
    // Search in scope to be sure we search patched constructors.
    for (var element in localScope.values) {
      if (element.isConstructor) return true;
    }
    return false;
  }

  void setDefaultConstructor(FunctionElement constructor,
                             DiagnosticReporter reporter) {
    // The default constructor, although synthetic, is part of a class' API.
    addMember(constructor, reporter);
  }

  List<DartType> computeTypeParameters(Parsing parsing) {
    ClassNode node = parseNode(parsing);
    return createTypeVariables(node.typeParameters);
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

class EnumClassElementX extends ClassElementX implements EnumClassElement {
  final Enum node;
  List<FieldElement> _enumValues;

  EnumClassElementX(String name, Element enclosing, int id, this.node)
      : super(name, enclosing, id, STATE_NOT_STARTED);

  @override
  bool get hasNode => true;

  @override
  Token get position => node.name.token;

  @override
  bool get isEnumClass => true;

  @override
  Node parseNode(Parsing parsing) => node;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitEnumClassElement(this, arg);
  }

  List<DartType> computeTypeParameters(Parsing parsing) => const <DartType>[];

  List<FieldElement> get enumValues {
    assert(invariant(this, _enumValues != null,
        message: "enumValues has not been computed for $this."));
    return _enumValues;
  }

  void set enumValues(List<FieldElement> values) {
    assert(invariant(this, _enumValues == null,
        message: "enumValues has already been computed for $this."));
    _enumValues = values;
  }
}

class EnumConstructorElementX extends ConstructorElementX {
  final FunctionExpression node;

  EnumConstructorElementX(EnumClassElementX enumClass,
                          Modifiers modifiers,
                          this.node)
      : super('', // Name.
              ElementKind.GENERATIVE_CONSTRUCTOR,
              modifiers,
              enumClass);

  @override
  bool get hasNode => true;

  @override
  FunctionExpression parseNode(Parsing parsing) => node;
}

class EnumMethodElementX extends MethodElementX {
  final FunctionExpression node;

  EnumMethodElementX(String name,
                     EnumClassElementX enumClass,
                     Modifiers modifiers,
                     this.node)
      : super(name, ElementKind.FUNCTION, modifiers, enumClass, true);

  @override
  bool get hasNode => true;

  @override
  FunctionExpression parseNode(Parsing parsing) => node;
}

class EnumFormalElementX extends InitializingFormalElementX {
  EnumFormalElementX(ConstructorElement constructor,
                     VariableDefinitions variables,
                     Identifier identifier,
                     EnumFieldElementX fieldElement)
      : super(constructor, variables, identifier, null, fieldElement) {
    typeCache = fieldElement.type;
  }
}

class EnumFieldElementX extends FieldElementX {

  EnumFieldElementX(Identifier name,
                    EnumClassElementX enumClass,
                    VariableList variableList,
                    Node definition,
                    [Expression initializer])
      : super(name, enumClass, variableList) {
    definitionsCache = new VariableDefinitions(null,
        variableList.modifiers, new NodeList.singleton(definition));
    initializerCache = initializer;
  }
}

class MixinApplicationElementX extends BaseClassElementX
    implements MixinApplicationElement {
  final Node node;
  final Modifiers modifiers;

  Link<ConstructorElement> constructors = new Link<ConstructorElement>();

  InterfaceType mixinType;

  MixinApplicationElementX(String name, Element enclosing, int id,
                           this.node, this.modifiers)
      : super(name, enclosing, id, STATE_NOT_STARTED);

  ClassElement get mixin => mixinType != null ? mixinType.element : null;

  bool get isMixinApplication => true;
  bool get isUnnamedMixinApplication => node is! NamedMixinApplication;
  bool get hasConstructor => !constructors.isEmpty;
  bool get hasLocalScopeMembers => !constructors.isEmpty;

  get patch => null;
  get origin => null;

  bool get hasNode => true;

  Token get position => node.getBeginToken();

  Node parseNode(Parsing parsing) => node;

  FunctionElement lookupLocalConstructor(String name) {
    for (Link<Element> link = constructors;
         !link.isEmpty;
         link = link.tail) {
      if (link.head.name == name) return link.head;
    }
    return null;
  }

  Element localLookup(String name) {
    Element constructor = lookupLocalConstructor(name);
    if (constructor != null) return constructor;
    if (mixin == null) return null;
    Element mixedInElement = mixin.localLookup(name);
    if (mixedInElement == null) return null;
    return mixedInElement.isInstanceMember ? mixedInElement : null;
  }

  void forEachLocalMember(void f(Element member)) {
    constructors.forEach(f);
    if (mixin != null) mixin.forEachLocalMember((Element mixedInElement) {
      if (mixedInElement.isInstanceMember) f(mixedInElement);
    });
  }

  void addMember(Element element, DiagnosticReporter reporter) {
    throw new UnsupportedError("Cannot add member to $this.");
  }

  void addToScope(Element element, DiagnosticReporter reporter) {
    reporter.internalError(this, 'Cannot add to scope of $this.');
  }

  void addConstructor(FunctionElement constructor) {
    constructors = constructors.prepend(constructor);
  }

  void setDefaultConstructor(FunctionElement constructor,
                             DiagnosticReporter reporter) {
    assert(!hasConstructor);
    addConstructor(constructor);
  }

  List<DartType> computeTypeParameters(Parsing parsing) {
    NamedMixinApplication named = node.asNamedMixinApplication();
    if (named == null) {
      throw new SpannableAssertionFailure(node,
          "Type variables on unnamed mixin applications must be set on "
          "creation.");
    }
    return createTypeVariables(named.typeParameters);
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitMixinApplicationElement(this, arg);
  }
}

class LabelDefinitionX implements LabelDefinition {
  final Label label;
  final String labelName;
  final JumpTarget target;
  bool isBreakTarget = false;
  bool isContinueTarget = false;

  LabelDefinitionX(Label label, String labelName, this.target)
      : this.label = label,
        this.labelName = labelName;

  // In case of a synthetic label, just use [labelName] for identifying the
  // label.
  String get name => label == null ? labelName : label.identifier.source;

  void setBreakTarget() {
    isBreakTarget = true;
    target.isBreakTarget = true;
  }

  void setContinueTarget() {
    isContinueTarget = true;
    target.isContinueTarget = true;
  }

  bool get isTarget => isBreakTarget || isContinueTarget;

  String toString() => 'Label:${name}';
}

class JumpTargetX implements JumpTarget {
  final ExecutableElement executableContext;
  final Node statement;
  final int nestingLevel;
  Link<LabelDefinition> labels = const Link<LabelDefinition>();
  bool isBreakTarget = false;
  bool isContinueTarget = false;

  JumpTargetX(this.statement, this.nestingLevel, this.executableContext);

  String get name => "target";

  bool get isTarget => isBreakTarget || isContinueTarget;

  LabelDefinition addLabel(Label label, String labelName) {
    LabelDefinition result = new LabelDefinitionX(label, labelName, this);
    labels = labels.prepend(result);
    return result;
  }

  bool get isSwitch => statement is SwitchStatement;

  String toString() => 'Target:$statement';
}

class TypeVariableElementX extends ElementX with AstElementMixin
    implements TypeVariableElement {
  final int index;
  final Node node;
  TypeVariableType typeCache;
  DartType boundCache;

  TypeVariableElementX(String name,
                       TypeDeclarationElement enclosing,
                       this.index,
                       this.node)
    : super(name, ElementKind.TYPE_VARIABLE, enclosing);

  TypeDeclarationElement get typeDeclaration => enclosingElement;

  TypeVariableType computeType(Resolution resolution) => type;

  TypeVariableType get type {
    assert(invariant(this, typeCache != null,
        message: "Type has not been set on $this."));
    return typeCache;
  }

  DartType get bound {
    assert(invariant(this, boundCache != null,
        message: "Bound has not been set on $this."));
    return boundCache;
  }

  bool get hasNode => true;

  Node parseNode(Parsing parsing) => node;

  Token get position => node.getBeginToken();

  accept(ElementVisitor visitor, arg) {
    return visitor.visitTypeVariableElement(this, arg);
  }

  // A type variable cannot be patched therefore defines itself.
  AstElement get definingElement => this;
}

/**
 * A single metadata annotation.
 *
 * For example, consider:
 *
 *     class Data {
 *       const Data();
 *     }
 *
 *     const data = const Data();
 *
 *     @data
 *     class Foo {}
 *
 *     @data @data
 *     class Bar {}
 *
 * In this example, there are three instances of [MetadataAnnotation]
 * and they correspond each to a location in the source code where
 * there is an at-sign, '@'. The [constant] of each of these instances
 * are the same compile-time constant, [: const Data() :].
 *
 * The mirror system does not have a concept matching this class.
 */
abstract class MetadataAnnotationX implements MetadataAnnotation {
  /**
   * The compile-time constant which this annotation resolves to.
   * In the mirror system, this would be an object mirror.
   */
  ConstantExpression constant;
  Element annotatedElement;
  int resolutionState;

  /**
   * The beginning token of this annotation, or [:null:] if it is synthetic.
   */
  Token get beginToken;

  MetadataAnnotationX([this.resolutionState = STATE_NOT_STARTED]);

  MetadataAnnotation ensureResolved(Resolution resolution) {
    if (annotatedElement.isClass || annotatedElement.isTypedef) {
      TypeDeclarationElement typeDeclaration = annotatedElement;
      typeDeclaration.ensureResolved(resolution);
    }
    if (resolutionState == STATE_NOT_STARTED) {
      resolution.resolveMetadataAnnotation(this);
    }
    return this;
  }

  Node parseNode(Parsing parsing);

  String toString() => 'MetadataAnnotation($constant, $resolutionState)';
}

/// Metadata annotation on a parameter.
class ParameterMetadataAnnotation extends MetadataAnnotationX {
  final Metadata metadata;

  ParameterMetadataAnnotation(Metadata this.metadata);

  Node parseNode(Parsing parsing) => metadata.expression;

  Token get beginToken => metadata.getBeginToken();

  Token get endToken => metadata.getEndToken();

  bool get hasNode => true;

  Metadata get node => metadata;
}

/// Mixin for the implementation of patched elements.
///
/// See [:patch_parser.dart:] for a description of the terminology.
abstract class PatchMixin<E extends Element> implements Element {
  // TODO(johnniwinther): Use type variables when issue 18630 is fixed.
  Element/*E*/ patch = null;
  Element/*E*/ origin = null;

  bool get isPatch => origin != null;
  bool get isPatched => patch != null;

  bool get isImplementation => !isPatched;
  bool get isDeclaration => !isPatch;

  Element/*E*/ get implementation => isPatched ? patch : this;
  Element/*E*/ get declaration => isPatch ? origin : this;

  /// Applies a patch to this element. This method must be called at most once.
  void applyPatch(PatchMixin<E> patch) {
    assert(invariant(this, this.patch == null,
                     message: "Element is patched twice."));
    assert(invariant(this, this.origin == null,
                     message: "Origin element is a patch."));
    assert(invariant(patch, patch.origin == null,
                     message: "Element is patched twice."));
    assert(invariant(patch, patch.patch == null,
                     message: "Patch element is patched."));
    this.patch = patch;
    patch.origin = this;
  }
}

/// Abstract implementation of the [AstElement] interface.
abstract class AstElementMixin implements AstElement {
  /// The element whose node defines this element.
  ///
  /// For patched functions the defining element is the patch element found
  /// through [implementation] since its node define the implementation of the
  /// function. For patched classes the defining element is the origin element
  /// found through [declaration] since its node define the inheritance relation
  /// for the class. For unpatched elements the defining element is the element
  /// itself.
  AstElement get definingElement;

  bool get hasResolvedAst => definingElement.hasTreeElements;

  ResolvedAst get resolvedAst {
    return new ResolvedAst(declaration,
        definingElement.node, definingElement.treeElements);
  }

}
