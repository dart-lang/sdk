
class MetadataJs extends DOMTypeJs implements Metadata native "*Metadata" {

  Date get modificationTime() native "return this.modificationTime;";
}
