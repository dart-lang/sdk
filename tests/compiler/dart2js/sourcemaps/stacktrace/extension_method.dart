class MyClass {
  MyClass();

  @pragma('dart2js:noInline')
  set internalSetter(int v) {
    /*7:MyClass.internalSetter*/ throw "error";
  }
}

int q = 3;

extension Ext on MyClass {
  @pragma('dart2js:noInline')
  int method() {
    this./*6:Ext.method*/ internalSetter = 1;
    // TODO(sigmund): remove once kernel preserves noInline pragmas. #38439
    if (q > 29) return 3;
    return 2;
  }

  @pragma('dart2js:noInline')
  int get propertyB {
    /*5:Ext.propertyB*/ method();
    // TODO(sigmund): remove once kernel preserves noInline pragmas. #38439
    if (q > 29) return 3;
    return 2;
  }

  @pragma('dart2js:noInline')
  set propertyA(int v) {
    /*4:Ext.propertyA*/ propertyB;
    // TODO(sigmund): remove once kernel preserves noInline pragmas. #38439
    if (q > 29) return null;
    return null;
  }

  @pragma('dart2js:noInline')
  int operator+(int v) {
    this./*3:Ext.+*/ propertyA = 2;
    // TODO(sigmund): remove once kernel preserves noInline pragmas. #38439
    if (q > 30) return 1;
    return 3;
  }

  @pragma('dart2js:noInline')
  int operator[](int v) {
    this /*2:Ext.[]*/ + 2;
    // TODO(sigmund): remove once kernel preserves noInline pragmas. #38439
    if (q > 30) return 1;
    return 3;
  }
}

extension on MyClass {
  @pragma('dart2js:noInline')
  int method2() {
    this/*1:MyClass.<anonymous extension>.method2*/[0];
    // TODO(sigmund): remove once kernel preserves noInline pragmas. #38439
    if (q > 29) return 3;
    return 2;
  }
}

@pragma('dart2js:noInline')
confuse(x) => x;

main() {
  q++;
  confuse(null);
  MyClass x = confuse(new MyClass());
  x. /*0:main*/method2();
}
