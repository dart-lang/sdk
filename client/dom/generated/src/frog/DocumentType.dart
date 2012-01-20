
class DocumentType extends Node native "*DocumentType" {

  NamedNodeMap get entities() native "return this.entities;";

  String get internalSubset() native "return this.internalSubset;";

  String get name() native "return this.name;";

  NamedNodeMap get notations() native "return this.notations;";

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}
