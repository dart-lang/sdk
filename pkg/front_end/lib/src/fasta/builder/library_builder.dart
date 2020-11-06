// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_builder;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' show Library, Nullability, Version;

import '../combinator.dart' show Combinator;

import '../problems.dart' show internalProblem, unsupported;

import '../export.dart' show Export;

import '../loader.dart' show Loader;

import '../messages.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        templateInternalProblemConstructorNotFound,
        templateInternalProblemNotFoundIn,
        templateInternalProblemPrivateConstructorAccess;

import '../scope.dart';

import 'builder.dart';
import 'class_builder.dart';
import 'field_builder.dart';
import 'member_builder.dart';
import 'modifier_builder.dart';
import 'name_iterator.dart';
import 'nullability_builder.dart';
import 'prefix_builder.dart';
import 'type_alias_builder.dart';
import 'type_builder.dart';

abstract class LibraryBuilder implements ModifierBuilder {
  Scope get scope;

  Scope get exportScope;

  ScopeBuilder get scopeBuilder;

  ScopeBuilder get exportScopeBuilder;

  List<Export> get exporters;

  LibraryBuilder partOfLibrary;

  bool mayImplementRestrictedTypes;

  /// Set the language version to a specific non-null [version].
  ///
  /// If the language version has previously been explicitly set set (i.e. with
  /// [explicit] set to true), any subsequent call (explicit or not) should be
  /// ignored.
  /// Multiple calls with [explicit] set to false should be allowed though.
  ///
  /// The main idea is that the .packages file specifies a default language
  /// version, but that the library can have source code that specifies another
  /// one which should be supported, but specifying several in code should not
  /// change anything.
  ///
  /// [offset] and [length] refers to the offset and length of the source code
  /// specifying the language version.
  void setLanguageVersion(Version version,
      {int offset: 0, int length, bool explicit});

  bool get isPart;

  Loader get loader;

  /// Returns the [Library] built by this builder.
  Library get library;

  /// Returns the import uri for the library.
  ///
  /// This is the canonical uri for the library, for instance 'dart:core'.
  Uri get importUri;

  Iterator<Builder> get iterator;

  NameIterator get nameIterator;

  Builder addBuilder(String name, Builder declaration, int charOffset);

  void addExporter(
      LibraryBuilder exporter, List<Combinator> combinators, int charOffset);

  /// Add a problem with a severity determined by the severity of the message.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  ///
  /// See `Loader.addMessage` for an explanation of the
  /// arguments passed to this method.
  FormattedMessage addProblem(
      Message message, int charOffset, int length, Uri fileUri,
      {bool wasHandled: false,
      List<LocatedMessage> context,
      Severity severity,
      bool problemOnLibrary: false});

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Builder member, [int charOffset = -1]);

  void addToScope(String name, Builder member, int charOffset, bool isImport);

  Builder computeAmbiguousDeclaration(
      String name, Builder declaration, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false});

  int finishDeferredLoadTearoffs();

  int finishForwarders();

  int finishNativeMethods();

  int finishPatchMethods();

  /// Looks up [constructorName] in the class named [className].
  ///
  /// The class is looked up in this library's export scope unless
  /// [bypassLibraryPrivacy] is true, in which case it is looked up in the
  /// library scope of this library.
  ///
  /// It is an error if no such class is found, or if the class doesn't have a
  /// matching constructor (or factory).
  ///
  /// If [constructorName] is null or the empty string, it's assumed to be an
  /// unnamed constructor. it's an error if [constructorName] starts with
  /// `"_"`, and [bypassLibraryPrivacy] is false.
  MemberBuilder getConstructor(String className,
      {String constructorName, bool bypassLibraryPrivacy: false});

  int finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType);

  /// Computes variances of type parameters on typedefs.
  ///
  /// The variance property of type parameters on typedefs is computed from the
  /// use of the parameters in the right-hand side of the typedef definition.
  int computeVariances() => 0;

  /// This method instantiates type parameters to their bounds in some cases
  /// where they were omitted by the programmer and not provided by the type
  /// inference.  The method returns the number of distinct type variables
  /// that were instantiated in this library.
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass);

  void becomeCoreLibrary();

  void addSyntheticDeclarationOfDynamic();

  void addSyntheticDeclarationOfNever();

  void addSyntheticDeclarationOfNull();

  /// Lookups the member [name] declared in this library.
  ///
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  Builder lookupLocalMember(String name, {bool required: false});

  Builder lookup(String name, int charOffset, Uri fileUri);

  /// If this is a patch library, apply its patches to [origin].
  void applyPatches();

  void recordAccess(int charOffset, int length, Uri fileUri);

  void buildOutlineExpressions();

  List<FieldBuilder> takeImplicitlyTypedFields();

  bool get isNonNullableByDefault;

  Nullability get nullable;

  Nullability get nonNullable;

  Nullability nullableIfTrue(bool isNullable);

  NullabilityBuilder get nullableBuilder;

  NullabilityBuilder get nonNullableBuilder;

  NullabilityBuilder nullableBuilderIfTrue(bool isNullable);
}

