// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Convertion of elements between the analyzer element model and the dart2js
/// element model.

library analyzer2dart.element_converter;

import 'package:compiler/implementation/elements/elements.dart' as dart2js;
import 'package:compiler/implementation/elements/modelx.dart' as modelx;
import 'package:compiler/implementation/util/util.dart' as util;
import 'package:compiler/implementation/dart_types.dart';
import 'package:analyzer/src/generated/element.dart' as analyzer;

class ElementConverter {
  /// Map from analyzer elements to their equivalent dart2js elements.
  Map<analyzer.Element, dart2js.Element> conversionMap =
      <analyzer.Element, dart2js.Element>{};

  /// Map from dart2js elements to their equivalent analyzer elements.
  Map<dart2js.Element, analyzer.Element> inversionMap =
      <dart2js.Element, analyzer.Element>{};

  ElementConverterVisitor visitor;

  ElementConverter() {
    visitor = new ElementConverterVisitor(this);
  }

  dart2js.Element convertElement(analyzer.Element input) {
    return conversionMap.putIfAbsent(input, () {
      dart2js.Element output = convertElementInternal(input);
      inversionMap[output] = input;
      return output;
    });
  }

  analyzer.Element invertElement(dart2js.Element input) {
    return inversionMap[input];
  }

  dart2js.Element convertElementInternal(analyzer.Element input) {
    dart2js.Element output = input.accept(visitor);
    if (output != null) return output;
    throw new UnsupportedError(
        "Conversion of $input (${input.runtimeType}) is not supported.");
  }
}

/// Visitor that converts analyzer elements to dart2js elements.
class ElementConverterVisitor
    extends analyzer.SimpleElementVisitor<dart2js.Element> {
  final ElementConverter converter;

  ElementConverterVisitor(this.converter);

  @override
  dart2js.LibraryElement visitLibraryElement(analyzer.LibraryElement input) {
    return new LibraryElementY(converter, input);
  }

  @override
  dart2js.FunctionElement visitFunctionElement(analyzer.FunctionElement input) {
    return new TopLevelFunctionElementY(converter, input);
  }
}

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
  dart2js.LibraryElement get library {
    return converter.convertElement(element.library);
  }

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
  bool get isDeclaration => unsupported('isDeclaration');

  @override
  bool get isDeferredLoaderGetter => unsupported('isDeferredLoaderGetter');

  @override
  bool get isFactoryConstructor => unsupported('isFactoryConstructor');

  @override
  bool get isForwardingConstructor => unsupported('isForwardingConstructor');

  @override
  bool get isImplementation => unsupported('isImplementation');

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
}

class LibraryElementY extends ElementY implements dart2js.LibraryElement {
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
  bool get hasTreeElements => unsupported('hasTreeElements');

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

  @override
  get treeElements => unsupported('treeElements');
}

class TopLevelFunctionElementY extends ElementY
    implements dart2js.FunctionElement {
  analyzer.FunctionElement get element => super.element;

  final dart2js.FunctionSignature functionSignature =
      new modelx.FunctionSignatureX(
          const util.Link<dart2js.Element>(),
          const util.Link<dart2js.Element>(),
          0, 0, false, const <dart2js.Element>[],
          new FunctionType.synthesized());


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

  @override
  dart2js.ElementKind get kind => dart2js.ElementKind.FUNCTION;

  @override
  bool get isClassMember => false;

  @override
  bool get isInstanceMember => false;

  @override
  bool get isTopLevel => true;

  TopLevelFunctionElementY(ElementConverter converter,
                           analyzer.FunctionElement element)
      : super(converter, element);

  @override
  get abstractField => unsupported('abstractField');

  @override
  computeSignature(_) => unsupported('computeSignature');

  @override
  bool get hasNode => unsupported('hasNode');

  @override
  bool get hasResolvedAst => unsupported('hasResolvedAst');

  @override
  bool get hasTreeElements => unsupported('hasTreeElements');

  @override
  get memberContext => unsupported('memberContext');

  @override
  get node => unsupported('node');

  @override
  get resolvedAst => unsupported('resolvedAst');

  @override
  get treeElements => unsupported('treeElements');

  @override
  FunctionType get type => functionSignature.type;
}
