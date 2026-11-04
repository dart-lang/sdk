// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/builder/property_builder.dart';
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart' show LibraryDependency;

import '../base/combinator.dart';
import '../base/extension_scope.dart';
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
  final UriOffsetName _uriOffsetName;

  @override
  final String name;

  final ComputedMutableNameSpace _prefixNameSpace =
      new ComputedMutableNameSpace();

  final ExtensionsBuilder _prefixExtensions = new ExtensionsBuilder();

  /// The [PrefixBuilder] of the same name declared in an ancestor compilation
  /// unit, if any.
  final PrefixBuilder? parentPrefixBuilder;

  late final LookupScope _prefixScope = new NameSpaceLookupScope(
    _prefixNameSpace,
    parent: parentPrefixBuilder?.prefixScope,
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

  new(
    this.name,
    this.deferred,
    this.parent,
    this.loadLibraryBuilder, {
    required this._uriOffsetName,
    required this.fileUri,
    required int prefixOffset,
    required int importOffset,
    required this.parentPrefixBuilder,
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
        prefixUriOffset: _uriOffsetName,
        prefixOffset: prefixOffset,
      );
    }
  }

  LookupScope get prefixScope => _prefixScope;

  void forEachExtension(void Function(ExtensionBuilder) f) {
    _prefixExtensions.forEachLocalExtension(f);
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
    required UriOffsetLength prefixUriOffset,
    required int prefixOffset,
  }) {
    if (deferred && member is ExtensionBuilder) {
      parent.addProblem(
        diag.deferredExtensionImport.withArguments(extensionName: name),
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
        uriOffset: prefixUriOffset,
      );
      _prefixNameSpace.replaceLocalMember(name, result, setter: isSetter);
    } else {
      _prefixNameSpace.addLocalMember(name, member, setter: isSetter);
    }
    if (member is ExtensionBuilder) {
      _prefixExtensions.addExtension(member);
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
  final SourceCompilationUnit importer;
  final CompilationUnit? imported;
  final List<CombinatorBuilder>? combinators;
  final bool deferred;
  final UriOffsetLength importUriOffset;
  final UriOffsetName _prefixUriOffsetName;

  PrefixBuilder? _builder;

  new({
    required this.importer,
    required this.imported,
    required this.combinators,
    required this.deferred,
    required this.importUriOffset,
    required this._prefixUriOffsetName,
  });

  Uri get fileUri => importUriOffset.fileUri;
  int get importOffset => importUriOffset.fileOffset;

  UriOffsetLength get uriOffset => _prefixUriOffsetName;

  String get name => _prefixUriOffsetName.name;

  int get prefixOffset => _prefixUriOffsetName.nameOffset;

  PrefixBuilder createPrefixBuilder(PrefixBuilder? parentPrefixBuilder) {
    LoadLibraryBuilder? loadLibraryBuilder;
    if (deferred) {
      assert(parentPrefixBuilder == null, "Deferred prefixes do not nest.");
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
      uriOffsetName: _prefixUriOffsetName,
      prefixOffset: prefixOffset,
      importOffset: importOffset,
      parentPrefixBuilder: parentPrefixBuilder,
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
