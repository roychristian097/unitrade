import 'theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'marketplace_screen.dart'; // For CurrencyInputFormatter if needed
import 'auth_service.dart';

class SellItemScreen extends StatefulWidget {
  final Product? existingProduct;
  const SellItemScreen({super.key, this.existingProduct});

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _itemType = 'Barang'; // 'Barang' or 'Jasa'

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _campusController = TextEditingController(text: "Universitas Nasional - Jakarta Selatan, Pasar Minggu");

  // Advanced details for Barang
  String _selectedWarranty = 'Tidak ada';
  final List<String> _warranties = ['Tidak ada', '1x24 Jam', '3 Hari', '1 Minggu'];
  final TextEditingController _minNegoController = TextEditingController();

  // Advanced details for Jasa
  final TextEditingController _maxPriceController = TextEditingController();

  // Handover Location for all
  final TextEditingController _handoverController = TextEditingController();

  String _selectedCategory = 'Elektronik';
  final List<String> _categories = ['Elektronik', 'Pakaian', 'Buku', 'Otomotif', 'Jasa', 'Lainnya'];

  String _selectedCondition = 'Baru (Brand New)';
  final List<String> _conditions = [
    'Baru (Brand New)',
    'Mulus (Like New)',
    'Pemakaian Wajar (Fair/Used)'
  ];

  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _itemType = p.itemType;
      _nameController.text = p.name;
      _descController.text = p.description;
      _priceController.text = p.price.toString();
      _campusController.text = p.campus;
      if (_categories.contains(p.category)) {
        _selectedCategory = p.category;
      }
      if (_conditions.contains(p.condition)) {
        _selectedCondition = p.condition;
      }

      if (_itemType == 'Barang') {
        _selectedWarranty = p.advancedDetails['warranty'] ?? 'Tidak ada';
        if (!_warranties.contains(_selectedWarranty)) _selectedWarranty = 'Tidak ada';
        _minNegoController.text = p.advancedDetails['min_nego']?.toString() ?? '';
      } else {
        _maxPriceController.text = p.advancedDetails['max_price']?.toString() ?? '';
      }
      _handoverController.text = p.advancedDetails['handover_location'] ?? '';
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

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String rawPrice = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final int price = int.parse(rawPrice.isEmpty ? '0' : rawPrice);

      final isEdit = widget.existingProduct != null;
      final uri = isEdit 
          ? Uri.http('192.168.1.3:8000', '/products/${widget.existingProduct!.id}')
          : Uri.http('192.168.1.3:8000', '/products');
      var request = http.MultipartRequest(isEdit ? 'PUT' : 'POST', uri);

