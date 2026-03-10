/// Education Module - REQ-6.x
/// What is AQI, pollutants, health effects
library;

class EducationTopic {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final bool kidFriendly;

  const EducationTopic({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.kidFriendly = false,
  });
}

class EducationRepository {
  static final _topics = [
    const EducationTopic(
      id: 'what_is_aqi',
      title: 'What is AQI?',
      content: '''The Air Quality Index (AQI) is a numerical scale from 0 to 500 that tells you how clean or polluted the air is. 

• 0–50: Good – Air quality is satisfactory.
• 51–100: Moderate – Acceptable; sensitive people should limit prolonged outdoor exertion.
• 101–150: Unhealthy for Sensitive Groups – People with heart or lung disease, older adults, and children may be affected.
• 151–200: Unhealthy – Everyone may experience health effects.
• 201–300: Very Unhealthy – Health alert; everyone may experience serious effects.
• 301–500: Hazardous – Health emergency.''',
      kidFriendly: true,
    ),
    const EducationTopic(
      id: 'pm25',
      title: 'PM2.5 (Fine Particulate Matter)',
      content: '''PM2.5 are tiny particles smaller than 2.5 micrometers. They can enter deep into your lungs and bloodstream.

Sources: Vehicle exhaust, wildfires, industrial emissions, dust.

Health effects: Short-term – coughing, shortness of breath, irritated eyes. Long-term – heart disease, lung disease, reduced life expectancy.''',
    ),
    const EducationTopic(
      id: 'pm10',
      title: 'PM10 (Coarse Particulate Matter)',
      content: '''PM10 particles are larger than PM2.5 but still small enough to inhale. They mainly affect the upper airways.

Sources: Dust, construction, agriculture, pollen.

Health effects: Coughing, throat irritation, worsened asthma and allergies.''',
    ),
    const EducationTopic(
      id: 'ozone',
      title: 'Ozone (O3)',
      content: '''Ground-level ozone forms when pollutants from cars and industry react with sunlight. It's different from the protective ozone layer in the upper atmosphere.

Health effects: Chest pain, coughing, throat irritation, worsening of asthma. Worst on hot, sunny days.''',
    ),
    const EducationTopic(
      id: 'nitrogen_dioxide',
      title: 'Nitrogen Dioxide (NO2)',
      content: '''NO2 comes mainly from vehicles and power plants. It contributes to smog and acid rain.

Health effects: Irritated airways, increased asthma attacks, greater susceptibility to respiratory infections.''',
    ),
    const EducationTopic(
      id: 'health_effects',
      title: 'Health Effects of Air Pollution',
      content: '''Short-term: Eye, nose, throat irritation; coughing; shortness of breath; worsened asthma.

Long-term: Heart disease, stroke, lung cancer, chronic respiratory disease, developmental effects in children.

Sensitive groups (children, elderly, people with asthma or heart disease) are at higher risk.''',
    ),
    const EducationTopic(
      id: 'environment',
      title: 'Environmental Impact',
      content: '''Air pollution affects ecosystems: acid rain damages forests and water; ozone harms crops; particulates reduce sunlight for plants. Reducing emissions protects both human health and the environment.''',
    ),
  ];

  List<EducationTopic> getAll() => List.unmodifiable(_topics);

  EducationTopic? getById(String id) =>
      _topics.cast<EducationTopic?>().firstWhere(
            (t) => t?.id == id,
            orElse: () => null,
          );

  List<String> get pollutantIds => ['pm25', 'pm10', 'ozone', 'nitrogen_dioxide'];
}
