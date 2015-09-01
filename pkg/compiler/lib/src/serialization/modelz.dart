// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the element model used for deserialiation.
///
/// These classes are created by [ElementDeserializer] triggered by the
/// [Deserializer].

library dart2js.serialization.modelz;

import 'serialization.dart';
import 'keys.dart';
import '../compiler.dart'
    show Compiler;
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../diagnostics/source_span.dart'
    show SourceSpan;
import '../dart_types.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart' show
    FunctionSignatureX;
import '../elements/common.dart';
import '../elements/visitor.dart';
import '../io/source_file.dart';
import '../ordered_typeset.dart';
import '../resolution/class_members.dart' as class_members;
import '../resolution/enum_creator.dart' show
    AstBuilder;
import '../resolution/tree_elements.dart' show
    TreeElements;
import '../resolution/scope.dart' show
    Scope;
import '../scanner/scannerlib.dart' show
    Token,
    SEMICOLON_INFO;
import '../script.dart';
import '../serialization/constant_serialization.dart';
import '../tree/tree.dart';
import '../util/util.dart' show
    Link,
    LinkBuilder;

/// Compute a [Link] from an [Iterable].
Link toLink(Iterable iterable) {
  LinkBuilder builder = new LinkBuilder();
  for (var element in iterable) {
    builder.addLast(element);
  }
  return builder.toLink();
}

abstract class ElementZ extends Element with ElementCommon {
  @override
  bool get isFactoryConstructor => false;

  String toString() {
    if (enclosingElement == null || isTopLevel) return 'Z$kind($name)';
    return 'Z$kind(${enclosingElement.name}#$name)';
  }

  _unsupported(text) => throw new UnsupportedError('${this}.$text');

  @override
  AnalyzableElement get analyzableElement {
    Element element = this;
    if (element is AnalyzableElement) {
      return element;
    } else if (enclosingElement != null) {
      return enclosingElement.analyzableElement;
    }
    return null;
  }

  @override
  FunctionElement asFunctionElement() => null;

  @override
  Scope buildScope() => _unsupported('analyzableElement');

  @override
  CompilationUnitElement get compilationUnit {
    return _unsupported('compilationUnit');
  }

  @override
  ClassElement get contextClass => _unsupported('contextClass');

  @override
  void diagnose(Element context, DiagnosticListener listener) {
    _unsupported('diagnose');
  }

  @override
  ClassElement get enclosingClass => null;

  @override
  Element get enclosingClassOrCompilationUnit {
    return _unsupported('enclosingClassOrCompilationUnit');
  }

  @override
  String get fixedBackendName => _unsupported('fixedBackendName');

  @override
  bool get hasFixedBackendName => _unsupported('hasFixedBackendName');

  @override
  LibraryElement get implementationLibrary => library;

  @override
  bool get isAbstract => false;

  @override
  bool get isAssignable => _unsupported('isAssignable');

  @override
  bool get isClassMember => false;

  @override
  bool get isClosure => _unsupported('isClosure');

  @override
  bool get isConst => _unsupported('isConst');

  @override
  bool get isDeferredLoaderGetter => false;

  @override
  bool get isFinal => _unsupported('isFinal');

  @override
  bool get isInstanceMember => false;

  @override
  bool get isLocal => false;

  @override
  bool get isMixinApplication => false;

  @override
  bool get isNative => false;

  @override
  bool get isOperator => false;

  @override
  bool get isStatic => false;

  // TODO(johnniwinther): Find a more precise semantics for this.
  @override
  bool get isSynthesized => true;

  @override
  bool get isTopLevel => false;

  // TODO(johnniwinther): Support metadata.
  @override
  Link<MetadataAnnotation> get metadata => const Link<MetadataAnnotation>();

  @override
  Element get outermostEnclosingMemberOrTopLevel {
    return _unsupported('outermostEnclosingMemberOrTopLevel');
  }

  @override
  Token get position => _unsupported('position');
}

abstract class DeserializedElementZ extends ElementZ {
  ObjectDecoder _decoder;

  DeserializedElementZ(this._decoder);

  @override
  String get name => _decoder.getString(Key.NAME);

  @override
  SourceSpan get sourcePosition {
    // TODO(johnniwinther): Should this be cached?
    int offset = _decoder.getInt(Key.OFFSET, isOptional: true);
    if (offset == null) return null;
    Uri uri = _decoder.getUri(Key.URI, isOptional: true);
    if (uri == null) {
      uri = compilationUnit.script.readableUri;
    }
    int length = _decoder.getInt(Key.LENGTH, isOptional: true);
    if (length == null) {
      length = name.length;
    }
    return new SourceSpan(uri, offset, offset + length);
  }
}

