import 'dart:io';
import 'package:langchain/langchain.dart';
import 'package:meta/meta.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

// Environment:
final env = dotenv.DotEnv(includePlatformEnvironment: true)
  ..load(['../../.env']);
final openaiApiKey = env['OPENAI_API_KEY']!;

void main() async {
  // Initialize the LLM with tool_choice: 'auto' to ensure proper tool handling

  final llm = ChatOllama(
    defaultOptions: ChatOllamaOptions(
      model: 'llama3-groq-tool-use',
      temperature: 0,
    ),
  );

  // Create the tool handlers
  final tools = [openAPIParserTool, testValidatorTool, testCaseExecutorTool, testCaseWriterTool];

  // Create the agent with proper configuration for handling tool calls
  final agent = ToolsAgent.fromLLMAndTools(llm: llm, tools: tools);

  final executor = AgentExecutor(
    agent: agent,
    returnIntermediateSteps: true, // Include intermediate steps in the response
    maxIterations: 5, // Limit the number of iterations to prevent infinite loops
  );

  // Memory for the agent (optional)
  final memory = ConversationBufferMemory(returnMessages: true);

  final agentWithMemory = ToolsAgent.fromLLMAndTools(
    llm: llm,
    tools: tools,
    memory: memory,
  );

  final executorWithMemory = AgentExecutor(
    agent: agentWithMemory,
    maxIterations: 5, // Limit the number of iterations
    returnIntermediateSteps: true, // Include intermediate steps in the response
  );

  // Run the agent
  try {
    print('Starting API testing workflow...');
    // final result = await executor.call({
    //   'userInput': 'I want to test the API that lists all books',
    //   'openapiSpec': await File('dummy_bookstore.yaml').readAsString(),
    // });
    final openapiSpec = await File('dummy_bookstore.yaml').readAsString();
    final result = await executor.call(
      'I want to Test the book deletion endpoint using this spec:\n$openapiSpec',
    );

    print('Testing results: $result');

    // Follow-up test with memory
    print('\nRunning follow-up test with memory...');
    final followUp = await executorWithMemory.call(
      'Now test the login endpoint as well with valid and invalid credentials.',
    );
    print('Follow-up test results: $followUp');
  } catch (e) {
    print('Error: $e');
    if (e.toString().contains('tool_calls')) {
      print('\nTool call error detected. Check tool call handling.');
    }
  }
}

@immutable
class OpenAPIParserInput {
  const OpenAPIParserInput({
    required this.userInput,
    required this.openapiSpec,
  });

  final String userInput;
  final String openapiSpec;

  OpenAPIParserInput.fromJson(Map<String, dynamic> json)
    : this(
        userInput: json['userInput'] as String,
        openapiSpec: json['openapiSpec'] as String,
      );
}

final openAPIParserTool = Tool.fromFunction<OpenAPIParserInput, String>(
  name: 'openapi_parser',
  description: 'Parse a human request into a structured API format using LLM.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'userInput': {
        'type': 'string',
        'description':
            'Natural language task or intent (e.g. "Test the book deletion endpoint")',
      },
      'openapiSpec': {
        'type': 'string',
        'description': 'Raw OpenAPI specification in YAML or JSON format',
      },
    },
    'required': ['userInput', 'openapiSpec'],
  },
  func: openApiParserLLM,
  getInputFromJson: OpenAPIParserInput.fromJson,
);

// LLM-powered function to parse the input
Future<String> openApiParserLLM(OpenAPIParserInput input) async {
  final chatModel = ChatOpenAI(
    apiKey: openaiApiKey,
    defaultOptions: ChatOpenAIOptions(
      model: 'gpt-4o',
      temperature: 0,
      responseFormat: ChatOpenAIResponseFormat.jsonSchema(
        ChatOpenAIJsonSchema(
          name: 'ParsedAPIRequest',
          description:
              'Returns structured representation of an API request to be tested.',
          strict: true,
          schema: {
            'type': 'object',
            'properties': {
              'method': {
                'type': 'string',
                'description': 'HTTP method, e.g. GET, POST, PUT, DELETE',
              },
              'endpoint': {
                'type': 'string',
                'description':
                    'API endpoint path, like /login or /user/profile',
              },
              'params': {
                'type': 'array',
                'description': 'List of parameter names required for the API',
                'items': {'type': 'string'},
              },
            },
            'required': ['method', 'endpoint', 'params'],
            'additionalProperties': false,
          },
        ),
      ),
    ),
  );

  // Create parser chain
  final chain = chatModel.pipe(StringOutputParser());

  final messages = [
    ChatMessage.system(
      'You are an API interpreter. Given a natural language request and an OpenAPI spec, '
      'return a structured JSON object with method, endpoint, and optional params. '
      'Use the OpenAPI spec to resolve the endpoint path and method.',
    ),
    ChatMessage.humanText(
      'Task:\n${input.userInput}\n\nOpenAPI Spec:\n${input.openapiSpec}',
    ),
  ];

  // Invoke the chain instead of raw model
  final response = await chain.invoke(PromptValue.chat(messages));
  print(("Type of response: ${response.runtimeType}"));
  return response;
}


