// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:web/web.dart';

import 'package:observatory/src/elements/helpers/element_utils.dart';

HTMLElement navBar(List<HTMLElement> content) {
  return (document.createElement('nav')
    ..className = 'nav-bar'
    ..appendChild(
      new HTMLUListElement()..appendChildren(content),
    )) as HTMLElement;
}
