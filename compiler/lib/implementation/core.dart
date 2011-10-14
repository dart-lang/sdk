// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ConstHelper {
  static String getConstId(var o) native;

  static String getConstMapId(Map map) native {
    StringBuffer sb = new StringBuffer();
    sb.add("m");
    bool first = true;
    for (String key in map.getKeys()) {
      if (first) {
        first = false;
      } else {
        sb.add(",");
      }
      sb.add(getConstId(key));
      sb.add(",");
      sb.add(getConstId(map[key]));
    }
    return sb.toString();
  }
}

class ExceptionHelper {
  static NullPointerException createNullPointerException() native {
    return new NullPointerException();
  }

  static ObjectNotClosureException createObjectNotClosureException() native {
    return new ObjectNotClosureException();
  }

  static NoSuchMethodException createNoSuchMethodException(
      receiver, functionName, arguments) native {
    return new NoSuchMethodException(receiver, functionName, arguments);
  }

  static TypeError createTypeError(String srcType, String dstType) native {
    return new TypeError(srcType, dstType);
  }
  
  static AssertionError createAssertionError() native {
    return new AssertionError();
  }
}

class _CoreJsUtil {
  static Map _newMapLiteral() native {
    return new LinkedHashMap();
  }
}

