// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of regress_39168;

// This class is not used and tree-shaken.
// However, mixin application B with C is de-duplicated with
// mixin application in regress_39168_part2.dart. This mixin application is
// the only thing which is used from regress_39168_part1.dart.
// As mixin application is a synthetic code, line numbers are not included
// for regress_39168_part1.dart script.
class A extends B with C {}
