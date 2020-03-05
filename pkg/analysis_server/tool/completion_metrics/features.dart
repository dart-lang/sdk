// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to compute the value of the features used for code
/// completion.
import 'package:analyzer/dart/element/element.dart' show ClassElement;

// TODO(brianwilkerson) Move this file to `lib` so that it can be used by the
//  completion contributors.

/// Return the inheritance distance between the [subclass] and the [superclass].
/// We define the inheritance distance between two types to be zero if the two
/// types are the same and the minimum number of edges that must be traversed in
/// the type graph to get from the subtype to the supertype if the two types are
/// not the same. Return `-1` if the [subclass] is not a subclass of the
/// [superclass].
int inheritanceDistance(ClassElement subclass, ClassElement superclass) {
  return _inheritanceDistance(subclass, superclass, {});
}

/// Return the value of the inheritance distance feature for a member defined in
/// the [superclass] that is being accessed through an expression whose static
/// type is the [subclass].
double inheritanceDistanceFeature(
    ClassElement subclass, ClassElement superclass) {
  var distance = _inheritanceDistance(subclass, superclass, {});
  if (distance < 0) {
    return 0;
  }
  return 1 / (distance + 1);
}

/// Return the inheritance distance between the [subclass] and the [superclass].
/// The set of [visited] elements is used to guard against cycles in the type
/// graph.
///
/// This is the implementation of [inheritanceDistance].
int _inheritanceDistance(
    ClassElement subclass, ClassElement superclass, Set<ClassElement> visited) {
  if (subclass == null) {
    return -1;
  } else if (subclass == superclass) {
    return 0;
  } else if (!visited.add(subclass)) {
    return -1;
  }
  var minDepth =
      _inheritanceDistance(subclass.supertype?.element, superclass, visited);
  for (var mixin in subclass.mixins) {
    var depth = _inheritanceDistance(mixin.element, superclass, visited);
    if (minDepth < 0 || depth < minDepth) {
      minDepth = depth;
    }
  }
  for (var interface in subclass.interfaces) {
    var depth = _inheritanceDistance(interface.element, superclass, visited);
    if (minDepth < 0 || (depth >= 0 && depth < minDepth)) {
      minDepth = depth;
    }
  }
  visited.remove(subclass);
  if (minDepth < 0) {
    return minDepth;
  }
  return minDepth + 1;
}
