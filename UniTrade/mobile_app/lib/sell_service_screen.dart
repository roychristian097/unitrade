import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'theme.dart';
import 'auth_service.dart';

import 'services_screen.dart'; // Import ServiceItem

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    int value = int.parse(cleanText);
    String formatted = value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return newValue.copyWith(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class SellServiceScreen extends StatefulWidget {
  final ServiceItem? existingService;
  
  const SellServiceScreen({super.key, this.existingService});

  @override
  State<SellServiceScreen> createState() => _SellServiceScreenState();
}

class _SellServiceScreenState extends State<SellServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _campusController = TextEditingController(text: "Universitas Nasional - Jakarta Selatan, Pasar Minggu");
  final TextEditingController _meetupController = TextEditingController();

  String _selectedCategory = 'Desain';
  final List<String> _categories = ['Desain', 'IT Support', 'Tutor', 'Writing', 'Lainnya'];

  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingService != null) {
      final service = widget.existingService!;
      _titleController.text = service.title;
      _descController.text = service.description;
      _priceController.text = service.price.toString();
      if (service.maxPrice != null) {
        _maxPriceController.text = service.maxPrice.toString();
      }
      if (_categories.contains(service.category)) {
        _selectedCategory = service.category;
      }
      if (service.campus != null) {
        _campusController.text = service.campus!;
      }
      if (service.meetupLocation != null) {
        _meetupController.text = service.meetupLocation!;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String rawPrice = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final int price = int.parse(rawPrice.isEmpty ? '0' : rawPrice);
      
      final String rawMaxPrice = _maxPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final int? maxPrice = rawMaxPrice.isEmpty ? null : int.parse(rawMaxPrice);

      final isEdit = widget.existingService != null;
      final uri = isEdit 
          ? Uri.http('192.168.110.199:8000', '/services/${widget.existingService!.id}')
          : Uri.http('192.168.110.199:8000', '/services');
      var request = http.MultipartRequest(isEdit ? 'PUT' : 'POST', uri);
      
      if (AuthService.token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.token}';
      }

      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descController.text;
      request.fields['price'] = price.toString();
      if (maxPrice != null) {
        request.fields['max_price'] = maxPrice.toString();
      }
      request.fields['category'] = _selectedCategory;
      request.fields['campus'] = _campusController.text;
      request.fields['meetup_location'] = _meetupController.text;

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
      }

      final streamedResponse = await request.send().timeout(Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Service successfully updated!' : 'Service successfully listed!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Gagal menyimpan layanan");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _maxPriceController.dispose();
    _campusController.dispose();
    _meetupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.existingService != null ? 'Edit Service' : 'Offer a Service', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: context.colors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border, style: BorderStyle.solid),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: context.colors.textMuted),
                            SizedBox(height: 8),
                            Text("Tambah Foto Portofolio", style: TextStyle(color: context.colors.textMuted)),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 24),
              _buildLabel("SERVICE TITLE"),
              _buildTextField(
                controller: _titleController,
                hint: "e.g. Jasa Desain Poster Acara",
                validator: (val) => val!.isEmpty ? "Title is required" : null,
              ),

              SizedBox(height: 24),
              _buildLabel("DESCRIPTION"),
              _buildTextField(
                controller: _descController,
                hint: "Describe what you offer in detail...",
                maxLines: 4,
                validator: (val) => val!.isEmpty ? "Description is required" : null,
              ),

              SizedBox(height: 24),
              _buildLabel("PRICE RANGE (Rp)"),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      hint: "Min (e.g. 50.000)",
                      isNumber: true,
                      formatters: [CurrencyInputFormatter()],
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxPriceController,
                      hint: "Max (Opsional)",
                      isNumber: true,
                      formatters: [CurrencyInputFormatter()],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),
              _buildLabel("CATEGORY"),
              _buildDropdown(_categories, _selectedCategory, (val) => setState(() => _selectedCategory = val!)),

              SizedBox(height: 24),
              _buildLabel("LOKASI KAMPUS"),
              _buildTextField(
                controller: _campusController,
                hint: "Masukkan nama kampus / lokasi",
                validator: (val) => val!.isEmpty ? "Kampus wajib diisi" : null,
              ),

              SizedBox(height: 24),
              _buildLabel("TITIK TEMU / PICKUP (Spesifik)"),
              _buildTextField(
                controller: _meetupController,
                hint: "Contoh: Kantin Sastra, Lab Komputer",
                validator: (val) => val!.isEmpty ? "Titik temu wajib diisi" : null,
              ),

              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(widget.existingService != null ? "Save Changes" : "Post Service", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(color: context.colors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : (maxLines != 1 ? TextInputType.multiline : TextInputType.text),
      textInputAction: maxLines != 1 ? TextInputAction.newline : TextInputAction.done,
      maxLines: maxLines,
      inputFormatters: formatters,
      style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.colors.textMuted, fontSize: 14),
        filled: true,
        fillColor: context.colors.cardBg,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorStyle: TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown(List<String> items, String currentValue, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          dropdownColor: context.colors.cardBg,
          icon: Icon(Icons.keyboard_arrow_down, color: context.colors.textMuted),
          style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }
}
