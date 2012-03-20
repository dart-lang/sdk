// Sample for complex templates:
//
//       top_searches_css.tmpl

#import('dart:html');
#source('complex_datamodel.dart');
#source('top_searches.dart');

void main() {
  List<Person> persons = dataModel;

  Person whichPerson = persons[2];
  var searchesView = new TopSearches(whichPerson, whichPerson.searches);

  document.body.elements.add(searchesView.root);
}

