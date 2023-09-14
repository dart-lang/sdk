// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E1(E1 it) /* Error */ {}

extension type E2a(E2b it) /* Error */ {}
extension type E2b(E2a it) /* Error */ {}

extension type E3a(E3b it) /* Error */ {}
extension type E3b(E3c it) /* Error */ {}
extension type E3c(E3a it) /* Error */ {}

extension type E4(E4 Function() it) /* Error */ {}

extension type E5(void Function(E5) it) /* Error */ {}

extension type E6((E6, int) it) /* Error */ {}

extension type E7(void Function<T extends E7>() it) /* Error */ {}

extension type E8<T>(List<E8> it) /* Error */ {}

typedef Alias9 = E9;
extension type E9(Alias9 it) /* Error */ {}

typedef Alias10<T> = E10<T>;
extension type E10<T>(Alias10<T> it) /* Error */ {}

typedef Alias11 = E11 Function();
extension type E11(Alias11 it) /* Error */ {}

typedef Alias12 = void Function(E12);
extension type E12(Alias12 it) /* Error */ {}

typedef Alias13 = void Function<T extends E13>();
extension type E13(Alias13 it) /* Error */ {}

typedef Alias14<T> = int;
extension type E14(Alias14<E14> it) /* Ok */ {}

typedef Alias15<T> = List<T>;
extension type E15a(Alias15<E15b> it) /* Error */ {}
extension type E15b(Alias15<E15a> it) /* Error */ {}

typedef Alias16a<T> = List<E16b>;
typedef Alias16b<T> = List<E16a>;
extension type E16a(Alias16a<int> it) /* Error */ {}
extension type E16b(Alias16b<int> it) /* Error */ {}

extension type E17((int, {E17 a}) it) /* Error */ {}

typedef Alias18a<T> = Alias18b<E18>;
typedef Alias18b<T> = void Function(T);
extension type E18(Alias18a<int> it) /* Error */ {}

extension type E19a((E19b, E19b) it) /* Ok */ {}
extension type E19b(int it) /* Ok */ {}

typedef Alias20 = Alias20; /* Error */
extension type E20(Alias20 it) /* Ok */ {}

typedef Alias21 = int; /* Ok */
extension type E21(Alias21<int> it) /* Error */ {}

typedef Alias22a = Alias22b<int>; /* Error */
typedef Alias22b = int;
extension type E22(Alias22a it) /* Ok */ {}

typedef Alias23<T extends E23> = List<T>;
extension type E23(Alias23 it) /* Error */ {}

typedef Alias24<T extends E24<T>> = List<T>;
extension type E24<T>(Alias24 it) /* Error */ {}

