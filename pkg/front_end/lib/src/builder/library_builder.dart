// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;
import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart'
    show Importability;
import 'package:kernel/ast.dart' show Library, Version;

import '../base/export.dart' show Export;
import '../base/extension_scope.dart';
import '../base/loader.dart' show Loader;
import '../base/lookup_result.dart';
import '../base/messages.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        ProblemReporting,
        codeInternalProblemConstructorNotFound,
        codeInternalProblemNotFoundIn,
        codeInternalProblemPrivateConstructorAccess;
import '../base/name_space.dart';
import '../base/problems.dart' show internalProblem;
import '../source/name_scheme.dart';
import '../source/source_library_builder.dart';
import 'builder.dart';
import 'compilation_unit.dart';
import 'constructor_builder.dart';
import 'declaration_builders.dart';
import 'factory_builder.dart';
import 'member_builder.dart';
import 'type_builder.dart';

abstract class LibraryBuilder implements Builder, ProblemReporting {
  NameSpace get libraryNameSpace;

  /// Extensions declared in this library.
  Extensions get libraryExtensions;

  ComputedNameSpace get exportNameSpace;

  List<Export> get exporters;

  /// Returns the set of imports and exports of this library from other
  /// libraries.
  Iterable<LibraryAccess> get accessors;

  LibraryBuilder? get partOfLibrary;

  LibraryBuilder get nameOriginBuilder;

  bool get mayImplementRestrictedTypes;

  bool get isPart;

  Loader get loader;

  /// Returns the [Library] built by this builder.
  Library get library;

  LibraryName get libraryName;

  @override
  Uri get fileUri;

  /// Returns the [Uri]s for the libraries that this library depend upon, either
  /// through import or export.
  Iterable<Uri> get dependencies;

  /// Returns the import uri for the library.
  ///
  /// This is the canonical uri for the library, for instance 'dart:core'.
  Uri get importUri;

  /// Returns the language [Version] used for this library.
  Version get languageVersion;

  /// If false, the library is not supported through the 'dart.library.*' value
  /// used in conditional imports and `bool.fromEnvironment` constants.
  bool get conditionalImportSupported;

  /// Specifies when the library is importable on the target platform.
  ///
  /// If [importability] is [Importability.always], or is
  /// [Importability.withFlag] when the
  /// `--include-unsupported-platform-library-stubs` flag is specified, the
  /// library can be imported.
  ///
  /// If [importability] is [Importability.never], or is
  /// [Importability.withFlag] when
  /// `--include-unsupported-platform-library-stubs` is not specified, imports
  /// of this library will result in a compilation error.
  Importability get importability;

  /// [Iterator] for all declarations declared in this library of type [T].
  ///
  /// If [includeDuplicates] is `true`, duplicate declarations are included.
  Iterator<T> filteredMembersIterator<T extends NamedBuilder>({
    required bool includeDuplicates,
  });

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
  MemberBuilder getConstructor(String className, {String constructorName});

  void becomeCoreLibrary();

  /// Lookups the member [name] declared in this library.
  LookupResult? lookupLocalMember(String name);

  /// Lookups the required member [name] declared in this library.
  ///
  /// If no member is found an internal problem is reported.
  NamedBuilder lookupRequiredLocalMember(String name);

  /// Records the location of an import or export of this library from
  /// [accessor].
  void recordAccess(
    CompilationUnit accessor,
    int charOffset,
    int length,
    Uri fileUri,
  );

  /// Returns `true` if [typeDeclarationBuilder] is the 'Function' class defined
  /// in [coreLibrary].
  static bool isFunction(
    TypeDeclarationBuilder? typeDeclarationBuilder,
    LibraryBuilder coreLibrary,
  ) {
    return typeDeclarationBuilder is ClassBuilder &&
        typeDeclarationBuilder.name == 'Function' &&
        typeDeclarationBuilder.libraryBuilder == coreLibrary;
  }

