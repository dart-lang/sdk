// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/compilation_unit.dart';

/// Information about a part directive.
class Part({
  /// The file URI at which the part directive occurs.
  required final Uri fileUri,

  /// The file offset at which the part directive occurs.
  required final int fileOffset,

  /// The [CompilationUnit] referenced by the part directive.
  required final CompilationUnit compilationUnit,
});

/// Information about a part-of directive.
class PartOf {
  /// The file URI at which the part-of directive occurs.
  final Uri fileUri;

  /// The file offset at which the part-of directive occurs.
  final int fileOffset;

  /// The name of the enclosing library.
  ///
  /// This is used for part-of directives of the form `part of foo.bar;`.
  final String? name;

  /// The URI of the enclosing part or library.
  ///
  /// This is used for part-of directives of the form `part of 'foo.dart';`.
  final Uri? parentUri;

  new withName({
    required this.fileUri,
    required this.fileOffset,
    required String this.name,
  }) : parentUri = null;

  new withUri({
    required this.fileUri,
    required this.fileOffset,
    required Uri this.parentUri,
  }) : name = null;
}

/// Information about a library directive.
class LibraryDirective({
  /// The file URI at which the library directive occurs.
  required final Uri fileUri,

  /// The file offset at which the library directive occurs.
  required final int fileOffset,

  /// The library name provided in the library directive, if any.
  required final String? name,
});
