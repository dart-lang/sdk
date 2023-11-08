// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef A<T> = (String, int);
typedef B<T> = (T, int);
typedef C<T> = ({T a, int b});
typedef D<T> = (T, T);
typedef E<T> = (void Function(T), int);
typedef F<T> = ({void Function(T) a, int b});
typedef G<T> = (void Function(T), T);
typedef H<T> = (void Function(T), {T b});
