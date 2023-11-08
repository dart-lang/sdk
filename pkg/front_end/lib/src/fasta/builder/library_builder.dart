// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_builder;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' show Class, Library, Nullability;

import '../combinator.dart' show CombinatorBuilder;

import '../problems.dart' show internalProblem;

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
import 'declaration_builders.dart';
import 'member_builder.dart';
import 'modifier_builder.dart';
import 'name_iterator.dart';
import 'nullability_builder.dart';
import 'prefix_builder.dart';
import 'type_builder.dart';

abstract class LibraryBuilder implements ModifierBuilder {
  Scope get scope;

  Scope get exportScope;

  List<Export> get exporters;

  @override
  LibraryBuilder get origin;

  abstract LibraryBuilder? partOfLibrary;

  LibraryBuilder get nameOriginBuilder;

  abstract bool mayImplementRestrictedTypes;

  bool get isPart;

  Loader get loader;

  /// Returns the [Library] built by this builder.
  Library get library;

  @override
  Uri get fileUri;

  /// Returns the [Uri]s for the libraries that this library depend upon, either
  /// through import or export.
  Iterable<Uri> get dependencies;

  /// Returns the import uri for the library.
  ///
  /// This is the canonical uri for the library, for instance 'dart:core'.
  Uri get importUri;

  /// If true, the library is not supported through the 'dart.library.*' value
  /// used in conditional imports and `bool.fromEnvironment` constants.
  bool get isUnsupported;

  /// Returns an iterator of all members (typedefs, classes and members)
  /// declared in this library, including duplicate declarations.
  // TODO(johnniwinther): Should the only exist on [SourceLibraryBuilder]?
  Iterator<Builder> get localMembersIterator;

  /// Returns an iterator of all members of specified type
  /// declared in this library, including duplicate declarations.
  // TODO(johnniwinther): Should the only exist on [SourceLibraryBuilder]?
  Iterator<T> localMembersIteratorOfType<T extends Builder>();

  /// Returns an iterator of all members (typedefs, classes and members)
  /// declared in this library, including duplicate declarations.
  ///
  /// Compared to [localMembersIterator] this also gives access to the name
  /// that the builders are mapped to.
  NameIterator<Builder> get localMembersNameIterator;

  /// [Iterator] for all declarations declared in this library or any of its
  /// augmentations.
  ///
  /// Duplicates and augmenting members are _not_ included.
  Iterator<T> fullMemberIterator<T extends Builder>();

  /// [NameIterator] for all declarations declared in this class or any of its
  /// augmentations.
  ///
  /// Duplicates and augmenting members are _not_ included.
  NameIterator<T> fullMemberNameIterator<T extends Builder>();

  void addExporter(LibraryBuilder exporter,
      List<CombinatorBuilder>? combinators, int charOffset);

