extension type const ExtensionType1(int it) {}
extension type const ExtensionType2(int it) implements ExtensionType1, int {}
extension type const ExtensionType3<T extends num>(T it) {}
extension type const ExtensionType4(int it) {
  const ExtensionType4.constructor(this.it);
  const ExtensionType4.redirect(int it) : this(it);
  factory ExtensionType4.fact(int it) => ExtensionType4(it);
  const factory ExtensionType4.redirectingFactory(int it) = ExtensionType4;

  int field = 42;
  int get getter => it;
  void set setter(int value) {}
  int method() => it;
  int operator[](int index) => it;
  void operator[]=(int index, int value) {}

  static int staticField = 42;
  static int get staticGetter => 42;
  static void set staticSetter(int value) {}
  static int staticMethod() => 42;
}
extension type const ExtensionType5.new(int it) {}
extension type const ExtensionType6.id(int it) {}
extension type const ExtensionType7<T extends num>.id(int it) {}