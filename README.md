# API Testing Agent

## Installation

```bash
flutter pub get
```
- Note: you will need to install ollama and set it up in your system.
  - after installing ollama, you will need pull llama3.2 model.
    ```bash
    ollama pull llama3.2
    ollama pull llama3-groq-tool-use
    ```


- You will also need to set up your OpenAI API key in the `.env` file. 
- [Temporarily as ollama was slow in some cases] 



## In lib/practice folder there are all poc's made with langchainnn dart,
- mainly you can go through : 
 1. agent_with_custom_tools_1.dart
 2. agent_with_custom_tools_2.dart
 3. chaining_multiple_chains.dart
 4. api_test_poc.dart

- fourth one is related to our **API testing AGent**, I'm working on that.