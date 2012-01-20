
class BeforeLoadEvent extends Event native "*BeforeLoadEvent" {

  String get url() native "return this.url;";
}
