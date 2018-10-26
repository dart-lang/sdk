// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';

/// This class is a temporary step toward migrating Analyzer clients to the
/// new API.  It guards against attempts to use any [AnalysisContext]
/// functionality (which is task based), except what we intend to expose
/// through the new API.
class RestrictedAnalysisContext implements AnalysisContextImpl {
  final FileSystemState _fsState;

  @override
  final AnalysisOptionsImpl analysisOptions;

  @override
  final DeclaredVariables declaredVariables;

  @override
  final SourceFactory sourceFactory;

  final ContentCache _contentCache;

  TypeProvider _typeProvider;

  TypeSystem _typeSystem;

  RestrictedAnalysisContext(this._fsState, this.analysisOptions,
      this.declaredVariables, this.sourceFactory)
      : _contentCache = _ContentCacheWrapper(_fsState);

  @override
  TypeProvider get typeProvider => _typeProvider;

  @override
  set typeProvider(TypeProvider typeProvider) {
    if (_typeProvider != null) {
      throw StateError('TypeProvider can be set only once.');
    }
    _typeProvider = typeProvider;
  }

  @override
  TypeSystem get typeSystem {
    return _typeSystem ??= StrongTypeSystemImpl(
      typeProvider,
      declarationCasts: analysisOptions.declarationCasts,
      implicitCasts: analysisOptions.implicitCasts,
    );
  }

  @override
  TimestampedData<String> getContents(Source source) {
    // TODO(scheglov) We want to get rid of this method.
    // We need it temporary until Analysis Server migrated to ResolveResult.
    String contents = _contentCache.getContents(source);
    if (contents != null) {
      return TimestampedData<String>(0, contents);
    }
    return source.contents;
  }

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  CompilationUnit parseCompilationUnit(Source source) {
    // TODO(scheglov) We want to get rid of this method.
    // We need it temporary until Analysis Server migrated to ResolveResult.
    var file = _fsState.getFileForPath(source.fullName);
    return file.parse();
  }
}

/// [ContentCache] wrapper around [FileContentOverlay].
class _ContentCacheWrapper implements ContentCache {
  final FileSystemState fsState;

  _ContentCacheWrapper(this.fsState);

  @override
  void accept(ContentCacheVisitor visitor) {
    throw new UnimplementedError();
  }

  @override
  String getContents(Source source) {
    return _getFileForSource(source).content;
  }

  @override
  bool getExists(Source source) {
    throw new UnimplementedError();
  }

  @override
  int getModificationStamp(Source source) {
    throw new UnimplementedError();
  }

  @override
  String setContents(Source source, String contents) {
    throw new UnimplementedError();
  }

  FileState _getFileForSource(Source source) {
    String path = source.fullName;
    return fsState.getFileForPath(path);
  }
}
