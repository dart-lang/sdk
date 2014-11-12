// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of analyzer2dart.element_converter;


/// Base [dart2js.Element] implementation for converted analyzer elements.
class ElementY extends dart2js.Element {
  final ElementConverter converter;
  final analyzer.Element element;

  @override
  String get name => element.name;

  ElementY(this.converter, this.element);

  @override
  dart2js.LibraryElement get implementationLibrary => library;

  @override
  dart2js.Element get origin => this;

  @override
  dart2js.Element get patch => null;

  @override
  dart2js.Element get declaration => this;

  @override
  dart2js.Element get implementation => this;

  @override
  bool get isPatch => false;

  @override
  bool get isPatched => false;

  @override
  bool get isDeclaration => true;

  @override
  bool get isImplementation => false;

  @override
  dart2js.LibraryElement get library {
    return converter.convertElement(element.library);
  }

  @override
  bool get isLocal => false;

  unsupported(String method) {
    throw new UnsupportedError(
        "'$method' is unsupported on $this ($runtimeType)");
  }


  @override
  bool get isFinal => unsupported('isFinal');

  @override
  bool get isStatic => unsupported('isStatic');

  @override
  bool isForeign(_) => unsupported('isForeign');

  @override
  bool get impliesType => unsupported('impliesType');

  @override
  bool get isOperator => unsupported('impliesType');

  @override
  get position => unsupported('position');

  @override
  computeType(_) => unsupported('computeType');

  @override
  get enclosingElement => unsupported('enclosingElement');

  @override
  accept(_) => unsupported('accept');

  @override
  void addMetadata(_) => unsupported('addMetadata');

  @override
  get analyzableElement => unsupported('analyzableElement');

  @override
  asFunctionElement() => unsupported('asFunctionElement');

  @override
  buildScope() => unsupported('buildScope');

  @override
  get compilationUnit => unsupported('compilationUnit');

  @override
  get contextClass => unsupported('contextClass');

  @override
  void diagnose(context, listener) => unsupported('diagnose');

  @override
  get enclosingClass => unsupported('enclosingClass');

  @override
  get enclosingClassOrCompilationUnit {
    return unsupported('enclosingClassOrCompilationUnit');
  }

  @override
  String get fixedBackendName => unsupported('fixedBackendName');

  @override
  bool get hasFixedBackendName => unsupported('hasFixedBackendName');

  @override
  bool get isAbstract => unsupported('isAbstract');

  @override
  bool get isAssignable => unsupported('isAssignable');

  @override
  bool get isClassMember => unsupported('isClassMember');

  @override
  bool get isClosure => unsupported('isClosure');

  @override
  bool get isConst => unsupported('isConst');

  @override
  bool get isDeferredLoaderGetter => unsupported('isDeferredLoaderGetter');

  @override
  bool get isFactoryConstructor => unsupported('isFactoryConstructor');

  @override
  bool get isForwardingConstructor => unsupported('isForwardingConstructor');

  @override
  bool get isInjected => unsupported('isInjected');

  @override
  bool get isInstanceMember => unsupported('isInstanceMember');

  @override
  bool get isMixinApplication => unsupported('isMixinApplication');

  @override
  bool get isNative => unsupported('isNative');

  @override
  bool get isSynthesized => unsupported('isSynthesized');

  @override
  bool get isTopLevel => unsupported('isTopLevel');

  @override
  get kind => unsupported('kind');

  @override
  get metadata => unsupported('metadata');

  @override
  get outermostEnclosingMemberOrTopLevel {
    return unsupported('outermostEnclosingMemberOrTopLevel');
  }

  @override
  void setFixedBackendName(String name) => unsupported('setFixedBackendName');

  @override
  void setNative(String name) => unsupported('setNative');

  String toString() => '$kind($name)';
}

abstract class AnalyzableElementY
    implements ElementY, dart2js.AnalyzableElement {
  @override
  bool get hasTreeElements => unsupported('hasTreeElements');

  @override
  get treeElements => unsupported('treeElements');
}

abstract class AstElementY implements ElementY, dart2js.AstElement {
  @override
  bool get hasNode => unsupported('hasNode');

  @override
  get node => unsupported('node');

  @override
  bool get hasResolvedAst => unsupported('hasResolvedAst');

  @override
  get resolvedAst => unsupported('resolvedAst');
}

