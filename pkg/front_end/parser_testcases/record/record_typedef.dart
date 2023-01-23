typedef (int, int) T1();
typedef ({int j}) T2();
typedef (int, int)? T3();
typedef ({int j})? T4();

/// Syntactically tricky coincidences containing >>> and >>>=.
/// DO NOT FORMAT THIS FILE. There should not be a space between >>> and =.
typedef F1<T extends (int, int)>= T Function();
typedef F2<T extends List<(int, int)>>= T Function();
typedef F3<T extends List<List<(int, int)>>>= T Function();
typedef F4<T extends List<List<List<(int, int)>>>>= T Function();
typedef F5<T extends List<List<List<List<(int, int)>>>>>= T Function();
typedef F6<T extends List<List<List<List<List<(int, int)>>>>>>= T Function();
