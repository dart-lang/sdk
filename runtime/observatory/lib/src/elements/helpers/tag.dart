// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

/// Utility class for Custom Tags registration.
class Tag<T extends HtmlElement> {
  /// Tag name.
  final String name;

  /// Dependent tags that need to be registred for this tag to work properly.
  final Iterable<Tag> dependencies;

  const Tag(this.name, {this.dependencies: const []});

  static final Map<Type, String> _tagByClass = <Type, String>{};
  static final Map<String, Type> _classByTag = <String, Type>{};

  /// Ensures that the Tag and all the dependencies are registered.
  void ensureRegistration() {
    if (!_tagByClass.containsKey(T) && !_classByTag.containsKey(name)) {
      document.registerElement(name, T);
      _tagByClass[T] = name;
      _classByTag[name] = T;
      dependencies.forEach((tag) => tag.ensureRegistration());
    }
    var tag = _tagByClass[T];
    if (tag != name) {
      throw new ArgumentError('Class $T is already registered to tag ${tag}');
    }
    var c = _classByTag[name];
    if (c != T) {
      throw new ArgumentError('Tag $name is already registered by class ${c}');
    }
  }
}
