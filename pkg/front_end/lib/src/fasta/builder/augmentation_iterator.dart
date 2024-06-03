// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Iterator for iterating through an origin and all its augmentations.
class AugmentationIterator<T> implements Iterator<T> {
  final T _origin;
  final List<T>? _augmentations;
  Iterator<T>? _augmentationsIterator;
  T? _current;

  AugmentationIterator(this._origin, this._augmentations);

  @override
  T get current =>
      _augmentationsIterator?.current ??
      _current ??
      (throw new StateError('No element'));

  @override
  bool moveNext() {
    if (_augmentationsIterator == null) {
      if (_current == null) {
        _current = _origin;
        return true;
      }
      _augmentationsIterator =
          _augmentations?.iterator ?? const Iterable<Never>.empty().iterator;
    }
    return _augmentationsIterator!.moveNext();
  }
}
