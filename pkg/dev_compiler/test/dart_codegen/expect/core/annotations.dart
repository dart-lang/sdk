part of dart.core;
 class Deprecated {final String expires;
 const Deprecated(String expires) : this.expires = expires;
 String toString() => "Deprecated feature. Will be removed $expires";
}
 class _Override {const _Override();
}
 const Deprecated deprecated = const Deprecated("next release");
 const Object override = const _Override();
 class _Proxy {const _Proxy();
}
 const Object proxy = const _Proxy();
