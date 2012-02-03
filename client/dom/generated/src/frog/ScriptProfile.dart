
class _ScriptProfileJs extends _DOMTypeJs implements ScriptProfile native "*ScriptProfile" {

  _ScriptProfileNodeJs get head() native "return this.head;";

  String get title() native "return this.title;";

  int get uid() native "return this.uid;";
}
