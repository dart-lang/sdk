
class _DocumentFragmentImpl extends _NodeImpl implements DocumentFragment native "*DocumentFragment" {

  ElementEvents get on() =>
    new ElementEvents(this);

  _ElementImpl query(String selectors) native "return this.querySelector(selectors);";

  _NodeListImpl _querySelectorAll(String selectors) native "return this.querySelectorAll(selectors);";
}
