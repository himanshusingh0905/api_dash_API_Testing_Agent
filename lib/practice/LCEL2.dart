

void processPromptValue(Map<String, dynamic> promptValueMap) {
  // 'void' means this function doesn't return any specific value.
  // 'processPromptValue' is the name of the function.
  // 'Map<String, dynamic>' defines the type of the input parameter. It's a map (like a dictionary)
  // where keys are Strings and values can be of any type ('dynamic').
  // 'promptValueMap' is the name of the input parameter that will hold the map you pass to this function.
  final String? topic = promptValueMap['topic'] as String?;
  // 'final' means the variable 'topic' can only be assigned a value once.
  // 'String?' declares that 'topic' will hold a String value, but it can also be null (indicated by '?').
  // 'promptValueMap['topic']' accesses the value associated with the key 'topic' in the input map.
  // 'as String?' attempts to cast the retrieved value to a String. If it's not a String or is null,
  // 'topic' will hold that value (or null).

  if (topic != null) {
    // 'if (topic != null)' checks if the 'topic' variable has a non-null value.
    print('Topic: $topic');
    // 'print()' is a built-in function that displays output to the console.
    // ''Topic: $topic'' is a String literal. The '$' symbol is used for string interpolation,
    // meaning the value of the 'topic' variable will be inserted into the string.
    // // You can perform other operations with the topic here
    // This is a single-line comment. It indicates where you would add more code
    // that uses the 'topic' value.
  }

  final List<Map<String, dynamic>>? messagesList = promptValueMap['messages'] as List<Map<String, dynamic>>?;
  // 'final' - the variable 'messagesList' can only be assigned once.
  // 'List<Map<String, dynamic>>?' declares that 'messagesList' will hold a list of maps.
  // Each map in the list will have String keys and values of any type ('dynamic').
  // The '?' indicates that 'messagesList' can also be null.
  // 'promptValueMap['messages']' accesses the value associated with the key 'messages' in the input map.
  // 'as List<Map<String, dynamic>>?' attempts to cast the retrieved value to a list of maps with the specified structure.

  if (messagesList != null) {
    // Checks if the 'messagesList' variable has a non-null value.
    print('Messages:');
    // Prints the string "Messages:" to the console.
    for (final message in messagesList) {
      // 'for (final message in messagesList)' is a 'for-in' loop.
      // It iterates over each element in the 'messagesList'.
      // In each iteration, the current element is assigned to the 'message' variable.
      // 'final message' declares that the 'message' variable within the loop can only be assigned once per iteration.
      print(message);
      // Prints the current 'message' (which is a map) to the console.
      // // Process each message as needed
      // Another single-line comment indicating where you would add code to process each individual message.
    }
  }

  final String? stringRepresentation = promptValueMap['string'] as String?;
  // 'final' - the variable 'stringRepresentation' can only be assigned once.
  // 'String?' declares that 'stringRepresentation' will hold a String value, or null.
  // 'promptValueMap['string']' accesses the value associated with the key 'string' in the input map.
  // 'as String?' attempts to cast the retrieved value to a String.

  if (stringRepresentation != null) {
    // Checks if the 'stringRepresentation' variable has a non-null value.
    print('String Representation: $stringRepresentation');
    // Prints the string "String Representation:" followed by the value of 'stringRepresentation'.
    // // Use the string representation
    // A comment indicating where you would add code to use the string representation.
  }
}

void main() async {
  // 'void' - this function doesn't return any specific value.
  // 'main()' is a special function in Dart. It's the entry point of your program.
  // 'async' keyword indicates that this function might perform asynchronous operations (though it doesn't in this specific example).

  // Simulate the promptValue and its properties
  // This is a comment explaining the following code block.
  final promptValue = {
    // 'final' - the variable 'promptValue' can only be assigned once.
    // '{ ... }' denotes a map literal. It's used to create a map directly in the code.
    'topic': 'ice cream',
    // 'topic' is a String literal, acting as a key in the map.
    // ':' separates the key from its value.
    // 'ice cream' is a String literal, the value associated with the 'topic' key.
    'messages': [
      // 'messages' is a String literal, another key in the map.
      // '[]' denotes a list literal. It's used to create a list directly in the code.
      {
        // '{ ... }' denotes a map literal. This is the first element in the 'messages' list.
        'content': {
          // 'content' is a String literal, a key within the inner map.
          'text': 'Tell me a joke about ice cream',
          // 'text' is a String literal, another key within the inner map.
          // 'Tell me a joke about ice cream' is the String value associated with the 'text' key.
        },
      },
    ],
    'string': "{ topic: 'ice cream' }",
    // 'string' is a String literal, a key in the main map.
    // "{ topic: 'ice cream' }" is a String literal, the value associated with the 'string' key.
  };

  processPromptValue(promptValue);
  // This line calls the 'processPromptValue' function, passing the 'promptValue' map as an argument.
}