
class EntryArraySyncJs extends DOMTypeJs implements EntryArraySync native "*EntryArraySync" {

  int get length() native "return this.length;";

  EntrySyncJs item(int index) native;
}
