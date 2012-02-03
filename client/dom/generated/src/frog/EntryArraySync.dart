
class _EntryArraySyncJs extends _DOMTypeJs implements EntryArraySync native "*EntryArraySync" {

  int get length() native "return this.length;";

  _EntrySyncJs item(int index) native;
}
