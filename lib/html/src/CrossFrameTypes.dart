// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Window {
  // Fields.
  Location get location;
  History get history;

  bool get closed;
  Window get opener;
  Window get parent;
  Window get top;

  // TODO(vsm): Add frames to navigate subframes.  See 2312.

  // Methods.
  void focus();
  void blur();
  void close();
  void postMessage(Dynamic message,
                   String targetOrigin,
		   [List messagePorts = null]);
}

abstract class Location {
  void set href(String val);
}

abstract class History {
  void back();
  void forward();
  void go(int distance);
}