// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptions;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/workspace/workspace.dart';

class MicroAnalysisContextImpl implements AnalysisContext {
  final FileResolver fileResolver;

  @override
  final AnalysisOptions analysisOptions;

  final ResourceProvider resourceProvider;

  @override
  final ContextRoot contextRoot;

  final DeclaredVariables declaredVariables;
  final SourceFactory sourceFactory;

  Workspace _workspace;

  MicroAnalysisContextImpl(
      this.fileResolver,
      this.contextRoot,
      this.analysisOptions,
      this.declaredVariables,
      this.sourceFactory,
      this.resourceProvider,
      {Workspace workspace})
      : this._workspace = workspace;

  @override
  AnalysisSession get currentSession {
    return _AnalysisSessionImpl(this, declaredVariables, sourceFactory);
  }

  @override
  Workspace get workspace {
    return _workspace ??= _buildWorkspace();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Workspace _buildWorkspace() {
    String path = contextRoot.root.path;
    ContextBuilder builder = ContextBuilder(
        resourceProvider, null /* sdkManager */, null /* contentCache */);
    return ContextBuilder.createWorkspace(resourceProvider, path, builder);
  }
}

class _AnalysisSessionImpl extends AnalysisSessionImpl {
  @override
  final MicroAnalysisContextImpl analysisContext;

  @override
  final DeclaredVariables declaredVariables;

  @override
  SourceFactory sourceFactory;

  _AnalysisSessionImpl(
    this.analysisContext,
    this.declaredVariables,
    this.sourceFactory,
  ) : super(null);

  @override
  ResourceProvider get resourceProvider =>
      analysisContext.contextRoot.resourceProvider;

  @override
  UriConverter get uriConverter {
    return _UriConverterImpl(
      analysisContext.contextRoot.resourceProvider,
      sourceFactory,
    );
  }

  @override
  FileResult getFile(String path) {
    return FileResultImpl(
      this,
      path,
      uriConverter.pathToUri(path),
      null,
      false,
    );
  }

  @override
  Future<ResolvedLibraryResult> getResolvedLibrary(String path) async {
    var resolvedUnit = await getResolvedUnit(path);
    return ResolvedLibraryResultImpl(
      this,
      path,
      resolvedUnit.uri,
      resolvedUnit.libraryElement,
      [resolvedUnit],
    );
  }

  @override
  Future<ResolvedUnitResult> getResolvedUnit(String path) async {
    return analysisContext.fileResolver.resolve(path);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UriConverterImpl implements UriConverter {
  final ResourceProvider resourceProvider;
  final SourceFactory sourceFactory;

  _UriConverterImpl(this.resourceProvider, this.sourceFactory);

  @override
  Uri pathToUri(String path, {String containingPath}) {
    var fileUri = resourceProvider.pathContext.toUri(path);
    var fileSource = sourceFactory.forUri2(fileUri);
    return sourceFactory.restoreUri(fileSource);
  }

  @override
  String uriToPath(Uri uri) {
    return sourceFactory.forUri2(uri)?.fullName;
  }
}
