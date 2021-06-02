// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This test verifies that `f<T, U>(0)` is properly parsed as a generic
// invocation, for all type syntaxes that may appear as T and U.

// Note: it doesn't really matter what we import here; it's just a handy library
// that has declares a types so that we can refer a type via a prefix.
import 'dart:async' as prefix;

import '../syntax_helper.dart';

class C extends SyntaxTracker {
  C([Object x = absent, Object y = absent])
      : super('new C${SyntaxTracker.args(x, y)}');
}

/// Helper function to work around the fact that not all types can be expressed
/// as type literals.
Type typeOf<T>() => T;

main() {
  SyntaxTracker.known[C] = 'C';
  SyntaxTracker.known[prefix.Zone] = 'prefix.Zone';
  SyntaxTracker.known[dynamic] = 'dynamic';
  SyntaxTracker.known[typeOf<List<C>>()] = 'List<C>';
  SyntaxTracker.known[typeOf<void Function()>()] = 'void Function()';
  checkSyntax(f(f<C, C>(0)), 'f(f<C, C>(0))');
  checkSyntax(f(f<dynamic, C>(0)), 'f(f<dynamic, C>(0))');
  checkSyntax(f(f<prefix.Zone, C>(0)), 'f(f<prefix.Zone, C>(0))');
  checkSyntax(f(f<List<C>, C>(0)), 'f(f<List<C>, C>(0))');
  checkSyntax(f(f<void Function(), C>(0)), 'f(f<void Function(), C>(0))');
  checkSyntax(f(f<C, dynamic>(0)), 'f(f<C, dynamic>(0))');
  checkSyntax(f(f<C, prefix.Zone>(0)), 'f(f<C, prefix.Zone>(0))');
  checkSyntax(f(f<C, List<C>>(0)), 'f(f<C, List<C>>(0))');
  checkSyntax(f(f<C, void Function()>(0)), 'f(f<C, void Function()>(0))');
}
