// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

staticMethod() {
  return "sdfg";
}

class Foo {
  instanceMethod() {
    return 123;
  }
}

external bool externalStatic();

abstract class ExternalValue {}

abstract class Bar {
  ExternalValue externalInstanceMethod();
}

external Bar createBar();

class Box {
  var field;
}

stringArgument(x) {}

intArgument(x) {}

class FinalBox {
  final finalField;
  FinalBox(this.finalField);
}

class SubFinalBox extends FinalBox {
  SubFinalBox(value) : super(value);
}

class DynamicReceiver1 {
  dynamicallyCalled(x) {}
}

class DynamicReceiver2 {
  dynamicallyCalled(x) {}
}

void makeDynamicCall(receiver) {
  receiver.dynamicallyCalled("sdfg");
}

main() {
  var x = staticMethod();
  var y = new Foo().instanceMethod();
  var z = externalStatic();
  var w = createBar().externalInstanceMethod();

  stringArgument("sdfg");
  intArgument(42);

  var box = new Box();
  box.field = "sdfg";
  var a = box.field;

  var finalBox = new FinalBox("dfg");
  var b = finalBox.finalField;

  var subBox = new SubFinalBox("dfg");
  var c = subBox.finalField;

  makeDynamicCall(new DynamicReceiver1());
  makeDynamicCall(new DynamicReceiver2());

  var list = ["string"];
  var d = list[0];
}
