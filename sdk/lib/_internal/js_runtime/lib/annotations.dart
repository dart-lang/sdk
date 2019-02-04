// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

/// Tells the optimizing compiler that the annotated method has no
/// side-effects. Allocations don't count as side-effects, since they can be
/// dropped without changing the semantics of the program.
///
/// Requires @NoInline() to function correctly.
class NoSideEffects {
  const NoSideEffects();
}

/// Tells the optimizing compiler that the annotated method cannot throw.
/// Requires @NoInline() to function correctly.
class NoThrows {
  const NoThrows();
}

/// Tells the optimizing compiler to not inline the annotated method.
class NoInline {
  const NoInline();
}

/// Tells the optimizing compiler to always inline the annotated method.
class ForceInline {
  const ForceInline();
}

/// Marks a class as native and defines its JavaScript name(s).
class Native {
  final String name;
  const Native(this.name);
}

class _Patch {
  const _Patch();
}

/// Annotation that marks the declaration as a patch.
const _Patch patch = const _Patch();
