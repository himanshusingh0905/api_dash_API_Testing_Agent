// Let's create a chain first :
// 1. In first chain we will ask for a joke on a topic.
// 2. we'll ask if it this joke is funny or not?
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

// Environment:
final env = dotenv.DotEnv(includePlatformEnvironment: true)
  ..load(['../../.env']);
final openaiApiKey = env['OPENAI_API_KEY']!;

void main() async {
  final llm = ChatOpenAI(apiKey: openaiApiKey);
  // Prompt 1
  final prompt1 = ChatPromptTemplate.fromTemplate(
    "Tell me a joke about {topic}",
  );

  // Prompt 2
  final prompt2 = ChatPromptTemplate.fromTemplate("Is this joke funny? {joke}");

  final chain1 = prompt1 | llm;
  final chain2 = Runnable.fromMap({'joke': chain1}) | prompt2 | llm | const StringOutputParser();

  // Result
  final result = await chain2.invoke({'topic': 'ice cream'});
  print(result);
}
