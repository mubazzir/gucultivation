class AppConstants {
  static const String appName = 'Gu Cultivation';
  static const String hiveBoxUser = 'user_profile';
  static const String hiveBoxGu = 'gu_collection';
  static const String hiveBoxMaterials = 'materials';
  static const String hiveBoxPaths = 'paths';
  static const String hiveBoxTasks = 'tasks';
  static const String hiveBoxEvents = 'events';
  static const String hiveBoxStats = 'statistics';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxSession = 'cultivation_session';

  // Aptitude grades
  static const List<String> aptitudes = ['A', 'B', 'C', 'D', 'E'];

  static const Map<String, String> aptitudeDescriptions = {
    'A': 'Excellent innate aptitude. Your cultivation potential is exceptional. Primeval essence flows freely through your apertures.',
    'B': 'Strong aptitude with considerable cultivation potential. Steady progress awaits the diligent.',
    'C': 'Average aptitude. Progress will require persistence and clever use of resources.',
    'D': 'Low aptitude. Every advancement must be earned through sweat and sacrifice.',
    'E': 'Extremely poor aptitude. The road ahead will be difficult, yet legends are forged in hardship.',
  };

  static const Map<String, double> aptitudeModifiers = {
    'A': 1.5,
    'B': 1.25,
    'C': 1.0,
    'D': 0.8,
    'E': 0.6,
  };
  static const String heavenPathName = 'Heaven Path';

  static const List<String> heavenDailyTasks = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
    'quran',
  ];

  static const Map<String, String> heavenTaskLabels = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
    'quran': 'Quran',
  };

  // Path attainment ranks
  static const List<String> attainmentRanks = [
    'Ordinary',
    'Master',
    'Grandmaster',
    'Great Grandmaster',
    'Quasi Supreme Grandmaster',
    'Supreme Grandmaster',
  ];

  // Cultivation ranks
  static const List<String> cultivationRanks = [
    'Rank 1',
    'Rank 2',
    'Rank 3',
    'Rank 4',
    'Rank 5',
    'Rank 6',
    'Rank 7',
    'Rank 8',
    'Rank 9',
  ];

  static const List<String> realms = [
    'Initial Stage',
    'Middle Stage',
    'Upper Stage',
    'Peak Stage',
  ];
}
