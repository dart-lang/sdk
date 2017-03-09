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

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';
import 'package:path/path.dart' as path;
import 'package:source_map_stack_trace/source_map_stack_trace.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';

typedef void ReadyCallback();

/// Global object DDC uses to see if a stack trace utility has been registered.
@JS(r'$dartStackTraceUtility')
external set dartStackTraceUtility(DartStackTraceUtility value);

typedef String StackTraceMapper(String stackTrace);
typedef dynamic LoadSourceMaps(List<String> scripts, ReadyCallback callback);

@JS()
@anonymous
class DartStackTraceUtility {
  external factory DartStackTraceUtility(
      {StackTraceMapper mapper, LoadSourceMaps loadSourceMaps});
}

/// Source mapping that is waits to parse source maps until they match the uri
/// of a requested source map.
///
/// This improves startup performance compared to using MappingBundle directly.
/// The unparsed data for the source maps must still be loaded before
/// LazyMapping is used.
class LazyMapping extends Mapping {
  MappingBundle _bundle = new MappingBundle();

  /// Map from url to unparsed source map.
  Map<String, String> _sourceMaps;

  LazyMapping(this._sourceMaps) {}

  List toJson() => _bundle.toJson();

  SourceMapSpan spanFor(int line, int column,
      {Map<String, SourceFile> files, String uri}) {
    if (uri == null) {
      throw new ArgumentError.notNull('uri');
    }
    var rawMap = _sourceMaps[uri];

    if (rawMap != null && rawMap.isNotEmpty && !_bundle.containsMapping(uri)) {
      SingleMapping mapping = parse(rawMap);
      mapping
        ..targetUrl = uri
        ..sourceRoot = '${path.dirname(uri)}/';
      _bundle.addMapping(mapping);
    }

    return _bundle.spanFor(line, column, files: files, uri: uri);
  }
}

String _toSourceMapLocation(String url) {
  // The url may have cache busting query parameters which we need to maintain
  // in the source map url.
  // For example:
  //   http://localhost/foo.js?cachebusting=23419
  // Should get source map
  //   http://localhost/foo.js.map?cachebusting=23419
  var uri = Uri.parse(url);
  return uri.replace(path: '${uri.path}.map').toString();
}

/// Load a source map for the specified url.
///
/// Returns a null string rather than reporting an error if the file cannot be
/// found as we don't want to throw errors if a few source maps are missing.
Future<String> loadSourceMap(String url) async {
  try {
    return await HttpRequest.getString(_toSourceMapLocation(url));
  } catch (e) {
    return null;
  }
}

LazyMapping _mapping;

String mapper(String rawStackTrace) {
  if (_mapping == null) {
    // This should not happen if the user has waited for the ReadyCallback
    // to start the application.
    throw new StateError('Source maps are not done loading.');
  }
  return mapStackTrace(_mapping, new Trace.parse(rawStackTrace)).toString();
}

Future<Null> loadSourceMaps(
    List<String> scripts, ReadyCallback callback) async {
  List<Future<String>> sourceMapFutures =
      scripts.map((script) => loadSourceMap(script)).toList();
  List<String> sourceMaps = await Future.wait(sourceMapFutures);
  _mapping = new LazyMapping(new Map.fromIterables(scripts, sourceMaps));
  callback();
}

main() {
  // Register with DDC.
  dartStackTraceUtility = new DartStackTraceUtility(
      mapper: allowInterop(mapper),
      loadSourceMaps: allowInterop(loadSourceMaps));
}
