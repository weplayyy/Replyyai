/// Bundled preset photos for room PFPs, grouped by category.
/// Drop the matching .png files into `assets/rooms/` and declare the
/// folder in pubspec.yaml (see "Pubspec change" below).
class RoomPresets {
  static const String fallback = 'assets/rooms/default.png';

  static const Map<String, List<String>> byCategory = {
    'Late Night': [
      'assets/rooms/late_night_1.png',
      'assets/rooms/late_night_2.png',
      'assets/rooms/late_night_3.png',
      'assets/rooms/late_night_4.png',
    ],
    'Confessions': [
      'assets/rooms/confessions_1.png',
      'assets/rooms/confessions_2.png',
      'assets/rooms/confessions_3.png',
      'assets/rooms/confessions_4.png',
    ],
    'Flirting': [
      'assets/rooms/flirting_1.png',
      'assets/rooms/flirting_2.png',
      'assets/rooms/flirting_3.png',
      'assets/rooms/flirting_4.png',
    ],
    'Memes': [
      'assets/rooms/memes_1.png',
      'assets/rooms/memes_2.png',
      'assets/rooms/memes_3.png',
      'assets/rooms/memes_4.png',
    ],
    'Debates': [
      'assets/rooms/debates_1.png',
      'assets/rooms/debates_2.png',
      'assets/rooms/debates_3.png',
      'assets/rooms/debates_4.png',
    ],
  };

  static List<String> photosFor(String category) =>
      byCategory[category] ?? const [fallback];

  static String firstFor(String category) {
    final list = photosFor(category);
    return list.isNotEmpty ? list.first : fallback;
  }
}
