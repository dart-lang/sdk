// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.declaration;

import '../problems.dart' show unsupported;

abstract class Declaration {
  /// Used when multiple things with the same name are declared within the same
  /// parent. Only used for top-level and class-member declarations, not for
  /// block scopes.
  Declaration next;

  Declaration();

  Declaration get parent;

  Uri get fileUri;

  int get charOffset;

  get target => unsupported("${runtimeType}.target", charOffset, fileUri);

  Declaration get origin => this;

  String get fullNameForErrors;

  bool get buildsArguments => false;

  bool get hasProblem => false;

  bool get hasTarget => false;

  bool get isConst => false;

  bool get isConstructor => false;

  bool get isFactory => false;

  bool get isField => false;

  bool get isFinal => false;

  bool get isGetter => false;

  bool get isInstanceMember => false;

  bool get isLocal => false;

  bool get isPatch => this != origin;

  bool get isRegularMethod => false;

  bool get isSetter => false;

  bool get isStatic => false;

  bool get isSynthetic => false;

  bool get isTopLevel => false;

  bool get isTypeDeclaration => false;

  bool get isTypeVariable => false;

  /// Applies [patch] to this declaration.
  void applyPatch(Declaration patch) {
    unsupported("${runtimeType}.applyPatch", charOffset, fileUri);
  }

  /// Returns the number of patches that was finished.
  int finishPatch() {
    if (!isPatch) return 0;
    unsupported("${runtimeType}.finishPatch", charOffset, fileUri);
    return 0;
  }

  /// Resolve constructors (lookup names in scope) recorded in this builder and
  /// return the number of constructors resolved.
  int resolveConstructors(covariant Declaration parent) => 0;

  void instrumentTopLevelInference(covariant instrumentation) {}
}
