import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class GenerationHistoryScreen extends StatefulWidget {
  const GenerationHistoryScreen({super.key});

  @override
  State<GenerationHistoryScreen> createState() => _GenerationHistoryScreenState();
}

class _GenerationHistoryScreenState extends State<GenerationHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Week', 'This Month'];

  final List<Map<String, dynamic>> _history = [
    {
      'id': 1,
      'type': 'Background Removal',
      'credits': 2,
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
      'thumbnail': 'https://picsum.photos/200/300?random=1',
    },
    {
      'id': 2,
      'type': 'AI Enhancement',
      'credits': 3,
      'date': DateTime.now().subtract(const Duration(hours: 5)),
      'status': 'completed',
      'thumbnail': 'https://picsum.photos/200/300?random=2',
    },
    {
      'id': 3,
      'type': 'Product Photo',
      'credits': 5,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'completed',
      'thumbnail': 'https://picsum.photos/200/300?random=3',
    },
    {
      'id': 4,
      'type': 'Background Change',
      'credits': 4,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'completed',
      'thumbnail': 'https://picsum.photos/200/300?random=4',
    },
    {
      'id': 5,
      'type': 'AI Enhancement',
      'credits': 3,
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'failed',
      'thumbnail': 'https://picsum.photos/200/300?random=5',
    },
    {
      'id': 6,
      'type': 'Background Removal',
      'credits': 2,
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'completed',
      'thumbnail': 'https://picsum.photos/200/300?random=6',
    },
  ];

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total credits used
    final totalCredits = _history
        .where((h) => h['status'] == 'completed')
        .fold<int>(0, (sum, h) => sum + (h['credits'] as int));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Generation History',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.text,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '${_history.length}',
                    'Total Generations',
                    Icons.auto_awesome,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withAlpha(50),
                ),
                Expanded(
                  child: _buildStatItem(
                    '$totalCredits',
                    'Credits Used',
                    Icons.bolt,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(filter),
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    backgroundColor: AppTheme.surface,
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.border,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // History List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                final isCompleted = item['status'] == 'completed';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: AppTheme.backgroundColor,
                        child: Image.network(
                          item['thumbnail'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.primarySoft,
                            child: const Icon(
                              Icons.image,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['type'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.success.withAlpha(25)
                                : AppTheme.error.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCompleted ? 'Completed' : 'Failed',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 14,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item['credits']} credits',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item['date']),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: isCompleted
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Downloading...')),
                              );
                            }
                          : null,
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

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
