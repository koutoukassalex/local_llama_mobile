import 'dart:convert';
import 'dart:io';
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
          _error = 'Failed to load results. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Search error: $e';
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
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Hugging Face'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for GGUF models (e.g., phi-2, mistral)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _performSearch(_searchController.text),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.background,
                  ),
                  onSubmitted: _performSearch,
                ),
                const SizedBox(height: 8),
                Text(
                  "Warning: Large models (>4GB) may crash mobile devices. Make sure your device has enough RAM.",
                  style: TextStyle(fontSize: 11, color: theme.secondary, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                    : _searchResults.isEmpty
                        ? Center(child: Text('No results', style: TextStyle(color: theme.onSurface.withOpacity(0.5))))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final repo = _searchResults[index];
                              return ListTile(
                                leading: const Icon(Icons.folder_shared),
                                title: Text(repo['modelId'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Downloads: ${repo['downloads'] ?? 0}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openRepo(repo['modelId']),
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
        
        // Filter only gguf files
        final ggufFiles = data.where((file) {
          final path = file['path'] as String;
          return path.toLowerCase().endsWith('.gguf');
        }).toList();

        setState(() {
          _files = ggufFiles;
        });
      } else {
        setState(() {
          _error = 'Failed to load repository tree. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading files: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _askVisionAndDownload(String path) async {
    final isVision = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vision Support'),
          content: const Text('Does this model support Image Uploads (Vision)?\n\nIf you are not sure, it is usually safe to select No.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (isVision != null) {
      final downloadUrl = 'https://huggingface.co/${widget.modelId}/resolve/main/$path';
      widget.onDownloadRequested(downloadUrl, path, isVision);
      
      // Close screens to go back to main screen
      if (mounted) {
        Navigator.pop(context); // close repo screen
        Navigator.pop(context); // close search screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modelId, style: const TextStyle(fontSize: 14)),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : _files.isEmpty
                  ? Center(child: Text('No .gguf files found in this repository.', style: TextStyle(color: theme.onSurface.withOpacity(0.5))))
                  : ListView.builder(
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        final filename = file['path'] as String;
                        final size = file['size'] as int;
                        final sizeGB = (size / (1024 * 1024 * 1024)).toStringAsFixed(2);

                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: Text(filename, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('Size: $sizeGB GB'),
                          trailing: IconButton(
                            icon: Icon(Icons.download, color: theme.primary),
                            onPressed: () => _askVisionAndDownload(filename),
                          ),
                          onTap: () => _askVisionAndDownload(filename),
                        );
                      },
                    ),
    );
  }
}
