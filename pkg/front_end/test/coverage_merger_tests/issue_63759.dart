// ignore_for_file: unnecessary_type_name_in_constructor

void main(List<String> args) {
  print([
    for (String s in args.map((s) => "$s!").toList()) new Foo(s.length, bar(s)),
    for (String s in args.map((s) => " - $s").toList())
      new Foo(s.length, bar(s)),
    if (1 + 1 == 3) new Foo(42, "42"),
  ]);
}

String bar(String s) {
  return s.trim();
}

class Foo {
  final int length;
  final String s;

  Foo(this.length, this.s);
}
