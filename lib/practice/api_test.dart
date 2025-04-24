import 'package:langchain/langchain.dart';
import 'package:meta/meta.dart';
import 'package:langchain_ollama/langchain_ollama.dart';
import 'dart:convert';

void main() async {
  // Initialize the LLM with tool_choice: 'auto' for proper tool handling
  final llm = ChatOllama(
    defaultOptions: ChatOllamaOptions(
      model: 'llama3-groq-tool-use',
      temperature: 0,
    ),
  );

  // Create the API testing tool handlers
  final tools = [
    openApiParserTool,
    testCaseWriterTool,
    testExecutorTool,
    testValidatorTool,
    feedbackGeneratorTool,
  ];

  // Create the agent with proper configuration for handling tool calls
  final agent = ToolsAgent.fromLLMAndTools(
    llm: llm,
    tools: tools,
  );

  final executor = AgentExecutor(
    agent: agent,
    returnIntermediateSteps: true,
    maxIterations: 10,
  );

  // Memory for the agent to maintain context across testing sessions
  final memory = ConversationBufferMemory(
    returnMessages: true,
  );

  final agentWithMemory = ToolsAgent.fromLLMAndTools(
    llm: llm,
    tools: tools,
    memory: memory,
  );

  final executorWithMemory = AgentExecutor(
    agent: agentWithMemory,
    maxIterations: 10,
    returnIntermediateSteps: true,
  );

  // Run the agent
  try {
    print('Starting API testing workflow...');
    final result = await executor.call(
      'Test the user registration API at https://api.example.com/register. ' +
      'It should validate email format and password strength.',
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



// 1. OpenAPI Parser Tool
@immutable
class OpenApiParserInput {
  const OpenApiParserInput({
    required this.apiSpec, 
    this.format = 'openapi',
  });

  final String apiSpec;
  final String format;

  OpenApiParserInput.fromJson(Map<String, dynamic> json)
    : this(
        apiSpec: json['apiSpec'] as String,
        format: (json['format'] as String?) ?? 'openapi',
      );
}

final openApiParserTool = Tool.fromFunction<OpenApiParserInput, String>(
  name: 'openapi_parser',
  description: 'Parse API specifications in different formats (OpenAPI, Swagger, etc.) into a unified format for test generation.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'apiSpec': {
        'type': 'string',
        'description': 'The API specification as a string or URL',
      },
      'format': {
        'type': 'string',
        'description': 'Format of the API specification',
        'enum': ['openapi', 'swagger', 'raml', 'url'],
      },
    },
    'required': ['apiSpec'],
  },
  func: parseApiSpec,
  getInputFromJson: OpenApiParserInput.fromJson,
);

String parseApiSpec(OpenApiParserInput input) {
  // In a real implementation, you would parse the API spec based on format
  print('Parsing API specification in ${input.format} format');
  
  // This is a simplified mock response
  final unifiedFormat = {
    'endpoints': [
      {
        'path': '/register',
        'method': 'POST',
        'description': 'User registration endpoint',
        'requestBody': {
          'required': true,
          'content': {
            'application/json': {
              'schema': {
                'properties': {
                  'email': {'type': 'string', 'format': 'email'},
                  'password': {'type': 'string', 'minLength': 8},
                  'name': {'type': 'string'},
                },
                'required': ['email', 'password']
              }
            }
          }
        },
        'responses': {
          '201': {'description': 'User created successfully'},
          '400': {'description': 'Invalid input'},
          '409': {'description': 'Email already exists'}
        }
      },
      {
        'path': '/login',
        'method': 'POST',
        'description': 'User login endpoint',
        'requestBody': {
          'required': true,
          'content': {
            'application/json': {
              'schema': {
                'properties': {
                  'email': {'type': 'string', 'format': 'email'},
                  'password': {'type': 'string'},
                },
                'required': ['email', 'password']
              }
            }
          }
        },
        'responses': {
          '200': {'description': 'Login successful'},
          '401': {'description': 'Invalid credentials'}
        }
      }
    ]
  };
  
  return jsonEncode(unifiedFormat);
}

// 2. Test Case Writer Tool
@immutable
class TestCaseWriterInput {
  const TestCaseWriterInput({
    required this.apiSpec,
    required this.endpoint,
    this.testFocus,
  });

  final String apiSpec;
  final String endpoint;
  final String? testFocus;

