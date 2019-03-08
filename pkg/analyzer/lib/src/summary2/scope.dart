// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/declaration.dart';

class Scope {
  final Scope parent;
  final Map<String, Declaration> map;

  Scope(this.parent, this.map);

  Scope.top() : this(null, <String, Declaration>{});

  void declare(String name, Declaration declaration) {
    map[name] = declaration;
  }

  void forEach(f(String name, Declaration declaration)) {
    map.forEach(f);
  }

  Declaration lookup(String name) {
    var declaration = map[name];
    if (declaration != null) return declaration;

    if (parent == null) return null;
    return parent.lookup(name);
  }
}