/// Deserializer for a collection of member elements serialized as a map from
/// names to element declarations.
///
/// The serialized data contains the declared getters and setters but lookup
/// into the map returns an [AbstractFieldElement] for pairs of corresponding
/// getters and setters.
///
/// The underlying map encoding allows for lazy computation of the members upon
/// query.
class MappedContainer {
  Map<String, Element> _lookupCache = {};

  Element lookup(String name, MapDecoder members) {
    if (_lookupCache.containsKey(name)) {
      Element element = _lookupCache[name];
      if (element != null) {
        return element;
      }
    }
    if (members == null) {
      return null;
    }
    bool hasId = members.containsKey(name);
    String setterName = '$name,=';
    bool hasSetterId = members.containsKey(setterName);
    Element element;
    Element setterElement;
    if (!hasId && !hasSetterId) {
      _lookupCache[name] = null;
      return null;
    }
    bool isAccessor = false;
    if (hasId) {
      element = members.getElement(name);
      isAccessor = element.isGetter;
    }
    if (hasSetterId) {
      setterElement = members.getElement(setterName);
      isAccessor = true;
    }
    if (isAccessor) {
      element = new AbstractFieldElementZ(name, element, setterElement);
    }
    _lookupCache[name] = element;
    return element;
  }
}

/// Deserializer for a collection of member elements serialized as a list of
/// element declarations.
///
/// The serialized data contains the declared getters and setters but lookup
/// into the map returns an [AbstractFieldElement] for pairs of corresponding
/// getters and setters.
///
/// The underlying list encoding requires the complete lookup map to be computed
/// before query.
class ListedContainer {
  final Map<String, Element> _lookupMap = <String, Element>{};

  ListedContainer(List<Element> elements) {
    Set<String> accessorNames = new Set<String>();
    Map<String, Element> getters = <String, Element>{};
    Map<String, Element> setters = <String, Element>{};
    for (Element element in elements) {
      String name = element.name;
      if (element.isGetter) {
        accessorNames.add(name);
        getters[name] = element;
        // Inserting [element] here to ensure insert order of [name].
        _lookupMap[name] = element;
      } else if (element.isSetter) {
        accessorNames.add(name);
        setters[name] = element;
        // Inserting [element] here to ensure insert order of [name].
        _lookupMap[name] = element;
      } else {
        _lookupMap[name] = element;
      }
    }
    for (String name in accessorNames) {
      _lookupMap[name] =
          new AbstractFieldElementZ(name, getters[name], setters[name]);
    }
  }

  Element lookup(String name) => _lookupMap[name];

  void forEach(f(Element element)) => _lookupMap.values.forEach(f);

  Iterable<Element> get values => _lookupMap.values;
}


abstract class AnalyzableElementMixin implements AnalyzableElement, ElementZ {
  @override
  bool get hasTreeElements => _unsupported('hasTreeElements');

  @override
  TreeElements get treeElements => _unsupported('treeElements');
}


abstract class AstElementMixin implements AstElement, ElementZ {
  @override
  bool get hasNode => _unsupported('hasNode');

  @override
  bool get hasResolvedAst => _unsupported('hasResolvedAst');

  @override
  get node => _unsupported('node');

  @override
  ResolvedAst get resolvedAst => _unsupported('resolvedAst');
}

abstract class ContainerMixin
    implements DeserializedElementZ, ScopeContainerElement {
  MappedContainer _membersMap = new MappedContainer();

  @override
  Element localLookup(String name) {
    return _membersMap.lookup(
        name, _decoder.getMap(Key.MEMBERS, isOptional: true));
  }

  @override
  void forEachLocalMember(f(Element element)) {
    MapDecoder members =
        _decoder.getMap(Key.MEMBERS, isOptional: true);
    if (members == null) return;
    members.forEachKey((String key) {
      Element member = members.getElement(key);
      if (member != null) {
        f(member);
      }
    });
  }
}

class AbstractFieldElementZ extends ElementZ implements AbstractFieldElement {
  final String name;
  final FunctionElement getter;
  final FunctionElement setter;

  AbstractFieldElementZ(this.name, this.getter, this.setter);

