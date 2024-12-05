// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.prefix_builder;

import 'package:kernel/ast.dart' show LibraryDependency;

import '../base/combinator.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../kernel/load_library_builder.dart' show LoadLibraryBuilder;
import '../kernel/utils.dart';
import '../source/source_library_builder.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';

class PrefixBuilder extends BuilderImpl {
  final String name;

  final NameSpace _prefixNameSpace = new NameSpaceImpl();

  late final LookupScope _prefixScope =
      new NameSpaceLookupScope(_prefixNameSpace, ScopeKind.library, "top");

  @override
  final SourceLibraryBuilder parent;

  final bool deferred;

  @override
  final Uri fileUri;

  @override
  final int charOffset;

  final LoadLibraryBuilder? loadLibraryBuilder;

  final bool isWildcard;

  PrefixBuilder(this.name, this.deferred, this.parent, this.loadLibraryBuilder,
      {required this.fileUri,
      required int prefixOffset,
      required int importOffset})
      : charOffset = prefixOffset,
        isWildcard = name == '_' {
    assert(deferred == (loadLibraryBuilder != null),
        "LoadLibraryBuilder must be provided iff prefix is deferred.");
    if (loadLibraryBuilder != null) {
      addToPrefixScope('loadLibrary', loadLibraryBuilder!,
          importOffset: importOffset, prefixOffset: prefixOffset);
    }
  }

  LookupScope get prefixScope => _prefixScope;

  void forEachExtension(void Function(ExtensionBuilder) f) {
    _prefixNameSpace.forEachLocalExtension(f);
  }

  LibraryDependency? get dependency => loadLibraryBuilder?.importDependency;

  /// Lookup a member with [name] in the export scope.
  Builder? lookup(String name, int charOffset, Uri fileUri) {
    return _prefixScope.lookupGetable(name, charOffset, fileUri);
  }

  void addToPrefixScope(String name, Builder member,
      {required int importOffset, required int prefixOffset}) {
    if (deferred && member is ExtensionBuilder) {
      parent.addProblem(templateDeferredExtensionImport.withArguments(name),
          importOffset, noLength, fileUri);
    }

    Builder? existing =
        _prefixNameSpace.lookupLocalMember(name, setter: member.isSetter);
    Builder result;
    if (existing != null) {
      result = computeAmbiguousDeclarationForImport(
          parent, name, existing, member,
          uriOffset: new UriOffset(fileUri, prefixOffset));
    } else {
      result = member;
    }
    _prefixNameSpace.addLocalMember(name, result, setter: member.isSetter);
    if (member is ExtensionBuilder) {
      _prefixNameSpace.addExtension(member);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => name;
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
          toKernelCombinators(combinators));
    }

    return builder = new PrefixBuilder(
        name, deferred, importer.libraryBuilder, loadLibraryBuilder,
        fileUri: fileUri,
        prefixOffset: prefixOffset,
        importOffset: importOffset);
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
