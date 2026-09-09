// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef a(x, x);
typedef b(x, [x]);
typedef c([x, x]);

typedef int F1(_, int _);
typedef int F2(_, int _, [_, int _]);
typedef int F3<T>(T _, T _, [T? _, T? _]);
typedef F4 = int Function(dynamic _, int _);
typedef F5 = int Function(dynamic _, int _, [dynamic _, int _]);
typedef F6<T> = int Function(T _, T _, [T? _, T? _]);
