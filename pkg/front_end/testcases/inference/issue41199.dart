// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo<X>(Map<X, Y> Function<Y>() f) => null;
baz() => foo(<Z>() => <dynamic, Z>{});

main() {}
