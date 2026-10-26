import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class InternetSearchResult {
  final String title;
  final String snippet;
  final String source;
  final String? url;

  const InternetSearchResult({
    required this.title,
    required this.snippet,
    required this.source,
    this.url,
  });
}

class InternetSearchService {
  static final InternetSearchService _instance = InternetSearchService._internal();
  factory InternetSearchService() => _instance;
  InternetSearchService._internal();

  /// Performs live real-time internet search and returns an augmented prompt context.
  /// If offline or if no results are found, returns null gracefully.
  Future<String?> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    final results = <InternetSearchResult>[];
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

    try {
      // 1. DuckDuckGo Instant Answer API
      try {
        final ddgUri = Uri.parse(
          'https://api.duckduckgo.com/?q=${Uri.encodeComponent(cleanQuery)}&format=json&no_html=1&skip_disambig=1',
        );
        final ddgReq = await client.getUrl(ddgUri).timeout(const Duration(seconds: 4));
        final ddgRes = await ddgReq.close().timeout(const Duration(seconds: 4));

        if (ddgRes.statusCode == 200) {
          final body = await ddgRes.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;

          final heading = data['Heading'] as String? ?? '';
          final abstractText = data['AbstractText'] as String? ?? '';
          final answer = data['Answer'] as String? ?? '';
          final definition = data['Definition'] as String? ?? '';
          final abstractUrl = data['AbstractURL'] as String? ?? '';

          if (abstractText.isNotEmpty) {
            results.add(InternetSearchResult(
              title: heading.isNotEmpty ? heading : "DuckDuckGo Summary",
              snippet: abstractText,
              source: "DuckDuckGo",
              url: abstractUrl.isNotEmpty ? abstractUrl : null,
            ));
          } else if (answer.isNotEmpty) {
            results.add(InternetSearchResult(
              title: "Direct Answer",
              snippet: answer,
              source: "DuckDuckGo",
            ));
          } else if (definition.isNotEmpty) {
            results.add(InternetSearchResult(
              title: "Definition",
              snippet: definition,
              source: "DuckDuckGo",
            ));
          }

          // Related Topics
          final related = data['RelatedTopics'] as List<dynamic>? ?? [];
          int addedTopics = 0;
          for (final item in related) {
            if (addedTopics >= 2) break;
            if (item is Map<String, dynamic> && item.containsKey('Text')) {
              final text = item['Text'] as String? ?? '';
              if (text.isNotEmpty && !text.startsWith("http")) {
                results.add(InternetSearchResult(
                  title: "Related Info",
                  snippet: text,
                  source: "DuckDuckGo",
                  url: item['FirstURL'] as String?,
                ));
                addedTopics++;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("[InternetSearch] DuckDuckGo query error: $e");
      }

      // 2. Wikipedia Search API
      try {
        final wikiUri = Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(cleanQuery)}&format=json&utf8=&srlimit=3',
        );
        final wikiReq = await client.getUrl(wikiUri).timeout(const Duration(seconds: 4));
        final wikiRes = await wikiReq.close().timeout(const Duration(seconds: 4));

        if (wikiRes.statusCode == 200) {
          final body = await wikiRes.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          final queryObj = data['query'] as Map<String, dynamic>?;
          final searchList = queryObj?['search'] as List<dynamic>? ?? [];

          for (final item in searchList.take(2)) {
            if (item is Map<String, dynamic>) {
              final title = item['title'] as String? ?? '';
              final rawSnippet = item['snippet'] as String? ?? '';
              final cleanSnippet = rawSnippet.replaceAll(RegExp(r'<[^>]*>'), '').trim();

              // If top result, fetch comprehensive Wikipedia REST summary
              String fullSummary = cleanSnippet;
              if (results.isEmpty && title.isNotEmpty) {
                try {
                  final summaryUri = Uri.parse(
                    'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title.replaceAll(' ', '_'))}',
                  );
                  final sumReq = await client.getUrl(summaryUri).timeout(const Duration(seconds: 3));
                  final sumRes = await sumReq.close().timeout(const Duration(seconds: 3));
                  if (sumRes.statusCode == 200) {
                    final sumBody = await sumRes.transform(utf8.decoder).join();
                    final sumData = jsonDecode(sumBody) as Map<String, dynamic>;
                    final extract = sumData['extract'] as String? ?? '';
                    if (extract.isNotEmpty) {
                      fullSummary = extract;
                    }
                  }
                } catch (_) {}
              }

              if (fullSummary.isNotEmpty) {
                results.add(InternetSearchResult(
                  title: title,
                  snippet: fullSummary,
                  source: "Wikipedia",
                  url: "https://en.wikipedia.org/wiki/${Uri.encodeComponent(title.replaceAll(' ', '_'))}",
                ));
              }
            }
          }
        }
      } catch (e) {
        debugPrint("[InternetSearch] Wikipedia query error: $e");
      }
    } catch (e) {
      debugPrint("[InternetSearch] General error: $e");
    } finally {
      client.close();
    }

    if (results.isEmpty) return null;

    // Assemble structured internet context for the LLM
    final buffer = StringBuffer();
    buffer.writeln("[REAL-TIME INTERNET SEARCH FINDINGS]");
    buffer.writeln("Query: $cleanQuery");
    buffer.writeln();

    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      buffer.writeln("• [${r.source}] ${r.title}:");
      buffer.writeln("  ${r.snippet}");
      if (r.url != null) {
        buffer.writeln("  URL: ${r.url}");
      }
      buffer.writeln();
    }

    buffer.writeln("[END OF SEARCH FINDINGS]");
    buffer.writeln();
    buffer.writeln("User Prompt: $cleanQuery");
    buffer.writeln("Instructions: You have live real-time internet access. Use the up-to-date web search findings above to answer the user accurately, factually, and concisely. Mention the key findings directly.");

    return buffer.toString();
  }
}
