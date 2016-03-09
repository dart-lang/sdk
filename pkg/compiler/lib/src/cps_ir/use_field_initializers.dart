// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.cps_ir.use_field_initializers;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart';

/// Eliminates [SetField] instructions when the value can instead be passed into
/// the field initializer of a [CreateInstance] instruction.
///
/// This compensates for a somewhat common pattern where fields are initialized
/// in the constructor body instead of using intializers. For example:
///
///     class Foo {
///       var x, y;
///       Foo(x, y) {
///          this.x = x;
///          this.y = y;
///        }
///      }
///
///   ==> (IR for Foo constructor)
///
///      foo = new D.Foo(null, null);
///      foo.x = 'a';
///      foo.y = 'b';
///
///   ==> (after this pass)
///
///      foo = new D.Foo('a', 'b');
//
// TODO(asgerf): Store forwarding and load elimination could most likely
//   handle this more generally.
//
class UseFieldInitializers extends BlockVisitor implements Pass {
  String get passName => 'Use field initializers';

  final JavaScriptBackend backend;

  final Set<CreateInstance> unescaped = new Set<CreateInstance>();

  /// Continuation bindings separating the current traversal position from an
  /// unescaped [CreateInstance].  When [CreateInstance] is sunk, these
  /// continuations must sink as well to ensure the object remains in scope
  /// inside the bound continuations.
  final List<LetCont> letConts = <LetCont>[];

  /// If non-null, the bindings in [letConts] should sink to immediately below
  /// this node.
  InteriorNode letContSinkTarget = null;
  EscapeVisitor escapeVisitor;

  UseFieldInitializers(this.backend);

  void rewrite(FunctionDefinition node) {
    escapeVisitor = new EscapeVisitor(this);
    BlockVisitor.traverseInPreOrder(node, this);
  }

  void escape(Reference ref) {
    Definition def = ref.definition;
    if (def is CreateInstance) {
      unescaped.remove(def);
      if (unescaped.isEmpty) {
        sinkLetConts();
        letConts.clear();
      }
    }
  }

  void visitContinuation(Continuation node) {
    endBasicBlock();
  }
  void visitLetHandler(LetHandler node) {
    endBasicBlock();
  }
  void visitInvokeContinuation(InvokeContinuation node) {
    endBasicBlock();
  }
  void visitBranch(Branch node) {
    endBasicBlock();
  }
  void visitRethrow(Rethrow node) {
    endBasicBlock();
  }
  void visitThrow(Throw node) {
    endBasicBlock();
  }
  void visitUnreachable(Unreachable node) {
    endBasicBlock();
  }

  void visitLetMutable(LetMutable node) {
    escape(node.valueRef);
  }

  void visitLetCont(LetCont node) {
    if (unescaped.isNotEmpty) {
      // Ensure we do not lift a LetCont if there is a sink target set above
      // the current node.
      sinkLetConts();
      letConts.add(node);
    }
  }

  void sinkLetConts() {
    if (letContSinkTarget != null) {
      for (LetCont letCont in letConts.reversed) {
        letCont..remove()..insertBelow(letContSinkTarget);
      }
      letContSinkTarget = null;
    }
  }

  void endBasicBlock() {
    sinkLetConts();
    letConts.clear();
    unescaped.clear();
  }

  void visitLetPrim(LetPrim node) {
    Primitive prim = node.primitive;
    if (prim is CreateInstance) {
      unescaped.add(prim);
      prim.argumentRefs.forEach(escape);
      return;
    }
    if (unescaped.isEmpty) return;
    if (prim is SetField) {
      escape(prim.valueRef);
      Primitive object = prim.object;
      if (object is CreateInstance && unescaped.contains(object)) {
        int index = getFieldIndex(object.classElement, prim.field);
        if (index == -1) {
          // This field is not initialized at creation time, so we cannot pull
          // set SetField into the CreateInstance instruction.  We have to
          // leave the instruction here, and this counts as a use of the object.
          escape(prim.objectRef);
        } else {
          // Replace the field initializer with the new value. There are no uses
          // of the object before this, so the old value cannot have been seen.
          object.argumentRefs[index].changeTo(prim.value);
          prim.destroy();
          // The right-hand side might not be in scope at the CreateInstance.
          // Sink the creation down to this point.
          rebindCreateInstanceAt(object, node);
          letContSinkTarget = node;
        }
      }
      return;
    }
    if (prim is GetField) {
      // When reading the field of a newly created object, just use the initial
      // value and destroy the GetField. This can unblock the other optimization
      // since we remove a use of the object.
      Primitive object = prim.object;
      if (object is CreateInstance && unescaped.contains(object)) {
        int index = getFieldIndex(object.classElement, prim.field);
        if (index == -1) {
          escape(prim.objectRef);
        } else {
          prim.replaceUsesWith(object.argument(index));
          prim.destroy();
          node.remove();
        }
      }
      return;
    }
    escapeVisitor.visit(node.primitive);
  }

  void rebindCreateInstanceAt(CreateInstance prim, LetPrim newBinding) {
    removeBinding(prim);
    newBinding.primitive = prim;
    prim.parent = newBinding;
  }

  /// Returns the index of [field] in the canonical initialization order in
  /// [classElement], or -1 if the field is not initialized at creation time
  /// for that class.
  int getFieldIndex(ClassElement classElement, FieldElement field) {
    // There is no stored map from a field to its index in a given class, so we
    // have to iterate over all instance fields until we find it.
    int current = -1, index = -1;
    classElement.forEachInstanceField((host, currentField) {
      if (!backend.isNativeOrExtendsNative(host)) {
        ++current;
        if (currentField == field) {
          index = current;
        }
      }
    }, includeSuperAndInjectedMembers: true);
    return index;
  }

  void removeBinding(Primitive prim) {
    LetPrim node = prim.parent;
    node.remove();
  }
}

class EscapeVisitor extends DeepRecursiveVisitor {
  final UseFieldInitializers main;
  EscapeVisitor(this.main);

  processReference(Reference ref) {
    main.escape(ref);
  }
}
