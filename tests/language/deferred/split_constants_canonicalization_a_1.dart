// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "split_constants_canonicalization_test.dart";

@pragma("vm:never-inline")
mint() => 0x7FFFFFFFFFFFF000; // Boxed 64-bit integer on VM.

@pragma("vm:never-inline")
string() => "We all have identical strings";

@pragma("vm:never-inline")
list() => const <String>["We all have identical lists"];

@pragma("vm:never-inline")
map() => const <String, String>{"We all have": "identical maps"};

@pragma("vm:never-inline")
box() => const Box("We all have identical boxes");

@pragma("vm:never-inline")
enumm() => Enum.GREEN;

@pragma("vm:never-inline")
type() => Box;

@pragma("vm:never-inline")
closure() => commonClosure;
