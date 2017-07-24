// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library elements.modelx;

import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common/resolution.dart' show Resolution, ParsingContext;
import '../compiler.dart' show Compiler;
import '../constants/constant_constructors.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../diagnostics/messages.dart' show MessageTemplate;
import '../ordered_typeset.dart' show OrderedTypeSet;
import '../resolution/class_members.dart' show ClassMemberMixin;
import '../resolution/resolution.dart' show AnalyzableElementX;
import '../resolution/scope.dart'
    show ClassScope, LibraryScope, Scope, TypeDeclarationScope;
import '../resolution/tree_elements.dart' show TreeElements;
import '../resolution/typedefs.dart' show TypedefCyclicVisitor;
import '../script.dart';
import 'package:front_end/src/fasta/scanner.dart' show ErrorToken, Token;
import 'package:front_end/src/fasta/scanner.dart' as Tokens show EOF_TOKEN;
import '../tree/tree.dart';
import '../util/util.dart';
import 'common.dart';
import 'elements.dart';
import 'entities.dart';
import 'jumps.dart';
import 'names.dart';
import 'resolution_types.dart';
import 'visitor.dart' show ElementVisitor;

/// Object that identifies a declaration site.
///
/// For most elements, this is the element itself, but for variable declarations
/// where multi-declarations like `var a, b, c` are allowed, the declaration
/// site is a separate object.
// TODO(johnniwinther): Add [beginToken] and [endToken] getters.
abstract class DeclarationSite {}

abstract class ElementX extends Element with ElementCommon {
  static int _elementHashCode = 0;
  static int newHashCode() =>
      _elementHashCode = (_elementHashCode + 1).toUnsigned(30);

  final String name;
  final ElementKind kind;
  final Element enclosingElement;
  final int hashCode = newHashCode();
  List<MetadataAnnotation> metadataInternal;

  ElementX(this.name, this.kind, this.enclosingElement) {
    assert(isError || implementationLibrary != null);
  }

  Modifiers get modifiers => Modifiers.EMPTY;

