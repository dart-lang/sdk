// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the element model used for deserialiation.
///
/// These classes are created by [ElementDeserializer] triggered by the
/// [Deserializer].

library dart2js.serialization.modelz;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../elements/resolution_types.dart';
import '../elements/common.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/modelx.dart' show FunctionSignatureX;
import '../elements/names.dart';
import '../elements/visitor.dart';
import '../io/source_file.dart';
import '../ordered_typeset.dart';
import '../resolution/class_members.dart' as class_members;
import '../resolution/scope.dart' show Scope;
import '../resolution/tree_elements.dart' show TreeElements;
import '../script.dart';
import '../serialization/constant_serialization.dart';
import 'package:front_end/src/fasta/scanner.dart' show Token;
import '../tree/tree.dart';
import '../util/util.dart' show Link, LinkBuilder;
import 'keys.dart';
import 'serialization.dart';

/// Compute a [Link] from an [Iterable].
Link toLink(Iterable iterable) {
  LinkBuilder builder = new LinkBuilder();
  for (var element in iterable) {
    builder.addLast(element);
  }
  return builder.toLink();
}

abstract class ElementZ extends Element with ElementCommon {
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
  Scope buildScope() => _unsupported('buildScope');

  @override
  ClassElement get enclosingClass => null;

  @override
  LibraryElement get implementationLibrary => library;

  @override
  bool get isAbstract => false;

  @override
  bool get isClassMember => false;

  @override
  bool get isClosure => false;

  @override
  bool get isConst => false;

  @override
  bool get isDeferredLoaderGetter => false;

  @override
  bool get isFinal => false;

  @override
  bool get isInstanceMember => false;

  @override
  bool get isLocal => false;

  @override
  bool get isMixinApplication => false;

  @override
  bool get isOperator => false;

  @override
  bool get isStatic => false;

  @override
  bool get isSynthesized => false;

  @override
  bool get isTopLevel => false;

  @override
  Iterable<MetadataAnnotation> get metadata => const <MetadataAnnotation>[];

  @override
  Token get position => _unsupported('position');
}

abstract class DeserializedElementZ extends ElementZ {
  ObjectDecoder _decoder;
  List<MetadataAnnotation> _metadata;

  DeserializedElementZ(this._decoder);

  @override
  String get name => _decoder.getString(Key.NAME);

  // TODO(johnniwinther): Should this be cached?
  @override
  int get sourceOffset => _decoder.getInt(Key.OFFSET, isOptional: true);

  @override
  SourceSpan get sourcePosition {
    // TODO(johnniwinther): Should this be cached?
    int offset = sourceOffset;
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

  @override
  Iterable<MetadataAnnotation> get metadata {
    if (_metadata == null) {
      _metadata = <MetadataAnnotation>[];
      ListDecoder list = _decoder.getList(Key.METADATA, isOptional: true);
      if (list != null) {
        for (int index = 0; index < list.length; index++) {
          ObjectDecoder object = list.getObject(index);
          Element element = object.getElement(Key.ELEMENT);
          Uri uri = object.getUri(Key.URI);
          int offset = object.getInt(Key.OFFSET);
          int length = object.getInt(Key.LENGTH);
          ConstantExpression constant = object.getConstant(Key.CONSTANT);
          _metadata.add(new MetadataAnnotationZ(
              element, new SourceSpan(uri, offset, offset + length), constant));
        }
      }
    }
    return _metadata;
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
    SetterElement setterElement;
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
      if (element.isDeferredLoaderGetter) {
        // Store directly.
        // TODO(johnniwinther): Should modelx be normalized to put `loadLibrary`
        // in an [AbstractFieldElement] instead?
        _lookupMap[name] = element;
      } else if (element.isGetter) {
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

abstract class AstElementMixinZ<N extends Node>
    implements AstElement, ElementZ {
  ResolvedAst _resolvedAst;

  // TODO(johnniwinther): This is needed for the token invariant assertion. Find
  // another way to bypass the test for modelz.
  @override
  bool get hasNode => false;

  @override
  bool get hasResolvedAst => _resolvedAst != null;

  @override
  N get node => _unsupported('node');

  @override
  ResolvedAst get resolvedAst {
    assert(_resolvedAst != null,
        failedAt(this, "ResolvedAst has not been set for $this."));
    return _resolvedAst;
  }

  void set resolvedAst(ResolvedAst value) {
    assert(_resolvedAst == null,
        failedAt(this, "ResolvedAst has already been set for $this."));
    _resolvedAst = value;
  }
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
    MapDecoder members = _decoder.getMap(Key.MEMBERS, isOptional: true);
    if (members == null) return;
    members.forEachKey((String key) {
      Element member = members.getElement(key);
      if (member != null) {
        f(member);
      }
    });
  }
}

class AbstractFieldElementZ extends ElementZ
    with AbstractFieldElementCommon
    implements AbstractFieldElement {
  final String name;
  final GetterElementZ getter;
  final SetterElementZ setter;

  factory AbstractFieldElementZ(
      String name, GetterElement getter, SetterElement setter) {
    if (getter?.abstractField != null) {
      return getter.abstractField;
    } else if (setter?.abstractField != null) {
      return setter.abstractField;
    } else {
      return new AbstractFieldElementZ._(name, getter, setter);
    }
  }

  AbstractFieldElementZ._(this.name, this.getter, this.setter) {
    if (getter != null) {
      getter.abstractField = this;
      getter.setter = setter;
    }
    if (setter != null) {
      setter.abstractField = this;
      setter.getter = getter;
    }
  }

  FunctionElement get _canonicalElement => getter != null ? getter : setter;

  @override
  ElementKind get kind => ElementKind.ABSTRACT_FIELD;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitAbstractFieldElement(this, arg);
  }

  @override
  LibraryElement get library => _canonicalElement.library;

  @override
  CompilationUnitElement get compilationUnit {
    return _canonicalElement.compilationUnit;
  }

  @override
  Element get enclosingElement => _canonicalElement.enclosingElement;

  @override
  int get sourceOffset => _canonicalElement.sourceOffset;

  @override
  SourceSpan get sourcePosition => _canonicalElement.sourcePosition;

  @override
  ClassElement get enclosingClass => _canonicalElement.enclosingClass;

  @override
  bool get isClassMember => _canonicalElement.isClassMember;

  @override
  bool get isInstanceMember => _canonicalElement.isInstanceMember;

  @override
  bool get isStatic => _canonicalElement.isStatic;

  @override
  bool get isTopLevel => _canonicalElement.isTopLevel;
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
class LibraryElementZ extends DeserializedElementZ
    with AnalyzableElementMixin, ContainerMixin, LibraryElementCommon
    implements LibraryElement {
  Uri _canonicalUri;
  CompilationUnitElement _entryCompilationUnit;
  Link<CompilationUnitElement> _compilationUnits;
  List<ImportElement> _imports;
  List<ExportElement> _exports;
  ListedContainer _exportsMap;
  ListedContainer _importsMap;
  Map<Element, List<ImportElement>> _importsFor;

  LibraryElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.LIBRARY;

  @override
  Element get enclosingElement => null;

  @override
  SourceSpan get sourcePosition => entryCompilationUnit.sourcePosition;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitLibraryElement(this, arg);
  }

  @override
  LibraryElement get library => this;

  @override
  CompilationUnitElement get compilationUnit => entryCompilationUnit;

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
      _compilationUnits = toLink(_decoder.getElements(Key.COMPILATION_UNITS));
    }
    return _compilationUnits;
  }