  @override
  ElementKind get kind => ElementKind.ABSTRACT_FIELD;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitAbstractFieldElement(this, arg);
  }

  @override
  LibraryElement get library {
    return getter != null ? getter.library : setter.library;
  }

  @override
  Element get enclosingElement {
    return getter != null ? getter.enclosingElement : setter.enclosingElement;
  }

  @override
  SourceSpan get sourcePosition {
    return getter != null ? getter.sourcePosition : setter.sourcePosition;
  }
}

class LibraryElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         ContainerMixin,
         LibraryElementCommon
    implements LibraryElement {
  Uri _canonicalUri;
  CompilationUnitElement _entryCompilationUnit;
  Link<CompilationUnitElement> _compilationUnits;
  Link<Element> _exports;
  ListedContainer _exportsMap;
  ListedContainer _importsMap;
  Map<LibraryTag, LibraryElement> _libraryDependencies;

  LibraryElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  Element get enclosingElement => null;

  @override
  String get name => entryCompilationUnit.name;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitLibraryElement(this, arg);
  }

  @override
  LibraryElement get library => this;

  @override
  Uri get canonicalUri {
    if (_canonicalUri == null) {
      _canonicalUri = _decoder.getUri(Key.CANONICAL_URI);
    }
    return _canonicalUri;
  }

  @override
  CompilationUnitElement get entryCompilationUnit {
    if (_entryCompilationUnit == null) {
      _entryCompilationUnit = _decoder.getElement(Key.COMPILATION_UNIT);
    }
    return _entryCompilationUnit;
  }

  @override
  Link<CompilationUnitElement> get compilationUnits {
    if (_compilationUnits == null) {
      _compilationUnits =
          toLink(_decoder.getElements(Key.COMPILATION_UNITS));
    }
    return _compilationUnits;
  }

  @override
  bool hasLibraryName() {
    return getLibraryName() != '';
  }

  @override
  String getLibraryName() {
    return _decoder.getString(Key.LIBRARY_NAME);
  }

  @override
  bool get exportsHandled => true;

  void _ensureExports() {
    if (_exports == null) {
      _exportsMap = new ListedContainer(_decoder.getElements(Key.EXPORTS));
      _exports = toLink(_exportsMap.values);
    }
  }

  Link<Element> get exports {
    _ensureExports();
    return _exports;
  }

  @override
  void forEachExport(f(Element element)) {
    exports.forEach(f);
  }

  @override
  Element find(String elementName) {
    Element element = localLookup(elementName);
    if (element == null) {
      _ensureImports();
      element = _importsMap.lookup(elementName);
    }
    return element;
  }

  @override
  Element findLocal(String elementName) {
    return localLookup(elementName);
  }

  void _ensureLibraryDependencies() {
    if (_libraryDependencies == null) {
      _libraryDependencies = <LibraryTag, LibraryElement>{};
      ListDecoder tags = _decoder.getList(Key.TAGS);
      AstBuilder builder = new AstBuilder(0);
      for (int i = 0; i < tags.length; i++) {
        ObjectDecoder dependency = tags.getObject(i);
        String kind = dependency.getString(Key.KIND);
        LibraryElement library = dependency.getElement(Key.LIBRARY);
        // TODO(johnniwinther): Add `ImportElement` and `ExportElement` to the
        // element model to avoid hacking up nodes.
        if (kind == 'import') {
          Import tag = new Import(
              builder.keywordToken('import'),
              builder.literalString(library.canonicalUri.toString())
                  ..getEndToken().next = builder.symbolToken(SEMICOLON_INFO),
              null, // prefix
              null, // combinators
              null, // metadata
              isDeferred: false);
          _libraryDependencies[tag] = library;
        } else if (kind == 'export') {
          Export tag = new Export(
              builder.keywordToken('export'),
              builder.literalString(library.canonicalUri.toString())
                  ..getEndToken().next = builder.symbolToken(SEMICOLON_INFO),
              null,  // combinators
              null); // metadata
          _libraryDependencies[tag] = library;
        }
      }
    }
  }

  @override
  Iterable<LibraryTag> get tags {
    _ensureLibraryDependencies();
    return _libraryDependencies.keys;
  }

  LibraryElement getLibraryFromTag(LibraryDependency tag) {
    _ensureLibraryDependencies();
    return _libraryDependencies[tag];
  }

  @override
  bool get canUseNative => false;

  @override
  Element findExported(String elementName) => _unsupported('findExported');

  void _ensureImports() {
    if (_importsMap == null) {
      _importsMap = new ListedContainer(_decoder.getElements(Key.IMPORTS));
    }
  }

  @override
  void forEachImport(f(Element element)) {
    _ensureImports();
    _importsMap.forEach(f);
  }

  @override
  Link<Import> getImportsFor(Element element) => _unsupported('getImportsFor');

  @override
  LibraryName get libraryTag => _unsupported('libraryTag');

  String toString() {
    return 'Zlibrary(${canonicalUri})';
  }
}