  TestCaseWriterInput.fromJson(Map<String, dynamic> json)
    : this(
        apiSpec: json['apiSpec'] as String,
        endpoint: json['endpoint'] as String,
        testFocus: json['testFocus'] as String?,
      );
}

final testCaseWriterTool = Tool.fromFunction<TestCaseWriterInput, String>(
  name: 'testcase_writer',
  description: 'Generate test cases for an API endpoint based on the API specification.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'apiSpec': {
        'type': 'string',
        'description': 'The parsed API specification in unified format',
      },
      'endpoint': {
        'type': 'string',
        'description': 'The specific endpoint to test (e.g., /register)',
      },
      'testFocus': {
        'type': 'string',
        'description': 'Optional focus area for tests (e.g., "input validation", "error handling")',
      },
    },
    'required': ['apiSpec', 'endpoint'],
  },
  func: writeTestCases,
  getInputFromJson: TestCaseWriterInput.fromJson,
);

String writeTestCases(TestCaseWriterInput input) {
  print('Writing test cases for ${input.endpoint}' + 
        (input.testFocus != null ? ' with focus on ${input.testFocus}' : ''));
  
  // This would typically use the parsed API spec to generate intelligent test cases
  // For this example, we're returning mock test cases
  
  final testCases = {
    'endpoint': input.endpoint,
    'testCases': []
  };
  
  if (input.endpoint == '/register') {
    testCases['testCases'] = [
      {
        'id': 'reg_valid_1',
        'name': 'Valid registration',
        'request': {
          'method': 'POST',
          'path': '/register',
          'headers': {'Content-Type': 'application/json'},
          'body': {
            'email': 'user@example.com',
            'password': 'StrongP@ss123',
            'name': 'Test User'
          }
        },
        'expectedResponse': {
          'statusCode': 201,
          'bodyContains': ['success', 'user']
        }
      },
      {
        'id': 'reg_invalid_1',
        'name': 'Invalid email format',
        'request': {
          'method': 'POST',
          'path': '/register',
          'headers': {'Content-Type': 'application/json'},
          'body': {
            'email': 'invalid-email',
            'password': 'StrongP@ss123',
            'name': 'Test User'
          }
        },
        'expectedResponse': {
          'statusCode': 400,
          'bodyContains': ['invalid', 'email']
        }
      },
      {
        'id': 'reg_invalid_2',
        'name': 'Weak password',
        'request': {
          'method': 'POST',
          'path': '/register',
          'headers': {'Content-Type': 'application/json'},
          'body': {
            'email': 'user@example.com',
            'password': '123',
            'name': 'Test User'
          }
        },
        'expectedResponse': {
          'statusCode': 400,
          'bodyContains': ['weak', 'password']
        }
      }
    ];
  } else if (input.endpoint == '/login') {
    testCases['testCases'] = [
      {
        'id': 'login_valid_1',
        'name': 'Valid login',
        'request': {
          'method': 'POST',
          'path': '/login',
          'headers': {'Content-Type': 'application/json'},
          'body': {
            'email': 'user@example.com',
            'password': 'StrongP@ss123'
          }
        },
        'expectedResponse': {
          'statusCode': 200,
          'bodyContains': ['token']
        }
      },
      {
        'id': 'login_invalid_1',
        'name': 'Invalid credentials',
        'request': {
          'method': 'POST',
          'path': '/login',
          'headers': {'Content-Type': 'application/json'},
          'body': {
            'email': 'user@example.com',
            'password': 'WrongPassword'
          }
        },
        'expectedResponse': {
          'statusCode': 401,
          'bodyContains': ['invalid', 'credentials']
        }
      }
    ];
  }
  
  return jsonEncode(testCases);
}

// 3. Test Executor Tool
@immutable
class TestExecutorInput {
  const TestExecutorInput({
    required this.testCases,
    required this.baseUrl,
    this.timeout = 30000,
  });

  final String testCases;
  final String baseUrl;
  final int timeout;

  TestExecutorInput.fromJson(Map<String, dynamic> json)
    : this(
        testCases: json['testCases'] as String,
        baseUrl: json['baseUrl'] as String,
        timeout: (json['timeout'] as int?) ?? 30000,
      );
}

final testExecutorTool = Tool.fromFunction<TestExecutorInput, String>(
  name: 'test_executor',
  description: 'Execute API test cases and return the results.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'testCases': {
        'type': 'string',
        'description': 'JSON string containing test cases to execute',
      },
      'baseUrl': {
        'type': 'string',
        'description': 'The base URL of the API (e.g., https://api.example.com)',
      },
      'timeout': {
        'type': 'integer',
        'description': 'Timeout in milliseconds for each request',
      },
    },
    'required': ['testCases', 'baseUrl'],
  },
  func: executeTests,
  getInputFromJson: TestExecutorInput.fromJson,
);

