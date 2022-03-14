class Class {
  augment augment method() {}
  augment external method();
  external augment method();

  augment augment void method() {}
  augment external void method();
  external augment void method();

  augment augment get getter => null;
  augment external get getter;
  external augment get getter;

  augment augment int get getter => 0;
  augment external int get getter;
  external augment int get getter;

  augment augment set setter(value) {}
  augment external set setter(value);
  external augment set setter(value);

  augment augment void set setter(value) {}
  augment external void set setter(value);
  external augment void set setter(value);

  augment augment var field;
  augment external var field;
  external augment var field;

  augment augment final field = 0;
  augment external final field;
  external augment final field;

  augment augment const field = 0;
  augment external const field;
  external augment const field;

  augment augment int field;
  augment external int field;
  external augment int field;

  augment augment late var field;
  augment late var field;
  augment late var field;

  augment augment late final field;
  augment late final field;
  augment late final field;

  augment augment late int field;
  augment late int field;
  augment late int field;

  augment augment static method() {}
  static augment method() {}

  augment augment static void method() {}
  static augment void method() {}

  augment augment static get getter => null;
  static augment get getter => null;

  augment augment static int get getter => 0;
  static augment int get getter => 0;

  augment augment static set setter(value) {}
  static augment set setter(value) {}

  augment augment static void set setter(value) {}
  static augment void set setter(value) {}

  augment augment static var field;
  static augment var field;

  augment augment static final field = 0;
  static augment final field = 0;

  augment augment static const field = 0;
  static augment const field = 0;

  augment augment static int field;
  static augment int field;

  augment augment static late var field;
  static augment late var field;

  augment augment static late final field;
  static augment late final field;

  augment augment static late int field;
  static augment late int field;
}
