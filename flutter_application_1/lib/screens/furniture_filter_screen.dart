import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/furniture.dart';
import '../services/furniture_store.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class FurnitureFilterScreen extends StatefulWidget {
  const FurnitureFilterScreen({super.key, required this.store});
  final FurnitureStore store;
  @override
  State<FurnitureFilterScreen> createState() => _FurnitureFilterScreenState();
}

class _FurnitureFilterScreenState extends State<FurnitureFilterScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _min, _max, _width, _depth, _height;
  String? _category, _company;
  Set<String> _materials = {}, _colors = {};
  bool _only3D = false;
  @override
  void initState() {
    super.initState();
    final filters = widget.store.filters;
    _min = TextEditingController(
      text: filters.minPrice == 0 ? '' : '${filters.minPrice}',
    );
    _max = TextEditingController(text: filters.maxPrice?.toString() ?? '');
    _width = TextEditingController(text: filters.maxWidth?.toString() ?? '');
    _depth = TextEditingController(text: filters.maxDepth?.toString() ?? '');
    _height = TextEditingController(text: filters.maxHeight?.toString() ?? '');
    _category = filters.category;
    _company = filters.company;
    _materials = {...filters.materials};
    _colors = {...filters.colors};
    _only3D = filters.only3D;
  }

  @override
  void dispose() {
    for (final controller in [_min, _max, _width, _depth, _height]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _numberError(String? value, {bool dimension = false}) {
    if (value == null || value.isEmpty) return null;
    final number = double.tryParse(value);
    if (number == null ||
        !number.isFinite ||
        number < 0 ||
        (dimension && number == 0)) {
      return 'Зөв ${dimension ? 'хэмжээ' : 'үнэ'} оруулна уу';
    }
    if (!dimension && int.tryParse(value) == null) {
      return 'Бүхэл тоо оруулна уу';
    }
    return null;
  }

  bool get _valid =>
      [_min, _max].every((c) => _numberError(c.text) == null) &&
      [
        _width,
        _depth,
        _height,
      ].every((c) => _numberError(c.text, dimension: true) == null) &&
      (_max.text.isEmpty ||
          (int.tryParse(_max.text) ?? -1) >= (int.tryParse(_min.text) ?? 0));
  FurnitureFilters get _draft => FurnitureFilters(
    category: _category,
    minPrice: int.tryParse(_min.text) ?? 0,
    maxPrice: int.tryParse(_max.text),
    maxWidth: double.tryParse(_width.text),
    maxDepth: double.tryParse(_depth.text),
    maxHeight: double.tryParse(_height.text),
    materials: Set.unmodifiable(_materials),
    colors: Set.unmodifiable(_colors),
    company: _company,
    only3D: _only3D,
  );
  void _clear() {
    setState(() {
      for (final controller in [_min, _max, _width, _depth, _height]) {
        controller.clear();
      }
      _category = null;
      _company = null;
      _materials = {};
      _colors = {};
      _only3D = false;
    });
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 14),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  );
  Widget _input(
    String label,
    TextEditingController controller, {
    bool dimension = false,
    bool upper = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: dimension),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            dimension ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
          ),
        ],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: dimension
              ? 'Хязгааргүй'
              : upper
              ? 'Хязгааргүй'
              : '0',
          suffixText: dimension ? null : '₮',
          errorMaxLines: 3,
        ),
        validator: (value) {
          final error = _numberError(value, dimension: dimension);
          if (error != null) return error;
          if (upper &&
              value != null &&
              value.isNotEmpty &&
              (int.tryParse(value) ?? 0) < (int.tryParse(_min.text) ?? 0)) {
            return 'Доод үнээс бага байна';
          }
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
    ],
  );
  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(
      label,
      style: TextStyle(color: selected ? Colors.white : AppTheme.ink),
    ),
    selected: selected,
    showCheckmark: false,
    selectedColor: AppTheme.green,
    backgroundColor: Colors.white,
    side: BorderSide(color: selected ? AppTheme.green : AppTheme.border),
    shape: const StadiumBorder(),
    onSelected: (_) => setState(onTap),
  );
  @override
  Widget build(BuildContext context) {
    final limit = math
        .max(
          3000000,
          math.max(int.tryParse(_max.text) ?? 0, int.tryParse(_min.text) ?? 0),
        )
        .toDouble();
    final low = (int.tryParse(_min.text) ?? 0).toDouble().clamp(0.0, limit);
    final high = (int.tryParse(_max.text) ?? limit.toInt()).toDouble().clamp(
      low,
      limit,
    );
    final count = _valid ? widget.store.matching(_draft).length : 0;
    final companies = widget.store.products
        .map((item) => item.company)
        .toSet()
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тавилга шүүх'),
        actions: [TextButton(onPressed: _clear, child: const Text('Цэвэрлэх'))],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heading('Ангилал'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [null, 'Буйдан', 'Ширээ', 'Сандал', 'Гэрэл']
                          .map(
                            (category) => _chip(
                              category ?? 'Бүгд',
                              _category == category,
                              () => _category = category,
                            ),
                          )
                          .toList(),
                    ),
                    _heading('Үнэ'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _input('Доод үнэ', _min)),
                        const SizedBox(width: 12),
                        Expanded(child: _input('Дээд үнэ', _max, upper: true)),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(low, high),
                      min: 0,
                      max: limit,
                      labels: RangeLabels(
                        '${low.round()} ₮',
                        '${high.round()} ₮',
                      ),
                      semanticFormatterCallback: (value) =>
                          '${value.round()} төгрөг',
                      onChanged: (values) => setState(() {
                        _min.text = '${values.start.round()}';
                        _max.text = values.end == limit
                            ? ''
                            : '${values.end.round()}';
                      }),
                    ),
                    _heading('Дээд хэмжээ · см'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _input('Өргөн', _width, dimension: true),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _input('Гүн', _depth, dimension: true)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _input('Өндөр', _height, dimension: true),
                        ),
                      ],
                    ),
                    _heading('Материал, өнгө'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip(
                          'Бүгд',
                          _materials.isEmpty,
                          () => _materials.clear(),
                        ),
                        ...['Мод', 'Даавуу'].map(
                          (material) => _chip(
                            material,
                            _materials.contains(material),
                            () {
                              if (!_materials.add(material)) {
                                _materials.remove(material);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children:
                          {
                                'Цөцгий': const Color(0xFFECE5D5),
                                'Модон': const Color(0xFFC5A775),
                                'Ногоон': const Color(0xFF9EA99E),
                                'Саарал': const Color(0xFF50564B),
                              }.entries
                              .map(
                                (entry) => Semantics(
                                  label: entry.key,
                                  selected: _colors.contains(entry.key),
                                  child: Tooltip(
                                    message: entry.key,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => setState(() {
                                        if (!_colors.add(entry.key)) {
                                          _colors.remove(entry.key);
                                        }
                                      }),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _colors.contains(entry.key)
                                                ? AppTheme.green
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: entry.value,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text('Компани', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_company),
                      initialValue: _company ?? '',
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Бүх компани'),
                        ),
                        ...companies.map(
                          (company) => DropdownMenuItem(
                            value: company,
                            child: Text(company),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _company = value == '' ? null : value),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _only3D,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Зөвхөн 3D / AR загвартай',
                        style: TextStyle(fontSize: 14),
                      ),
                      onChanged: (value) =>
                          setState(() => _only3D = value ?? false),
                    ),
                    if (!_valid)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Үнэ болон хэмжээг шалгана уу. Дээд үнэ доод үнээс бага байж болохгүй.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    PrimaryButton(
                      label: '$count тавилга үзэх',
                      onPressed: !_valid
                          ? null
                          : () {
                              if (_form.currentState!.validate()) {
                                Navigator.pop(context, _draft);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _clear,
                        child: const Text('Бүх шүүлтүүрийг цэвэрлэх'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
