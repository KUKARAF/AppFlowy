class LaunchConfiguration {
  const LaunchConfiguration({
    required this.version,
    required this.rustEnvs,
  });

  final String version;
  final Map<String, String> rustEnvs;
}
