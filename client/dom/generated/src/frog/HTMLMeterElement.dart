
class HTMLMeterElementJS extends HTMLElementJS implements HTMLMeterElement native "*HTMLMeterElement" {

  HTMLFormElementJS get form() native "return this.form;";

  num get high() native "return this.high;";

  void set high(num value) native "this.high = value;";

  NodeListJS get labels() native "return this.labels;";

  num get low() native "return this.low;";

  void set low(num value) native "this.low = value;";

  num get max() native "return this.max;";

  void set max(num value) native "this.max = value;";

  num get min() native "return this.min;";

  void set min(num value) native "this.min = value;";

  num get optimum() native "return this.optimum;";

  void set optimum(num value) native "this.optimum = value;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";
}
