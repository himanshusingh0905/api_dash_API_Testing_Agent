

import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:meta/meta.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:langchain_community/langchain_community.dart';
import 'package:langchain_ollama/langchain_ollama.dart';

// Environment:
final env = dotenv.DotEnv(includePlatformEnvironment: true)..load(['../../.env']);
final openaiApiKey = env['OPENAI_API_KEY']!;



@immutable
class SearchInput {
  const SearchInput({
    required this.query,
    required this.n,
  });

  final String query;
  final int n;

  SearchInput.fromJson(final Map<String, dynamic> json)
      : this(
    query: json['query'] as String,
    n: json['n'] as int,
  );
}

final searchTool = Tool.fromFunction<SearchInput, String>(
  name: 'search',
  description: 'Tool for searching the web.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'The query to search for',
      },
      'n': {
        'type': 'integer',
        'description': 'The number of results to return',
      },
    },
    'required': ['query'],
  },
  func: callYourSearchFunction,
  getInputFromJson: SearchInput.fromJson,
);

String callYourSearchFunction(final SearchInput input) {
    final n = input.n;
    final res = List<String>.generate(
      n,
      (i) => 'Result ${i + 1}: ${String.fromCharCode(65 + i) * 3}',
    );
    return 'Results:\n${res.join('\n')}';
}


void main() async {
  final llm = ChatOllama(
    defaultOptions: ChatOllamaOptions(
      model: 'llama3-groq-tool-use',
      temperature: 0,
    ),
  );

  final memory = ConversationBufferMemory(returnMessages: true);
  final agent = ToolsAgent.fromLLMAndTools(
    llm: llm,
    tools: [searchTool],
    memory: memory,
  );

  final executor = AgentExecutor(agent: agent);

  final res1 = await executor.run(
    'What is the current weather in New York City?',
  );
  print(res1);
  // Here are the top 3 cat names I found: AAA, BBB, and CCC.
}
