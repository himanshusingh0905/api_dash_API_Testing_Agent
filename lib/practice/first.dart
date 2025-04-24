
import 'package:openai_dart/openai_dart.dart';

import 'package:dotenv/dotenv.dart' as dotenv;
final env = dotenv.DotEnv(includePlatformEnvironment: true)..load(['../../.env']);
final openaiApiKey = env['OPENAI_API_KEY']!;

Future<void> main() async {
  final client = OpenAIClient(apiKey: openaiApiKey);

  final res = await client.createChatCompletion(
    request: const CreateChatCompletionRequest(
      model: ChatCompletionModel.modelId('gpt-4o-mini'),
      messages: [
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(
            'what is the capital of france',
          ),
        ),
      ],
      temperature: 0.3,
    ),
  );

  print(res.choices.first.message.content);
  client.endSession();
}