abstract class LibraryBuilderImpl extends ModifierBuilderImpl
    implements LibraryBuilder {
  @override
  final Scope scope;

  @override
  final Scope exportScope;

  @override
  final ScopeBuilder scopeBuilder;

  @override
  final ScopeBuilder exportScopeBuilder;

  @override
  final List<Export> exporters = <Export>[];

  @override
  LibraryBuilder partOfLibrary;

  @override
  bool mayImplementRestrictedTypes = false;

  LibraryBuilderImpl(Uri fileUri, this.scope, this.exportScope)
      : scopeBuilder = new ScopeBuilder(scope),
        exportScopeBuilder = new ScopeBuilder(exportScope),
        super(null, -1, fileUri);

  @override
  bool get isSynthetic => false;

  /// Set the language version to a specific non-null major and minor version.
  ///
  /// If [version] is null (and no other version has been explicitly set) a
  /// problem is issued.
  ///
  /// If the language version has previously been explicitly set set (i.e. with
  /// [explicit] set to true), any subsequent call (explicit or not) should be
  /// ignored.
  /// Multiple calls with [explicit] set to false should be allowed though.
  ///
  /// The main idea is that the .packages file specifies a default language
  /// version, but that the library can have source code that specifies another
  /// one which should be supported, but specifying several in code should not
  /// change anything.
  ///
  /// [offset] and [length] refers to the offset and length of the source code
  /// specifying the language version.
  @override
  void setLanguageVersion(Version version,
      {int offset: 0, int length, bool explicit});

  @override
  Builder get parent => null;

  @override
  bool get isPart => false;

  @override
  String get debugName => "LibraryBuilder";

  @override
  Loader get loader;

  @override
  int get modifiers => 0;

  @override
  Uri get importUri;

  @override
  Iterator<Builder> get iterator {
    return new LibraryLocalDeclarationIterator(this);
  }

  @override
  NameIterator get nameIterator {
    return new LibraryLocalDeclarationNameIterator(this);
  }

  @override
  void addExporter(
      LibraryBuilder exporter, List<Combinator> combinators, int charOffset) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  @override
  FormattedMessage addProblem(
      Message message, int charOffset, int length, Uri fileUri,
      {bool wasHandled: false,
      List<LocatedMessage> context,
      Severity severity,
      bool problemOnLibrary: false}) {
    fileUri ??= this.fileUri;

    return loader.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: true);
  }

  @override
  bool addToExportScope(String name, Builder member, [int charOffset = -1]) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Builder existing =
        exportScope.lookupLocalMember(name, setter: member.isSetter);
    if (existing == member) {
      return false;
    } else {
      if (existing != null) {
        Builder result = computeAmbiguousDeclaration(
            name, existing, member, charOffset,
            isExport: true);
        exportScope.addLocalMember(name, result, setter: member.isSetter);
        return result != existing;
      } else {
        exportScope.addLocalMember(name, member, setter: member.isSetter);
        return true;
      }
    }
  }

  @override
  int finishDeferredLoadTearoffs() => 0;

  @override
  int finishForwarders() => 0;

  @override
  int finishNativeMethods() => 0;

  @override
  int finishPatchMethods() => 0;

  @override
  MemberBuilder getConstructor(String className,
      {String constructorName, bool bypassLibraryPrivacy: false}) {
    constructorName ??= "";
    if (constructorName.startsWith("_") && !bypassLibraryPrivacy) {
      return internalProblem(
          templateInternalProblemPrivateConstructorAccess
              .withArguments(constructorName),
          -1,
          null);
    }
    Builder cls = (bypassLibraryPrivacy ? scope : exportScope)
        .lookup(className, -1, null);
    if (cls is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = cls;
      // No type arguments are available, but this method is only called in
      // order to find constructors of specific non-generic classes (errors),
      // so we can pass the empty list.
      cls = aliasBuilder.unaliasDeclaration(const <TypeBuilder>[]);
    }
    if (cls is ClassBuilder) {
      // TODO(ahe): This code is similar to code in `endNewExpression` in
      // `body_builder.dart`, try to share it.
      MemberBuilder constructor =
          cls.findConstructorOrFactory(constructorName, -1, null, this);
      if (constructor == null) {
        // Fall-through to internal error below.
      } else if (constructor.isConstructor) {
        if (!cls.isAbstract) {
          return constructor;
        }
      } else if (constructor.isFactory) {
        return constructor;
      }
    }
    throw internalProblem(
        templateInternalProblemConstructorNotFound.withArguments(
            "$className.$constructorName", importUri),
        -1,
        null);
  }

  @override
  int finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType) => 0;

  @override
  int computeVariances() => 0;

  @override
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
    return 0;
  }

  @override
  void becomeCoreLibrary() {
    if (scope.lookupLocalMember("dynamic", setter: false) == null) {
      addSyntheticDeclarationOfDynamic();
    }
    if (scope.lookupLocalMember("Never", setter: false) == null) {
      addSyntheticDeclarationOfNever();
    }
    if (scope.lookupLocalMember("Null", setter: false) == null) {
      addSyntheticDeclarationOfNull();
    }
  }

  @override
  Builder lookupLocalMember(String name, {bool required: false}) {
    Builder builder = scope.lookupLocalMember(name, setter: false);
    if (required && builder == null) {
      internalProblem(
          templateInternalProblemNotFoundIn.withArguments(
              name, fullNameForErrors),
          -1,
          null);
    }
    return builder;
  }

  @override
  Builder lookup(String name, int charOffset, Uri fileUri) {
    return scope.lookup(name, charOffset, fileUri);
  }

  @override
  void applyPatches() {
    if (!isPatch) return;
    unsupported("${runtimeType}.applyPatches", -1, fileUri);
  }

  @override
  void recordAccess(int charOffset, int length, Uri fileUri) {}

  @override
  void buildOutlineExpressions() {}

  @override
  List<FieldBuilder> takeImplicitlyTypedFields() => null;

  @override
  Nullability get nullable {
    return isNonNullableByDefault ? Nullability.nullable : Nullability.legacy;
  }

  @override
  Nullability get nonNullable {
    return isNonNullableByDefault
        ? Nullability.nonNullable
        : Nullability.legacy;
  }

  @override
  Nullability nullableIfTrue(bool isNullable) {
    if (isNonNullableByDefault) {
      return isNullable ? Nullability.nullable : Nullability.nonNullable;
    }
    return Nullability.legacy;
  }

  @override
  NullabilityBuilder get nullableBuilder {
    return isNonNullableByDefault
        ? const NullabilityBuilder.nullable()
        : const NullabilityBuilder.omitted();
  }

  @override
  NullabilityBuilder get nonNullableBuilder {
    return const NullabilityBuilder.omitted();
  }

  @override
  NullabilityBuilder nullableBuilderIfTrue(bool isNullable) {
    return isNullable
        ? const NullabilityBuilder.nullable()
        : const NullabilityBuilder.omitted();
  }
}

class LibraryLocalDeclarationIterator implements Iterator<Builder> {
  final LibraryBuilder library;
  final Iterator<Builder> iterator;

  LibraryLocalDeclarationIterator(this.library)
      : iterator = library.scope.iterator;

  Builder get current => iterator.current;

  bool moveNext() {
    while (iterator.moveNext()) {
      if (current.parent == library) return true;
    }
    return false;
  }
}

class LibraryLocalDeclarationNameIterator implements NameIterator {
  final LibraryBuilder library;
  final NameIterator iterator;

  LibraryLocalDeclarationNameIterator(this.library)
      : iterator = library.scope.nameIterator;

  Builder get current => iterator.current;

  String get name => iterator.name;

  bool moveNext() {
    while (iterator.moveNext()) {
      if (current.parent == library) return true;
    }
    return false;
  }
}
