
class DocumentTypeJs extends NodeJs implements DocumentType native "*DocumentType" {

  NamedNodeMapJs get entities() native "return this.entities;";

  String get internalSubset() native "return this.internalSubset;";

  String get name() native "return this.name;";

  NamedNodeMapJs get notations() native "return this.notations;";

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}