  @override
  bool get hasLibraryName {
    return libraryName != '';
  }

  @override
  String get libraryName {
    return _decoder.getString(Key.LIBRARY_NAME);
  }

  @override
  bool get exportsHandled => true;

  void _ensureExports() {
    if (_exportsMap == null) {
      _exportsMap = new ListedContainer(
          _decoder.getElements(Key.EXPORT_SCOPE, isOptional: true));
    }
  }

  @override
  void forEachExport(f(Element element)) {
    _ensureExports();
    _exportsMap.forEach(f);
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

  @override
  Element findExported(String elementName) {
    _ensureExports();
    return _exportsMap.lookup(elementName);
  }

  void _ensureImports() {
    if (_importsMap == null) {
      _importsMap = new ListedContainer(
          _decoder.getElements(Key.IMPORT_SCOPE, isOptional: true));
      _importsFor = <Element, List<ImportElement>>{};

      ListDecoder importsDecoder = _decoder.getList(Key.IMPORTS_FOR);
      for (int index = 0; index < importsDecoder.length; index++) {
        ObjectDecoder objectDecoder = importsDecoder.getObject(index);
        Element key = objectDecoder.getElement(Key.ELEMENT);
        List<ImportElement> imports =
            objectDecoder.getElements(Key.IMPORTS, isOptional: true);

        // Imports are mapped to [AbstractFieldElement] which are not serialized
        // so we use getter (or setter if there is no getter) as the key.
        Element importedElement = key;
        if (key.isDeferredLoaderGetter) {
          // Use as [importedElement].
        } else if (key.isAccessor) {
          AccessorElement accessor = key;
          importedElement = accessor.abstractField;
        }
        _importsFor[importedElement] = imports;
      }
    }
  }

  @override
  void forEachImport(f(Element element)) {
    _ensureImports();
    _importsMap.forEach(f);
  }

  @override
  Iterable<ImportElement> getImportsFor(Element element) {
    _ensureImports();
    return _importsFor[element] ?? const <ImportElement>[];
  }

  String toString() {
    return 'Zlibrary(${canonicalUri})';
  }

  @override
  Iterable<ExportElement> get exports {
    if (_exports == null) {
      _exports = _decoder.getElements(Key.EXPORTS, isOptional: true);
    }
    return _exports;
  }

  @override
  Iterable<ImportElement> get imports {
    if (_imports == null) {
      _imports = _decoder.getElements(Key.IMPORTS, isOptional: true);
    }
    return _imports;
  }
}

class ScriptZ implements Script {
  final Uri resourceUri;
  SourceFile _file;
  bool _isSynthesized = false;

  ScriptZ(this.resourceUri);

  @override
  Script copyWithFile(SourceFile file) {
    throw new UnsupportedError('ScriptZ.copyWithFile');
  }

  @override
  SourceFile get file {
    if (_file == null) {
      throw new UnsupportedError('ScriptZ.file');
    }
    return _file;
  }

  void set file(SourceFile value) {
    _file = value;
  }

  // TODO(johnniwinther): Decide if it is meaningful to serialize erroneous
  // elements.
  @override
  bool get isSynthesized => _isSynthesized;

  void set isSynthesized(bool value) {
    _isSynthesized = value;
  }

  @override
  String get name {
    if (_file != null) {
      return _file.filename;
    }
    return resourceUri.toString();
  }

  // TODO(johnniwinther): Support the distinction between [readableUri] and
  // [resourceUri]; needed for platform libraries.
  @override
  Uri get readableUri => resourceUri;

  @override
  String get text {
    if (_file != null) {
      return _file.slowText();
    }
    throw new UnsupportedError('ScriptZ.text');
  }
}

class CompilationUnitElementZ extends DeserializedElementZ
    with LibraryMemberMixin, CompilationUnitElementCommon
    implements CompilationUnitElement {
  List<Element> _members;
  Script _script;

  CompilationUnitElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  @override
  CompilationUnitElement get compilationUnit => this;

  @override
  Element get enclosingElement => library;

  @override
  SourceSpan get sourcePosition => new SourceSpan(script.resourceUri, 0, 0);

  @override
  bool get isTopLevel => false;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitCompilationUnitElement(this, arg);
  }

