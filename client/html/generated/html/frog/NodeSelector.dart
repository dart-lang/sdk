
class _NodeSelectorImpl implements NodeSelector native "*NodeSelector" {

  _ElementImpl query(String selectors) native "return this.querySelector(selectors);";

  _NodeListImpl _querySelectorAll(String selectors) native "return this.querySelectorAll(selectors);";
}
