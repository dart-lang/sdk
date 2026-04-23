// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An event that signifies the main isolate has exited.
class IsolateExit {
  IsolateExit();

  factory IsolateExit.fromJson(Map<String, dynamic> _) => IsolateExit();

  Map<String, dynamic> toJson() => {};

  @override
  String toString() => 'IsolateExit{}';
}

/// An event that signifies the main isolate has started.
class IsolateStart {
  IsolateStart();

  factory IsolateStart.fromJson(Map<String, dynamic> _) => IsolateStart();

  Map<String, dynamic> toJson() => {};

  @override
  String toString() => 'IsolateStart{}';
}
