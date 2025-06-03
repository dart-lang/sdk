// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Foo { e1, e2, e3 }

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() => Foo.e2;