class LibraryElementY extends ElementY with AnalyzableElementY
    implements dart2js.LibraryElement {
  analyzer.LibraryElement get element => super.element;

  @override
  dart2js.ElementKind get kind => dart2js.ElementKind.LIBRARY;

  // TODO(johnniwinther): Ensure the correct semantics of this.
  @override
  bool get isInternalLibrary => isPlatformLibrary && element.isPrivate;

  // TODO(johnniwinther): Ensure the correct semantics of this.
  @override
  bool get isPlatformLibrary => element.isInSdk;

  @override
  bool get isDartCore => element.isDartCore;

  LibraryElementY(ElementConverter converter, analyzer.LibraryElement element)
      : super(converter, element);

  @override
  void addCompilationUnit(_) => unsupported('addCompilationUnit');

  @override
  void addImport(element, import, listener) => unsupported('addImport');

  @override
  void addMember(element, listener) => unsupported('addMember');

  @override
  void addTag(tag, listener) => unsupported('addTag');

  @override
  void addToScope(element, listener) => unsupported('addToScope');

  @override
  void set canUseNative(bool value) => unsupported('canUseNative');

  @override
  bool get canUseNative => unsupported('canUseNative');

  @override
  Uri get canonicalUri => unsupported('canonicalUri');

  @override
  int compareTo(other) => unsupported('compareTo');

  @override
  get compilationUnits => unsupported('compilationUnits');

  @override
  get entryCompilationUnit => unsupported('entryCompilationUnit');

  @override
  get exports => unsupported('exports');

  @override
  bool get exportsHandled => unsupported('exportsHandled');

  @override
  find(String elementName) => unsupported('find');

  @override
  findExported(String elementName) => unsupported('findExported');

  @override
  findLocal(String elementName) => unsupported('findLocal');

  @override
  void forEachExport(_) => unsupported('forEachExport');

  @override
  void forEachLocalMember(_) => unsupported('forEachLocalMember');

  @override
  getImportsFor(element) => unsupported('getImportsFor');

  @override
  getLibraryFromTag(tag) => unsupported('getLibraryFromTag');

  @override
  String getLibraryName() => unsupported('getLibraryName');

  @override
  String getLibraryOrScriptName() => unsupported('getLibraryOrScriptName');

  @override
  getNonPrivateElementsInScope() => unsupported('getNonPrivateElementsInScope');

  @override
  bool hasLibraryName() => unsupported('hasLibraryName');

  @override
  bool get isPackageLibrary => unsupported('isPackageLibrary');

  @override
  get libraryTag => unsupported('libraryTag');

  @override
  void set libraryTag(value) => unsupported('libraryTag');

  @override
  localLookup(elementName) => unsupported('localLookup');

  @override
  void recordResolvedTag(tag, library) => unsupported('recordResolvedTag');

  @override
  void setExports(exportedElements) => unsupported('setExports');

  @override
  get tags => unsupported('tags');
}

abstract class TopLevelElementMixin implements ElementY {
  @override
  bool get isClassMember => false;

  @override
  bool get isInstanceMember => false;

  @override
  bool get isTopLevel => true;

  // TODO(johnniwinther): Ensure the correct semantics of this.
  @override
  bool get isFactoryConstructor => false;

  @override
  bool get isStatic {
    // Semantic difference: Analyzer considers top-level and static class
    // members to be static, dart2js only considers static class members to be
    // static.
    return false;
  }

  // TODO(johnniwinther): Ensure the correct semantics of this.
  @override
  bool get isAbstract => false;
}

abstract class FunctionElementMixin
    implements ElementY, dart2js.FunctionElement {
  @override
  get abstractField => unsupported('abstractField');

  @override
  computeSignature(_) => unsupported('computeSignature');

  @override
  get memberContext => unsupported('memberContext');

  @override
  get functionSignature => unsupported('functionSignature');

  @override
  bool get hasFunctionSignature => unsupported('hasFunctionSignature');

  @override
  get asyncMarker => unsupported('asyncMarker');
}

class TopLevelFunctionElementY extends ElementY
    with AnalyzableElementY,
         AstElementY,
         TopLevelElementMixin,
         FunctionElementMixin
    implements dart2js.FunctionElement {
  analyzer.FunctionElement get element => super.element;

  @override
  dart2js.ElementKind get kind => dart2js.ElementKind.FUNCTION;

  @override
  dart2js.FunctionType get type => converter.convertType(element.type);

  TopLevelFunctionElementY(ElementConverter converter,
                           analyzer.FunctionElement element)
      : super(converter, element);
}

class LocalFunctionElementY extends ElementY
    with AnalyzableElementY,
         AstElementY,
         LocalElementMixin,
         FunctionElementMixin
    implements dart2js.LocalFunctionElement {
  analyzer.FunctionElement get element => super.element;

  @override
  dart2js.ElementKind get kind => dart2js.ElementKind.FUNCTION;

  @override
  dart2js.FunctionType get type => converter.convertType(element.type);

  @override
  bool get isAbstract => false;

  @override
  bool get isConst => false;

  LocalFunctionElementY(ElementConverter converter,
                        analyzer.FunctionElement element)
      : super(converter, element);
}

