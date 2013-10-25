library java.engine;

class StringUtilities {
  static const String EMPTY = '';
  static const List<String> EMPTY_ARRAY = const <String> [];
  static String intern(String s) => s;
  static String substringBefore(String str, String separator) {
    if (str == null || str.isEmpty) {
      return str;
    }
    int pos = str.indexOf(separator);
    if (pos < 0) {
      return str;
    }
    return str.substring(0, pos);
  }
}

class FileNameUtilities {
  static String getExtension(String fileName) {
    if (fileName == null) {
      return "";
    }
    int index = fileName.lastIndexOf('.');
    if (index >= 0) {
      return fileName.substring(index + 1);
    }
    return "";
  }
}

class ArrayUtils {
  static List addAll(List target, List source) {
    List result = new List.from(target);
    result.addAll(source);
    return result;
  }
}

class UUID {
  static int __nextId = 0;
  final String id;
  UUID(this.id);
  String toString() => id;
  static UUID randomUUID() => new UUID((__nextId).toString());
}
