import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';
import 'auth_service.dart';

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
  const SellServiceScreen({super.key});

  @override
  State<SellServiceScreen> createState() => _SellServiceScreenState();
}

class _SellServiceScreenState extends State<SellServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedCategory = 'Desain';
  final List<String> _categories = ['Desain', 'IT Support', 'Tutor', 'Writing', 'Lainnya'];

  bool _isLoading = false;

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String rawPrice = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final int price = int.parse(rawPrice.isEmpty ? '0' : rawPrice);

      final uri = Uri.http('192.168.1.3:8000', '/services');
      
      final headers = {'Content-Type': 'application/json'};
      if (AuthService.token != null) {
        headers['Authorization'] = 'Bearer ${AuthService.token}';
      }

      final body = json.encode({
        "title": _titleController.text,
        "description": _descController.text,
        "price": price,
        "category": _selectedCategory,
      });

      final response = await http.post(uri, headers: headers, body: body).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service successfully listed!'), backgroundColor: Colors.green),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Offer a Service', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              _buildLabel("PRICE (Rp)"),
              _buildTextField(
                controller: _priceController,
                hint: "e.g. 50.000",
                isNumber: true,
                formatters: [CurrencyInputFormatter()],
                validator: (val) => val!.isEmpty ? "Price is required" : null,
              ),

              SizedBox(height: 24),
              _buildLabel("CATEGORY"),
              _buildDropdown(_categories, _selectedCategory, (val) => setState(() => _selectedCategory = val!)),

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
                      : Text("Post Service", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
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
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
