// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library libraries;

/**
 * A bit flag used by [LibraryInfo] indicating that a library is used by dart2js
 */
const int DART2JS_PLATFORM = 1;

/**
 * A bit flag used by [LibraryInfo] indicating that a library is used by the VM
 */
const int VM_PLATFORM = 2;

/**
 * Mapping of "dart:" library name (e.g. "core") to information about that library.
 * This information is structured such that Dart Editor can parse this file
 * and extract the necessary information without executing it
 * while other tools can access via execution.
 */
const Map<String, LibraryInfo> LIBRARIES = const {

  "async": const LibraryInfo(
      "async/async.dart",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/async_patch.dart"),

  "collection": const LibraryInfo(
      "collection/collection.dart",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/collection_patch.dart"),

  "convert": const LibraryInfo(
      "convert/convert.dart",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/convert_patch.dart"),

  "core": const LibraryInfo(
      "core/core.dart",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/core_patch.dart"),

  "html": const LibraryInfo(
      "html/dart2js/html_dart2js.dart",
      category: "Client",
      maturity: Maturity.WEB_STABLE),

  "html_common": const LibraryInfo(
      "html/html_common/html_common_dart2js.dart",
      category: "Client",
      maturity: Maturity.WEB_STABLE,
      documented: false,
      implementation: true),

  "indexed_db": const LibraryInfo(
      "indexed_db/dart2js/indexed_db_dart2js.dart",
      category: "Client",
      maturity: Maturity.WEB_STABLE),

  "io": const LibraryInfo(
      "io/io.dart",
      category: "Server",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/io_patch.dart"),

  "isolate": const LibraryInfo(
      "isolate/isolate.dart",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/isolate_patch.dart"),

  "js": const LibraryInfo(
      "js/dartium/js_dartium.dart",
      category: "Client",
      maturity: Maturity.STABLE,
      dart2jsPath: "js/dart2js/js_dart2js.dart"),

  "js_util": const LibraryInfo(
      "js_util/dartium/js_util_dartium.dart",
      categories: "Client",
      maturity: Maturity.STABLE,
      dart2jsPath: "js_util/dart2js/js_util_dart2js.dart"),

  "math": const LibraryInfo(
      "math/math.dart",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/math_patch.dart"),

  "mirrors": const LibraryInfo(
      "mirrors/mirrors.dart",
      maturity: Maturity.UNSTABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/mirrors_patch.dart"),

  "typed_data": const LibraryInfo(
      "typed_data/typed_data.dart",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/compiler/js_lib/typed_data_patch.dart"),

  "_native_typed_data": const LibraryInfo(
      "_internal/compiler/js_lib/native_typed_data.dart",
      category: "Internal",
      implementation: true,
      documented: false,
      platforms: DART2JS_PLATFORM),

  "svg": const LibraryInfo(
      "svg/dart2js/svg_dart2js.dart",
      category: "Client",
      maturity: Maturity.WEB_STABLE),

  "web_audio": const LibraryInfo(
      "web_audio/dart2js/web_audio_dart2js.dart",
      category: "Client",
      maturity: Maturity.WEB_STABLE),

  "web_gl": const LibraryInfo(
      "web_gl/dart2js/web_gl_dart2js.dart",
      category: "Client",
      maturity: Maturity.WEB_STABLE),

  "web_sql": const LibraryInfo(
      "web_sql/dart2js/web_sql_dart2js.dart",
      category: "Client",
      maturity: Maturity.WEB_STABLE),

  "_internal": const LibraryInfo(
      "internal/internal.dart",
      category: "Internal",
      documented: false,
      dart2jsPatchPath:
          "_internal/compiler/js_lib/internal_patch.dart"),

  "_js_helper": const LibraryInfo(
      "_internal/compiler/js_lib/js_helper.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_interceptors": const LibraryInfo(
      "_internal/compiler/js_lib/interceptors.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_foreign_helper": const LibraryInfo(
      "_internal/compiler/js_lib/foreign_helper.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_isolate_helper": const LibraryInfo(
      "_internal/compiler/js_lib/isolate_helper.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_js_mirrors": const LibraryInfo(
      "_internal/compiler/js_lib/js_mirrors.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_js_primitives": const LibraryInfo(
      "_internal/compiler/js_lib/js_primitives.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  // TODO(ahe): This library is only for dart2dart, perhaps it should use a
  // different platform.
  "_mirror_helper": const LibraryInfo(
      "_internal/compiler/js_lib/mirror_helper.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_js_embedded_names": const LibraryInfo(
      "_internal/compiler/js_lib/shared/embedded_names.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_metadata": const LibraryInfo(
      "html/html_common/metadata.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_runtime": const LibraryInfo(
      "_internal/compiler/js_lib/ddc_runtime/runtime.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_debugger": const LibraryInfo(
      "_internal/compiler/js_lib/debugger.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),
};

/**
 * Information about a "dart:" library.
 */
class LibraryInfo {

  /**
   * Path to the library's *.dart file relative to this file.
   */
  final String path;

  /**
   * The category in which the library should appear in the editor
   * (e.g. "Shared", "Client", "Server", ...).
   * If a category is not specified it defaults to "Shared".
   */
  final String category;

  /**
   * Path to the dart2js library's *.dart file relative to this file
   * or null if dart2js uses the common library path defined above.
   * Access using the [#getDart2JsPath()] method.
   */
  final String dart2jsPath;

  /**
   * Path to the dart2js library's patch file relative to this file
   * or null if no dart2js patch file associated with this library.
   * Access using the [#getDart2JsPatchPath()] method.
   */
  final String dart2jsPatchPath;

  /**
   * True if this library is documented and should be shown to the user.
   */
  final bool documented;

  /**
   * Bit flags indicating which platforms consume this library.
   * See [DART2JS_LIBRARY] and [VM_LIBRARY].
   */
  final int platforms;

  /**
   * True if the library contains implementation details for another library.
   * The implication is that these libraries are less commonly used
   * and that tools like Dart Editor should not show these libraries
   * in a list of all libraries unless the user specifically asks the tool to
   * do so.
   */
  final bool implementation;

  /**
   * States the current maturity of this library.
   */
  final Maturity maturity;

  const LibraryInfo(this.path, {
                    this.category: "Shared",
                    this.dart2jsPath,
                    this.dart2jsPatchPath,
                    this.implementation: false,
                    this.documented: true,
                    this.maturity: Maturity.UNSPECIFIED,
                    this.platforms: DART2JS_PLATFORM | VM_PLATFORM});

  bool get isDart2jsLibrary => (platforms & DART2JS_PLATFORM) != 0;
  bool get isVmLibrary => (platforms & VM_PLATFORM) != 0;
}



/**
 * Abstraction to capture the maturity of a library.
 */
class Maturity {
  final int level;
  final String name;
  final String description;

  const Maturity(this.level, this.name, this.description);

  String toString() => "$name: $level\n$description\n";

  static const Maturity DEPRECATED = const Maturity(0, "Deprecated",
    "This library will be remove before next major release.");

  static const Maturity EXPERIMENTAL = const Maturity(1, "Experimental",
    "This library is experimental and will likely change or be removed\n"
    "in future versions.");

  static const Maturity UNSTABLE = const Maturity(2, "Unstable",
    "This library is in still changing and have not yet endured\n"
    "sufficient real-world testing.\n"
    "Backwards-compatibility is NOT guaranteed.");

  static const Maturity WEB_STABLE = const Maturity(3, "Web Stable",
    "This library is tracking the DOM evolution as defined by WC3.\n"
    "Backwards-compatibility is NOT guaranteed.");

  static const Maturity STABLE = const Maturity(4, "Stable",
    "The library is stable. API backwards-compatibility is guaranteed.\n"
    "However implementation details might change.");

  static const Maturity LOCKED = const Maturity(5, "Locked",
    "This library will not change except when serious bugs are encountered.");

  static const Maturity UNSPECIFIED = const Maturity(-1, "Unspecified",
    "The maturity for this library has not been specified.");
}
