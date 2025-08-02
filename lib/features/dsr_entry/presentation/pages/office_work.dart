import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/document_number_storage.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/modern_button.dart';
import '../../../../core/widgets/modern_input.dart';
import '../../../../core/widgets/modern_app_bar.dart';
import 'dsr_entry.dart';
import 'dsr_exception_entry.dart';

class OfficeWork extends StatefulWidget {
  const OfficeWork({super.key});
  @override
  State<OfficeWork> createState() => _OfficeWorkState();
}

class _OfficeWorkState extends State<OfficeWork> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _submissionDateController = TextEditingController();
  final TextEditingController _reportDateController     = TextEditingController();

  // Add/Update process type state
  String? _processItem = 'Select';
  List<String> _processdropdownItems = ['Select'];
  bool _isLoadingProcessTypes = true;
  String? _processTypeError;

  // Document-number dropdown state
  bool _loadingDocs = false;
  List<String> _documentNumbers = [];
  String? _selectedDocuNumb;

  // Dynamic field definitions
  List<Map<String, dynamic>> _fields = [];
  bool _isLoading = true;

  List<File?> _selectedImages = [null];

  final _documentNumberController = TextEditingController();
  String? _documentNumber;

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initGeolocation();
    _loadInitialDocumentNumber();
    _fetchProcessTypes();
    _setSubmissionDateToToday();
    _initializeFields();
  }

  Future<void> _initGeolocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied.');
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = pos;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }


  // Load document number when screen initializes
  Future<void> _loadInitialDocumentNumber() async {
    final savedDocNumber = await DocumentNumberStorage.loadDocumentNumber(DocumentNumberKeys.officeWork);
    if (savedDocNumber != null) {
      setState(() {
        _documentNumber = savedDocNumber;
      });
    }
  }

  void _setSubmissionDateToToday() {
    final today = DateTime.now();
    _submissionDateController.text = DateFormat('yyyy-MM-dd').format(today);
  }

  Future<void> _initializeFields() async {
    try {
      // Fetch process types from API
      final processTypes = await _fetchProcessTypes();
      
      setState(() {
        _fields = [
          {
            'label': 'Process Type',
            'type': 'dropdown',
            'items': processTypes,
            'value': processTypes.isNotEmpty ? processTypes[0] : 'Select',
            'key': 'ProcessType',
          },
          {
            'label': 'Work Related To',
            'controller': TextEditingController(),
            'type': 'text',
            'maxLines': 3,
            'key': 'dsrRem01',
          },
          {
            'label': 'No. of Hours Spent',
            'controller': TextEditingController(),
            'type': 'number',
            'key': 'dsrRem02',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching process types: $e');
      // Fallback to default process types
      setState(() {
        _fields = [
          {
            'label': 'Process Type',
            'type': 'dropdown',
            'items': ['Select', 'Add', 'Update'],
            'value': 'Select',
            'key': 'ProcessType',
          },
          {
            'label': 'Work Related To',
            'controller': TextEditingController(),
            'type': 'text',
            'maxLines': 3,
            'key': 'dsrRem01',
          },
          {
            'label': 'No. of Hours Spent',
            'controller': TextEditingController(),
            'type': 'number',
            'key': 'dsrRem02',
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchProcessTypes() async {
    setState(() { _isLoadingProcessTypes = true; _processTypeError = null; });
    try {
      final url = Uri.parse('http://192.168.36.25/api/DsrTry/getProcessTypes');
      final response = await http.get(url);
      print('ProcessTypes API status:  [33m${response.statusCode} [0m');
      print('ProcessTypes API body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List processTypesList = [];
        if (data is List) {
          processTypesList = data;
        } else if (data is Map &&
            (data['ProcessTypes'] != null || data['processTypes'] != null)) {
          processTypesList =
              (data['ProcessTypes'] ?? data['processTypes']) as List;
        }
        final processTypes = processTypesList
            .map<String>((type) {
              if (type is Map) {
                return type['Description']?.toString() ??
                    type['description']?.toString() ??
                    '';
              } else {
                return type.toString();
              }
            })
            .where((desc) => desc.isNotEmpty)
            .toList();
        setState(() {
          _processdropdownItems = ['Select', ...processTypes];
          _processItem = 'Select';
        });
        return processTypes;
      } else {
        setState(() {
          _processTypeError = 'Failed to load process types: ${response.statusCode}';
          _processdropdownItems = ['Select'];
          _processItem = 'Select';
        });
        return ['Select'];
      }
    } catch (e) {
      setState(() {
        _processTypeError = 'Error: $e';
        _processdropdownItems = ['Select'];
        _processItem = 'Select';
      });
      return ['Select'];
    } finally {
      setState(() {
        _isLoadingProcessTypes = false;
      });
    }
    // Fallback return in case of unexpected flow
    return ['Select'];
  }

  // Fetch document numbers for Update
  Future<void> _fetchDocumentNumbers() async {
    setState(() {
      _loadingDocs = true;
      _documentNumbers = [];
      _selectedDocuNumb = null;
    });
    final uri = Uri.parse(
      'http://192.168.36.25/api/DsrTry/getDocumentNumbers?dsrParam=53' // Use correct param for this activity
    );
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _documentNumbers = data
            .map((e) {
              return (e['DocuNumb']
                   ?? e['docuNumb']
                   ?? e['DocumentNumber']
                   ?? e['documentNumber']
                   ?? '').toString();
            })
            .where((s) => s.isNotEmpty)
            .toList();
        });
      }
    } catch (_) {
      // ignore errors
    } finally {
      setState(() { _loadingDocs = false; });
    }
  }

  // Fetch details for a document number and populate fields
  Future<void> _fetchAndPopulateDetails(String docuNumb) async {
    final uri = Uri.parse('http://192.168.36.25/api/DsrTry/getDsrEntry?docuNumb=$docuNumb');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          for (final field in _fields) {
            if (field['type'] == 'dropdown') {
              field['value'] = data[field['key']] ?? 'Select';
            } else if (field['type'] == 'text' || field['type'] == 'number') {
              field['controller'].text = data[field['key']] ?? '';
            }
          }
          if (data['SubmissionDate'] != null) {
            _submissionDateController.text = data['SubmissionDate'].toString().substring(0, 10);
          }
          if (data['ReportDate'] != null) {
            _reportDateController.text = data['ReportDate'].toString().substring(0, 10);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _submissionDateController.dispose();
    _reportDateController.dispose();
    for (final field in _fields) {
      if (field['type'] == 'text' || field['type'] == 'number') {
        field['controller'].dispose();
      }
    }
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<String?> _fetchDocumentNumberFromServer() async {
    try {
      final url = Uri.parse('http://192.168.36.25/api/DsrTry/generateDocumentNumber');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode('KKR'), // Hardcoded to KKR
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? documentNumber;
        if (data is Map<String, dynamic>) {
          documentNumber = data['documentNumber'] ?? data['DocumentNumber'] ?? data['docNumber'] ?? data['DocNumber'];
        } else if (data is String) {
          documentNumber = data;
        }
        
        // Save to persistent storage
        if (documentNumber != null) {
          await DocumentNumberStorage.saveDocumentNumber(DocumentNumberKeys.officeWork, documentNumber);
        }
        
        return documentNumber;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickSubmissionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _submissionDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickReportDate() async {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10), // Allow any past date
      lastDate: now, // Restrict to today or earlier
    );
    if (picked != null) {
      // Check if picked date is before threeDaysAgo
      if (picked.isBefore(threeDaysAgo)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Please Put Valid DSR Date.'),
            content: const Text(
              'You Can submit DSR only Last Three Days. If You want to submit back date entry Please enter Exception entry(Path : Transcation --> DSR Exception Entry). Take Approval from concerned and Fill DSR Within 3 days after approval.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DsrExceptionEntryPage()),
                  );
                },
                child: const Text('Go to Exception Entry'),
              ),
            ],
          ),
        );
        return;
      }
      setState(() {
        _reportDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages[index] = File(pickedFile.path);
      });
    }
  }

  void _showImageDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.file(imageFile, fit: BoxFit.contain),
      ),
    );
  }

  void _onSubmit({required bool exitAfter}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      await _initGeolocation();
    }

    final dsrData = <String, dynamic>{
      'ActivityType': 'Office Work',
      'SubmissionDate': _submissionDateController.text,
      'ReportDate': _reportDateController.text,
      ...{
        for (final field in _fields)
          if (field['type'] == 'dropdown')
            field['key'] as String: field['value']
          else
            field['key'] as String: field['controller'].text
      },
      'Images': _selectedImages.map((file) => file?.path).toList(),
      'latitude': _currentPosition?.latitude.toString() ?? '',
      'longitude': _currentPosition?.longitude.toString() ?? '',
      'DsrParam': '53',
      'DocuNumb': _processItem == 'Update' ? _selectedDocuNumb : null,
      'ProcessType': _processItem == 'Update' ? 'U' : 'A',
    };

    try {
      final url = Uri.parse(
        'http://192.168.36.25/api/DsrTry/' + (_processItem == 'Update' ? 'update' : '')
      );
      final resp = _processItem == 'Update'
          ? await http.put(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(dsrData),
            )
          : await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(dsrData),
            );

      final success = (_processItem == 'Update' && resp.statusCode == 204) ||
                      (_processItem != 'Update' && resp.statusCode == 201);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? exitAfter
                  ? '${_processItem == 'Update' ? 'Updated' : 'Submitted'} successfully. Exiting...'
                  : '${_processItem == 'Update' ? 'Updated' : 'Submitted'} successfully. Ready for new entry.'
              : 'Error: ${resp.body}'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) {
        if (exitAfter) {
          Navigator.of(context).pop();
        } else {
          _clearForm();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exception: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _submissionDateController.clear();
      _reportDateController.clear();
      for (final field in _fields) {
        if (field['type'] == 'dropdown') {
          field['value'] = field['items'][0];
        } else if (field['type'] == 'text' || field['type'] == 'number') {
          field['controller'].clear();
        }
      }
      _selectedImages = [null];
    });
    _formKey.currentState!.reset();
  }

  // Add a method to reset the form (clear document number)
  void _resetForm() {
    setState(() {
      _documentNumber = null;
      _documentNumberController.clear();
      _fields[0]['value'] = 'Select';
      // Clear other form fields as needed
    });
    DocumentNumberStorage.clearDocumentNumber(DocumentNumberKeys.officeWork); // Clear from persistent storage
  }

  Future<void> submitDsrEntry(Map<String, dynamic> dsrData) async {
    final url = Uri.parse('http://192.168.36.25/api/DsrTry');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dsrData),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    if (response.statusCode == 201) {
      print('✅ Data inserted successfully!');
    } else {
      print('❌ Data NOT inserted! Error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: SparshTheme.scaffoldBackground,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DsrEntry()),
            ),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          title: const Text('Office Work', style: TextStyle(color: Colors.white)),
          backgroundColor: SparshTheme.primaryBlue,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SparshTheme.scaffoldBackground,
      appBar: ModernAppBar(
        title: 'Office Work',
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DsrEntry()),
          ),
          icon: const Icon(Icons.arrow_back_ios_new, color: SparshTheme.textOnPrimary),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SparshTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ModernCardHeader(
                      title: 'Process Information',
                      subtitle: 'Select process type and document details',
                      leading: Icon(Icons.settings, color: SparshTheme.primaryBlue),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    if (_processTypeError != null)
                      Container(
                        padding: const EdgeInsets.all(SparshTheme.spacing12),
                        decoration: BoxDecoration(
                          color: SparshTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(SparshTheme.radiusSm),
                        ),
                        child: Text(_processTypeError!, style: const TextStyle(color: SparshTheme.errorRed)),
                      ),
                    if (_processTypeError != null) const SizedBox(height: SparshTheme.spacing12),
                    _isLoadingProcessTypes
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : ModernDropdown<String>(
                          label: _fields[0]['label'],
                          value: _processItem,
                          items: _processdropdownItems.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
                          onChanged: (val) async {
                            setState(() {
                              _processItem = val;
                              _fields[0]['value'] = val;
                            });
                            if (val == 'Update') await _fetchDocumentNumbers();
                          },
                        ),
                    if (_processItem == 'Update') ...[
                      const SizedBox(height: SparshTheme.spacing16),
                      _loadingDocs
                        ? const Center(child: CircularProgressIndicator())
                        : ModernDropdown<String>(
                            label: 'Document Number',
                            value: _selectedDocuNumb,
                            items: _documentNumbers
                                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (v) async {
                              setState(() => _selectedDocuNumb = v);
                              if (v != null) await _fetchAndPopulateDetails(v);
                            },
                          ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: SparshTheme.spacing16),
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ModernCardHeader(
                      title: 'Activity Details',
                      subtitle: 'Enter work-related information',
                      leading: Icon(Icons.work, color: SparshTheme.primaryBlue),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    // Render the rest of the fields (text/number)
                    for (final field in _fields.skip(1)) ...[
                      ModernInput(
                        label: field['label'],
                        controller: field['controller'],
                        keyboardType: field['type'] == 'number' ? TextInputType.number : TextInputType.text,
                        maxLines: field['maxLines'] ?? 1,
                      ),
                      const SizedBox(height: SparshTheme.spacing16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: SparshTheme.spacing16),
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ModernCardHeader(
                      title: 'Date Information',
                      subtitle: 'Submission and report dates',
                      leading: Icon(Icons.calendar_today, color: SparshTheme.primaryBlue),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    ModernInput(
                      label: 'Submission Date',
                      controller: _submissionDateController,
                      readOnly: true,
                      enabled: false,
                      suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    ModernInput(
                      label: 'Report Date',
                      controller: _reportDateController,
                      readOnly: true,
                      onTap: _pickReportDate,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SparshTheme.spacing16),
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ModernCardHeader(
                      title: 'Upload Images',
                      subtitle: 'Add supporting documents',
                      leading: Icon(Icons.photo_library, color: SparshTheme.primaryBlue),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    ...List.generate(_selectedImages.length, (i) {
                      final file = _selectedImages[i];
                      return ModernCard(
                        margin: const EdgeInsets.only(bottom: SparshTheme.spacing12),
                        backgroundColor: file != null ? SparshTheme.successGreen.withOpacity(0.05) : SparshTheme.surfaceSecondary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Document ${i + 1}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: SparshTheme.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                if (file != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: SparshTheme.spacing8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: SparshTheme.successGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(SparshTheme.radiusXl),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, color: SparshTheme.successGreen, size: 16),
                                        const SizedBox(width: SparshTheme.spacing4),
                                        Text(
                                          'Uploaded',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: SparshTheme.successGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: SparshTheme.spacing12),
                            Row(
                              children: [
                                Expanded(
                                  child: ModernButton(
                                    text: file != null ? 'Replace' : 'Upload',
                                    icon: Icon(file != null ? Icons.refresh : Icons.upload_file, size: 18),
                                    onPressed: () => _pickImage(i),
                                    type: ModernButtonType.outline,
                                  ),
                                ),
                                if (file != null) ...[
                                  const SizedBox(width: SparshTheme.spacing8),
                                  Expanded(
                                    child: ModernButton(
                                      text: 'View',
                                      icon: const Icon(Icons.visibility, size: 18),
                                      onPressed: () => _showImageDialog(file),
                                      type: ModernButtonType.success,
                                    ),
                                  ),
                                  const SizedBox(width: SparshTheme.spacing8),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedImages.removeAt(i);
                                      });
                                    },
                                    icon: const Icon(Icons.remove_circle_outline, color: SparshTheme.errorRed),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_selectedImages.length < 3) ...[
                      const SizedBox(height: SparshTheme.spacing12),
                      Center(
                        child: ModernButton(
                          text: 'Add More Image',
                          icon: const Icon(Icons.add_photo_alternate),
                          onPressed: () {
                            setState(() {
                              _selectedImages.add(null);
                            });
                          },
                          type: ModernButtonType.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: SparshTheme.spacing24),
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      text: 'Submit & New',
                      onPressed: () => _onSubmit(exitAfter: false),
                      type: ModernButtonType.secondary,
                    ),
                  ),
                  const SizedBox(width: SparshTheme.spacing12),
                  Expanded(
                    child: ModernButton(
                      text: 'Submit & Exit',
                      onPressed: () => _onSubmit(exitAfter: true),
                      type: ModernButtonType.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SparshTheme.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: SparshTypography.bodyBold.copyWith(color: SparshTheme.textPrimary),
    ),
  );

  Widget _buildTextField(
      String hint, {
        TextEditingController? controller,
        TextInputType? keyboardType,
        int maxLines = 1,
      }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.md)),
          contentPadding: const EdgeInsets.symmetric(horizontal: SparshSpacing.sm, vertical: SparshSpacing.sm),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      );

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SparshBorderRadius.md),
          border: Border.all(color: SparshTheme.borderGrey, width: 1),
          color: SparshTheme.cardBackground,
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          underline: Container(),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      );

  Widget _buildDateField(TextEditingController controller, VoidCallback onTap, String hint) =>
      TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: onTap),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(SparshBorderRadius.md)),
          contentPadding: const EdgeInsets.symmetric(horizontal: SparshSpacing.sm, vertical: SparshSpacing.sm),
        ),
        onTap: onTap,
        validator: (val) => val == null || val.isEmpty ? 'Select date' : null,
      );
}
