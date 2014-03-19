// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility functions to test the code generation tools with the resolver.
// Note, this is just for simple tests, so we restricted the logic to only
// support root-relative imports. For more sophisticated stuff, you should be
// using the test helpers in `package:code_transformers`.
library smoke.test.codegen.testing_resolver_utils;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:code_transformers/tests.dart' show testingDartSdkDirectory;

class LibraryProvider {
  final AnalysisContext _analyzer;
  final Map<String, Source> _allSources;
  LibraryProvider(this._analyzer, this._allSources);
  LibraryElement libraryFor(String uri) =>
      _analyzer.computeLibraryElement(_allSources[uri]);
}

LibraryProvider initAnalyzer(Map<String, String> contents) {
  var analyzer = AnalysisEngine.instance.createAnalysisContext();
  var options = new AnalysisOptionsImpl()
      ..cacheSize = 256
      ..preserveComments = false
      ..analyzeFunctionBodies = false;
  analyzer.analysisOptions = options;
  var sdk = new DirectoryBasedDartSdk(new JavaFile(testingDartSdkDirectory));
  sdk.context.analysisOptions = options;
  var changes = new ChangeSet();
  var allSources = {};
  contents.forEach((url, code) { 
    var source = new _SimpleSource(url, code, allSources);
    allSources[url] = source;
    changes.addedSource(source);
  });
  analyzer.applyChanges(changes);

  analyzer.sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      new _SimpleUriResolver(allSources)]);

  return new LibraryProvider(analyzer, allSources);
}

class _SimpleUriResolver implements UriResolver {
  final Map<String, Source> allSources;
  _SimpleUriResolver(this.allSources);

  Source resolveAbsolute(Uri uri) => allSources['$uri'];

  Source fromEncoding(UriKind kind, Uri uri) =>
      throw new UnimplementedError('fromEncoding not implemented');

  Uri restoreAbsolute(Source source) =>
      throw new UnimplementedError('restoreAbsolute not implemented');
}

class _SimpleSource extends Source {
  final String path;
  final String rawContents;
  final Map<String, Source> allSources;

  _SimpleSource(this.path, this.rawContents, this.allSources);

  operator ==(other) => other is _SimpleSource &&
      rawContents == other.rawContents;
  int get hashCode => rawContents.hashCode;

  bool exists() => true;
  String get encoding => '$uriKind/$path';
  String get fullName => path;
  TimestampedData<String> get contents =>
      new TimestampedData<String>(modificationStamp, rawContents);

  int get modificationStamp => 1;
  String get shortName => path;
  UriKind get uriKind => UriKind.FILE_URI;
  final bool isInSystemLibrary = false;

  // Since this is just for simple tests we just restricted this mock
  // to root-relative imports. For more sophisticated stuff, you should be
  // using the test helpers in `package:code_transformers`.
  Source resolveRelative(Uri uri) {
    if (uri.path.startsWith('/')) return allSources['${uri.path}'];
    throw new UnimplementedError('relative URIs not supported: $uri');
  }

  void getContentsToReceiver(Source_ContentReceiver receiver) {
    receiver.accept(rawContents, modificationStamp);
  }
}
