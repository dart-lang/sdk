
class ProgressEvent extends Event native "*ProgressEvent" {

  bool get lengthComputable() native "return this.lengthComputable;";

  int get loaded() native "return this.loaded;";

  int get total() native "return this.total;";
}
