// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.source;

import 'dart:async';

import 'package:pub_semver/pub_semver.dart';

import 'package.dart';
import 'pubspec.dart';
import 'system_cache.dart';

/// A source from which to get packages.
///
/// Each source has many packages that it looks up using [PackageId]s. Sources
/// that inherit this directly (currently just [PathSource]) are *uncached*
/// sources. They deliver a package directly to the package that depends on it.
///
/// Other sources are *cached* sources. These extend [CachedSource]. When a
/// package needs a dependency from a cached source, it is first installed in
/// the [SystemCache] and then acquired from there.
abstract class Source {
  /// The name of the source.
  ///
  /// Should be lower-case, suitable for use in a filename, and unique accross
  /// all sources.
  String get name;

  /// Whether this source can choose between multiple versions of the same
  /// package during version solving.
  ///
  /// Defaults to `false`.
  final bool hasMultipleVersions = false;

  /// Whether or not this source is the default source.
  bool get isDefault => systemCache.sources.defaultSource == this;

  /// The system cache with which this source is registered.
  SystemCache get systemCache {
    assert(_systemCache != null);
    return _systemCache;
  }

  /// The system cache variable.
  ///
  /// Set by [_bind].
  SystemCache _systemCache;

  /// Records the system cache to which this source belongs.
  ///
  /// This should only be called once for each source, by
  /// [SystemCache.register]. It should not be overridden by base classes.
  void bind(SystemCache systemCache) {
    assert(_systemCache == null);
    this._systemCache = systemCache;
  }

  /// Get the list of all versions that exist for the package described by
  /// [description].
  ///
  /// [name] is the expected name of the package.
  ///
  /// Note that this does *not* require the packages to be downloaded locally,
  /// which is the point. This is used during version resolution to determine
  /// which package versions are available to be downloaded (or already
  /// downloaded).
  ///
  /// By default, this assumes that each description has a single version and
  /// uses [describe] to get that version.
  Future<List<Version>> getVersions(String name, description) {
    var id = new PackageId(name, this.name, Version.none, description);
    return describe(id).then((pubspec) => [pubspec.version]);
  }

  /// Loads the (possibly remote) pubspec for the package version identified by
  /// [id].
  ///
  /// This may be called for packages that have not yet been downloaded during
  /// the version resolution process.
  ///
  /// Sources should not override this. Instead, they implement [doDescribe].
  Future<Pubspec> describe(PackageId id) {
    if (id.isRoot) throw new ArgumentError("Cannot describe the root package.");
    if (id.source != name) {
      throw new ArgumentError("Package $id does not use source $name.");
    }

    // Delegate to the overridden one.
    return doDescribe(id);
  }

  /// Loads the (possibly remote) pubspec for the package version identified by
  /// [id].
  ///
  /// This may be called for packages that have not yet been downloaded during
  /// the version resolution process.
  ///
  /// This method is effectively protected: subclasses must implement it, but
  /// external code should not call this. Instead, call [describe].
  Future<Pubspec> doDescribe(PackageId id);

  /// Ensures [id] is available locally and creates a symlink at [symlink]
  /// pointing it.
  Future get(PackageId id, String symlink);

  /// Returns the directory where this package can (or could) be found locally.
  ///
  /// If the source is cached, this will be a path in the system cache. In that
  /// case, this will return a directory even if the package has not been
  /// installed into the cache yet.
  Future<String> getDirectory(PackageId id);

  /// Gives the source a chance to interpret and validate the description for
  /// a package coming from this source.
  ///
  /// When a [Pubspec] or [LockFile] is parsed, it reads in the description for
  /// each dependency. It is up to the dependency's [Source] to determine how
  /// that should be interpreted. This will be called during parsing to validate
  /// that the given [description] is well-formed according to this source, and
  /// to give the source a chance to canonicalize the description.
  ///
  /// [containingPath] is the path to the local file (pubspec or lockfile)
  /// where this description appears. It may be `null` if the description is
  /// coming from some in-memory source (such as pulling down a pubspec from
  /// pub.dartlang.org).
  ///
  /// It should return if a (possibly modified) valid description, or throw a
  /// [FormatException] if not valid.
  ///
  /// [fromLockFile] is true when the description comes from a [LockFile], to
  /// allow the source to use lockfile-specific descriptions via [resolveId].
  dynamic parseDescription(String containingPath, description,
                           {bool fromLockFile: false});

  /// When a [LockFile] is serialized, it uses this method to get the
  /// [description] in the right format.
  ///
  /// [containingPath] is the containing directory of the root package.
  dynamic serializeDescription(String containingPath, description) {
    return description;
  }

  /// When a package [description] is shown to the user, this is called to
  /// convert it into a human-friendly form.
  ///
  /// By default, it just converts the description to a string, but sources
  /// may customize this. [containingPath] is the containing directory of the
  /// root package.
  String formatDescription(String containingPath, description) {
    return description.toString();
  }

  /// Returns whether or not [description1] describes the same package as
  /// [description2] for this source.
  ///
  /// This method should be light-weight. It doesn't need to validate that
  /// either package exists.
  bool descriptionsEqual(description1, description2);

  /// Resolves [id] to a more possibly more precise that will uniquely identify
  /// a package regardless of when the package is requested.
  ///
  /// For some sources, [PackageId]s can point to different chunks of code at
  /// different times. This takes such an [id] and returns a future that
  /// completes to a [PackageId] that will uniquely specify a single chunk of
  /// code forever.
  ///
  /// For example, [GitSource] might take an [id] with description
  /// `http://github.com/dart-lang/some-lib.git` and return an id with a
  /// description that includes the current commit of the Git repository.
  ///
  /// Pub calls this after getting a package, so the source can use the local
  /// package to determine information about the resolved id.
  ///
  /// The returned [PackageId] may have a description field that's invalid
  /// according to [parseDescription], although it must still be serializable
  /// to JSON and YAML. It must also be equal to [id] according to
  /// [descriptionsEqual].
  ///
  /// By default, this just returns [id].
  Future<PackageId> resolveId(PackageId id) => new Future.value(id);

  /// Returns the source's name.
  String toString() => name;
}
