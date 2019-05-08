// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Directive;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';

/// Implementation of [CompilationUnitElement] that wraps a
/// [CompilationUnitElement] and defers all method calls to it.
///
/// This is intended to be used by the rare clients that must reimplement
/// [CompilationUnitElement], so that they won't be broken if new methods are
/// added.
class WrappedCompilationUnitElement implements CompilationUnitElement {
  final CompilationUnitElement wrappedUnit;

  WrappedCompilationUnitElement(this.wrappedUnit);

  @override
  List<PropertyAccessorElement> get accessors => wrappedUnit.accessors;

  @override
  AnalysisContext get context => wrappedUnit.context;

  @override
  String get displayName => wrappedUnit.displayName;

  @override
  String get documentationComment => wrappedUnit.documentationComment;

  @override
  LibraryElement get enclosingElement => wrappedUnit.enclosingElement;

  @override
  List<ClassElement> get enums => wrappedUnit.enums;

  @override
  List<FunctionElement> get functions => wrappedUnit.functions;

  @override
  List<FunctionTypeAliasElement> get functionTypeAliases =>
      wrappedUnit.functionTypeAliases;

  @override
  bool get hasAlwaysThrows => wrappedUnit.hasAlwaysThrows;

  @override
  bool get hasDeprecated => wrappedUnit.hasDeprecated;

  @override
  bool get hasFactory => wrappedUnit.hasFactory;

  @override
  bool get hasIsTest => wrappedUnit.hasIsTest;

  @override
  bool get hasIsTestGroup => wrappedUnit.hasIsTestGroup;

  @override
  bool get hasJS => wrappedUnit.hasJS;

  @override
  bool get hasLiteral => wrappedUnit.hasLiteral;

  @override
  bool get hasLoadLibraryFunction => wrappedUnit.hasLoadLibraryFunction;

  @override
  bool get hasMustCallSuper => wrappedUnit.hasMustCallSuper;

  @override
  bool get hasOptionalTypeArgs => wrappedUnit.hasOptionalTypeArgs;

  @override
  bool get hasOverride => wrappedUnit.hasOverride;

  @override
  bool get hasProtected => wrappedUnit.hasProtected;

  @override
  bool get hasRequired => wrappedUnit.hasRequired;

  @override
  bool get hasSealed => wrappedUnit.hasSealed;

  @override
  bool get hasVisibleForTemplate => wrappedUnit.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => wrappedUnit.hasVisibleForTesting;

  @override
  int get id => wrappedUnit.id;

  @override
  bool get isAlwaysThrows => hasAlwaysThrows;

  @override
  bool get isDeprecated => hasDeprecated;

  @override
  bool get isFactory => hasFactory;

  @override
  bool get isJS => hasJS;

  @override
  bool get isOverride => hasOverride;

  @override
  bool get isPrivate => wrappedUnit.isPrivate;

  @override
  bool get isProtected => hasProtected;

  @override
  bool get isPublic => wrappedUnit.isPublic;

  @override
  bool get isRequired => hasRequired;

  @override
  bool get isSynthetic => wrappedUnit.isSynthetic;

  @override
  bool get isVisibleForTesting => hasVisibleForTesting;

  @override
  ElementKind get kind => wrappedUnit.kind;

  @override
  LibraryElement get library => wrappedUnit.library;

  @override
  Source get librarySource => wrappedUnit.librarySource;

  @override
  LineInfo get lineInfo => wrappedUnit.lineInfo;

  @override
  ElementLocation get location => wrappedUnit.location;

  @override
  List<ElementAnnotation> get metadata => wrappedUnit.metadata;

  @override
  List<ClassElement> get mixins => wrappedUnit.mixins;

  @override
  String get name => wrappedUnit.name;

  @override
  int get nameLength => wrappedUnit.nameLength;

  @override
  int get nameOffset => wrappedUnit.nameOffset;

  @override
  AnalysisSession get session => wrappedUnit.session;

  @override
  Source get source => wrappedUnit.source;

