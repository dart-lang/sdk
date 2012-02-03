
class _ValidityStateJs extends _DOMTypeJs implements ValidityState native "*ValidityState" {

  bool get customError() native "return this.customError;";

  bool get patternMismatch() native "return this.patternMismatch;";

  bool get rangeOverflow() native "return this.rangeOverflow;";

  bool get rangeUnderflow() native "return this.rangeUnderflow;";

  bool get stepMismatch() native "return this.stepMismatch;";

  bool get tooLong() native "return this.tooLong;";

  bool get typeMismatch() native "return this.typeMismatch;";

  bool get valid() native "return this.valid;";

  bool get valueMissing() native "return this.valueMissing;";
}
