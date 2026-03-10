/// Suggestions engine - REQ-2.x
/// Pre-outdoor, during-travel, post-exposure advice per AQI category
library;

import '../models/aqi_models.dart';

class SuggestionItem {
  final String title;
  final String description;
  final String phase; // pre, during, post

  const SuggestionItem({
    required this.title,
    required this.description,
    required this.phase,
  });
}

class SuggestionsRepository {
  List<SuggestionItem> getSuggestions(AqiCategory category, String phase) {
    switch (phase) {
      case 'pre':
        return _preOutdoor(category);
      case 'during':
        return _duringTravel(category);
      case 'post':
        return _postExposure(category);
      default:
        return [..._preOutdoor(category), ..._duringTravel(category), ..._postExposure(category)];
    }
  }

  List<SuggestionItem> getAllSuggestions(AqiCategory category) {
    return [
      ..._preOutdoor(category),
      ..._duringTravel(category),
      ..._postExposure(category),
    ];
  }

  List<SuggestionItem> _preOutdoor(AqiCategory cat) {
    switch (cat) {
      case AqiCategory.good:
        return [
          const SuggestionItem(title: 'Ideal for outdoor activities', description: 'Air quality is good. Enjoy outdoor exercise and activities.', phase: 'pre'),
        ];
      case AqiCategory.moderate:
        return [
          const SuggestionItem(title: 'Generally acceptable', description: 'Consider limiting prolonged outdoor exertion if you are sensitive.', phase: 'pre'),
          const SuggestionItem(title: 'Check pollen count', description: 'If you have allergies, check local pollen levels too.', phase: 'pre'),
        ];
      case AqiCategory.unhealthySensitive:
        return [
          const SuggestionItem(title: 'Reduce outdoor exposure', description: 'Sensitive individuals should limit prolonged outdoor exertion.', phase: 'pre'),
          const SuggestionItem(title: 'Use N95 mask', description: 'Consider an N95 or KN95 mask if you must go outside for long.', phase: 'pre'),
          const SuggestionItem(title: 'Choose timing', description: 'Early morning often has lower pollution. Schedule outdoor activities accordingly.', phase: 'pre'),
        ];
      case AqiCategory.unhealthy:
        return [
          const SuggestionItem(title: 'Avoid strenuous activities', description: 'Everyone should reduce prolonged outdoor exertion.', phase: 'pre'),
          const SuggestionItem(title: 'Wear a mask', description: 'Use N95/KN95 mask for essential outdoor trips.', phase: 'pre'),
          const SuggestionItem(title: 'Use air purifier', description: 'Keep indoor air clean before and after going out.', phase: 'pre'),
        ];
      case AqiCategory.veryUnhealthy:
      case AqiCategory.hazardous:
        return [
          const SuggestionItem(title: 'Stay indoors if possible', description: 'Avoid unnecessary outdoor exposure.', phase: 'pre'),
          const SuggestionItem(title: 'Close windows', description: 'Keep windows closed; use AC with clean filters.', phase: 'pre'),
          const SuggestionItem(title: 'Essential trips only', description: 'If you must go out, wear N95 and limit time outside.', phase: 'pre'),
        ];
    }
  }

  List<SuggestionItem> _duringTravel(AqiCategory cat) {
    switch (cat) {
      case AqiCategory.good:
      case AqiCategory.moderate:
        return [
          const SuggestionItem(title: 'Normal travel', description: 'No special precautions needed. Stay hydrated.', phase: 'during'),
        ];
      case AqiCategory.unhealthySensitive:
        return [
          const SuggestionItem(title: 'Limit time outdoors', description: 'Keep outdoor time short. Take breaks indoors.', phase: 'during'),
          const SuggestionItem(title: 'Avoid heavy traffic', description: 'Traffic areas often have higher pollution. Choose routes with less congestion.', phase: 'during'),
        ];
      case AqiCategory.unhealthy:
        return [
          const SuggestionItem(title: 'Wear mask', description: 'Keep N95/KN95 on when outside.', phase: 'during'),
          const SuggestionItem(title: 'Use car AC', description: 'Set car AC to recirculate to reduce outdoor air intake.', phase: 'during'),
        ];
      case AqiCategory.veryUnhealthy:
      case AqiCategory.hazardous:
        return [
          const SuggestionItem(title: 'Minimize exposure', description: 'Shortest path, minimal stops. Wear N95 throughout.', phase: 'during'),
          const SuggestionItem(title: 'Recirculate air', description: 'Vehicle: recirculate cabin air. Avoid opening windows.', phase: 'during'),
        ];
    }
  }

  List<SuggestionItem> _postExposure(AqiCategory cat) {
    switch (cat) {
      case AqiCategory.good:
      case AqiCategory.moderate:
        return [
          const SuggestionItem(title: 'Shower if needed', description: 'After heavy outdoor activity, a shower can remove particles from skin.', phase: 'post'),
        ];
      case AqiCategory.unhealthySensitive:
        return [
          const SuggestionItem(title: 'Rinse nose', description: 'Use saline nasal rinse to clear particles.', phase: 'post'),
          const SuggestionItem(title: 'Hydrate', description: 'Drink plenty of water to support your respiratory system.', phase: 'post'),
        ];
      case AqiCategory.unhealthy:
        return [
          const SuggestionItem(title: 'Shower and change', description: 'Remove outer clothing and shower to reduce pollutant exposure.', phase: 'post'),
          const SuggestionItem(title: 'Nasal rinse', description: 'Saline nasal rinse helps clear pollutants.', phase: 'post'),
          const SuggestionItem(title: 'Rest', description: 'Allow your body to recover. Avoid additional physical stress.', phase: 'post'),
        ];
      case AqiCategory.veryUnhealthy:
      case AqiCategory.hazardous:
        return [
          const SuggestionItem(title: 'Immediate shower', description: 'Shower and change clothes as soon as you return.', phase: 'post'),
          const SuggestionItem(title: 'Nasal rinse', description: 'Use saline nasal rinse to clear airways.', phase: 'post'),
          const SuggestionItem(title: 'Monitor symptoms', description: 'Watch for coughing, irritation. Rest and hydrate. Seek medical advice if symptoms persist.', phase: 'post'),
        ];
    }
  }
}
