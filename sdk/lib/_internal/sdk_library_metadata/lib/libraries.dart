// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The package:analyzer parse of the `libraries` field depends on the current
// use of const.
// ignore_for_file: unnecessary_const

/// Mapping of "dart:" library name (e.g. "core") to information about that
/// library.
const Map<String, LibraryInfo> libraries = const {
  'async': const LibraryInfo(
    'async/async.dart',
  ),
  'collection': const LibraryInfo(
    'collection/collection.dart',
  ),
  'convert': const LibraryInfo(
    'convert/convert.dart',
  ),
  'core': const LibraryInfo(
    'core/core.dart',
  ),
  'developer': const LibraryInfo(
    'developer/developer.dart',
  ),
  'ffi': const LibraryInfo(
    'ffi/ffi.dart',
  ),
  'html': const LibraryInfo(
    'html/dart2js/html_dart2js.dart',
  ),
  'html_common': const LibraryInfo(
    'html/html_common/html_common_dart2js.dart',
    documented: false,
    implementation: false,
  ),
  'indexed_db': const LibraryInfo(
    'indexed_db/dart2js/indexed_db_dart2js.dart',
  ),
  '_http': const LibraryInfo(
    '_http/http.dart',
    documented: false,
  ),
  'io': const LibraryInfo(
    'io/io.dart',
  ),
  'isolate': const LibraryInfo(
    'isolate/isolate.dart',
  ),
  'js': const LibraryInfo(
    'js/js.dart',
  ),
  '_js': const LibraryInfo(
    'js/_js.dart',
    documented: false,
  ),
  'js_interop': const LibraryInfo(
    'js_interop/js_interop.dart',
  ),
  'js_interop_unsafe': const LibraryInfo(
    'js_interop_unsafe/js_interop_unsafe.dart',
  ),
  'js_util': const LibraryInfo(
    'js_util/js_util.dart',
  ),
  'math': const LibraryInfo(
    'math/math.dart',
  ),
  'mirrors': const LibraryInfo(
    'mirrors/mirrors.dart',
  ),
  'nativewrappers': const LibraryInfo(
    'html/dartium/nativewrappers.dart',
    documented: false,
    implementation: false,
  ),
  'typed_data': const LibraryInfo(
    'typed_data/typed_data.dart',
  ),
  '_native_typed_data': const LibraryInfo(
    '_internal/js_runtime/lib/native_typed_data.dart',
    documented: false,
    implementation: true,
  ),
  'cli': const LibraryInfo(
    'cli/cli.dart',
  ),
  'svg': const LibraryInfo(
    'svg/dart2js/svg_dart2js.dart',
  ),
  'web_audio': const LibraryInfo(
    'web_audio/dart2js/web_audio_dart2js.dart',
  ),
  'web_gl': const LibraryInfo(
    'web_gl/dart2js/web_gl_dart2js.dart',
  ),
  '_internal': const LibraryInfo(
    'internal/internal.dart',
    documented: false,
  ),
  '_js_helper': const LibraryInfo(
    '_internal/js_runtime/lib/js_helper.dart',
    documented: false,
  ),
  '_late_helper': const LibraryInfo(
    '_internal/js_runtime/lib/late_helper.dart',
    documented: false,
  ),
  '_rti': const LibraryInfo(
    '_internal/js_shared/lib/rti.dart',
    documented: false,
  ),
  '_dart2js_runtime_metrics': const LibraryInfo(
    '_internal/js_runtime/lib/dart2js_runtime_metrics.dart',
    documented: false,
  ),
  '_interceptors': const LibraryInfo(
    '_internal/js_runtime/lib/interceptors.dart',
    documented: false,
  ),
  '_foreign_helper': const LibraryInfo(
    '_internal/js_runtime/lib/foreign_helper.dart',
    documented: false,
  ),
  '_js_names': const LibraryInfo(
    '_internal/js_runtime/lib/js_names.dart',
    documented: false,
  ),
  '_js_primitives': const LibraryInfo(
    '_internal/js_runtime/lib/js_primitives.dart',
    documented: false,
  ),
  '_js_embedded_names': const LibraryInfo(
    '_internal/js_runtime/lib/synced/embedded_names.dart',
    documented: false,
  ),
  '_js_shared_embedded_names': const LibraryInfo(
    '_internal/js_shared/lib/synced/embedded_names.dart',
    documented: false,
  ),
  '_js_types': const LibraryInfo(
    '_internal/js_shared/lib/js_types.dart',
    documented: false,
  ),
  '_async_status_codes': const LibraryInfo(
    '_internal/js_runtime/lib/synced/async_status_codes.dart',
    documented: false,
  ),
  '_recipe_syntax': const LibraryInfo(
    '_internal/js_shared/lib/synced/recipe_syntax.dart',
    documented: false,
  ),
  '_load_library_priority': const LibraryInfo(
    '_internal/js_runtime/lib/synced/load_library_priority.dart',
    documented: false,
  ),
  '_metadata': const LibraryInfo(
    'html/html_common/metadata.dart',
    documented: false,
  ),
  '_js_annotations': const LibraryInfo(
    'js/_js_annotations.dart',
    documented: false,
  ),
};

/// Information about a "dart:" library.
class LibraryInfo {
  /// Path to the library's *.dart file relative to this file.
  final String path;

  /// True if this library is documented and should be shown to the user.
  final bool documented;

  /// True if the library contains implementation details for another library.
  ///
  /// The implication is that tools should generally not show these libraries to
  /// users.
  final bool implementation;

  const LibraryInfo(
    this.path, {
    this.documented = true,
    bool? implementation,
  }) : this.implementation = implementation ?? !documented;
}
