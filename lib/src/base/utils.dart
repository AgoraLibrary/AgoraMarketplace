/// Convert `foo_bar` to `fooBar`.
String camelCase(String str) {
  int index = str.indexOf('_');
  while (index != -1 && index < str.length - 2) {
    str = str.substring(0, index) +
        str.substring(index + 1, index + 2).toUpperCase() +
        str.substring(index + 2);
    index = str.indexOf('_');
  }
  return str;
}

final RegExp _upperRegex = RegExp(r'[A-Z]');

/// Convert `fooBar` to `foo_bar`.
String snakeCase(String str, [String sep = '_']) {
  return str.replaceAllMapped(_upperRegex,
      (Match m) => '${m.start == 0 ? '' : sep}${m[0]!.toLowerCase()}');
}
