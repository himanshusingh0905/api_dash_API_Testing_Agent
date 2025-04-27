// import 'package:langchain/langchain.dart';
// import 'package:langchain_openai/langchain_openai.dart';
// import 'package:meta/meta.dart';
// import 'package:dotenv/dotenv.dart' as dotenv;
// import 'package:langchain_community/langchain_community.dart';
// import 'package:langchain_ollama/langchain_ollama.dart';

// // Environment:
// final env = dotenv.DotEnv(includePlatformEnvironment: true)
//   ..load(['../../.env']);
// final openaiApiKey = env['OPENAI_API_KEY']!;

// @immutable
// class SearchInput {
//   const SearchInput({required this.query, required this.n});

//   final String query;
//   final int n;

//   SearchInput.fromJson(final Map<String, dynamic> json)
//     : this(query: json['query'] as String, n: json['n'] as int);
// }

// final searchTool = Tool.fromFunction<SearchInput, String>(
//   name: 'search',
//   description: 'Tool for searching the web.',
//   inputJsonSchema: {
//     'type': 'object',
//     'properties': {
//       'query': {'type': 'string', 'description': 'The query to search for'},
//       'n': {
//         'type': 'integer',
//         'description': 'The number of results to return',
//       },
//     },
//     'required': ['query'],
//   },
//   func: callYourSearchFunction,
//   getInputFromJson: SearchInput.fromJson,
// );

// String callYourSearchFunction(final SearchInput input) {
//   final n = input.n;
//   final res = List<String>.generate(
//     n,
//     (i) => 'Result ${i + 1}: ${String.fromCharCode(65 + i) * 3}',
//   );
//   return 'Results:\n${res.join('\n')}';
// }

// void main() async {
//   final llm = ChatOllama(
//     defaultOptions: ChatOllamaOptions(
//       model: 'llama3-groq-tool-use',
//       temperature: 0,
//     ),
//   );

//   final memory = ConversationBufferMemory(returnMessages: true);
//   final agent = ToolsAgent.fromLLMAndTools(
//     llm: llm,
//     tools: [searchTool],
//     memory: memory,
//   );

//   final executor = AgentExecutor(agent: agent);

//   final res1 = await executor.run(
//     'What is the capital of france?',
//   );
//   print(res1);
// }


import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:meta/meta.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:langchain_community/langchain_community.dart';
import 'package:langchain_ollama/langchain_ollama.dart';

final env = dotenv.DotEnv(includePlatformEnvironment: true)..load(['../../.env']);
final openaiApiKey = env['OPENAI_API_KEY']!; 

// 1. Tool Definition ========================================
@immutable
class SearchInput {
  const SearchInput({required this.query, required this.n});

  final String query;
  final int n;

  SearchInput.fromJson(final Map<String, dynamic> json)
    : this(query: json['query'] as String, n: json['n'] as int);
}

final searchTool = Tool.fromFunction<SearchInput, String>(
  name: 'search',
  description: 'Tool for searching the web. Use when you need current or specific information.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'query': {'type': 'string', 'description': 'The search query'},
      'n': {
        'type': 'integer',
        'description': 'Number of results (default: 3)',
        'default': 3
      },
    },
    'required': ['query'],
  },
  func: callYourSearchFunction,
  getInputFromJson: SearchInput.fromJson,
);

String callYourSearchFunction(final SearchInput input) {
  // Mock search results - replace with real API calls
  final n = input.n.clamp(1, 5); // Safety limit
  final res = List<String>.generate(
    n,
    (i) => 'Result ${i+1}: ${input.query} ${String.fromCharCode(65+i)}',
  );
  return res.join('\n');
}

// 2. Custom Prompt Template ================================
final promptTemplate = ChatPromptTemplate.fromTemplate('''
You are a helpful assistant. Follow these rules:
1. Answer general questions directly using your knowledge
2. Only use tools for current info or specific searches
3. Be concise but helpful

Question: {input}

Think step by step. If needed, use tools.{agent_scratchpad}''');

// 3. Main Execution ========================================
void main() async {
  final llm = ChatOllama(
    defaultOptions: ChatOllamaOptions(
      model: 'llama3-groq-tool-use',
      temperature: 0,
      stop: ['Observation:'], // Critical for tool handling
    ),
  );

  final memory = ConversationBufferMemory(returnMessages: true);
  
  final agent = ToolsAgent.fromLLMAndTools(
    llm: llm,
    tools: [searchTool],
    memory: memory,
  );

  final executor = AgentExecutor(agent: agent);

  final res3 = await executor.run('Who won the 2020 US presidential election?');
  print('Fact-based: $res3'); // Should answer directly but can use tool if model is unsure

  final res4 = await executor.run('How fish inhales?');
  print('fact-based: $res4'); // Should use search tool
}