class ParameterElementY extends ElementY
    with AnalyzableElementY, AstElementY
    implements dart2js.ParameterElement {

  analyzer.ParameterElement get element => super.element;

  @override
  dart2js.ElementKind get kind => dart2js.ElementKind.PARAMETER;

  @override
  dart2js.DartType get type => converter.convertType(element.type);

  @override
  bool get isLocal => true;

  @override
  bool get isStatic => false;

  @override
  bool get isConst => false;

  ParameterElementY(ElementConverter converter,
                    analyzer.ParameterElement element)
      : super(converter, element) {
    assert(!element.isInitializingFormal);
  }

  @override
  get executableContext => unsupported('executableContext');

  @override
  get functionDeclaration => unsupported('functionDeclaration');

  @override
  get initializer => unsupported('initializer');

  @override
  get memberContext => unsupported('memberContext');

  @override
  get functionSignature => unsupported('functionSignature');
}

class TypeDeclarationElementY extends ElementY
    with AnalyzableElementY, AstElementY
    implements dart2js.TypeDeclarationElement {

  TypeDeclarationElementY(ElementConverter converter,
                          analyzer.Element element)
      : super(converter, element);

  @override
  void ensureResolved(compiler) => unsupported('ensureResolved');

  @override
  bool get isResolved => unsupported('isResolved');

  @override
  get rawType => null;//unsupported('rawType');

  @override
  int get resolutionState => unsupported('resolutionState');

  @override
  get thisType => unsupported('thisType');

  @override
  get typeVariables => unsupported('typeVariables');

}

class ClassElementY extends TypeDeclarationElementY
    implements dart2js.ClassElement {

  analyzer.ClassElement get element => super.element;

  dart2js.ElementKind get kind => dart2js.ElementKind.CLASS;

  @override
  bool get isObject => element.type.isObject;

  ClassElementY(ElementConverter converter, analyzer.ClassElement element)
      : super(converter, element);

  @override
  void addBackendMember(element) => unsupported('addBackendMember');

  @override
  void addMember(element, listener) => unsupported('addMember');

  @override
  void addToScope(element, listener) => unsupported('addToScope');

  @override
  get allSupertypes => unsupported('allSupertypes');

  @override
  get allSupertypesAndSelf => unsupported('allSupertypesAndSelf');

  @override
  asInstanceOf(cls) => unsupported('asInstanceOf');

  @override
  get callType => unsupported('callType');

  @override
  computeTypeParameters(compiler) => unsupported('computeTypeParameters');

  @override
  get constructors => unsupported('constructors');

  @override
  void forEachBackendMember(f) => unsupported('forEachBackendMember');

  @override
  void forEachClassMember(f) => unsupported('forEachClassMember');

  @override
  void forEachInstanceField(f, {includeSuperAndInjectedMembers: false}) {
    unsupported('forEachInstanceField');
  }

  @override
  void forEachInterfaceMember(f) => unsupported('forEachInterfaceMember');

  @override
  void forEachLocalMember(f) => unsupported('forEachLocalMember');

  @override
  void forEachMember(f,
                     {includeBackendMembers: false,
                      includeSuperAndInjectedMembers: false}) {
    unsupported('forEachMember');
  }

  @override
  void forEachStaticField(f) => unsupported('forEachStaticField');

  @override
  bool get hasBackendMembers => unsupported('hasBackendMembers');

  @override
  bool get hasConstructor => unsupported('hasConstructor');

  @override
  bool hasFieldShadowedBy(fieldMember) => unsupported('hasFieldShadowedBy');

  @override
  bool get hasIncompleteHierarchy => unsupported('hasIncompleteHierarchy');

  @override
  bool get hasLocalScopeMembers => unsupported('hasLocalScopeMembers');

  @override
  int get hierarchyDepth => unsupported('hierarchyDepth');

  @override
  int get id => unsupported('id');

  @override
  bool implementsInterface(intrface) => unsupported('implementsInterface');

  @override
  get interfaces => unsupported('interfaces');

  @override
  bool get isProxy => unsupported('isProxy');

  @override
  bool isSubclassOf(cls) => unsupported('isSubclassOf');

  @override
  get isUnnamedMixinApplication => unsupported('isUnnamedMixinApplication');

  @override
  localLookup(String elementName) => unsupported('localLookup');

  @override
  lookupBackendMember(String memberName) => unsupported('lookupBackendMember');

  @override
  lookupClassMember(name) => unsupported('lookupClassMember');

  @override
  lookupConstructor(selector, [noMatch]) => unsupported('lookupConstructor');

  @override
  lookupInterfaceMember(name) => unsupported('lookupInterfaceMember');

  @override
  lookupLocalMember(String memberName) => unsupported('lookupLocalMember');

  @override
  lookupMember(String memberName) => unsupported('lookupMember');

  @override
  lookupSelector(selector) => unsupported('lookupSelector');

  @override
  lookupSuperMember(String memberName) => unsupported('lookupSuperMember');

  @override
  lookupSuperMemberInLibrary(memberName, library) {
    unsupported('lookupSuperMemberInLibrary');
  }

  @override
  lookupSuperSelector(selector) => unsupported('lookupSuperSelector');

  @override
  String get nativeTagInfo => unsupported('nativeTagInfo');

  @override
  void reverseBackendMembers() => unsupported('reverseBackendMembers');

  @override
  void setDefaultConstructor(constructor, compiler) {
    unsupported('setDefaultConstructor');
  }

  @override
  dart2js.ClassElement get superclass => unsupported('superclass');

  // TODO(johnniwinther): Semantic difference: Dart2js points to unnamed
  // mixin applications, analyzer points to the type in the extends clause or
  // Object if omitted.
  @override
  dart2js.DartType get supertype => unsupported('supertype');

  @override
  int get supertypeLoadState => unsupported('supertypeLoadState');

  @override
  validateConstructorLookupResults(selector,  result, noMatch) {
    unsupported('validateConstructorLookupResults');
  }

  @override
  bool get isEnumClass => unsupported('isEnum');
}

