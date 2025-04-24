import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';


import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> main() async {
  final env = dotenv.DotEnv(); // Create an instance
  env.load(['../.env']); // Load .env file
  final openaiApiKey = env['OPENAI_API_KEY'];
  
  if (openaiApiKey == null) {
    print('OPENAI_API_KEY not set');
    return;
  }

  
// 1. Create a vector store and add documents to it
final vectorStore = MemoryVectorStore(embeddings: OpenAIEmbeddings(apiKey: openaiApiKey));                                                    
await vectorStore.addDocuments(
  documents: [
    Document(pageContent: 'LangChain was created by Harrison'),
    Document(pageContent: 'David ported LangChain to Dart in LangChain.dart'),
  ],
);

// 2. Define the retrieval chain
final retriever = vectorStore.asRetriever();

final setupAndRetrieval = Runnable.fromMap<String>({
  'context': retriever.pipe(
    Runnable.mapInput((docs) => docs.map((d) => d.pageContent).join('\n')),
  ),
  'question': Runnable.passthrough(),
});

// 3. Construct a RAG prompt template
final promptTemplate = ChatPromptTemplate.fromTemplates([
  (ChatMessageType.system, 'Answer the question based on only the following context:\n{context}'),
  (ChatMessageType.human, '{question}'),
]);

// 4. Define the final chain
final model = ChatOpenAI(apiKey: openaiApiKey);
const outputParser = StringOutputParser<ChatResult>();
final chain = setupAndRetrieval
    .pipe(promptTemplate)
    .pipe(model)
    .pipe(outputParser);

// 5. Run the pipeline
final res = await chain.invoke('Who created LangChain.dart?');
print(res);
// David created LangChain.dart
}
