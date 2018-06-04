// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'kernel_builder.dart' show Declaration, Scope;

/// Scope that returns an [UnlinkedDeclaration] if a name can't be resolved.
/// This is intended to be used as the `enclosingScope` in `BodyBuilder` to
/// create ASTs with building outlines.
class UnlinkedScope extends Scope {
  UnlinkedScope() : super.top(isModifiable: false);

  Declaration lookupIn(String name, int charOffset, Uri fileUri,
      Map<String, Declaration> map, bool isInstanceScope) {
    return new UnlinkedDeclaration(name, isInstanceScope, charOffset, fileUri);
  }
}

class UnlinkedDeclaration extends Declaration {
  final String name;

  final bool isInstanceScope;

  @override
  final int charOffset;

  @override
  final Uri fileUri;

  UnlinkedDeclaration(
      this.name, this.isInstanceScope, this.charOffset, this.fileUri);

  @override
  Declaration get parent => null;

  @override
  String get fullNameForErrors => name;
}
