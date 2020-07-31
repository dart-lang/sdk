// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This has crashed DDC with Kernel because of a
// "Concurrent modification during iteration" exception.

import 'class_in_other_file_helper.dart';

typedef bool Foo1(bool baz);
typedef bool Foo2(Bar baz);

main() {}
