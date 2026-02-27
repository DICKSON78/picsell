import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/theme.dart';
import '../services/firestore_service.dart';

class AdvertisementsScreen extends StatefulWidget {
  const AdvertisementsScreen({super.key});

  @override
  State<AdvertisementsScreen> createState() => _AdvertisementsScreenState();
}

class _AdvertisementsScreenState extends State<AdvertisementsScreen> {
  final AdminFirestoreService _db = AdminFirestoreService();

  String _formatTimeLeft(DateTime? expiry) {
    if (expiry == null) return 'Haijawekwa';
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return 'Imekwisha';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h zimebaki';
    if (hours > 0) return '${hours}h ${mins}m zimebaki';
    return '${mins}m zimebaki';
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdFormSheet(onSaved: () => setState(() {})),
    );
  }

  void _openEditSheet(Map<String, dynamic> ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdFormSheet(existing: ad, onSaved: () => setState(() {})),
    );
  }

  Future<void> _toggleActive(String id, bool current) async {
    await _db.updateAdvertisement(id, {'isActive': !current});
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Futa Tangazo', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kufuta tangazo hili?', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hapana', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Futa', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _db.deleteAdvertisement(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Matangazo', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.text)),
                        Text('Dhibiti matangazo ya slider', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _openAddSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text('Ongeza', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ads list
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.streamAdvertisements(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final ads = snapshot.data ?? [];

                  if (ads.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.campaign_outlined, size: 48, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text('Hakuna Matangazo', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
                          const SizedBox(height: 8),
                          Text('Bonyeza "Ongeza" kuunda tangazo la kwanza', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: ads.length,
                    itemBuilder: (context, index) {
                      final ad = ads[index];
                      final String id = ad['id'] as String;
                      final String imageUrl = ad['imageUrl'] as String? ?? '';
                      final String title = ad['title'] as String? ?? '';
                      final String subtitle = ad['subtitle'] as String? ?? '';
                      final bool isActive = ad['isActive'] as bool? ?? false;
                      final Timestamp? expiresTs = ad['expiresAt'] as Timestamp?;
                      final DateTime? expiryDate = expiresTs?.toDate();
                      final bool isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
                      final String timeLeft = _formatTimeLeft(expiryDate);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isExpired
                                ? AppTheme.error.withAlpha(60)
                                : isActive
                                    ? AppTheme.primaryColor.withAlpha(60)
                                    : AppTheme.border,
                          ),
                          boxShadow: AppTheme.shadowSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image preview
                            if (imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    height: 160,
                                    color: AppTheme.primarySoft,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    height: 160,
                                    color: AppTheme.primarySoft,
                                    child: const Icon(Icons.broken_image, color: AppTheme.primaryColor, size: 40),
                                  ),
                                ),
                              )
                            else
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Container(
                                  height: 100,
                                  color: AppTheme.primarySoft,
                                  child: const Center(child: Icon(Icons.image_outlined, size: 40, color: AppTheme.primaryColor)),
                                ),
                              ),

                            // Info + actions
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (title.isNotEmpty)
                                          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        if (subtitle.isNotEmpty)
                                          Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            // Active/inactive badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isActive ? AppTheme.accentGreen.withAlpha(20) : AppTheme.error.withAlpha(15),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isActive ? 'Inaonyeshwa' : 'Imesimamishwa',
                                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppTheme.accentGreen : AppTheme.error),
                                              ),
                                            ),
                                            // Time remaining badge
                                            if (expiryDate != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isExpired ? AppTheme.error.withAlpha(15) : AppTheme.primarySoft,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                                                      size: 11,
                                                      color: isExpired ? AppTheme.error : AppTheme.primaryColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      timeLeft,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: isExpired ? AppTheme.error : AppTheme.primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Active toggle
                                  GestureDetector(
                                    onTap: () => _toggleActive(id, isActive),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (isActive ? AppTheme.accentGreen : AppTheme.textLight).withAlpha(20),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(isActive ? Icons.visibility : Icons.visibility_off_outlined, size: 20, color: isActive ? AppTheme.accentGreen : AppTheme.textLight),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Edit
                                  GestureDetector(
                                    onTap: () => _openEditSheet(ad),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primarySoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primaryColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete
                                  GestureDetector(
                                    onTap: () => _delete(id),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error.withAlpha(15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Bottom sheet form for Add / Edit advertisement
// ============================================================
class _AdFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _AdFormSheet({this.existing, required this.onSaved});

  @override
  State<_AdFormSheet> createState() => _AdFormSheetState();
}

class _AdFormSheetState extends State<_AdFormSheet> {
  final AdminFirestoreService _db = AdminFirestoreService();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();

  File? _pickedImage;
  String _existingImageUrl = '';
  bool _isActive = true;
  bool _isSaving = false;

  // Duration options: hours
  static const List<Map<String, dynamic>> _durationOptions = [
    {'label': '24 saa', 'hours': 24},
    {'label': 'Siku 3', 'hours': 72},
    {'label': 'Wiki 1', 'hours': 168},
    {'label': 'Wiki 2', 'hours': 336},
  ];
  int _selectedHours = 168; // default: 1 week

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final ad = widget.existing!;
      _titleController.text = ad['title'] as String? ?? '';
      _subtitleController.text = ad['subtitle'] as String? ?? '';
      _isActive = ad['isActive'] as bool? ?? true;
      _existingImageUrl = ad['imageUrl'] as String? ?? '';
      // Calculate remaining hours from existing expiresAt
      final Timestamp? ts = ad['expiresAt'] as Timestamp?;
      if (ts != null) {
        final diff = ts.toDate().difference(DateTime.now());
        final remaining = diff.inHours;
        if (remaining <= 24) {
          _selectedHours = 24;
        } else if (remaining <= 72) {
          _selectedHours = 72;
        } else if (remaining <= 168) {
          _selectedHours = 168;
        } else {
          _selectedHours = 336;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<String> _uploadImage(File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('advertisements/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final hasImage = _pickedImage != null || _existingImageUrl.isNotEmpty;
    if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tafadhali chagua picha ya tangazo', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
      }

      final expiresAt = DateTime.now().add(Duration(hours: _selectedHours));

      if (_isEditing) {
        await _db.updateAdvertisement(widget.existing!['id'] as String, {
          'imageUrl': imageUrl,
          'title': _titleController.text.trim(),
          'subtitle': _subtitleController.text.trim(),
          'isActive': _isActive,
          'expiresAt': Timestamp.fromDate(expiresAt),
        });
      } else {
        await _db.createAdvertisement(
          imageUrl: imageUrl,
          title: _titleController.text.trim(),
          subtitle: _subtitleController.text.trim(),
          isActive: _isActive,
          expiresAt: expiresAt,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindwa: ${e.toString()}', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _isEditing ? 'Hariri Tangazo' : 'Tangazo Jipya',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
            ),
            const SizedBox(height: 20),

            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withAlpha(60), width: 1.5),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_pickedImage!, fit: BoxFit.cover),
                      )
                    : _existingImageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(imageUrl: _existingImageUrl, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppTheme.primaryColor),
                              const SizedBox(height: 8),
                              Text('Bonyeza kuchagua picha', style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                            ],
                          ),
              ),
            ),

            // Image size guidelines
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ukubwa unaoshauriwa: 1080 × 540 px (uwiano 2:1)',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Format: JPG au PNG  •  Ukubwa max: 2 MB',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Title field
            _buildField(_titleController, 'Kichwa cha habari (optional)', Icons.title),
            const SizedBox(height: 10),

            // Subtitle field
            _buildField(_subtitleController, 'Maelezo mafupi (optional)', Icons.subtitles_outlined, maxLines: 2),
            const SizedBox(height: 16),

            // Duration picker
            Text('Muda wa Tangazo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.text)),
            const SizedBox(height: 4),
            Text(
              _isEditing ? 'Chagua muda mpya (unahesabiwa kutoka sasa)' : 'Tangazo litaisha baada ya muda huu',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: _durationOptions.map((opt) {
                final hours = opt['hours'] as int;
                final isSelected = _selectedHours == hours;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedHours = hours),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppTheme.border,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            opt['label'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Active toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Onyesha kwenye App', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.text)),
                        Text('Tangazo litaonekana kwenye slider ya wateja', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: AppTheme.primaryColor,
                    activeTrackColor: AppTheme.primarySoft,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _isSaving ? null : AppTheme.primaryGradient,
                    color: _isSaving ? AppTheme.border : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isSaving ? [] : [BoxShadow(color: AppTheme.primaryColor.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryColor))
                      else
                        const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _isSaving ? 'Inapakia...' : (_isEditing ? 'Hifadhi Mabadiliko' : 'Chapisha Tangazo'),
                        style: GoogleFonts.poppins(color: _isSaving ? AppTheme.textSecondary : Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
      ),
    );
  }
}
