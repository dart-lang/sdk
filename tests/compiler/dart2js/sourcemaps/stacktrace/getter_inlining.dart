class MyClass {
  int fieldName;

  MyClass(this.fieldName);

  int get getterName => /*1:getterName(inlined)*/ fieldName;
}

@pragma('dart2js:noInline')
confuse(x) => x;

main() {
  confuse(new MyClass(3));
  var m = confuse(null);
  m. /*0:main*/ getterName;
}
