import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learning2/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/document_number_storage.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/modern_button.dart';
import '../../../../core/widgets/modern_input.dart';
import '../../../../core/widgets/modern_app_bar.dart';
import 'dsr_entry.dart';
import 'dsr_exception_entry.dart';

class AnyOtherActivity extends StatefulWidget {
  const AnyOtherActivity({super.key});

  @override
  State<AnyOtherActivity> createState() => _AnyOtherActivityState();
}

class _AnyOtherActivityState extends State<AnyOtherActivity> {
  // 1) CONTROLLERS for dropdowns and dates
  String? _processItem = 'Select';
  List<String> _processdropdownItems = ['Select'];
  bool _isLoadingProcessTypes = true;
  String? _processTypeError;

  // NEW: Document-number dropdown state
  bool _loadingDocs = false;
  List<String> _documentNumbers = [];
  String? _selectedDocuNumb;

  // Geolocation
  Position? _currentPosition;

  final TextEditingController _dateController       = TextEditingController();
  final TextEditingController _reportDateController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedReportDate;

  // 2) CONTROLLERS for activity text fields
  final TextEditingController _activity1Controller      = TextEditingController();
  final TextEditingController _activity2Controller      = TextEditingController();
  final TextEditingController _activity3Controller      = TextEditingController();
  final TextEditingController _anyOtherPointsController = TextEditingController();

  // 3) IMAGE UPLOAD state (up to 3)
  final List<int> _uploadRows        = [0];
  final ImagePicker _picker          = ImagePicker();
  final List<XFile?> _selectedImages = [null];

  // 4) Document-number persistence
  final _documentNumberController = TextEditingController();
  String? _documentNumber;

  // 5) Config: dsrParam for this activity
  String param = '60';
  // Add areaCode variable (replace 'XYZ' with actual value if available)
 

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initGeolocation();
    _loadInitialDocumentNumber();
    _fetchProcessTypes();
    _setSubmissionDateToToday();
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

  // Load any saved document number
  Future<void> _loadInitialDocumentNumber() async {
    final saved = await DocumentNumberStorage.loadDocumentNumber(DocumentNumberKeys.anyOtherActivity);
    if (saved != null) {
      setState(() {
        _documentNumber = saved;
        _documentNumberController.text = saved;
      });
    }
  }

