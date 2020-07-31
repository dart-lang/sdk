// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'inheritance_from_opt_out_lib.dart';

class Class1 extends LegacyClass1 {}

class Class2<T> extends LegacyClass2<T> {}

class Class3a<T> extends LegacyClass3<T> {}

class Class3b<T> extends LegacyClass3<T> implements GenericInterface<T> {}

class Class4a extends LegacyClass4 {}

class Class4b implements GenericInterface<num> {}

class Class4c implements GenericInterface<num?> {}

class Class4d extends LegacyClass4 implements GenericInterface<num> {}

main() {}
