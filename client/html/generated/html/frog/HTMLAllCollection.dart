
class _HTMLAllCollectionImpl implements HTMLAllCollection native "*HTMLAllCollection" {

  final int length;

  _NodeImpl item(int index) native;

  _NodeImpl namedItem(String name) native;

  _NodeListImpl tags(String name) native;
}
