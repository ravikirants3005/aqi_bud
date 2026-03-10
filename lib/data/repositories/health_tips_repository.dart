/// Health Tips - REQ-3.x
/// Yoga, walking, breathing exercises, lung health
library;

class HealthTip {
  final String id;
  final String title;
  final String category; // yoga, walking, breathing, lung
  final String description;
  final String? duration;
  final List<String> steps;
  final bool hasAnimation;

  const HealthTip({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.duration,
    this.steps = const [],
    this.hasAnimation = false,
  });
}

class HealthTipsRepository {
  static final _tips = [
    const HealthTip(
      id: 'breath_1',
      title: '4-7-8 Breathing',
      category: 'breathing',
      description: 'Calming breath technique for stress and better lung function.',
      duration: '2–4 min',
      steps: [
        'Inhale through nose for 4 seconds',
        'Hold breath for 7 seconds',
        'Exhale slowly through mouth for 8 seconds',
        'Repeat 4 times',
      ],
      hasAnimation: true,
    ),
    const HealthTip(
      id: 'breath_2',
      title: 'Diaphragmatic Breathing',
      category: 'breathing',
      description: 'Strengthens diaphragm and improves oxygen exchange.',
      duration: '5 min',
      steps: [
        'Lie down or sit comfortably',
        'Place one hand on chest, one on belly',
        'Breathe in through nose, belly rises; chest stays still',
        'Exhale slowly, belly falls',
        'Repeat 10–15 times',
      ],
      hasAnimation: true,
    ),
    const HealthTip(
      id: 'breath_3',
      title: 'Pursed-Lip Breathing',
      category: 'breathing',
      description: 'Helps keep airways open longer and reduce breathlessness.',
      duration: '2–5 min',
      steps: [
        'Inhale slowly through nose for 2 counts',
        'Purse lips like blowing out a candle',
        'Exhale slowly for 4 counts',
        'Repeat 5–10 times',
      ],
      hasAnimation: true,
    ),
    const HealthTip(
      id: 'yoga_1',
      title: 'Pranayama (Alternate Nostril)',
      category: 'yoga',
      description: 'Balances breath and calms the nervous system.',
      duration: '5 min',
      steps: [
        'Sit comfortably, spine straight',
        'Close right nostril, inhale through left',
        'Close left, exhale through right',
        'Inhale right, exhale left',
        'Continue for 5 minutes',
      ],
      hasAnimation: false,
    ),
    const HealthTip(
      id: 'yoga_2',
      title: 'Bhujangasana (Cobra Pose)',
      category: 'yoga',
      description: 'Opens chest and improves lung capacity.',
      duration: '2 min',
      steps: [
        'Lie on stomach, palms under shoulders',
        'Inhale and lift chest off floor',
        'Keep elbows slightly bent',
        'Hold 15–30 seconds',
        'Release and repeat 3 times',
      ],
      hasAnimation: false,
    ),
    const HealthTip(
      id: 'walking_1',
      title: 'Brisk Walking in Clean Air',
      category: 'walking',
      description: 'Best when AQI is below 50. Builds lung fitness safely.',
      duration: '20–30 min',
      steps: [
        'Choose low-AQI time (early morning often best)',
        'Walk at moderate pace',
        'Breathe through nose',
        'Gradually increase distance over weeks',
      ],
      hasAnimation: false,
    ),
    const HealthTip(
      id: 'lung_1',
      title: 'Hydration for Lung Health',
      category: 'lung',
      description: 'Keeps mucous thin and easier to clear.',
      steps: [
        'Drink 8–10 glasses of water daily',
        'Avoid excess caffeine and alcohol',
        'Warm fluids like herbal tea can help',
      ],
      hasAnimation: false,
    ),
    const HealthTip(
      id: 'lung_2',
      title: 'Indoor Air Quality',
      category: 'lung',
      description: 'Improve air you breathe at home.',
      steps: [
        'Use HEPA air purifier in bedroom',
        'Ventilate when outdoor AQI is good',
        'Avoid smoking and strong chemicals',
        'Add indoor plants (e.g., peace lily)',
      ],
      hasAnimation: false,
    ),
  ];

  List<HealthTip> getAll() => List.unmodifiable(_tips);

  List<HealthTip> getByCategory(String category) =>
      _tips.where((t) => t.category == category).toList();

  List<String> get categories => ['breathing', 'yoga', 'walking', 'lung'];

  HealthTip? getById(String id) =>
      _tips.cast<HealthTip?>().firstWhere((t) => t?.id == id, orElse: () => null);

  HealthTip getDailyTip() {
    final day = DateTime.now().day % _tips.length;
    return _tips[day];
  }
}
