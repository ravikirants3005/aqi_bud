class RuntimeConfig {
  static const fallback = RuntimeConfig();

  const RuntimeConfig();

  static Future<RuntimeConfig> load() async {
    return const RuntimeConfig();
  }
}
