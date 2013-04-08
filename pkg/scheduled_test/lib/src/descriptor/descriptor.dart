// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.descriptor;

import 'dart:async';

import '../utils.dart';

/// The base class for various declarative descriptions of filesystem entries.
/// All asynchronous operations on descriptors are [schedule]d unless otherwise
/// noted.
abstract class Descriptor {
  /// The name of this entry.
  final String name;

  Descriptor(this.name);

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

  /// An unscheduled version of [validate]. This is useful if validation errors
  /// need to be caught, since otherwise they'd be registered by the schedule.
  Future validateNow([String parent]);

  /// Treats [this] as an in-memory filesystem and returns a stream of the
  /// contents of the child entry located at [path]. This only works if [this]
  /// is a directory entry. This operation is not [schedule]d.
  ///
  /// This method uses POSIX paths regardless of the underlying operating
  /// system.
  ///
  /// All errors in loading the file will be passed through the returned
  /// [Stream].
  Stream<List<int>> load(String pathToLoad) => errorStream("Can't load "
      "'$pathToLoad' from within '$name': not a directory.");

  /// Returns the contents of [this] as a stream. This only works if [this] is a
  /// file entry. This operation is not [schedule]d.
  ///
  /// All errors in loading the file will be passed through the returned
  /// [Stream].
  Stream<List<int>> read();

  /// Returns a detailed tree-style description of [this].
  String describe();
}
