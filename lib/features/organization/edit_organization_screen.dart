import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../organization/organization_provider.dart';
import 'manage_businesses_screen.dart'; // To invalidate businesses provider

class EditOrganizationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> organization;
  const EditOrganizationScreen({super.key, required this.organization});

  @override
  ConsumerState<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends ConsumerState<EditOrganizationScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedCategory;
  late bool _enableScheduledAppointments;
  
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  final List<String> _categories = [
    'Hospital',
    'Bank',
    'Salon',
    'Restaurant',
    'Government',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.organization['name']);
    _descController = TextEditingController(text: widget.organization['description'] ?? '');
    
    _selectedCategory = widget.organization['category'] ?? 'Other';
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Other';
    }
    
    // MySQL tinyint comes back as 1/0 or "1"/"0"
    var allows = widget.organization['allows_scheduling'];
    _enableScheduledAppointments = (allows == 1 || allows == "1");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a business name.')));
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null || user['user_id'] == null) return;

    setState(() => _isLoading = true);

    try {
      // Using multipart request
      var uri = Uri.parse('${ApiClient.baseUrl}/organizations/update.php');
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['org_id'] = widget.organization['org_id'].toString();
      request.fields['user_id'] = user['user_id'].toString();
      request.fields['name'] = _nameController.text.trim();
      request.fields['category'] = _selectedCategory;
      request.fields['description'] = _descController.text.trim();
      request.fields['allows_scheduling'] = _enableScheduledAppointments ? '1' : '0';

      if (_selectedImageBytes != null && _selectedImageName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          _selectedImageBytes!,
          filename: _selectedImageName,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Refresh providers to show updated data globally
        ref.invalidate(myBusinessesProvider);
        ref.invalidate(organizationsProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Organization updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(); // Go back to manage businesses
        }
      } else {
        var msg = 'Failed to update organization';
        try {
          var data = jsonDecode(response.body);
          msg = data['message'] ?? msg;
        } catch (_) {}
        _showError(msg);
      }
    } catch (e) {
      _showError('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Business', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Update Your Details',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep your business profile looking fresh and accurate for your customers.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),
                  
                  // Image Uploader
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _selectedImageBytes != null
                              ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                              : (widget.organization['logo_url'] != null
                                  ? Image.network(
                                      '${ApiClient.baseUrl.split('/backend/api').first}/${widget.organization['logo_url']}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.textSecondary),
                                    )
                                  : const Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('Tap to upload logo', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: [
                        _buildInput(
                          controller: _nameController,
                          label: 'Business Name',
                          icon: Icons.business,
                        ),
                        const SizedBox(height: 20),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategory = val!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildInput(
                          controller: _descController,
                          label: 'Description',
                          hint: 'Brief description of your business',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFF1F5F9), thickness: 2),
                        const SizedBox(height: 8),
                        
                        SwitchListTile(
                          value: _enableScheduledAppointments,
                          onChanged: (val) => setState(() => _enableScheduledAppointments = val),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable Scheduled Appointments', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          subtitle: const Text('Allow customers to book a specific time instead of just joining a live queue.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SAVE CHANGES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String label, String? hint, IconData? icon, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8)) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
