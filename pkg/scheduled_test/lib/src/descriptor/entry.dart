// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.entry;

import 'dart:async';

import '../utils.dart';
import 'utils.dart';

/// The base class for various declarative descriptions of filesystem entries.
/// All asynchronous operations on descriptors are [schedule]d unless otherwise
/// noted.
abstract class Entry {
  /// The name of this entry. For most operations, this must be a [String];
  /// however, if the entry will only be used for validation, it may be a
  /// non-[String] [Pattern]. In this case, there must be only one entry
  /// matching it in the physical filesystem for validation to succeed.
  final Pattern name;

  Entry(this.name);

  /// Schedules the creation of the described entry within the [parent]
  /// directory. Returns a [Future] that completes after the creation is done.
  ///
  /// [parent] defaults to [defaultRoot].
  Future create([String parent]);

  /// Schedules the validation of the described entry. This validates that the
  /// physical file system under [parent] contains an entry that matches the one
  /// described by [this]. Returns a [Future] that completes to `null` if the
  /// entry is valid, or throws an error if it failed.
  ///
  /// [parent] defaults to [defaultRoot].
  Future validate([String parent]);

  /// Treats [this] as an in-memory filesystem and returns a stream of the
  /// contents of the child entry located at [path]. This only works if [this]
  /// is a directory entry. This operation is not [schedule]d.
  ///
  /// All errors in loading the file will be passed through the returned
  /// [Stream].
  Stream<List<int>> load(String pathToLoad) => errorStream("Can't load "
      "'$pathToLoad' from within $nameDescription: not a directory.");

  /// Returns the contents of [this] as a stream. This only works if [this] is a
  /// file entry. This operation is not [schedule]d.
  ///
  /// All errors in loading the file will be passed through the returned
  /// [Stream].
  Stream<List<int>> read();

  /// Asserts that the name of the descriptor is a [String] and returns it.
  String get stringName {
    if (name is String) return name;
    throw 'Pattern $nameDescription must be a string.';
  }

  /// Returns a human-readable description of [name], for error reporting. For
  /// string names, this will just be the name in quotes; for regular
  /// expressions, it will use JavaScript-style `/.../` notation.
  String get nameDescription => describePattern(name);

  /// Returns a detailed tree-style description of [this].
  String describe();
}
