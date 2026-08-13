// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ExtensionType1(int i) {}

const implicitConst1 = ExtensionType1(0); /* Error */
var explicitConst1 = const ExtensionType1(0); /* Error */
const newConst1 = new ExtensionType1(0); /* Error */

typedef Typedef1<X> = ExtensionType1;

const implicitConstAliased1 = Typedef1(0); /* Error */
var explicitConstAliased1 = const Typedef1(0); /* Error */
const newConstAliased1 = new Typedef1(0); /* Error */

extension type const ExtensionType2(int i) {}

const implicitConst2 = ExtensionType2(0); /* Ok */
var explicitConst2 = const ExtensionType2(0); /* Ok */
const newConst2 = new ExtensionType2(0); /* Error */

typedef Typedef2<X> = ExtensionType2;

const implicitConstAliased2 = Typedef2(0); /* Ok */
var explicitConstAliased2 = const Typedef2(0); /* Ok */
const newConstAliased2 = new Typedef2(0); /* Error */
