
class _NodeSelectorJs extends _DOMTypeJs implements NodeSelector native "*NodeSelector" {

  _ElementJs querySelector(String selectors) native;

  _NodeListJs querySelectorAll(String selectors) native;
}
