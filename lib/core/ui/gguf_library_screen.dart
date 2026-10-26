import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../models/gguf_catalog_item.dart';
import '../models/gguf_model.dart';
import '../services/chat_service.dart';
import '../services/model_manager.dart';
import 'huggingface_search_screen.dart';

class GgufLibraryScreen extends StatefulWidget {
  final Function(String url, String filename, bool isVision) onDownloadRequested;
  final VoidCallback onImportRequested;

  const GgufLibraryScreen({
    super.key,
    required this.onDownloadRequested,
    required this.onImportRequested,
  });

  @override
  State<GgufLibraryScreen> createState() => _GgufLibraryScreenState();
}

class _GgufLibraryScreenState extends State<GgufLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All"; // "All", "Compatible", "Light", "Balanced", "Flagship", "Vision", "Reasoning", "Uncensored"
  
  late DeviceRamTier _currentRamTier;

  @override
  void initState() {
    super.initState();
    _detectInitialRamTier();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _detectInitialRamTier() {
    try {
      final cores = Platform.numberOfProcessors;
      if (cores >= 8) {
        _currentRamTier = DeviceRamTier.flagship;
      } else if (cores >= 6) {
        _currentRamTier = DeviceRamTier.balanced;
      } else {
        _currentRamTier = DeviceRamTier.budget;
      }
    } catch (_) {
      _currentRamTier = DeviceRamTier.balanced;
    }
  }

  List<GgufCatalogItem> _getFilteredCatalog() {
    return kGgufCatalog.where((item) {
      // 1. Text Search Filter
      if (_searchQuery.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(_searchQuery);
        final matchesDesc = item.description.toLowerCase().contains(_searchQuery);
        final matchesQuant = item.quant.toLowerCase().contains(_searchQuery);
        final matchesFamily = item.family.name.toLowerCase().contains(_searchQuery);
        if (!matchesName && !matchesDesc && !matchesQuant && !matchesFamily) {
          return false;
        }
      }

      // 2. Category / Filter Chip
      switch (_selectedFilter) {
        case "Compatible":
          return item.isCompatibleWith(_currentRamTier);
        case "Light":
          return item.sizeGB < 1.0;
        case "Balanced":
          return item.sizeGB >= 1.0 && item.sizeGB <= 2.5;
        case "Flagship":
          return item.sizeGB > 2.5;
        case "Vision":
          return item.isVision;
        case "Reasoning":
          return item.isReasoning;
        case "Uncensored":
          return item.isUncensored;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeBridge = ThemeProviderBridge.maybeOf(context);
    final theme = themeBridge?.activeTheme ?? appThemesList.first;
    final chatService = Provider.of<ChatService>(context);
    final modelManager = Provider.of<ModelManager>(context);
    final installedModels = modelManager.models;
    final filteredList = _getFilteredCatalog();

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Model Library",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              "${installedModels.length} models installed · Offline",
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBg,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: theme.textSecondary.withOpacity(0.08),
            height: 0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Import File",
            icon: const Icon(Icons.file_upload_outlined, size: 22),
            onPressed: widget.onImportRequested,
          ),
          IconButton(
            tooltip: "Hugging Face",
            icon: const Icon(Icons.travel_explore_rounded, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HuggingFaceSearchScreen(
                    onDownloadRequested: widget.onDownloadRequested,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Phone Compatibility & RAM Tier Bar
          _buildDeviceProfileHeader(theme),

          // 2. Search Field
          _buildSearchBar(theme),

          // 3. Category Filter Chips
          _buildFilterChips(theme),

          const SizedBox(height: 6),

          // 4. Model Catalog List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildModelCard(
                        context,
                        theme,
                        item,
                        installedModels,
                        chatService,
                        modelManager,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceProfileHeader(AppThemeProfile theme) {
    String tierLabel;
    String tierDesc;
    Color tierColor;

    switch (_currentRamTier) {
      case DeviceRamTier.budget:
        tierLabel = "Budget Device (< 4 GB RAM)";
        tierDesc = "Optimal for models < 1.0 GB (SmolLM2, Qwen 0.5B, Llama 1B)";
        tierColor = const Color(0xFFFF9F0A);
        break;
      case DeviceRamTier.balanced:
        tierLabel = "Balanced Device (4 - 6 GB RAM)";
        tierDesc = "Optimal for models up to 2.5 GB (DeepSeek 1.5B, Llama 3B, Qwen 1.5B)";
        tierColor = const Color(0xFF0A84FF);
        break;
      case DeviceRamTier.flagship:
        tierLabel = "Flagship Device (8+ GB RAM)";
        tierDesc = "Optimal for all models including 8B & Vision models";
        tierColor = const Color(0xFF30D158);
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tierColor.withOpacity(0.12),
            ),
            child: Icon(Icons.memory_rounded, size: 20, color: tierColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tierLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tierDesc,
                  style: TextStyle(fontSize: 12, color: theme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<DeviceRamTier>(
            tooltip: "Change RAM Profile",
            icon: Icon(Icons.tune_rounded, size: 20, color: theme.primaryAccent),
            onSelected: (tier) {
              setState(() {
                _currentRamTier = tier;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: DeviceRamTier.budget,
                child: Text("Budget Phone (< 4 GB)"),
              ),
              const PopupMenuItem(
                value: DeviceRamTier.balanced,
                child: Text("Balanced Phone (4 - 6 GB)"),
              ),
              const PopupMenuItem(
                value: DeviceRamTier.flagship,
                child: Text("Flagship Phone (8+ GB)"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeProfile theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.textSecondary.withOpacity(0.08), width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: theme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: "Search models, architectures...",
            hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5), fontSize: 15),
            prefixIcon: Icon(Icons.search_rounded, color: theme.textSecondary.withOpacity(0.6), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Icon(Icons.cancel_rounded, color: theme.textSecondary.withOpacity(0.5), size: 16),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppThemeProfile theme) {
    final filters = [
      {"id": "All", "label": "All (${kGgufCatalog.length})"},
      {"id": "Compatible", "label": "Compatible"},
      {"id": "Light", "label": "Ultra-Light (<1 GB)"},
      {"id": "Balanced", "label": "Balanced (1-2.5 GB)"},
      {"id": "Reasoning", "label": "Reasoning"},
      {"id": "Vision", "label": "Vision"},
      {"id": "Uncensored", "label": "Uncensored"},
      {"id": "Flagship", "label": "Heavy (2.5+ GB)"},
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryAccent : theme.cardBg,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: isSelected ? theme.primaryAccent : theme.textSecondary.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Text(
                filter['label']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : theme.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context,
    AppThemeProfile theme,
    GgufCatalogItem item,
    List<GgufModel> installedModels,
    ChatService chatService,
    ModelManager modelManager,
  ) {
    final installedMatch = installedModels.where((m) => m.path.toLowerCase().endsWith(item.filename.toLowerCase())).toList();
    final isInstalled = installedMatch.isNotEmpty;
    final installedModel = isInstalled ? installedMatch.first : null;
    final isLoaded = isInstalled && chatService.activeModel?.path == installedModel?.path;

    // Compatibility calculation
    final compLevel = item.evaluateFor(_currentRamTier);
    Color compColor;
    String compText;

    switch (compLevel) {
      case CompatibilityLevel.flawless:
        compColor = const Color(0xFF30D158);
        compText = "Flawless";
        break;
      case CompatibilityLevel.good:
        compColor = const Color(0xFF0A84FF);
        compText = "Smooth";
        break;
      case CompatibilityLevel.demanding:
        compColor = const Color(0xFFFF9F0A);
        compText = "Demanding";
        break;
      case CompatibilityLevel.unsupported:
        compColor = const Color(0xFFFF453A);
        compText = "High RAM";
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLoaded
              ? theme.primaryAccent
              : theme.textSecondary.withOpacity(0.08),
          width: isLoaded ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Quant Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.quant,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Feature Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: compColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  compText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: compColor,
                  ),
                ),
              ),
              if (item.isReasoning)
                _buildMiniBadge("Reasoning", const Color(0xFFBF5AF2)),
              if (item.isVision)
                _buildMiniBadge("Vision", const Color(0xFF0A84FF)),
              if (item.isUncensored)
                _buildMiniBadge("Uncensored", const Color(0xFFFF9F0A)),
              if (item.isUltraFast)
                _buildMiniBadge("40+ t/s", const Color(0xFF30D158)),
            ],
          ),
          const SizedBox(height: 14),

          // Action Row: Size + Download / Load Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Size: ${item.sizeGB < 1.0 ? '${(item.sizeGB * 1024).toInt()} MB' : '${item.sizeGB.toStringAsFixed(2)} GB'}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
              if (isInstalled)
                Row(
                  children: [
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: isLoaded ? const Color(0xFF30D158) : theme.primaryAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: (isLoaded ? const Color(0xFF30D158) : theme.primaryAccent).withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: Icon(
                          isLoaded ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isLoaded ? "ACTIVE" : "LOAD",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          if (!isLoaded && installedModel != null) {
                            chatService.loadModel(installedModel);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Loaded ${item.name}!"),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        if (installedModel != null) {
                          await modelManager.deleteModel(installedModel);
                          setState(() {});
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFFF453A)),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      widget.onDownloadRequested(item.url, item.filename, item.isVision);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Starting download for ${item.name}..."),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "GET",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeProfile theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: theme.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            "No Results",
            style: TextStyle(fontSize: 17, color: theme.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Try searching Hugging Face for custom GGUFs",
            style: TextStyle(fontSize: 13, color: theme.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.travel_explore_rounded, size: 18),
              label: const Text("Search on Hugging Face", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HuggingFaceSearchScreen(
                      onDownloadRequested: widget.onDownloadRequested,
                    ),
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
