

import 'package:langchain/langchain.dart'; // contains ChatPromptTemplate
import 'package:langchain_openai/langchain_openai.dart'; // contains ChatOpenAI


import 'package:dotenv/dotenv.dart' as dotenv;
final env = dotenv.DotEnv(includePlatformEnvironment: true)..load(['../../.env']);
final openaiApiKey = env['OPENAI_API_KEY']!;

//  Chaining of model + prompt + output parser
Future<void> main() async {
// 1. llm
  final model = ChatOpenAI(apiKey: openaiApiKey);

  // 2. prompt
  final prompt = ChatPromptTemplate.fromTemplate('What is the behaviour of {animal}');
  
  // 3. output parser
  const outputParser = StringOutputParser<ChatResult>();

  final chain = prompt | model | outputParser;
  final result = await chain.invoke({'animal': 'cat'});
print(result);
}

