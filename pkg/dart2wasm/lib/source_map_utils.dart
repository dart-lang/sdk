// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String _sourceMapExtensionName = "x_org_dartlang_dart2js";

/// Add dart2js source map extension fields to allow mapping "minified:Class123"
/// parts in error messages to unminified class names like "String".
///
/// This is only needed in minified builds. Non-minified builds will have the
/// full class names in the errors.
///
/// The extension format is described in
/// `pkg/compiler/doc/sourcemap_extensions.md`.
void addMinifiedClassNames(
    Map<String, Object?> sourceMapJson, List<String?> classNames) {
  final List<dynamic> names = sourceMapJson['names'] as List<dynamic>;

  // Some of the class names may already be in the names list. Create the
  // name->index map with existing names to reuse existing names.
  final Map<String, int> nameIndices = {};
  for (var i = 0; i < names.length; i += 1) {
    nameIndices[names[i]] = i;
  }

  final Map<String, int> minifiedClassNamesToUnminified = {};
  for (var classId = 0; classId < classNames.length; classId += 1) {
    final unminifiedClassName = classNames[classId];
    if (unminifiedClassName == null) continue;
    final minifiedClassName = "Class$classId";
    int? unminifiedClassNameIndex = nameIndices[unminifiedClassName];
    if (unminifiedClassNameIndex == null) {
      unminifiedClassNameIndex = names.length;
      names.add(unminifiedClassName);
    }
    minifiedClassNamesToUnminified[minifiedClassName] =
        unminifiedClassNameIndex;
  }

  // 'names' is updated in-place above with the full class names, add the
  // new section.
  //
  // We don't need the "instance" section, but some of the tools want it to be
  // present always.
  sourceMapJson[_sourceMapExtensionName] = <String, Object?>{
    "minified_names": <String, Object?>{
      "global": minifiedClassNamesToUnminified.entries
          .map((entry) => "${entry.key},${entry.value}")
          .join(","),
      "instance": "",
    }
  };
}

/// If the source map has the custom section added by [addMinifiedClassNames],
/// parse the unminified class names and return the original list* passed to
/// [addMinifiedClassNames].
///
/// (*): With the exception that trailing `null` elements of the original list
/// will be missing in the return value of this function.
List<String?>? getMinifiedClassNames(Map<String, Object?> sourceMapJson) {
  final List<dynamic> names = sourceMapJson["names"] as List<dynamic>;

  final extensionField = sourceMapJson[_sourceMapExtensionName];
  if (extensionField == null) return null;

  final List<String> globalMinifiedNames =
      (((extensionField as Map)["minified_names"] as Map)["global"] as String)
          .split(",");

  List<String?> unminifiedClassNames = [];

  for (int i = 0; i < globalMinifiedNames.length; i += 2) {
    final minifiedClassName = globalMinifiedNames[i];
    assert(minifiedClassName.startsWith("Class"));
    final classId = int.parse(minifiedClassName.substring("Class".length));
    final unminifiedClassNameIndex = int.parse(globalMinifiedNames[i + 1]);
    final unminifiedClassName = names[unminifiedClassNameIndex] as String;
    while (unminifiedClassNames.length <= classId) {
      unminifiedClassNames.add(null);
    }
    assert(unminifiedClassNames[classId] == null);
    unminifiedClassNames[classId] = unminifiedClassName;
  }

  return unminifiedClassNames;
}
