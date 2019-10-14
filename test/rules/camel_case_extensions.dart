// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N camel_case_extensions`

extension fooBar // LINT
    on Object  { }

extension Foo_Bar //LINT
    on Object {}

extension FooBar //OK
    on Object {}

extension on Object { }  //OK
