// compile options: --modules=es6
library test;

typedef void Callback({int i});

class A {}
class _A {}
class B<T> {}
class _B<T> {}

f() {}
_f() {}

const String constant = "abc";
final String finalConstant = "abc";
final String lazy = (() {
  print('lazy');
  return "abc";
})();
String mutable = "abc";
String lazyMutable = (() {
  print('lazyMutable');
  return "abc";
})();
