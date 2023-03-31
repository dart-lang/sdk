// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method(Unresolved o) {
  switch (o) {
    case [_]:
    case [_, ...var a, _]:
    case [...]:
    case {0: 1}:
    case String(length: 5):
    case == 5:
    case < 5: // TODO(johnniwinther): Why do we get an error here?
    case (0, :var a):
  }
}
