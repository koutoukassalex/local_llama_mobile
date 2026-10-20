import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HuggingFaceSearchScreen extends StatefulWidget {
  final Function(String url, String filename, bool isVision) onDownloadRequested;

  const HuggingFaceSearchScreen({super.key, required this.onDownloadRequested});

  @override
  State<HuggingFaceSearchScreen> createState() => _HuggingFaceSearchScreenState();
}

class _HuggingFaceSearchScreenState extends State<HuggingFaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String _error = '';

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = '';
      _searchResults = [];
    });

    try {
      final client = HttpClient();
      final url = Uri.parse('https://huggingface.co/api/models?search=gguf+${Uri.encodeComponent(query)}&limit=20');
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as List<dynamic>;
        setState(() {
          _searchResults = data;
        });
      } else {
        setState(() {
          _error = 'Failed to load results (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _openRepo(String modelId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HuggingFaceRepoScreen(
          modelId: modelId,
          onDownloadRequested: widget.onDownloadRequested,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final textSecondary = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    const primaryAccent = Color(0xFF0A84FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Hugging Face',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.4),
        ),
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: textSecondary.withOpacity(0.15), height: 0.5),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // iOS Search Bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: textSecondary.withOpacity(0.12), width: 0.5),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search GGUF models (phi-4, mistral, llama)...',
                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded, color: textSecondary.withOpacity(0.6), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                child: Icon(Icons.cancel_rounded, color: textSecondary.withOpacity(0.5), size: 16),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: _performSearch,
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(height: 8),

                // Note callout
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F0A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFFF9F0A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Models > 4 GB require 8+ GB RAM to run reliably.",
                          style: TextStyle(fontSize: 12, color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isSearching
                ? const Center(child: CupertinoActivityIndicator(radius: 14))
                : _error.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error, style: const TextStyle(color: Color(0xFFFF453A), fontSize: 15), textAlign: TextAlign.center),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'Search for open-source GGUF weights',
                              style: TextStyle(color: textSecondary, fontSize: 15),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final repo = _searchResults[index];
                              final modelId = repo['modelId'] ?? 'Unknown';
                              final downloads = repo['downloads'] ?? 0;

                              return Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: textSecondary.withOpacity(0.08), width: 0.5),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primaryAccent.withOpacity(0.12),
                                    ),
                                    child: const Icon(Icons.hub_rounded, size: 18, color: primaryAccent),
                                  ),
                                  title: Text(
                                    modelId,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '$downloads downloads',
                                      style: TextStyle(fontSize: 13, color: textSecondary),
                                    ),
                                  ),
                                  trailing: Icon(Icons.chevron_right_rounded, color: textSecondary.withOpacity(0.6), size: 20),
                                  onTap: () => _openRepo(modelId),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class HuggingFaceRepoScreen extends StatefulWidget {
  final String modelId;
  final Function(String url, String filename, bool isVision) onDownloadRequested;

  const HuggingFaceRepoScreen({
    super.key,
    required this.modelId,
    required this.onDownloadRequested,
  });

  @override
  State<HuggingFaceRepoScreen> createState() => _HuggingFaceRepoScreenState();
}

class _HuggingFaceRepoScreenState extends State<HuggingFaceRepoScreen> {
  List<dynamic> _files = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchTree();
  }

  Future<void> _fetchTree() async {
    try {
      final client = HttpClient();
      final url = Uri.parse('https://huggingface.co/api/models/${widget.modelId}/tree/main');
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as List<dynamic>;

        final ggufFiles = data.where((file) {
          final path = (file['path'] as String? ?? '').toLowerCase();
          return path.endsWith('.gguf');
        }).toList();

        setState(() {
          _files = ggufFiles;
        });
      } else {
        setState(() {
          _error = 'Failed to load repository files (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading repository: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _askVisionAndDownload(String path) async {
    final isVision = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Vision Capability'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Does this model support vision and image uploads?\n\nIf you are uncertain, select "Standard LLM".'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Standard LLM'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vision Model'),
            ),
          ],
        );
      },
    );

    if (isVision != null) {
      final downloadUrl = 'https://huggingface.co/${widget.modelId}/resolve/main/$path';
      widget.onDownloadRequested(downloadUrl, path, isVision);

      if (mounted) {
        Navigator.pop(context); // close repo screen
        Navigator.pop(context); // close search screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final textSecondary = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    const primaryAccent = Color(0xFF0A84FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.modelId,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: textSecondary.withOpacity(0.15), height: 0.5),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error, style: const TextStyle(color: Color(0xFFFF453A), fontSize: 15), textAlign: TextAlign.center),
                  ),
                )
              : _files.isEmpty
                  ? Center(
                      child: Text('No .gguf files found in this repository.', style: TextStyle(color: textSecondary, fontSize: 15)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _files.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        final filename = file['path'] as String? ?? 'model.gguf';
                        final size = file['size'] as int? ?? 0;
                        final sizeGB = (size / (1024 * 1024 * 1024)).toStringAsFixed(2);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: textSecondary.withOpacity(0.08), width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryAccent.withOpacity(0.12),
                                ),
                                child: const Icon(Icons.description_outlined, size: 18, color: primaryAccent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      filename,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$sizeGB GB',
                                      style: TextStyle(fontSize: 13, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () => _askVisionAndDownload(filename),
                                  child: const Text('GET', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
