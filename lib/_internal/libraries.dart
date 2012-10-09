// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('libraries');

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
const Map<String, LibraryInfo> LIBRARIES = const <LibraryInfo> {

  "core": const LibraryInfo(
      "core/core.dart",
      dart2jsPatchPath: "compiler/implementation/lib/core_patch.dart"),

  "coreimpl": const LibraryInfo(
      "coreimpl/coreimpl.dart",
      implementation: true,
      dart2jsPatchPath: "compiler/implementation/lib/coreimpl_patch.dart"),

  "crypto": const LibraryInfo(
      "crypto/crypto.dart"),

  "html": const LibraryInfo(
      "html/dartium/html_dartium.dart",
      category: "Client",
      dart2jsPath: "html/dart2js/html_dart2js.dart"),

  "io": const LibraryInfo(
      "io/io_runtime.dart",
      category: "Server",
      dart2jsPath: "compiler/implementation/lib/io.dart"),

  "isolate": const LibraryInfo(
      "isolate/isolate.dart",
      dart2jsPatchPath: "compiler/implementation/lib/isolate_patch.dart"),

  "json": const LibraryInfo(
      "json/json.dart"),

  "math": const LibraryInfo(
      "math/math.dart",
      dart2jsPatchPath: "compiler/implementation/lib/math_patch.dart"),

  "mirrors": const LibraryInfo(
      "mirrors/mirrors.dart",
      documented: false,
      platforms: VM_PLATFORM),

  "nativewrappers": const LibraryInfo(
      "html/dartium/nativewrappers.dart",
      category: "Client",
      implementation: true,
      documented: false,
      platforms: VM_PLATFORM),

  "scalarlist": const LibraryInfo(
      "scalarlist/scalarlist.dart",
      category: "Server",
      dart2jsPatchPath: "compiler/implementation/lib/scalarlist_patch.dart"),

  "uri": const LibraryInfo(
      "uri/uri.dart"),

  "utf": const LibraryInfo(
      "utf/utf.dart"),

  "_js_helper": const LibraryInfo(
      "compiler/implementation/lib/js_helper.dart",
      category: "Internal",
      documented: false,
      platforms: DART2JS_PLATFORM),

  "_interceptors": const LibraryInfo(
      "compiler/implementation/lib/interceptors.dart",
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
   * (e.g. "Common", "Client", "Server", ...).
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
   * do so. (E.g. "coreimpl" contains implementation for the "core" library).
   */
  final bool implementation;

  const LibraryInfo(this.path, [
           this.category = "Shared",
           this.dart2jsPath,
           this.dart2jsPatchPath,
           this.implementation = false,
           this.documented = true,
           this.platforms = DART2JS_PLATFORM | VM_PLATFORM]);

  bool get isDart2jsLibrary => (platforms & DART2JS_PLATFORM) != 0;
  bool get isVmLibrary => (platforms & VM_PLATFORM) != 0;
}
