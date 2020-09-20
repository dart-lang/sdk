// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';

MicroContextObjects createMicroContextObjects({
  @required FileResolver fileResolver,
  @required AnalysisOptionsImpl analysisOptions,
  @required SourceFactory sourceFactory,
  @required ContextRootImpl root,
  @required ResourceProvider resourceProvider,
  @required Workspace workspace,
}) {
  var declaredVariables = DeclaredVariables();
  var synchronousSession = SynchronousSession(
    analysisOptions,
    declaredVariables,
  );

  var analysisContext = AnalysisContextImpl(
    synchronousSession,
    sourceFactory,
  );

  var analysisSession = _MicroAnalysisSessionImpl(
    declaredVariables,
    sourceFactory,
  );

  var analysisContext2 = _MicroAnalysisContextImpl(
    fileResolver,
    synchronousSession,
    root,
    declaredVariables,
    sourceFactory,
    resourceProvider,
    workspace: workspace,
  );

  analysisContext2.currentSession = analysisSession;
  analysisSession.analysisContext = analysisContext2;

  return MicroContextObjects(
    declaredVariables: declaredVariables,
    synchronousSession: synchronousSession,
    analysisSession: analysisSession,
    analysisContext: analysisContext,
    analysisContext2: analysisContext2,
  );
}

class MicroContextObjects {
  final DeclaredVariables declaredVariables;
  final SynchronousSession synchronousSession;
  final _MicroAnalysisSessionImpl analysisSession;
  final AnalysisContextImpl analysisContext;
  final _MicroAnalysisContextImpl analysisContext2;

  MicroContextObjects({
    @required this.declaredVariables,
    @required this.synchronousSession,
    @required this.analysisSession,
    @required this.analysisContext,
    @required this.analysisContext2,
  });

  set analysisOptions(AnalysisOptionsImpl analysisOptions) {
    synchronousSession.analysisOptions = analysisOptions;
  }

  InheritanceManager3 get inheritanceManager {
    return analysisSession.inheritanceManager;
  }
}

class _MicroAnalysisContextImpl implements AnalysisContext {
  final FileResolver fileResolver;
  final SynchronousSession synchronousSession;

  final ResourceProvider resourceProvider;

  @override
  final ContextRoot contextRoot;

  @override
  _MicroAnalysisSessionImpl currentSession;

  final DeclaredVariables declaredVariables;
  final SourceFactory sourceFactory;

  Workspace _workspace;

  _MicroAnalysisContextImpl(
    this.fileResolver,
    this.synchronousSession,
    this.contextRoot,
    this.declaredVariables,
    this.sourceFactory,
    this.resourceProvider, {
    Workspace workspace,
  }) : _workspace = workspace;

  @override
  AnalysisOptionsImpl get analysisOptions {
    return synchronousSession.analysisOptions;
  }

  @override
  Workspace get workspace {
    return _workspace ??= _buildWorkspace();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Workspace _buildWorkspace() {
    String path = contextRoot.root.path;
    ContextBuilder builder = ContextBuilder(
        resourceProvider, null /* sdkManager */, null /* contentCache */);
    return ContextBuilder.createWorkspace(resourceProvider, path, builder);
  }
}

class _MicroAnalysisSessionImpl extends AnalysisSessionImpl {
  @override
  final DeclaredVariables declaredVariables;

  final SourceFactory sourceFactory;

  @override
  _MicroAnalysisContextImpl analysisContext;

  _MicroAnalysisSessionImpl(
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
    return analysisContext.fileResolver.resolve(path: path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
