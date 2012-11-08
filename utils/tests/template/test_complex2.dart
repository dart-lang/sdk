// Sample for complex templates:
//
//       top_searches2.tmpl

import 'dart:html';
part 'complex_datamodel.dart';
part 'top_searches2.dart';

void main() {
  List<Person> persons = dataModel;

  var searchesView = new TopSearches(persons);

  document.body.elements.add(searchesView.root);
}

