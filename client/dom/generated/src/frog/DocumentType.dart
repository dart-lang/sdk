
class DocumentTypeJS extends NodeJS implements DocumentType native "*DocumentType" {

  NamedNodeMapJS get entities() native "return this.entities;";

  String get internalSubset() native "return this.internalSubset;";

  String get name() native "return this.name;";

  NamedNodeMapJS get notations() native "return this.notations;";

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}
