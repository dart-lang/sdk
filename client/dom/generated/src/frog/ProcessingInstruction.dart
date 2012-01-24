
class ProcessingInstructionJs extends NodeJs implements ProcessingInstruction native "*ProcessingInstruction" {

  String get data() native "return this.data;";

  void set data(String value) native "this.data = value;";

  StyleSheetJs get sheet() native "return this.sheet;";

  String get target() native "return this.target;";
}
