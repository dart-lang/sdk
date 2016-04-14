// compile options: --closure-experimental --destructure-named-params --modules=es6
library test;
import 'dart:js';

List/*<T>*/ generic_function/*<T>*/(List/*<T>*/ items, dynamic/*=T*/ seed) {
  var strings = items.map((i) => "$i").toList();
  return items;
}

typedef void Callback({int i});

class Foo<T> {
  final int i;
  bool b;
  String s;
  T v;

  Foo(this.i, this.v);

  factory Foo.build() => new Foo(1, null);

  untyped_method(a, b) {}

  T pass(T t) => t;

  String typed_method(
      Foo foo, List list,
      int i, num n, double d, bool b, String s,
      JsArray a, JsObject o, JsFunction f) {
    return '';
  }

  optional_params(a, [b, int c]) {}

  static named_params(a, {b, int c}) {}

  nullary_method() {}

  function_params(int f(x, [y]), g(x, {String y, z}), Callback cb) {
    cb(i: i);
  }

  run(List a, String b, List c(String d), List<int> e(f(g)), {Map<Map, Map> h}) {}

  String get prop => null;
  set prop(String value) {}

  static String get staticProp => null;
  static set staticProp(String value) {}

  static const String some_static_constant = "abc";
  static final String some_static_final = "abc";
  static String some_static_var = "abc";
}

class Bar {}

class Baz extends Foo<int> with Bar {
  Baz(int i) : super(i, 123);
}

void main(args) {}

const String some_top_level_constant = "abc";
final String some_top_level_final = "abc";
String some_top_level_var = "abc";
