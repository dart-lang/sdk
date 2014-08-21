// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.source_registry;

import 'dart:collection';

import 'package.dart';
import 'source.dart';
import 'source/unknown.dart';

/// A class that keeps track of [Source]s used for getting packages.
class SourceRegistry extends IterableBase<Source> {
  final _sources = new Map<String, Source>();
  Source _default;

  /// Returns the default source, which is used when no source is specified.
  Source get defaultSource => _default;

  /// Iterates over the registered sources in name order.
  Iterator<Source> get iterator {
    var sources = _sources.values.toList();
    sources.sort((a, b) => a.name.compareTo(b.name));
    return sources.iterator;
  }

  /// Returns whether [id1] and [id2] refer to the same package, including
  /// validating that their descriptions are equivalent.
  bool idsEqual(PackageId id1, PackageId id2) {
    if (id1 != id2) return false;
    if (id1 == null && id2 == null) return true;
    return idDescriptionsEqual(id1, id2);
  }

  /// Returns whether [id1] and [id2] have the same source and description.
  ///
  /// This doesn't check whether the name or versions are equal.
  bool idDescriptionsEqual(PackageId id1, PackageId id2) {
    if (id1.source != id2.source) return false;
    return this[id1.source].descriptionsEqual(id1.description, id2.description);
  }

  /// Sets the default source.
  ///
  /// This takes a string, which must be the name of a registered source.
  void setDefault(String name) {
    if (!_sources.containsKey(name)) {
      throw new StateError('Default source $name is not in the registry');
    }

    _default = _sources[name];
  }

  /// Registers a new source.
  ///
  /// This source may not have the same name as a source that's already been
  /// registered.
  void register(Source source) {
    if (_sources.containsKey(source.name)) {
      throw new StateError('Source registry already has a source named '
          '${source.name}');
    }

    _sources[source.name] = source;
  }

  /// Returns the source named [name].
  ///
  /// Returns an [UnknownSource] if no source with that name has been
  /// registered. If [name] is null, returns the default source.
  Source operator[](String name) {
    if (name == null) {
      if (defaultSource != null) return defaultSource;
      throw new StateError('No default source has been registered');
    }

    if (_sources.containsKey(name)) return _sources[name];
    return new UnknownSource(name);
  }
}
