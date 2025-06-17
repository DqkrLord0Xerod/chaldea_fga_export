import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'custom_dialogs.dart';

class SliderWithPrefix extends StatelessWidget {
  final bool titled;
  final String label;
  final String Function(int v)? valueFormatter;
  final int min;
  final int max;
  final int value;
  final ValueChanged<double> onChange;
  final ValueChanged<double>? onEdit;
  final int? division;
  final double leadingWidth;
  final bool enableInput;
  final EdgeInsetsGeometry? padding;

  const SliderWithPrefix({
    super.key,
    this.titled = false,
    required this.label,
    this.valueFormatter,
    required this.min,
    required this.max,
    required this.value,
    required this.onChange,
    this.onEdit,
    this.division,
    this.leadingWidth = 48,
    this.enableInput = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color? lableColor = enableInput ? Theme.of(context).colorScheme.primary : null;
    Widget header;
    final valueText = valueFormatter?.call(value) ?? value.toString();
    if (titled) {
      header = Text.rich(
        TextSpan(
          text: label,
          children: [
            const TextSpan(text: ': '),
            TextSpan(
              text: valueText,
              style: TextStyle(color: lableColor),
            ),
          ],
        ),
      );
    } else {
      header = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSizeText(
            label,
            maxLines: 1,
            minFontSize: 10,
            maxFontSize: 16,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: valueText.isEmpty ? lableColor : null),
          ),
          AutoSizeText(valueText, maxLines: 1, minFontSize: 10, maxFontSize: 14, style: TextStyle(color: lableColor)),
        ],
      );
    }

    if (enableInput) {
      header = InkWell(
        onTap: () {
          showDialog(context: context, useRootNavigator: false, builder: getInputDialog);
        },
        child: header,
      );
    }
    Widget slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackShape: const _CustomTrackShape(left: 16, right: 16),
      ),
      child: Slider(
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: max > min ? (division ?? max - min) : null,
        value: value.toDouble(),
        label: valueText,
        onChanged: (v) {
          onChange(v);
        },
      ),
    );
    slider = ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320, maxHeight: 24), child: slider);

    Widget child;
    if (titled) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, slider],
      );
    } else {
      child = Row(
        children: [
          if (!titled) SizedBox(width: leadingWidth, child: header),
          Flexible(child: slider),
        ],
      );
    }
    if (padding != null) {
      child = Padding(padding: padding!, child: child);
    }
    return child;
  }

  Widget getInputDialog(BuildContext context) {
    String helperText = '$min~$max';
    return InputCancelOkDialog.number(
      title: label,
      initValue: value,
      helperText: helperText,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      validate: (v) => v >= min && v <= max,
      onSubmit: (v) {
        if (v >= min && v <= max) {
          if (onEdit != null) {
            onEdit!(v.toDouble());
          } else {
            onChange(v.toDouble());
          }
        }
      },
    );
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  final double left;
  final double right;

  const _CustomTrackShape({this.left = 0.0, this.right = 0.0});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx + left;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width - left - right;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
