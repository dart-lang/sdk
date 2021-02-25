// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Environment does not contain "bar".
const bool barFromEnv = const bool.fromEnvironment("bar");
const bool hasBarEnv = const bool.hasEnvironment("bar");
const bool barFromEnvOrNull =
    const bool.fromEnvironment("bar", defaultValue: null);
const bool notBarFromEnvOrNull = !barFromEnvOrNull;
const bool conditionalOnNull = barFromEnvOrNull ? true : false;
const bool nullAwareOnNullTrue = barFromEnvOrNull ?? true;
const bool nullAwareOnNullFalse = barFromEnvOrNull ?? false;
const bool andOnFalse = nullAwareOnNullFalse && nullAwareOnNullTrue;
const bool andOnFalse2 = nullAwareOnNullTrue && nullAwareOnNullFalse;
const bool andOnNull = barFromEnvOrNull && true;
const bool andOnNull2 = true && barFromEnvOrNull;
const bool orOnNull = barFromEnvOrNull || true;
const bool orOnNull2 = barFromEnvOrNull || false;
const bool orOnNull3 = true || barFromEnvOrNull;
const bool orOnNull4 = false || barFromEnvOrNull;

const String barFromEnvString = const String.fromEnvironment("bar");
const String barFromEnvOrNullString =
    const String.fromEnvironment("bar", defaultValue: null);
const String barFromEnvOrActualString =
    const String.fromEnvironment("bar", defaultValue: "hello");
const String nullFromEnvString =
    const String.fromEnvironment(barFromEnvOrNullString);

const bool barFromEnvBool = const bool.fromEnvironment("bar");
const bool barFromEnvOrNullBool =
    const bool.fromEnvironment("bar", defaultValue: null);
const bool barFromEnvOrActualBool =
    const bool.fromEnvironment("bar", defaultValue: true);
const bool nullFromEnvBool = const bool.fromEnvironment(barFromEnvOrNullString);

const int barFromEnvInt = const int.fromEnvironment("bar");
const int barFromEnvOrNullInt =
    const int.fromEnvironment("bar", defaultValue: null);
const int barFromEnvOrActualInt =
    const int.fromEnvironment("bar", defaultValue: 42);
const int nullFromEnvInt = const int.fromEnvironment(barFromEnvOrNullString);

// Environment does contain "baz" (value '42', i.e. neither true nor false).
const bool bazFromEnv = const bool.fromEnvironment("baz");
const bool hasBazEnv = const bool.hasEnvironment("baz");
const int bazFromEnvAsInt = const int.fromEnvironment("baz");
const String bazFromEnvAsString = const String.fromEnvironment("baz");

// Environment does contain "bazTrue" (value 'true') and
// "bazFalse" (value 'false').
const bool bazTrueFromEnv = const bool.fromEnvironment("bazTrue");
const bool bazFalseFromEnv = const bool.fromEnvironment("bazFalse");

const bool trueBool = true;
const bool falseBool = false;
const bool binaryOnBoolCaret = trueBool ^ falseBool;
const bool binaryOnBoolAmpersand = trueBool & falseBool;
const bool binaryOnBoolBar = trueBool | falseBool;
const bool binaryOnBoolBar2 = falseBool | trueBool;

const dynamic willBeDouble = const bool.fromEnvironment("foo") ? 42 : 42.42;
const binaryOnDouble = willBeDouble << 2;
const dynamic willBeInt = const bool.fromEnvironment("foo") ? 42.42 : 42;
const binaryOnIntWithDoubleBad = willBeInt << willBeDouble;
const binaryOnIntWithDoubleOK = willBeInt + willBeDouble;
const binaryOnIntWithString = willBeInt << "hello";
const dynamic willBeString =
    const bool.fromEnvironment("foo") ? 42.42 : "hello";
const binaryOnStringWithStringOK = willBeString + " world";
const binaryOnStringWithInt = willBeString + willBeInt;
const binaryOnStringWithStringBad = willBeString - " world";

var x = 1;
const x1 = --x;
const x2 = ++x;
const x3 = x--;
const x4 = x++;

const y = 1;
const y1 = --y;
const y2 = ++y;
const y3 = y--;
const y4 = y++;

abstract class AbstractClass {}

