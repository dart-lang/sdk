// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/timestamped_data.dart';

/// The interface `Source` defines the behavior of objects representing source
/// code that can be analyzed by the analysis engine.
///
/// Implementations of this interface need to be aware of some assumptions made
/// by the analysis engine concerning sources:
///
/// * Sources are not required to be unique. That is, there can be multiple
///   instances representing the same source.
/// * Sources are long lived. That is, the engine is allowed to hold on to a
/// source for an extended period of time and that source must continue to
/// report accurate and up-to-date information.
///
/// Because of these assumptions, most implementations will not maintain any
/// state but will delegate to an authoritative system of record in order to
/// implement this API. For example, a source that represents files on disk
/// would typically query the file system to determine the state of the file.
///
/// If the instances that implement this API are the system of record, then they
/// will typically be unique. In that case, sources that are created that
/// represent nonexistent files must also be retained so that if those files
/// are created at a later date the long-lived sources representing those files
/// will know that they now exist.
abstract class Source {
  /// Get the contents and timestamp of this source.
  ///
  /// @return the contents and timestamp of the source
  /// @throws Exception if the contents of this source could not be accessed
  TimestampedData<String> get contents;

  /// Return the full (long) version of the name that can be displayed to the
  /// user to denote this source. For example, for a source representing a file
  /// this would typically be the absolute path of the file.
  ///
  /// @return a name that can be displayed to the user to denote this source
  String get fullName;

  /// Return a hash code for this source.
  ///
  /// @return a hash code for this source
  /// See [Object.hashCode].
  @override
  int get hashCode;

  /// Return a short version of the name that can be displayed to the user to
  /// denote this source. For example, for a source representing a file this
  /// would typically be the name of the file.
  ///
  /// @return a name that can be displayed to the user to denote this source
  String get shortName;

  /// Return the URI from which this source was originally derived.
  ///
  /// @return the URI from which this source was originally derived
  Uri get uri;

  /// Return `true` if the given object is a source that represents the same
  /// source code as this source.
  ///
  /// @param object the object to be compared with this object
  /// @return `true` if the given object is a source that represents the same
  ///         source code as this source
  /// See [Object.==].
  @override
  bool operator ==(Object other);

  /// Return `true` if this source exists.
  ///
  /// Clients should consider using the method [AnalysisContext.exists] because
  /// contexts can have local overrides of the content of a source that the
  /// source is not aware of and a source with local content is considered to
  /// exist even if there is no file on disk.
  ///
  /// @return `true` if this source exists
  bool exists();
}
