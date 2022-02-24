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

augment augment int field = 0;
augment external int field;
external augment int field;

augment augment class Class {}
abstract augment class Class {}

augment augment class Class = Object with Mixin;
abstract augment class Class = Object with Mixin;

augment augment mixin Mixin {}
