// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library args.utils;

/// Pads [source] to [length] by adding spaces at the end.
String padRight(String source, int length) =>
    source + ' ' * (length - source.length);