  @override
  List<TopLevelVariableElement> get topLevelVariables =>
      wrappedUnit.topLevelVariables;

  @override
  List<ClassElement> get types => wrappedUnit.types;

  @deprecated
  @override
  CompilationUnit get unit => wrappedUnit.unit;

  @override
  String get uri => wrappedUnit.uri;

  @override
  int get uriEnd => wrappedUnit.uriEnd;

  @override
  int get uriOffset => wrappedUnit.uriOffset;

  @override
  T accept<T>(ElementVisitor<T> visitor) => wrappedUnit.accept(visitor);

  @override
  String computeDocumentationComment() => wrappedUnit
      .computeDocumentationComment(); // ignore: deprecated_member_use_from_same_package

  @deprecated
  @override
  CompilationUnit computeNode() => wrappedUnit.computeNode();

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) =>
      wrappedUnit.getAncestor(predicate);

  @override
  ClassElement getEnum(String name) => wrappedUnit.getEnum(name);

  @override
  String getExtendedDisplayName(String shortName) =>
      wrappedUnit.getExtendedDisplayName(shortName);

  @override
  ClassElement getType(String className) => wrappedUnit.getType(className);

  @override
  bool isAccessibleIn(LibraryElement library) =>
      wrappedUnit.isAccessibleIn(library);

  @override
  void visitChildren(ElementVisitor visitor) =>
      wrappedUnit.visitChildren(visitor);
}

/// Implementation of [ImportElement] that wraps an [ImportElement] and defers
/// all method calls to it.
///
/// This is intended to be used by the rare clients that must reimplement
/// [ImportElement], so that they won't be broken if new methods are added.
class WrappedImportElement implements ImportElement {
  final ImportElement wrappedImport;

  WrappedImportElement(this.wrappedImport);

  @override
  List<NamespaceCombinator> get combinators => wrappedImport.combinators;

  @override
  AnalysisContext get context => wrappedImport.context;

  @override
  String get displayName => wrappedImport.displayName;

  @override
  String get documentationComment => wrappedImport.documentationComment;

  @override
  LibraryElement get enclosingElement => wrappedImport.enclosingElement;

  @override
  bool get hasAlwaysThrows => wrappedImport.hasAlwaysThrows;

  @override
  bool get hasDeprecated => wrappedImport.hasDeprecated;

  @override
  bool get hasFactory => wrappedImport.hasFactory;

  @override
  bool get hasIsTest => wrappedImport.hasIsTest;

  @override
  bool get hasIsTestGroup => wrappedImport.hasIsTestGroup;

  @override
  bool get hasJS => wrappedImport.hasJS;

  @override
  bool get hasLiteral => wrappedImport.hasLiteral;

  @override
  bool get hasMustCallSuper => wrappedImport.hasMustCallSuper;

  @override
  bool get hasOptionalTypeArgs => wrappedImport.hasOptionalTypeArgs;

  @override
  bool get hasOverride => wrappedImport.hasOverride;

  @override
  bool get hasProtected => wrappedImport.hasProtected;

  @override
  bool get hasRequired => wrappedImport.hasRequired;

  @override
  bool get hasSealed => wrappedImport.hasSealed;

  @override
  bool get hasVisibleForTemplate => wrappedImport.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => wrappedImport.hasVisibleForTesting;

  @override
  int get id => wrappedImport.id;

  @override
  LibraryElement get importedLibrary => wrappedImport.importedLibrary;

  @override
  bool get isAlwaysThrows => hasAlwaysThrows;

  @override
  bool get isDeferred => wrappedImport.isDeferred;

  @override
  bool get isDeprecated => hasDeprecated;

  @override
  bool get isFactory => hasFactory;

  @override
  bool get isJS => hasJS;

  @override
  bool get isOverride => hasOverride;

  @override
  bool get isPrivate => wrappedImport.isPrivate;

  @override
  bool get isProtected => hasProtected;

  @override
  bool get isPublic => wrappedImport.isPublic;

  @override
  bool get isRequired => hasRequired;