String executeTests(TestExecutorInput input) {
  print('Executing tests against ${input.baseUrl} with timeout ${input.timeout}ms');
  
  // Parse the test cases
  final testCasesMap = jsonDecode(input.testCases) as Map<String, dynamic>;
  final testCases = testCasesMap['testCases'] as List;
  final endpoint = testCasesMap['endpoint'] as String;
  
  // In a real implementation, you would make actual HTTP requests
  // For this example, we're simulating test execution with mock results
  
  final results = {
    'endpoint': endpoint,
    'baseUrl': input.baseUrl,
    'executionTime': '1.45s',
    'results': []
  };
  
  for (final testCase in testCases) {
    // Simulate test execution
    final isSuccess = testCase['id'].toString().contains('valid');
    
    (results['results'] as List<Map<String, dynamic>>).add({
      'id': testCase['id'],
      'name': testCase['name'],
      'status': isSuccess ? 'PASS' : 'FAIL',
      'responseTime': '${(100 + (50 * (isSuccess ? 1 : 2))).toString()}ms',
      'actualResponse': {
        'statusCode': isSuccess 
            ? testCase['expectedResponse']['statusCode'] 
            : (testCase['expectedResponse']['statusCode'] == 200 ? 401 : 400),
        'body': isSuccess 
            ? '{"success": true, "message": "Operation successful", "user": {"id": 123, "email": "user@example.com"}}' 
            : '{"error": true, "message": "Validation failed", "details": ["Invalid input parameter"]}'
      }
    });
  }
  
  return jsonEncode(results);
}

// 4. Test Validator Tool
@immutable
class TestValidatorInput {
  const TestValidatorInput({
    required this.testCases,
    required this.executionResults,
  });

  final String testCases;
  final String executionResults;

  TestValidatorInput.fromJson(Map<String, dynamic> json)
    : this(
        testCases: json['testCases'] as String,
        executionResults: json['executionResults'] as String,
      );
}

final testValidatorTool = Tool.fromFunction<TestValidatorInput, String>(
  name: 'test_validator',
  description: 'Validate test execution results against expected outcomes.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'testCases': {
        'type': 'string',
        'description': 'JSON string containing the original test cases with expected results',
      },
      'executionResults': {
        'type': 'string',
        'description': 'JSON string containing the actual execution results',
      },
    },
    'required': ['testCases', 'executionResults'],
  },
  func: validateTests,
  getInputFromJson: TestValidatorInput.fromJson,
);

String validateTests(TestValidatorInput input) {
  print('Validating test execution results');
  
  // Parse inputs
  final testCasesMap = jsonDecode(input.testCases) as Map<String, dynamic>;
  final executionResultsMap = jsonDecode(input.executionResults) as Map<String, dynamic>;
  
  final testCases = testCasesMap['testCases'] as List;
  final results = executionResultsMap['results'] as List;
  
  // In a real implementation, you would compare expected and actual results
  // For this example, we're using simple validation logic
  
  final validationResults = {
    'endpoint': testCasesMap['endpoint'],
    'summary': {
      'total': testCases.length,
      'passed': 0,
      'failed': 0,
      'skipped': 0,
    },
    'validationDetails': []
  };
  
  for (int i = 0; i < results.length; i++) {
    final testCase = testCases[i];
    final result = results[i];
    
    final expectedStatusCode = testCase['expectedResponse']['statusCode'];
    final actualStatusCode = result['actualResponse']['statusCode'];
    
    final expectedBodyContains = testCase['expectedResponse']['bodyContains'] as List;
    final actualBody = result['actualResponse']['body'] as String;
    
    final bodyValidation = expectedBodyContains.every(
      (term) => actualBody.toLowerCase().contains(term.toString().toLowerCase())
    );
    
    final isValid = expectedStatusCode == actualStatusCode && bodyValidation;
    
    if (isValid) {
      validationResults['summary']['passed'] = (validationResults['summary']['passed'] as int) + 1;
    } else {
      validationResults['summary']['failed'] = (validationResults['summary']['failed'] as int) + 1;
    }
    
    validationResults['validationDetails'].add({
      'id': testCase['id'],
      'name': testCase['name'],
      'valid': isValid,
      'statusCodeMatch': expectedStatusCode == actualStatusCode,
      'bodyValidation': bodyValidation,
      'details': isValid 
          ? 'All validations passed'
          : 'Failed validations: ' + 
            (expectedStatusCode != actualStatusCode 
                ? 'Status code mismatch (expected: $expectedStatusCode, got: $actualStatusCode). ' 
                : '') +
            (!bodyValidation 
                ? 'Response body does not contain all required terms.' 
                : '')
    });
  }
  
  return jsonEncode(validationResults);
}

