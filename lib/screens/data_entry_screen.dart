import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/kago_theme.dart';
import '../widgets/common_widgets.dart';

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _grossWeightCtrl = TextEditingController();
  final _tareWeightCtrl  = TextEditingController();
  final _notesCtrl       = TextEditingController();
  final _fuelLitersCtrl  = TextEditingController();
  final _fuelCostCtrl    = TextEditingController();

  RecordType _selectedType = RecordType.weightReceipt;
  String _selectedCargo    = 'Agricultural produce';
  String _selectedStation  = 'Chalinze Weighbridge';
  String _selectedFuelStop = 'Morogoro Stop';

  bool _isSubmitting = false;

  static const _cargoTypes = [
    'Agricultural produce',
    'Construction materials',
    'Consumer goods',
    'Fuel / Chemicals',
    'Medical supplies',
  ];

  static const _weighbridges = [
    'Chalinze Weighbridge',
    'Mikumi Weighbridge',
    'Iringa Weighbridge',
    'Mbeya Weighbridge',
    'Other',
  ];

  static const _fuelStops = [
    'Chalinze Stop',
    'Morogoro Stop',
    'Mikumi Stop',
    'Iringa Stop',
    'Mbeya Depot',
  ];

  @override
  void dispose() {
    _grossWeightCtrl.dispose();
    _tareWeightCtrl.dispose();
    _notesCtrl.dispose();
    _fuelLitersCtrl.dispose();
    _fuelCostCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final app = context.read<AppProvider>();
    Map<String, dynamic> data;

    if (_selectedType == RecordType.weightReceipt) {
      data = {
        'cargoType':   _selectedCargo,
        'grossWeight': _grossWeightCtrl.text,
        'tareWeight':  _tareWeightCtrl.text,
        'station':     _selectedStation,
        'notes':       _notesCtrl.text,
      };
    } else {
      data = {
        'liters':   _fuelLitersCtrl.text,
        'cost':     _fuelCostCtrl.text,
        'station':  _selectedFuelStop,
        'notes':    _notesCtrl.text,
      };
    }

    try {
      final record = await app.saveRecord(type: _selectedType, data: data);
      if (mounted) {
        _showSnackbar(
          record.status == SyncStatus.synced
              ? '✅ Record uploaded to server'
              : '💾 Saved locally — will sync when online',
          record.status == SyncStatus.synced ? KagoTheme.green : KagoTheme.amber,
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) _showSnackbar('❌ Error: $e', KagoTheme.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _grossWeightCtrl.clear();
    _tareWeightCtrl.clear();
    _notesCtrl.clear();
    _fuelLitersCtrl.clear();
    _fuelCostCtrl.clear();
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'SpaceGrotesk')),
        backgroundColor: KagoTheme.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Form Card ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: KagoTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KagoTheme.border),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text('New Entry', style: TextStyle(
                          fontFamily: 'SpaceGrotesk', fontSize: 16, fontWeight: FontWeight.w600,
                        )),
                        const SizedBox(height: 4),
                        const Text('Submit data for current trip', style: TextStyle(
                          fontFamily: 'SpaceGrotesk', fontSize: 11, color: KagoTheme.grey,
                        )),
                        const SizedBox(height: 14),

                        // Offline indicator
                        if (!app.isOnline) ...[
                          _OfflineTag(),
                          const SizedBox(height: 14),
                        ],

                        // Record type selector
                        _FieldLabel('RECORD TYPE'),
                        _SegmentedPicker(
                          options: const ['Weight Receipt', 'Fuel Log'],
                          selected: _selectedType == RecordType.weightReceipt ? 0 : 1,
                          onChanged: (i) => setState(() {
                            _selectedType = i == 0 ? RecordType.weightReceipt : RecordType.fuelLog;
                          }),
                        ),
                        const SizedBox(height: 14),

                        // Dynamic fields
                        if (_selectedType == RecordType.weightReceipt) ...[
                          _FieldLabel('CARGO TYPE'),
                          _DropdownField(
                            value: _selectedCargo,
                            items: _cargoTypes,
                            onChanged: (v) => setState(() => _selectedCargo = v!),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _FieldLabel('GROSS WEIGHT (T)'),
                                  TextFormField(
                                    controller: _grossWeightCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13),
                                    decoration: const InputDecoration(hintText: 'e.g. 23.4'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ]),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _FieldLabel('TARE WEIGHT (T)'),
                                  TextFormField(
                                    controller: _tareWeightCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13),
                                    decoration: const InputDecoration(hintText: 'e.g. 8.2'),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('WEIGHBRIDGE STATION'),
                          _DropdownField(
                            value: _selectedStation,
                            items: _weighbridges,
                            onChanged: (v) => setState(() => _selectedStation = v!),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _FieldLabel('FUEL (LITERS)'),
                                  TextFormField(
                                    controller: _fuelLitersCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13),
                                    decoration: const InputDecoration(hintText: 'e.g. 120'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ]),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _FieldLabel('COST (TZS)'),
                                  TextFormField(
                                    controller: _fuelCostCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13),
                                    decoration: const InputDecoration(hintText: 'e.g. 180000'),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('FUEL STOP'),
                          _DropdownField(
                            value: _selectedFuelStop,
                            items: _fuelStops,
                            onChanged: (v) => setState(() => _selectedFuelStop = v!),
                          ),
                        ],

                        const SizedBox(height: 12),
                        _FieldLabel('NOTES (OPTIONAL)'),
                        TextFormField(
                          controller: _notesCtrl,
                          style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13),
                          decoration: const InputDecoration(hintText: 'e.g. seal no. 2284'),
                        ),

                        const SizedBox(height: 20),
                        KagoButton(
                          label: app.isOnline ? 'Save & Upload' : 'Save Offline',
                          icon: app.isOnline ? Icons.cloud_upload_outlined : Icons.save_outlined,
                          isLoading: _isSubmitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Sync Queue ─────────────────────────────────────────────
              const SectionTitle('Sync Queue'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: app.syncRecords.isEmpty
                    ? _EmptyQueue()
                    : Column(
                        children: app.syncRecords.map((r) => QueueItem(record: r)).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(
      fontFamily: 'SpaceGrotesk', fontSize: 11, color: KagoTheme.grey, letterSpacing: 0.3,
    )),
  );
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropdownField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(
        fontFamily: 'SpaceGrotesk', fontSize: 13,
      )))).toList(),
      onChanged: onChanged,
      dropdownColor: KagoTheme.cardBg,
      decoration: const InputDecoration(),
      style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, color: Color(0xFFE8EAF0)),
    );
  }
}

class _OfflineTag extends StatefulWidget {
  @override
  State<_OfflineTag> createState() => _OfflineTagState();
}

class _OfflineTagState extends State<_OfflineTag> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: KagoTheme.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: KagoTheme.red.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _ctrl,
            child: Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(color: KagoTheme.red, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'OFFLINE — will sync automatically',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk', fontSize: 10, fontWeight: FontWeight.w700,
              color: KagoTheme.red, letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  const _SegmentedPicker({required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KagoTheme.darkBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KagoTheme.border),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? KagoTheme.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  options[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : KagoTheme.grey,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: KagoTheme.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: KagoTheme.border),
    ),
    child: const Column(
      children: [
        Text('📭', style: TextStyle(fontSize: 28)),
        SizedBox(height: 8),
        Text('No records yet', style: TextStyle(
          fontFamily: 'SpaceGrotesk', fontSize: 13, color: KagoTheme.grey,
        )),
      ],
    ),
  );
}
