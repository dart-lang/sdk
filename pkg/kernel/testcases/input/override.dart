class Foo {}

class Bar extends Foo {}

class Base {
  Foo method() {
    return new Foo();
  }
}

class Sub extends Base {
  Foo method() {
    return new Bar();
  }
}

main(List<String> args) {
  var object = args.length == 0 ? new Base() : new Sub();
  var a = object.method();
  print(a);
}
