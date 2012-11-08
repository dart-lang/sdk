// Sample for complex templates:
//
//       top_searches_css.tmpl

import 'dart:html';
part 'complex_datamodel.dart';
part 'top_searches.dart';

void main() {
  List<Person> persons = dataModel;

  Person whichPerson = persons[2];
  var searchesView = new TopSearches(whichPerson, whichPerson.searches);

  document.body.elements.add(searchesView.root);
}

