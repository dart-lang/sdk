// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:web/web.dart';

navMenu(String label, {String? link, List<HTMLElement> content = const []}) {
  final ulist = new HTMLUListElement();
  for (final element in content) {
    ulist.appendChild(element);
  }
  return new HTMLLIElement()
    ..className = 'nav-menu'
    ..appendChild(new HTMLSpanElement()
      ..className = 'nav-menu_label'
      ..appendChild(new HTMLAnchorElement()
        ..href = link ?? ''
        ..text = label)
      ..appendChild(ulist));
}