class ScriptZ implements Script {
  final Uri resourceUri;

  ScriptZ(this.resourceUri);

  @override
  Script copyWithFile(SourceFile file) {
    throw new UnsupportedError('ScriptZ.copyWithFile');
  }

  @override
  SourceFile get file => throw new UnsupportedError('ScriptZ.file');

  @override
  bool get isSynthesized => throw new UnsupportedError('ScriptZ.isSynthesized');

  @override
  String get name => resourceUri.toString();

  // TODO(johnniwinther): Support the distinction between [readableUri] and
  // [resourceUri]; needed for platform libraries.
  @override
  Uri get readableUri => resourceUri;

  @override
  String get text => throw new UnsupportedError('ScriptZ.text');
}

class CompilationUnitElementZ extends DeserializedElementZ
    with LibraryMemberMixin,
         CompilationUnitElementCommon
    implements CompilationUnitElement {
  List<Element> _members;
  Script _script;

  CompilationUnitElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  @override
  CompilationUnitElement get compilationUnit => this;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitCompilationUnitElement(this, arg);
  }

  @override
  void forEachLocalMember(f(Element element)) {
    if (_members == null) {
      _members =
          _decoder.getElements(Key.ELEMENTS, isOptional: true);
    }
    _members.forEach(f);
  }

  @override
  Script get script {
    if (_script == null) {
      Uri resolvedUri = _decoder.getUri(Key.URI);
      _script = new ScriptZ(resolvedUri);
    }
    return _script;
  }

  @override
  String get name => script.name;
}


abstract class LibraryMemberMixin implements DeserializedElementZ {
  LibraryElement _library;
  CompilationUnitElement _compilationUnit;

  @override
  LibraryElement get library {
    if (_library == null) {
      _library = _decoder.getElement(Key.LIBRARY);
    }
    return _library;
  }

  @override
  CompilationUnitElement get compilationUnit {
    if (_compilationUnit == null) {
      _compilationUnit = _decoder.getElement(Key.COMPILATION_UNIT);
    }
    return _compilationUnit;
  }

  @override
  Element get enclosingElement => compilationUnit;

  @override
  ClassElement get enclosingClass => null;

  @override
  bool get isTopLevel => true;

  @override
  bool get isStatic => false;
}

abstract class ClassMemberMixin implements DeserializedElementZ {
  ClassElement _class;

  @override
  Element get enclosingElement => enclosingClass;

  @override
  ClassElement get enclosingClass {
    if (_class == null) {
      _class = _decoder.getElement(Key.CLASS);
    }
    return _class;
  }

  @override
  bool get isClassMember => true;

  @override
  LibraryElement get library => enclosingClass.library;

  @override
  CompilationUnitElement get compilationUnit => enclosingClass.compilationUnit;
}

abstract class InstanceMemberMixin implements DeserializedElementZ {
  @override
  bool get isTopLevel => false;

  @override
  bool get isStatic => false;

  @override
  bool get isInstanceMember => true;
}

abstract class StaticMemberMixin implements DeserializedElementZ {
  @override
  bool get isTopLevel => false;

  @override
  bool get isStatic => true;
}

abstract class TypedElementMixin
    implements DeserializedElementZ, TypedElement {
  DartType _type;

  @override
  DartType get type {
    if (_type == null) {
      _type = _decoder.getType(Key.TYPE);
    }
    return _type;
  }

  @override
  DartType computeType(Compiler compiler) => type;
}

