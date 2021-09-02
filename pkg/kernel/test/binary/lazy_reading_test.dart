// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/src/tool/find_referenced_libraries.dart';
import 'utils.dart';

void main() {
  Library lib;
  {
    /// Create a library with two classes (A and B) where class A - in its
    /// constructor - invokes the constructor for B.
    final Uri uri = Uri.parse('org-dartlang:///lib.dart');
    lib = new Library(uri, fileUri: uri);
    final Class classA = new Class(name: "A", fileUri: uri);
    lib.addClass(classA);
    final Class classB = new Class(name: "B", fileUri: uri);
    lib.addClass(classB);

    final Constructor classBConstructor = new Constructor(
        new FunctionNode(new EmptyStatement()),
        name: new Name(""),
        fileUri: uri);
    classB.addConstructor(classBConstructor);

    final Constructor classAConstructor = new Constructor(
        new FunctionNode(new ExpressionStatement(new ConstructorInvocation(
            classBConstructor, new Arguments.empty()))),
        name: new Name(""),
        fileUri: uri);
    classA.addConstructor(classAConstructor);
  }
  Component c = new Component(libraries: [lib]);
  c.setMainMethodAndMode(null, false, NonNullableByDefaultCompiledMode.Weak);
  List<int> loadMe = serializeComponent(c);

  // Load and make sure we can get at class B from class A (i.e. that it's
  // loaded correctly!).
  Component loadedComponent = new Component();
  new BinaryBuilder(loadMe,
          disableLazyReading: false, disableLazyClassReading: false)
      .readSingleFileComponent(loadedComponent);
  {
    final Library loadedLib = loadedComponent.libraries.single;
    final Class loadedClassA = loadedLib.classes.first;
    final ExpressionStatement loadedConstructorA =
        loadedClassA.constructors.single.function.body as ExpressionStatement;
    final ConstructorInvocation loadedConstructorInvocation =
        loadedConstructorA.expression as ConstructorInvocation;
    final Class pointedToClass =
        loadedConstructorInvocation.target.enclosingClass;
    final Library pointedToLib =
        loadedConstructorInvocation.target.enclosingLibrary;

    Set<Library> reachable = findAllReferencedLibraries([loadedLib]);
    if (reachable.length != 1 || reachable.single != loadedLib) {
      throw "Expected only the single library to be reachable, "
          "but found $reachable";
    }

    final Class loadedClassB = loadedLib.classes[1];
    if (loadedClassB != pointedToClass) {
      throw "Doesn't point to the right class";
    }
    if (pointedToLib != loadedLib) {
      throw "Doesn't point to the right library";
    }
  }
  // Attempt to load again, overwriting the old stuff. This should logically
  // "relink" to the newly loaded version.
  Component loadedComponent2 = new Component(nameRoot: loadedComponent.root);
  new BinaryBuilder(loadMe,
          disableLazyReading: false,
          disableLazyClassReading: false,
          alwaysCreateNewNamedNodes: true)
      .readSingleFileComponent(loadedComponent2);
  {
    final Library loadedLib = loadedComponent2.libraries.single;
    final Class loadedClassA = loadedLib.classes.first;
    final ExpressionStatement loadedConstructorA =
        loadedClassA.constructors.single.function.body as ExpressionStatement;
    final ConstructorInvocation loadedConstructorInvocation =
        loadedConstructorA.expression as ConstructorInvocation;
    final Class pointedToClass =
        loadedConstructorInvocation.target.enclosingClass;
    final Library pointedToLib =
        loadedConstructorInvocation.target.enclosingLibrary;

    Set<Library> reachable = findAllReferencedLibraries([loadedLib]);
    if (reachable.length != 1 || reachable.single != loadedLib) {
      throw "Expected only the single library to be reachable, "
          "but found $reachable";
    }

    final Class loadedClassB = loadedLib.classes[1];
    if (loadedClassB != pointedToClass) {
      throw "Doesn't point to the right class";
    }
    if (pointedToLib != loadedLib) {
      throw "Doesn't point to the right library";
    }
  }
}