  @override
  void forEachLocalMember(f(Element element)) {
    if (_members == null) {
      _members = _decoder.getElements(Key.ELEMENTS, isOptional: true);
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
  CompilationUnitElement _compilationUnit;

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
  CompilationUnitElement get compilationUnit {
    if (_compilationUnit == null) {
      _compilationUnit =
          _decoder.getElement(Key.COMPILATION_UNIT, isOptional: true);
      if (_compilationUnit == null) {
        _compilationUnit = enclosingClass.compilationUnit;
      }
    }
    return _compilationUnit;
  }
}

abstract class InstanceMemberMixin implements DeserializedElementZ {
  @override
  bool get isTopLevel => false;

  @override
  bool get isStatic => false;

  @override
  bool get isInstanceMember => true;

  @override
  bool get isClassMember => true;
}

abstract class StaticMemberMixin implements DeserializedElementZ {
  @override
  bool get isTopLevel => false;

  @override
  bool get isStatic => true;

  @override
  bool get isClassMember => true;
}

abstract class TypedElementMixin<T extends ResolutionDartType>
    implements DeserializedElementZ, TypedElement {
  T _type;

  @override
  T get type {
    if (_type == null) {
      _type = _decoder.getType(Key.TYPE);
    }
    return _type;
  }

  @override
  T computeType(Resolution resolution) => type;
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
      List<ResolutionDartType> parameterTypes = <ResolutionDartType>[];
      List<ResolutionDartType> optionalParameterTypes = <ResolutionDartType>[];
      for (ParameterElement parameter in parameters) {
        if (parameter.isOptional) {
          optionalParameterCount++;
          optionalParameters.add(parameter);
          orderedOptionalParameters.add(parameter);
          if (parameter.isNamed) {
            optionalParametersAreNamed = true;
          } else {
            optionalParameterTypes.add(parameter.type);
          }
        } else {
          requiredParameterCount++;
          requiredParameters.add(parameter);
          parameterTypes.add(parameter.type);
        }
      }
      List<String> namedParameters = const <String>[];
      List<ResolutionDartType> namedParameterTypes =
          const <ResolutionDartType>[];
      if (optionalParametersAreNamed) {
        namedParameters = <String>[];
        namedParameterTypes = <ResolutionDartType>[];
        orderedOptionalParameters.sort((Element a, Element b) {
          return a.name.compareTo(b.name);
        });
        for (ParameterElement parameter in orderedOptionalParameters) {
          namedParameters.add(parameter.name);
          namedParameterTypes.add(parameter.type);
        }
      }
      List<ResolutionDartType> typeVariables =
          _decoder.getTypes(Key.TYPE_VARIABLES, isOptional: true);

      ResolutionFunctionType type = new ResolutionFunctionType(
          this,
          _decoder.getType(Key.RETURN_TYPE),
          parameterTypes,
          optionalParameterTypes,
          namedParameters,
          namedParameterTypes);
      _functionSignature = new FunctionSignatureX(
          typeVariables: typeVariables,
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

  ParameterStructure get parameterStructure =>
      functionSignature.parameterStructure;
}

abstract class FunctionTypedElementMixin
    implements FunctionElement, DeserializedElementZ {
  @override
  FunctionElement asFunctionElement() => this;

  @override
  bool get isExternal {
    return _decoder.getBool(Key.IS_EXTERNAL,
        isOptional: true, defaultValue: false);
  }

  @override
  List<ResolutionDartType> get typeVariables => functionSignature.typeVariables;
}

abstract class ClassElementMixin
    implements ElementZ, ClassElement, class_members.ClassMemberMixin {
  bool _isResolved = false;

  ResolutionInterfaceType _createType(List<ResolutionDartType> typeArguments) {
    return new ResolutionInterfaceType(this, typeArguments);
  }

  @override
  ElementKind get kind => ElementKind.CLASS;

  @override
  bool get hasConstructor => _unsupported('hasConstructor');

  @override
  bool get hasIncompleteHierarchy => _unsupported('hasIncompleteHierarchy');

  @override
  bool get hasLocalScopeMembers => _unsupported('hasLocalScopeMembers');

  @override
  bool get isEnumClass => false;

  @override
  ConstructorElement lookupDefaultConstructor() {
    ConstructorElement constructor = lookupConstructor("");
    if (constructor != null &&
        constructor.functionSignature.requiredParameterCount == 0) {
      return constructor;
    }
    return null;
  }

  @override
  ClassElement get superclass => supertype != null ? supertype.element : null;

  @override
  void ensureResolved(Resolution resolution) {
    if (!_isResolved) {
      _isResolved = true;
      // TODO(johnniwinther): Avoid eager computation of all members. `call` is
      // always needed, but the remaining should be computed on-demand or on
      // type instantiation.
      class_members.MembersCreator.computeAllClassMembers(resolution, this);
      resolution.registerClass(this);
    }
  }
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
class ClassElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ,
        ClassElementCommon,
        class_members.ClassMemberMixin,
        ContainerMixin,
        LibraryMemberMixin,
        TypeDeclarationMixin,
        ClassElementMixin
    implements ClassElement {
  bool _isObject;
  ResolutionInterfaceType _supertype;
  OrderedTypeSet _allSupertypesAndSelf;
  Link<ResolutionDartType> _interfaces;
  ResolutionFunctionType _callType;

  ClassElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  List<ResolutionDartType> _getTypeVariables() {
    return _decoder.getTypes(Key.TYPE_VARIABLES, isOptional: true);
  }

  void _ensureSuperHierarchy() {
    if (_interfaces == null) {
      ResolutionInterfaceType supertype =
          _decoder.getType(Key.SUPERTYPE, isOptional: true);
      if (supertype == null) {
        _isObject = true;
        _allSupertypesAndSelf = new OrderedTypeSet.singleton(thisType);
        _interfaces = const Link<ResolutionDartType>();
      } else {
        _isObject = false;
        _interfaces =
            toLink(_decoder.getTypes(Key.INTERFACES, isOptional: true));
        List<ResolutionInterfaceType> mixins =
            _decoder.getTypes(Key.MIXINS, isOptional: true);
        for (ResolutionInterfaceType mixin in mixins) {
          MixinApplicationElement mixinElement =
              new UnnamedMixinApplicationElementZ(this, supertype, mixin);
          supertype = mixinElement.thisType
              .subst(typeVariables, mixinElement.typeVariables);
        }
        _supertype = supertype;
        _allSupertypesAndSelf = new ResolutionOrderedTypeSetBuilder(this)
            .createOrderedTypeSet(_supertype, _interfaces);
        _callType = _decoder.getType(Key.CALL_TYPE, isOptional: true);
      }
    }
  }

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitClassElement(this, arg);
  }

  @override
  ResolutionDartType get supertype {
    _ensureSuperHierarchy();
    return _supertype;
  }

  @override
  bool get isAbstract => _decoder.getBool(Key.IS_ABSTRACT);

  @override
  bool get isObject {
    _ensureSuperHierarchy();
    return _isObject;
  }

  @override
  OrderedTypeSet get allSupertypesAndSelf {
    _ensureSuperHierarchy();
    return _allSupertypesAndSelf;
  }

  @override
  Link<ResolutionDartType> get interfaces {
    _ensureSuperHierarchy();
    return _interfaces;
  }

  @override
  bool get isProxy => _decoder.getBool(Key.IS_PROXY);

  @override
  bool get isInjected => _decoder.getBool(Key.IS_INJECTED);

  @override
  bool get isUnnamedMixinApplication => false;

  @override
  ResolutionFunctionType get callType {
    _ensureSuperHierarchy();
    // TODO(johnniwinther): Why can't this always be computed in ensureResolved?
    return _callType;
  }

  ResolutionInterfaceType get thisType => super.thisType;

  ResolutionInterfaceType get rawType => super.rawType;
}

abstract class MixinApplicationElementMixin
    implements ElementZ, MixinApplicationElement {
  @override
  bool get isMixinApplication => true;

  @override
  ClassElement get mixin => mixinType.element;
}

class NamedMixinApplicationElementZ extends ClassElementZ
    with MixinApplicationElementMixin {
  Link<Element> _constructors;
  ResolutionInterfaceType _mixinType;

  NamedMixinApplicationElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ResolutionInterfaceType get mixinType =>
      _mixinType ??= _decoder.getType(Key.MIXIN);

  @override
  ClassElement get subclass => null;
}

class UnnamedMixinApplicationElementZ extends ElementZ
    with
        ClassElementCommon,
        ClassElementMixin,
        class_members.ClassMemberMixin,
        // ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_MIXIN
        TypeDeclarationMixin,
        AnalyzableElementMixin,
        AstElementMixinZ,
        MixinApplicationElementCommon,
        MixinApplicationElementMixin {
  final String name;
  final ClassElement subclass;
  final ResolutionInterfaceType _supertypeBase;
  final ResolutionInterfaceType _mixinBase;
  ResolutionInterfaceType _supertype;
  Link<ResolutionDartType> _interfaces;
  OrderedTypeSet _allSupertypesAndSelf;
  Link<ConstructorElement> _constructors;

  UnnamedMixinApplicationElementZ(this.subclass,
      ResolutionInterfaceType supertype, ResolutionInterfaceType mixin)
      : this._supertypeBase = supertype,
        this._mixinBase = mixin,
        this.name = "${supertype.name}+${mixin.name}";

  @override
  CompilationUnitElement get compilationUnit => subclass.compilationUnit;

  @override
  bool get isTopLevel => true;

  @override
  bool get isAbstract => true;

  @override
  bool get isUnnamedMixinApplication => true;

  Link<ConstructorElement> get constructors {
    if (_constructors == null) {
      LinkBuilder<ConstructorElement> builder =
          new LinkBuilder<ConstructorElement>();
      for (ConstructorElement definingConstructor in superclass.constructors) {
        if (definingConstructor.isGenerativeConstructor &&
            definingConstructor.memberName.isAccessibleFrom(library)) {
          ForwardingConstructorElementZ constructor =
              new ForwardingConstructorElementZ(this, definingConstructor);
          constructor.resolvedAst = new SynthesizedResolvedAst(
              constructor, ResolvedAstKind.FORWARDING_CONSTRUCTOR);
          builder.addLast(constructor);
        }
      }
      _constructors = builder.toLink();
    }
    return _constructors;
  }

  @override
  List<ResolutionDartType> _getTypeVariables() {
    // Create synthetic type variables for the mixin application.
    List<ResolutionDartType> typeVariables = <ResolutionDartType>[];
    int index = 0;
    for (ResolutionTypeVariableType type in subclass.typeVariables) {
      SyntheticTypeVariableElementZ typeVariableElement =
          new SyntheticTypeVariableElementZ(this, index, type.name);
      ResolutionTypeVariableType typeVariable =
          new ResolutionTypeVariableType(typeVariableElement);
      typeVariables.add(typeVariable);
      index++;
    }
    // Setup bounds on the synthetic type variables.
    for (ResolutionTypeVariableType type in subclass.typeVariables) {
      ResolutionTypeVariableType typeVariable =
          typeVariables[type.element.index];
      SyntheticTypeVariableElementZ typeVariableElement = typeVariable.element;
      typeVariableElement._type = typeVariable;
      typeVariableElement._bound =
          type.element.bound.subst(typeVariables, subclass.typeVariables);
    }
    return typeVariables;
  }

  @override
  ResolutionInterfaceType get supertype {
    if (_supertype == null) {
      // Substitute the type variables in [_supertypeBase] provided by
      // [_subclass] with the type variables in this unnamed mixin application.
      //
      // For instance
      //    class S<S.T> {}
      //    class M<M.T> {}
      //    class C<C.T> extends S<C.T> with M<C.T> {}
      // the unnamed mixin application should be
      //    abstract class S+M<S+M.T> extends S<S+M.T> implements M<S+M.T> {}
      // but the supertype is provided as S<C.T> and we need to substitute S+M.T
      // for C.T.
      _supertype = _supertypeBase.subst(typeVariables, subclass.typeVariables);
    }
    return _supertype;
  }

  @override
  Link<ResolutionDartType> get interfaces {
    if (_interfaces == null) {
      // Substitute the type variables in [_mixinBase] provided by
      // [_subclass] with the type variables in this unnamed mixin application.
      //
      // For instance
      //    class S<S.T> {}
      //    class M<M.T> {}
      //    class C<C.T> extends S<C.T> with M<C.T> {}
      // the unnamed mixin application should be
      //    abstract class S+M<S+M.T> extends S<S+M.T> implements M<S+M.T> {}
      // but the mixin is provided as M<C.T> and we need to substitute S+M.T
      // for C.T.
      _interfaces = const Link<ResolutionDartType>()
          .prepend(_mixinBase.subst(typeVariables, subclass.typeVariables));
    }
    return _interfaces;
  }

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitMixinApplicationElement(this, arg);
  }

  @override
  OrderedTypeSet get allSupertypesAndSelf {
    if (_allSupertypesAndSelf == null) {
      _allSupertypesAndSelf = new ResolutionOrderedTypeSetBuilder(this)
          .createOrderedTypeSet(supertype, interfaces);
    }
    return _allSupertypesAndSelf;
  }

  @override
  Element get enclosingElement => subclass.enclosingElement;

  @override
  bool get isObject => false;

  @override
  bool get isProxy => false;

  @override
  LibraryElement get library => enclosingElement.library;

  @override
  ResolutionInterfaceType get mixinType => interfaces.head;

  @override
  int get sourceOffset => subclass.sourceOffset;

  @override
  SourceSpan get sourcePosition => subclass.sourcePosition;
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
class EnumClassElementZ extends ClassElementZ implements EnumClassElement {
  List<FieldElement> _enumValues;

  EnumClassElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  bool get isEnumClass => true;

  @override
  List<EnumConstantElement> get enumValues {
    if (_enumValues == null) {
      _enumValues = _decoder.getElements(Key.FIELDS);
    }
    return _enumValues;
  }
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
abstract class ConstructorElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<FunctionExpression>,
        ClassMemberMixin,
        FunctionTypedElementMixin,
        ParametersMixin,
        TypedElementMixin<ResolutionFunctionType>,
        MemberElementMixin,
        ConstructorElementCommon
    implements
        ConstructorElement,
        // TODO(johnniwinther): Sort out whether a constructor is a method.
        MethodElement {
  ConstantConstructor _constantConstructor;
  ConstructorElement _effectiveTarget;

  ConstructorElementZ(ObjectDecoder decoder) : super(decoder);

  accept(ElementVisitor visitor, arg) {
    return visitor.visitConstructorElement(this, arg);
  }

  @override
  bool get isConst => _decoder.getBool(Key.IS_CONST);

  @override
  bool get isExternal => _decoder.getBool(Key.IS_EXTERNAL);

  @override
  bool get isDefaultConstructor => false;

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
  AsyncMarker get asyncMarker => AsyncMarker.SYNC;

  @override
  ConstructorElement get definingConstructor => null;

  @override
  bool get hasEffectiveTarget => true;

  @override
  ConstructorElement get effectiveTarget {
    if (_effectiveTarget == null) {
      _effectiveTarget =
          _decoder.getElement(Key.EFFECTIVE_TARGET, isOptional: true);
      if (_effectiveTarget == null) {
        _effectiveTarget = this;
      }
    }
    return _effectiveTarget;
  }

  @override
  ConstructorElement get immediateRedirectionTarget => null;

  // TODO(johnniwinther): Should serialization support erroneous element
  // relations?
  @override
  bool get isEffectiveTargetMalformed => false;

  @override
  bool get isCyclicRedirection => false;

  @override
  bool get isRedirectingFactory => false;

  @override
  bool get isRedirectingGenerative => false;

  @override
  PrefixElement get redirectionDeferredPrefix => null;

  @override
  ResolutionDartType computeEffectiveTargetType(
          ResolutionInterfaceType newType) =>
      newType;
}

class GenerativeConstructorElementZ extends ConstructorElementZ {
  GenerativeConstructorElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.GENERATIVE_CONSTRUCTOR;

  @override
  bool get isRedirectingGenerative => _decoder.getBool(Key.IS_REDIRECTING);
}

class DefaultConstructorElementZ extends ConstructorElementZ {
  DefaultConstructorElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.GENERATIVE_CONSTRUCTOR;

  @override
  bool get isSynthesized => true;

  @override
  bool get isDefaultConstructor => true;

  @override
  ConstructorElement get definingConstructor {
    return enclosingClass.superclass.lookupConstructor('');
  }
}

class FactoryConstructorElementZ extends ConstructorElementZ {
  FactoryConstructorElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.FACTORY_CONSTRUCTOR;
}

class RedirectingFactoryConstructorElementZ extends ConstructorElementZ {
  ResolutionDartType _effectiveTargetType;
  ConstructorElement _immediateRedirectionTarget;
  PrefixElement _redirectionDeferredPrefix;
  bool _effectiveTargetIsMalformed;

  RedirectingFactoryConstructorElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.FACTORY_CONSTRUCTOR;

  @override
  bool get isRedirectingFactory => true;

  void _ensureEffectiveTarget() {
    if (_effectiveTarget == null) {
      _effectiveTarget =
          _decoder.getElement(Key.EFFECTIVE_TARGET, isOptional: true);
      if (_effectiveTarget == null) {
        _effectiveTarget = this;
        _effectiveTargetType = enclosingClass.thisType;
        _effectiveTargetIsMalformed = false;
      } else {
        _effectiveTargetType = _decoder.getType(Key.EFFECTIVE_TARGET_TYPE);
        _effectiveTargetIsMalformed =
            _decoder.getBool(Key.EFFECTIVE_TARGET_IS_MALFORMED);
      }
    }
  }

  bool get isEffectiveTargetMalformed {
    _ensureEffectiveTarget();
    return _effectiveTargetIsMalformed;
  }

  @override
  ConstructorElement get effectiveTarget {
    _ensureEffectiveTarget();
    return _effectiveTarget;
  }

  @override
  ResolutionDartType computeEffectiveTargetType(
      ResolutionInterfaceType newType) {
    _ensureEffectiveTarget();
    return _effectiveTargetType.substByContext(newType);
  }

  void _ensureRedirection() {
    if (_immediateRedirectionTarget == null) {
      _immediateRedirectionTarget =
          _decoder.getElement(Key.IMMEDIATE_REDIRECTION_TARGET);
      _redirectionDeferredPrefix =
          _decoder.getElement(Key.PREFIX, isOptional: true);
    }
  }

  @override
  ConstructorElement get immediateRedirectionTarget {
    _ensureRedirection();
    return _immediateRedirectionTarget;
  }

  @override
  PrefixElement get redirectionDeferredPrefix {
    _ensureRedirection();
    return _redirectionDeferredPrefix;
  }
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
class ForwardingConstructorElementZ extends ElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<FunctionExpression>
    implements
        ConstructorElement,
        // TODO(johnniwinther): Sort out whether a constructor is a method.
        MethodElement {
  final MixinApplicationElement enclosingClass;
  final ConstructorElement definingConstructor;

  ForwardingConstructorElementZ(this.enclosingClass, this.definingConstructor);

  @override
  CompilationUnitElement get compilationUnit => enclosingClass.compilationUnit;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitConstructorElement(this, arg);
  }

  @override
  AsyncMarker get asyncMarker => AsyncMarker.SYNC;

  @override
  ResolutionDartType computeEffectiveTargetType(
      ResolutionInterfaceType newType) {
    return enclosingClass.thisType.substByContext(newType);
  }

  @override
  ResolutionDartType computeType(Resolution resolution) => type;

  @override
  bool get isConst => false;

  @override
  bool get isClassMember => true;

  @override
  bool get isDefaultConstructor => false;

  @override
  ConstantConstructor get constantConstructor => null;

  @override
  bool get hasEffectiveTarget => true;

  @override
  ConstructorElement get effectiveTarget => this;

  @override
  Element get enclosingElement => enclosingClass;

  @override
  FunctionSignature get functionSignature {
    // TODO(johnniwinther): Ensure that the function signature (and with it the
    // function type) substitutes type variables correctly.
    return definingConstructor.functionSignature;
  }

  @override
  ParameterStructure get parameterStructure {
    return functionSignature.parameterStructure;
  }

  @override
  bool get hasFunctionSignature {
    return _unsupported('hasFunctionSignature');
  }

  @override
  ConstructorElement get immediateRedirectionTarget => null;

  @override
  bool get isCyclicRedirection => false;

  @override
  bool get isEffectiveTargetMalformed => false;

  @override
  bool get isExternal => false;

  @override
  bool get isFromEnvironmentConstructor => false;

  @override
  bool get isIntFromEnvironmentConstructor => false;

  @override
  bool get isBoolFromEnvironmentConstructor => false;

  @override
  bool get isStringFromEnvironmentConstructor => false;

  @override
  bool get isRedirectingFactory => false;

  @override
  bool get isRedirectingGenerative => false;

  @override
  bool get isSynthesized => true;

  @override
  ElementKind get kind => ElementKind.GENERATIVE_CONSTRUCTOR;

  @override
  LibraryElement get library => enclosingClass.library;

  @override
  MemberElement get memberContext => this;

  @override
  Name get memberName => definingConstructor.memberName;

  @override
  String get name => definingConstructor.name;

  @override
  List<FunctionElement> get nestedClosures => const <FunctionElement>[];

  @override
  List<ParameterElement> get parameters {
    // TODO(johnniwinther): We need to create synthetic parameters that
    // substitute type variables.
    return definingConstructor.parameters;
  }

  // TODO: implement redirectionDeferredPrefix
  @override
  PrefixElement get redirectionDeferredPrefix => null;

  @override
  int get sourceOffset => enclosingClass.sourceOffset;

  @override
  SourceSpan get sourcePosition => enclosingClass.sourcePosition;

  @override
  ResolutionFunctionType get type {
    // TODO(johnniwinther): Ensure that the function type substitutes type
    // variables correctly.
    return definingConstructor.type;
  }

  @override
  List<ResolutionDartType> get typeVariables => _unsupported("typeVariables");
}

abstract class MemberElementMixin
    implements DeserializedElementZ, MemberElement {
  final List<FunctionElement> nestedClosures = <FunctionElement>[];

  @override
  MemberElement get memberContext => this;

  @override
  Name get memberName => new Name(name, library);

  @override
  bool get isInjected => _decoder.getBool(Key.IS_INJECTED);
}

abstract class FieldElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<VariableDefinitions>,
        TypedElementMixin,
        MemberElementMixin
    implements FieldElement {
  bool _isConst;
  ConstantExpression _constant;

  FieldElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.FIELD;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitFieldElement(this, arg);
  }

  @override
  bool get isFinal => _decoder.getBool(Key.IS_FINAL);

  void _ensureConstant() {
    if (_isConst == null) {
      _isConst = _decoder.getBool(Key.IS_CONST);
      _constant = _decoder.getConstant(Key.CONSTANT, isOptional: true);
    }
  }

  @override
  bool get isConst {
    _ensureConstant();
    return _isConst;
  }

  @override
  bool get hasConstant => true;

  @override
  ConstantExpression get constant {
    _ensureConstant();
    return _constant;
  }

  @override
  Expression get initializer => _unsupported('initializer');
}

class TopLevelFieldElementZ extends FieldElementZ with LibraryMemberMixin {
  TopLevelFieldElementZ(ObjectDecoder decoder) : super(decoder);
}

class StaticFieldElementZ extends FieldElementZ
    with ClassMemberMixin, StaticMemberMixin {
  StaticFieldElementZ(ObjectDecoder decoder) : super(decoder);
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
class EnumConstantElementZ extends StaticFieldElementZ
    implements EnumConstantElement {
  EnumConstantElementZ(ObjectDecoder decoder) : super(decoder);

  int get index => _decoder.getInt(Key.INDEX);
}

class InstanceFieldElementZ extends FieldElementZ
    with ClassMemberMixin, InstanceMemberMixin {
  InstanceFieldElementZ(ObjectDecoder decoder) : super(decoder);
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
abstract class FunctionElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<FunctionExpression>,
        ParametersMixin,
        FunctionTypedElementMixin,
        TypedElementMixin<ResolutionFunctionType>,
        MemberElementMixin
    implements MethodElement {
  FunctionElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitMethodElement(this, arg);
  }

  @override
  AsyncMarker get asyncMarker {
    return _decoder.getEnum(Key.ASYNC_MARKER, AsyncMarker.values);
  }

  @override
  bool get isAbstract => _decoder.getBool(Key.IS_ABSTRACT);

  @override
  bool get isOperator => _decoder.getBool(Key.IS_OPERATOR);
}

class TopLevelFunctionElementZ extends FunctionElementZ
    with LibraryMemberMixin {
  TopLevelFunctionElementZ(ObjectDecoder decoder) : super(decoder);
}

class StaticFunctionElementZ extends FunctionElementZ
    with ClassMemberMixin, StaticMemberMixin {
  StaticFunctionElementZ(ObjectDecoder decoder) : super(decoder);
}

class InstanceFunctionElementZ extends FunctionElementZ
    with ClassMemberMixin, InstanceMemberMixin {
  InstanceFunctionElementZ(ObjectDecoder decoder) : super(decoder);
}

abstract class LocalExecutableMixin
    implements DeserializedElementZ, ExecutableElement, LocalElement {
  ExecutableElement _executableContext;

  @override
  Element get enclosingElement => executableContext;

  @override
  ClassElementZ get enclosingClass => memberContext.enclosingClass;

  @override
  ExecutableElement get executableContext {
    if (_executableContext == null) {
      _executableContext = _decoder.getElement(Key.EXECUTABLE_CONTEXT);
    }
    return _executableContext;
  }

  @override
  MemberElement get memberContext => executableContext.memberContext;

  @override
  bool get isLocal => true;

  @override
  LibraryElement get library => memberContext.library;

  @override
  CompilationUnitElement get compilationUnit {
    return memberContext.compilationUnit;
  }

  @override
  bool get hasTreeElements => memberContext.hasTreeElements;

  @override
  TreeElements get treeElements => memberContext.treeElements;
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
class LocalFunctionElementZ extends DeserializedElementZ
    with
        LocalExecutableMixin,
        AstElementMixinZ<FunctionExpression>,
        ParametersMixin,
        FunctionTypedElementMixin,
        TypedElementMixin<ResolutionFunctionType>
    implements LocalFunctionElement {
  LocalFunctionElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitLocalFunctionElement(this, arg);
  }

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  AsyncMarker get asyncMarker {
    return _decoder.getEnum(Key.ASYNC_MARKER, AsyncMarker.values);
  }
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
abstract class GetterElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<FunctionExpression>,
        FunctionTypedElementMixin,
        ParametersMixin,
        TypedElementMixin<ResolutionFunctionType>,
        MemberElementMixin
    implements GetterElement {
  AbstractFieldElement abstractField;
  SetterElement setter;

  GetterElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.GETTER;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitGetterElement(this, arg);
  }

  @override
  bool get isAbstract => _decoder.getBool(Key.IS_ABSTRACT);

  @override
  AsyncMarker get asyncMarker {
    return _decoder.getEnum(Key.ASYNC_MARKER, AsyncMarker.values);
  }
}

class TopLevelGetterElementZ extends GetterElementZ with LibraryMemberMixin {
  TopLevelGetterElementZ(ObjectDecoder decoder) : super(decoder);
}

class StaticGetterElementZ extends GetterElementZ
    with ClassMemberMixin, StaticMemberMixin {
  StaticGetterElementZ(ObjectDecoder decoder) : super(decoder);
}

class InstanceGetterElementZ extends GetterElementZ
    with ClassMemberMixin, InstanceMemberMixin {
  InstanceGetterElementZ(ObjectDecoder decoder) : super(decoder);
}

// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
abstract class SetterElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<FunctionExpression>,
        FunctionTypedElementMixin,
        ParametersMixin,
        TypedElementMixin<ResolutionFunctionType>,
        MemberElementMixin
    implements SetterElement {
  AbstractFieldElement abstractField;
  GetterElement getter;

  SetterElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  ElementKind get kind => ElementKind.SETTER;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitSetterElement(this, arg);
  }

  @override
  bool get isAbstract => _decoder.getBool(Key.IS_ABSTRACT);

  @override
  AsyncMarker get asyncMarker => AsyncMarker.SYNC;
}

class TopLevelSetterElementZ extends SetterElementZ with LibraryMemberMixin {
  TopLevelSetterElementZ(ObjectDecoder decoder) : super(decoder);
}

class StaticSetterElementZ extends SetterElementZ
    with ClassMemberMixin, StaticMemberMixin {
  StaticSetterElementZ(ObjectDecoder decoder) : super(decoder);
}

class InstanceSetterElementZ extends SetterElementZ
    with ClassMemberMixin, InstanceMemberMixin {
  InstanceSetterElementZ(ObjectDecoder decoder) : super(decoder);
}

abstract class TypeDeclarationMixin
    implements ElementZ, TypeDeclarationElement {
  List<ResolutionDartType> _typeVariables;
  GenericType _rawType;
  GenericType _thisType;
  Name _memberName;

  Name get memberName {
    if (_memberName == null) {
      _memberName = new Name(name, library);
    }
    return _memberName;
  }

  List<ResolutionDartType> _getTypeVariables();

  void _ensureTypes() {
    if (_typeVariables == null) {
      _typeVariables = _getTypeVariables();
      _rawType = _createType(new List<ResolutionDartType>.filled(
          _typeVariables.length, const ResolutionDynamicType()));
      _thisType = _createType(_typeVariables);
    }
  }

  GenericType _createType(List<ResolutionDartType> typeArguments);

  @override
  List<ResolutionDartType> get typeVariables {
    _ensureTypes();
    return _typeVariables;
  }

  @override
  GenericType get rawType {
    _ensureTypes();
    return _rawType;
  }

  @override
  GenericType get thisType {
    _ensureTypes();
    return _thisType;
  }

  @override
  GenericType computeType(Resolution resolution) => thisType;

  @override
  bool get isResolved => true;
}

class TypedefElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<Node>,
        LibraryMemberMixin,
        ParametersMixin,
        TypeDeclarationMixin
    implements TypedefElement {
  ResolutionDartType _alias;

  TypedefElementZ(ObjectDecoder decoder) : super(decoder);

  ResolutionTypedefType _createType(List<ResolutionDartType> typeArguments) {
    return new ResolutionTypedefType(this, typeArguments);
  }

  @override
  List<ResolutionDartType> _getTypeVariables() {
    return _decoder.getTypes(Key.TYPE_VARIABLES, isOptional: true);
  }

  @override
  ElementKind get kind => ElementKind.TYPEDEF;

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitTypedefElement(this, arg);
  }

  @override
  ResolutionDartType get alias {
    if (_alias == null) {
      _alias = _decoder.getType(Key.ALIAS);
    }
    return _alias;
  }

  @override
  void ensureResolved(Resolution resolution) {}

  @override
  void checkCyclicReference(Resolution resolution) {}

  ResolutionTypedefType get thisType => super.thisType;

  ResolutionTypedefType get rawType => super.rawType;
}

class TypeVariableElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<Node>,
        TypedElementMixin<ResolutionTypeVariableType>
    implements TypeVariableElement {
  GenericElement _typeDeclaration;
  ResolutionTypeVariableType _type;
  ResolutionDartType _bound;
  Name _memberName;

  TypeVariableElementZ(ObjectDecoder decoder) : super(decoder);

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
  ClassElementZ get enclosingClass => typeDeclaration;

  @override
  int get index => _decoder.getInt(Key.INDEX);

  @override
  GenericElement get typeDeclaration {
    if (_typeDeclaration == null) {
      _typeDeclaration = _decoder.getElement(Key.TYPE_DECLARATION);
    }
    return _typeDeclaration;
  }

  ResolutionDartType get bound {
    if (_bound == null) {
      _bound = _decoder.getType(Key.BOUND);
    }
    return _bound;
  }

  @override
  LibraryElement get library => typeDeclaration.library;
}

class SyntheticTypeVariableElementZ extends ElementZ
    with AnalyzableElementMixin, AstElementMixinZ<Node>
    implements TypeVariableElement {
  final TypeDeclarationElement typeDeclaration;
  final int index;
  final String name;
  ResolutionTypeVariableType _type;
  ResolutionDartType _bound;
  Name _memberName;

  SyntheticTypeVariableElementZ(this.typeDeclaration, this.index, this.name);

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
  ResolutionTypeVariableType get type {
    assert(_type != null,
        failedAt(this, "Type variable type has not been set on $this."));
    return _type;
  }

  @override
  ResolutionTypeVariableType computeType(Resolution resolution) => type;

  @override
  Element get enclosingElement => typeDeclaration;

  @override
  ClassElementZ get enclosingClass => typeDeclaration;

  ResolutionDartType get bound {
    assert(_bound != null,
        failedAt(this, "Type variable bound has not been set on $this."));
    return _bound;
  }

  @override
  LibraryElement get library => typeDeclaration.library;

  @override
  int get sourceOffset => typeDeclaration.sourceOffset;

  @override
  SourceSpan get sourcePosition => typeDeclaration.sourcePosition;
}

abstract class ParameterElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<VariableDefinitions>,
        TypedElementMixin
    implements ParameterElement {
  FunctionElement _functionDeclaration;
  ConstantExpression _constant;
  ResolutionDartType _type;

  ParameterElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  bool get isFinal => _decoder.getBool(Key.IS_FINAL);

  @override
  bool get isConst => false;

  @override
  bool get hasConstant => true;

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

  // TODO(johnniwinther): Remove [initializer] and [node] on
  // [ParameterElementZ] when the inference does need these.
  @override
  Expression initializer;

  @override
  VariableDefinitions node;

  @override
  bool get isNamed => _decoder.getBool(Key.IS_NAMED);

  @override
  bool get isOptional => _decoder.getBool(Key.IS_OPTIONAL);

  @override
  LibraryElement get library => executableContext.library;

  @override
  MemberElement get memberContext => executableContext.memberContext;

  @override
  List<ResolutionDartType> get typeVariables => functionSignature.typeVariables;
}

class LocalParameterElementZ extends ParameterElementZ
    implements LocalParameterElement {
  LocalParameterElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitParameterElement(this, arg);
  }

  @override
  bool get isLocal => true;

  @override
  ElementKind get kind => ElementKind.PARAMETER;

  @override
  bool get isUnnamed => false;
}

class InitializingFormalElementZ extends LocalParameterElementZ
    implements InitializingFormalElement {
  FieldElement _fieldElement;

  InitializingFormalElementZ(ObjectDecoder decoder) : super(decoder);

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

  @override
  bool get isLocal => true;

  ConstructorElementZ get functionDeclaration => super.functionDeclaration;
}

class LocalVariableElementZ extends DeserializedElementZ
    with
        AnalyzableElementMixin,
        AstElementMixinZ<VariableDefinitions>,
        LocalExecutableMixin,
        TypedElementMixin
    implements LocalVariableElement {
  bool _isConst;
  ConstantExpression _constant;

  LocalVariableElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  accept(ElementVisitor visitor, arg) {
    return visitor.visitLocalVariableElement(this, arg);
  }

  @override
  ElementKind get kind => ElementKind.VARIABLE;

  @override
  bool get isFinal => _decoder.getBool(Key.IS_FINAL);

  @override
  bool get isConst {
    if (_isConst == null) {
      _constant = _decoder.getConstant(Key.CONSTANT, isOptional: true);
      _isConst = _constant != null;
    }
    return _isConst;
  }

  @override
  bool get hasConstant => true;

  @override
  ConstantExpression get constant {
    if (isConst) {
      return _constant;
    }
    return null;
  }

  @override
  Expression get initializer => _unsupported('initializer');
}

class ImportElementZ extends DeserializedElementZ
    with LibraryMemberMixin
    implements ImportElement {
  bool _isDeferred;
  PrefixElement _prefix;
  LibraryElement _importedLibrary;
  Uri _uri;

  ImportElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  String get name => '';

  @override
  accept(ElementVisitor visitor, arg) => visitor.visitImportElement(this, arg);

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  LibraryElement get importedLibrary {
    if (_importedLibrary == null) {
      _importedLibrary = _decoder.getElement(Key.LIBRARY_DEPENDENCY);
    }
    return _importedLibrary;
  }

  void _ensurePrefixResolved() {
    if (_isDeferred == null) {
      _isDeferred = _decoder.getBool(Key.IS_DEFERRED);
      _prefix = _decoder.getElement(Key.PREFIX, isOptional: true);
    }
  }

  @override
  bool get isDeferred {
    _ensurePrefixResolved();
    return _isDeferred;
  }

  @override
  PrefixElement get prefix {
    _ensurePrefixResolved();
    return _prefix;
  }

  @override
  Uri get uri {
    if (_uri == null) {
      _uri = _decoder.getUri(Key.URI);
    }
    return _uri;
  }

  @override
  Import get node => _unsupported('node');

  String toString() => 'Z$kind($uri)';
}

class ExportElementZ extends DeserializedElementZ
    with LibraryMemberMixin
    implements ExportElement {
  LibraryElement _exportedLibrary;
  Uri _uri;

  ExportElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  String get name => '';

  @override
  accept(ElementVisitor visitor, arg) => visitor.visitExportElement(this, arg);

  @override
  ElementKind get kind => ElementKind.EXPORT;

  @override
  LibraryElement get exportedLibrary {
    if (_exportedLibrary == null) {
      _exportedLibrary = _decoder.getElement(Key.LIBRARY_DEPENDENCY);
    }
    return _exportedLibrary;
  }

  @override
  Uri get uri {
    if (_uri == null) {
      _uri = _decoder.getUri(Key.URI);
    }
    return _uri;
  }

  @override
  Export get node => _unsupported('node');

  String toString() => 'Z$kind($uri)';
}

class PrefixElementZ extends DeserializedElementZ
    with LibraryMemberMixin
    implements PrefixElement {
  bool _isDeferred;
  ImportElement _deferredImport;
  GetterElement _loadLibrary;
  ListedContainer _members;

  PrefixElementZ(ObjectDecoder decoder) : super(decoder);

  @override
  accept(ElementVisitor visitor, arg) => visitor.visitPrefixElement(this, arg);

  @override
  bool get isTopLevel => false;

  void _ensureDeferred() {
    if (_isDeferred == null) {
      _isDeferred = _decoder.getBool(Key.IS_DEFERRED);
      if (_isDeferred) {
        _deferredImport = _decoder.getElement(Key.IMPORT);
        _loadLibrary = _decoder.getElement(Key.GETTER);
      }
    }
  }

  @override
  ImportElement get deferredImport {
    _ensureDeferred();
    return _deferredImport;
  }

  @override
  bool get isDeferred {
    _ensureDeferred();
    return _isDeferred;
  }

  @override
  GetterElement get loadLibrary {
    return _loadLibrary;
  }

  @override
  ElementKind get kind => ElementKind.PREFIX;

  void _ensureMembers() {
    if (_members == null) {
      _members = new ListedContainer(
          _decoder.getElements(Key.MEMBERS, isOptional: true));
    }
  }

  @override
  Element lookupLocalMember(String memberName) {
    _ensureMembers();
    return _members.lookup(memberName);
  }

  @override
  void forEachLocalMember(void f(Element member)) {
    _ensureMembers();
    _members.forEach(f);
  }
}

class MetadataAnnotationZ implements MetadataAnnotation {
  final Element annotatedElement;
  final SourceSpan sourcePosition;
  final ConstantExpression constant;

  MetadataAnnotationZ(
      this.annotatedElement, this.sourcePosition, this.constant);

  @override
  MetadataAnnotation ensureResolved(Resolution resolution) {
    // Do nothing.
    return this;
  }

  @override
  Node get node => throw new UnsupportedError('${this}.node');

  @override
  bool get hasNode => false;

  String toString() => 'MetadataAnnotationZ(${constant.toDartText()})';
}
