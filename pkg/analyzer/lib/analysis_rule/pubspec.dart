// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:source_span/source_span.dart';

/// Representation of a key/value pair which maps a package name to a
/// _package description_.
///
/// **Example** of a path-dependency:
/// ```yaml
/// dependencies:
///   <name>:
///     version: <version>
///     path: <path>
/// ```
abstract class PubspecDependency {
  /// The git dependency section, if specified.
  PubspecGitRepo? get git;

  /// The host section, if specified.
  PubspecHost? get host;

  /// The dependency name, if specified.
  PubspecNode? get name;

  /// The path section, if specified.
  PubspecEntry? get path;

  /// The dependency version, if specified.
  PubspecEntry? get version;
}

/// Representation of the map from package name to _package description_ used
/// under `dependencies`, `dev_dependencies` and `dependency_overrides`.
abstract class PubspecDependencyList with IterableMixin<PubspecDependency> {}

/// Representation of a YAML section in a pubspec file.
class PubspecEntry {
  final PubspecNode? key;
  final PubspecNode value;

  PubspecEntry(this.key, this.value);

  @override
  String toString() => '${key != null ? '$key: ' : ''}$value';
}

/// Representation of an `environment` section in a pubspec file.
///
/// **Example** of an environment:
/// ```yaml
/// environment:
///   sdk: '>=2.12.0 <4.0.0'
///   flutter: ^3.3.10
/// ```
abstract class PubspecEnvironment implements PubspecSection {
  /// The `flutter` section, if specified.
  PubspecEntry? get flutter;

  /// The (Dart) `sdk` section, if specified.
  PubspecEntry? get sdk;
}

/// Representation of git-dependency section in a pubspec file.
///
/// **Example** of a git-dependency:
/// ```yaml
/// dependencies:
///   foo:
///     git: # <-- this is the [token] property
///       url: https://github.com/example/example
///       ref: main # ref is optional
/// ```
///
/// This may also be written in the form:
/// ```yaml
/// dependencies:
///   foo:
///     git:       https://github.com/example/example
///     # ^-token  ^--url
///     # In this case [ref] is `null`.
/// ```
abstract class PubspecGitRepo implements PubspecSection {
  /// [PubspecEntry] for `ref: main` where [PubspecEntry.key] is `ref` and
  /// [PubspecEntry.value] is `main`.
  PubspecEntry? get ref;

  /// [PubspecEntry] for `url: https://...` or `git: https://`, where [PubspecEntry.key]
  /// is either `url` or `git`, and [PubspecEntry.key] is the URL.
  ///
  /// If the git-dependency is given in the form:
  /// ```yaml
  /// dependencies:
  ///   foo:
  ///     git:       https://github.com/example/example
  /// ```
  /// Then [token] and `url.key` will be the same object.
  PubspecEntry? get url;
}

/// A section describing where a package is hosted in a custom package
/// repository.
abstract class PubspecHost implements PubspecSection {
  /// True, if _short-form_ for writing hosted-dependencies was used.
  ///
  /// **Example** of a hosted-dependency written in short-form:
  /// ```yaml
  /// dependencies:
  ///   foo:
  ///     hosted: https://some-pub-server.com
  ///     version: ^1.2.3
  /// ```
  ///
  /// The _long-form_ for writing the dependency given above is:
  /// ```yaml
  /// dependencies:
  ///   foo:
  ///     hosted:
  ///       url: https://some-pub-server.com
  ///       name: foo
  ///     version: ^1.2.3
  /// ```
  ///
  /// The short-form was added in Dart 2.15.0 because:
  ///  * The `name` property just specifies the package name, which can be
  ///    inferred from the context. So it is unnecessary to write it.
  ///  * The nested object and `url` key becomes unnecessary when the `name`
  ///    property is removed.
  bool get isShortForm;

  /// The name of the package at the package repository.
  PubspecEntry? get name;

  /// The URL of the package repository.
  PubspecEntry? get url;
}

/// Representation of a leaf-node in a pubspec file.
abstract class PubspecNode {
  /// Information about this node's location in the pubspec file.
  SourceSpan get span;

  /// String value of the node, or `null` if value in the pubspec file is `null`
  /// or omitted.
  ///
  /// **Example**
  /// ```
  /// name: foo
  /// version:
  /// ```
  /// In the example above the [PubspecNode] for `foo` will have [text] "foo", and
  /// the [PubspecNode] for `version` will have not have [text] as `null`, as empty
  /// value or `"null"` is the same in YAML.
  String? get text;
}

/// A list of [PubspecNode]s in a section.
abstract class PubspecNodeList
    with IterableMixin<PubspecNode>
    implements PubspecSection {
  @override
  Iterator<PubspecNode> get iterator;
}

abstract class PubspecSection {
  /// The node for this section's key.
  ///
  /// This is primarily used in the string representation of node classes.
  PubspecNode get token;
}

/// A visitor that visits various semantic sections of a pubspec file.
abstract class PubspecVisitor<T> {
  T? visitPackageAuthor(PubspecEntry author) => null;

  T? visitPackageAuthors(PubspecNodeList authors) => null;

  T? visitPackageDependencies(PubspecDependencyList dependencies) => null;

  T? visitPackageDependency(PubspecDependency dependency) => null;

  T? visitPackageDependencyOverride(PubspecDependency dependency) => null;

  T? visitPackageDependencyOverrides(PubspecDependencyList dependencies) =>
      null;

  T? visitPackageDescription(PubspecEntry description) => null;

  T? visitPackageDevDependencies(PubspecDependencyList dependencies) => null;

  T? visitPackageDevDependency(PubspecDependency dependency) => null;

  T? visitPackageDocumentation(PubspecEntry documentation) => null;

  T? visitPackageEnvironment(PubspecEnvironment environment) => null;

  T? visitPackageHomepage(PubspecEntry homepage) => null;

  T? visitPackageIssueTracker(PubspecEntry issueTracker) => null;

  T? visitPackageName(PubspecEntry name) => null;

  T? visitPackageRepository(PubspecEntry repository) => null;

  T? visitPackageVersion(PubspecEntry version) => null;
}