abstract class ParametersMixin
    implements DeserializedElementZ, FunctionTypedElement {
  FunctionSignature _functionSignature;
  List<ParameterElement> _parameters;

  bool get hasFunctionSignature => true;

  @override
  FunctionSignature get functionSignature {
    if (_functionSignature == null) {
      List<Element> requiredParameters = [];
      List<Element> optionalParameters = [];
      List orderedOptionalParameters = [];
      int requiredParameterCount = 0;
      int optionalParameterCount = 0;
      bool optionalParametersAreNamed = false;
      List<DartType> parameterTypes = <DartType>[];
      List<DartType> optionalParameterTypes = <DartType>[];
      List<String> namedParameters = <String>[];
      List<DartType> namedParameterTypes = <DartType>[];
      for (ParameterElement parameter in parameters) {
        if (parameter.isOptional) {
          optionalParameterCount++;
          requiredParameters.add(parameter);
          orderedOptionalParameters.add(parameter);
          if (parameter.isNamed) {
            optionalParametersAreNamed = true;
            namedParameters.add(parameter.name);
            namedParameterTypes.add(parameter.type);
          } else {
            optionalParameterTypes.add(parameter.type);
          }
        } else {
          requiredParameterCount++;
          optionalParameters.add(parameter);
          parameterTypes.add(parameter.type);
        }
      }
      if (optionalParametersAreNamed) {
        orderedOptionalParameters.sort((Element a, Element b) {
            return a.name.compareTo(b.name);
        });
      }

      FunctionType type = new FunctionType(
          this,
          _decoder.getType(Key.RETURN_TYPE),
          parameterTypes,
          optionalParameterTypes,
          namedParameters,
          namedParameterTypes);
      _functionSignature = new FunctionSignatureX(
          requiredParameters: requiredParameters,
          requiredParameterCount: requiredParameterCount,
          optionalParameters: optionalParameters,
          optionalParameterCount: optionalParameterCount,
          optionalParametersAreNamed: optionalParametersAreNamed,
          orderedOptionalParameters: orderedOptionalParameters,
          type: type);
    }
    return _functionSignature;
  }

  List<ParameterElement> get parameters {
    if (_parameters == null) {
      _parameters = _decoder.getElements(Key.PARAMETERS, isOptional: true);
    }
    return _parameters;
  }
}

abstract class FunctionTypedElementMixin
    implements FunctionElement, DeserializedElementZ {
  @override
  AsyncMarker get asyncMarker => _unsupported('');

  @override
  bool get isExternal => _unsupported('');

  @override
  FunctionElement asFunctionElement() => this;
}

class ClassElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         ClassElementCommon,
         class_members.ClassMemberMixin,
         ContainerMixin,
         LibraryMemberMixin,
         TypeDeclarationMixin<InterfaceType>
    implements ClassElement {
  bool _isObject;
  DartType _supertype;
  OrderedTypeSet _allSupertypesAndSelf;
  Link<DartType> _interfaces;

  ClassElementZ(ObjectDecoder decoder)
      : super(decoder);

  InterfaceType _createType(List<DartType> typeArguments) {
    return new InterfaceType(this, typeArguments);
  }

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitClassElement(this, arg);
  }

  @override
  DartType get supertype {
    if (_isObject == null) {
      _supertype = _decoder.getType(Key.SUPERTYPE, isOptional: true);
      _isObject = _supertype == null;
    }
    return _supertype;
  }

  @override
  bool get isAbstract => _decoder.getBool(Key.IS_ABSTRACT);

  @override
  bool get isObject {
    return supertype == null;
  }

  @override
  void addBackendMember(Element element) => _unsupported('addBackendMember');

  @override
  OrderedTypeSet get allSupertypesAndSelf {
    if (_allSupertypesAndSelf == null) {
      ObjectDecoder supertypesDeserializer =
          _decoder.getObject(Key.SUPERTYPES);
      List<int> offsets = supertypesDeserializer.getInts(Key.OFFSETS);
      List<Link<DartType>> levels = new List<Link<DartType>>(offsets.length);
      LinkBuilder<DartType> typesBuilder = new LinkBuilder<DartType>();
      int offset = 0;
      int depth = offsets.length - 1;
      for (DartType type in supertypesDeserializer.getTypes(Key.TYPES)) {
        Link<DartType> link = typesBuilder.addLast(type);
        if (offsets[depth] == offset) {
          levels[depth] = link;
          depth--;
        }
        offset++;
      }
      LinkBuilder<DartType> supertypesBuilder = new LinkBuilder<DartType>();
      for (DartType supertype in
          supertypesDeserializer.getTypes(Key.SUPERTYPES, isOptional: true)) {
        supertypesBuilder.addLast(supertype);
      }
      Link<DartType> types = typesBuilder.toLink();
      Link<DartType> supertypes = supertypesBuilder.toLink();
      _allSupertypesAndSelf = new OrderedTypeSet.internal(
          levels, types, supertypes);
    }
    return _allSupertypesAndSelf;
  }

  @override
  void forEachBackendMember(void f(Element member)) {
    _unsupported('forEachBackendMember');
  }

  @override
  bool get hasBackendMembers => _unsupported('hasBackendMembers');

  @override
  bool get hasConstructor => _unsupported('hasConstructor');

  @override
  bool hasFieldShadowedBy(Element fieldMember) => _unsupported('');

  @override
  bool get hasIncompleteHierarchy => _unsupported('hasIncompleteHierarchy');

  @override
  bool get hasLocalScopeMembers => _unsupported('hasLocalScopeMembers');

  @override
  bool implementsFunction(Compiler compiler) {
    return _unsupported('implementsFunction');
  }

  @override
  Link<DartType> get interfaces {
    if (_interfaces == null) {
      _interfaces = toLink(
          _decoder.getTypes(Key.INTERFACES, isOptional: true));
    }
    return _interfaces;
  }

  @override
  bool get isEnumClass => false;

  @override
  bool get isProxy => _unsupported('isProxy');

  @override
  bool get isUnnamedMixinApplication {
    return _unsupported('isUnnamedMixinApplication');
  }

  @override
  Element lookupBackendMember(String memberName) {
    return _unsupported('lookupBackendMember');
  }

  @override
  ConstructorElement lookupDefaultConstructor() {
    ConstructorElement constructor = lookupConstructor("");
    if (constructor != null && constructor.parameters.isEmpty) {
      return constructor;
    }
    return null;
  }

  @override
  String get nativeTagInfo => _unsupported('nativeTagInfo');

  @override
  void reverseBackendMembers() => _unsupported('reverseBackendMembers');

  @override
  ClassElement get superclass => supertype != null ? supertype.element : null;
}

