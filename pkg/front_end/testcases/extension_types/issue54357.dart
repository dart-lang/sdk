// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const ex3 = ExInt(3);
const ex4 = ExInt(4);

const l3 = [ex3];
const l4 = [ex4];
const l34i = [ex3 as int, ... l4 as List<int>];
const l43 = [ex4, ex3];
const l3s4 = [ex3, ... l4];
const ls43 = [... l4, ex3];
const ls3s4 = [... l3, ... l4];

const s3 = {ex3};
const s4 = {ex4};
const s34i = {ex3 as int, ... s4 as Set<int>};
const s43 = {ex4, ex3};
const s3s4 = {ex3, ... s4};
const ss43 = {... s4, ex3};
const ss3s4 = {... s3, ... s4};

const m3 = {ex3: ex3};
const m4 = {ex4: ex4};
const m34i = {ex3 as int: ex3 as int, ... m4 as Map<int, int>};
const m43 = {ex4: ex4, ex3: ex3};
const m3s4 = {ex3: ex3, ... m4};
const ms43 = {... m4, ex3: ex3};
const ms3s4 = {... m3, ... m4};

extension type const ExInt(int _) implements int {}
