
class HTMLProgressElement extends HTMLElement native "*HTMLProgressElement" {

  HTMLFormElement get form() native "return this.form;";

  NodeList get labels() native "return this.labels;";

  num get max() native "return this.max;";

  void set max(num value) native "this.max = value;";

  num get position() native "return this.position;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";
}
