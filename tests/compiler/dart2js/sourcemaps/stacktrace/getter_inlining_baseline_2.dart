class MyClass {
  int fieldName;

  MyClass(this.fieldName);

  // This is a baseline test for no inlining of getter.
  @pragma('dart2js:noInline')
  int get getterName => fieldName;
}

@pragma('dart2js:noInline')
confuse(x) => x;

@pragma('dart2js:noInline')
sink(x) {}

main() {
  confuse(new MyClass(3));
  var m = confuse(null);
  sink(m. /*0:main*/ getterName);
  sink(m.getterName);
}
