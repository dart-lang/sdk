// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test: inference error when returning a closure from an async
// function.
//
// For details, see: https://github.com/dart-lang/sdk/issues/52825

Future<double Function(int)> get getter async =>
    // The parameter `p` in this closure is accidentally treated as having
    // an empty type mask. As a result `.toDouble` is tree-shaken.
    //
    // Adding an `await` circumvents this issue.
    (int p) => p.toDouble();

main() => getter.then((double Function(int) f) => f(1));
