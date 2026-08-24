// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Future<bool> applyState() async => true;

Future<bool> test() async {
  var changed = false;
  try {
    changed |= await applyState();
    return changed;
  } finally {
    print('done');
  }
}

void main() async {
  await test();
}
