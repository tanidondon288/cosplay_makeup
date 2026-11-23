import 'package:flutter/material.dart';

/// よく使うメイクの色の見本。
const _presetColors = <int>[
  0xFFFFF4E0, // ハイライト
  0xFFFBE3D6,
  0xFFE8C4A8,
  0xFFC99A7A,
  0xFF8C5A43,
  0xFF4B2E24,
  0xFFF4C2C2,
  0xFFE38B9A,
  0xFFB0405A,
  0xFFF2B27A,
  0xFFD9A441,
  0xFFE6E6FA,
  0xFF9B7CC4,
  0xFF6FA8DC,
  0xFF7FBF7F,
  0xFF7A7A80,
  0xFF222222,
  0xFFFFFFFF,
];

/// 色見本とスライダーで色を選ぶダイアログ。選んだ色を返す。
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, required this.initial});

  final Color initial;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('色を選ぶ'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _hsv.toColor(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _presetColors)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _hsv = HSVColor.fromColor(Color(c))),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _slider('色合い', _hsv.hue, 360, (v) => _hsv = _hsv.withHue(v)),
              _slider(
                '鮮やかさ',
                _hsv.saturation,
                1,
                (v) => _hsv = _hsv.withSaturation(v),
              ),
              _slider('明るさ', _hsv.value, 1, (v) => _hsv = _hsv.withValue(v)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _hsv.toColor()),
          child: const Text('決定'),
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double maxValue,
    void Function(double) update,
  ) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            max: maxValue,
            onChanged: (v) => setState(() => update(v)),
          ),
        ),
      ],
    );
  }
}