  /// Returns `true` if [typeDeclarationBuilder] is the 'Record' class defined
  /// in [coreLibrary].
  static bool isRecord(
    TypeDeclarationBuilder? typeDeclarationBuilder,
    LibraryBuilder coreLibrary,
  ) {
    return typeDeclarationBuilder is ClassBuilder &&
        typeDeclarationBuilder.name == 'Record' &&
        typeDeclarationBuilder.libraryBuilder == coreLibrary;
  }
}

abstract class LibraryBuilderImpl extends BuilderImpl
    implements LibraryBuilder {
  @override
  final Uri fileUri;

  LibraryBuilderImpl(this.fileUri);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthetic => false;

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  int get fileOffset => -1;

  @override
  bool get isPart => false;

  @override
  Loader get loader;

  @override
  Uri get importUri;

  @override
  final List<LibraryAccess> accessors = <LibraryAccess>[];

  @override
  FormattedMessage? addProblem(
    Message message,
    int charOffset,
    int length,
    Uri? fileUri, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
    CfeSeverity? severity,
    bool problemOnLibrary = false,
  }) {
    fileUri ??= this.fileUri;

    return loader.addProblem(
      message,
      charOffset,
      length,
      fileUri,
      wasHandled: wasHandled,
      context: context,
      severity: severity,
      problemOnLibrary: true,
    );
  }

  @override
  MemberBuilder getConstructor(String className, {String? constructorName}) {
    constructorName ??= "";
    if (constructorName.startsWith("_")) {
      return internalProblem(
        codeInternalProblemPrivateConstructorAccess.withArgumentsOld(
          constructorName,
        ),
        -1,
        null,
      );
    }
    Builder? cls = exportNameSpace.lookup(className)?.getable;
    if (cls is TypeAliasBuilder) {
      // Coverage-ignore-block(suite): Not run.
      TypeAliasBuilder aliasBuilder = cls;
      // No type arguments are available, but this method is only called in
      // order to find constructors of specific non-generic classes (errors),
      // so we can pass the empty list.
      cls = aliasBuilder.unaliasDeclaration(const <TypeBuilder>[]);
    }
    if (cls is ClassBuilder) {
      // TODO(ahe): This code is similar to code in `endNewExpression` in
      // `body_builder.dart`, try to share it.
      MemberLookupResult? result = cls.findConstructorOrFactory(
        constructorName,
        this,
      );
      if (result != null && !result.isInvalidLookup) {
        MemberBuilder? constructor = result.getable;
        if (constructor == null) {
          // Fall-through to internal error below.
        } else if (constructor is ConstructorBuilder) {
          if (!cls.isAbstract) {
            return constructor;
          }
        }
        // Coverage-ignore(suite): Not run.
        else if (constructor is FactoryBuilder) {
          return constructor;
        }
      }
    }
    // Coverage-ignore-block(suite): Not run.
    throw internalProblem(
      codeInternalProblemConstructorNotFound.withArgumentsOld(
        "$className.$constructorName",
        importUri,
      ),
      -1,
      null,
    );
  }

  @override
  LookupResult? lookupLocalMember(String name) {
    return libraryNameSpace.lookup(name);
  }

  @override
  NamedBuilder lookupRequiredLocalMember(String name) {
    NamedBuilder? builder = libraryNameSpace.lookup(name)?.getable;
    if (builder == null) {
      internalProblem(
        codeInternalProblemNotFoundIn.withArgumentsOld(name, fullNameForErrors),
        -1,
        null,
      );
    }
    return builder;
  }

  @override
  void recordAccess(
    CompilationUnit accessor,
    int charOffset,
    int length,
    Uri fileUri,
  ) {
    accessors.add(new LibraryAccess(accessor, fileUri, charOffset, length));
  }

  @override
  String toString() {
    return '$runtimeType(${isPart ? fileUri : importUri})';
  }
}
