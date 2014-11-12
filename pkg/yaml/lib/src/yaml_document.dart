// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.yaml_document;

import 'dart:collection';

import 'package:source_span/source_span.dart';

import 'yaml_node.dart';

/// A YAML document, complete with metadata.
class YamlDocument {
  /// The contents of the document.
  final YamlNode contents;

  /// The span covering the entire document.
  final SourceSpan span;

  /// The version directive for the document, if any.
  final VersionDirective versionDirective;

  /// The tag directives for the document.
  final List<TagDirective> tagDirectives;

  /// Whether the beginning of the document was implicit (versus explicit via
  /// `===`).
  final bool startImplicit;

  /// Whether the end of the document was implicit (versus explicit via `...`).
  final bool endImplicit;

  /// Users of the library should not use this constructor.
  YamlDocument.internal(this.contents, this.span, this.versionDirective,
          List<TagDirective> tagDirectives, {this.startImplicit: false,
          this.endImplicit: false})
      : tagDirectives = new UnmodifiableListView(tagDirectives);

  String toString() => contents.toString();
}

/// A directive indicating which version of YAML a document was written to.
class VersionDirective {
  /// The major version number.
  final int major;

  /// The minor version number.
  final int minor;

  VersionDirective(this.major, this.minor);

  String toString() => "%YAML $major.$minor";
}

/// A directive describing a custom tag handle.
class TagDirective {
  /// The handle for use in the document.
  final String handle;

  /// The prefix that the handle maps to.
  final String prefix;

  TagDirective(this.handle, this.prefix);

  String toString() => "%TAG $handle $prefix";
}
