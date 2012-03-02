
class _NodeSelectorImpl implements NodeSelector native "*NodeSelector" {

  _ElementImpl querySelector(String selectors) native;

  _NodeListImpl querySelectorAll(String selectors) native;
}
