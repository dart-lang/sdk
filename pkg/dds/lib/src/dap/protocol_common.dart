// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A base class for (spec-generated) classes that represent the `body` of a an
/// event.
abstract class EventBody {
  static bool canParse(Object? obj) => obj is Map<String, Object?>?;
}

/// A base class for (spec-generated) classes that represent the `arguments` of
/// a request.
abstract class RequestArguments {
  static bool canParse(Object? obj) => obj is Map<String, Object?>?;
}
