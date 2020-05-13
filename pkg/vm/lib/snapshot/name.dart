// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helpers for parsing Code object name produced by Code::QualifiedName
library vm.snapshot.name;

// Wrapper around the name of a Code object produced by Code::QualifiedName.
//
// Raw textual representation of the name contains not just the name of itself,
// but also various attributes (whether this code object originates from the
// Dart function or from a stub, whether it is optimized or not, whether
// it corresponds to some synthetic function, etc).
class Name {
  /// Raw textual representation of the name as it occurred in the output
  /// of the AOT compiler.
  final String raw;

  Name(this.raw);

  /// Pretty version of the name, with some of the irrelevant information
  /// removed from it.
  /// Note: we still expect this name to be unique within compilation,
  /// so we are not removing any details that are used for disambiguation.
  String get scrubbed => raw.replaceAll(_scrubbingRe, '');

  /// Returns true if this name refers to a stub.
  bool get isStub => raw.startsWith('[Stub] ');

  /// Returns true if this name refers to an allocation stub.
  bool get isAllocationStub => raw.startsWith('[Stub] Allocate ');
}

// Remove useless prefixes and private library suffixes from the raw name.
//
// Note that we want to keep anonymous closure token positions in the name
// still, these names are formatted as '<anonymous closure @\d+>'.
final _scrubbingRe =
    RegExp(r'\[(Optimized|Unoptimized|Stub)\]\s*|@\d+(?![>\d])');
