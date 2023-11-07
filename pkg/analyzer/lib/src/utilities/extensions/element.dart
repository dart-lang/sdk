// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

extension ElementExtension on Element {
  /// TODO(scheglov) Maybe just add to `Element`?
  Element? get augmentation {
    if (this case final AugmentableElement augmentable) {
      return augmentable.augmentation;
    }
    return null;
  }

  List<Element> get withAugmentations {
    final result = <Element>[];
    Element? current = this;
    while (current != null) {
      result.add(current);
      current = current.augmentation;
    }
    return result;
  }
}
