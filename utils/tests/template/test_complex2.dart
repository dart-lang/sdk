// Sample for complex templates:
//
//       top_searches2.tmpl

#import('dart:html');
#source('complex_datamodel.dart');
#source('top_searches2.dart');

void main() {
  List<Person> persons = dataModel;

  var searchesView = new TopSearches(persons);

  document.body.elements.add(searchesView.root);
}

