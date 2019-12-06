// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

nullAwareListSpread(List<String> list) {
  list = ['foo', ...?list];
}

nullAwareSetSpread(Set<String> set) {
  set = {'foo', ...?set};
}

nullAwareMapSpread(Map<int, String> map) {
  map = {0: 'foo', ...?map};
}

main() {
  nullAwareListSpread(null);
  nullAwareSetSpread(null);
  nullAwareMapSpread(null);
}