  Node parseNode(ParsingContext parsing) {
    parsing.reporter.internalError(this, 'parseNode not implemented on $this.');
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
        ? metadataInternal
        : const <MetadataAnnotation>[];
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

  @override
  int get sourceOffset => position?.charOffset;

  Token get position => null;

  SourceSpan get sourcePosition {
    if (position == null) return null;
    Uri uri = compilationUnit.script.resourceUri;
    return new SourceSpan(uri, position.charOffset, position.charEnd);
  }

  Token findMyName(Token token) {
    return findNameToken(token, isConstructor, name, enclosingElement.name);
  }

  static Token findNameToken(
      Token token, bool isConstructor, String name, String enclosingClassName) {
    // We search for the token that has the name of this element.
    // For constructors, that doesn't work because they may have
    // named formed out of multiple tokens (named constructors) so
    // for those we search for the class name instead.
    String needle = isConstructor ? enclosingClassName : name;
    // The unary '-' operator has a special element name (specified).
    if (needle == 'unary-') needle = '-';
    for (Token t = token; Tokens.EOF_TOKEN != t.kind; t = t.next) {
      if (t is! ErrorToken && needle == t.lexeme) return t;
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

  LibraryElement get implementationLibrary {
    Element element = this;
    while (!identical(element.kind, ElementKind.LIBRARY)) {
      element = element.enclosingElement;
    }
    return element;
  }

  ClassElement get enclosingClass {
    for (Element e = this; e != null; e = e.enclosingElement) {
      if (e.isClass) return e.declaration;
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

class ErroneousElementX extends ElementX
    with ConstructorElementCommon
    implements ErroneousElement {
  final MessageKind messageKind;
  final Map messageArguments;

  ErroneousElementX(
      this.messageKind, this.messageArguments, String name, Element enclosing)
      : super(name, ElementKind.ERROR, enclosing);

  bool get isTopLevel => false;

  bool get isSynthesized => true;

  bool get isCyclicRedirection => false;

  bool get isDefaultConstructor => false;

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
  get parameterStructure => unsupported();
  get parameters => unsupported();
  Element get patch => null;
  Element get origin => this;
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

  bool get hasEffectiveTarget => true;

  get effectiveTarget => this;

  computeEffectiveTargetType(ResolutionInterfaceType newType) => unsupported();

  get definingConstructor => null;

  FunctionElement asFunctionElement() => this;

  String get message {
    return MessageTemplate.TEMPLATES[messageKind]
        .message(messageArguments)
        .toString();
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
  List<ResolutionDartType> get typeVariables => unsupported();
}

/// A constructor that was synthesized to recover from a compile-time error.
class ErroneousConstructorElementX extends ErroneousElementX
    with
        PatchMixin<FunctionElement>,
        AnalyzableElementX,
        ConstantConstructorMixin
    implements ConstructorElementX {
  // TODO(ahe): Instead of subclassing [ErroneousElementX], this class should
  // be more like [ErroneousFieldElementX]. In particular, its kind should be
  // [ElementKind.GENERATIVE_CONSTRUCTOR], and it shouldn't throw as much.

  ErroneousConstructorElementX(MessageKind messageKind, Map messageArguments,
      String name, Element enclosing)
      : super(messageKind, messageArguments, name, enclosing);

  @override
  bool get isRedirectingGenerative => false;

  @override
  bool isRedirectingGenerativeInternal;

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
  get _asyncMarker {
    throw new UnsupportedError("_asyncMarker");
  }

  @override
  set _asyncMarker(_) {
    throw new UnsupportedError("_asyncMarker=");
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
  void setEffectiveTarget(ConstructorElement target, ResolutionDartType type,
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
  get _immediateRedirectionTarget {
    throw new UnsupportedError("_immediateRedirectionTarget");
  }

  @override
  set _immediateRedirectionTarget(_) {
    throw new UnsupportedError("_immediateRedirectionTarget=");
  }

  @override
  setImmediateRedirectionTarget(a, b) {
    throw new UnsupportedError("setImmediateRedirectionTarget");
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
  get parameterStructure {
    throw new UnsupportedError("parameterStructure");
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
  get _redirectionDeferredPrefix {
    throw new UnsupportedError("_redirectionDeferredPrefix");
  }

  @override
  set _redirectionDeferredPrefix(_) {
    throw new UnsupportedError("_redirectionDeferredPrefix=");
  }

  // TODO(johnniwinther): Remove this.
  ConstructorElementX get declaration => super.declaration;

  // TODO(johnniwinther): Remove this.
  ConstructorElementX get implementation => super.implementation;

  // TODO(johnniwinther): Remove this.
  ConstructorElementX get origin => super.origin;

  // TODO(johnniwinther): Remove this.
  ConstructorElementX get patch => super.patch;

  ResolutionFunctionType computeType(Resolution resolution) =>
      super.computeType(resolution);
}

/// A message attached to a [WarnOnUseElementX].
class WrappedMessage {
  /// The message position. If [:null:] the position of the reference to the
  /// [WarnOnUseElementX] is used.
  final SourceSpan sourceSpan;

  /**
   * The message to report on resolving a wrapped element.
   */
  final MessageKind messageKind;

  /**
   * The message arguments to report on resolving a wrapped element.
   */
  final Map messageArguments;

  WrappedMessage(this.sourceSpan, this.messageKind, this.messageArguments);
}

class WarnOnUseElementX extends ElementX implements WarnOnUseElement {
  /// Warning to report on resolving this element.
  final WrappedMessage warning;

  /// Info to report on resolving this element.
  final WrappedMessage info;

  /// The element whose usage cause a warning.
  final Element wrappedElement;

  WarnOnUseElementX(
      this.warning, this.info, Element enclosingElement, Element wrappedElement)
      : this.wrappedElement = wrappedElement,
        super(wrappedElement.name, ElementKind.WARN_ON_USE, enclosingElement);

  Element unwrap(DiagnosticReporter reporter, Spannable usageSpannable) {
    dynamic unwrapped = wrappedElement;
    if (warning != null) {
      Spannable spannable = warning.sourceSpan;
      if (spannable == null) spannable = usageSpannable;
      DiagnosticMessage warningMessage = reporter.createMessage(
          spannable, warning.messageKind, warning.messageArguments);
      List<DiagnosticMessage> infos = <DiagnosticMessage>[];
      if (info != null) {
        Spannable spannable = info.sourceSpan;
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

  List<DiagnosticMessage> computeInfos(
      Element context, DiagnosticReporter reporter) {
    return const <DiagnosticMessage>[];
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitAmbiguousElement(this, arg);
  }

  bool get isTopLevel => false;

  ResolutionDynamicType get type => const ResolutionDynamicType();
}

/// Element synthesized to diagnose an ambiguous import.
class AmbiguousImportX extends AmbiguousElementX {
  AmbiguousImportX(MessageKind messageKind, Map messageArguments,
      Element enclosingElement, Element existingElement, Element newElement)
      : super(messageKind, messageArguments, enclosingElement, existingElement,
            newElement);

  List<DiagnosticMessage> computeInfos(
      Element context, DiagnosticReporter reporter) {
    List<DiagnosticMessage> infos = <DiagnosticMessage>[];
    Setlet ambiguousElements = flatten();
    MessageKind code = (ambiguousElements.length == 1)
        ? MessageKind.AMBIGUOUS_REEXPORT
        : MessageKind.AMBIGUOUS_LOCATION;
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
  DuplicatedElementX(MessageKind messageKind, Map messageArguments,
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
                element, MessageKind.DUPLICATE_DEFINITION, {'name': name}),
            <DiagnosticMessage>[
              reporter.createMessage(
                  existing, MessageKind.EXISTING_DEFINITION, {'name': name}),
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
  void addAccessor(AccessorElementX accessor, Element existing,
      DiagnosticReporter reporter) {
    void reportError(Element other) {
      reporter.reportError(
          reporter.createMessage(accessor, MessageKind.DUPLICATE_DEFINITION,
              {'name': accessor.name}),
          <DiagnosticMessage>[
            reporter.createMessage(other, MessageKind.EXISTING_DEFINITION,
                {'name': accessor.name}),
          ]);

      contents[accessor.name] = new DuplicatedElementX(
          MessageKind.DUPLICATE_DEFINITION,
          {'name': accessor.name},
          accessor.memberContext.enclosingElement,
          other,
          accessor);
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
        super(script.name, ElementKind.COMPILATION_UNIT, library) {
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
      LibraryElementX library = implementationLibrary;
      library.addMember(element, reporter);
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
      reporter.reportErrorMessage(tag, MessageKind.BEFORE_TOP_LEVEL);
      return;
    }
    if (partTag != null) {
      reporter.reportWarningMessage(tag, MessageKind.DUPLICATED_PART_OF);
      return;
    }
    partTag = tag;
    LibraryName libraryTag = library.libraryTag;

    Expression libraryReference = tag.name;
    if (libraryReference is LiteralString) {
      // Name is a URI. Resolve and compare to library's URI.
      String content = libraryReference.dartString.slowToString();
      Uri uri = this.script.readableUri.resolve(content);
      Uri expectedUri = library.canonicalUri;
      // Also allow `string.dart` to refer to `dart:core` as `core.dart`.
      if (library.isPlatformLibrary && !uri.isScheme("dart")) {
        expectedUri = library.entryCompilationUnit.script.readableUri;
      }
      if (uri != expectedUri) {
        // Consider finding a relative URI reference for the error message.
        reporter.reportWarningMessage(tag.name,
            MessageKind.LIBRARY_URI_MISMATCH, {'libraryUri': expectedUri});
      }
      return;
    }
    String actualName = tag.name.toString();
    if (libraryTag != null) {
      String expectedName = libraryTag.name.toString();
      if (expectedName != actualName) {
        reporter.reportWarningMessage(tag.name,
            MessageKind.LIBRARY_NAME_MISMATCH, {'libraryName': expectedName});
      }
    } else {
      reporter.reportWarning(
          reporter.createMessage(library, MessageKind.MISSING_LIBRARY_NAME,
              {'libraryName': actualName}),
          <DiagnosticMessage>[
            reporter.createMessage(
                tag.name, MessageKind.THIS_IS_THE_PART_OF_TAG),
          ]);
    }
  }

  bool get hasMembers => !localMembers.isEmpty;

  AnalyzableElement get analyzableElement => library;

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

  /// Returns the list of [ImportElement]s through which [element] was
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
  final Map<String, Element> importScope = new Map<String, Element>();

  /**
   * Adds [element] to the import scope of this library.
   *
   * If an element by the same name is already in the imported scope, an
   * [ErroneousElement] will be put in the imported scope, allowing for
   * detection of ambiguous uses of imported names.
   */
  void addImport(Element enclosingElement, Element element,
      ImportElement import, DiagnosticReporter reporter) {
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

    void registerWarnOnUseElement(ImportElement import, MessageKind messageKind,
        Element hidingElement, Element hiddenElement) {
      Uri hiddenUri = hiddenElement.library.canonicalUri;
      Uri hidingUri = hidingElement.library.canonicalUri;
      Element element = new WarnOnUseElementX(
          new WrappedMessage(
              null, // Report on reference to [hidingElement].
              messageKind,
              {'name': name, 'hiddenUri': hiddenUri, 'hidingUri': hidingUri}),
          new WrappedMessage(reporter.spanFromSpannable(import),
              MessageKind.IMPORTED_HERE, {'name': name}),
          enclosingElement,
          hidingElement);
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
          registerWarnOnUseElement(existingImport,
              MessageKind.HIDDEN_IMPLICIT_IMPORT, existing, element);
        } else {
          registerWarnOnUseElement(
              import, MessageKind.HIDDEN_IMPORT, existing, element);
        }
      } else {
        Element ambiguousElement = new AmbiguousImportX(
            MessageKind.DUPLICATE_IMPORT,
            {'name': name},
            enclosingElement,
            existing,
            element);
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
      ElementKind kind, this.node, this.uri)
      : super('', kind, enclosingElement);

  @override
  List<MetadataAnnotation> get metadata => node.metadata;

  void set metadata(value) {
    // The metadata is stored on [libraryDependency].
    failedAt(this, 'Cannot set metadata on a import/export.');
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
  SyntheticImportElement(CompilationUnitElement enclosingElement, Uri uri,
      LibraryElement libraryDependency)
      : super(enclosingElement, null, uri) {
    this.libraryDependency = libraryDependency;
  }

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

class LibraryElementX extends ElementX
    with LibraryElementCommon, AnalyzableElementX, PatchMixin<LibraryElementX>
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

  final Map<String, MixinApplicationElementX> mixinApplicationCache =
      <String, MixinApplicationElementX>{};

  LibraryElementX(Script script, [Uri canonicalUri, LibraryElementX origin])
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
    failedAt(this, 'Cannot set metadata on Library');
  }

  CompilationUnitElement get compilationUnit => entryCompilationUnit;

  AnalyzableElement get analyzableElement => this;

  void addCompilationUnit(CompilationUnitElement element) {
    compilationUnits = compilationUnits.prepend(element);
  }

  void addTag(LibraryTag tag, DiagnosticReporter reporter) {
    if (tagsCache != null) {
      reporter.internalError(
          tag, "Library tags for $this have already been computed.");
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
  void addImport(
      Element element, ImportElement import, DiagnosticReporter reporter) {
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
    assert(!exportsHandled,
        failedAt(this, 'Exports already set to $slotForExports on $this'));
    assert(exportedElements != null, failedAt(this));
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
    assert(exportsHandled, failedAt(this, 'Exports not handled on $this'));
    for (Link link = slotForExports; !link.isEmpty; link = link.tail) {
      Element element = link.head;
      if (element.name == elementName) return element;
    }
    return null;
  }

  void forEachExport(f(Element element)) {
    assert(exportsHandled, failedAt(this, 'Exports not handled on $this'));
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

  // TODO(johnniwinther): Remove this.
  LibraryElementX get declaration => super.declaration;

  // TODO(johnniwinther): Remove this.
  LibraryElementX get implementation => super.implementation;

  // TODO(johnniwinther): Remove this.
  LibraryElementX get origin => super.origin;

  // TODO(johnniwinther): Remove this.
  LibraryElementX get patch => super.patch;
}

class PrefixElementX extends ElementX implements PrefixElement {
  Token firstPosition;

  final ImportScope importScope = new ImportScope();

  bool get isDeferred => deferredImport != null;

  // Only needed for deferred imports.
  final ImportElement deferredImport;

  PrefixElementX(
      String prefix, Element enclosing, this.firstPosition, this.deferredImport)
      : super(prefix, ElementKind.PREFIX, enclosing);

  bool get isTopLevel => false;

  Element lookupLocalMember(String memberName) => importScope[memberName];

  void forEachLocalMember(f(Element member)) => importScope.forEach(f);

  ResolutionDartType computeType(Resolution resolution) =>
      const ResolutionDynamicType();

  Token get position => firstPosition;

  void addImport(
      Element element, ImportElement import, DiagnosticReporter reporter) {
    importScope.addImport(this, element, import, reporter);
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitPrefixElement(this, arg);
  }

  @override
  GetterElement get loadLibrary {
    return isDeferred ? lookupLocalMember(Identifiers.loadLibrary) : null;
  }

  String toString() => '$kind($name)';
}

class TypedefElementX extends ElementX
    with AstElementMixin, AnalyzableElementX, TypeDeclarationElementX
    implements TypedefElement {
  Typedef cachedNode;

  /**
   * The type annotation which defines this typedef.
   */
  ResolutionDartType aliasCache;

  ResolutionDartType get alias {
    assert(hasBeenCheckedForCycles,
        failedAt(this, "$this has not been checked for cycles."));
    return aliasCache;
  }

  /// [:true:] if the typedef has been checked for cyclic reference.
  bool hasBeenCheckedForCycles = false;

  int resolutionState = STATE_NOT_STARTED;

  TypedefElementX(String name, Element enclosing)
      : super(name, ElementKind.TYPEDEF, enclosing);

  bool get hasNode => cachedNode != null;

  Typedef get node {
    assert(cachedNode != null,
        failedAt(this, "Node has not been computed for $this."));
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

  ResolutionTypedefType computeType(Resolution resolution) {
    if (thisTypeCache != null) return thisTypeCache;
    Typedef node = parseNode(resolution.parsingContext);
    setThisAndRawTypes(createTypeVariables(node.templateParameters));
    ensureResolved(resolution);
    return thisTypeCache;
  }

  void ensureResolved(Resolution resolution) {
    if (resolutionState == STATE_NOT_STARTED) {
      resolution.resolveTypedef(this);
    }
  }

  ResolutionTypedefType createType(List<ResolutionDartType> typeArguments) {
    return new ResolutionTypedefType(this, typeArguments);
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

  ResolutionTypedefType get thisType => super.thisType;

  ResolutionTypedefType get rawType => super.rawType;
}

// This class holds common information for a list of variable or field
// declarations. It contains the node, and the type. A [VariableElementX]
// forwards its [computeType] and [parseNode] methods to this class.
class VariableList implements DeclarationSite {
  VariableDefinitions definitions;
  ResolutionDartType type;
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
        ? metadataInternal
        : const <MetadataAnnotation>[];
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

  VariableDefinitions parseNode(Element element, ParsingContext parsing) {
    return definitions;
  }

  ResolutionDartType computeType(Element element, Resolution resolution) =>
      type;
}

abstract class ConstantVariableMixin implements VariableElement {
  ConstantExpression constantCache;

  // TODO(johnniwinther): Update the on `constant = ...` when evaluation of
  // constant expression can handle references to unanalyzed constant variables.
  @override
  bool get hasConstant => false;

  ConstantExpression get constant {
    if (isPatch) {
      ConstantVariableMixin originVariable = origin;
      return originVariable.constant;
    }
    assert(!isConst || constantCache != null,
        failedAt(this, "Constant has not been computed for $this."));
    return constantCache;
  }

  void set constant(ConstantExpression value) {
    if (isPatch) {
      ConstantVariableMixin originVariable = origin;
      originVariable.constant = value;
      return;
    }
    if (constantCache != null &&
        constantCache.kind == ConstantExpressionKind.ERRONEOUS) {
      // TODO(johnniwinther): Find out why we sometimes compute a non-erroneous
      // constant for a variable already known to be erroneous.
      return;
    }
    if (constantCache != null && constantCache != value) {
      // Allow setting the constant as erroneous. Constants computed during
      // resolution are locally valid but might be effectively erroneous. For
      // instance `a ? true : false` where a is `const a = m()`. Since `a` is
      // declared to be constant, the conditional is assumed valid, but when
      // computing the value we see that it isn't.
      // TODO(johnniwinther): Remove this exception when all constant
      // expressions are computed during resolution.
      assert(
          value == null || value.kind == ConstantExpressionKind.ERRONEOUS,
          failedAt(
              this,
              "Constant has already been computed for $this. "
              "Existing constant: "
              "${constantCache != null ? constantCache.toStructuredText() : ''}"
              ", New constant: "
              "${value != null ? value.toStructuredText() : ''}."));
    }
    constantCache = value;
  }
}

abstract class VariableElementX extends ElementX
    with AstElementMixin, ConstantVariableMixin
    implements VariableElement {
  final Token token;
  final VariableList variables;
  VariableDefinitions definitionsCache;
  Expression definitionCache;
  Expression initializerCache;

  Modifiers get modifiers => variables.modifiers;

  VariableElementX(String name, ElementKind kind, Element enclosingElement,
      VariableList variables, this.token)
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
    assert(definitionsCache != null,
        failedAt(this, "Node has not been computed for $this."));
    return definitionsCache;
  }

  /// Returns the node that defines this field.
  ///
  /// For instance in `var a, b = true`, the definitions nodes for fields 'a'
  /// and 'b' are the nodes for `a` and `b = true`, respectively.
  Expression get definition {
    assert(definitionCache != null,
        failedAt(this, "Definition node has not been computed for $this."));
    return definitionCache;
  }

  Expression get initializer {
    assert(definitionsCache != null,
        failedAt(this, "Initializer has not been computed for $this."));
    return initializerCache;
  }

  Node parseNode(ParsingContext parsing) {
    if (definitionsCache != null) return definitionsCache;

    VariableDefinitions definitions = variables.parseNode(this, parsing);
    createDefinitions(definitions);
    return definitionsCache;
  }

  void createDefinitions(VariableDefinitions definitions) {
    assert(
        definitionsCache == null,
        failedAt(
            this, "VariableDefinitions has already been computed for $this."));
    for (Link<Node> link = definitions.definitions.nodes;
        !link.isEmpty;
        link = link.tail) {
      Expression initializedIdentifier = link.head;
      Identifier identifier = initializedIdentifier.asIdentifier();
      if (identifier == null) {
        SendSet sendSet = initializedIdentifier.asSendSet();
        identifier = sendSet.selector.asIdentifier();
        if (identical(name, identifier.source)) {
          definitionCache = initializedIdentifier;
          initializerCache = sendSet.arguments.first;
        }
      } else if (identical(name, identifier.source)) {
        definitionCache = initializedIdentifier;
      }
    }
    if (definitionCache == null) {
      failedAt(definitionCache, "Could not find '$name'.");
    }
    definitionsCache = definitions;
  }

  ResolutionDartType computeType(Resolution resolution) {
    if (variables.type != null) return variables.type;
    // Call [parseNode] to ensure that [definitionsCache] and [initializerCache]
    // are set as a consequence of calling [computeType].
    parseNode(resolution.parsingContext);
    return variables.computeType(this, resolution);
  }

  ResolutionDartType get type {
    assert(variables.type != null,
        failedAt(this, "Type has not been computed for $this."));
    return variables.type;
  }

  bool get isInstanceMember => isClassMember && !isStatic;

  // Note: cachedNode.beginToken will not be correct in all
  // cases, for example, for function typed parameters.
  Token get position => token;

  DeclarationSite get declarationSite => variables;
}

class LocalVariableElementX extends VariableElementX
    implements LocalVariableElement {
  LocalVariableElementX(String name, ExecutableElement enclosingElement,
      VariableList variables, Token token)
      : super(name, ElementKind.VARIABLE, enclosingElement, variables, token) {
    createDefinitions(variables.definitions);
  }

  ExecutableElement get executableContext => enclosingElement;

  MemberElement get memberContext => executableContext.memberContext;

  bool get isLocal => true;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitLocalVariableElement(this, arg);
  }
}

class FieldElementX extends VariableElementX
    with AnalyzableElementX
    implements FieldElement {
  List<FunctionElement> nestedClosures = new List<FunctionElement>();

  FieldElementX(
      Identifier name, Element enclosingElement, VariableList variables)
      : super(name.source, ElementKind.FIELD, enclosingElement, variables,
            name.token);

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
    with ConstantVariableMixin
    implements FieldElementX {
  final VariableList variables;

  ErroneousFieldElementX(Identifier name, Element enclosingElement)
      : variables = new VariableList(Modifiers.EMPTY)
          ..definitions = new VariableDefinitions(
              null, Modifiers.EMPTY, new NodeList.singleton(name))
          ..type = const ResolutionDynamicType(),
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

  ResolutionDynamicType get type => const ResolutionDynamicType();

  Token get token => node.getBeginToken();

  get definitionCache {
    throw new UnsupportedError("definitionCache");
  }

  set definitionCache(_) {
    throw new UnsupportedError("definitionCache=");
  }

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

  get definition => null;

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

  ResolutionDartType computeType(Resolution resolution) => type;
}

/// [Element] for a parameter-like element.
class FormalElementX extends ElementX
    with AstElementMixin
    implements FormalElement {
  final VariableDefinitions definitions;
  final Identifier identifier;
  ResolutionDartType typeCache;

  @override
  List<ResolutionDartType> get typeVariables => functionSignature.typeVariables;

  /**
   * Function signature for a variable with a function type. The signature is
   * kept to provide full information about parameter names through the mirror
   * system.
   */
  FunctionSignature _functionSignatureCache;

  FormalElementX(ElementKind elementKind, FunctionTypedElement enclosingElement,
      this.definitions, Identifier identifier)
      : this.identifier = identifier,
        super(identifier.source, elementKind, enclosingElement);

  FormalElementX.unnamed(ElementKind elementKind,
      FunctionTypedElement enclosingElement, this.definitions)
      : this.identifier = null,
        super("<unnamed>", elementKind, enclosingElement);

  /// Whether this is an unnamed parameter in a Function type.
  bool get isUnnamed => identifier == null;

  FunctionTypedElement get functionDeclaration => enclosingElement;

  Modifiers get modifiers => definitions.modifiers;

  Token get position => identifier.getBeginToken();

  Node parseNode(ParsingContext parsing) => definitions;

  ResolutionDartType computeType(Resolution resolution) {
    assert(type != null,
        failedAt(this, "Parameter type has not been set for $this."));
    return type;
  }

  ResolutionDartType get type {
    assert(typeCache != null,
        failedAt(this, "Parameter type has not been set for $this."));
    return typeCache;
  }

  FunctionSignature get functionSignature {
    assert(_functionSignatureCache != null,
        failedAt(this, "Parameter signature has not been computed for $this."));
    return _functionSignatureCache;
  }

  void set functionSignature(FunctionSignature value) {
    assert(
        _functionSignatureCache == null,
        failedAt(
            this, "Parameter signature has already been computed for $this."));
    _functionSignatureCache = value;
    typeCache = _functionSignatureCache.type;
  }

  bool get hasNode => true;

  VariableDefinitions get node => definitions;

  ResolutionFunctionType get functionType => type;

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
    with PatchMixin<ParameterElement>, ConstantVariableMixin
    implements ParameterElement {
  final Expression initializer;
  final bool isOptional;
  final bool isNamed;

  ParameterElementX(
      ElementKind elementKind,
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
  LocalParameterElementX(
      FunctionElement functionDeclaration,
      VariableDefinitions definitions,
      Identifier identifier,
      Expression initializer,
      {bool isOptional: false,
      bool isNamed: false})
      : super(ElementKind.PARAMETER, functionDeclaration, definitions,
            identifier, initializer,
            isOptional: isOptional, isNamed: isNamed);
}

/// Parameters in constructors that directly initialize fields. For example:
/// `A(this.field)`.
class InitializingFormalElementX extends ParameterElementX
    implements InitializingFormalElement {
  final FieldElement fieldElement;

  InitializingFormalElementX(
      ConstructorElement constructorDeclaration,
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

  @override
  bool get isFinal => true;

  @override
  bool get isLocal => true;

  ConstructorElement get functionDeclaration => super.functionDeclaration;
}

class ErroneousInitializingFormalElementX extends ParameterElementX
    implements InitializingFormalElementX {
  final ErroneousFieldElementX fieldElement;

  ErroneousInitializingFormalElementX(
      Identifier identifier, Element enclosingElement)
      : this.fieldElement =
            new ErroneousFieldElementX(identifier, enclosingElement),
        super(ElementKind.INITIALIZING_FORMAL, enclosingElement, null,
            identifier, null);

  VariableDefinitions get definitions => fieldElement.node;

  MemberElement get memberContext => enclosingElement;

  bool get isLocal => false;

  bool get isMalformed => true;

  ResolutionDynamicType get type => const ResolutionDynamicType();

  ConstructorElement get functionDeclaration => super.functionDeclaration;
}

class AbstractFieldElementX extends ElementX
    with AbstractFieldElementCommon
    implements AbstractFieldElement {
  GetterElementX getter;
  SetterElementX setter;

  AbstractFieldElementX(String name, Element enclosing)
      : super(name, ElementKind.ABSTRACT_FIELD, enclosing);

  ResolutionDartType computeType(Compiler compiler) {
    throw "internal error: AbstractFieldElement has no type";
  }

  Node parseNode(ParsingContext parsing) {
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
    if (getter != null && identical(getter.compilationUnit, compilationUnit)) {
      return getter.position;
    } else {
      return setter.position;
    }
  }

  Modifiers get modifiers {
    // The resolver ensures that the flags match (ignoring abstract).
    if (getter != null) {
      return new Modifiers.withFlags(getter.modifiers.nodes,
          getter.modifiers.flags | Modifiers.FLAG_ABSTRACT);
    } else {
      return new Modifiers.withFlags(setter.modifiers.nodes,
          setter.modifiers.flags | Modifiers.FLAG_ABSTRACT);
    }
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitAbstractFieldElement(this, arg);
  }
}

// TODO(johnniwinther): [FunctionSignature] should be merged with
// [FunctionType].
class FunctionSignatureX extends FunctionSignatureCommon
    implements FunctionSignature {
  final List<ResolutionDartType> typeVariables;
  final List<FormalElement> requiredParameters;
  final List<FormalElement> optionalParameters;
  final int requiredParameterCount;
  final int optionalParameterCount;
  final bool optionalParametersAreNamed;
  final List<FormalElement> orderedOptionalParameters;
  final ResolutionFunctionType type;
  final bool hasOptionalParameters;

  FunctionSignatureX(
      {this.typeVariables: const <ResolutionDartType>[],
      this.requiredParameters: const <FormalElement>[],
      this.requiredParameterCount: 0,
      List<Element> optionalParameters: const <FormalElement>[],
      this.optionalParameterCount: 0,
      this.optionalParametersAreNamed: false,
      this.orderedOptionalParameters: const <FormalElement>[],
      this.type})
      : optionalParameters = optionalParameters,
        hasOptionalParameters = !optionalParameters.isEmpty;
}

abstract class BaseFunctionElementX extends ElementX
    with PatchMixin<FunctionElement>, AstElementMixin
    implements FunctionElement {
  ResolutionDartType typeCache;
  final Modifiers modifiers;

  List<FunctionElement> nestedClosures = new List<FunctionElement>();

  FunctionSignature _functionSignatureCache;

  AsyncMarker _asyncMarker = AsyncMarker.SYNC;

  BaseFunctionElementX(String name, ElementKind kind, Modifiers this.modifiers,
      Element enclosing)
      : super(name, kind, enclosing) {
    assert(modifiers != null);
  }

  AsyncMarker get asyncMarker {
    if (isPatched) {
      return patch.asyncMarker;
    }
    return _asyncMarker;
  }

  void set asyncMarker(AsyncMarker value) {
    if (isPatched) {
      BaseFunctionElementX function = patch;
      function.asyncMarker = value;
    } else {
      _asyncMarker = value;
    }
  }

  bool get isExternal => modifiers.isExternal;

  bool get isInstanceMember {
    return isClassMember && !isConstructor && !isStatic;
  }

  ParameterStructure get parameterStructure =>
      functionSignature.parameterStructure;

  bool get hasFunctionSignature => _functionSignatureCache != null;

  void _computeSignature(Resolution resolution) {
    if (hasFunctionSignature) return;
    functionSignature = resolution.resolveSignature(this);
  }

  FunctionSignature get functionSignature {
    assert(hasFunctionSignature,
        failedAt(this, "Function signature has not been computed for $this."));
    return _functionSignatureCache;
  }

  void set functionSignature(FunctionSignature value) {
    // TODO(johnniwinther): Strengthen the invariant to `!hasFunctionSignature`
    // when checked mode checks are not enqueued eagerly.
    assert(
        !hasFunctionSignature || type == value.type,
        failedAt(
            this, "Function signature has already been computed for $this."));
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

  ResolutionFunctionType computeType(Resolution resolution) {
    if (typeCache != null) return typeCache;
    _computeSignature(resolution);
    assert(typeCache != null,
        failedAt(this, "Type cache expected to be set on $this."));
    return typeCache;
  }

  ResolutionFunctionType get type {
    assert(typeCache != null,
        failedAt(this, "Type has not been computed for $this."));
    return typeCache;
  }

  FunctionElement asFunctionElement() => this;

  @override
  Scope buildScope() => new TypeDeclarationScope(super.buildScope(), this);

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

  // A function is defined by the implementation element.
  AstElement get definingElement => implementation;

  @override
  List<ResolutionDartType> get typeVariables => functionSignature.typeVariables;

  // TODO(johnniwinther): Remove this.
  FunctionElement get declaration => super.declaration;

  // TODO(johnniwinther): Remove this.
  FunctionElement get implementation => super.implementation;

  // TODO(johnniwinther): Remove this.
  FunctionElement get origin => super.origin;

  // TODO(johnniwinther): Remove this.
  FunctionElement get patch => super.patch;
}

abstract class FunctionElementX extends BaseFunctionElementX
    with AnalyzableElementX
    implements MethodElement {
  FunctionElementX(
      String name, ElementKind kind, Modifiers modifiers, Element enclosing)
      : super(name, kind, modifiers, enclosing);

  MemberElement get memberContext => this;

  @override
  SourceSpan get sourcePosition {
    SourceSpan span = super.sourcePosition;
    if (span != null && hasNode) {
      FunctionExpression functionExpression = node.asFunctionExpression();
      if (functionExpression != null) {
        span = new SourceSpan.fromNode(span.uri, functionExpression);
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

  MethodElementX(
      String name,
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

  accept(ElementVisitor visitor, arg) {
    return visitor.visitMethodElement(this, arg);
  }
}

abstract class AccessorElementX extends MethodElementX
    implements AccessorElement {
  AbstractFieldElement abstractField;

  AccessorElementX(String name, ElementKind kind, Modifiers modifiers,
      Element enclosing, bool hasBody)
      : super(name, kind, modifiers, enclosing, hasBody);
}

abstract class GetterElementX extends AccessorElementX
    implements GetterElement {
  GetterElementX(
      String name, Modifiers modifiers, Element enclosing, bool hasBody)
      : super(name, ElementKind.GETTER, modifiers, enclosing, hasBody);

  accept(ElementVisitor visitor, arg) {
    return visitor.visitGetterElement(this, arg);
  }
}

abstract class SetterElementX extends AccessorElementX
    implements SetterElement {
  SetterElementX(
      String name, Modifiers modifiers, Element enclosing, bool hasBody)
      : super(name, ElementKind.SETTER, modifiers, enclosing, hasBody);

  accept(ElementVisitor visitor, arg) {
    return visitor.visitSetterElement(this, arg);
  }
}

class LocalFunctionElementX extends BaseFunctionElementX
    implements LocalFunctionElement {
  final FunctionExpression node;

  MethodElement callMethod;

  LocalFunctionElementX(String name, FunctionExpression this.node,
      ElementKind kind, Modifiers modifiers, ExecutableElement enclosing)
      : super(name, kind, modifiers, enclosing);

  ExecutableElement get executableContext => enclosingElement;

  MemberElement get memberContext => executableContext.memberContext;

  bool get hasNode => true;

  FunctionExpression parseNode(ParsingContext parsing) => node;

  Token get position {
    // Use the name as position if this is not an unnamed closure.
    if (node.name != null) {
      return node.name.getBeginToken();
    } else {
      return node.getBeginToken();
    }
  }

  bool get isLocal => true;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitLocalFunctionElement(this, arg);
  }
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
      assert(
          isConst,
          failedAt(
              this,
              "Constant constructor set on non-constant "
              "constructor $this."));
      assert(
          !isFromEnvironmentConstructor,
          failedAt(
              this,
              "Constant constructor set on fromEnvironment "
              "constructor: $this."));
      assert(
          _constantConstructor == null || _constantConstructor == value,
          failedAt(
              this,
              "Constant constructor already computed for $this:"
              "Existing: $_constantConstructor, new: $value"));
      _constantConstructor = value;
    }
  }

  /// Returns the empty list of type variables by default.
  @override
  List<ResolutionDartType> get typeVariables => functionSignature.typeVariables;
}

abstract class ConstructorElementX extends FunctionElementX
    with ConstantConstructorMixin, ConstructorElementCommon
    implements ConstructorElement {
  bool isRedirectingGenerativeInternal = false;

  ConstructorElementX(
      String name, ElementKind kind, Modifiers modifiers, Element enclosing)
      : super(name, kind, modifiers, enclosing);

  ConstructorElement _immediateRedirectionTarget;
  PrefixElement _redirectionDeferredPrefix;

  bool get isRedirectingGenerative {
    if (isPatched) return patch.isRedirectingGenerative;
    return isRedirectingGenerativeInternal;
  }

  bool get isRedirectingFactory => immediateRedirectionTarget != null;

  // TODO(johnniwinther): This should also return true for cyclic redirecting
  // generative constructors.
  bool get isCyclicRedirection => effectiveTarget.isRedirectingFactory;

  bool get isDefaultConstructor => false;

  /// These fields are set by the post process queue when checking for cycles.
  ConstructorElement effectiveTargetInternal;
  ResolutionDartType _effectiveTargetType;
  bool _isEffectiveTargetMalformed;

  bool get hasEffectiveTarget {
    if (isPatched) {
      return patch.hasEffectiveTarget;
    }
    return effectiveTargetInternal != null;
  }

  void setImmediateRedirectionTarget(
      ConstructorElement target, PrefixElement prefix) {
    if (isPatched) {
      patch.setImmediateRedirectionTarget(target, prefix);
    } else {
      assert(
          _immediateRedirectionTarget == null,
          failedAt(this,
              "Immediate redirection target has already been set on $this."));
      _immediateRedirectionTarget = target;
      _redirectionDeferredPrefix = prefix;
    }
  }

  ConstructorElement get immediateRedirectionTarget {
    if (isPatched) {
      return patch.immediateRedirectionTarget;
    }
    return _immediateRedirectionTarget;
  }

  PrefixElement get redirectionDeferredPrefix {
    if (isPatched) {
      return patch.redirectionDeferredPrefix;
    }
    return _redirectionDeferredPrefix;
  }

  void setEffectiveTarget(ConstructorElement target, ResolutionDartType type,
      {bool isMalformed: false}) {
    if (isPatched) {
      patch.setEffectiveTarget(target, type, isMalformed: isMalformed);
    } else {
      assert(target != null,
          failedAt(this, 'No effective target provided for $this.'));
      assert(
          effectiveTargetInternal == null,
          failedAt(
              this, 'Effective target has already been computed for $this.'));
      assert(
          !target.isMalformed || isMalformed,
          failedAt(
              this,
              'Effective target is not marked as malformed for $this: '
              'target=$target, type=$type, isMalformed: $isMalformed'));
      assert(
          isMalformed || type.isInterfaceType,
          failedAt(
              this,
              'Effective target type is not an interface type for $this: '
              'target=$target, type=$type, isMalformed: $isMalformed'));
      effectiveTargetInternal = target;
      _effectiveTargetType = type;
      _isEffectiveTargetMalformed = isMalformed;
    }
  }

  ConstructorElement get effectiveTarget {
    if (isPatched) {
      return patch.effectiveTarget;
    }
    if (isRedirectingFactory) {
      assert(effectiveTargetInternal != null);
      return effectiveTargetInternal;
    }
    return this;
  }

  ResolutionDartType get effectiveTargetType {
    if (isPatched) {
      return patch.effectiveTargetType;
    }
    assert(
        _effectiveTargetType != null,
        failedAt(this,
            'Effective target type has not yet been computed for $this.'));
    return _effectiveTargetType;
  }

  ResolutionDartType computeEffectiveTargetType(
      ResolutionInterfaceType newType) {
    if (isPatched) {
      return patch.computeEffectiveTargetType(newType);
    }
    if (!isRedirectingFactory) return newType;
    return effectiveTargetType.substByContext(newType);
  }

  bool get isEffectiveTargetMalformed {
    if (isPatched) {
      return patch.isEffectiveTargetMalformed;
    }
    if (!isRedirectingFactory) return false;
    assert(_isEffectiveTargetMalformed != null,
        failedAt(this, 'Malformedness has not yet been computed for $this.'));
    return _isEffectiveTargetMalformed == true;
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitConstructorElement(this, arg);
  }

  ConstructorElement get definingConstructor => null;

  ClassElement get enclosingClass => enclosingElement.declaration;

  // TODO(johnniwinther): Remove this.
  ConstructorElementX get declaration => super.declaration;

  // TODO(johnniwinther): Remove this.
  ConstructorElementX get implementation => super.implementation;

  // TODO(johnniwinther): Remove this.
  ConstructorElementX get origin => super.origin;

  // TODO(johnniwinther): Remove this.
  ConstructorElementX get patch => super.patch;
}

class DeferredLoaderGetterElementX extends GetterElementX {
  final PrefixElement prefix;

  DeferredLoaderGetterElementX(PrefixElement prefix)
      : this.prefix = prefix,
        super(Identifiers.loadLibrary, Modifiers.EMPTY, prefix, false) {
    functionSignature =
        new FunctionSignatureX(type: new ResolutionFunctionType(this));
  }

  bool get isClassMember => false;

  bool get isSynthesized => true;

  bool get isDeferredLoaderGetter => true;

  bool get isTopLevel => true;

  // By having position null, the enclosing elements location is printed in
  // error messages.
  Token get position => null;

  FunctionExpression parseNode(ParsingContext parsing) => null;

  bool get hasNode => false;

  FunctionExpression get node => null;

  bool get hasResolvedAst => true;

  ResolvedAst get resolvedAst {
    return new SynthesizedResolvedAst(
        this, ResolvedAstKind.DEFERRED_LOAD_LIBRARY);
  }

  @override
  SetterElement get setter => null;
}

class ConstructorBodyElementX extends BaseFunctionElementX
    implements ConstructorBodyElement {
  final ResolvedAst _resolvedAst;
  final ConstructorElement constructor;

  ConstructorBodyElementX(
      ResolvedAst resolvedAst, ConstructorElement constructor)
      : this._resolvedAst = resolvedAst,
        this.constructor = constructor,
        super(constructor.name, ElementKind.GENERATIVE_CONSTRUCTOR_BODY,
            Modifiers.EMPTY, constructor.enclosingElement) {
    functionSignature = constructor.functionSignature;
  }

  /// Returns the constructor body associated with the given constructor or
  /// creates a new constructor body, if none can be found.
  ///
  /// Returns `null` if the constructor does not have a body.
  static ConstructorBodyElementX createFromResolvedAst(
      ResolvedAst constructorResolvedAst) {
    ConstructorElement constructor =
        constructorResolvedAst.element.implementation;
    assert(constructor.isGenerativeConstructor);
    if (constructorResolvedAst.kind != ResolvedAstKind.PARSED) return null;

    FunctionExpression node = constructorResolvedAst.node;
    // If we know the body doesn't have any code, we don't generate it.
    if (!node.hasBody) return null;
    if (node.hasEmptyBody) return null;
    ClassElement classElement = constructor.enclosingClass;
    ConstructorBodyElement bodyElement;
    classElement.forEachConstructorBody((ConstructorBodyElement body) {
      if (body.constructor == constructor) {
        // TODO(kasperl): Find a way of stopping the iteration
        // through the backend members.
        bodyElement = body;
      }
    });
    if (bodyElement == null) {
      bodyElement =
          new ConstructorBodyElementX(constructorResolvedAst, constructor);
      classElement.addConstructorBody(bodyElement);

      if (constructor.isPatch) {
        // Create origin body element for patched constructors.
        ConstructorBodyElementX patch = bodyElement;
        ConstructorBodyElementX origin = new ConstructorBodyElementX(
            constructorResolvedAst, constructor.origin);
        origin.applyPatch(patch);
        classElement.origin.addConstructorBody(bodyElement.origin);
      }
    }
    assert(bodyElement.isGenerativeConstructorBody);
    return bodyElement;
  }

  bool get hasNode => _resolvedAst.kind == ResolvedAstKind.PARSED;

  FunctionExpression get node => _resolvedAst.node;

  bool get hasResolvedAst => true;

  ResolvedAst get resolvedAst {
    if (_resolvedAst.kind == ResolvedAstKind.PARSED) {
      return new ParsedResolvedAst(declaration, _resolvedAst.node,
          _resolvedAst.body, _resolvedAst.elements, _resolvedAst.sourceUri);
    } else {
      return new SynthesizedResolvedAst(declaration, _resolvedAst.kind);
    }
  }

  List<MetadataAnnotation> get metadata => constructor.metadata;

  bool get isInstanceMember => true;

  ResolutionFunctionType computeType(Resolution resolution) {
    DiagnosticReporter reporter = resolution.reporter;
    reporter.internalError(this, '$this.computeType.');
    return null;
  }

  int get sourceOffset => constructor.sourceOffset;

  Token get position => constructor.position;

  Element get outermostEnclosingMemberOrTopLevel => constructor;

  AnalyzableElement get analyzableElement => constructor.analyzableElement;

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
  ResolvedAst _resolvedAst;

  SynthesizedConstructorElementX.notForDefault(
      String name, this.definingConstructor, Element enclosing)
      : super(name, ElementKind.GENERATIVE_CONSTRUCTOR, Modifiers.EMPTY,
            enclosing) {
    _resolvedAst = new SynthesizedResolvedAst(
        this, ResolvedAstKind.FORWARDING_CONSTRUCTOR);
  }

  SynthesizedConstructorElementX.forDefault(
      this.definingConstructor, Element enclosing)
      : super('', ElementKind.GENERATIVE_CONSTRUCTOR, Modifiers.EMPTY,
            enclosing) {
    functionSignature = new FunctionSignatureX(
        type: new ResolutionFunctionType.synthesized(
            const ResolutionDynamicType()));
    _resolvedAst =
        new SynthesizedResolvedAst(this, ResolvedAstKind.DEFAULT_CONSTRUCTOR);
  }

  bool get isDefaultConstructor {
    return _resolvedAst.kind == ResolvedAstKind.DEFAULT_CONSTRUCTOR;
  }

  FunctionExpression parseNode(ParsingContext parsing) => null;

  bool get hasNode => false;

  FunctionExpression get node => null;

  Token get position => enclosingElement.position;

  bool get isSynthesized => true;

  bool get hasResolvedAst => true;

  ResolvedAst get resolvedAst => _resolvedAst;

  ResolutionFunctionType get type {
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
          type:
              new ResolutionFunctionType.synthesized(enclosingClass.thisType));
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

abstract class TypeDeclarationElementX implements TypeDeclarationElement {
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
  GenericType thisTypeCache;

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
   * instantiation of [ResolutionInterfaceType] with [:dynamic:] as type
   * argument. Using this distinction, we can print the raw type with type
   * arguments only when the input source has used explicit type arguments.
   *
   * This type is computed together with [thisType] in [computeType].
   */
  GenericType rawTypeCache;

  GenericType get thisType {
    assert(thisTypeCache != null,
        failedAt(this, 'This type has not been computed for $this'));
    return thisTypeCache;
  }

  GenericType get rawType {
    assert(rawTypeCache != null,
        failedAt(this, 'Raw type has not been computed for $this'));
    return rawTypeCache;
  }

  GenericType createType(List<ResolutionDartType> typeArguments);

  void setThisAndRawTypes(List<ResolutionDartType> typeParameters) {
    assert(thisTypeCache == null,
        failedAt(this, "This type has already been set on $this."));
    assert(rawTypeCache == null,
        failedAt(this, "Raw type has already been set on $this."));
    thisTypeCache = createType(typeParameters);
    if (typeParameters.isEmpty) {
      rawTypeCache = thisTypeCache;
    } else {
      List<ResolutionDartType> dynamicParameters =
          new List.filled(typeParameters.length, const ResolutionDynamicType());
      rawTypeCache = createType(dynamicParameters);
    }
  }

  List<ResolutionDartType> get typeVariables => thisType.typeArguments;

  /**
   * Creates the type variables, their type and corresponding element, for the
   * type variables declared in [parameter] on [element]. The bounds of the type
   * variables are not set until [element] has been resolved.
   */
  List<ResolutionDartType> createTypeVariables(NodeList parameters) {
    if (parameters == null) return const <ResolutionDartType>[];

    // Create types and elements for type variable.
    Link<Node> nodes = parameters.nodes;
    List<ResolutionDartType> arguments =
        new List.generate(nodes.slowLength(), (int index) {
      TypeVariable node = nodes.head;
      String variableName = node.name.source;
      nodes = nodes.tail;
      TypeVariableElementX variableElement =
          new TypeVariableElementX(variableName, this, index, node);
      ResolutionTypeVariableType variableType =
          new ResolutionTypeVariableType(variableElement);
      variableElement.typeCache = variableType;
      return variableType;
    }, growable: false);
    return arguments;
  }

  bool get isResolved => resolutionState == STATE_DONE;

  int get resolutionState;
}

abstract class BaseClassElementX extends ElementX
    with
        AstElementMixin,
        AnalyzableElementX,
        ClassElementCommon,
        TypeDeclarationElementX,
        PatchMixin<ClassElement>,
        ClassMemberMixin
    implements ClassElement {
  final int id;

  ResolutionInterfaceType supertype;
  Link<ResolutionDartType> interfaces;
  int supertypeLoadState;
  int resolutionState;
  bool isProxy = false;
  bool hasIncompleteHierarchy = false;

  OrderedTypeSet allSupertypesAndSelf;

  BaseClassElementX(String name, Element enclosing, this.id, int initialState)
      : supertypeLoadState = initialState,
        resolutionState = initialState,
        super(name, ElementKind.CLASS, enclosing);

  int get hashCode => id;

  bool get isUnnamedMixinApplication => false;

  @override
  bool get isEnumClass => false;

  ResolutionInterfaceType computeType(Resolution resolution) {
    if (isPatch) {
      origin.computeType(resolution);
      thisTypeCache = origin.thisType;
      rawTypeCache = origin.rawType;
    } else if (thisTypeCache == null) {
      computeThisAndRawType(
          resolution, computeTypeParameters(resolution.parsingContext));
    }
    return thisTypeCache;
  }

  void computeThisAndRawType(
      Resolution resolution, List<ResolutionDartType> typeVariables) {
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
  ResolutionInterfaceType createType(List<ResolutionDartType> typeArguments) {
    return new ResolutionInterfaceType(this, typeArguments);
  }

  List<ResolutionDartType> computeTypeParameters(ParsingContext parsing);

  bool get isObject {
    assert(isResolved,
        failedAt(this, "isObject has not been computed for $this."));
    return supertype == null;
  }

  void ensureResolved(Resolution resolution) {
    if (resolutionState == STATE_NOT_STARTED) {
      resolution.resolveClass(this);
      resolution.registerClass(this);
    }
  }

  void setDefaultConstructor(
      FunctionElement constructor, DiagnosticReporter reporter);

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
    assert(supertypeLoadState == STATE_DONE,
        failedAt(this, "Superclass has not been computed for $this."));
    return supertype == null ? null : supertype.element;
  }

  // A class declaration is defined by the declaration element.
  AstElement get definingElement => declaration;

  ResolutionInterfaceType get thisType => super.thisType;

  ResolutionInterfaceType get rawType => super.rawType;

  // TODO(johnniwinther): Remove this.
  ClassElement get declaration => super.declaration;

  // TODO(johnniwinther): Remove this.
  ClassElement get implementation => super.implementation;

  // TODO(johnniwinther): Remove this.
  ClassElement get origin => super.origin;

  // TODO(johnniwinther): Remove this.
  ClassElement get patch => super.patch;
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
      reporter.reportErrorMessage(element, MessageKind.MEMBER_USES_CLASS_NAME);
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

  void setDefaultConstructor(
      FunctionElement constructor, DiagnosticReporter reporter) {
    // The default constructor, although synthetic, is part of a class' API.
    addMember(constructor, reporter);
  }

  List<ResolutionDartType> computeTypeParameters(ParsingContext parsing) {
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

/// This element is used to encode an enum class.
///
/// For instance
///
///     enum A { b, c, }
///
/// is modelled as
///
///     class A {
///       final int index;
///
///       const A(this.index);
///
///       String toString() {
///         return const <int, A>{0: 'A.b', 1: 'A.c'}[index];
///       }
///
///       static const A b = const A(0);
///       static const A c = const A(1);
///
///       static const List<A> values = const <A>[b, c];
///     }
///
///  where the `A` class is encoded using this element.
///
class EnumClassElementX extends ClassElementX
    implements EnumClassElement, DeclarationSite {
  final Enum node;
  List<EnumConstantElement> _enumValues;

  EnumClassElementX(String name, Element enclosing, int id, this.node)
      : super(name, enclosing, id, STATE_NOT_STARTED);

  @override
  bool get hasNode => true;

  @override
  Token get position => node.name.token;

  @override
  bool get isEnumClass => true;

  @override
  Node parseNode(ParsingContext parsing) => node;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitEnumClassElement(this, arg);
  }

  List<ResolutionDartType> computeTypeParameters(ParsingContext parsing) =>
      const <ResolutionDartType>[];

  List<EnumConstantElement> get enumValues {
    assert(_enumValues != null,
        failedAt(this, "enumValues has not been computed for $this."));
    return _enumValues;
  }

  void set enumValues(List<EnumConstantElement> values) {
    assert(_enumValues == null,
        failedAt(this, "enumValues has already been computed for $this."));
    _enumValues = values;
  }

  @override
  DeclarationSite get declarationSite => this;
}

/// This element is used to encode the implicit constructor in an enum class.
///
/// For instance
///
///     enum A { b, c, }
///
/// is modelled as
///
///     class A {
///       final int index;
///
///       const A(this.index);
///
///       String toString() {
///         return const <int, A>{0: 'A.b', 1: 'A.c'}[index];
///       }
///
///       static const A b = const A(0);
///       static const A c = const A(1);
///
///       static const List<A> values = const <A>[b, c];
///     }
///
///  where the `const A(...)` constructor is encoded using this element.
///
class EnumConstructorElementX extends ConstructorElementX {
  final FunctionExpression node;

  EnumConstructorElementX(
      EnumClassElementX enumClass, Modifiers modifiers, this.node)
      : super(
            '', // Name.
            ElementKind.GENERATIVE_CONSTRUCTOR,
            modifiers,
            enumClass);

  @override
  bool get hasNode => true;

  @override
  FunctionExpression parseNode(ParsingContext parsing) => node;

  @override
  SourceSpan get sourcePosition => enclosingClass.sourcePosition;
}

/// This element is used to encode the implicit methods in an enum class.
///
/// For instance
///
///     enum A { b, c, }
///
/// is modelled as
///
///     class A {
///       final int index;
///
///       const A(this.index);
///
///       String toString() {
///         return const <int, A>{0: 'A.b', 1: 'A.c'}[index];
///       }
///
///       static const A b = const A(0);
///       static const A c = const A(1);
///
///       static const List<A> values = const <A>[b, c];
///     }
///
///  where the `toString` method is encoded using this element.
///
class EnumMethodElementX extends MethodElementX {
  final FunctionExpression node;

  EnumMethodElementX(
      String name, EnumClassElementX enumClass, Modifiers modifiers, this.node)
      : super(name, ElementKind.FUNCTION, modifiers, enumClass, true);

  @override
  bool get hasNode => true;

  @override
  FunctionExpression parseNode(ParsingContext parsing) => node;

  @override
  SourceSpan get sourcePosition => enclosingClass.sourcePosition;
}

/// This element is used to encode the initializing formal of the implicit
/// constructor in an enum class.
///
/// For instance
///
///     enum A { b, c, }
///
/// is modelled as
///
///     class A {
///       final int index;
///
///       const A(this.index);
///
///       String toString() {
///         return const <int, A>{0: 'A.b', 1: 'A.c'}[index];
///       }
///
///       static const A b = const A(0);
///       static const A c = const A(1);
///
///       static const List<A> values = const <A>[b, c];
///     }
///
///  where the `this.index` formal is encoded using this element.
///
class EnumFormalElementX extends InitializingFormalElementX {
  EnumFormalElementX(
      ConstructorElement constructor,
      VariableDefinitions variables,
      Identifier identifier,
      EnumFieldElementX fieldElement)
      : super(constructor, variables, identifier, null, fieldElement) {
    typeCache = fieldElement.type;
  }

  @override
  SourceSpan get sourcePosition => enclosingClass.sourcePosition;
}

/// This element is used to encode the implicitly fields in an enum class.
///
/// For instance
///
///     enum A { b, c, }
///
/// is modelled as
///
///     class A {
///       final int index;
///
///       const A(this.index);
///
///       String toString() {
///         return const <int, A>{0: 'A.b', 1: 'A.c'}[index];
///       }
///
///       static const A b = const A(0);
///       static const A c = const A(1);
///
///       static const List<A> values = const <A>[b, c];
///     }
///
///  where the `index` and `values` fields are encoded using this element.
///
class EnumFieldElementX extends FieldElementX {
  EnumFieldElementX(Identifier name, EnumClassElementX enumClass,
      VariableList variableList, Node definition,
      [Expression initializer])
      : super(name, enumClass, variableList) {
    definitionsCache = new VariableDefinitions(
        null, variableList.modifiers, new NodeList.singleton(definition));
    initializerCache = initializer;
    definitionCache = definition;
  }

  @override
  SourceSpan get sourcePosition => enclosingClass.sourcePosition;
}

/// This element is used to encode the constant value in an enum class.
///
/// For instance
///
///     enum A { b, c, }
///
/// is modelled as
///
///     class A {
///       final int index;
///
///       const A(this.index);
///
///       String toString() {
///         return const <int, A>{0: 'A.b', 1: 'A.c'}[index];
///       }
///
///       static const A b = const A(0);
///       static const A c = const A(1);
///
///       static const List<A> values = const <A>[b, c];
///     }
///
///  where the `b` and `c` fields are encoded using this element.
///
class EnumConstantElementX extends EnumFieldElementX
    implements EnumConstantElement {
  final int index;

  EnumConstantElementX(
      Identifier name,
      EnumClassElementX enumClass,
      VariableList variableList,
      Node definition,
      Expression initializer,
      this.index)
      : super(name, enumClass, variableList, definition, initializer);

  @override
  SourceSpan get sourcePosition {
    return new SourceSpan(enclosingClass.sourcePosition.uri,
        position.charOffset, position.charEnd);
  }

  EnumClassElement get enclosingClass => super.enclosingClass;
}

abstract class MixinApplicationElementX extends BaseClassElementX
    with MixinApplicationElementCommon
    implements MixinApplicationElement {
  Link<ConstructorElement> constructors = new Link<ConstructorElement>();

  ResolutionInterfaceType mixinType;

  MixinApplicationElementX(String name, Element enclosing, int id)
      : super(name, enclosing, id, STATE_NOT_STARTED);

  ClassElement get mixin => mixinType != null ? mixinType.element : null;

  bool get isMixinApplication => true;
  bool get hasConstructor => !constructors.isEmpty;
  bool get hasLocalScopeMembers => !constructors.isEmpty;

  get patch => null;
  get origin => null;

  bool get hasNode => true;

  Token get position => node.getBeginToken();

  Node parseNode(ParsingContext parsing) => node;

  void addMember(Element element, DiagnosticReporter reporter) {
    throw new UnsupportedError("Cannot add member to $this.");
  }

  void addToScope(Element element, DiagnosticReporter reporter) {
    reporter.internalError(this, 'Cannot add to scope of $this.');
  }

  void addConstructor(FunctionElement constructor) {
    constructors = constructors.prepend(constructor);
  }

  void setDefaultConstructor(
      FunctionElement constructor, DiagnosticReporter reporter) {
    assert(!hasConstructor);
    addConstructor(constructor);
  }

  List<ResolutionDartType> computeTypeParameters(ParsingContext parsing) {
    NamedMixinApplication named = node.asNamedMixinApplication();
    if (named == null) {
      failedAt(
          node,
          "Type variables on unnamed mixin applications must be set on "
          "creation.");
    }
    return createTypeVariables(named.typeParameters);
  }

  accept(ElementVisitor visitor, arg) {
    return visitor.visitMixinApplicationElement(this, arg);
  }
}

class NamedMixinApplicationElementX extends MixinApplicationElementX
    implements DeclarationSite {
  final NamedMixinApplication node;

  NamedMixinApplicationElementX(
      String name, CompilationUnitElement enclosing, int id, this.node)
      : super(name, enclosing, id);

  Modifiers get modifiers => node.modifiers;

  DeclarationSite get declarationSite => this;

  ClassElement get subclass => null;
}

class UnnamedMixinApplicationElementX extends MixinApplicationElementX {
  final Node node;
  final ClassElement subclass;

  UnnamedMixinApplicationElementX(
      String name, ClassElement subclass, int id, this.node)
      : this.subclass = subclass,
        super(name, subclass.compilationUnit, id);

  bool get isUnnamedMixinApplication => true;

  bool get isAbstract => true;
}

class LabelDefinitionX extends LabelDefinition<Node> {
  final Label label;
  final String labelName;
  final JumpTargetX target;
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

  String toString() => 'Label:${name}';
}

class JumpTargetX extends JumpTarget<Node> {
  final ExecutableElement executableContext;
  final Node statement;
  final int nestingLevel;
  List<LabelDefinition<Node>> labels = <LabelDefinition<Node>>[];
  bool isBreakTarget = false;
  bool isContinueTarget = false;

  final int hashCode = ElementX.newHashCode();

  JumpTargetX(this.statement, this.nestingLevel, this.executableContext);

  @override
  MemberElement get memberContext => executableContext.memberContext;

  LabelDefinition<Node> addLabel(Label label, String labelName,
      {bool isBreakTarget: false}) {
    LabelDefinitionX result = new LabelDefinitionX(label, labelName, this);
    labels.add(result);
    if (isBreakTarget) {
      result.setBreakTarget();
    }
    return result;
  }

  bool get isSwitch => statement is SwitchStatement;

  String toString() => 'Target:$statement';
}

class TypeVariableElementX extends ElementX
    with AstElementMixin
    implements TypeVariableElement {
  final int index;
  final Node node;
  ResolutionTypeVariableType typeCache;
  ResolutionDartType boundCache;

  TypeVariableElementX(
      String name, GenericElement enclosing, this.index, this.node)
      : super(name, ElementKind.TYPE_VARIABLE, enclosing);

  GenericElement get typeDeclaration => enclosingElement;

  ResolutionTypeVariableType computeType(Resolution resolution) => type;

  ResolutionTypeVariableType get type {
    assert(
        typeCache != null, failedAt(this, "Type has not been set on $this."));
    return typeCache;
  }

  ResolutionDartType get bound {
    assert(
        boundCache != null, failedAt(this, "Bound has not been set on $this."));
    return boundCache;
  }

  bool get hasNode => true;

  Node parseNode(ParsingContext parsing) => node;

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

  Token get endToken;

  final int hashCode = ElementX.newHashCode();

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

  Node parseNode(ParsingContext parsing);

  SourceSpan get sourcePosition {
    Uri uri = annotatedElement.compilationUnit.script.resourceUri;
    return new SourceSpan.fromTokens(uri, beginToken, endToken);
  }

  String toString() => 'MetadataAnnotation($constant, $resolutionState)';
}

/// Metadata annotation on a parameter.
class ParameterMetadataAnnotation extends MetadataAnnotationX {
  final Metadata metadata;

  ParameterMetadataAnnotation(Metadata this.metadata);

  Node parseNode(ParsingContext parsing) => metadata.expression;

  Token get beginToken => metadata.getBeginToken();

  Token get endToken => metadata.getEndToken();

  bool get hasNode => true;

  Metadata get node => metadata;
}

/// Mixin for the implementation of patched elements.
///
/// See `patch_parser.dart` for a description of the terminology.
abstract class PatchMixin<E extends Element> implements Element {
  // TODO(johnniwinther): Use type variables.
  Element /* E */ patch = null;
  Element /* E */ origin = null;

  bool get isPatch => origin != null;
  bool get isPatched => patch != null;

  bool get isImplementation => !isPatched;
  bool get isDeclaration => !isPatch;

  Element /* E */ get implementation => isPatched ? patch : this;
  Element /* E */ get declaration => isPatch ? origin : this;

  /// Applies a patch to this element. This method must be called at most once.
  void applyPatch(PatchMixin<E> patch) {
    assert(this.patch == null, failedAt(this, "Element is patched twice."));
    assert(this.origin == null, failedAt(this, "Origin element is a patch."));
    assert(patch.origin == null, failedAt(patch, "Element is patched twice."));
    assert(patch.patch == null, failedAt(patch, "Patch element is patched."));
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

  bool get hasResolvedAst {
    return definingElement.hasNode && definingElement.hasTreeElements;
  }

  ResolvedAst get resolvedAst {
    Node node = definingElement.node;
    Node body;
    if (definingElement.isField) {
      FieldElement field = definingElement;
      body = field.initializer;
    } else if (node != null && node.asFunctionExpression() != null) {
      body = node.asFunctionExpression().body;
    }
    return new ParsedResolvedAst(
        declaration,
        node,
        body,
        definingElement.treeElements,
        definingElement.compilationUnit.script.resourceUri);
  }
}
