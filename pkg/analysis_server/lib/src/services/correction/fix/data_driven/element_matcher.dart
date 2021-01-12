// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:meta/meta.dart';

/// An object that can be used to determine whether an element is appropriate
/// for a given reference.
class ElementMatcher {
  /// The URIs of the libraries that are imported in the library containing the
  /// reference.
  final List<Uri> importedUris;

  /// The components of the element being referenced. The components are ordered
  /// from the most local to the most global.
  final List<String> components;

  /// A list of the kinds of elements that are appropriate for some given
  /// location in the code An empty list represents all kinds rather than no
  /// kinds.
  final List<ElementKind> validKinds;

  /// Initialize a newly created matcher representing a reference to an element
  /// with the given [name] in a library that imports the [importedUris].
  ElementMatcher(
      {@required this.importedUris,
      @required this.components,
      List<ElementKind> kinds})
      : assert(components != null && components.isNotEmpty),
        validKinds = kinds ?? const [];

  /// Return `true` if this matcher matches the given [element].
  bool matches(ElementDescriptor element) {
    //
    // Check that the components in the element's name match the node.
    //
    // This algorithm is probably too general given that there will currently
    // always be either one or two components.
    //
    var elementComponents = element.components;
    var elementComponentCount = elementComponents.length;
    var nodeComponentCount = components.length;
    if (nodeComponentCount == elementComponentCount) {
      // The component counts are the same, so we can just compare the two
      // lists.
      for (var i = 0; i < nodeComponentCount; i++) {
        if (elementComponents[i] != components[i]) {
          return false;
        }
      }
    } else if (nodeComponentCount < elementComponentCount) {
      // The node has fewer components, which can happen, for example, when we
      // can't figure out the class that used to define a field. We treat the
      // missing components as wildcards and match the rest.
      for (var i = 0; i < nodeComponentCount; i++) {
        if (elementComponents[i] != components[i]) {
          return false;
        }
      }
    } else {
      // The node has more components than the element, which can happen when a
      // constructor is implicitly renamed because the class was renamed.
      // TODO(brianwilkerson) Figure out whether we want to support this or
      //  whether we want to require fix data authors to explicitly include the
      //  change to the constructor. On the one hand it's more work for the
      //  author, on the other hand it give us more data so we're less likely to
      //  make apply a fix in invalid circumstances.
      if (elementComponents[0] != components[1]) {
        return false;
      }
    }
    //
    // Check whether the kind of element matches the possible kinds that the
    // node might have.
    //
    if (validKinds.isNotEmpty && !validKinds.contains(element.kind)) {
      return false;
    }
    //
    // Check whether the element is in an imported library.
    //
    var libraryUris = element.libraryUris;
    for (var importedUri in importedUris) {
      if (libraryUris.contains(importedUri)) {
        return true;
      }
    }
    return false;
  }
}
