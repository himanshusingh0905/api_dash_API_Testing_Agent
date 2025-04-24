import 'package:langchain/langchain.dart';
import 'package:meta/meta.dart';
import 'package:langchain_ollama/langchain_ollama.dart';


void main() async {
  // Initialize the LLM with tool_choice: 'auto' to ensure proper tool handling

  final llm = ChatOllama(
    defaultOptions: ChatOllamaOptions(
      model: 'llama3-groq-tool-use',
      temperature: 0,
    ),
  );

  // Create the tool handlers
  final tools = [weatherTool, stockPriceTool, currencyConversionTool];

  // Create the agent with proper configuration for handling tool calls
  final agent = ToolsAgent.fromLLMAndTools(
    llm: llm,
    tools: tools,
  );

  final executor = AgentExecutor(
    agent: agent,
    returnIntermediateSteps: true, // Include intermediate steps in the response
    maxIterations:5, // Limit the number of iterations to prevent infinite loops
  );

  // Memory for the agent (optional)
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
    maxIterations: 5, // Limit the number of iterations
    returnIntermediateSteps: true, // Include intermediate steps in the response
  );

  // Run the agent
  try {
    print('Running agent query about weather and stock price...');
    final result = await executor.call(
      'What\'s the weather like in London, and what\'s the current price of Apple stock?',
    );
    print('Result: $result');

    // Using the agent with memory for follow-up questions
    print('\nRunning agent with memory for currency conversion...');
    final followUp = await executorWithMemory.call('Now convert 100 USD to GBP');
    print('Follow-up: $followUp');
  } catch (e) {
    print('Error: $e');
    // Add more detailed error handling if needed
    if (e.toString().contains('tool_calls')) {
      print(
        '\nTool call error detected. Check that each tool call is being properly handled.',
      );
    }
  }
}

// Weather Tool
@immutable
class WeatherInput {
  const WeatherInput({required this.location, this.units = 'celsius'});

  final String location;
  final String units;

  WeatherInput.fromJson(Map<String, dynamic> json)
    : this(
        location: json['location'] as String,
        units: (json['units'] as String?) ?? 'celsius',
      );
}

final weatherTool = Tool.fromFunction<WeatherInput, String>(
  name: 'weather_lookup',
  description: 'Get current weather information for a specific location.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'location': {
        'type': 'string',
        'description': 'The city or location to get weather information for',
      },
      'units': {
        'type': 'string',
        'description': 'Temperature units: celsius or fahrenheit',
        'enum': ['celsius', 'fahrenheit'],
      },
    },
    'required': ['location'],
  },
  func: getWeatherData,
  getInputFromJson: WeatherInput.fromJson,
);

String getWeatherData(WeatherInput input) {
  // In a real implementation, you would call a weather API here
  final location = input.location;
  final units = input.units;

  print('Weather tool called for location: $location, units: $units');

  return '''
    Weather for $location:
    Temperature: ${units == 'celsius' ? '22°C' : '71.6°F'}
    Condition: Partly Cloudy
    Humidity: 65%
    Wind: 12 km/h
      ''';
    }

// Stock Price Tool
@immutable
class StockPriceInput {
  const StockPriceInput({required this.symbol});

  final String symbol;

  StockPriceInput.fromJson(Map<String, dynamic> json)
    : this(symbol: json['symbol'] as String);
}

final stockPriceTool = Tool.fromFunction<StockPriceInput, String>(
  name: 'stock_price',
  description: 'Get the current price of a stock by ticker symbol.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'symbol': {
        'type': 'string',
        'description': 'The stock ticker symbol (e.g., AAPL for Apple)',
      },
    },
    'required': ['symbol'],
  },
  func: getStockPrice,
  getInputFromJson: StockPriceInput.fromJson,
);

String getStockPrice(StockPriceInput input) {
  // In a real implementation, you would call a stock API here
  final Map<String, double> mockPrices = {
    'AAPL': 178.42,
    'GOOGL': 142.53,
    'MSFT': 337.89,
    'AMZN': 180.75,
  };

  final symbol = input.symbol.toUpperCase();
  final price = mockPrices[symbol] ?? 0.0;

  print('Stock price tool called for symbol: $symbol');

  if (price == 0.0) {
    return 'Stock price for $symbol not found.';
  }

  return 'Current price of $symbol: \$${price.toStringAsFixed(2)}';
}

// Currency Conversion Tool
@immutable
class CurrencyConversionInput {
  const CurrencyConversionInput({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
  });

  final double amount;
  final String fromCurrency;
  final String toCurrency;

  CurrencyConversionInput.fromJson(Map<String, dynamic> json)
    : this(
        amount:
            (json['amount'] is int)
                ? (json['amount'] as int).toDouble()
                : json['amount'] as double,
        fromCurrency: json['fromCurrency'] as String,
        toCurrency: json['toCurrency'] as String,
      );
}

final currencyConversionTool =
    Tool.fromFunction<CurrencyConversionInput, String>(
      name: 'currency_converter',
      description: 'Convert an amount from one currency to another.',
      inputJsonSchema: {
        'type': 'object',
        'properties': {
          'amount': {'type': 'number', 'description': 'The amount to convert'},
          'fromCurrency': {
            'type': 'string',
            'description': 'The source currency code (e.g., USD, EUR, GBP)',
          },
          'toCurrency': {
            'type': 'string',
            'description': 'The target currency code (e.g., USD, EUR, GBP)',
          },
        },
        'required': ['amount', 'fromCurrency', 'toCurrency'],
      },
      func: convertCurrency,
      getInputFromJson: CurrencyConversionInput.fromJson,
    );

String convertCurrency(CurrencyConversionInput input) {
  // In a real implementation, you would call a currency API here
  final Map<String, Map<String, double>> rates = {
    'USD': {'EUR': 0.92, 'GBP': 0.79, 'JPY': 150.52, 'CAD': 1.37},
    'EUR': {'USD': 1.09, 'GBP': 0.86, 'JPY': 163.84, 'CAD': 1.49},
    'GBP': {'USD': 1.27, 'EUR': 1.16, 'JPY': 190.53, 'CAD': 1.74},
  };

  final from = input.fromCurrency.toUpperCase();
  final to = input.toCurrency.toUpperCase();

  print('Currency conversion tool called: ${input.amount} $from to $to');

  if (!rates.containsKey(from) || !rates[from]!.containsKey(to)) {
    if (from == to) {
      return '${input.amount} $from = ${input.amount} $to';
    }
    return 'Conversion rate not available for $from to $to.';
  }

  final convertedAmount = input.amount * rates[from]![to]!;

  return '${input.amount} $from = ${convertedAmount.toStringAsFixed(2)} $to';
}
