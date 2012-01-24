
class NodeSelectorJs extends DOMTypeJs implements NodeSelector native "*NodeSelector" {

  ElementJs querySelector(String selectors) native;

  NodeListJs querySelectorAll(String selectors) native;
}
