// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Shared element model between the dart analyzer and dart2js.

library elements;

/// The interface `Element` defines the behavior common to all of the elements
/// in the element model. Generally speaking, the element model is a semantic
/// model of the program that represents things that are declared with a name
/// and hence can be referenced elsewhere in the code.
abstract class Element {
  // TODO(johnniwinther): Semantic difference. Setter names from the analyzer
  // contain '=' but doesn't in dart2js.
  // TODO(johnniwinther,paulberry,brianwilkerson): What about privacy? Maybe
  // name should be the `Name` class in
  // 'package:compiler/src/elements/names.dart'.
  /// The name of this element, or `null` if this element does not have a name.
  String get name;

  /// The library that contains this element. This will be the element itself if
  /// it is a library element.
  LibraryElement get library;
}

/// The interface `LibraryElement` defines the behavior of elements representing
/// a library.
abstract class LibraryElement extends Element {

}

/// The interface `ClassElement` defines the behavior of elements that represent
/// a class.
abstract class ClassElement extends Element {

}
