// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma("vm:external-name", "ExternalFoo")
external int externalFoo<T>(int a, {String b = 'bb'});

void main() {}
