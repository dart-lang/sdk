// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The prefix used to create macro library URIs.
const String macroSchemePrefix = 'dart-macro+';

/// Returns `true` if [uri] is a macro library URI.
bool isMacroLibraryUri(Uri uri) {
  return uri.scheme.startsWith(macroSchemePrefix);
}

/// Creates the macro library URI corresponding to the [originLibraryUri].
Uri toMacroLibraryUri(Uri originLibraryUri) {
  return Uri.parse('${macroSchemePrefix}${originLibraryUri}');
}

/// Extracts the origin library URI from [macroLibraryUri].
///
/// This assumes that [macroLibraryUri] is a macro library URI as determined
/// by [isMacroLibraryUri].
Uri toOriginLibraryUri(Uri macroLibraryUri) {
  assert(isMacroLibraryUri(macroLibraryUri),
      "Invalid macro library uri $macroLibraryUri");
  return Uri.parse(
      macroLibraryUri.toString().substring(macroSchemePrefix.length));
}
