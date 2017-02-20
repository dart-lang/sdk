// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.runtime.declarations;

import 'types.dart' show FunctionType, Interface, ReifiedType, TypeVariable;

typedef String Id2String(Object id);

/// Represents a class.
///
/// There's one instance of this class for each class in the program.
///
/// Note: not all classes can be represented as a compile-time constants. For
/// example, most core classes, such as, `String`, `int`, and `double`
/// implement `Comparable` in a way that cannot be expressed as a constant.
class Class {
  final id;

  Interface supertype;

  FunctionType callableType;

  final List<TypeVariable> variables;

  List<Interface> interfaces;

  static Id2String debugId2String;

  Class(this.id, this.supertype,
      {this.callableType,
      this.variables: const <TypeVariable>[],
      this.interfaces /* set in init */});

  Interface get thisType {
    return new Interface(this, variables);
  }

  String get name => debugId2String == null ? "$id" : debugId2String(id);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("class $name");
    if (variables.isNotEmpty) {
      sb.write("<");
      bool first = true;
      for (TypeVariable tv in variables) {
        if (!first) {
          sb.write(", ");
        }
        sb.write(tv);
        sb.write(" extends ");
        sb.write(tv.bound);
      }
      sb.write(">");
    }
    if (supertype != null) {
      sb.write(" extends $supertype");
    }
    if (interfaces.isNotEmpty) {
      sb.write(" implements ");
      sb.writeAll(interfaces, ", ");
    }
    return "$sb";
  }
}

/// Allocates a (non-growable) list of [amount] class declarations with ids `0`
/// to `amount - 1`. This function is called from the generated code that
/// initializes the type information.
List<Class> allocateDeclarations(List<String> names, List<int> typeParameters) {
  List<TypeVariable> allocateVariables(int amount) {
    if (amount == 0) return const <TypeVariable>[];
    return new List<TypeVariable>.generate(
        amount, (int i) => new TypeVariable(i),
        growable: false);
  }

  return new List<Class>.generate(
      names.length,
      (int i) => new Class(names[i], null,
          variables: allocateVariables(typeParameters[i])),
      growable: false);
}

/// Initializes the supertype and interfaces of `classes[index]`.
/// This function is called from generated code.
void init(List<Class> classes, int index, ReifiedType supertype,
    [List<Interface> interfaces = const <Interface>[],
    FunctionType callableType]) {
  Class declaration = classes[index];
  assert(supertype == null);
  declaration.supertype = supertype;
  assert(interfaces == null);
  declaration.interfaces = interfaces;
  declaration.callableType = callableType;
}
