// Sample for testing templates:
//
//       name_entry.tmpl
//       name_entry2.tmpl
//       name_entry_css.tmpl

import 'dart:html';
part 'name_entry.dart';

void main() {
  // Simple template.
  var x = new NameEntry("Terry Lucas", 52);
  var y = x.root;
  document.body.elements.add(y);
}

