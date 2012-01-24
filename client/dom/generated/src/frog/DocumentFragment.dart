
class DocumentFragmentJs extends NodeJs implements DocumentFragment native "*DocumentFragment" {

  ElementJs querySelector(String selectors) native;

  NodeListJs querySelectorAll(String selectors) native;
}
