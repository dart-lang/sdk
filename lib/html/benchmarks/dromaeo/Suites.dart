class Origin {
  final String author;
  final String url;

  const Origin(this.author, this.url);
}

class SuiteDescription {
  final String file;
  final String name;
  final Origin origin;
  final String description;

  const SuiteDescription(this.file, this.name, this.origin, this.description);
}

class Suites {
  static final JOHN_RESIG = const Origin('John Resig', 'http://ejohn.org/');

  static final SUITE_DESCRIPTIONS = const [
      const SuiteDescription(
          'dom-attr.html',
          'DOM Attributes',
          JOHN_RESIG,
          'Setting and getting DOM node attributes'),
      const SuiteDescription(
          'dom-modify.html',
          'DOM Modification',
          JOHN_RESIG,
          'Creating and injecting DOM nodes into a document'),
      const SuiteDescription(
          'dom-query.html',
          'DOM Query',
          JOHN_RESIG,
          'Querying DOM elements in a document'),
      const SuiteDescription(
          'dom-traverse.html',
          'DOM Traversal',
          JOHN_RESIG,
          'Traversing a DOM structure')
  ];
}
