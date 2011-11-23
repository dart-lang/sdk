
class DirectoryReaderSync native "*DirectoryReaderSync" {

  EntryArraySync readEntries() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
