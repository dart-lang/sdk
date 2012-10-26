// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('options');

/**
 * An individual option.
 */
class ArchiveOption {
  /** The name of the option. */
  final String name;

  /** The value of the option. */
  final value;

  /** The module to which the option applies.*/
  String module;

  ArchiveOption(this.name, this.value, [this.module]);
}

/**
 * A collection of options.
 */
class ArchiveOptions {
  /** The internal options map. */
  final Map<String, ArchiveOption> _options;

  ArchiveOptions() : _options = <String, ArchiveOption>{};

  /** Returns whether any options have been set. */
  bool get isEmpty => _options.isEmpty;

  /**
   * Sets an option. [value] should either be a bool or something with a
   * reasonable `toString` method.
   *
   * To set the module for an option, use [operator[]].
   */
  void operator[]=(String name, value) {
    _options[name] = new ArchiveOption(name, value);
  }

  /** Gets the option with the given name. */
  ArchiveOption operator[](String name) {
    return _options[name];
  }

  /** Gets all options. */
  List<ArchiveOption> get all => _options.values;
}
