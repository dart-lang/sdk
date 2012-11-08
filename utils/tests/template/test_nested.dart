// Sample for #with templates:
//
//       productview.tmpl
//       productview2.tmpl


import 'dart:html';
part 'nestedview.dart';

class Person {
  String name;
  int age;

  Person(this.name, this.age);
}

void main() {
  // Simple template.
  Person person1 = new Person("Aristotle - Bugger for the bottle", 52);
  Person person2 = new Person("René Descartes - Drunken fart", 62);

  NestedView view = new NestedView(person1, person2);
  document.body.elements.add(view.root);
}

