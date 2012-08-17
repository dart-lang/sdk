// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('libraries');

/**
 * Mapping of "dart:" library name (e.g. "core") to information about that library.
 * This information is structured such that Dart Editor can parse this file
 * and extract the necessary information without executing it
 * while other tools can access via execution.
 */
final Map<String, LibraryInfo> LIBRARIES = const <LibraryInfo> {

  // Used by VM applications
  "builtin": const LibraryInfo(
      "builtin/builtin_runtime.dart",
      category: "Server"),

  "compiler": const LibraryInfo(
      "compiler/compiler.dart",
      category: "Tools"),

  "core": const LibraryInfo(
      "core/core_runtime.dart",
      dart2jsPath: "compiler/implementation/lib/core.dart"),

  "coreimpl": const LibraryInfo(
      "coreimpl/coreimpl_runtime.dart",
      implementation: true,
      dart2jsPath: "compiler/implementation/lib/coreimpl.dart",
      dart2jsPatchPath: "compiler/implementation/lib/coreimpl.dartp"),

  "crypto": const LibraryInfo(
      "crypto/crypto.dart"),

  // dom/dom_frog.dart is a placeholder for dartium dom
  "dom_deprecated": const LibraryInfo(
      "dom/dom_dart2js.dart",
      dart2jsPath: "dom/dart2js/dom_dart2js.dart",
      internal: true),

  "html": const LibraryInfo(
      "html/html_dartium.dart",
      category: "Client",
      dart2jsPath: "html/dart2js/html_dart2js.dart"),

  "io": const LibraryInfo(
      "io/io_runtime.dart",
      category: "Server",
      dart2jsPath: "compiler/implementation/lib/io.dart"),

  "isolate": const LibraryInfo(
      "isolate/isolate_compiler.dart",
      dart2jsPath: "isolate/isolate_dart2js.dart"),

  "json": const LibraryInfo(
      "json/json.dart"),

  "math": const LibraryInfo(
      "math/math.dart",
      dart2jsPatchPath: "compiler/implementation/lib/math.dartp"),

  // Used by Dartium applications
  "nativewrappers": const LibraryInfo(
      "html/nativewrappers.dart",
      category: "Client",
      implementation: true),

  "unittest": const LibraryInfo(
      "unittest/unittest.dart",
      category: "Tools"),

  "uri": const LibraryInfo(
      "uri/uri.dart"),

  "utf": const LibraryInfo(
      "utf/utf.dart"),

  "web": const LibraryInfo(
      "web/web.dart"),

  // Used by dart2js
  "_js_helper": const LibraryInfo(
      "compiler/implementation/lib/js_helper.dart",
      category: "Internal",
      internal: true),

  // Used by dart2js
  "_interceptors": const LibraryInfo(
      "compiler/implementation/lib/interceptors.dart",
      category: "Internal",
      internal: true),
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
   */
  final String dart2jsPath;

  /**
   * Path to the dart2js library's patch file relative to this file
   * or null if no dart2js patch file associated with this library.
   */
  final String dart2jsPatchPath;

  /**
   * True if this library is internal and should not be shown to the user
   */
  final bool internal;

  /**
   * True if the library contains implementation details for another library.
   * The implication is that these libraries are less commonly used
   * and that tools like Dart Editor should not show these libraries
   * in a list of all libraries unless the user specifically asks the tool to do so.
   * (e.g. "coreimpl" contains implementation for the "core" library).
   */
  final bool implementation;

  const LibraryInfo(this.path, [this.category = "Shared",
           this.dart2jsPath, this.dart2jsPatchPath,
           this.implementation = false, this.internal = false]);
}