  /// Add a problem with a severity determined by the severity of the message.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  ///
  /// See `Loader.addMessage` for an explanation of the
  /// arguments passed to this method.
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false});

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Builder member, [int charOffset = -1]);

  void addToScope(String name, Builder member, int charOffset, bool isImport);

  Builder computeAmbiguousDeclaration(
      String name, Builder declaration, Builder other, int charOffset,
      {bool isExport = false, bool isImport = false});

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
      {String constructorName, bool bypassLibraryPrivacy = false});

  void becomeCoreLibrary();

  void addSyntheticDeclarationOfDynamic();

  void addSyntheticDeclarationOfNever();

  void addSyntheticDeclarationOfNull();

  /// Lookups the member [name] declared in this library.
  ///
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  Builder? lookupLocalMember(String name, {bool required = false});

  Builder? lookup(String name, int charOffset, Uri fileUri);

  void recordAccess(
      LibraryBuilder accessor, int charOffset, int length, Uri fileUri);

  bool get isNonNullableByDefault;

  Nullability get nullable;

  Nullability get nonNullable;

  Nullability nullableIfTrue(bool isNullable);

  NullabilityBuilder get nullableBuilder;

  NullabilityBuilder get nonNullableBuilder;

  NullabilityBuilder nullableBuilderIfTrue(bool isNullable);

  /// Returns `true` if [cls] is the 'Function' class defined in [coreLibrary].
  static bool isFunction(Class cls, LibraryBuilder coreLibrary) {
    return cls.name == 'Function' && _isCoreClass(cls, coreLibrary);
  }

  /// Returns `true` if [cls] is the 'Record' class defined in [coreLibrary].
  static bool isRecord(Class cls, LibraryBuilder coreLibrary) {
    return cls.name == 'Record' && _isCoreClass(cls, coreLibrary);
  }

  /// Returns `true` if [cls] is the 'Object' class defined in [coreLibrary].
  static bool isObject(Class cls, LibraryBuilder coreLibrary) {
    return cls.name == 'Object' && _isCoreClass(cls, coreLibrary);
  }

  static bool _isCoreClass(Class cls, LibraryBuilder coreLibrary) {
    // We use `superclass.parent` here instead of
    // `superclass.enclosingLibrary` to handle platform compilation. If
    // we are currently compiling the platform, the enclosing library of
    // the core class has not yet been set, so the accessing
    // `enclosingLibrary` would result in a cast error. We assume that the
    // SDK does not contain this error, which we otherwise not find. If we
    // are _not_ compiling the platform, the `superclass.parent` has been
    // set, if it is a class from `dart:core`.
    if (cls.parent == coreLibrary.library) {
      return true;
    }
    return false;
  }
}

abstract class LibraryBuilderImpl extends ModifierBuilderImpl
    implements LibraryBuilder {
  @override
  final Scope scope;

  @override
  final Scope exportScope;

  @override
  final List<Export> exporters = <Export>[];

  @override
  final Uri fileUri;

  @override
  LibraryBuilder? partOfLibrary;

  @override
  bool mayImplementRestrictedTypes = false;

  LibraryBuilderImpl(this.fileUri, this.scope, this.exportScope)
      : super(null, -1);

  @override
  bool get isSynthetic => false;

  @override
  Builder? get parent => null;

  @override
  bool get isPart => false;

  @override
  String get debugName => "$runtimeType";

  @override
  Loader get loader;

  @override
  int get modifiers => 0;

  @override
  Uri get importUri;

  @override
  Iterator<Builder> get localMembersIterator {
    return scope.filteredIterator(
        parent: this, includeDuplicates: true, includeAugmentations: true);
  }

  @override
  Iterator<T> localMembersIteratorOfType<T extends Builder>() {
    return scope.filteredIterator<T>(
        parent: this, includeDuplicates: true, includeAugmentations: true);
  }

  @override
  NameIterator<Builder> get localMembersNameIterator {
    return scope.filteredNameIterator(
        parent: this, includeDuplicates: true, includeAugmentations: true);
  }

  @override
  void addExporter(LibraryBuilder exporter,
      List<CombinatorBuilder>? combinators, int charOffset) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  @override
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false}) {
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
    Builder? existing =
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
  MemberBuilder getConstructor(String className,
      {String? constructorName, bool bypassLibraryPrivacy = false}) {
    constructorName ??= "";
    if (constructorName.startsWith("_") && !bypassLibraryPrivacy) {
      return internalProblem(
          templateInternalProblemPrivateConstructorAccess
              .withArguments(constructorName),
          -1,
          null);
    }
    Builder? cls = (bypassLibraryPrivacy ? scope : exportScope)
        .lookup(className, -1, fileUri);
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
      MemberBuilder? constructor =
          cls.findConstructorOrFactory(constructorName, -1, fileUri, this);
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
  Builder? lookupLocalMember(String name, {bool required = false}) {
    Builder? builder = scope.lookupLocalMember(name, setter: false);
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
  Builder? lookup(String name, int charOffset, Uri fileUri) {
    return scope.lookup(name, charOffset, fileUri);
  }

  @override
  void recordAccess(
      LibraryBuilder accessor, int charOffset, int length, Uri fileUri) {}

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

  @override
  StringBuffer printOn(StringBuffer buffer) {
    return buffer..write(isPart || isPatch ? fileUri : importUri);
  }
}