class TypedefElementY extends TypeDeclarationElementY
    implements dart2js.TypedefElement {

  analyzer.FunctionTypeAliasElement get element => super.element;

  dart2js.ElementKind get kind => dart2js.ElementKind.TYPEDEF;

  TypedefElementY(ElementConverter converter,
                  analyzer.FunctionTypeAliasElement element)
      : super(converter, element);

  @override
  dart2js.DartType get alias => unsupported('alias');

  @override
  void checkCyclicReference(compiler) => unsupported('checkCyclicReference');

  @override
  get functionSignature => unsupported('functionSignature');
}

abstract class VariableElementMixin
    implements ElementY, dart2js.VariableElement {
  @override
  get initializer => unsupported('initializer');

  @override
  get memberContext => unsupported('memberContext');
}

class TopLevelVariableElementY extends ElementY
    with AnalyzableElementY,
         AstElementY,
         TopLevelElementMixin,
         VariableElementMixin
    implements dart2js.FieldElement {

  analyzer.TopLevelVariableElement get element => super.element;

  dart2js.ElementKind get kind => dart2js.ElementKind.FIELD;

  @override
  dart2js.DartType get type => converter.convertType(element.type);

  TopLevelVariableElementY(ElementConverter converter,
                           analyzer.TopLevelVariableElement element)
      : super(converter, element);

  @override
  get nestedClosures => unsupported('nestedClosures');
}

abstract class LocalElementMixin implements ElementY, dart2js.LocalElement {

  @override
  bool get isLocal => true;

  @override
  bool get isStatic => false;

  @override
  get executableContext => unsupported('executableContext');

  // TODO(johnniwinther): Ensure the correct semantics of this.
  @override
  bool get isFactoryConstructor => false;
}

class LocalVariableElementY extends ElementY
    with AnalyzableElementY,
         AstElementY,
         LocalElementMixin,
         VariableElementMixin
    implements dart2js.LocalVariableElement {

  analyzer.LocalVariableElement get element => super.element;

  dart2js.ElementKind get kind => dart2js.ElementKind.VARIABLE;

  @override
  bool get isConst => element.isConst;

  LocalVariableElementY(ElementConverter converter,
                        analyzer.LocalVariableElement element)
      : super(converter, element);

  @override
  dart2js.DartType get type => unsupported('type');
}

class ConstructorElementY extends ElementY
    with AnalyzableElementY,
         AstElementY,
         FunctionElementMixin
    implements dart2js.ConstructorElement {

  analyzer.ConstructorElement get element => super.element;

  @override
  dart2js.ClassElement get enclosingClass {
    return converter.convertElement(element.enclosingElement);
  }

  // TODO(johnniwinther): Support redirecting/factory constructors.
  @override
  dart2js.ElementKind get kind => dart2js.ElementKind.GENERATIVE_CONSTRUCTOR;

  ConstructorElementY(ElementConverter converter,
                      analyzer.ConstructorElement element)
      : super(converter, element);

  @override
  computeEffectiveTargetType(_) => unsupported('computeEffectiveTargetType');

  @override
  get definingConstructor => unsupported('definingConstructor');

  @override
  get effectiveTarget => unsupported('effectiveTarget');

  @override
  get immediateRedirectionTarget => unsupported('immediateRedirectionTarget');

  @override
  bool get isRedirectingFactory => unsupported('isRedirectingFactory');

  @override
  get nestedClosures => unsupported('nestedClosures');

  @override
  get type => unsupported('type');
}