
class FileWriterJS implements FileWriter native "*FileWriter" {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  FileErrorJS get error() native "return this.error;";

  int get length() native "return this.length;";

  EventListener get onabort() native "return this.onabort;";

  void set onabort(EventListener value) native "this.onabort = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  EventListener get onprogress() native "return this.onprogress;";

  void set onprogress(EventListener value) native "this.onprogress = value;";

  EventListener get onwrite() native "return this.onwrite;";

  void set onwrite(EventListener value) native "this.onwrite = value;";

  EventListener get onwriteend() native "return this.onwriteend;";

  void set onwriteend(EventListener value) native "this.onwriteend = value;";

  EventListener get onwritestart() native "return this.onwritestart;";

  void set onwritestart(EventListener value) native "this.onwritestart = value;";

  int get position() native "return this.position;";

  int get readyState() native "return this.readyState;";

  void abort() native;

  void seek(int position) native;

  void truncate(int size) native;

  void write(BlobJS data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
