
class ScriptProfileJs extends DOMTypeJs implements ScriptProfile native "*ScriptProfile" {

  ScriptProfileNodeJs get head() native "return this.head;";

  String get title() native "return this.title;";

  int get uid() native "return this.uid;";
}
