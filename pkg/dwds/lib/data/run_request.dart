// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A request to run the application's main method.
class RunRequest {
  RunRequest();

  Map<String, dynamic> toJson() => {};

  factory RunRequest.fromJson(Map<String, dynamic> json) {
    return RunRequest();
  }
}