//  Testcase writer agent.
@immutable
class TestCaseWriterInput {
  const TestCaseWriterInput({required this.apiSpec});

  final String apiSpec;

  TestCaseWriterInput.fromJson(Map<String, dynamic> json)
      : this(apiSpec: json['apiSpec'] as String);
}

final testCaseWriterTool = Tool.fromFunction<TestCaseWriterInput, String>(
  name: 'test_case_writer',
  description: 'Generate test cases from structured API request using LLM.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'apiSpec': {
        'type': 'string',
        'description': 'Structured API request JSON output from openapi_parser',
      },
    },
    'required': ['apiSpec'],
  },
  func: generateTestCasesWithLLM,
  getInputFromJson: TestCaseWriterInput.fromJson,
);

Future<String> generateTestCasesWithLLM(TestCaseWriterInput input) async {
  final chatModel = ChatOpenAI(
    apiKey: openaiApiKey,
    defaultOptions: ChatOpenAIOptions(model: 'gpt-4o', temperature: 0),
  );

  final chain = chatModel.pipe(StringOutputParser());

  final messages = [
    ChatMessage.system(
        'You are a test case generator. Given a structured API spec in JSON format, generate appropriate test cases in JSON format.'),
    ChatMessage.humanText(input.apiSpec),
  ];

  final response = await chain.invoke(PromptValue.chat(messages));
  return response;
}


// Test case executor:
@immutable
class TestCaseExecutorInput {
  const TestCaseExecutorInput({required this.testCasesJson});

  final String testCasesJson;

  TestCaseExecutorInput.fromJson(Map<String, dynamic> json)
      : this(testCasesJson: json['testCasesJson'] as String);
}

final testCaseExecutorTool =
    Tool.fromFunction<TestCaseExecutorInput, String>(
  name: 'test_case_executor',
  description: 'Executes test cases and returns simulated results.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'testCasesJson': {
        'type': 'string',
        'description': 'The test cases in JSON format to be executed',
      },
    },
    'required': ['testCasesJson'],
  },
  func: executeTestCases,
  getInputFromJson: TestCaseExecutorInput.fromJson,
);

String executeTestCases(TestCaseExecutorInput input) {
  // Mock execution
  print('Executing test cases: ${input.testCasesJson}');
  return '''
{
  "results": [
    {"id": 1, "status": "passed"},
    {"id": 2, "status": "failed", "reason": "Missing required param"},
    {"id": 3, "status": "passed"}
  ]
}
''';
}


// Test case validator:
@immutable
class TestValidationInput {
  const TestValidationInput({required this.executionResultJson});

  final String executionResultJson;

  TestValidationInput.fromJson(Map<String, dynamic> json)
      : this(executionResultJson: json['executionResultJson'] as String);
}

final testValidatorTool = Tool.fromFunction<TestValidationInput, String>(
  name: 'test_result_validator',
  description: 'Analyze executed test results and generate validation feedback.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'executionResultJson': {
        'type': 'string',
        'description': 'The result output of executed test cases',
      },
    },
    'required': ['executionResultJson'],
  },
  func: generateValidationFeedbackLLM,
  getInputFromJson: TestValidationInput.fromJson,
);

Future<String> generateValidationFeedbackLLM(TestValidationInput input) async {
  final chatModel = ChatOpenAI(
    apiKey: openaiApiKey,
    defaultOptions: ChatOpenAIOptions(model: 'gpt-4o', temperature: 0),
  );

  final chain = chatModel.pipe(StringOutputParser());

  final messages = [
    ChatMessage.system(
        'You are a test validator. Analyze the JSON test result and provide a detailed feedback summary including number of passed/failed cases and suggestions.'),
    ChatMessage.humanText(input.executionResultJson),
  ];

  final response = await chain.invoke(PromptValue.chat(messages));
  return response;
}
