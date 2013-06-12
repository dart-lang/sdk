/**
 * This library is used solely for testing during development and is not
 * intended to be run by the testing machines.
 */
// TODO(tmandel): Remove this file once docgen is ready for more clear tests.
library DummyLibrary;

import 'dart:json';
import 'dart:math';

/// Doc comment for top-level variable.
int _variable1 = 0;

void set variable1(int abc) => _variable1 = abc;

abstract class B {

}

/**
 * Doc comment for class A.
 */
/*
 * Normal comment for class A.
 */
class A implements B {

  /**
   * Markdown _test_ for **class** `A` 
   */
  int _someNumber;

  A() {
    _someNumber = 12;
  }

  int get someNumber => _someNumber;

  void doThis(int a) {
    print(a);
  }

  int multi(int a) {
    return a * _someNumber;
  } 

}

main() {
  A a = new A();
  print(a.someNumber);
}

A getA(int testInt, [String testString="default"]) {
  return new A();
}