abstract class ConstructorElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         ClassMemberMixin,
         FunctionTypedElementMixin,
         ParametersMixin,
         TypedElementMixin,
         MemberElementMixin
    implements ConstructorElement {
  ConstantConstructor _constantConstructor;

  ConstructorElementZ(ObjectDecoder decoder)
      : super(decoder);

  accept(ElementVisitor visitor, arg) {
    return visitor.visitConstructorElement(this, arg);
  }

  @override
  bool get isConst => _decoder.getBool(Key.IS_CONST);

  @override
  bool get isExternal => _decoder.getBool(Key.IS_EXTERNAL);

  bool get isFromEnvironmentConstructor {
    return name == 'fromEnvironment' &&
           library.isDartCore &&
           (enclosingClass.name == 'bool' ||
            enclosingClass.name == 'int' ||
            enclosingClass.name == 'String');
  }

  ConstantConstructor get constantConstructor {
    if (isConst && _constantConstructor == null) {
      ObjectDecoder data =
          _decoder.getObject(Key.CONSTRUCTOR, isOptional: true);
      if (data == null) {
        assert(isFromEnvironmentConstructor || isExternal);
        return null;
      }
      _constantConstructor = ConstantConstructorDeserializer.deserialize(data);
    }
    return _constantConstructor;
  }

  @override
  AsyncMarker get asyncMarker => _unsupported('asyncMarker');

  @override
  InterfaceType computeEffectiveTargetType(InterfaceType newType) {
    return _unsupported('computeEffectiveTargetType');
  }

  @override
  ConstructorElement get definingConstructor  {
    return _unsupported('definingConstructor');
  }

  @override
  ConstructorElement get effectiveTarget  {
    return _unsupported('effectiveTarget');
  }

  @override
  ConstructorElement get immediateRedirectionTarget  {
    return _unsupported('immediateRedirectionTarget');
  }

  @override
  bool get isRedirectingFactory => _unsupported('isRedirectingFactory');

  @override
  bool get isRedirectingGenerative => _unsupported('isRedirectingGenerative');

  @override
  bool get isCyclicRedirection => _unsupported('isCyclicRedirection');

  @override
  PrefixElement get redirectionDeferredPrefix  {
    return _unsupported('redirectionDeferredPrefix');
  }
}

class GenerativeConstructorElementZ extends ConstructorElementZ {
  GenerativeConstructorElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  ElementKind get kind => ElementKind.GENERATIVE_CONSTRUCTOR;
}

class FactoryConstructorElementZ extends ConstructorElementZ {

  FactoryConstructorElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  bool get isFactoryConstructor => true;
}

abstract class MemberElementMixin
    implements DeserializedElementZ, MemberElement {

  @override
  MemberElement get memberContext => this;

  @override
  Name get memberName => new Name(name, library);

  @override
  List<FunctionElement> get nestedClosures => const <FunctionElement>[];

}

