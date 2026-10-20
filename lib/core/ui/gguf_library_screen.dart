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
    final cores = Platform.numberOfProcessors;
    if (cores >= 8) {
      _currentRamTier = DeviceRamTier.flagship;
    } else if (cores >= 6) {
      _currentRamTier = DeviceRamTier.balanced;
    } else {
      _currentRamTier = DeviceRamTier.budget;
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
    final theme = ThemeProviderBridge.of(context).activeTheme;
    final chatService = Provider.of<ChatService>(context);
    final modelManager = Provider.of<ModelManager>(context);
    final installedModels = modelManager.installedModels;
    final filteredList = _getFilteredCatalog();

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "GGUF MODEL LIBRARY",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            Text(
              "${installedModels.length} models installed · Offline on-device",
              style: TextStyle(fontSize: 10, color: theme.textSecondary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: theme.appBarBg,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Import local GGUF file",
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: widget.onImportRequested,
          ),
          IconButton(
            tooltip: "Search Hugging Face",
            icon: const Icon(Icons.travel_explore_rounded),
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

          // 4. Model Catalog List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        tierColor = Colors.amber;
        break;
      case DeviceRamTier.balanced:
        tierLabel = "Balanced Device (4 - 6 GB RAM)";
        tierDesc = "Optimal for models up to 2.5 GB (DeepSeek 1.5B, Llama 3B, Qwen 1.5B)";
        tierColor = Colors.cyanAccent;
        break;
      case DeviceRamTier.flagship:
        tierLabel = "Flagship Device (8+ GB RAM)";
        tierDesc = "Optimal for all models including 8B & 11B Vision models";
        tierColor = Colors.greenAccent[400]!;
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierColor.withOpacity(0.12),
                ),
                child: Icon(Icons.memory_rounded, size: 16, color: tierColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "DEVICE PROFILE: ",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: theme.textSecondary,
                          ),
                        ),
                        Text(
                          tierLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: tierColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tierDesc,
                      style: TextStyle(fontSize: 10, color: theme.textSecondary.withOpacity(0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<DeviceRamTier>(
                tooltip: "Change Phone RAM Tier",
                icon: Icon(Icons.tune_rounded, size: 18, color: theme.primaryAccent),
                onSelected: (tier) {
                  setState(() {
                    _currentRamTier = tier;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: DeviceRamTier.budget,
                    child: Text("📱 Budget Phone (< 4 GB RAM)"),
                  ),
                  const PopupMenuItem(
                    value: DeviceRamTier.balanced,
                    child: Text("📱 Balanced Phone (4 - 6 GB RAM)"),
                  ),
                  const PopupMenuItem(
                    value: DeviceRamTier.flagship,
                    child: Text("⚡ Flagship Phone (8+ GB RAM)"),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeProfile theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: theme.cardBg.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.primaryAccent.withOpacity(0.12)),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: theme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Search models, architectures (Qwen, Llama, DeepSeek)...",
            hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.6), fontSize: 12),
            prefixIcon: Icon(Icons.search_rounded, color: theme.primaryAccent, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: theme.textSecondary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppThemeProfile theme) {
    final filters = [
      {"id": "All", "label": "All (${kGgufCatalog.length})"},
      {"id": "Compatible", "label": " Compatible with Phone"},
      {"id": "Light", "label": "⚡ Ultra-Light (<1 GB)"},
      {"id": "Balanced", "label": " Balanced (1-2.5 GB)"},
      {"id": "Reasoning", "label": "🧠 DeepSeek Reasoning"},
      {"id": "Vision", "label": " Vision Multimodal"},
      {"id": "Uncensored", "label": "🔓 Uncensored"},
      {"id": "Flagship", "label": " Heavy (2.5+ GB)"},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['id'];
          return ChoiceChip(
            label: Text(
              filter['label']!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : theme.textPrimary,
              ),
            ),
            selected: isSelected,
            selectedColor: theme.primaryAccent,
            backgroundColor: theme.cardBg.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(
              color: isSelected ? theme.primaryAccent : theme.primaryAccent.withOpacity(0.1),
            ),
            onSelected: (val) {
              setState(() {
                _selectedFilter = filter['id']!;
              });
            },
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
    final installedMatch = installedModels.where((m) => m.path.endsWith(item.filename)).toList();
    final isInstalled = installedMatch.isNotEmpty;
    final installedModel = isInstalled ? installedMatch.first : null;
    final isLoaded = isInstalled && chatService.activeModel?.path == installedModel?.path;

    // Compatibility calculation
    final compLevel = item.evaluateFor(_currentRamTier);
    Color compColor;
    String compText;
    IconData compIcon;

    switch (compLevel) {
      case CompatibilityLevel.flawless:
        compColor = Colors.greenAccent[400]!;
        compText = "Flawless on Phone";
        compIcon = Icons.bolt_rounded;
        break;
      case CompatibilityLevel.good:
        compColor = Colors.cyanAccent;
        compText = "Runs Smoothly";
        compIcon = Icons.check_circle_outline_rounded;
        break;
      case CompatibilityLevel.demanding:
        compColor = Colors.amber;
        compText = "Demanding";
        compIcon = Icons.speed_rounded;
        break;
      case CompatibilityLevel.unsupported:
        compColor = Colors.redAccent;
        compText = "High RAM Required";
        compIcon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLoaded
            ? theme.primaryAccent.withOpacity(0.12)
            : theme.cardBg.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLoaded
              ? theme.primaryAccent
              : theme.primaryAccent.withOpacity(0.12),
          width: isLoaded ? 1.5 : 1,
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.quant,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
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
              // Compatibility Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: compColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(compIcon, size: 12, color: compColor),
                    const SizedBox(width: 4),
                    Text(
                      compText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: compColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Feature Badges
              if (item.isReasoning)
                _buildMiniBadge("🧠 CoT Reasoning", Colors.purpleAccent),
              if (item.isVision)
                _buildMiniBadge(" Vision Capable", Colors.blueAccent),
              if (item.isUncensored)
                _buildMiniBadge("🔓 Uncensored", Colors.orangeAccent),
              if (item.isUltraFast)
                _buildMiniBadge("⚡ 40+ t/s", Colors.tealAccent),
            ],
          ),
          const SizedBox(height: 12),

          // Action Row: Size + Download / Load Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Size: ${item.sizeGB < 1.0 ? '${(item.sizeGB * 1024).toInt()} MB' : '${item.sizeGB.toStringAsFixed(2)} GB'}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              if (isInstalled)
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isLoaded ? Colors.greenAccent[400] : theme.primaryAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: (isLoaded ? Colors.greenAccent : theme.primaryAccent).withOpacity(0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(
                        isLoaded ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isLoaded ? "ACTIVE" : "LOAD",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      tooltip: "Delete model",
                      onPressed: () async {
                        if (installedModel != null) {
                          await modelManager.deleteModel(installedModel);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    "DOWNLOAD",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    widget.onDownloadRequested(item.url, item.filename, item.isVision);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
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
            "No models found matching '$_searchQuery'",
            style: TextStyle(fontSize: 13, color: theme.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Try searching Hugging Face for custom GGUFs",
            style: TextStyle(fontSize: 11, color: theme.textSecondary),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.travel_explore_rounded, size: 16),
            label: const Text("Search on Hugging Face"),
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
    );
  }
}
