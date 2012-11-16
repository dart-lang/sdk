// Sample for #each templates:
//
//       applications.tmpl

import 'dart:html';
part 'applications.dart';

class Product {
  String name;
  int users;

  Product(this.name, this.users);
}

void main() {
  List<Product> products = [];
  products.add(new Product("Gmail", 75000000));
  products.add(new Product("Talk", 5000000));
  products.add(new Product("iGoogle", 2000000));
  products.add(new Product("Dart", 2000));

  var form = new Applications(products);

  document.body.elements.add(form.root);
}