  @override
  bool get isSynthetic => wrappedImport.isSynthetic;

  @override
  bool get isVisibleForTesting => hasVisibleForTesting;

  @override
  ElementKind get kind => wrappedImport.kind;

  @override
  LibraryElement get library => wrappedImport.library;

  @override
  Source get librarySource => wrappedImport.librarySource;

  @override
  ElementLocation get location => wrappedImport.location;

  @override
  List<ElementAnnotation> get metadata => wrappedImport.metadata;

  @override
  String get name => wrappedImport.name;

  @override
  int get nameLength => wrappedImport.nameLength;

  @override
  int get nameOffset => wrappedImport.nameOffset;

  @override
  Namespace get namespace => wrappedImport.namespace;

  @override
  PrefixElement get prefix => wrappedImport.prefix;

  @override
  int get prefixOffset => wrappedImport.prefixOffset;

  @override
  AnalysisSession get session => wrappedImport.session;

  @override
  Source get source => wrappedImport.source;

  @deprecated
  @override
  CompilationUnit get unit => wrappedImport.unit;

  @override
  String get uri => wrappedImport.uri;

  @override
  int get uriEnd => wrappedImport.uriEnd;

  @override
  int get uriOffset => wrappedImport.uriOffset;

  @override
  T accept<T>(ElementVisitor<T> visitor) => wrappedImport.accept(visitor);

  @override
  String computeDocumentationComment() => wrappedImport
      .computeDocumentationComment(); // ignore: deprecated_member_use_from_same_package

  @deprecated
  @override
  AstNode computeNode() => wrappedImport.computeNode();

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) =>
      wrappedImport.getAncestor(predicate);

  @override
  String getExtendedDisplayName(String shortName) =>
      wrappedImport.getExtendedDisplayName(shortName);

  @override
  bool isAccessibleIn(LibraryElement library) =>
      wrappedImport.isAccessibleIn(library);

  @override
  void visitChildren(ElementVisitor visitor) =>
      wrappedImport.visitChildren(visitor);
}

/// Implementation of [LibraryElement] that wraps a [LibraryElement] and defers
/// all method calls to it.
///
/// This is intended to be used by the rare clients that must reimplement
/// [LibraryElement], so that they won't be broken if new methods are added.
class WrappedLibraryElement implements LibraryElement {
  final LibraryElement wrappedLib;

  WrappedLibraryElement(this.wrappedLib);

  @override
  AnalysisContext get context => wrappedLib.context;

  @override
  CompilationUnitElement get definingCompilationUnit =>
      wrappedLib.definingCompilationUnit;

  @override
  String get displayName => wrappedLib.displayName;

  @override
  String get documentationComment => wrappedLib.documentationComment;

  @override
  Element get enclosingElement => wrappedLib.enclosingElement;

  @override
  FunctionElement get entryPoint => wrappedLib.entryPoint;

  @override
  List<LibraryElement> get exportedLibraries => wrappedLib.exportedLibraries;

  @override
  Namespace get exportNamespace => wrappedLib.exportNamespace;

  @override
  List<ExportElement> get exports => wrappedLib.exports;

  @override
  bool get hasAlwaysThrows => wrappedLib.hasAlwaysThrows;

  @override
  bool get hasDeprecated => wrappedLib.hasDeprecated;

  @override
  bool get hasExtUri => wrappedLib.hasExtUri;

  @override
  bool get hasFactory => wrappedLib.hasFactory;

  @override
  bool get hasIsTest => wrappedLib.hasIsTest;

  @override
  bool get hasIsTestGroup => wrappedLib.hasIsTestGroup;

  @override
  bool get hasJS => wrappedLib.hasJS;

  @override
  bool get hasLiteral => wrappedLib.hasLiteral;

  @override
  bool get hasLoadLibraryFunction => wrappedLib.hasLoadLibraryFunction;

  @override
  bool get hasMustCallSuper => wrappedLib.hasMustCallSuper;

  @override
  bool get hasOptionalTypeArgs => wrappedLib.hasOptionalTypeArgs;