abstract class FieldElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         TypedElementMixin,
         MemberElementMixin
    implements FieldElement {
  ConstantExpression _constant;

  FieldElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitFieldElement(this, arg);
  }

  @override
  bool get isFinal => _decoder.getBool(Key.IS_FINAL);

  @override
  bool get isConst => _decoder.getBool(Key.IS_CONST);

  @override
  ConstantExpression get constant {
    if (isConst && _constant == null) {
      _constant = _decoder.getConstant(Key.CONSTANT);
    }
    return _constant;
  }

  @override
  Expression get initializer => _unsupported('initializer');
}


class TopLevelFieldElementZ extends FieldElementZ with LibraryMemberMixin {
  TopLevelFieldElementZ(ObjectDecoder decoder)
      : super(decoder);
}

class StaticFieldElementZ extends FieldElementZ
    with ClassMemberMixin, StaticMemberMixin {
  StaticFieldElementZ(ObjectDecoder decoder)
      : super(decoder);
}

class InstanceFieldElementZ extends FieldElementZ
    with ClassMemberMixin, InstanceMemberMixin {
  InstanceFieldElementZ(ObjectDecoder decoder)
      : super(decoder);
}

abstract class FunctionElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         ParametersMixin,
         FunctionTypedElementMixin,
         TypedElementMixin,
         MemberElementMixin
    implements MethodElement {
  FunctionElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitFunctionElement(this, arg);
  }

  @override
  bool get isOperator => _decoder.getBool(Key.IS_OPERATOR);
}

class TopLevelFunctionElementZ extends FunctionElementZ
    with LibraryMemberMixin {
  TopLevelFunctionElementZ(ObjectDecoder decoder)
      : super(decoder);
}

class StaticFunctionElementZ extends FunctionElementZ
    with ClassMemberMixin, StaticMemberMixin {
  StaticFunctionElementZ(ObjectDecoder decoder)
      : super(decoder);
}

class InstanceFunctionElementZ extends FunctionElementZ
    with ClassMemberMixin, InstanceMemberMixin {
  InstanceFunctionElementZ(ObjectDecoder decoder)
      : super(decoder);
}

abstract class GetterElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         FunctionTypedElementMixin,
         ParametersMixin,
         TypedElementMixin,
         MemberElementMixin
    implements FunctionElement {

  GetterElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  ElementKind get kind => ElementKind.GETTER;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitFunctionElement(this, arg);
  }
}

class TopLevelGetterElementZ extends GetterElementZ with LibraryMemberMixin {
  TopLevelGetterElementZ(ObjectDecoder decoder)
      : super(decoder);
}

class StaticGetterElementZ extends GetterElementZ
    with ClassMemberMixin, StaticMemberMixin {
  StaticGetterElementZ(ObjectDecoder decoder)
      : super(decoder);
}

class InstanceGetterElementZ extends GetterElementZ
    with ClassMemberMixin, InstanceMemberMixin {
  InstanceGetterElementZ(ObjectDecoder decoder)
      : super(decoder);
}

abstract class SetterElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         FunctionTypedElementMixin,
         ParametersMixin,
         TypedElementMixin,
         MemberElementMixin
    implements FunctionElement {

  SetterElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  ElementKind get kind => ElementKind.SETTER;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitFunctionElement(this, arg);
  }
}

class TopLevelSetterElementZ extends SetterElementZ with LibraryMemberMixin {
  TopLevelSetterElementZ(ObjectDecoder decoder)
      : super(decoder);
}

class StaticSetterElementZ extends SetterElementZ
    with ClassMemberMixin, StaticMemberMixin {
  StaticSetterElementZ(ObjectDecoder decoder)
      : super(decoder);
}

class InstanceSetterElementZ extends SetterElementZ
    with ClassMemberMixin, InstanceMemberMixin {
  InstanceSetterElementZ(ObjectDecoder decoder)
      : super(decoder);
}

abstract class TypeDeclarationMixin<T extends GenericType>
    implements DeserializedElementZ, TypeDeclarationElement {
  List<DartType> _typeVariables;
  T _rawType;
  T _thisType;
  Name _memberName;

  Name get memberName {
    if (_memberName == null) {
      _memberName = new Name(name, library);
    }
    return _memberName;
  }

  void _ensureTypes() {
    if (_typeVariables == null) {
      _typeVariables = _decoder.getTypes(
          Key.TYPE_VARIABLES, isOptional: true);
      _rawType = _createType(new List<DartType>.filled(
          _typeVariables.length, const DynamicType()));
      _thisType = _createType(_typeVariables);
    }
  }

  T _createType(List<DartType> typeArguments);

  @override
  List<DartType> get typeVariables {
    _ensureTypes();
    return _typeVariables;
  }

  @override
  T get rawType {
    _ensureTypes();
    return _rawType;
  }

  @override
  T get thisType {
    _ensureTypes();
    return _thisType;
  }

  @override
  T computeType(Compiler compiler) => thisType;

  @override
  bool get isResolved => true;

  @override
  void ensureResolved(Compiler compiler) {}
}

class TypedefElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         LibraryMemberMixin,
         ParametersMixin,
         TypeDeclarationMixin<TypedefType>
    implements TypedefElement {
  DartType _alias;

  TypedefElementZ(ObjectDecoder decoder)
      : super(decoder);

  TypedefType _createType(List<DartType> typeArguments) {
    return new TypedefType(this, typeArguments);
  }

  @override
  ElementKind get kind => ElementKind.TYPEDEF;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitTypedefElement(this, arg);
  }

  @override
  DartType get alias {
    if (_alias == null) {
      _alias = _decoder.getType(Key.ALIAS);
    }
    return _alias;
  }

  @override
  void checkCyclicReference(Compiler compiler) {}
}

class TypeVariableElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         TypedElementMixin
    implements TypeVariableElement {
  TypeDeclarationElement _typeDeclaration;
  TypeVariableType _type;
  DartType _bound;
  Name _memberName;

  TypeVariableElementZ(ObjectDecoder decoder)
      : super(decoder);

  Name get memberName {
    if (_memberName == null) {
      _memberName = new Name(name, library);
    }
    return _memberName;
  }

  @override
  ElementKind get kind => ElementKind.TYPE_VARIABLE;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitTypeVariableElement(this, arg);
  }

  @override
  CompilationUnitElement get compilationUnit {
    return typeDeclaration.compilationUnit;
  }

  @override
  Element get enclosingElement => typeDeclaration;

  @override
  Element get enclosingClass => typeDeclaration;

  @override
  int get index => _decoder.getInt(Key.INDEX);

  @override
  TypeDeclarationElement get typeDeclaration {
    if (_typeDeclaration == null) {
      _typeDeclaration =
          _decoder.getElement(Key.TYPE_DECLARATION);
    }
    return _typeDeclaration;
  }

  DartType get bound {
    if (_bound == null) {
      _bound = _decoder.getType(Key.BOUND);
    }
    return _bound;
  }

  @override
  LibraryElement get library => typeDeclaration.library;
}

class ParameterElementZ extends DeserializedElementZ
    with AnalyzableElementMixin,
         AstElementMixin,
         TypedElementMixin
    implements ParameterElement {
  FunctionElement _functionDeclaration;
  ConstantExpression _constant;
  DartType _type;

  ParameterElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitParameterElement(this, arg);
  }

  @override
  ConstantExpression get constant {
    if (isOptional) {
      if (_constant == null) {
        _constant = _decoder.getConstant(Key.CONSTANT);
      }
      return _constant;
    }
    return null;
  }

  @override
  CompilationUnitElement get compilationUnit {
    return functionDeclaration.compilationUnit;
  }

  @override
  ExecutableElement get executableContext => functionDeclaration;

  @override
  Element get enclosingElement => functionDeclaration;

  @override
  FunctionElement get functionDeclaration {
    if (_functionDeclaration == null) {
      _functionDeclaration = _decoder.getElement(Key.FUNCTION);
    }
    return _functionDeclaration;
  }

  @override
  FunctionSignature get functionSignature => _unsupported('functionSignature');

  @override
  Expression get initializer => _unsupported('initializer');

  @override
  bool get isNamed => _decoder.getBool(Key.IS_NAMED);

  @override
  bool get isOptional => _decoder.getBool(Key.IS_OPTIONAL);

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  LibraryElement get library => executableContext.library;

  @override
  MemberElement get memberContext => executableContext.memberContext;
}


class InitializingFormalElementZ extends ParameterElementZ
    implements InitializingFormalElement {
  FieldElement _fieldElement;

  InitializingFormalElementZ(ObjectDecoder decoder)
      : super(decoder);

  @override
  FieldElement get fieldElement {
    if (_fieldElement == null) {
      _fieldElement = _decoder.getElement(Key.FIELD);
    }
    return _fieldElement;
  }

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitFieldParameterElement(this, arg);
  }

  @override
  ElementKind get kind => ElementKind.INITIALIZING_FORMAL;

}