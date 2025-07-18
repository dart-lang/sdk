// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// This class provides access to [Scope]s corresponding to [AstNode]s.
class LinkingNodeContext {
  static final _expando = Expando<LinkingNodeContext>();

  final Scope scope;

  LinkingNodeContext(AstNode node, this.scope) {
    _expando[node] = this;
  }

  static LinkingNodeContext get(AstNode node) {
    var context = _expando[node];
    if (context == null) {
      throw StateError('No context for: $node');
    }
    return context;
  }
}
