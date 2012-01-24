
class DocumentFragmentJS extends NodeJS implements DocumentFragment native "*DocumentFragment" {

  ElementJS querySelector(String selectors) native;

  NodeListJS querySelectorAll(String selectors) native;
}
