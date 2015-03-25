part of dart.convert;
 abstract class Encoding extends Codec<String, List<int>> {const Encoding();
 Future<String> decodeStream(Stream<List<int>> byteStream) {
  return ((__x5) => DEVC$RT.cast(__x5, DEVC$RT.type((DDC$async$.Future<dynamic> _) {
    }
  ), DEVC$RT.type((DDC$async$.Future<String> _) {
    }
  ), "CompositeCast", """line 14, column 12 of dart:convert/encoding.dart: """, __x5 is DDC$async$.Future<String>, false))(byteStream.transform(DEVC$RT.cast(decoder, DEVC$RT.type((Converter<List<int>, String> _) {
    }
  ), DEVC$RT.type((DDC$async$.StreamTransformer<List<int>, dynamic> _) {
    }
  ), "CompositeCast", """line 15, column 18 of dart:convert/encoding.dart: """, decoder is DDC$async$.StreamTransformer<List<int>, dynamic>, false)).fold(new StringBuffer(), (buffer, string) => buffer..write(string)).then((buffer) => buffer.toString()));
  }
 String get name;
 static Map<String, Encoding> _nameToEncoding = <String, Encoding> {
  "iso_8859-1:1987" : LATIN1, "iso-ir-100" : LATIN1, "iso_8859-1" : LATIN1, "iso-8859-1" : LATIN1, "latin1" : LATIN1, "l1" : LATIN1, "ibm819" : LATIN1, "cp819" : LATIN1, "csisolatin1" : LATIN1, "iso-ir-6" : ASCII, "ansi_x3.4-1968" : ASCII, "ansi_x3.4-1986" : ASCII, "iso_646.irv:1991" : ASCII, "iso646-us" : ASCII, "us-ascii" : ASCII, "us" : ASCII, "ibm367" : ASCII, "cp367" : ASCII, "csascii" : ASCII, "ascii" : ASCII, "csutf8" : UTF8, "utf-8" : UTF8}
;
 static Encoding getByName(String name) {
  if (name == null) return null;
   name = name.toLowerCase();
   return _nameToEncoding[name];
  }
}