  Future<void> _fetchProcessTypes() async {
    setState(() {
      _isLoadingProcessTypes = true;
      _processTypeError = null;
    });
    try {
      final url = Uri.parse('http://192.168.36.25/api/DsrTry/getProcessTypes');
      final response = await http.get(url);
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
          _isLoadingProcessTypes = false;
        });
      } else {
        throw Exception('Failed to load process types.');
      }
    } catch (e) {
      setState(() {
        _processdropdownItems = ['Select'];
        _processItem = 'Select';
        _isLoadingProcessTypes = false;
        _processTypeError = 'Failed to load process types.';
      });
    }
  }

  // Fetch docuNumb list when Update selected
  Future<void> _fetchDocumentNumbers() async {
  setState(() {
    _loadingDocs = true;
    _documentNumbers = [];
    _selectedDocuNumb = null;
  });
  final uri = Uri.parse(
    'http://192.168.36.25/api/DsrTry/getDocumentNumbers?dsrParam=$param'
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



  @override
  void dispose() {
    _dateController.dispose();
    _reportDateController.dispose();
    _activity1Controller.dispose();
    _activity2Controller.dispose();
    _activity3Controller.dispose();
    _anyOtherPointsController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  // DATE PICKERS
  void _setSubmissionDateToToday() {
    final today = DateTime.now();
    _selectedDate = today;
    _dateController.text = DateFormat('dd-MM-yy').format(today);
  }

  Future<void> _pickReportDate() async {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final pick = await showDatePicker(
      context: context,
      initialDate: _selectedReportDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (pick != null) {
      if (pick.isBefore(threeDaysAgo)) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Invalid DSR Date'),
            content: const Text(
              'You can only submit up to 3 days back. Use Exception Entry for older dates.'
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
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
        _selectedReportDate = pick;
        _reportDateController.text = DateFormat('dd-MM-yy').format(pick);
      });
    }
  }

  // IMAGE PICKER
  Future<void> _pickImage(int idx) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _selectedImages[idx] = file);
  }

  void _showImageDialog(XFile file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.file(
          File(file.path),
          fit: BoxFit.contain,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
        ),
      ),
    );
  }

  void _addRow() {
    if (_uploadRows.length < 3) {
      setState(() {
        _uploadRows.add(_uploadRows.length);
        _selectedImages.add(null);
      });
    }
  }

  void _removeRow() {
    if (_uploadRows.length > 1) {
      setState(() {
        _uploadRows.removeLast();
        _selectedImages.removeLast();
      });
    }
  }

  // SUBMIT / UPDATE
  Future<void> _onSubmit({required bool exitAfter}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) await _initGeolocation();

    final dsrData = {
      'ActivityType':   'Any Other Activity',
      'SubmissionDate': _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'ReportDate':     _selectedReportDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'dsrRem01':       _activity1Controller.text,
      'dsrRem02':       _activity2Controller.text,
      'dsrRem03':       _activity3Controller.text,
      'dsrRem04':       _anyOtherPointsController.text,
      'latitude':       _currentPosition?.latitude.toString() ?? '',
      'longitude':      _currentPosition?.longitude.toString() ?? '',
      'DsrParam':       param, // <-- Added for backend validation
      // <-- Added for backend validation
      'DocuNumb':       _processItem == 'Update' ? _selectedDocuNumb : null,
      'ProcessType':    _processItem == 'Update' ? 'U' : 'A',
      'CreateId':       '2948',
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

      if (!success) {
        print('Error submitting DSR: Status ${resp.statusCode}\nBody: ${resp.body}');
      }

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
          _formKey.currentState!.reset();
          setState(() {
            _processItem = 'Select';
            _selectedDocuNumb = null;
            _dateController.clear();
            _reportDateController.clear();
            _selectedDate = null;
            _selectedReportDate = null;
            _activity1Controller.clear();
            _activity2Controller.clear();
            _activity3Controller.clear();
            _anyOtherPointsController.clear();
            _uploadRows
              ..clear()
              ..add(0);
            _selectedImages
              ..clear()
              ..add(null);
          });
        }
      }
    } catch (e) {
      print('Exception during submit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exception: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> submitDsrEntry(Map<String, dynamic> dsrData) async {
    final url = Uri.parse('http://192.168.36.25/api/DsrTry');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dsrData),
    );
    // existing debug prints...
  }

  Widget _buildLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: SparshSpacing.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          filled: true,
          fillColor: SparshTheme.lightGreyBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SparshBorderRadius.sm),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SparshSpacing.md,
            vertical: SparshSpacing.sm,
          ),
        ),
        items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
        onChanged: enabled ? onChanged : null,
        validator: validator,
      );

  Widget _buildDateField(
    TextEditingController ctrl,
    VoidCallback onTap,
    String hint, {
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        readOnly: true,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: SparshTheme.lightGreyBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SparshBorderRadius.sm),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, size: SparshIconSize.lg),
            onPressed: onTap,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SparshSpacing.md,
            vertical: SparshSpacing.sm,
          ),
        ),
        onTap: onTap,
        validator: validator,
      );

  Widget _buildMultilineField(
    String hint,
    TextEditingController ctrl,
    int minLines,
  ) =>
      TextFormField(
        controller: ctrl,
        minLines: minLines,
        maxLines: minLines + 1,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: SparshTheme.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SparshBorderRadius.sm),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SparshSpacing.md,
            vertical: SparshSpacing.sm,
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SparshTheme.lightGreyBackground,
      appBar: const ModernAppBar(
        title: 'Any Other Activity',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SparshSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Activity Information ───────────────────────────
              ModernCard(
                title: 'Activity Information',
                icon: Icons.info_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_processTypeError != null)
                      Container(
                        padding: const EdgeInsets.all(SparshTheme.spacing12),
                        margin: const EdgeInsets.only(bottom: SparshTheme.spacing16),
                        decoration: BoxDecoration(
                          color: SparshTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(SparshTheme.radiusSm),
                          border: Border.all(color: SparshTheme.errorRed.withOpacity(0.3)),
                        ),
                        child: Text(_processTypeError!, style: const TextStyle(color: SparshTheme.errorRed)),
                      ),
                    _isLoadingProcessTypes
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : ModernDropdown<String>(
                          label: 'Process Type',
                          value: _processItem == 'Select' ? null : _processItem,
                          items: _processdropdownItems.where((item) => item != 'Select').map((item) => 
                            DropdownMenuItem(value: item, child: Text(item))
                          ).toList(),
                          onChanged: (val) async {
                            setState(() => _processItem = val ?? 'Select');
                            if (val == 'Update') await _fetchDocumentNumbers();
                          },
                          validator: (v) => v == null ? 'Please select a process type' : null,
                          enabled: _processdropdownItems.length > 1,
                        ),
                    if (_processItem == 'Update') ...[
                      const SizedBox(height: SparshTheme.spacing16),
                      _loadingDocs
                        ? const Center(child: CircularProgressIndicator())
                        : ModernDropdown<String>(
                            label: 'Document Number',
                            value: _selectedDocuNumb,
                            items: _documentNumbers.map((d) => 
                              DropdownMenuItem(value: d, child: Text(d))
                            ).toList(),
                            onChanged: (v) async {
                              setState(() => _selectedDocuNumb = v);
                            },
                            validator: (v) => v == null ? 'Please select a document number' : null,
                          ),
                    ],
                    const SizedBox(height: SparshTheme.spacing16),
                    ModernInput(
                      label: 'Submission Date',
                      controller: _dateController,
                      readOnly: true,
                      enabled: false,
                      suffixIcon: const Icon(Icons.lock, color: SparshTheme.textSecondary),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    ModernInput(
                      label: 'Report Date',
                      controller: _reportDateController,
                      readOnly: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, color: SparshTheme.primaryBlue),
                        onPressed: _pickReportDate,
                      ),
                      onTap: _pickReportDate,
                      validator: (v) => v == null || v.isEmpty ? 'Please select a report date' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: SparshSpacing.md),

              // ── Activity Details ───────────────────────────────
              ModernCard(
                title: 'Activity Details',
                icon: Icons.assignment_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ModernInput(
                      label: 'Activity Details 1',
                      controller: _activity1Controller,
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.description_outlined, color: SparshTheme.primaryBlue),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    ModernInput(
                      label: 'Activity Details 2',
                      controller: _activity2Controller,
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.description_outlined, color: SparshTheme.primaryBlue),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    ModernInput(
                      label: 'Activity Details 3',
                      controller: _activity3Controller,
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.description_outlined, color: SparshTheme.primaryBlue),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    ModernInput(
                      label: 'Any Other Points',
                      controller: _anyOtherPointsController,
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.note_add_outlined, color: SparshTheme.primaryBlue),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: SparshSpacing.md),

              // ── Supporting Documents ─────────────────────────────
              ModernCard(
                title: 'Supporting Documents',
                icon: Icons.photo_library_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload up to 3 images related to your activity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SparshTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SparshTheme.spacing16),
                    ..._uploadRows.map((idx) {
                      final file = _selectedImages[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: SparshTheme.spacing16),
                        padding: const EdgeInsets.all(SparshTheme.spacing16),
                        decoration: BoxDecoration(
                          color: SparshTheme.surfaceSecondary,
                          borderRadius: BorderRadius.circular(SparshTheme.radiusMd),
                          border: Border.all(color: SparshTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  file != null ? Icons.image : Icons.image_outlined,
                                  color: SparshTheme.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: SparshTheme.spacing8),
                                Text(
                                  'Document ${idx + 1}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: SparshTheme.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                if (_uploadRows.length > 1 && idx == _uploadRows.last)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: SparshTheme.errorRed),
                                    onPressed: _removeRow,
                                    tooltip: 'Remove document',
                                  ),
                              ],
                            ),
                            const SizedBox(height: SparshTheme.spacing12),
                            Row(
                              children: [
                                Expanded(
                                  child: ModernButton(
                                    text: file != null ? 'Replace' : 'Upload',
                                    onPressed: () => _pickImage(idx),
                                    type: file != null ? ModernButtonType.secondary : ModernButtonType.primary,
                                    icon: Icon(file != null ? Icons.refresh : Icons.upload_file),
                                  ),
                                ),
                                if (file != null) ...[
                                  const SizedBox(width: SparshTheme.spacing12),
                                  Expanded(
                                    child: ModernButton(
                                      text: 'View',
                                      onPressed: () => _showImageDialog(file),
                                      type: ModernButtonType.outline,
                                      icon: const Icon(Icons.visibility),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_uploadRows.length < 3) ...[
                      const SizedBox(height: SparshTheme.spacing16),
                      Center(
                        child: ModernButton(
                          text: 'Add More Image',
                          icon: const Icon(Icons.add_photo_alternate),
                          onPressed: _addRow,
                          type: ModernButtonType.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: SparshSpacing.lg),

              // ── Submit Buttons ────────────────────────────────────
              ModernButton(
                text: _processItem == 'Update' ? 'Update & New' : 'Submit & New',
                onPressed: () => _onSubmit(exitAfter: false),
                type: ModernButtonType.secondary,
                isFullWidth: true,
                icon: const Icon(Icons.add_circle_outline),
              ),
              const SizedBox(height: SparshTheme.spacing16),
              ModernButton(
                text: _processItem == 'Update' ? 'Update & Exit' : 'Submit & Exit',
                onPressed: () => _onSubmit(exitAfter: true),
                type: ModernButtonType.success,
                isFullWidth: true,
                icon: const Icon(Icons.check_circle_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
