// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Standalone utility that manages loading source maps for all Dart scripts
/// on the page compiled with DDC.
///
/// Example JavaScript usage:
/// $dartStackTraceUtility.addLoadedListener(function() {
///   // All Dart source maps are now loaded. It is now safe to start your
///   // Dart application compiled with DDC.
///   dart_library.start('your_dart_application');
/// })
///
/// If $dartStackTraceUtility is set, the dart:core StackTrace class calls
/// $dartStackTraceUtility.mapper(someJSStackTrace)
/// to apply source maps.
///
/// This utility can be compiled to JavaScript using Dart2JS while the rest
/// of the application is compiled with DDC or could be compiled with DDC.

@JS()
library stack_trace_mapper;

import 'package:js/js.dart';
import 'package:path/path.dart' as path;
import 'source_map_stack_trace.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';

typedef void ReadyCallback();

/// Global object DDC uses to see if a stack trace utility has been registered.
@JS(r'$dartStackTraceUtility')
external set dartStackTraceUtility(DartStackTraceUtility value);

@JS(r'$dartLoader.rootDirectories')
external List get rootDirectories;

typedef String StackTraceMapper(String stackTrace);
typedef dynamic SourceMapProvider(String modulePath);
typedef void SetSourceMapProvider(SourceMapProvider provider);

@JS()
@anonymous
class DartStackTraceUtility {
  external factory DartStackTraceUtility(
      {StackTraceMapper mapper, SetSourceMapProvider setSourceMapProvider});
}

@JS('JSON.stringify')
external String _stringify(dynamic json);

/// Source mapping that is waits to parse source maps until they match the uri
/// of a requested source map.
///
/// This improves startup performance compared to using MappingBundle directly.
/// The unparsed data for the source maps must still be loaded before
/// LazyMapping is used.
class LazyMapping extends Mapping {
  MappingBundle _bundle = new MappingBundle();
  SourceMapProvider _provider;

  LazyMapping(this._provider);

  List toJson() => _bundle.toJson();

  SourceMapSpan spanFor(int line, int column,
      {Map<String, SourceFile> files, String uri}) {
    if (uri == null) {
      throw new ArgumentError.notNull('uri');
    }

    if (!_bundle.containsMapping(uri)) {
      var rawMap = _provider(uri);
      if (rawMap != null) {
        if (rawMap is! String) {
          // The sourcemap was passed as regular JavaScript JSON.
          rawMap = _stringify(rawMap);
        }
        SingleMapping mapping = parse(rawMap);
        mapping
          ..targetUrl = uri
          ..sourceRoot = '${path.dirname(uri)}/';
        _bundle.addMapping(mapping);
      }
    }
    var span = _bundle.spanFor(line, column, files: files, uri: uri);
    // TODO(jacobr): we shouldn't have to filter out invalid sourceUrl entries
    // here.
    if (span == null || span.start.sourceUrl == null) return null;
    var pathSegments = span.start.sourceUrl.pathSegments;
    if (pathSegments.isNotEmpty && pathSegments.last == 'null') return null;
    return span;
  }
}

LazyMapping _mapping;

List<String> roots = rootDirectories.map((s) => '$s').toList();

String mapper(String rawStackTrace) {
  if (_mapping == null) {
    // This should not happen if the user has waited for the ReadyCallback
    // to start the application.
    throw new StateError('Source maps are not done loading.');
  }
  var trace = new Trace.parse(rawStackTrace);
  return mapStackTrace(_mapping, trace, roots: roots).toString();
}

void setSourceMapProvider(SourceMapProvider provider) {
  _mapping = new LazyMapping(provider);
}

main() {
  // Register with DDC.
  dartStackTraceUtility = new DartStackTraceUtility(
      mapper: allowInterop(mapper),
      setSourceMapProvider: allowInterop(setSourceMapProvider));
}
