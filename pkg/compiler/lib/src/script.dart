// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.script;

import 'io/source_file.dart';

class Script {
  final SourceFile file;

  /// The readable URI from which this script was loaded.
  ///
  /// See [LibraryLoader] for terminology on URIs.
  final Uri readableUri;

  /// The resource URI from which this script was loaded.
  ///
  /// See [LibraryLoader] for terminology on URIs.
  final Uri resourceUri;

  /// This script was synthesized.
  final bool isSynthesized;

  Script(this.readableUri, this.resourceUri, this.file) : isSynthesized = false;

  Script.synthetic(Uri uri)
      : readableUri = uri,
        resourceUri = uri,
        file = new StringSourceFile.fromUri(
            uri, "// Synthetic source file generated for '$uri'."),
        isSynthesized = true;

  String get text => (file == null) ? null : file.slowText();
  String get name => (file == null) ? null : file.filename;

  /// Creates a new [Script] with the same URIs, but new content ([file]).
  Script copyWithFile(SourceFile file) {
    return new Script(readableUri, resourceUri, file);
  }
}
