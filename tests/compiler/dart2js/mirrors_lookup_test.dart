// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_source_file_helper;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';
import 'package:compiler/src/mirrors/source_mirrors.dart';
import 'package:compiler/src/mirrors/mirrors_util.dart';

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': r"""

library main;

import 'dart:async' as async show Future;

var variable;

method(a, [b]) {}

class Class<A> {
  var field;
  var variable;
  method(c, {d}) {}
}

class Subclass<B> extends Class<B> {
  var subfield;
}
""",
};

void main() {
  asyncTest(() => mirrorSystemFor(MEMORY_SOURCE_FILES).then(
      (MirrorSystem mirrors) => test(mirrors),
      onError: (e) => Expect.fail('$e')));
}

void test(MirrorSystem mirrors) {
  LibrarySourceMirror dartCore = mirrors.libraries[Uri.parse('dart:core')];
  Expect.isNotNull(dartCore);

  LibrarySourceMirror dartAsync = mirrors.libraries[Uri.parse('dart:async')];
  Expect.isNotNull(dartAsync);

  LibrarySourceMirror library = mirrors.libraries[Uri.parse('memory:main.dart')];
  Expect.isNotNull(library);

  // Check top-level scope.

  DeclarationSourceMirror String_ = library.lookupInScope('String');
  Expect.isTrue(String_ is ClassMirror);
  Expect.equals(#String, String_.simpleName);
  Expect.equals(dartCore, String_.owner);

  Expect.isNull(library.lookupInScope('async'));
  Expect.isNull(library.lookupInScope('Future'));
  DeclarationSourceMirror Future_ = library.lookupInScope('async.Future');
  Expect.isTrue(Future_ is ClassMirror);
  Expect.equals(#Future, Future_.simpleName);
  Expect.equals(dartAsync, Future_.owner);
  // Timer is not in scope.
  Expect.isNull(library.lookupInScope('Timer'));
  // async.Timer is hidden.
  Expect.isNull(library.lookupInScope('async.Timer'));

  DeclarationSourceMirror variable = library.lookupInScope('variable');
  Expect.isTrue(variable is VariableMirror);
  Expect.equals(#variable, variable.simpleName);
  Expect.equals(#main.variable, variable.qualifiedName);
  Expect.equals(library, variable.owner);
  // Parameter `a` is not in scope.
  Expect.isNull(library.lookupInScope('a'));
  // Parameter `b` is not in scope.
  Expect.isNull(library.lookupInScope('b'));

  DeclarationSourceMirror method = library.lookupInScope('method');
  Expect.isTrue(method is MethodMirror);
  Expect.equals(#method, method.simpleName);
  Expect.equals(#main.method, method.qualifiedName);
  Expect.equals(library, method.owner);

  DeclarationSourceMirror Class = library.lookupInScope('Class');
  Expect.isTrue(Class is ClassMirror);
  Expect.equals(#Class, Class.simpleName);
  Expect.equals(#main.Class, Class.qualifiedName);
  Expect.equals(library, Class.owner);
  // Type variable `A` is not in scope.
  Expect.isNull(library.lookupInScope('A'));

  DeclarationSourceMirror Subclass = library.lookupInScope('Subclass');
  Expect.isTrue(Subclass is ClassMirror);
  Expect.equals(#Subclass, Subclass.simpleName);
  Expect.equals(#main.Subclass, Subclass.qualifiedName);
  Expect.equals(library, Subclass.owner);
  // Type variable `B` is not in scope.
  Expect.isNull(library.lookupInScope('B'));

  // Check top-level declaration scope.
  checkTopScope(DeclarationSourceMirror declaration) {
    Expect.equals(String_, declaration.lookupInScope('String'));
    Expect.equals(Future_, declaration.lookupInScope('async.Future'));
    Expect.isNull(method.lookupInScope('Timer'));
    Expect.isNull(declaration.lookupInScope('async.Timer'));
    Expect.equals(variable, declaration.lookupInScope('variable'));
    Expect.equals(method, declaration.lookupInScope('method'));
    Expect.equals(Class, declaration.lookupInScope('Class'));
    // Type variable `A` is not in scope.
    Expect.isNull(declaration.lookupInScope('A'));
    // Field `field` is not in scope.
    Expect.isNull(declaration.lookupInScope('field'));
    Expect.equals(Subclass, declaration.lookupInScope('Subclass'));
    // Type variable `B` is not in scope.
    Expect.isNull(declaration.lookupInScope('B'));
    // Field `subfield` is not in scope.
    Expect.isNull(declaration.lookupInScope('subfield'));
  }

  checkTopScope(variable);
  // Parameter `a` is not in scope of `variable`.
  Expect.isNull(variable.lookupInScope('a'));
  // Parameter `b` is not in scope of `variable`.
  Expect.isNull(variable.lookupInScope('b'));

  checkTopScope(method);
  // Parameter `a` is in scope of `method`.
  print(method.lookupInScope('a'));
  Expect.isTrue(method.lookupInScope('a') is ParameterMirror);
  // Parameter `b` is in scope of `method`.
  Expect.isTrue(method.lookupInScope('b') is ParameterMirror);

  // Check class scope.
  DeclarationSourceMirror Class_field = Class.lookupInScope('field');
  Expect.isTrue(Class_field is VariableMirror);
  Expect.notEquals(variable, Class_field);
  Expect.equals(Class, Class_field.owner);

  DeclarationSourceMirror Class_variable = Class.lookupInScope('variable');
  Expect.isTrue(Class_variable is VariableMirror);
  Expect.notEquals(variable, Class_variable);
  Expect.equals(Class, Class_variable.owner);

  DeclarationSourceMirror Class_method = Class.lookupInScope('method');
  Expect.isTrue(Class_method is MethodMirror);
  Expect.notEquals(method, Class_method);
  Expect.equals(Class, Class_method.owner);

  checkClassScope(DeclarationSourceMirror declaration, {bool parametersInScope}) {
    Expect.equals(String_, declaration.lookupInScope('String'));
    Expect.equals(Future_, declaration.lookupInScope('async.Future'));
    Expect.isNull(declaration.lookupInScope('Timer'));
    Expect.isNull(declaration.lookupInScope('async.Timer'));

    Expect.equals(Class_field, declaration.lookupInScope('field'));
    Expect.equals(Class_variable, declaration.lookupInScope('variable'));
    Expect.equals(Class_method, declaration.lookupInScope('method'));

    // Parameter `a` is not in scope.
    Expect.isNull(declaration.lookupInScope('a'));
    // Parameter `b` is not in scope.
    Expect.isNull(declaration.lookupInScope('b'));

    if (parametersInScope) {
      // Parameter `c` is in scope.
      Expect.isTrue(declaration.lookupInScope('c') is ParameterMirror);
      // Parameter `d` is in scope.
      Expect.isTrue(declaration.lookupInScope('d') is ParameterMirror);
    } else {
      // Parameter `c` is not in scope.
      Expect.isNull(declaration.lookupInScope('c'));
      // Parameter `d` is not in scope.
      Expect.isNull(declaration.lookupInScope('d'));
    }

    Expect.equals(Class, declaration.lookupInScope('Class'));
    // Type variable `A` is in scope.
    Expect.isTrue(declaration.lookupInScope('A') is TypeVariableMirror);
    Expect.equals(Subclass, declaration.lookupInScope('Subclass'));
    // Type variable `B` is not in scope.
    Expect.isNull(declaration.lookupInScope('B'));
    // Field `subfield` is not in scope.
    Expect.isNull(declaration.lookupInScope('subfield'));
  }
  checkClassScope(Class, parametersInScope: false);
  checkClassScope(Class_field, parametersInScope: false);
  checkClassScope(Class_variable, parametersInScope: false);
  checkClassScope(Class_method, parametersInScope: true);

  // Check class scope.
  DeclarationSourceMirror Subclass_subfield = Subclass.lookupInScope('subfield');
  Expect.isTrue(Subclass_subfield is VariableMirror);
  Expect.notEquals(variable, Subclass_subfield);
  Expect.equals(Subclass, Subclass_subfield.owner);

  checkSubclassScope(DeclarationSourceMirror declaration) {
    Expect.equals(String_, declaration.lookupInScope('String'));
    Expect.equals(Future_, declaration.lookupInScope('async.Future'));
    Expect.isNull(declaration.lookupInScope('Timer'));
    Expect.isNull(declaration.lookupInScope('async.Timer'));

    // Top level `variable` is in scope.
    Expect.equals(variable, declaration.lookupInScope('variable'));
    // Top level `method` is in scope.
    Expect.equals(method, declaration.lookupInScope('method'));

    // Parameter `a` is not in scope
    Expect.isNull(declaration.lookupInScope('a'));
    // Parameter `b` is not in scope
    Expect.isNull(declaration.lookupInScope('b'));

    // Parameter `c` is not in scope.
    Expect.isNull(declaration.lookupInScope('c'));
    // Parameter `d` is not in scope.
    Expect.isNull(declaration.lookupInScope('d'));

    Expect.equals(Class, declaration.lookupInScope('Class'));
    // Type variable `A` is not in scope
    Expect.isNull(declaration.lookupInScope('A'));
    // Field `field` is in scope
    Expect.equals(Class_field, declaration.lookupInScope('field'));
    Expect.equals(Subclass, declaration.lookupInScope('Subclass'));
    // Type variable `B` is in scope
    Expect.isTrue(declaration.lookupInScope('B') is TypeVariableMirror);
    // Field `subfield` is in scope
    Expect.equals(Subclass_subfield, declaration.lookupInScope('subfield'));
  }
  checkSubclassScope(Subclass);
  checkSubclassScope(Subclass_subfield);

  // `Timer` is in scope of `Future`.
  Expect.isTrue(Future_.lookupInScope('Timer') is ClassMirror);

  // Check qualified lookup.
  Expect.equals(variable, lookupQualifiedInScope(library, 'variable'));
  Expect.equals(method, lookupQualifiedInScope(library, 'method'));
  Expect.isTrue(lookupQualifiedInScope(library, 'method.a') is ParameterMirror);

  Expect.equals(Class, lookupQualifiedInScope(library, 'Class'));
  Expect.isTrue(
      lookupQualifiedInScope(library, 'Class.A') is TypeVariableMirror);

  Expect.isNull(library.lookupInScope('Class.field'));
  Expect.equals(Class_field, lookupQualifiedInScope(library, 'Class.field'));

  Expect.equals(Class_method, lookupQualifiedInScope(library, 'Class.method'));
  Expect.isTrue(
      lookupQualifiedInScope(library, 'Class.method.c') is ParameterMirror);

  // `field` should not be found through the prefix `Subclass`.
  Expect.isNull(lookupQualifiedInScope(library, 'Subclass.field'));
  Expect.equals(Subclass_subfield,
                lookupQualifiedInScope(library, 'Subclass.subfield'));

  Expect.equals(Future_, lookupQualifiedInScope(library, 'async.Future'));
  Expect.isTrue(
      lookupQualifiedInScope(library, 'async.Future.then') is MethodMirror);
  // `Timer` should not be found through the prefix `async.Future`.
  Expect.isNull(
      lookupQualifiedInScope(library, 'async.Future.Timer'));
}
