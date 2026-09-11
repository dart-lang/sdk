// ignore_for_file: unnecessary_type_name_in_constructor

void main(List<String> args) {
  Foo foo = new Foo(args.length == 42 ? args : null);
  print(foo.lateListLengths);
}

class Foo {
  final List<String>? list;
  late final List<int>? lateListLengths = list?.map((x) => x.length).toList();

  Foo(this.list);
}
