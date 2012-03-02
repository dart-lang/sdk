
class _AttrImpl extends _NodeImpl implements Attr native "*Attr" {

  final bool isId;

  final String name;

  final _ElementImpl ownerElement;

  final bool specified;

  String value;
}
