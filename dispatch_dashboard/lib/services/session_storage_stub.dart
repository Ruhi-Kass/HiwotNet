/// In-memory storage stub for non-web environments (tests, VM).
class SessionStorage {
  static final Map<String, String> _memory = {};

  static void setItem(String key, String value) {
    _memory[key] = value;
  }

  static String? getItem(String key) {
    return _memory[key];
  }

  static void removeItem(String key) {
    _memory.remove(key);
  }

  static void clear() {
    _memory.clear();
  }
}
