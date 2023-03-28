// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  static bool _result = true;
  const C();
  bool operator ==(Object other) {
    _result = !_result;
    return _result;
  }
}

instanceConstant(Object obj) => /*type=Object*/ switch (obj) {
      const C() /*space=?*/ => 'one',
      const C() /*space=?*/ => 'two',
      _ /*space=Object*/ => 'other',
    };

recordConstant(
        Object
            obj) => /*cfe.
             fields={$1:-,$2:-},
             type=Object
            */ /*analyzer.
 fields={$1:-,$2:-},
 type=Object
*/
    switch (obj) {
      const (1, const C()) /*space=(1, ?)*/ => 'one',
      const (1, const C()) /*space=(1, ?)*/ => 'two',
      _ /*space=Object*/ => 'other',
    };
