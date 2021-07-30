// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  external factory Class.fact({bool defaultValue: true});
  external const factory Class.constFact({bool defaultValue: true});
  external const factory Class.redirect({bool defaultValue: true});
}
