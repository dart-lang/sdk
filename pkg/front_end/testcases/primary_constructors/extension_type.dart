// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET0(int it);

extension type ET1(final bool it);

extension type ET2([int?it]);

extension type ET3([final bool? it]);

extension type ET4([int it = 42]);

extension type ET5([final bool it = true]);

extension type ET6({String? it});

extension type ET7({final List<int>? it});

extension type ET8({String? it = 'foo'});

extension type ET9({final List<int>? it = const [0]});

extension type ET10({required String it});

extension type ET11({required final List<int> it});

main() {
  ET0(0);

  ET1(true);

  ET2();
  ET2(null);
  ET2(0);

  ET3();
  ET3(null);
  ET3(true);

  ET4();
  ET4(87);

  ET5();
  ET5(false);

  ET6();
  ET6(it: null);
  ET6(it: 'foo');

  ET7();
  ET7(it: null);
  ET7(it: [42]);

  ET8();
  ET8(it: 'bar');

  ET9();
  ET9(it: [42]);

  ET10(it: 'foo');

  ET11(it: [42]);
}