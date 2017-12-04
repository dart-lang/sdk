// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/dependency_grapher_impl.dart' as impl;

/// Generates a representation of the dependency graph of a program.
///
/// Given the Uri of one or more files, this function follows `import`,
/// `export`, and `part` declarations to discover a graph of all files involved
/// in the program.
Future<Graph> graphForProgram(List<Uri> sources, CompilerOptions options) {
  var processedOptions = new ProcessedOptions(options);
  return impl.graphForProgram(sources, processedOptions);
}

/// A representation of the dependency graph of a program.
///
/// Not intended to be extended, implemented, or mixed in by clients.
class Graph {
  /// A list of all library cycles in the program, in topologically sorted order
  /// (each cycle only depends on libraries in the cycles that precede it).
  final topologicallySortedCycles = <LibraryCycleNode>[];
}

/// A representation of a single library cycle in the dependency graph of a
/// program.
///
/// Not intended to be extended, implemented, or mixed in by clients.
class LibraryCycleNode {
  /// A map of all the libraries in the cycle, keyed by the URI of their
  /// defining compilation unit.
  final libraries = <Uri, LibraryNode>{};
}

/// A representation of a single library in the dependency graph of a program.
///
/// Not intended to be extended, implemented, or mixed in by clients.
class LibraryNode {
  /// The URI of this library's defining compilation unit.
  final Uri uri;

  /// A list of the URIs of all of this library's "part" files.
  final parts = <Uri>[];

  /// A list of all the other libraries this library directly depends on.
  final dependencies = <LibraryNode>[];

  LibraryNode(this.uri);
}
