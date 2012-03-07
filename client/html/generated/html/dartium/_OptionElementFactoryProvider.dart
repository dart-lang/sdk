// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _OptionElementFactoryProvider {
  factory OptionElement([String data = null, String value = null, bool defaultSelected = null, bool selected = null]) =>
      _wrap(new dom.HTMLOptionElement(_unwrap(data), _unwrap(value), _unwrap(defaultSelected), _unwrap(selected)));
}
