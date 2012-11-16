// Sample for #with templates:
//
//       productview.tmpl
//       productview2.tmpl


import 'dart:html';
part 'productview.dart';

class Person {
  String name;
  int age;

  Person(this.name, this.age);
}

void main() {
  // Simple template.
  Person person = new Person("Terry Lucas", 52);
  ProductView view = new ProductView(person);
  document.body.elements.add(view.root);
}

