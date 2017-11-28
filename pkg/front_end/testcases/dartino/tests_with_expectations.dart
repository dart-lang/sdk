// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library dartino_compiler.test.tests_with_expectations;

/// List of tests on this form:
///
///     ```
///     TEST_NAME
///     ==> a_test_file.dart <==
///     ... source code for a_test_file.dart ...
///     ==> another_test_file.dart.patch <==
///     ... source code for another_test_file.dart ...
///     ```
///
/// Filenames ending with ".patch" are special and are expanded into multiple
/// versions of a file. The parts of the file that vary between versions are
/// surrounded by `<<<<` and `>>>>` and the alternatives are separated by
/// `====`. For example:
///
///     ```
///     ==> file.txt.patch <==
///     first
///     <<<< "ex1"
///     v1
///     ==== "ex2"
///     v2
///     ==== "ex2"
///     v3
///     >>>>
///     last
///     ```
///
/// Will produce three versions of a file named `file.txt.patch`:
///
/// Version 1:
///     ```
///     first
///     v1
///     last
///     ```
/// With expectation `ex1`
///
/// Version 2:
///     ```
///     first
///     v2
///     last
///     ```
///
/// With expectation `ex2`
///
/// Version 3:
///     ```
///     first
///     v3
///     last
///     ```
///
/// With expectation `ex3`
///
///
/// It is possible to have several independent changes in the same
/// patch. However, most of the time, it's problematic to have more than one
/// change in a patch. See topic below on "Making minimal changes". One should
/// only specify the expectations once. For example:
///
///     ==> main.dart.patch <==
///     class Foo {
///     <<<< "a"
///     ==== "b"
///       var bar;
///     >>>>
///     }
///     main() {
///       var foo = new Foo();
///     <<<<
///       print("a");
///     ====
///       print("b");
///     >>>>
///     }
///
/// Expectations
/// ------------
///
/// An expectation is a JSON string. It is decoded and the resulting object,
/// `o`, is converted to a [ProgramExpectation] in the following way:
///
/// * If `o` is a [String]: `new ProgramExpectation([o])`, otherwise
///
/// * if `o` is a [List]: `new ProgramExpectation(o)`, otherwise
///
/// * a new [ProgramExpectation] instance is instantiated with its fields
///   initialized to the corresponding properties of the JSON object. See
///   [ProgramExpectation.fromJson].
///
/// Make minimal changes
/// --------------------
///
/// When adding new tests, it's important to keep the changes to the necessary
/// minimum. We do this to ensure that a test actually tests what we intend,
/// and to avoid accidentally relying on side-effects of other changes making
/// the test pass or fail unexpectedly.
///
/// Let's look at an example of testing what happens when an instance field is
/// added.
///
/// A good test:
///
///     ==> main.dart.patch <==
///     class Foo {
///     <<<< ["instance is null", "setter threw", "getter threw"]
///     ==== "v2"
///       var bar;
///     >>>>
///     }
///     var instance;
///     main() {
///       if (instance == null) {
///         print("instance is null");
///         instance = new Foo();
///       }
///       try {
///         instance.bar = "v2";
///       } catch (e) {
///         print("setter threw");
///       }
///       try {
///         print(instance.bar);
///       } catch (e) {
///         print("getter threw");
///       }
///     }
///
/// A problematic version of the same test:
///
///     ==> main.dart.patch <==
///     class Foo {
///     <<<< "v1"
///     ==== "v2"
///       var bar;
///     >>>>
///     }
///     var instance;
///     main() {
///     <<<<
//        instance = new Foo();
///       print("v1");
///     ====
///       instance.bar = 42;
///       print(instance.bar);
///     >>>>
///     }
///
/// The former version tests precisely what happens when an instance field is
/// added to a class, we assume this is the intent of the test.
///
/// The latter version tests what happens when:
///
/// * An instance field is added to a class.
///
/// * A modification is made to a top-level method.
///
/// * A modifiction is made to the main method, which is a special case.
///
/// * Two more selectors are added to tree-shaking, the enqueuer: 'get:bar',
///   and 'set:bar'.
///
/// The latter version does not test:
///
/// * If an instance field is added, does existing accessors correctly access
///   the new field. As `main` was explicitly changed, we don't know if
///   already compiled accessors behave correctly.
const List<String> tests = const <String>[
  r'''
hello_world
==> main.dart.patch <==
// Basic hello-world test
main() { print(
<<<< "Hello, World!"
'Hello, World!'
==== "Hello, Brave New World!"
'Hello, Brave New World!'
>>>>
); }

''',

  r'''
preserving_identity_hashcode
==> main.dart.patch <==
class Foo {
<<<< "Generated firstHashCode"
==== "firstHashCode == secondHashCode: true"
  var bar;
>>>>
}
Foo foo;
int firstHashCode;
main() {
<<<<
  foo = new Foo();
  firstHashCode = foo.hashCode;
  print("Generated firstHashCode");
====
  int secondHashCode = foo.hashCode;
  print("firstHashCode == secondHashCode: ${firstHashCode == secondHashCode}");
>>>>
}
''',

// Test that we can do a program rewrite (which implies a big GC) while there
// are multiple processes alive that depend on the program.
  r'''
program_gc_with_processes
==> main.dart.patch <==
import 'dart:dartino';

class Comms {
<<<< "comms is null"
==== "Hello world"
  int late_arrival;
>>>>
  var paused;
  var pausedPort;
  var resumePort;
  Process process;
}

Comms comms;

void SubProcess(Port pausedPort) {
  // This function, used by the spawned processes, does not exist after the
  // rewrite, but it will be on the stack, so it is kept alive across the GC.
  var c = new Channel();
  pausedPort.send(new Port(c));
  c.receive();
  print("Hello world");
}

main() {
  if (comms == null) {
    print("comms is null");
    // The setup takes place before the rewrite.
    comms = new Comms();

    comms.paused = new Channel();
    var pausedPort = comms.pausedPort = new Port(comms.paused);

    comms.process = Process.spawnDetached(() => SubProcess(pausedPort));
  } else {
    // After the rewrite we get the port from the sub-process and send the
    // data it needs to resume running.
    comms.resumePort = comms.paused.receive();

    var monitor = new Channel();

    comms.process.monitor(new Port(monitor));

    comms.resumePort.send(null);
  }
}
''',

  r'''
instance_field_end
==> main.dart.patch <==
// Test that we can manipulate a field from an instance
// of a class from the end of the field list
class A {
  var x;
<<<< "instance is null"
  var y;
==== "x = 0"
==== "x = 0"
  var y;
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
    instance.x = 0;
  } else {
    print('x = ${instance.x}');
  }
}
''',

  r'''
instance_field_middle
==> main.dart.patch <==
// Test that we can manipulate a field from an instance
// of a class from the middle of the field list
class A {
  var x;
<<<< "instance is null"
  var y;
==== "x = 0"
==== ["x = 3","y = null","z = 2"]
  var y;
>>>>
  var z;
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
    instance.x = 0;
    instance.y = 1;
    instance.z = 2;
  } else {
    print('x = ${instance.x}');
    if (instance.x == 3) {
      print('y = ${instance.y}');
      print('z = ${instance.z}');
    }
    instance.x = 3;
  }
}
''',

  r'''
subclass_schema_1
==> main.dart.patch <==
// Test that schema changes affect subclasses correctly
class A {
  var x;
<<<< "instance is null"
  var y;
==== "x = 0"
==== ["x = 3","y = null","z = 2"]
  var y;
>>>>
}

class B extends A {
  var z;
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new B();
    instance.x = 0;
    instance.y = 1;
    instance.z = 2;
  } else {
    print('x = ${instance.x}');
    if (instance.x == 3) {
      print('y = ${instance.y}');
      print('z = ${instance.z}');
    }
    instance.x = 3;
  }
}
''',

  r'''
subclass_schema_2
==> main.dart.patch <==
// Test that schema changes affect subclasses of subclasses correctly
class A {
  var x;
<<<< "instance is null"
  var y;
==== "x = 0"
==== ["x = 3","y = null","z = 2"]
  var y;
>>>>
}

class B extends A {
}

class C extends B {
  var z;
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
    instance.x = 0;
    instance.y = 1;
    instance.z = 2;
  } else {
    print('x = ${instance.x}');
    if (instance.x == 3) {
      print('y = ${instance.y}');
      print('z = ${instance.z}');
    }
    instance.x = 3;
  }
}
''',

  r'''
subclass_schema_3
==> main.dart.patch <==
// Test that multiple schema changes in subclasses work as intended.
class A {
  var x;
<<<< "instance is null"
  var y;
==== "x = 0"
==== ["x = 3","y = null","z = 2"]
  var y;
>>>>
}

class B extends A {
}

class C extends B {
  var z;
<<<<
====
  var a;
====
  var a;
  var b;
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
    instance.x = 0;
    instance.y = 1;
    instance.z = 2;
  } else {
    print('x = ${instance.x}');
    if (instance.x == 3) {
      print('y = ${instance.y}');
      print('z = ${instance.z}');
    }
    instance.x = 3;
  }
}
''',

  r'''
super_schema
==> main.dart.patch <==
// Test that schema changes work in the presence of fields in the superclass
class A {
  var x;
}

class B extends A {
<<<< "instance is null"
  var y;
==== "x = 0"
==== ["x = 3","y = null","z = 2"]
  var y;
>>>>
  var z;
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new B();
    instance.x = 0;
    instance.y = 1;
    instance.z = 2;
  } else {
    print('x = ${instance.x}');
    if (instance.x == 3) {
      print('y = ${instance.y}');
      print('z = ${instance.z}');
    }
    instance.x = 3;
  }
}
''',

  r'''
add_instance_field
==> main.dart.patch <==
// Test adding a field to a class works

class A {
<<<< ["instance is null","setter threw","getter threw"]
==== "v2"
  var x;
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  }
  try {
    instance.x = 'v2';
  } catch(e) {
    print('setter threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('getter threw');
  }
}
''',

  r'''
remove_instance_field
==> main.dart.patch <==
// Test removing a field from a class works

class A {
<<<< ["instance is null","v1"]
  var x;
==== ["setter threw","getter threw"]
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  }
  try {
    instance.x = 'v1';
  } catch(e) {
    print('setter threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('getter threw');
  }
}
''',

  r'''
two_updates
==> main.dart.patch <==
// Test that the test framework handles more than one update
main() { print(
<<<< "Hello darkness, my old friend"
'Hello darkness, my old friend'
==== "I've come to talk with you again"
'I\'ve come to talk with you again'
==== "Because a vision softly creeping"
'Because a vision softly creeping'
>>>>
); }

''',

  r'''
two_updates_not_main
==> main.dart.patch <==
// Test that the test framework handles more than one update to a top-level
// method that isn't main.
foo() {
<<<< "Hello darkness, my old friend"
  print("Hello darkness, my old friend");
==== "I've come to talk with you again"
  print("I've come to talk with you again");
==== "Because a vision softly creeping"
  print('Because a vision softly creeping');
>>>>
}
main() {
  foo();
}
''',

  r'''
two_updates_instance_method
==> main.dart.patch <==
// Test that the test framework handles more than one update to an instance
// method.
class C {
  foo() {
<<<< ["instance is null", "Hello darkness, my old friend"]
    print("Hello darkness, my old friend");
==== "I've come to talk with you again"
    print("I've come to talk with you again");
==== "Because a vision softly creeping"
    print("Because a vision softly creeping");
>>>>
  }
}

var instance;

main() {
  if (instance == null) {
    print("instance is null");
    instance = new C();
  }
  instance.foo();
}
''',

  r'''
two_updates_with_removal
==> main.dart.patch <==
// Test that the test framework handles more than one update when the last
// update is a removal.

<<<< "Hello, World!"
foo() {
  print("Hello, World!");
}
==== "Hello, Brave New World!"
foo() {
  print("Hello, Brave New World!");
}
==== "threw"
>>>>

main() {
  try {
    foo();
  } catch (e) {
    print("threw");
  }
}
''',

  r'''
main_args
==> main.dart.patch <==
// Test that that isolate support works
main(arguments) { print(
<<<< "Hello, Isolated World!"
'Hello, Isolated World!'
==== "[]"
arguments
>>>>
); }

''',

  r'''
stored_closure
==> main.dart.patch <==
// Test that a stored closure changes behavior when updated

var closure;

foo(a, [b = 'b']) {
<<<< ["[closure] is null.","a b","a c"]
  print('$a $b');
==== ["b a","c a"]
  print('$b $a');
>>>>
}

main() {
  if (closure == null) {
    print('[closure] is null.');
    closure = foo;
  }
  closure('a');
  closure('a', 'c');
}


''',

  r'''
modify_static_method
==> main.dart.patch <==
// Test modifying a static method works

class C {
  static m() {
<<<< "v1"
  print('v1');
==== ["v2"]
  print('v2');
>>>>
  }
}
main() {
  C.m();
}


''',

  r'''
modify_instance_method
==> main.dart.patch <==
// Test modifying an instance method works

class C {
  m() {
<<<< ["instance is null","v1"]
  print('v1');
==== ["v2"]
  print('v2');
>>>>
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}


''',

  r'''
stored_instance_tearoff
==> main.dart.patch <==
// Test that a stored instance tearoff changes behavior when updated

class C {
  m() {
<<<< ["closure is null","v1"]
  print('v1');
==== "v2"
  print('v2');
>>>>
  }
}
var closure;
main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().m;
  }
  closure();
}


''',

  r'''
local_function_closure
==> main.dart.patch <==
// Test that a stored closure of a local function changes behavior when updated

var closure;
class C {
  m() {
    l() {
<<<< ["closure is null","v1"]
      print('v1');
==== "v2"
      print('v2');
>>>>
    }
    closure = l;
  }
}

main() {
  if (closure == null) {
    print('closure is null');
    new C().m();
  }
  closure();
}

''',

  r'''
new_instance_tearoff
==> main.dart.patch <==
// Test that we can tear off an exisiting instance method

class C {
  m(String s) {
    print(s);
  }

  n() {
<<<< ["instance is null","v1"]
    m("v1");
==== "v2"
    var f = m;
    f("v2");
>>>>
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.n();
}


''',

  r'''
stored_instance_tearoff_with_named_parameters
==> main.dart.patch <==
// Test that a stored instance tearoff with named parameter changes behavior
// when updated

class C {
  m({a: 'a'}) {
<<<< ["closure is null","v1"]
  print('v1');
==== "v2"
  print('v2');
>>>>
  }
}
var closure;
main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().m;
  }
  closure(a: 'b');
}


''',

  r'''
stored_instance_tearoff_with_optional_positional_parameters
==> main.dart.patch <==
// Test that a stored instance tearoff with optional positional parameter
// changes behavior when updated

class C {
  m([a ='a']) {
<<<< ["closure is null","v1", "v1"]
  print('v1');
==== ["v2", "v2"]
  print('v2');
>>>>
  }
}
var closure;
main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().m;
  }
  closure('b');
  closure();
}


''',

  r'''
invalidate_method_used_in_tearoff
==> main.dart.patch <==
// Test that we can introduce a change that causes a method used as tear-off
// to be recompiled.

class A {
  m() => print("v1");
}

class B extends A {
<<<< ["closure is null","v1"]
==== []
  m() => null;
>>>>
}

var closure;
main() {
  if (closure == null) {
    print('closure is null');
    closure = new B().m;
    closure();
  }
}


''',

  r'''
invalidate_method_with_optional_parameters
==> main.dart.patch <==
// Test that we can introduce a change that causes a method with optional
// parameters to be recompiled.

class A {
  m([a="a"]) => print("v1");
}

class B extends A {
<<<< "v1"
  m([a="a"]) => null;
==== "v1"
>>>>
}

main() {
  new B();
  new A().m();
}


''',

  r'''
remove_instance_method
==> main.dart.patch <==
// Test that deleting an instance method works

class C {
<<<< ["instance is null","v1"]
  m() {
    print('v1');
  }
==== {"messages":["threw"]}
>>>>
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  try {
    instance.m();
  } catch (e) {
    print('threw');
  }
}


''',

  r'''
remove_instance_method_with_optional_parameters
==> main.dart.patch <==
// Test that deleting an instance method with optional parameters works

class C {
<<<< ["instance is null","v1","v1"]
  m([a = "a"]) {
    print('v1');
  }
==== ["threw","threw"]
>>>>
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  try {
    instance.m();
  } catch (e) {
    print('threw');
  }
    try {
    instance.m("b");
  } catch (e) {
    print('threw');
  }
}


''',

  r'''
remove_instance_method_stored_in_tearoff
==> main.dart.patch <==
// Test that deleting an instance method works, even if stored in a tear-off

class C {
<<<< ["instance is null","v1"]
  m() {
    print('v1');
  }
==== {"messages":["threw", "threw"]}
>>>>
}
var closure;
main() {
  if (closure == null) {
    print('instance is null');
    closure = new C().m;
  }
  try {
    closure();
  } catch (e) {
    print('threw');
  }

  try {
    new C().m;
  } catch (e) {
    print("threw");
  }
}


''',

  r'''
remove_instance_method_with_optional_parameters_stored_in_tearoff
==> main.dart.patch <==
// Test that deleting an instance method with optional parameters works, even if
// stored in a tear-off

class C {
<<<< ["closure is null","v1","v1"]
  m([a = "a"]) {
    print('v1');
  }
==== ["threw", "threw"]
>>>>
}
var closure;
main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().m;
  }
  try {
    closure();
  } catch (e) {
    print('threw');
  }
    try {
    closure("b");
  } catch (e) {
    print('threw');
  }
}


''',

  r'''
remove_instance_method_super_access
==> main.dart.patch <==
// Test that deleting an instance method works, even when accessed through
// super

class A {
  m() {
    print('v2');
  }
}
class B extends A {
<<<< ["instance is null","v1"]
  m() {
    print('v1');
  }
==== "v2"
>>>>
}
class C extends B {
  m() {
    super.m();
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}


''',

  r'''
override_method_with_field_conflict
==> main.dart.patch <==
// Test that adding an override conflict results in a compile-time error.

class A {
  m() {}
}

class B extends A {
<<<< {"messages":["42"]}
==== {"messages":["42"],"hasCompileTimeError":1}
  var m;
>>>>
}

var c;
main() {
  // This print statement is added to ensure minimal incremental change in the
  // second version of the program: The compile-time error introduced causes
  // [compileError] to be added which in turn adds static fields because of its
  // print statement.
  print("42");
  if (c == null) {
    c = 0;
  } else {
    new B().m;
  }
}


''',

  r'''
override_field_with_method_conflict
==> main.dart.patch <==
// Test that adding an override conflict results in a compile-time error.

class A {
  var m;
}

class B extends A {
<<<< {"messages":["42"]}
==== {"messages":["42"],"hasCompileTimeError":1}
  m() {}
>>>>
}

var c;
main() {
  // This print statement is added to ensure minimal incremental change in the
  // second version of the program: The compile-time error introduced causes
  // [compileError] to be added which in turn adds static fields because of its
  // print statement.
  print("42");
  if (c == null) {
    c = 0;
  } else {
    new B().m();
  }
}


''',

  r'''
override_method_with_getter_conflict
==> main.dart.patch <==
// Test that adding an override conflict results in a compile-time error.

class A {
  m() {}
}

class B extends A {
<<<< {"messages":["42"]}
==== {"messages":["42"],"hasCompileTimeError":1}
  get m => null;
>>>>
}

var c;
main() {
  // This print statement is added to ensure minimal incremental change in the
  // second version of the program: The compile-time error introduced causes
  // [compileError] to be added which in turn adds static fields because of its
  // print statement.
  print("42");
  if (c == null) {
    c = 0;
  } else {
    new B().m;
  }
}


''',

  r'''
override_getter_with_method_conflict
==> main.dart.patch <==
// Test that adding an override conflict results in a compile-time error.

class A {
  get m => null;
}

class B extends A {
<<<< {"messages":["42"]}
==== {"messages":["42"],"hasCompileTimeError":1}
  m() {}
>>>>
}

var c;
main() {
  // This print statement is added to ensure minimal incremental change in the
  // second version of the program: The compile-time error introduced causes
  // [compileError] to be added which in turn adds static fields because of its
  // print statement.
  print("42");
  if (c == null) {
    c = 0;
  } else {
    new B().m();
  }
}


''',

  r'''
remove_top_level_method
==> main.dart.patch <==
// Test that deleting a top-level method works

<<<< ["instance is null","v1"]
toplevel() {
  print('v1');
}
==== {"messages":["threw"]}
>>>>
class C {
  m() {
    try {
      toplevel();
    } catch (e) {
      print('threw');
    }
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}


''',

  r'''
remove_static_method
==> main.dart.patch <==
// Test that deleting a static method works

class B {
<<<< ["instance is null","v1"]
  static staticMethod() {
    print('v1');
  }
==== "threw"
>>>>
}
class C {
  m() {
    try {
      B.staticMethod();
    } catch (e) {
      print('threw');
    }
    try {
      // Ensure that noSuchMethod support is compiled. This test is not about
      // adding new classes.
      B.missingMethod();
      print('bad');
    } catch (e) {
    }
  }
}
var instance;
main() {
  new B(); // TODO(ahe): Work around dart2js assertion in World.subclassesOf
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}


''',

  r'''
newly_instantiated_class
==> main.dart.patch <==
// Test that a newly instantiated class is handled

class A {
  m() {
    print('Called A.m');
  }
}

class B {
  m() {
    print('Called B.m');
  }
}

var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
<<<< ["instance is null","Called A.m"]
==== ["Called B.m"]
  } else {
    instance = new B();
>>>>
  }
  instance.m();
}


''',

  r'''
source_maps_no_throw
==> main.dart.patch <==
// Test that source maps don't throw exceptions

main() {
  print('a');
<<<< "a"
==== ["a","b","c"]
  print('b');
  print('c');
>>>>
}


''',

  r'''
newly_instantiated_class_X
==> main.dart.patch <==
// Test that a newly instantiated class is handled

// TODO(ahe): How is this different from the other test with same comment?

class A {
  get name => 'A.m';

  m() {
    print('Called $name');
  }
}

class B extends A {
  get name => 'B.m';
}

var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
<<<< ["instance is null","Called A.m"]
==== ["Called B.m"]
  } else {
    instance = new B();
>>>>
  }
  instance.m();
}


''',

  r'''
newly_instantiated_class_with_fields
==> main.dart.patch <==
// Test that fields of a newly instantiated class are handled

class A {
  var x;
  A(this.x);
}
var instance;
foo() {
  if (instance != null) {
    print(instance.x);
  } else {
    print('v1');
  }
}
main() {
<<<< "v1"
==== "v2"
  instance = new A('v2');
>>>>
  foo();
}


''',

  r'''
add_top_level_method
==> main.dart.patch <==
// Test that top-level functions can be added

<<<< "threw"
==== "v2"
foo() {
  print('v2');
}
>>>>
main() {
  try {
    foo();
  } catch(e) {
    print('threw');
  }
}


''',

  r'''
add_static_method
==> main.dart.patch <==
// Test that static methods can be added

class C {
<<<< "threw"
==== "v2"
  static foo() {
    print('v2');
  }
>>>>
}

main() {
  new C(); // TODO(ahe): Work around dart2js assertion in World.subclassesOf
  try {
    C.foo();
  } catch(e) {
    print('threw');
  }
}


''',

  r'''
add_instance_method
==> main.dart.patch <==
// Test that instance methods can be added

class C {
<<<< ["instance is null","threw"]
==== ["v2"]
  foo() {
    print('v2');
  }
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }

  try {
    instance.foo();
  } catch(e) {
    print('threw');
  }
}


''',

  r'''
signature_change_top_level_method
==> main.dart.patch <==
// Test that top-level functions can have signature changed

<<<< "v1"
foo() {
  print('v1');
==== {"messages":["v2"]}
void foo() {
  print('v2');
>>>>
}

main() {
  foo();
}


''',

  r'''
signature_change_static_method
==> main.dart.patch <==
// Test that static methods can have signature changed

class C {
<<<< "v1"
  static foo() {
    print('v1');
==== "v2"
  static void foo() {
    print('v2');
>>>>
  }
}

main() {
  new C(); // TODO(ahe): Work around dart2js assertion in World.subclassesOf
  C.foo();
}


''',

  r'''
signature_change_instance_method
==> main.dart.patch <==
// Test that instance methods can have signature changed

class C {
<<<< ["instance is null","v1"]
  foo() {
    print('v1');
==== {"messages":["v2"]}
  void foo() {
    print('v2');
>>>>
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }

  instance.foo();
}


''',

  r'''
signature_change_parameter_instance_method
==> main.dart.patch <==
// Test that instance methods can have signature changed

class C {
<<<< ["instance is null","v1"]
  foo() {
    print('v1');
  }
==== "v2"
  foo(int i) {
    print('v2');
  }
>>>>>
}
var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
    instance.foo();
  } else {
    instance.foo(1);
  }
}


''',

  r'''
super_call_simple_change
==> main.dart.patch <==
// Test that super calls are dispatched correctly
class C {

  foo() {
<<<< ["instance is null","v1"]
    print('v1');
==== "v2"
    print('v2');
>>>>>
  }
}

class B extends C {
  bar() {
    super.foo();
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new B();
  }

  instance.bar();
}


''',

  r'''
super_call_signature_change
==> main.dart.patch <==
// Test that super calls are dispatched correctly
class C {
<<<< ["instance is null", "v1", "super.foo()", "super.foo(42) threw"]
  foo() {
    print('v1');
  }
==== ["super.foo() threw", "v2", "super.foo(42)"]
  foo(int i) {
    print('v2');
  }
>>>>>
}

class B extends C {
  superFooNoArgs() => super.foo();
  superFooOneArg(x) => super.foo(x);
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new B();
  }
  try {
    instance.superFooNoArgs();
    print("super.foo()");
  } catch (e) {
    print("super.foo() threw");
  }
  try {
    instance.superFooOneArg(42);
    print("super.foo(42)");
  } catch (e) {
    print("super.foo(42) threw");
  }
}


''',

  r'''
add_class
==> main.dart.patch <==
// Test that adding a class is supported

<<<< "v1"
==== "v2"
class C {
  void foo() {
    print('v2');
  }
}
>>>>
main() {
<<<<
  print('v1');

====
  new C().foo();
>>>>
}


''',

  r'''
remove_class
==> main.dart.patch <==
// Test that removing a class is supported, using constructor

<<<< "v1"
class C {
}
==== {"messages":["v2"]}
>>>>
main() {
  try {
    new C();
    print('v1');
  } catch (e) {
    print('v2');
  }
}


''',

  r'''
remove_class_with_static_method
==> main.dart.patch <==
// Test that removing a class is supported, using a static method

<<<< "v1"
class C {
  static m() {
    print('v1');
  }
}
==== "v2"
>>>>
main() {
  try {
    C.m();
  } catch (e) {
    print('v2');
  }
}


''',

  r'''
change_supertype
==> main.dart.patch <==
// Test that changing the supertype of a class works

class A {
  m() {
    print('v2');
  }
}
class B extends A {
  m() {
    print('v1');
  }
}
<<<< ["instance is null","v1"]
class C extends B {
==== ["v2"]
class C extends A {
>>>>
  m() {
    super.m();
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}


''',

  r'''
call_named_arguments_1
==> main.dart.patch <==
// Test that named arguments can be called

class C {
  foo({a, named: 'v1', x}) {
    print(named);
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
<<<< ["instance is null","v1"]
  instance.foo();
==== ["v2"]
  instance.foo(named: 'v2');
>>>>
}


''',

  r'''
call_named_arguments_2
==> main.dart.patch <==
// Test that named arguments can be called

class C {
  foo({a, named: 'v2', x}) {
    print(named);
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
<<<< ["instance is null","v1"]
  instance.foo(named: 'v1');
==== ["v2"]
  instance.foo();
>>>>
}


''',

  r'''
call_named_arguments_from_instance_method
==> main.dart.patch <==
// Similiar to call_named_arguments_2 but where the change in the way the method
// with named parameters is called happens in an instance method belonging to
// the same class.

class C {
  foo({a: 'v2'}) {
    print(a);
  }

  bar() {
<<<< ["instance is null", "v1"]
    foo(a: 'v1');
==== "v2"
    foo();
>>>>
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.bar();
}


''',

  r'''
call_instance_tear_off_named
==> main.dart.patch <==
// Test that an instance tear-off with named parameters can be called

class C {
  foo({a, named: 'v1', x}) {
    print(named);
  }
}

var closure;

main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().foo;
  }
<<<< ["closure is null","v1"]
  closure();
==== "v2"
  closure(named: 'v2');
>>>>
}


''',

  r'''
lazy_static
==> main.dart.patch <==
// Test that a lazy static is supported

var normal;

<<<< "v1"
foo() {
  print(normal);
}
==== ["v2","lazy"]
var lazy = bar();

foo() {
  print(lazy);
}

bar() {
  print('v2');
  return 'lazy';
}

>>>>
main() {
  if (normal == null) {
    normal = 'v1';
  } else {
    normal = '';
  }
  foo();
}


''',

  r'''
super_classes_of_directly_instantiated
==> main.dart.patch <==
// Test that superclasses of directly instantiated classes are also emitted
class A {
}

class B extends A {
}

main() {
<<<< "v1"
  print('v1');
==== "v2"
  new B();
  print('v2');
>>>>
}


''',

  r'''
interceptor_classes
==> main.dart.patch <==
// Test that interceptor classes are handled correctly

main() {
<<<< "v1"
  print('v1');
==== "v2"
  ['v2'].forEach(print);
>>>>
}


''',

  r'''
newly_instantiated_superclasses_two_updates
==> main.dart.patch <==
// Test that newly instantiated superclasses are handled correctly when there
// is more than one change

class A {
  foo() {
    print('Called foo');
  }

  bar() {
    print('Called bar');
  }
}

class B extends A {
}

main() {
<<<< "Called foo"
  new B().foo();
==== "Called foo"
  new B().foo();
==== "Called bar"
  new A().bar();
>>>>
}


''',

  r'''
newly_instantiated_subclases_two_updates
==> main.dart.patch <==
// Test that newly instantiated subclasses are handled correctly when there is
// more than one change

class A {
  foo() {
    print('Called foo');
  }

  bar() {
    print('Called bar');
  }
}

class B extends A {
}

main() {
<<<< "Called foo"
  new A().foo();
==== "Called foo"
  new A().foo();
==== "Called bar"
  new B().bar();
>>>>
}


''',

  r'''
constants
==> main.dart.patch <==
// Test that constants are handled correctly

class C {
  final String value;
  const C(this.value);
}

main() {
<<<< "v1"
  print(const C('v1').value);
==== "v2"
  print(const C('v2').value);
>>>>
}


''',

  r'''
constant_retaining
==> main.dart.patch <==
// Test that constants are retained
class Foo {
  const Foo();
}

class Bar {
  final f = const Foo();
  const Bar();
}

class Baz {
  final f = const Foo();
  const Baz();
}

class C {
  foo() {
<<<< ["true"]
    return const Foo();
==== ["true"]
    return const Bar().f;
==== ["true"]
    return const Baz().f;
>>>>
  }
}

void main() {
  var c = new C();
  print(identical(c.foo(), const Foo()));
}


''',

  r'''
constant_retaining_2
==> main.dart.patch <==
// Test that constants are handled correctly when stored in a top-level
// variable.
var constant;

class Foo {
  const Foo();
}

class C {
  foo() {
<<<< ["v1", "true"]
    print("v1");
    constant = const Foo();
==== ["v2", "true"]
    print("v2");
==== ["v3", "true"]
    print("v3");
>>>>
    print(constant == const Foo());
  }
}

main() {
  new C().foo();
}


''',

  r'''
constant_retaining_3
==> main.dart.patch <==
// Similiar to constant_retaining_2, but tests that constant handling is still
// correct even if an unrelated constant is introduced and removed again.
var constant;

class Foo {
  const Foo();
}

class Bar {
  const Bar();
}

class C {
  foo() {
<<<< ["v1", "true"]
    print("v1");
    constant = const Foo();
==== ["v2", "false", "true"]
    print("v2");
    print(constant == const Bar());
==== ["v3", "true"]
    print("v3");
>>>>
    print(constant == const Foo());
  }
}

main() {
  new C().foo();
}


''',

  r'''
add_compound_instance_field
==> main.dart.patch <==
// Test that an instance field can be added to a compound declaration

class C {
<<<< ["[instance] is null","v1","[instance.y] threw"]
  int x;
==== ["v1","v2"]
  int x, y;
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
  } else {
    instance.y = 'v2';
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
  try {
    print(instance.y);
  } catch (e) {
    print('[instance.y] threw');
  }
}


''',

  r'''
remove_compound_instance_field
==> main.dart.patch <==
// Test that an instance field can be removed from a compound declaration

class C {
<<<< ["[instance] is null","v1","v2"]
  int x, y;
==== ["v1","[instance.y] threw"]
  int x;
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
    instance.y = 'v2';
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
  try {
    print(instance.y);
  } catch (e) {
    print('[instance.y] threw');
  }
}


''',

  r'''
static_field_to_instance_field
==> main.dart.patch <==
// Test that a static field can be made an instance field

class C {
<<<< ["[instance] is null","v1","[instance.x] threw"]
  static int x;
==== ["[C.x] threw","v2"]
  int x;
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    C.x = 'v1';
  } else {
    instance.x = 'v2';
  }
  try {
    print(C.x);
  } catch (e) {
    print('[C.x] threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
}


''',

  r'''
instance_field_to_static_field
==> main.dart.patch <==
// Test that instance field can be made static

class C {
<<<< ["[instance] is null","[C.x] threw","v1"]
  int x;
==== ["v2","[instance.x] threw"]
  static int x;
>>>>
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
  } else {
    C.x = 'v2';
  }
  try {
    print(C.x);
  } catch (e) {
    print('[C.x] threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
}


''',

  r'''
compound_constants
==> main.dart.patch <==
// Test compound constants

class A {
  final value;
  const A(this.value);

  toString() => 'A($value)';
}

class B {
  final value;
  const B(this.value);

  toString() => 'B($value)';
}

main() {
<<<< ["A(v1)","B(v1)"]
  print(const A('v1'));
  print(const B('v1'));
==== ["B(A(v2))","A(B(v2))"]
  print(const B(const A('v2')));
  print(const A(const B('v2')));
>>>>
}


''',

  r'''
constants_of_new_classes
==> main.dart.patch <==
// Test constants of new classes

class A {
  final value;
  const A(this.value);

  toString() => 'A($value)';
}
<<<< "A(v1)"
==== ["A(v2)","B(v2)","B(A(v2))","A(B(v2))"]
class B {
  final value;
  const B(this.value);

  toString() => 'B($value)';
}

>>>>
main() {
<<<<
  print(const A('v1'));

====
  print(const A('v2'));
  print(const B('v2'));
  print(const B(const A('v2')));
  print(const A(const B('v2')));
>>>>
}


''',

  r'''
change_in_part
==> main.dart <==
// Test that a change in a part is handled
library test.main;

part 'part.dart';


==> part.dart.patch <==
part of test.main;

main() {
<<<< "Hello, World!"
  print('Hello, World!');
==== "Hello, Brave New World!"
  print('Hello, Brave New World!');
>>>>
}
''',

  r'''
change_library_name
==> main.dart.patch <==
// Test that a change in library name is handled
<<<< "Hello, World!"
library test.main1;
==== "Hello, World!"
library test.main2;
>>>>

main() {
  print('Hello, World!');
}
''',

  r'''
add_import
==> main.dart.patch <==
// Test that adding an import is handled
<<<< "Hello, World!"
==== "Hello, World!"
import 'dart:core';
>>>>

main() {
  print('Hello, World!');
}
''',

  r'''
add_export
==> main.dart.patch <==
// Test that adding an export is handled
<<<< "Hello, World!"
==== "Hello, World!"
export 'dart:core';
>>>>

main() {
  print('Hello, World!');
}
''',

  r'''
add_part
==> main.dart.patch <==
// Test that adding a part is handled
library test.main;

<<<< "Hello, World!"
==== "Hello, World!"
part 'part.dart';
>>>>

main() {
  print('Hello, World!');
}


==> part.dart <==
part of test.main
''',

  r'''
multiple_libraries
==> main.dart <==
// Test that changes in multiple libraries is handled
import 'library1.dart' as lib1;
import 'library2.dart' as lib2;

main() {
  lib1.method();
  lib2.method();
}


==> library1.dart.patch <==
library test.library1;

method() {
<<<< ["lib1.v1","lib2.v1"]
  print('lib1.v1');
==== ["lib1.v2","lib2.v2"]
  print('lib1.v2');
==== ["lib1.v3","lib2.v3"]
  print('lib1.v3');
>>>>
}


==> library2.dart.patch <==
library test.library2;

method() {
<<<<
  print('lib2.v1');
====
  print('lib2.v2');
====
  print('lib2.v3');
>>>>
}
''',

  r'''
bad_stack_trace_repro
==> main.dart.patch <==
// Reproduces a problem where the stack trace includes an old method that
// should have been removed by the incremental compiler
main() {
  bar();
}

bar() {
<<<< []
  foo(true);
==== []
  foo(false);
>>>>
}

foo(a) {
  if (a) throw "throw";
}
''',

  r'''
compile_time_error_001
==> main.dart.patch <==
// Reproduce a crash when a compile-time error is added
main() {
<<<< []
==== {"messages":[],"hasCompileTimeError":1}
  do for while if;
>>>>
}
''',

  r'''
compile_time_error_002
==> main.dart.patch <==
// Reproduce a crash when a *recoverable* compile-time error is added
main() {
<<<< "fisk"
  print("fisk");
==== {"messages":[],"hasCompileTimeError":1}
  new new();
>>>>
}
''',

  r'''
compile_time_error_003
==> main.dart.patch <==
// Reproduce a crash when a compile-time error is reported on a new class
<<<< []
==== {"messages":[],"hasCompileTimeError":1}
abstract class A implements bool default F {
  A();
}
>>>>

class F {
<<<<
====
  factory A() { return null; }
>>>>
}

main() {
<<<<
====
  new A();
>>>>
}
''',

  r'''
compile_time_error_004
==> main.dart.patch <==
// Reproduce a crash when a class has a bad hierarchy
<<<< []
typedef A(C c);
==== {"messages":[],"hasCompileTimeError":1}
typedef A(Class c);
>>>>

typedef B(A a);

typedef C(B b);

class Class {
<<<<
====
  A a;
>>>>
}

void testA(A a) {}

void main() {
  testA(null);
}
''',

  r'''
compile_time_error_005
==> main.dart.patch <==
// Regression for crash when attempting to reuse method with compile-time
// error.
main() {
<<<< {"messages":[],"hasCompileTimeError":1}
  var funcnuf = (x) => ((x))=((x)) <= (x);
==== "Hello"
  print("Hello");
>>>>
}
''',

  r'''
compile_time_error_006
==> main.dart.patch <==
<<<< "error"
==== {"messages":[],"hasCompileTimeError":1}
test({b}) {
  if (?b) return b;
}
>>>>
main() {
  try {
    test(b: 2);
  } catch (e) {
    print("error");
  }
}

''',

  r'''
generic_types_001
==> main.dart.patch <==
// Test removing a generic class.
<<<< []
class A<T> {
}
==== []
>>>>

main() {
<<<<
  new A();
====
>>>>
}
''',

  r'''
generic_types_002
==> main.dart.patch <==
// Test adding a generic class.
<<<< []
==== []
class A<T> {
}
>>>>

main() {
<<<<
====
  new A();
>>>>
}
''',

  r'''
generic_types_003
==> main.dart.patch <==
// Test adding type variables to a class.
<<<< []
class A {
}
==== []
class A<T> {
}
>>>>

main() {
  new A();
}
''',

  r'''
generic_types_004
==> main.dart.patch <==
// Test removing type variables from a class.
<<<< []
class A<T> {
}
==== []
class A {
}
>>>>

main() {
  new A();
}
''',

  r'''
add_named_mixin_application
==> main.dart.patch <==
// Test that we can add a mixin application.
class A {}
<<<< []
==== []
class C = Object with A;
>>>>
main() {
  new A();
<<<<
====
  new C();
>>>>
}
''',

  r'''
remove_named_mixin_application
==> main.dart.patch <==
// Test that we can remove a mixin application.
class A {}
<<<< []
class C = Object with A;
==== []
>>>>
main() {
  new A();
<<<<
  new C();
====
>>>>
}
''',

  r'''
unchanged_named_mixin_application
==> main.dart.patch <==
// Test that we can handle a mixin application that doesn't change.
class A {}
class C = Object with A;

main() {
  new C();
<<<< []
==== []
  new C();
>>>>
}
''',

  r'''
bad_diagnostics
==> main.dart.patch <==
// Test that our diagnostics handler doesn't crash
main() {
<<<< []
==== []
  // This is a long comment to guarantee that we have a position beyond the end
  // of the first version of this file.
  NoSuchClass c = null; // Provoke a warning to exercise the diagnostic handler.
>>>>
}
''',

  r'''
super_is_parameter
==> main.dart.patch <==
<<<< []
class A<S> {
==== []
class A<S extends S> {
>>>>
  S field;
}

class B<T> implements A<T> {
  T field;
}

main() {
  new B<int>();
}
''',

  r'''
closure_capture
==> main.dart.patch <==
main() {
  var a = "hello";
<<<< "hello"
  print(a);
==== "hello from closure"
  (() => print('$a from closure'))();
>>>>
}
''',

  r'''
add_top_level_const_field
==> main.dart.patch <==
// Test that we can add a top-level field.
<<<< "0"
==== "1"
  const c = 1;
>>>>

main() {
<<<<
  print(0);
====
  print(c);
>>>>
}
''',

  r'''
remove_class_with_field_and_subclass
==> main.dart.patch <==
<<<< []
class A {
  var x;
}

class B extends A {
}
==== []
>>>>

main() {
<<<<
  new B();
====
>>>>
}
''',

  r'''
fix_compile_time_error_in_field
==> main.dart.patch <==
// Regression test for a bad assertion in dart2js (can't compute subclasses of
// C because C isn't recorded as instantiated, which it really is, it's just
// that a compile-time error was encountered when attempting to resolve C).
class C {
<<<< {"messages":[],"hasCompileTimeError":1}
  int sync*;
==== {"messages":[],"hasCompileTimeError":1}
  // TODO(ahe): There's no compile-time error here
  int sync;
>>>>
}
main() {
  new C();
}
''',

  r'''
compile_time_error_partial_file
==> main.dart.patch <==
// Regression test for problem noticed when a mistake was made in
// fix_compile_time_error_in_field.
class C {
<<<< {"messages":[],"hasCompileTimeError":1}
  int sync*;
==== []
  int sync;
}
main() {
  new C();
}
>>>>
''',

  r'''
compile_time_error_field_becomes_removed_function
==> main.dart.patch <==
// Regression test for a syntax error in a field becomes a function that is
// subsequently removed.
class C {
<<<< {"messages":[],"hasCompileTimeError":1}
  int sync*;
==== {"messages":[],"hasCompileTimeError":1}
  // TODO(ahe): Should just expect [], no compile-time error
  sync();
==== {"messages":[],"hasCompileTimeError":1}
  // TODO(ahe): Should just expect [], no compile-time error
>>>>
}
main() {
  new C();
}
''',

  r'''
add_field_and_remove_subclass
==> main.dart.patch <==
// Regression test for what happens when a field is added at the same time a
// class is removed.
class A {
<<<< []
==== []
  var field;
>>>>
}

<<<<
class B extends A {
}
====
>>>>

main() {
<<<<
  new B();
====
  new A();
>>>>
}
''',

  r'''
compile_time_error_hides_field
==> main.dart.patch <==
// Regression test for what happens when the parser doesn't recover.
class A {
<<<< {"messages":[],"hasCompileTimeError":1}
  // TODO(ahe): should just expect "null"
  bool operator ===(A other) { return true; }
==== {"messages":[],"hasCompileTimeError":1}
  // TODO(ahe): Should expect just: ["getter ok", "null", "setter ok"], not a
  // compile-time error.
>>>>

  int field;
}

main() {
  var a = new A();
  var value;
  try {
    value = a.field;
    print("getter ok");
  } catch (e) {
    print("getter threw");
  }
  print(value);
  try {
    a.field = "fisk"
    print("setter ok");
  } catch (e) {
    print("setter threw");
  }
}
''',

  r'''
update_dependencies
==> main.dart.patch <==
foo() {
<<<< "v1"
  print("v1");
==== "v2"
  print("v2");
>>>>
}

bar() => foo();

main() {
  bar();
}
''',

  r'''
update_dependencies_recoverable_compile_time_error
==> main.dart.patch <==
foo() {
<<<< {"messages":[],"hasCompileTimeError":1}
  new new();
==== "v2"
  print("v2");
>>>>
}

bar() => foo();

main() {
  bar();
}
''',

  r'''
update_dependencies_unrecoverable_compile_time_error
==> main.dart.patch <==
foo() {
<<<< {"messages":[],"hasCompileTimeError":1}
  for do while default if else new;
==== "v2"
  print("v2");
>>>>
}

bar() => foo();

main() {
  bar();
}
''',

  r'''
add_top_level_field
==> main.dart.patch <==
<<<< "v1"
==== ["null","value"]
var field;
>>>>
main() {
<<<<
  print("v1");
====
  print(field);
  field = "value";
  print(field);
>>>>
}
''',

  r'''
add_static_field
==> main.dart.patch <==
class C {
<<<< "v1"
==== ["null","value"]
  static var field;
>>>>
}

main() {
<<<<
  print("v1");
====
  print(C.field);
  field = "value";
  print(C.field);
>>>>
}
''',

  r'''
main_signature_change
==> main.dart.patch <==
<<<< "v1"
void main() {
  print("v1");
}
==== "v2"
main() {
  print("v2");
}
>>>>
''',

  r'''
same_tokens
==> main.dart.patch <==
// Test what happens when a ScopeContainerElement is changed back to its
// original declaration.
class C {
  static m() {
<<<< "v1"
    print("v1");
==== "v2"
    print("v2");
==== "v1"
    print("v1");
>>>>
  }
}

main() {
  new C();
  C.m();
}
''',

  r'''
same_tokens_variant
==> main.dart.patch <==
// Variant of same_tokens which causes bad code generated by incremental
// compiler.
class C {
  static m() {
<<<< "v1"
    print("v1");
==== "v2"
    print("v2");
==== "v1"
    print("v1");
>>>>
  }
}

main() {
  new C();
<<<<
var x;
====
var y;
====
var z;
>>>>
  C.m();
}
''',

  r'''
change_optional_arguments
==> main.dart.patch <==
// Test that a method with optional arguments can change.
<<<< ["1:3","1:2"]
foo(x, [y = 3]) {
  print("$x:$y");
}

void main() {
  foo(1);
  foo(1, 2);
}
==== ["3","2"]
foo([x = 3]) {
  print(x);
}

void main() {
  var f = foo;
  f();
  f(2);
}
>>>>
''',

  r'''
closure
==> main.dart.patch <==
// Tests what happens when an added method is closurized.

class A {
<<<< "v1"
  foo() {
    print("v1");
  }
==== "v2"
  a() {
    print("v2");
  }
>>>>
}

void main() {
<<<<
  var a = new A();
  a.foo();
====
  var a = new A();
  var f = a.a;
  f();
>>>>
}
''',

  r'''
no_closure
==> main.dart.patch <==
// Similar to closure, but doesn't use closures.
class A {
<<<< "v1"
  foo() {
    print("v1");
  }
==== "v2"
  a() {
    print("v2");
  }
>>>>
}

void main() {
<<<<
  var a = new A();
  a.foo();
====
  var a = new A();
  a.a();
>>>>
}
''',

r'''
add_unused_enum_class
==> main.dart.patch <==
<<<< []
==== []
enum E { e0 }
>>>>

main() {
}
''',

r'''
remove_unused_enum_class
==> main.dart.patch <==
<<<< []
enum E { e0 }
==== []
>>>>

main() {
}
''',
];
