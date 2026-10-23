enum EnvironmentMode { indoor, outdoor }

extension EnvironmentModeX on EnvironmentMode {
  String get label => switch (this) {
        EnvironmentMode.indoor => 'INDOOR',
        EnvironmentMode.outdoor => 'OUTDOOR',
      };

  String get emoji => switch (this) {
        EnvironmentMode.indoor => '🏠',
        EnvironmentMode.outdoor => '🌳',
      };

  String get description => switch (this) {
        EnvironmentMode.indoor => 'Home, rooms and cozy everyday worlds.',
        EnvironmentMode.outdoor => 'Nature, open spaces and adventures outside.',
      };
}
