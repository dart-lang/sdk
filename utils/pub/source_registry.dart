// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('source_registry');

#import('source.dart');

/**
 * A class that keeps track of [Source]s used for installing packages.
 */
class SourceRegistry {
  final Map<String, Source> _map;
  Source _default;

  /**
   * Creates a new registry with no packages registered.
   */
  SourceRegistry() : _map = <String, Source>{};

  /**
   * Returns the default source, which is used when no source is specified.
   */
  Source get defaultSource() => _default;

  /**
   * Sets the default source. This takes a string, which must be the name of a
   * registered source.
   */
  void setDefault(String name) {
    if (!_map.containsKey(name)) {
      // TODO(nweiz): Real error-handling system
      throw 'Default source $name is not in the registry';
    }

    _default = _map[name];
  }

  /**
   * Registers a new source. This source may not have the same name as a source
   * that's already been registered.
   */
  void register(Source source) {
    if (_map.containsKey(source.name)) {
      // TODO(nweiz): Real error-handling system
      throw 'Source registry already has a source named ${source.name}';
    }

    _map[source.name] = source;
  }

  /**
   * Returns `true` if there is a source named [name].
   */
  bool contains(String name) => _map.containsKey(name);

  /**
   * Returns the source named [name]. Throws an error if no such source has been
   * registered. If [name] is null, returns the default source.
   */
  Source operator[](String name) {
    if (name == null) {
      if (defaultSource != null) return defaultSource;
      // TODO(nweiz): Real error-handling system
      throw 'No default source has been registered';
    }
    if (_map.containsKey(name)) return _map[name];
    throw 'No source named $name is registered';
  }
}
