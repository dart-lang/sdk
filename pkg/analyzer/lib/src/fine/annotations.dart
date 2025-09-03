// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotation for classes that are part of the element model.
///
/// Classes marked with this annotation require some of their members to be
/// annotated, as follows:
///
/// Public getters and fields must be annotated with one of:
///   [trackedIncludedInId]
///   [trackedDirectly]
///   [trackedIndirectly]
///
/// Public methods must be annotated with one of:
///   [trackedDirectly]
///   [trackedIndirectly]
const elementClass = _ElementClass();

/// Annotation for methods that must record the fact of the invocation.
///
/// In contrast to [trackedIncludedInId], the result of the method is not
/// reflected in the ID of the target class, so we need to record this
/// requirement separately.
///
/// Examples: `getMethod(name)`, `getNamedConstructor(name)`.
const trackedDirectly = _TrackedDirectly();

/// As [trackedDirectly], but for methods that are expensive.
///
/// For example, `get methods` adds dependency on all declared methods, but
/// if the client then filters these methods in some way, it would be better
/// to use (or add if absent) a more specific method, e.g. `getMethod(name)`.
///
/// Examples: `constructors`, `methods`.
///
/// We must make sure that the analyzer itself does not use such APIs.
/// We should try to fix any popular lint rules that use such APIs.
const trackedDirectlyExpensive = _TrackedDirectlyExpensive();

/// Annotation for methods that are too invasive, and if invoked for anything
/// other than the current library, disable fine-grained dependencies
/// optimizations. So, the result will be re-computed if just anything in
/// its transitive closure of imported libraries changed.
///
/// Examples: `fragments`, `visitChildren()`.
///
/// We must make sure that the analyzer itself does not use such APIs.
/// We should try to fix any popular lint rules that use such APIs.
const trackedDirectlyOpaque = _TrackedDirectlyOpaque();

/// Annotation for getters that don't require recording.
///
/// The library manifest builder must compare the value of the getter with
/// the previous value in the manifest, and give the element a new ID if the
/// value is different.
///
/// Examples: `isAbstract`, `interfaces`, `returnType`.
const trackedIncludedInId = _TrackedIncludedInId();

/// Annotation for methods that don't require recording.
///
/// The implementation of the method uses only getters and methods which
/// do record requirements, or already would cause a new ID for the target
/// class.
const trackedIndirectly = _TrackedIndirectly();

/// Annotation for methods that used internally while building elements,
/// but are not supposed to be used by any client.
///
/// Such methods of course are never API, and potential clients could only
/// be other parts of the analyzer itself.
const trackedInternal = _TrackedInternal();

final class _ElementClass {
  const _ElementClass();
}

final class _TrackedDirectly extends _TrackedKind {
  const _TrackedDirectly();
}

final class _TrackedDirectlyExpensive extends _TrackedDirectly {
  const _TrackedDirectlyExpensive();
}

final class _TrackedDirectlyOpaque extends _TrackedDirectly {
  const _TrackedDirectlyOpaque();
}

final class _TrackedIncludedInId extends _TrackedKind {
  const _TrackedIncludedInId();
}

final class _TrackedIndirectly extends _TrackedKind {
  const _TrackedIndirectly();
}

final class _TrackedInternal extends _TrackedKind {
  const _TrackedInternal();
}

/// Superclass for all specific kinds of tracking annotations.
sealed class _TrackedKind {
  const _TrackedKind();
}
