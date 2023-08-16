// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Contravariant<T> = void Function(T);
typedef Invariant<T> = void Function<S extends T>();
typedef Covariant<T> = T Function();
typedef Bivariant<T> = T Function(T);

extension type ET_Contravariant<T>(void Function(T) f) /* Error */ {}

extension type ET_Invariant<T>(void Function<S extends T>() f) /* Error */ {}

extension type ET_Covariant<T>(T Function() f) /* Ok */ {}

extension type ET_Bivariant<T>(T Function(T) f) /* Error */ {}

extension type ET_ContravariantAlias<T>(Contravariant<T> f) /* Error */ {}

extension type ET_InvariantAlias<T>(Invariant<T> f) /* Error */ {}

extension type ET_CovariantAlias<T>(Covariant<T> f) /* Ok */ {}

extension type ET_BivariantAlias<T>(Bivariant<T> f) /* Error */ {}

extension type ET_ContravariantAlias1<T>
    (Contravariant<T> Function() f) /* Error */ {}

extension type ET_ContravariantAlias2<T>
    (void Function(Covariant<T>) f) /* Error */ {}

extension type ET_CovariantAlias1<T>
    (Covariant<T> Function() f) /* Ok */ {}

extension type ET_CovariantAlias2<T>
    (void Function(Contravariant<T>) f) /* Ok */ {}
