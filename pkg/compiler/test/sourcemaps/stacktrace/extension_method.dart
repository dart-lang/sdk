class MyClass {
  MyClass();

// @dart = 2.7
  @pragma('dart2js:noInline')
  set internalSetter(int v) {
    /*7:MyClass.internalSetter*/ throw "error";
  }
}

int q = 3;

extension Ext on MyClass {
  @pragma('dart2js:noInline')
  int method() {
    this. /*6:Ext.method*/ internalSetter = 1;
    return 0;
  }

  @pragma('dart2js:noInline')
  int get propertyB => /*5:Ext.propertyB*/ method();

  @pragma('dart2js:noInline')
  set propertyA(int v) {
    /*4:Ext.propertyA*/ propertyB;
  }

  @pragma('dart2js:noInline')
  int operator +(int v) {
    this. /*3:Ext.+*/ propertyA = 2;
    return 1;
  }

  @pragma('dart2js:noInline')
  int operator [](int v) => this /*2:Ext.[]*/ + 2;
}

extension on MyClass {
  @pragma('dart2js:noInline')
  int method2() => this /*1:MyClass.<anonymous extension>.method2*/ [0];
}

@pragma('dart2js:noInline')
confuse(x) => x;

main() {
  q++;
  confuse(null);
  MyClass x = confuse(new MyClass());
  x. /*0:main*/ method2();
}