abstract class AbstractClassWithConstructor {
  const AbstractClassWithConstructor();

  int foo();
}

AbstractClassWithConstructor abstractClassWithConstructor =
    const AbstractClassWithConstructor();

class NotAbstractClass {
  @AbstractClass()
  Object foo;

  @AbstractClassWithConstructor()
  Object bar;
}

class Foo {
  final int x;
  final int y;
  const Foo(int x)
      : this.x = x,
        this.y = "hello".length;
}

class ExtendsFoo1 extends Foo {
  // No constructor.
}

const ExtendsFoo1 extendsFoo1 = const ExtendsFoo1();

class ExtendsFoo2 extends Foo {
  const ExtendsFoo2();
}

const ExtendsFoo2 extendsFoo2 = const ExtendsFoo2();

const Foo foo1 = const Foo(42);
const Foo foo2 = const Foo(42);
const bool foosIdentical = identical(foo1, foo2);
const bool foosEqual = foo1 == foo2;
const Symbol barFoo = const Symbol("Foo");
const Symbol barFooEqual = const Symbol("Foo=");
const Symbol tripleShiftSymbol = const Symbol(">>>");
const Symbol symbolWithDots = const Symbol("I.Have.Dots");

const int circularity1 = circularity2;
const int circularity2 = circularity3;
const int circularity3 = circularity4;
const int circularity4 = circularity1;

const function_const = () {};
var function_var = () {};

class ConstClassWithFailingAssertWithEmptyMessage {
  const ConstClassWithFailingAssertWithEmptyMessage() : assert(false, "");
}

ConstClassWithFailingAssertWithEmptyMessage failedAssertEmptyMessage =
    const ConstClassWithFailingAssertWithEmptyMessage();

class ClassWithTypeArguments<E, F, G> {
  const ClassWithTypeArguments(E e, F f, G g);
}

const ClassWithTypeArguments classWithTypeArguments1 =
    const ClassWithTypeArguments<int, int, int>(42, 42, 42);
const ClassWithTypeArguments classWithTypeArguments2 =
    const ClassWithTypeArguments(42, 42, 42);
const bool classWithTypeArgumentsIdentical =
    identical(classWithTypeArguments1, classWithTypeArguments2);

class ClassWithNonEmptyConstConstructor {
  const ClassWithNonEmptyConstConstructor() {
    print("hello");
  }
}

ClassWithNonEmptyConstConstructor classWithNonEmptyConstConstructor =
    const ClassWithNonEmptyConstConstructor();

class ConstClassWithFinalFields1 {
  const ConstClassWithFinalFields1();

  final x = 1;
}

class ConstClassWithFinalFields2 {
  const ConstClassWithFinalFields2();

  final y = 1;
  final z1 = y;
  final z2 = x;
}

ConstClassWithFinalFields2 constClassWithFinalFields =
    const ConstClassWithFinalFields2();

const zeroPointZeroIdentical = identical(0.0, 0.0);
const zeroPointZeroIdenticalToZero = identical(0.0, 0);
const zeroIdenticalToZeroPointZero = identical(0, 0.0);
const nanIdentical = identical(0 / 0, 0 / 0);

const zeroPointZeroEqual = 0.0 == 0.0;
const zeroPointZeroEqualToZero = 0.0 == 0;
const zeroEqualToZeroPointZero = 0 == 0.0;
const nanEqual = 0 / 0 == 0 / 0;

T id1<T>(T t) => t;
T id2<T>(T t) => t;

const dynamic willBecomeNull = const bool.fromEnvironment("foo") ? id1 : null;

const int Function(int) willBecomeNullToo =
    const bool.fromEnvironment("foo") ? id1 : willBecomeNull;
const int Function(int) partialInstantiation =
    const bool.fromEnvironment("foo") ? willBecomeNull : id1;

const bool yBool = true;
const bool zBool = !yBool;

const maybeInt = bool.fromEnvironment("foo") ? 42 : true;
const bool isItInt = maybeInt is int ? true : false;
const maybeInt2 = zBool ? 42 : true;
const bool isItInt2 = maybeInt2 is int ? true : false;
const maybeInt3 = zBool ? 42 : null;
const bool isItInt3 = maybeInt3 is int ? true : false;

main() {
  print(barFromEnv);
  print(hasBarEnv);
}
