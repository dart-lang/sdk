<!--
Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->

List of tests on this form:

    ```
    TEST_NAME
    ==> a_test_file.dart <==
    ... source code for a_test_file.dart ...
    ==> another_test_file.dart.patch <==
    ... source code for another_test_file.dart ...
    ```

Filenames ending with ".patch" are special and are expanded into multiple
versions of a file. The parts of the file that vary between versions are
surrounded by `<<<<` and `>>>>` and the alternatives are separated by
`====`. For example:

    ```
    ==> file.txt.patch <==
    first
    <<<< "ex1"
    v1
    ==== "ex2"
    v2
    ==== "ex2"
    v3
    >>>>
    last
    ```

Will produce three versions of a file named `file.txt.patch`:

Version 1:
    ```
    first
    v1
    last
    ```
With expectation `ex1`

Version 2:
    ```
    first
    v2
    last
    ```

With expectation `ex2`

Version 3:
    ```
    first
    v3
    last
    ```

With expectation `ex3`


It is possible to have several independent changes in the same
patch. However, most of the time, it's problematic to have more than one
change in a patch. See topic below on "Making minimal changes". One should
only specify the expectations once. For example:

    ==> main.dart.patch <==
    class Foo {
    <<<< "a"
    ==== "b"
      var bar;
    >>>>
    }
    main() {
      var foo = new Foo();
    <<<<
      print("a");
    ====
      print("b");
    >>>>
    }

Expectations
------------

An expectation is a JSON string. It is decoded and the resulting object,
`o`, is converted to a [ProgramExpectation] in the following way:

* If `o` is a [String]: `new ProgramExpectation([o])`, otherwise

* if `o` is a [List]: `new ProgramExpectation(o)`, otherwise

* a new [ProgramExpectation] instance is instantiated with its fields
  initialized to the corresponding properties of the JSON object. See
  [ProgramExpectation.fromJson].

Make minimal changes
--------------------

When adding new tests, it's important to keep the changes to the necessary
minimum. We do this to ensure that a test actually tests what we intend,
and to avoid accidentally relying on side-effects of other changes making
the test pass or fail unexpectedly.

Let's look at an example of testing what happens when an instance field is
added.

A good test:

    ==> main.dart.patch <==
    class Foo {
    <<<< ["instance is null", "setter threw", "getter threw"]
    ==== "v2"
      var bar;
    >>>>
    }
    var instance;
    main() {
      if (instance == null) {
        print("instance is null");
        instance = new Foo();
      }
      try {
        instance.bar = "v2";
      } catch (e) {
        print("setter threw");
      }
      try {
        print(instance.bar);
      } catch (e) {
        print("getter threw");
      }
    }

A problematic version of the same test:

    ==> main.dart.patch <==
    class Foo {
    <<<< "v1"
    ==== "v2"
      var bar;
    >>>>
    }
    var instance;
    main() {
    <<<<
      instance = new Foo();
      print("v1");
    ====
      instance.bar = 42;
      print(instance.bar);
    >>>>
    }

The former version tests precisely what happens when an instance field is
added to a class, we assume this is the intent of the test.

The latter version tests what happens when:

* An instance field is added to a class.

* A modification is made to a top-level method.

* A modifiction is made to the main method, which is a special case.

* Two more selectors are added to tree-shaking, the enqueuer: 'get:bar',
  and 'set:bar'.

The latter version does not test:

* If an instance field is added, does existing accessors correctly access
  the new field. As `main` was explicitly changed, we don't know if
  already compiled accessors behave correctly.
