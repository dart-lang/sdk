
class HTMLMarqueeElementJs extends HTMLElementJs implements HTMLMarqueeElement native "*HTMLMarqueeElement" {

  String get behavior() native "return this.behavior;";

  void set behavior(String value) native "this.behavior = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  String get direction() native "return this.direction;";

  void set direction(String value) native "this.direction = value;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  int get hspace() native "return this.hspace;";

  void set hspace(int value) native "this.hspace = value;";

  int get loop() native "return this.loop;";

  void set loop(int value) native "this.loop = value;";

  int get scrollAmount() native "return this.scrollAmount;";

  void set scrollAmount(int value) native "this.scrollAmount = value;";

  int get scrollDelay() native "return this.scrollDelay;";

  void set scrollDelay(int value) native "this.scrollDelay = value;";

  bool get trueSpeed() native "return this.trueSpeed;";

  void set trueSpeed(bool value) native "this.trueSpeed = value;";

  int get vspace() native "return this.vspace;";

  void set vspace(int value) native "this.vspace = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  void start() native;

  void stop() native;
}
