/// Available AI models and their configurations
class AIModel {
  final String id;
  final String name;
  final String provider;
  final String description;
  final int maxTokens;
  final double temperature;

  const AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.maxTokens,
    this.temperature = 0.3,
  });

  /// Get model by ID
  static AIModel? fromId(String id) {
    return availableModels.firstWhere(
      (model) => model.id == id,
      orElse: () => gemini15Flash,
    );
  }

  /// List of all available models
  static const List<AIModel> availableModels = [
    gemini15Flash,
    gemini15Pro,
    gpt4o,
    gpt4oMini,
    claude3Opus,
    claude3Sonnet,
  ];

  // Google Gemini Models
  static const gemini15Flash = AIModel(
    id: 'gemini-1.5-flash',
    name: 'Gemini 1.5 Flash',
    provider: 'google',
    description: 'Fast and efficient model for code fixes',
    maxTokens: 8192,
  );

  static const gemini15Pro = AIModel(
    id: 'gemini-1.5-pro',
    name: 'Gemini 1.5 Pro',
    provider: 'google',
    description: 'Advanced model for complex code analysis',
    maxTokens: 8192,
  );

  // OpenAI Models (future support)
  static const gpt4o = AIModel(
    id: 'gpt-4o',
    name: 'GPT-4 Optimized',
    provider: 'openai',
    description: 'OpenAI\'s most capable model',
    maxTokens: 4096,
  );

  static const gpt4oMini = AIModel(
    id: 'gpt-4o-mini',
    name: 'GPT-4 Mini',
    provider: 'openai',
    description: 'Faster, more affordable GPT-4',
    maxTokens: 4096,
  );

  // Anthropic Models (future support)
  static const claude3Opus = AIModel(
    id: 'claude-3-opus',
    name: 'Claude 3 Opus',
    provider: 'anthropic',
    description: 'Most capable Claude model',
    maxTokens: 4096,
  );

  static const claude3Sonnet = AIModel(
    id: 'claude-3-sonnet',
    name: 'Claude 3 Sonnet',
    provider: 'anthropic',
    description: 'Balanced performance and cost',
    maxTokens: 4096,
  );

  @override
  String toString() => '$name ($id)';
}

/// Extension to check model availability
extension AIModelAvailability on AIModel {
  /// Check if this model is currently supported
  bool get isSupported {
    // Currently only Gemini models are supported
    return provider == 'google';
  }

  /// Get required API key name for this model
  String get apiKeyName {
    switch (provider) {
      case 'google':
        return 'gemini_api_key';
      case 'openai':
        return 'openai_api_key';
      case 'anthropic':
        return 'anthropic_api_key';
      default:
        throw Exception('Unknown provider: $provider');
    }
  }
}