// 5. Feedback Generator Tool
@immutable
class FeedbackGeneratorInput {
  const FeedbackGeneratorInput({
    required this.validationResults,
    this.format = 'text',
  });

  final String validationResults;
  final String format;

  FeedbackGeneratorInput.fromJson(Map<String, dynamic> json)
    : this(
        validationResults: json['validationResults'] as String,
        format: (json['format'] as String?) ?? 'text',
      );
}

final feedbackGeneratorTool = Tool.fromFunction<FeedbackGeneratorInput, String>(
  name: 'feedback_generator',
  description: 'Generate human-readable feedback from test validation results.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'validationResults': {
        'type': 'string',
        'description': 'JSON string containing the validation results',
      },
      'format': {
        'type': 'string',
        'description': 'The format of the output feedback',
        'enum': ['text', 'markdown', 'html', 'json'],
      },
    },
    'required': ['validationResults'],
  },
  func: generateFeedback,
  getInputFromJson: FeedbackGeneratorInput.fromJson,
);

String generateFeedback(FeedbackGeneratorInput input) {
  print('Generating feedback in ${input.format} format');
  
  // Parse validation results
  final validationResultsMap = jsonDecode(input.validationResults) as Map<String, dynamic>;
  final endpoint = validationResultsMap['endpoint'] as String;
  final summary = validationResultsMap['summary'] as Map<String, dynamic>;
  final details = validationResultsMap['validationDetails'] as List;
  
  // Generate feedback based on format
  if (input.format == 'markdown') {
    final stringBuffer = StringBuffer();
    
    stringBuffer.writeln('# API Testing Results for `$endpoint`');
    stringBuffer.writeln();
    stringBuffer.writeln('## Summary');
    stringBuffer.writeln('- **Total Tests:** ${summary['total']}');
    stringBuffer.writeln('- **Passed:** ${summary['passed']}');
    stringBuffer.writeln('- **Failed:** ${summary['failed']}');
    stringBuffer.writeln('- **Skipped:** ${summary['skipped']}');
    stringBuffer.writeln();
    
    stringBuffer.writeln('## Test Details');
    for (final test in details) {
      stringBuffer.writeln('### ${test['name']} (ID: ${test['id']})');
      stringBuffer.writeln('- **Status:** ${test['valid'] ? '✅ PASSED' : '❌ FAILED'}');
      stringBuffer.writeln('- **Details:** ${test['details']}');
      stringBuffer.writeln();
    }
    
    if (summary['failed'] > 0) {
      stringBuffer.writeln('## Recommendations');
      stringBuffer.writeln('1. Review failed tests and address validation issues');
      stringBuffer.writeln('2. Consider adding more edge cases to your test suite');
      stringBuffer.writeln('3. Rerun tests after making necessary changes');
    }
    
    return stringBuffer.toString();
  } else if (input.format == 'text') {
    final stringBuffer = StringBuffer();
    
    stringBuffer.writeln('API Testing Results for $endpoint');
    stringBuffer.writeln('================================');
    stringBuffer.writeln();
    stringBuffer.writeln('Summary:');
    stringBuffer.writeln('  Total Tests: ${summary['total']}');
    stringBuffer.writeln('  Passed: ${summary['passed']}');
    stringBuffer.writeln('  Failed: ${summary['failed']}');
    stringBuffer.writeln('  Skipped: ${summary['skipped']}');
    stringBuffer.writeln();
    
    stringBuffer.writeln('Test Details:');
    for (final test in details) {
      stringBuffer.writeln('  ${test['name']} (ID: ${test['id']})');
      stringBuffer.writeln('    Status: ${test['valid'] ? 'PASSED' : 'FAILED'}');
      stringBuffer.writeln('    Details: ${test['details']}');
      stringBuffer.writeln();
    }
    
    return stringBuffer.toString();
  } else {
    // Return the original JSON for 'json' format or if format not supported
    return input.validationResults;
  }
}