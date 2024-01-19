// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET(int i) {}

const dynamic tearOff = ET.new;

const a = [tearOff]; // Ok
const b = <ET Function(int)>[tearOff]; // Ok
const c = <int Function(int)>[tearOff]; // Ok

const d = [ET.new]; // Ok
const e = <ET Function(int)>[ET.new]; // Ok
const f = <int Function(int)>[ET.new]; // Error