// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirrors.visitor;

import 'dart:mirrors';

abstract class MirrorsVisitor {
  visitMirror(Mirror mirror) {
    if (mirror == null) return;

    if (mirror is FunctionTypeMirror) {
      visitFunctionTypeMirror(mirror);
    } else if (mirror is ClassMirror) {
      visitClassMirror(mirror);
    } else if (mirror is TypedefMirror) {
      visitTypedefMirror(mirror);
    } else if (mirror is TypeVariableMirror) {
      visitTypeVariableMirror(mirror);
    } else if (mirror is TypeMirror) {
      visitTypeMirror(mirror);
    } else if (mirror is ParameterMirror) {
      visitParameterMirror(mirror);
    } else if (mirror is VariableMirror) {
      visitVariableMirror(mirror);
    } else if (mirror is MethodMirror) {
      visitMethodMirror(mirror);
    } else if (mirror is LibraryMirror) {
      visitLibraryMirror(mirror);
    } else if (mirror is InstanceMirror) {
      visitInstanceMirror(mirror);
    } else if (mirror is ObjectMirror) {
      visitObjectMirror(mirror);
    } else if (mirror is DeclarationMirror) {
      visitDeclarationMirror(mirror);
    } else {
      throw new StateError(
          'Unexpected mirror kind ${mirror.runtimeType}: $mirror');
    }
  }

  visitClassMirror(ClassMirror mirror) {
    visitObjectMirror(mirror);
    visitTypeMirror(mirror);
  }

  visitDeclarationMirror(DeclarationMirror mirror) {}

  visitFunctionTypeMirror(FunctionTypeMirror mirror) {
    visitClassMirror(mirror);
  }

  visitInstanceMirror(InstanceMirror mirror) {
    visitObjectMirror(mirror);
  }

  visitLibraryMirror(LibraryMirror mirror) {
    visitObjectMirror(mirror);
    visitDeclarationMirror(mirror);
  }

  visitMethodMirror(MethodMirror mirror) {
    visitDeclarationMirror(mirror);
  }

  visitObjectMirror(ObjectMirror mirror) {}

  visitParameterMirror(ParameterMirror mirror) {
    visitVariableMirror(mirror);
  }

  visitTypedefMirror(TypedefMirror mirror) {
    visitTypeMirror(mirror);
  }

  visitTypeMirror(TypeMirror mirror) {
    visitDeclarationMirror(mirror);
  }

  visitTypeVariableMirror(TypeVariableMirror mirror) {
    visitTypeMirror(mirror);
  }

  visitVariableMirror(VariableMirror mirror) {
    visitDeclarationMirror(mirror);
  }
}
