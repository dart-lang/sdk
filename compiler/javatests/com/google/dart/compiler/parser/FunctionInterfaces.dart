// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void VoidCallback1(Event event);
typedef void VoidCallback2(Event event, int x);
typedef void VoidCallback3(Event event, int x, y);
typedef void VoidCallback4(Event event, int x, var y);

typedef Callback1(Event event);
typedef Callback2(Event event, int x);
typedef Callback3(Event event, int x, y);
typedef Callback4(Event event, int x, var y);

typedef int IntCallback1(Event event);
typedef int IntCallback2(Event event, int x);
typedef int IntCallback3(Event event, int x, y);
typedef int IntCallback4(Event event, int x, var y);

typedef Box<int> BoxCallback1(Event event);
typedef Box<int> BoxCallback2(Event event, int x);
typedef Box<int> BoxCallback3(Event event, int x, y);
typedef Box<int> BoxCallback4(Event event, int x, var y);

typedef Box<Box<int>> BoxBoxCallback1(Event event);
typedef Box<Box<int>> BoxBoxCallback2(Event event, int x);
typedef Box<Box<int>> BoxBoxCallback3(Event event, int x, y);
typedef Box<Box<int>> BoxBoxCallback4(Event event, int x, var y);