      if (AuthService.token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.token}';
      }

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descController.text;
      request.fields['price'] = price.toString();
      request.fields['category'] = _selectedCategory;
      request.fields['condition'] = _selectedCondition;
      request.fields['campus'] = _campusController.text;
      request.fields['tags'] = '["${_selectedCategory.toUpperCase()}", "NEW LISTING"]';
      
      Map<String, dynamic> advancedDetails = {};
      if (_itemType == 'Barang') {
        advancedDetails['warranty'] = _selectedWarranty;
        String minNego = _minNegoController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (minNego.isNotEmpty) advancedDetails['min_nego'] = minNego;
      } else {
        String maxPrice = _maxPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (maxPrice.isNotEmpty) advancedDetails['max_price'] = maxPrice;
      }
      advancedDetails['handover_location'] = _handoverController.text;
      request.fields['item_type'] = _itemType;
      request.fields['advanced_details'] = jsonEncode(advancedDetails);

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
      }

      final streamedResponse = await request.send().timeout(Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Item successfully updated!' : 'Item successfully listed!'), backgroundColor: Colors.green),
        );
        // Pop and return true to trigger refresh
        Navigator.pop(context, true);
      } else {
        throw Exception("Gagal menyimpan data");
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
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _campusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(widget.existingProduct != null ? 'Edit Listing' : 'Sell An Item', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.textColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Placeholder
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.textColor.withOpacity(0.1), style: BorderStyle.solid),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 40),
                              SizedBox(height: 8),
                              Text("Tap to upload photos", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 32),
              _buildLabel("JENIS LISTING"),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Barang', style: TextStyle(color: context.textColor, fontSize: 14)),
                      value: 'Barang',
                      groupValue: _itemType,
                      activeColor: const Color(0xFFE67E22),
                      onChanged: (val) => setState(() { _itemType = val!; _selectedCategory = 'Elektronik'; }),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Jasa', style: TextStyle(color: context.textColor, fontSize: 14)),
                      value: 'Jasa',
                      groupValue: _itemType,
                      activeColor: const Color(0xFFE67E22),
                      onChanged: (val) => setState(() { _itemType = val!; _selectedCategory = 'Jasa'; }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              _buildLabel("PRODUCT/SERVICE NAME"),
              _buildTextField(
                controller: _nameController,
                hint: "e.g. MacBook Air M1",
                validator: (val) => val!.isEmpty ? "Name is required" : null,
              ),

              SizedBox(height: 24),
              _buildLabel("DESCRIPTION"),
              _buildTextField(
                controller: _descController,
                hint: "Describe the condition, specs, etc.",
                maxLines: 4,
                validator: (val) => val!.isEmpty ? "Description is required" : null,
              ),

              SizedBox(height: 24),
              if (_itemType == 'Barang') ...[
                _buildLabel("PRICE (Rp)"),
                _buildTextField(
                  controller: _priceController,
                  hint: "e.g. 5.000.000",
                  isNumber: true,
                  formatters: [CurrencyInputFormatter()],
                  validator: (val) => val!.isEmpty ? "Price is required" : null,
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("HARGA MINIMUM (Rp)"),
                          _buildTextField(
                            controller: _priceController,
                            hint: "Min Price",
                            isNumber: true,
                            formatters: [CurrencyInputFormatter()],
                            validator: (val) => val!.isEmpty ? "Required" : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("HARGA MAKSIMUM (Rp)"),
                          _buildTextField(
                            controller: _maxPriceController,
                            hint: "Opsional",
                            isNumber: true,
                            formatters: [CurrencyInputFormatter()],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("CATEGORY"),
                        _buildDropdown(_categories, _selectedCategory, (val) => setState(() => _selectedCategory = val!)),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  if (_itemType == 'Barang')
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("CONDITION"),
                          _buildDropdown(_conditions, _selectedCondition, (val) => setState(() => _selectedCondition = val!)),
                        ],
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 24),
              if (_itemType == 'Barang') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("PERSONAL WARRANTY"),
                          _buildDropdown(_warranties, _selectedWarranty, (val) => setState(() => _selectedWarranty = val!)),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("HARGA MIN NEGO"),
                          _buildTextField(
                            controller: _minNegoController,
                            hint: "Opsional",
                            isNumber: true,
                            formatters: [CurrencyInputFormatter()],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 24),
              _buildLabel("LOKASI HANDOVER / MEETUP"),
              _buildTextField(
                controller: _handoverController,
                hint: "e.g. Kantin Bawah, Halte Depan, dsb. (Opsional)",
              ),

              SizedBox(height: 24),
              _buildLabel("CAMPUS"),
              _buildTextField(
                controller: _campusController,
                hint: "Universitas Nasional - Jakarta Selatan, Pasar Minggu",
                validator: (val) => val!.isEmpty ? "Campus is required" : null,
              ),

              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.textColor, strokeWidth: 2))
                      : Text(widget.existingProduct != null ? "Save Changes" : "List Item", style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
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
      child: Text(text, style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
      style: TextStyle(color: context.textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        filled: true,
        fillColor: context.surfaceColor,
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
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          dropdownColor: context.surfaceColor,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: TextStyle(color: context.textColor, fontSize: 14),
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
