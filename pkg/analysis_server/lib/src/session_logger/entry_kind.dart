// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An identifier for the kind of a log entry.
enum EntryKind {
  /// An entry representing the command-line used to start the server.
  ///
  /// Entries of this kind will have the following keys:
  /// - argList
  commandLine('commandLine'),

  /// An entry representing the passing of a message from one process to
  /// another.
  ///
  /// Entries of this kind will have the following keys:
  /// - sender
  /// - receiver
  /// - message
  message('message');

  /// A map used to associate kinds with their name.
  ///
  /// Used to support [EntryKind.forName].
  static Map<String, EntryKind> _nameMap = {
    for (var value in values) value.name: value,
  };

  /// The name of the kind.
  final String name;

  /// Creates a new kind with the given [name].
  const EntryKind(this.name);

  /// Returns the kind with the given [name].
  factory EntryKind.forName(String name) => _nameMap[name]!;
}
