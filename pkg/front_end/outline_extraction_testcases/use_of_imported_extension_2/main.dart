import "foo.dart";

final foo = [Foo.d, Foo.b];

final foo2 = foo.map((f) => f.giveInt).toList();
