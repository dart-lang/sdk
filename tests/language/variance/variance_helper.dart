// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Common declarations for testing variance.

class LegacyCovariant<T>;

class Covariant<out T>;

class Contravariant<in T>;

class Invariant<inout T>;

mixin MLegacyCovariant<T>;

mixin MCovariant<out T>;

mixin MContravariant<in T>;

mixin MInvariant<inout T>;

typedef CovFunction<T> = T Function();

typedef ContraFunction<T> = void Function(T);

typedef InvFunction<T> = T Function(T);

typedef InvBoundFunction<T> = void Function<X extends T>();

class Multi<out T, inout U, in V>;

class Exactly<inout T>;

Exactly<T> exactly<T>(T x) => new Exactly<T>();

class Upper;

class Middle extends Upper;

class Lower extends Middle;
