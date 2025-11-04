// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A shorthand for the type of a map produced by the json decoder.
typedef JsonMap = Map<String, Object?>;

/// An identifier for a process that can both send and received messages.
enum ProcessId {
  /// The Dart tooling daemon.
  dtd('dtd'),

  /// The IDE (or client).
  ide('ide'),

  /// The analysis server.
  server('server'),

  /// The plugin isolate (even though technically it isn't a separate process).
  plugin('plugin'),

  /// The file system's file watcher.
  watcher('watcher');

  /// A map used to associate processes with their name.
  ///
  /// Used to support [Process.forName].
  static Map<String, ProcessId> _nameMap = {
    for (var value in values) value.name: value,
  };

  /// The name of the process.
  final String name;

  /// Creates a new process with the given [name].
  const ProcessId(this.name);

  /// Returns the process with the given [name].
  factory ProcessId.forName(String name) => _nameMap[name]!;
}
