// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue45626.dart' as self;

class C {}
typedef CAlias = C;

class D implements C, C {}
class D2 implements C, CAlias {}
class D3 implements CAlias, C {}
class D4 implements C, self.C {}
class D5 implements self.C, C {}

mixin CM on C, C {}
mixin CM2 on C, CAlias {}
mixin CM3 on CAlias, C {}
mixin CM4 on self.C, C {}
mixin CM5 on C, self.C {}

main() {}