  @override
  bool get hasOverride => wrappedLib.hasOverride;

  @override
  bool get hasProtected => wrappedLib.hasProtected;

  @override
  bool get hasRequired => wrappedLib.hasRequired;

  @override
  bool get hasSealed => wrappedLib.hasSealed;

  @override
  bool get hasVisibleForTemplate => wrappedLib.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => wrappedLib.hasVisibleForTesting;

  @override
  int get id => wrappedLib.id;

  @override
  String get identifier => wrappedLib.identifier;

  @override
  List<LibraryElement> get importedLibraries => wrappedLib.importedLibraries;

  @override
  List<ImportElement> get imports => wrappedLib.imports;

  @override
  bool get isAlwaysThrows => hasAlwaysThrows;

  @override
  bool get isBrowserApplication => wrappedLib.isBrowserApplication;

  @override
  bool get isDartAsync => wrappedLib.isDartAsync;

  @override
  bool get isDartCore => wrappedLib.isDartCore;

  @override
  bool get isDeprecated => hasDeprecated;

  @override
  bool get isFactory => hasFactory;

  @override
  bool get isInSdk => wrappedLib.isInSdk;

  @override
  bool get isJS => hasJS;

  @override
  bool get isOverride => hasOverride;

  @override
  bool get isPrivate => wrappedLib.isPrivate;

  @override
  bool get isProtected => hasProtected;

  @override
  bool get isPublic => wrappedLib.isPublic;

  @override
  bool get isRequired => hasRequired;

  @override
  bool get isSynthetic => wrappedLib.isSynthetic;

  @override
  bool get isVisibleForTesting => hasVisibleForTesting;

  @override
  ElementKind get kind => wrappedLib.kind;

  @override
  LibraryElement get library => wrappedLib.library;

  @override
  List<LibraryElement> get libraryCycle => wrappedLib.libraryCycle;

  @override
  Source get librarySource => wrappedLib.librarySource;

  @override
  FunctionElement get loadLibraryFunction => wrappedLib.loadLibraryFunction;

  @override
  ElementLocation get location => wrappedLib.location;

  @override
  List<ElementAnnotation> get metadata => wrappedLib.metadata;

  @override
  String get name => wrappedLib.name;

  @override
  int get nameLength => wrappedLib.nameLength;

  @override
  int get nameOffset => wrappedLib.nameOffset;

  @override
  List<CompilationUnitElement> get parts => wrappedLib.parts;

  @override
  List<PrefixElement> get prefixes => wrappedLib.prefixes;

  @override
  Namespace get publicNamespace => wrappedLib.publicNamespace;

  @override
  AnalysisSession get session => wrappedLib.session;

  @override
  Source get source => wrappedLib.source;

  @override
  Iterable<Element> get topLevelElements => wrappedLib.topLevelElements;

  @deprecated
  @override
  CompilationUnit get unit => wrappedLib.unit;

  @override
  List<CompilationUnitElement> get units => wrappedLib.units;

  @override
  T accept<T>(ElementVisitor<T> visitor) => wrappedLib.accept(visitor);

  @override
  String computeDocumentationComment() => wrappedLib
      .computeDocumentationComment(); // ignore: deprecated_member_use_from_same_package

  @deprecated
  @override
  AstNode computeNode() => wrappedLib.computeNode();

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) =>
      wrappedLib.getAncestor(predicate);

  @override
  String getExtendedDisplayName(String shortName) =>
      wrappedLib.getExtendedDisplayName(shortName);

  @override
  List<ImportElement> getImportsWithPrefix(PrefixElement prefix) =>
      wrappedLib.getImportsWithPrefix(prefix);

  @override
  ClassElement getType(String className) => wrappedLib.getType(className);

  @override
  bool isAccessibleIn(LibraryElement library) =>
      wrappedLib.isAccessibleIn(library);

  @override
  void visitChildren(ElementVisitor visitor) =>
      wrappedLib.visitChildren(visitor);
}
