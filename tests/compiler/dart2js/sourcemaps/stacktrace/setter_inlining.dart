class MyClass {
  int fieldName;

  MyClass(this.fieldName);

  set setterName(int v) => /*1:setterName(inlined)*/ fieldName = v;
}

@pragma('dart2js:noInline')
confuse(x) => x;

main() {
  confuse(new MyClass(3));
  var m = confuse(null);
  m. /*0:main*/ setterName = 2;
}
