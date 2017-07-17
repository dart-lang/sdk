// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.uri_translator;

import 'package:front_end/file_system.dart' show FileSystem;

/// Instances of [UriTranslator] translate absolute URIs into corresponding
/// file URIs in a [FileSystem]. Translated URIs are typically `file:` URIs,
/// but may use a different scheme depending on the used custom file system.
abstract class UriTranslator {
  /// Return the URIs of patches that should be applied to the platform library
  /// with the given [libraryName], or `null` if there are no patches to apply.
  List<Uri> getDartPatches(String libraryName);

  /// Returns `true` if [uri] is private to the platform libraries (and thus
  /// not accessible from user code).
  bool isPlatformImplementation(Uri uri);

  /// Return the corresponding file URI for the given absolute [uri], or `null`
  /// if there is no corresponding file URI, or the given [uri] is already a
  /// file URI.
  ///
  /// Note: this only translates the URI, there is no guarantee that the
  /// corresponding file exists in the file system.
  Uri translate(Uri uri);
}
