// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/builder/property_builder.dart';
import 'package:kernel/ast.dart' show LibraryDependency;

import '../base/combinator.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../kernel/load_library_builder.dart' show LoadLibraryBuilder;
import '../kernel/utils.dart';
import '../source/source_library_builder.dart';
import 'builder.dart';
import 'compilation_unit.dart';
import 'declaration_builders.dart';

class PrefixBuilder extends NamedBuilderImpl
    with LookupResultMixin
    implements LookupResult {
  @override
  final String name;

  final ComputedMutableNameSpace _prefixNameSpace =
      new ComputedMutableNameSpace();

  late final LookupScope _prefixScope = new NameSpaceLookupScope(
    _prefixNameSpace,
    ScopeKind.library,
  );

  @override
  final SourceLibraryBuilder parent;

  final bool deferred;

  @override
  final Uri fileUri;

  @override
  final int fileOffset;

  final LoadLibraryBuilder? loadLibraryBuilder;

  final bool isWildcard;

  PrefixBuilder(
    this.name,
    this.deferred,
    this.parent,
    this.loadLibraryBuilder, {
    required this.fileUri,
    required int prefixOffset,
    required int importOffset,
  }) : fileOffset = prefixOffset,
       isWildcard = name == '_' {
    assert(
      deferred == (loadLibraryBuilder != null),
      "LoadLibraryBuilder must be provided iff prefix is deferred.",
    );
    if (loadLibraryBuilder != null) {
      addToPrefixScope(
        loadLibraryBuilder!.name,
        loadLibraryBuilder!,
        importOffset: importOffset,
        prefixOffset: prefixOffset,
      );
    }
  }

  LookupScope get prefixScope => _prefixScope;

  void forEachExtension(void Function(ExtensionBuilder) f) {
    _prefixNameSpace.forEachLocalExtension(f);
  }

  LibraryDependency? get dependency => loadLibraryBuilder?.importDependency;

  /// Lookup a member with [name] in the export scope.
  LookupResult? lookup(String name) {
    return _prefixScope.lookup(name);
  }

  void addToPrefixScope(
    String name,
    NamedBuilder member, {
    required int importOffset,
    required int prefixOffset,
  }) {
    if (deferred && member is ExtensionBuilder) {
      parent.addProblem(
        codeDeferredExtensionImport.withArgumentsOld(name),
        importOffset,
        noLength,
        fileUri,
      );
    }

    bool isSetter = isMappedAsSetter(member);

    LookupResult? existingResult = _prefixNameSpace.lookup(name);
    NamedBuilder? existing = isSetter
        ? existingResult?.setable
        : existingResult?.getable;
    if (existing != null) {
      NamedBuilder result = computeAmbiguousDeclarationForImport(
        parent,
        name,
        existing,
        member,
        uriOffset: new UriOffset(fileUri, prefixOffset),
      );
      _prefixNameSpace.replaceLocalMember(name, result, setter: isSetter);
    } else {
      _prefixNameSpace.addLocalMember(name, member, setter: isSetter);
    }
    if (member is ExtensionBuilder) {
      _prefixNameSpace.addExtension(member);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => name;

  @override
  NamedBuilder get getable => this;

  @override
  NamedBuilder? get setable => null;
}

class PrefixFragment {
  final String name;
  final SourceCompilationUnit importer;
  final CompilationUnit? imported;
  final List<CombinatorBuilder>? combinators;
  final bool deferred;
  final Uri fileUri;
  final int importOffset;
  final int prefixOffset;

  PrefixBuilder? _builder;

  PrefixFragment({
    required this.name,
    required this.importer,
    required this.imported,
    required this.combinators,
    required this.deferred,
    required this.fileUri,
    required this.importOffset,
    required this.prefixOffset,
  });

  PrefixBuilder createPrefixBuilder() {
    LoadLibraryBuilder? loadLibraryBuilder;
    if (deferred) {
      loadLibraryBuilder = new LoadLibraryBuilder(
        importer.libraryBuilder,
        prefixOffset,
        imported!,
        name,
        importOffset,
        toCombinators(combinators),
      );
    }

    return builder = new PrefixBuilder(
      name,
      deferred,
      importer.libraryBuilder,
      loadLibraryBuilder,
      fileUri: fileUri,
      prefixOffset: prefixOffset,
      importOffset: importOffset,
    );
  }

  PrefixBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(PrefixBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$importOffset)';
}
